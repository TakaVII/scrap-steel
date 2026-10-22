# purpose: [v5] The Assembler. Route power from PWR to OUT through every node (C) using a LIMITED amount of wire, before the timer ends. The planted route is a near-shortest path through 1/2/3 nodes (by tier) that detours around hazards, and the wire budget is that route plus a small slack, so the player must plan the order of the nodes. Output stays locked until all nodes are connected. Game feel: pop and burst on every cell, node chimes, red shake on hazards, time bar, completion sweep along the wire, result popup. Tile art: Assets/Textures/Minigames/tile_*.png.
# depends: MinigameBase, SpriteKit, Sfx, Juice, GamePalette
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Assembler Mechanics")
@export var tier_time_limits: Array[float] = [28.0, 26.0, 24.0]
@export var tier_grid_sizes: Array[int] = [5, 6, 7]
@export var tier_waypoints: Array[int] = [1, 2, 3]
@export var tier_hazard_density: Array[float] = [0.22, 0.28, 0.35]
## Spare wire pieces on top of the planted route. Less spare wire = harder.
@export var tier_wire_slack: Array[int] = [5, 3, 2]
@export var fog_from_tier: int = 3
@export var fog_radius: int = 2
## The planted route must be at least this many times the straight (Manhattan) distance.
@export var min_detour_ratio: float = 1.4
@export var hazard_score_penalty: float = 0.25
@export var time_score_penalty_weight: float = 0.40
@export var timeout_completion_multiplier: float = 0.30
## Cell size in logical pixels. Tile art (tile_*.png) is drawn at exactly this size (20x20).
@export var cell_size: int = 20
@export_group("Game Feel")
@export var sweep_step_sec: float = 0.035
@export var finish_delay_sec: float = 1.0

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0)]
const BUILD_ATTEMPTS: int = 60

@onready var grid_container: GridContainer = %GridContainer
@onready var timer_label: Label = %TimerLabel
@onready var hazards_label: Label = %HazardsLabel
@onready var status_label: Label = %StatusLabel

enum CellType { EMPTY, START_NODE, END_NODE, HAZARD, WAYPOINT }

var _tier: int = 1
var _grid_dim: int = 5
var _time_limit: float = 25.0
var _time_remaining: float = 25.0
var _hazards_hit: int = 0
var _start_cell: Vector2i = Vector2i(0, 2)
var _end_cell: Vector2i = Vector2i(4, 2)
var _cells: Dictionary = {}     # Vector2i -> CellType
var _buttons: Dictionary = {}   # Vector2i -> Button
var _revealed: Dictionary = {}  # hazards revealed by fog
var _waypoints: Array[Vector2i] = []
var _solution_path: Array[Vector2i] = []
var _player_path: Array[Vector2i] = []
var _wire_budget: int = 20
var _last_tenth: int = -1
var _wire_label: Label
var _time_bar: ProgressBar
var _fx: CPUParticles2D
var _out_unlocked: bool = false
var _out_tween: Tween

func setup(diff: Dictionary) -> void:
	super.setup(diff)
	_tier = diff.get("tier", 1)
	var ti: int = clampi(_tier - 1, 0, 2)
	_grid_dim = tier_grid_sizes[ti]
	_time_limit = tier_time_limits[ti] * float(diff.get("window_mult", 1.0)) # slow mode = more time
	_time_remaining = _time_limit

func start() -> void:
	super.start()
	_hazards_hit = 0
	_out_unlocked = false
	_generate_circuit_grid()
	_reveal_near(_start_cell)
	_build_extras()
	_build_ui_grid()
	_update_labels()

# ---------------------------------------------------------------- generation

func _generate_circuit_grid() -> void:
	var ok: bool = false
	for attempt in range(BUILD_ATTEMPTS):
		if _try_build_solution():
			ok = true
			break
	if not ok:
		_waypoints.clear()
		_solution_path = _fallback_path()
	_place_cells()
	_wire_budget = (_solution_path.size() - 1) + tier_wire_slack[clampi(_tier - 1, 0, 2)]

## Builds a near-shortest route start -> nodes (nearest first) -> output, one BFS leg at a time.
func _try_build_solution() -> bool:
	var ti: int = clampi(_tier - 1, 0, 2)
	_start_cell = Vector2i(0, randi_range(0, _grid_dim - 1))
	_end_cell = Vector2i(_grid_dim - 1, randi_range(0, _grid_dim - 1))
	_waypoints = _pick_waypoints(tier_waypoints[ti])
	if _waypoints.size() < tier_waypoints[ti]:
		return false
	var stops: Array[Vector2i] = _nearest_order(_start_cell, _waypoints)
	stops.append(_end_cell)
	var used: Dictionary = {_start_cell: true}
	var path: Array[Vector2i] = [_start_cell]
	var cur: Vector2i = _start_cell
	for stop in stops:
		var leg: Array[Vector2i] = _bfs_leg(cur, stop, used)
		if leg.is_empty():
			return false
		for c in leg:
			used[c] = true
		path.append_array(leg)
		cur = stop
	var manhattan: int = absi(_end_cell.x - _start_cell.x) + absi(_end_cell.y - _start_cell.y)
	if path.size() - 1 < int(ceil(min_detour_ratio * float(manhattan))):
		return false
	_solution_path = path
	return true

## Nodes sit at least 2 rows off the straight start->end line and 3+ cells from each other.
func _pick_waypoints(count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var tries: int = 0
	while result.size() < count and tries < 80:
		tries += 1
		var c := Vector2i(randi_range(1, _grid_dim - 2), randi_range(0, _grid_dim - 1))
		var t: float = float(c.x) / float(_grid_dim - 1)
		var line_y: float = lerpf(float(_start_cell.y), float(_end_cell.y), t)
		if absf(float(c.y) - line_y) < 2.0:
			continue
		var far_enough: bool = true
		for w in result:
			if absi(w.x - c.x) + absi(w.y - c.y) < 3:
				far_enough = false
		if far_enough:
			result.append(c)
	return result

func _nearest_order(from: Vector2i, points: Array[Vector2i]) -> Array[Vector2i]:
	var remaining: Array[Vector2i] = []
	remaining.append_array(points)
	var order: Array[Vector2i] = []
	var cur: Vector2i = from
	while not remaining.is_empty():
		var best: int = 0
		var best_d: int = 1000000
		for i in range(remaining.size()):
			var d: int = absi(remaining[i].x - cur.x) + absi(remaining[i].y - cur.y)
			if d < best_d:
				best_d = d
				best = i
		cur = remaining.pop_at(best)
		order.append(cur)
	return order

## Shortest path from `from` to `to` that avoids used cells and the other stops. Excludes `from`, includes `to`. Empty = no path.
func _bfs_leg(from: Vector2i, to: Vector2i, used: Dictionary) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = []
	dirs.append_array(DIRS)
	dirs.shuffle() # random tie-breaks so grids differ
	var came: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		if cur == to:
			break
		for d in dirs:
			var n: Vector2i = cur + d
			if n.x < 0 or n.x >= _grid_dim or n.y < 0 or n.y >= _grid_dim:
				continue
			if came.has(n) or used.has(n):
				continue
			if n != to and (n == _end_cell or _waypoints.has(n)):
				continue # other stops are visited on their own leg
			came[n] = cur
			queue.append(n)
	var out: Array[Vector2i] = []
	if not came.has(to):
		return out
	var c: Vector2i = to
	while c != from:
		out.push_front(c)
		c = came[c]
	return out

## Straight run along the start row, then along the end column. Always contiguous.
func _fallback_path() -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for x in range(_start_cell.x, _end_cell.x + 1):
		path.append(Vector2i(x, _start_cell.y))
	var step: int = 1 if _end_cell.y > _start_cell.y else -1
	var y: int = _start_cell.y + step
	while _start_cell.y != _end_cell.y and y != _end_cell.y + step:
		path.append(Vector2i(_end_cell.x, y))
		y += step
	return path

func _place_cells() -> void:
	_cells.clear()
	_revealed.clear()
	var ti: int = clampi(_tier - 1, 0, 2)
	for y in range(_grid_dim):
		for x in range(_grid_dim):
			_cells[Vector2i(x, y)] = CellType.EMPTY
	_cells[_start_cell] = CellType.START_NODE
	_cells[_end_cell] = CellType.END_NODE
	for w in _waypoints:
		_cells[w] = CellType.WAYPOINT
	var on_path: Dictionary = {}
	for p in _solution_path:
		on_path[p] = true
	for y in range(_grid_dim):
		for x in range(_grid_dim):
			var pt := Vector2i(x, y)
			if not on_path.has(pt) and _cells[pt] == CellType.EMPTY and randf() < tier_hazard_density[ti]:
				_cells[pt] = CellType.HAZARD
	_player_path = [_start_cell]

# ---------------------------------------------------------------- ui

## Adds the wire counter, a time bar and the particle emitter to the scene (once).
func _build_extras() -> void:
	if _time_bar != null:
		return
	var header: Node = hazards_label.get_parent()
	_wire_label = Label.new()
	header.add_child(_wire_label)
	header.move_child(_wire_label, timer_label.get_index())
	var vbox: Node = header.get_parent()
	if vbox is VBoxContainer:
		(vbox as VBoxContainer).add_theme_constant_override("separation", 4)
	_time_bar = ProgressBar.new()
	_time_bar.show_percentage = false
	_time_bar.max_value = 100.0
	_time_bar.value = 100.0
	_time_bar.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(_time_bar)
	vbox.move_child(_time_bar, header.get_index() + 1)
	var instruct: Label = vbox.find_child("InstructLabel", false, false) as Label
	if instruct != null:
		instruct.text = tr("MINIGAME_ASSEMBLER_INSTRUCT")

	_fx = CPUParticles2D.new()
	_fx.emitting = false
	_fx.one_shot = true
	_fx.explosiveness = 1.0
	_fx.lifetime = 0.4
	_fx.spread = 180.0
	_fx.initial_velocity_min = 30.0
	_fx.initial_velocity_max = 80.0
	_fx.gravity = Vector2.ZERO
	_fx.scale_amount_min = 1.5
	_fx.scale_amount_max = 3.0
	add_child(_fx)

func _build_ui_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_buttons.clear()
	grid_container.columns = _grid_dim
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)
	for y in range(_grid_dim):
		for x in range(_grid_dim):
			var pt := Vector2i(x, y)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(cell_size, cell_size)
			btn.pressed.connect(_on_cell_clicked.bind(pt))
			grid_container.add_child(btn)
			_buttons[pt] = btn
	_refresh_cell_visuals()

func _hazard_visible(pt: Vector2i) -> bool:
	return _tier < fog_from_tier or _revealed.has(pt)

func _all_nodes_connected() -> bool:
	return _waypoints_hit() >= _waypoints.size()

func _refresh_cell_visuals() -> void:
	var unlocked: bool = _all_nodes_connected()
	for pt in _buttons.keys():
		var btn: Button = _buttons[pt]
		if pt == _start_cell:
			_style_cell(btn, "power", "PWR", GamePalette.POSITIVE)
		elif pt == _end_cell:
			_style_cell(btn, "output", "OUT", GamePalette.ACCENT if unlocked else Color(GamePalette.ACCENT, 0.4))
		elif _cells[pt] == CellType.WAYPOINT:
			var lit: bool = _player_path.has(pt)
			_style_cell(btn, "node_lit" if lit else "node", "[C]" if lit else "C", GamePalette.NEON_MAGENTA)
		elif _player_path.has(pt):
			_style_cell(btn, "wire", "o", GamePalette.POSITIVE)
		elif _cells[pt] == CellType.HAZARD and _hazard_visible(pt):
			_style_cell(btn, "hazard", "!", GamePalette.NEGATIVE) # shape "!" + colour: never colour alone
		else:
			_style_cell(btn, "empty", "+", Color(0.8, 0.8, 0.8, 0.8))

func _style_cell(btn: Button, tile: String, fallback: String, tint: Color) -> void:
	var t: Texture2D = SpriteKit.tex(SpriteKit.MG + "tile_" + tile + ".png")
	if t != null:
		btn.icon = t
		btn.expand_icon = true
		btn.text = ""
		btn.modulate = Color(1, 1, 1, tint.a)
	else:
		btn.icon = null
		btn.text = fallback
		btn.modulate = tint

func _reveal_near(head: Vector2i) -> void:
	for pt in _cells.keys():
		if _cells[pt] == CellType.HAZARD and maxi(absi(pt.x - head.x), absi(pt.y - head.y)) <= fog_radius:
			_revealed[pt] = true

func _waypoints_hit() -> int:
	var n: int = 0
	for w in _waypoints:
		if _player_path.has(w):
			n += 1
	return n

# ---------------------------------------------------------------- game feel

func _burst(pt: Vector2i, color: Color, amount: int) -> void:
	var btn: Button = _buttons.get(pt) as Button
	if btn == null:
		return
	_fx.position = btn.global_position - global_position + btn.size * 0.5
	_fx.amount = amount
	_fx.color = color
	_fx.restart()

func _pop(pt: Vector2i) -> void:
	var btn: Button = _buttons.get(pt) as Button
	if btn == null:
		return
	btn.pivot_offset = btn.size * 0.5
	btn.scale = Vector2(1.35, 1.35)
	btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.14)

func _flash_cell(pt: Vector2i) -> void:
	var btn: Button = _buttons.get(pt) as Button
	if btn == null:
		return
	btn.pivot_offset = btn.size * 0.5
	btn.scale = Vector2(1.25, 1.25)
	btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12)
	_burst(pt, GamePalette.NEON_CYAN, 4)

func _hazard_feedback(pt: Vector2i) -> void:
	_burst(pt, GamePalette.NEGATIVE, 16)
	Juice.shake(self, 3.5, 0.18)
	if not SettingsManager.reduced_flashing:
		grid_container.modulate = Color(1.0, 0.45, 0.45)
		grid_container.create_tween().tween_property(grid_container, "modulate", Color.WHITE, 0.3)

func _unlock_output() -> void:
	_out_unlocked = true
	status_label.text = tr("MINIGAME_ASSEMBLER_OUT_UNLOCKED")
	_burst(_end_cell, GamePalette.ACCENT, 18)
	Sfx.play("upgrade_buy")
	var btn: Button = _buttons.get(_end_cell) as Button
	if btn != null and not SettingsManager.reduced_flashing:
		_out_tween = btn.create_tween().set_loops()
		_out_tween.tween_property(btn, "modulate:a", 0.55, 0.35)
		_out_tween.tween_property(btn, "modulate:a", 1.0, 0.35)

# ---------------------------------------------------------------- play

func _on_cell_clicked(pt: Vector2i) -> void:
	if not is_active:
		return
	var last: Vector2i = _player_path.back()
	if _player_path.size() > 1 and pt == _player_path[_player_path.size() - 2]:
		_player_path.pop_back() # click the previous cell to undo (the wire piece comes back)
		if _out_unlocked and not _all_nodes_connected():
			_out_unlocked = false
			if _out_tween:
				_out_tween.kill()
		_refresh_cell_visuals()
		_update_labels()
		return
	var delta_cell: Vector2i = pt - last
	if (absi(delta_cell.x) + absi(delta_cell.y)) != 1 or _player_path.has(pt):
		return
	if _player_path.size() - 1 >= _wire_budget:
		status_label.text = tr("MINIGAME_ASSEMBLER_NO_WIRE")
		Sfx.play("warning")
		Juice.shake(self, 1.5, 0.1)
		return
	if pt == _end_cell and not _all_nodes_connected():
		status_label.text = tr("MINIGAME_ASSEMBLER_NEED_NODES")
		Sfx.play("strike_miss")
		return

	var was_unlocked: bool = _all_nodes_connected()
	if _cells[pt] == CellType.HAZARD:
		_hazards_hit += 1
		_revealed[pt] = true
		status_label.text = tr("MINIGAME_ASSEMBLER_HAZARD_HIT")
		Sfx.play("assembler_hazard")
		_hazard_feedback(pt)
	else:
		status_label.text = ""
		Sfx.play("assembler_step")
		_burst(pt, GamePalette.POSITIVE, 5)
	_player_path.append(pt)
	_reveal_near(pt)
	_refresh_cell_visuals()
	_pop(pt)
	_update_labels()

	if _cells[pt] == CellType.WAYPOINT:
		_burst(pt, GamePalette.NEON_MAGENTA, 14)
		Sfx.play("credit_coin")
	if not was_unlocked and _all_nodes_connected() and not _waypoints.is_empty():
		_unlock_output()

	if pt == _end_cell:
		var time_used: float = _time_limit - _time_remaining
		var s: float = clampf(1.0 - hazard_score_penalty * float(_hazards_hit) - time_score_penalty_weight * (time_used / _time_limit), 0.0, 1.0)
		status_label.text = tr("MINIGAME_ASSEMBLER_CIRCUIT_CLOSED")
		_play_completion(s)

## Lights the wire from PWR to OUT piece by piece, then shows the result.
func _play_completion(score: float) -> void:
	if _out_tween:
		_out_tween.kill()
	var sweep := create_tween()
	for p in _player_path:
		sweep.tween_callback(_flash_cell.bind(p))
		sweep.tween_interval(sweep_step_sec)
	finish_with_delay(score, finish_delay_sec)

func _process(delta: float) -> void:
	if not is_active:
		return
	_time_remaining -= delta
	var tenth: int = int(maxf(0.0, _time_remaining) * 10.0)
	if tenth != _last_tenth:
		_last_tenth = tenth
		_update_labels()
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		status_label.text = tr("MG_TIME_UP")
		var completion: float = float(_player_path.size() - 1) / float(maxi(1, _solution_path.size() - 1))
		finish_with_delay(timeout_completion_multiplier * clampf(completion, 0.0, 1.0))

func _update_labels() -> void:
	timer_label.text = "%.1fs" % maxf(0.0, _time_remaining)
	timer_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if _time_remaining < 5.0 else GamePalette.NEUTRAL_TEXT)
	hazards_label.text = "%s: %d  %s: %d/%d" % [tr("MINIGAME_ASSEMBLER_HAZARDS"), _hazards_hit, tr("MINIGAME_ASSEMBLER_NODES"), _waypoints_hit(), _waypoints.size()]
	var used: int = _player_path.size() - 1
	_wire_label.text = "%s: %d/%d" % [tr("MINIGAME_ASSEMBLER_WIRE"), used, _wire_budget]
	_wire_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if _wire_budget - used <= 2 else GamePalette.NEUTRAL_TEXT)
	var frac: float = clampf(_time_remaining / _time_limit, 0.0, 1.0)
	_time_bar.value = frac * 100.0
	_time_bar.modulate = Color.WHITE if frac > 0.5 else (GamePalette.ACCENT if frac > 0.25 else GamePalette.NEGATIVE)

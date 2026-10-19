# purpose: [v4] The Assembler. No more straight lines: the solution is built through 1/2/3 waypoint "nodes" (by tier) placed away from the direct line, so the player must detour; every node must be connected before the output accepts the path. Hazard density rises with tier; tier 3 hides hazards until the path head is close (fog). Grids are guaranteed solvable because the solution is built first and hazards go only off-path. Optional tile art: Assets/Textures/Minigames/tile_*.png.
# depends: MinigameBase, SpriteKit, Sfx, GamePalette
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Assembler Mechanics")
@export var tier_time_limits: Array[float] = [25.0, 30.0, 35.0]
@export var tier_grid_sizes: Array[int] = [5, 6, 7]
@export var tier_waypoints: Array[int] = [1, 2, 3]
@export var tier_hazard_density: Array[float] = [0.22, 0.26, 0.30]
@export var fog_from_tier: int = 3
@export var fog_radius: int = 2
## The solution must be at least this many times the straight (Manhattan) distance.
@export var min_detour_ratio: float = 1.4
@export var hazard_score_penalty: float = 0.25
@export var time_score_penalty_weight: float = 0.40
@export var timeout_completion_multiplier: float = 0.30
## Cell size in logical pixels. Tile art (tile_*.png) is drawn at exactly this size (20x20).
@export var cell_size: int = 20

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0)]
const SEARCH_BUDGET: int = 600
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
var _search_budget: int = 0
var _last_tenth: int = -1

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
	_generate_circuit_grid()
	_reveal_near(_start_cell)
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

func _try_build_solution() -> bool:
	var ti: int = clampi(_tier - 1, 0, 2)
	_start_cell = Vector2i(0, randi_range(0, _grid_dim - 1))
	_end_cell = Vector2i(_grid_dim - 1, randi_range(0, _grid_dim - 1))
	_waypoints = _pick_waypoints(tier_waypoints[ti])
	if _waypoints.size() < tier_waypoints[ti]:
		return false
	var used: Dictionary = {_start_cell: true}
	var path: Array[Vector2i] = [_start_cell]
	var stops: Array[Vector2i] = []
	stops.append_array(_waypoints)
	stops.append(_end_cell)
	var cur: Vector2i = _start_cell
	for stop in stops:
		_search_budget = SEARCH_BUDGET
		var leg: Array[Vector2i] = []
		if not _dfs_leg(cur, stop, used, leg):
			return false
		path.append_array(leg)
		cur = stop
	var manhattan: int = absi(_end_cell.x - _start_cell.x) + absi(_end_cell.y - _start_cell.y)
	if path.size() - 1 < int(ceil(min_detour_ratio * float(manhattan))):
		return false
	_solution_path = path
	return true

## Waypoints sit at least 2 rows off the straight start->end line and 3+ cells from each other.
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
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	return result

## Randomised depth-first self-avoiding walk from `cur` to `target`. Fills `out` (excluding `cur`, including `target`).
func _dfs_leg(cur: Vector2i, target: Vector2i, used: Dictionary, out: Array[Vector2i]) -> bool:
	if cur == target:
		return true
	_search_budget -= 1
	if _search_budget <= 0:
		return false
	var ranked: Array = []
	for d in DIRS:
		var n: Vector2i = cur + d
		if n.x < 0 or n.x >= _grid_dim or n.y < 0 or n.y >= _grid_dim:
			continue
		if used.has(n):
			continue
		if n != target and (n == _end_cell or _waypoints.has(n)):
			continue # other stops are visited on their own leg
		var dx: int = n.x - target.x
		var dy: int = n.y - target.y
		ranked.append([float(dx * dx + dy * dy) + randf() * 6.0, n])
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for r in ranked:
		var n: Vector2i = r[1]
		used[n] = true
		out.append(n)
		if _dfs_leg(n, target, used, out):
			return true
		out.pop_back()
		used.erase(n)
	return false

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

func _build_ui_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_buttons.clear()
	grid_container.columns = _grid_dim
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)
	var px: int = cell_size
	for y in range(_grid_dim):
		for x in range(_grid_dim):
			var pt := Vector2i(x, y)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(px, px)
			btn.pressed.connect(_on_cell_clicked.bind(pt))
			grid_container.add_child(btn)
			_buttons[pt] = btn
	_refresh_cell_visuals()

func _hazard_visible(pt: Vector2i) -> bool:
	return _tier < fog_from_tier or _revealed.has(pt)

func _refresh_cell_visuals() -> void:
	for pt in _buttons.keys():
		var btn: Button = _buttons[pt]
		if pt == _start_cell:
			_style_cell(btn, "power", "PWR", GamePalette.POSITIVE)
		elif pt == _end_cell:
			_style_cell(btn, "output", "OUT", GamePalette.ACCENT)
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
		btn.modulate = Color.WHITE
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

func _on_cell_clicked(pt: Vector2i) -> void:
	if not is_active:
		return
	var last: Vector2i = _player_path.back()
	if _player_path.size() > 1 and pt == _player_path[_player_path.size() - 2]:
		_player_path.pop_back() # click the previous cell to undo
		_refresh_cell_visuals()
		_update_labels()
		return
	var delta_cell: Vector2i = pt - last
	if (absi(delta_cell.x) + absi(delta_cell.y)) != 1 or _player_path.has(pt):
		return
	if pt == _end_cell and _waypoints_hit() < _waypoints.size():
		status_label.text = tr("MINIGAME_ASSEMBLER_NEED_NODES")
		return

	if _cells[pt] == CellType.HAZARD:
		_hazards_hit += 1
		_revealed[pt] = true
		status_label.text = tr("MINIGAME_ASSEMBLER_HAZARD_HIT")
		Sfx.play("assembler_hazard")
	else:
		status_label.text = ""
		Sfx.play("assembler_step")
	_player_path.append(pt)
	_reveal_near(pt)
	_refresh_cell_visuals()
	_update_labels()

	if pt == _end_cell:
		var time_used: float = _time_limit - _time_remaining
		var s: float = clampf(1.0 - hazard_score_penalty * float(_hazards_hit) - time_score_penalty_weight * (time_used / _time_limit), 0.0, 1.0)
		status_label.text = tr("MINIGAME_ASSEMBLER_CIRCUIT_CLOSED")
		_finish(s)

func _process(delta: float) -> void:
	if not is_active:
		return
	_time_remaining -= delta
	var tenth: int = int(_time_remaining * 10.0)
	if tenth != _last_tenth:
		_last_tenth = tenth
		_update_labels()
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		var completion: float = float(_player_path.size() - 1) / float(maxi(1, _solution_path.size() - 1))
		_finish(timeout_completion_multiplier * clampf(completion, 0.0, 1.0))

func _update_labels() -> void:
	timer_label.text = "%.1fs" % maxf(0.0, _time_remaining)
	hazards_label.text = "%s: %d  %s: %d/%d" % [tr("MINIGAME_ASSEMBLER_HAZARDS"), _hazards_hit, tr("MINIGAME_ASSEMBLER_NODES"), _waypoints_hit(), _waypoints.size()]

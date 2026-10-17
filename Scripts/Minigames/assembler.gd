# purpose: The Assembler minigame using self-avoiding walk circuit generation to avoid warranty claims.
# depends: MinigameBase, Balance
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Assembler Mechanics")
@export var time_limit_sec: float = 25.0
@export var tier_grid_sizes: Array[int] = [5, 6, 7]
@export var hazard_density: float = 0.20
@export var hazard_score_penalty: float = 0.25
@export var time_score_penalty_weight: float = 0.40
@export var timeout_completion_multiplier: float = 0.30

@onready var grid_container: GridContainer = %GridContainer
@onready var timer_label: Label = %TimerLabel
@onready var hazards_label: Label = %HazardsLabel
@onready var status_label: Label = %StatusLabel

enum CellType { EMPTY, START_NODE, END_NODE, HAZARD }

var _tier: int = 1
var _grid_dim: int = 5
var _time_remaining: float = 25.0
var _hazards_hit: int = 0
var _start_cell: Vector2i = Vector2i(0, 2)
var _end_cell: Vector2i = Vector2i(4, 2)
var _cells: Dictionary = {} # Vector2i -> CellType
var _buttons: Dictionary = {} # Vector2i -> Button
var _solution_path: Array[Vector2i] = []
var _player_path: Array[Vector2i] = []

func setup(diff: Dictionary) -> void:
	super.setup(diff)
	_tier = diff.get("tier", 1)
	var tier_idx: int = clampi(_tier - 1, 0, 2)
	_grid_dim = tier_grid_sizes[tier_idx]
	_time_remaining = time_limit_sec
	if diff.get("speed_mult", 1.0) < 1.0:
		_time_remaining *= 1.25

func start() -> void:
	super.start()
	_hazards_hit = 0
	_player_path.clear()
	_generate_circuit_grid()
	_build_ui_grid()
	_update_labels()

func _generate_circuit_grid() -> void:
	_cells.clear()
	_solution_path.clear()
	_start_cell = Vector2i(0, randi_range(1, _grid_dim - 2))
	_end_cell = Vector2i(_grid_dim - 1, randi_range(1, _grid_dim - 2))

	# Initialize empty cells
	for y in range(_grid_dim):
		for x in range(_grid_dim):
			_cells[Vector2i(x, y)] = CellType.EMPTY

	_cells[_start_cell] = CellType.START_NODE
	_cells[_end_cell] = CellType.END_NODE

	# Guaranteed self-avoiding random walk from start to end
	var walk_success: bool = false
	for attempt in range(50):
		var path: Array[Vector2i] = [_start_cell]
		var curr: Vector2i = _start_cell
		var visited: Dictionary = {curr: true}

		while curr != _end_cell and path.size() < (_grid_dim * _grid_dim):
			var neighbors: Array[Vector2i] = []
			for dir in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0)]:
				var next: Vector2i = curr + dir
				if next.x >= 0 and next.x < _grid_dim and next.y >= 0 and next.y < _grid_dim:
					if not visited.has(next):
						neighbors.append(next)
			if neighbors.is_empty():
				break
			# Bias towards end cell
			neighbors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				return (a.distance_squared_to(_end_cell)) < (b.distance_squared_to(_end_cell))
			)
			var chosen: Vector2i = neighbors[0] if randf() < 0.60 or neighbors.size() == 1 else neighbors[1]
			visited[chosen] = true
			path.append(chosen)
			curr = chosen
			if curr == _end_cell:
				walk_success = true
				_solution_path = path
				break
		if walk_success:
			break

	if not walk_success:
		# Fallback direct path
		_solution_path = [_start_cell, Vector2i(_start_cell.x + 1, _start_cell.y), Vector2i(_end_cell.x - 1, _end_cell.y), _end_cell]

	# Place hazards off the guaranteed solution path (~20% density)
	var path_set: Dictionary = {}
	for p in _solution_path:
		path_set[p] = true

	for y in range(_grid_dim):
		for x in range(_grid_dim):
			var pt := Vector2i(x, y)
			if not path_set.has(pt) and _cells[pt] == CellType.EMPTY:
				if randf() < hazard_density:
					_cells[pt] = CellType.HAZARD

	_player_path = [_start_cell]

func _build_ui_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_buttons.clear()

	grid_container.columns = _grid_dim
	for y in range(_grid_dim):
		for x in range(_grid_dim):
			var pt := Vector2i(x, y)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(36, 36)
			btn.pressed.connect(_on_cell_clicked.bind(pt))
			grid_container.add_child(btn)
			_buttons[pt] = btn

	_refresh_cell_visuals()

func _refresh_cell_visuals() -> void:
	for y in range(_grid_dim):
		for x in range(_grid_dim):
			var pt := Vector2i(x, y)
			var btn: Button = _buttons[pt]
			var is_in_player_path: bool = _player_path.has(pt)
			var cell_type: CellType = _cells[pt]

			if pt == _start_cell:
				btn.text = "PWR"
				btn.modulate = Color(0.168, 0.513, 0.729, 1.0)
			elif pt == _end_cell:
				btn.text = "OUT"
				btn.modulate = Color(0.992, 0.682, 0.380, 1.0)
			elif is_in_player_path:
				btn.text = "●"
				btn.modulate = Color(0.168, 0.513, 0.729, 1.0)
			elif cell_type == CellType.HAZARD and _hazards_hit > 0:
				btn.text = "!"
				btn.modulate = Color(0.843, 0.098, 0.109, 1.0)
			else:
				btn.text = "+"
				btn.modulate = Color(0.8, 0.8, 0.8, 0.8)

func _on_cell_clicked(pt: Vector2i) -> void:
	if not is_active:
		return

	var last: Vector2i = _player_path.back()
	# Check if clicking previous cell to backtrack
	if _player_path.size() > 1 and pt == _player_path[_player_path.size() - 2]:
		_player_path.pop_back()
		_refresh_cell_visuals()
		return

	# Only allow adjacent cells
	var diff: Vector2i = pt - last
	var is_adj: bool = (abs(diff.x) + abs(diff.y)) == 1
	if not is_adj or _player_path.has(pt):
		return

	if _cells[pt] == CellType.HAZARD:
		_hazards_hit += 1
		status_label.text = tr("MINIGAME_ASSEMBLER_HAZARD_HIT")
	else:
		status_label.text = ""

	_player_path.append(pt)
	_refresh_cell_visuals()
	_update_labels()

	# Reached end
	if pt == _end_cell:
		var time_used: float = time_limit_sec - _time_remaining
		var s: float = clampf(1.0 - (hazard_score_penalty * float(_hazards_hit)) - (time_score_penalty_weight * (time_used / time_limit_sec)), 0.0, 1.0)
		status_label.text = tr("MINIGAME_ASSEMBLER_CIRCUIT_CLOSED")
		_finish(s)

func _process(delta: float) -> void:
	if not is_active:
		return
	_time_remaining -= delta
	_update_labels()
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		# Timeout score
		var completion: float = float(_player_path.size() - 1) / float(maxi(1, _solution_path.size() - 1))
		var s: float = timeout_completion_multiplier * clampf(completion, 0.0, 1.0)
		_finish(s)

func _update_labels() -> void:
	timer_label.text = "%.1fs" % _time_remaining
	hazards_label.text = "Hazards: %d" % _hazards_hit

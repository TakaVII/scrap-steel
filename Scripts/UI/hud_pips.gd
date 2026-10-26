# purpose: Small drawn indicator used by the HUD. Mode DAYS = 30-day track (installment days are taller), CELLS = AP battery cells (cells above the normal maximum are amber = overtime), STRIKES = strike boxes with an X. Shape carries the meaning, not only colour (colorblind rule).
# depends on: Control, GamePalette
# signals emitted: none
# signals listened to: none

class_name HudPips
extends Control

enum Mode { DAYS, CELLS, STRIKES }

@export var mode: Mode = Mode.DAYS

const COL_EMPTY: Color = Color(0.25, 0.22, 0.35, 1.0)
const COL_PAST: Color = Color(0.169, 0.514, 0.729, 0.55)

var _total: int = 1
var _value: int = 0
## DAYS: installment days. CELLS: [normal_max] so extra cells can be drawn amber.
var _marks: Array[int] = []

func set_state(value: int, total: int, marks: Array[int] = []) -> void:
	var new_total: int = maxi(1, total)
	if value == _value and new_total == _total and marks == _marks:
		return
	_value = value
	_total = new_total
	_marks = marks.duplicate()
	queue_redraw()

func _draw() -> void:
	match mode:
		Mode.DAYS:
			_draw_days()
		Mode.CELLS:
			_draw_cells()
		Mode.STRIKES:
			_draw_strikes()

func _draw_days() -> void:
	var gap: int = 1
	var pip_w: int = maxi(1, floori((size.x - float((_total - 1) * gap)) / float(_total)))
	var full_h: float = size.y
	var low_h: float = maxf(2.0, full_h - 4.0)
	for i in range(_total):
		var day: int = i + 1
		var is_mark: bool = _marks.has(day)
		var h: float = full_h if (is_mark or day == _value) else low_h
		var col: Color = COL_EMPTY
		if day == _value:
			col = GamePalette.NEON_CYAN
		elif is_mark:
			col = GamePalette.ACCENT if day > _value else COL_PAST
		elif day < _value:
			col = COL_PAST
		draw_rect(Rect2(float(i * (pip_w + gap)), size.y - h, float(pip_w), h), col)

func _draw_cells() -> void:
	var cw: float = 7.0
	var gap: float = 1.0
	var h: float = minf(size.y, 8.0)
	var y: float = floorf((size.y - h) * 0.5)
	var base: int = _marks[0] if not _marks.is_empty() else _total
	for i in range(_total):
		var r := Rect2(float(i) * (cw + gap), y, cw, h)
		if i < _value:
			var col: Color = GamePalette.NEON_CYAN if i < base else GamePalette.ACCENT
			draw_rect(r, col)
			draw_rect(Rect2(r.position.x + 1.0, r.position.y + 1.0, cw - 2.0, 1.0), Color(1, 1, 1, 0.5))
		else:
			draw_rect(r, COL_EMPTY, false, 1.0)

func _draw_strikes() -> void:
	var s: float = 8.0
	var gap: float = 2.0
	var y: float = floorf((size.y - s) * 0.5)
	for i in range(_total):
		var r := Rect2(float(i) * (s + gap), y, s, s)
		if i < _value:
			draw_rect(r, GamePalette.NEGATIVE)
			draw_line(r.position + Vector2(2, 2), r.end - Vector2(2, 2), Color.WHITE, 1.0)
			draw_line(Vector2(r.end.x - 2.0, r.position.y + 2.0), Vector2(r.position.x + 2.0, r.end.y - 2.0), Color.WHITE, 1.0)
		else:
			draw_rect(r, COL_EMPTY, false, 1.0)

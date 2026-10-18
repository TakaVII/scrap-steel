# purpose: [v2] Append daily economy snapshots to user://telemetry.csv and provide web export retrieval inspection.
# depends on: EventBus, EconomyManager, TimeManager, CommissionManager
# signals emitted: none
# signals listened to: EventBus.night_summary_ready, EventBus.commission_delivered, EventBus.day_started
extends Node

const TELEMETRY_PATH: String = "user://telemetry.csv"
const CSV_HEADER: String = "day,credits,debt,revenue,materials,fines,rent,interest,ap_used,avg_score,jobs_delivered\n"

var _jobs_delivered_today: int = 0
var _quality_scores_today: Array[float] = []

func _ready() -> void:
	EventBus.night_summary_ready.connect(_on_night_summary_ready)
	EventBus.commission_delivered.connect(_on_commission_delivered)
	EventBus.day_started.connect(_on_day_started)
	_ensure_csv_file()

func _ensure_csv_file() -> void:
	if not FileAccess.file_exists(TELEMETRY_PATH):
		var file: FileAccess = FileAccess.open(TELEMETRY_PATH, FileAccess.WRITE)
		if file:
			file.store_string(CSV_HEADER)
			file.flush()
			file.close()

func _on_day_started(_day: int) -> void:
	_jobs_delivered_today = 0
	_quality_scores_today.clear()

func _on_commission_delivered(_commission: Resource, quality: float, _payout: int) -> void:
	_jobs_delivered_today += 1
	_quality_scores_today.append(quality)

func _on_night_summary_ready(summary: Dictionary) -> void:
	var day: int = summary.get("day", TimeManager.day)
	var credits: int = summary.get("credits", EconomyManager.credits)
	var debt: int = summary.get("debt", EconomyManager.debt)
	var revenue: int = summary.get("revenue", 0)
	var materials: int = summary.get("materials", 0)
	var fines: int = summary.get("fines", 0)
	var rent: int = summary.get("rent", 0)
	var interest: int = summary.get("interest", 0)
	var ap_used: int = maxi(0, TimeManager.ap_max - TimeManager.ap)

	var avg_score: float = 0.0
	if not _quality_scores_today.is_empty():
		var total_q: float = 0.0
		for q in _quality_scores_today:
			total_q += q
		avg_score = total_q / _quality_scores_today.size()
	else:
		avg_score = CommissionManager.shop_rating()

	var jobs_delivered: int = _jobs_delivered_today

	_append_row(day, credits, debt, revenue, materials, fines, rent, interest, ap_used, avg_score, jobs_delivered)

func _append_row(day: int, credits: int, debt: int, revenue: int, materials: int, fines: int, rent: int, interest: int, ap_used: int, avg_score: float, jobs_delivered: int) -> void:
	var file: FileAccess
	if FileAccess.file_exists(TELEMETRY_PATH):
		file = FileAccess.open(TELEMETRY_PATH, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	else:
		file = FileAccess.open(TELEMETRY_PATH, FileAccess.WRITE)
		if file:
			file.store_string(CSV_HEADER)

	if file:
		var line: String = "%d,%d,%d,%d,%d,%d,%d,%d,%d,%.2f,%d\n" % [
			day, credits, debt, revenue, materials, fines, rent, interest, ap_used, avg_score, jobs_delivered
		]
		file.store_string(line)
		file.flush()
		file.close()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() and not OS.has_feature("editor"):
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_F9:
			print_telemetry_debug()

func print_telemetry_debug() -> void:
	var global_path: String = ProjectSettings.globalize_path(TELEMETRY_PATH)
	var size_bytes: int = _get_csv_size()
	print("==================================================")
	print("[TELEMETRY RECORDER] Daily Economy Telemetry Status")
	print("Local File Path: ", global_path)
	print("Engine Virtual Path: ", TELEMETRY_PATH)
	print("Current CSV File Size: ", size_bytes, " bytes")
	print("Columns: day,credits,debt,revenue,materials,fines,rent,interest,ap_used,avg_score,jobs_delivered")
	print("--- HOW TO RETRIEVE TELEMETRY IN WEB BUILDS ---")
	print("1. In Godot HTML5 / Web exports, user:// is mapped to Emscripten IDBFS at '/userfs'.")
	print("2. Open Browser DevTools (F12) -> Application/Storage Tab -> IndexedDB -> '/userfs'.")
	print("3. Or run directly in DevTools JavaScript Console:")
	print("   FS.readFile('/userfs/telemetry.csv', { encoding: 'utf8' })")
	print("4. To copy into clipboard via JavaScript console:")
	print("   copy(FS.readFile('/userfs/telemetry.csv', { encoding: 'utf8' }))")
	print("==================================================")

func _get_csv_size() -> int:
	if FileAccess.file_exists(TELEMETRY_PATH):
		var f: FileAccess = FileAccess.open(TELEMETRY_PATH, FileAccess.READ)
		if f:
			var len_bytes: int = f.get_length()
			f.close()
			return len_bytes
	return 0

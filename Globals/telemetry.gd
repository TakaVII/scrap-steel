# purpose: [v3] Daily economy snapshots to user://telemetry.csv (ap_used now comes from the day totals) and one line per finished part to user://minigame_scores.csv (use it to calibrate minigame difficulty against balance_sim.py skill levels). F9 is handled by DebugCheats.
# depends on: EventBus, EconomyManager, TimeManager, CommissionManager, PartResult
# signals emitted: none
# signals listened to: EventBus.night_summary_ready, EventBus.commission_delivered, EventBus.day_started, EventBus.minigame_finished
extends Node

const TELEMETRY_PATH: String = "user://telemetry.csv"
const SCORES_PATH: String = "user://minigame_scores.csv"
const CSV_HEADER: String = "day,credits,debt,revenue,materials,fines,rent,interest,ap_used,avg_score,jobs_delivered\n"
const SCORES_HEADER: String = "day,minigame_type,tier,score\n"

var _jobs_delivered_today: int = 0
var _quality_scores_today: Array[float] = []

func _ready() -> void:
	EventBus.night_summary_ready.connect(_on_night_summary_ready)
	EventBus.commission_delivered.connect(_on_commission_delivered)
	EventBus.day_started.connect(_on_day_started)
	EventBus.minigame_finished.connect(_on_minigame_finished)

func _on_day_started(_day: int) -> void:
	_jobs_delivered_today = 0
	_quality_scores_today.clear()

func _on_commission_delivered(_commission: Resource, quality: float, _payout: int) -> void:
	_jobs_delivered_today += 1
	_quality_scores_today.append(quality)

func _on_minigame_finished(result: RefCounted) -> void:
	var r: PartResult = result as PartResult
	if r == null or r.part == null or r.commission == null:
		return
	_append_line(SCORES_PATH, SCORES_HEADER, "%d,%d,%d,%.3f\n" % [TimeManager.day, int(r.part.minigame_type), r.commission.tier, r.score])

func _on_night_summary_ready(summary: Dictionary) -> void:
	var avg_score: float = CommissionManager.shop_rating()
	if not _quality_scores_today.is_empty():
		var total_q: float = 0.0
		for q in _quality_scores_today:
			total_q += q
		avg_score = total_q / _quality_scores_today.size()
	var line: String = "%d,%d,%d,%d,%d,%d,%d,%d,%d,%.2f,%d\n" % [
		int(summary.get("day", TimeManager.day)), int(summary.get("credits", EconomyManager.credits)),
		int(summary.get("debt", EconomyManager.debt)), int(summary.get("revenue", 0)),
		int(summary.get("materials", 0)), int(summary.get("fines", 0)), int(summary.get("rent", 0)),
		int(summary.get("interest", 0)), int(summary.get("ap_used", 0)), avg_score, _jobs_delivered_today
	]
	_append_line(TELEMETRY_PATH, CSV_HEADER, line)

func _append_line(path: String, header: String, line: String) -> void:
	var file: FileAccess
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(header)
	if file:
		file.store_string(line)
		file.flush()
		file.close()

func print_telemetry_debug() -> void:
	print("==================================================")
	print("[TELEMETRY] ", ProjectSettings.globalize_path(TELEMETRY_PATH), " (", _size(TELEMETRY_PATH), " bytes)")
	print("[TELEMETRY] ", ProjectSettings.globalize_path(SCORES_PATH), " (", _size(SCORES_PATH), " bytes)")
	print("Web build: DevTools console -> FS.readFile('/userfs/telemetry.csv', { encoding: 'utf8' })")
	print("           and FS.readFile('/userfs/minigame_scores.csv', { encoding: 'utf8' })")
	print("==================================================")

func _size(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	var n: int = f.get_length()
	f.close()
	return n

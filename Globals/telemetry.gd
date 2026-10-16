# purpose: Developer telemetry recorder logging daily economy snapshots to compare with balance_sim.py.
# depends on: EventBus, EconomyManager, TimeManager
# signals emitted: none
# signals listened to: EventBus.night_summary_ready

extends Node

var log_records: Array[Dictionary] = []

func _ready() -> void:
	EventBus.night_summary_ready.connect(_on_night_summary_ready)

func _on_night_summary_ready(summary: Dictionary) -> void:
	var entry: Dictionary = {
		"day": summary.get("day", 0),
		"credits": summary.get("credits", 0),
		"debt": summary.get("debt", 0),
		"revenue": summary.get("revenue", 0),
		"materials": summary.get("materials", 0),
		"rent": summary.get("rent", 0),
		"interest": summary.get("interest", 0),
		"net_profit": summary.get("revenue", 0) - summary.get("materials", 0) - summary.get("rent", 0) - summary.get("interest", 0)
	}
	log_records.append(entry)

func export_csv() -> String:
	var lines: Array[String] = ["day,credits,debt,revenue,materials,rent,interest,net_profit"]
	for r in log_records:
		lines.append("%d,%d,%d,%d,%d,%d,%d,%d" % [
			r["day"], r["credits"], r["debt"], r["revenue"], r["materials"], r["rent"], r["interest"], r["net_profit"]
		])
	return "\n".join(lines)

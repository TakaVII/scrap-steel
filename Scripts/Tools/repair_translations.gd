# purpose: Repairs Data/translations.csv INSIDE Godot (no Python needed) and adds every v8/v9 key (en, es, ar) from _reference/tools/translation_keys_v9.json. Fixes rows cut at unquoted commas, drops the old tutorial keys, keeps everything else, writes a backup (translations.csv.bak), and reimports the CSV. Run: open this file in the Script editor, File > Run (Ctrl+Shift+X). Safe to run again.
# depends on: EditorScript
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

const CSV_PATH: String = "res://Data/translations.csv"
const BACKUP_PATH: String = "res://Data/translations.csv.bak"
const JSON_PATH: String = "res://_reference/tools/translation_keys_v9.json"

func _run() -> void:
	print("=== repair_translations ===")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(JSON_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("Could not read ", JSON_PATH, " (is it in the project?)")
		return
	var new_keys: Dictionary = parsed["keys"]
	var deprecated: Array = parsed["deprecated"]

	var text: String = FileAccess.get_file_as_string(CSV_PATH)
	if text == "":
		printerr("Could not read ", CSV_PATH)
		return
	var rows: Array = []
	var seen: Dictionary = {}
	var bad: Array = []
	for raw_line in text.split("\n"):
		var line: String = raw_line.trim_suffix("\r")
		var stripped: String = line.strip_edges()
		if stripped == "" or stripped.begins_with("#"):
			continue
		var key: String = line.split(",", true, 1)[0].strip_edges()
		if key == "keys" or deprecated.has(key):
			continue
		if new_keys.has(key):
			if not seen.has(key):
				rows.append([key, new_keys[key][0], new_keys[key][1], new_keys[key][2]])
				seen[key] = true
			continue
		var cells: PackedStringArray = _parse_line(line)
		if cells.size() != 4:
			bad.append("%s (%d columns)" % [key, cells.size()])
			continue
		if not seen.has(key):
			rows.append([cells[0], cells[1], cells[2], cells[3]])
			seen[key] = true
	if not bad.is_empty():
		printerr("NOT WRITTEN. These rows still have the wrong number of columns (an unquoted comma). Fix them by hand or send them to Claude:")
		for b in bad:
			printerr("  ", b)
		return
	var added: int = 0
	for key in new_keys.keys():
		if not seen.has(key):
			rows.append([key, new_keys[key][0], new_keys[key][1], new_keys[key][2]])
			seen[key] = true
			added += 1

	DirAccess.copy_absolute(ProjectSettings.globalize_path(CSV_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
	var out: FileAccess = FileAccess.open(CSV_PATH, FileAccess.WRITE)
	if out == null:
		printerr("Could not write ", CSV_PATH)
		return
	out.store_csv_line(PackedStringArray(["keys", "en", "es", "ar"]))
	for r in rows:
		out.store_csv_line(PackedStringArray(r))
	out.close()
	print("OK: %d keys written (%d added). Backup: %s" % [rows.size(), added, BACKUP_PATH])
	EditorInterface.get_resource_filesystem().reimport_files(PackedStringArray([CSV_PATH]))
	print("CSV reimported. Run check_translations.gd to confirm 0 problems.")

## Minimal CSV line parser (comma separated, double quotes, "" escapes a quote).
func _parse_line(line: String) -> PackedStringArray:
	var cells := PackedStringArray()
	var cur: String = ""
	var in_quotes: bool = false
	var i: int = 0
	while i < line.length():
		var c: String = line[i]
		if in_quotes:
			if c == "\"":
				if i + 1 < line.length() and line[i + 1] == "\"":
					cur += "\""
					i += 1
				else:
					in_quotes = false
			else:
				cur += c
		else:
			if c == "\"":
				in_quotes = true
			elif c == ",":
				cells.append(cur)
				cur = ""
			else:
				cur += c
		i += 1
	cells.append(cur)
	return cells

# purpose: EditorScript that applies _reference/tools/translation_patch_v11.json to Data/translations.csv INSIDE Godot. Replaces the text of existing keys, adds new keys, removes the keys listed as deprecated, keeps every other row, writes a backup (translations.csv.bak) and reimports the CSV. Uses Godot's own CSV reader/writer, so quotes and commas are always correct. Run: open this file in the Script editor, File > Run (Ctrl+Shift+X). Safe to run again.
# depends on: EditorScript
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

const CSV_PATH: String = "res://Data/translations.csv"
const BACKUP_PATH: String = "res://Data/translations.csv.bak"
const PATCH_PATH: String = "res://_reference/tools/translation_patch_v11.json"

func _run() -> void:
	print("=== apply_translation_patch ===")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATCH_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("Could not read ", PATCH_PATH)
		return
	var patch_keys: Dictionary = parsed["keys"]
	var deprecated: Array = parsed["deprecated"]

	var f: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		printerr("Could not open ", CSV_PATH)
		return
	var header: PackedStringArray = f.get_csv_line()
	var order: Array[String] = []
	var rows: Dictionary = {}
	var line_no: int = 1
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		line_no += 1
		if row.size() == 1 and row[0].strip_edges() == "":
			continue
		if row.size() != header.size():
			printerr("NOT WRITTEN. Line %d (%s) has %d columns, expected %d. Run check_translations.gd first." % [line_no, row[0], row.size(), header.size()])
			return
		var key: String = row[0].strip_edges()
		if not rows.has(key):
			order.append(key)
		rows[key] = row
	f.close()

	var replaced: int = 0
	var added: int = 0
	for key in patch_keys.keys():
		var cells: Array = patch_keys[key]
		var new_row := PackedStringArray([key, cells[0], cells[1], cells[2]])
		if rows.has(key):
			replaced += 1
		else:
			order.append(key)
			added += 1
		rows[key] = new_row
	var removed: int = 0
	for key in deprecated:
		if rows.has(key):
			rows.erase(key)
			order.erase(key)
			removed += 1

	DirAccess.copy_absolute(ProjectSettings.globalize_path(CSV_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
	var out: FileAccess = FileAccess.open(CSV_PATH, FileAccess.WRITE)
	if out == null:
		printerr("Could not write ", CSV_PATH)
		return
	out.store_csv_line(header)
	for key in order:
		out.store_csv_line(rows[key])
	out.close()
	print("OK: %d replaced, %d added, %d removed. %d rows total. Backup: %s" % [replaced, added, removed, order.size(), BACKUP_PATH])
	EditorInterface.get_resource_filesystem().reimport_files(PackedStringArray([CSV_PATH]))
	print("CSV reimported. Run check_translations.gd: it should report 0 problems.")

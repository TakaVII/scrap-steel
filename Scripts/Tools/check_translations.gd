# purpose: EditorScript that finds out why translations do not apply. Run it from the Script editor: File > Run (Ctrl+Shift+X). It parses Data/translations.csv the way Godot's importer does (reports broken rows with line numbers, duplicate keys, empty cells), then checks every entry in Project Settings > Localization > Translations (exists? how many messages? does HUD_DAY resolve?) and whether the CSV has been imported.
# depends on: EditorScript
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

const CSV_PATH: String = "res://Data/translations.csv"
const IMPORT_PATH: String = "res://Data/translations.csv.import"
const SETTING: String = "internationalization/locale/translations"

func _run() -> void:
	print("=== check_translations ===")
	_check_csv()
	_check_project_setting()
	_check_import_file()
	print("=== done ===")

func _check_csv() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		printerr("CSV not found: ", CSV_PATH)
		return
	var f: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	var header: PackedStringArray = f.get_csv_line()
	print("CSV header: ", header)
	if header.size() < 2 or header[0].strip_edges() != "keys":
		printerr("PROBLEM: the first row must be exactly: keys,en,es,ar (a '#' comment line above it breaks the import)")
	var seen: Dictionary = {}
	var line_no: int = 1
	var ok_rows: int = 0
	var problems: int = 0
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		line_no += 1
		if row.size() == 1 and row[0].strip_edges() == "":
			continue
		var key: String = row[0].strip_edges()
		if row.size() != header.size():
			problems += 1
			printerr("PROBLEM line %d (%s): %d columns, expected %d (unquoted comma?)" % [line_no, key, row.size(), header.size()])
			continue
		if seen.has(key):
			problems += 1
			printerr("PROBLEM line %d: duplicate key %s (first seen on line %d)" % [line_no, key, seen[key]])
		seen[key] = line_no
		for i in range(1, row.size()):
			if row[i].strip_edges() == "":
				problems += 1
				printerr("PROBLEM line %d (%s): empty %s cell" % [line_no, key, header[i]])
		ok_rows += 1
	f.close()
	print("CSV rows OK: %d, problems: %d" % [ok_rows, problems])

func _check_project_setting() -> void:
	var list: PackedStringArray = ProjectSettings.get_setting(SETTING, PackedStringArray())
	if list.is_empty():
		printerr("PROBLEM: Project Settings > Localization > Translations is EMPTY. Add the three translations.<locale>.translation files.")
		return
	print("Registered translations: ", list)
	for p in list:
		if not ResourceLoader.exists(p):
			printerr("PROBLEM: %s is registered but the file does not exist. Reimport the CSV." % p)
			continue
		var t: Translation = load(p) as Translation
		if t == null:
			printerr("PROBLEM: %s did not load as a Translation." % p)
			continue
		print("  %s -> locale %s, %d messages, HUD_DAY = '%s'" % [p, t.locale, t.get_message_count(), str(t.get_message(&"HUD_DAY"))])

func _check_import_file() -> void:
	if not FileAccess.file_exists(IMPORT_PATH):
		printerr("PROBLEM: %s does not exist: the CSV was never imported. Select the CSV in the FileSystem dock and press Reimport." % IMPORT_PATH)
		return
	var text: String = FileAccess.get_file_as_string(IMPORT_PATH)
	if not text.contains("dest_files"):
		printerr("PROBLEM: the .import file lists no dest_files: the last import FAILED. Look at the Output panel when you press Reimport.")
	else:
		print("Import file looks fine (dest_files present).")

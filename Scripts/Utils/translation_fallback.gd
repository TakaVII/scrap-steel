# purpose: Safety net for translations. If the imported .translation files are not working (a CSV import error, or the files are not listed in Project Settings > Localization), this loads res://Data/translations.csv directly at startup, prints exactly which rows are broken, and registers the translations. If the imported files already work it does nothing.
# depends on: RefCounted, TranslationServer, FileAccess
# signals emitted: none
# signals listened to: none
#
# Exported builds: the CSV is not exported by default. If the warning below appears in the web build,
# add *.csv to Project > Export > Resources > "Filters to export non-resource files".

class_name TranslationFallback
extends RefCounted

const CSV_PATH: String = "res://Data/translations.csv"
const PROBE_KEY: StringName = &"HUD_DAY"

static func ensure_loaded() -> void:
	if String(TranslationServer.translate(PROBE_KEY)) != String(PROBE_KEY):
		return # the imported translations work
	push_warning("TranslationFallback: imported translations are NOT active. Loading %s directly. Check Project Settings > Localization > Translations and reimport the CSV." % CSV_PATH)
	if not FileAccess.file_exists(CSV_PATH):
		push_warning("TranslationFallback: %s not found (exported builds: add *.csv to the export filters)." % CSV_PATH)
		return
	var f: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		push_warning("TranslationFallback: could not open %s." % CSV_PATH)
		return
	var header: PackedStringArray = f.get_csv_line()
	if header.size() < 2:
		push_warning("TranslationFallback: header row has fewer than 2 columns: %s" % str(header))
		return
	var tables: Array[Translation] = []
	for i in range(1, header.size()):
		var t := Translation.new()
		t.locale = header[i].strip_edges()
		tables.append(t)
	var line_no: int = 1
	var keys_loaded: int = 0
	var bad_rows: int = 0
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		line_no += 1
		if row.size() == 1 and row[0].strip_edges() == "":
			continue
		var key: String = row[0].strip_edges()
		if key == "" or key.begins_with("#"):
			continue
		if row.size() != header.size():
			bad_rows += 1
			push_warning("translations.csv line %d (%s): expected %d columns but found %d (an unquoted comma?)" % [line_no, key, header.size(), row.size()])
			continue
		for i in range(1, row.size()):
			tables[i - 1].add_message(StringName(key), StringName(row[i].c_unescape()))
		keys_loaded += 1
	f.close()
	for t in tables:
		TranslationServer.add_translation(t)
	print("TranslationFallback: loaded %d keys for locales %s (%d broken rows skipped)." % [keys_loaded, str(header.slice(1)), bad_rows])

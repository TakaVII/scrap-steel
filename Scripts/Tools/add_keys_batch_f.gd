# purpose: EditorScript that ADDS the translation keys of Batch F to Data/translations.csv (en, es, ar) and reimports it. Existing keys are never changed (only missing ones are appended), a backup is written to translations.csv.bak_f, and nothing is written if any current row has the wrong number of columns. Run: open this file in the Script editor, File > Run (Ctrl+Shift+X). Safe to run again. es/ar are machine-translated.
# depends on: EditorScript
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

const CSV_PATH: String = "res://Data/translations.csv"
const BACKUP_PATH: String = "res://Data/translations.csv.bak_f"

const NEW_KEYS: Dictionary = {
	"BTN_SELECT": ["Select", "Elegir", "اختيار"],
	"END_RANK": ["Rank", "Rango", "الرتبة"],
	"MENU_SUBTITLE": ["ASTRA CITY GARAGE", "TALLER DE ASTRA CITY", "ورشة مدينة أسترا"],
	"WORKSHOP_OVERTIME_SHORT": ["Overtime +2 AP", "Horas extra +2 PA", "عمل إضافي +2"],
	"PAUSE_TITLE": ["Paused", "En pausa", "متوقف مؤقتاً"],
	"PAUSE_RESUME": ["Resume", "Continuar", "استئناف"],
	"PAUSE_QUIT": ["Quit game", "Salir del juego", "الخروج من اللعبة"],
	"PAUSE_HINT": ["Progress is saved every morning.", "El progreso se guarda cada mañana.", "يُحفظ التقدم كل صباح."],
	"PAUSE_HINT_MINIGAME": ["Finish the part to go back to the menu.", "Termina la pieza para volver al menú.", "أنهِ القطعة للعودة إلى القائمة."],
	"LEDGER_CAT_INCOME": ["Income", "Ingreso", "إيراد"],
	"LEDGER_CAT_MATERIALS": ["Materials", "Materiales", "مواد"],
	"LEDGER_CAT_RENT": ["Rent", "Alquiler", "إيجار"],
	"LEDGER_CAT_OVERTIME": ["Overtime", "Horas extra", "إضافي"],
	"LEDGER_CAT_FINE": ["Fine", "Multa", "غرامة"],
	"LEDGER_CAT_REFUND": ["Refund", "Reembolso", "تعويض"],
	"LEDGER_CAT_DEBT": ["Debt", "Deuda", "دين"],
	"LEDGER_CAT_DEBT_ADDED": ["New debt", "Deuda nueva", "دين جديد"],
	"LEDGER_CAT_UPGRADE": ["Upgrade", "Mejora", "ترقية"],
	"LEDGER_CAT_INFO": ["Info", "Info", "معلومة"],
}

func _run() -> void:
	print("=== add_keys_batch_f ===")
	var f: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		printerr("Could not open ", CSV_PATH)
		return
	var header: PackedStringArray = f.get_csv_line()
	var rows: Array[PackedStringArray] = []
	var existing: Dictionary = {}
	var bad: Array[String] = []
	var line_no: int = 1
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		line_no += 1
		if row.size() == 1 and row[0].strip_edges() == "":
			continue
		if row.size() != header.size():
			bad.append("line %d (%s): %d columns" % [line_no, row[0], row.size()])
			continue
		rows.append(row)
		existing[row[0]] = true
	f.close()
	if not bad.is_empty():
		printerr("NOT WRITTEN. Fix these rows first (run repair_translations.gd):")
		for b in bad:
			printerr("  ", b)
		return

	var added: int = 0
	for key in NEW_KEYS.keys():
		if existing.has(key):
			continue
		var v: Array = NEW_KEYS[key]
		rows.append(PackedStringArray([key, v[0], v[1], v[2]]))
		added += 1
	if added == 0:
		print("Nothing to add: every key already exists.")
		return

	DirAccess.copy_absolute(ProjectSettings.globalize_path(CSV_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
	var out: FileAccess = FileAccess.open(CSV_PATH, FileAccess.WRITE)
	if out == null:
		printerr("Could not write ", CSV_PATH)
		return
	out.store_csv_line(header)
	for r in rows:
		out.store_csv_line(r)
	out.close()
	print("OK: %d keys added (%d rows total). Backup: %s" % [added, rows.size(), BACKUP_PATH])
	EditorInterface.get_resource_filesystem().reimport_files(PackedStringArray([CSV_PATH]))
	print("CSV reimported. Run check_translations.gd to confirm 0 problems.")

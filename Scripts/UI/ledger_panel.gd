# purpose: [v5] Ledger (today's money in and out, filterable). v5: now opened with the quick_ledger action (L) from main.gd, rows are appended instead of rebuilding everything per entry, cleared every morning, filters translated, plain +/- marks instead of font-dependent glyphs.
# depends on: Control, EventBus, NumberFormat, GamePalette
# signals emitted: none
# signals listened to: EventBus.ledger_entry_added, EventBus.day_started
# note: FilterOptionButton.item_selected and CloseButton.pressed are connected in ledger_panel.tscn.

extends Control

const MAX_ENTRIES: int = 150

@onready var entries_container: VBoxContainer = %EntriesContainer
@onready var filter_option_button: OptionButton = %FilterOptionButton

var all_entries: Array[Dictionary] = []
var current_filter: StringName = &"ALL"

func _ready() -> void:
	EventBus.ledger_entry_added.connect(_on_ledger_entry_added)
	EventBus.day_started.connect(_on_day_started)
	EventBus.locale_changed.connect(_on_locale_changed)
	_setup_filters()

func _setup_filters() -> void:
	filter_option_button.clear()
	filter_option_button.add_item(tr("LEDGER_F_ALL"), 0)
	filter_option_button.add_item(tr("LEDGER_F_INCOME"), 1)
	filter_option_button.add_item(tr("LEDGER_F_MATERIALS"), 2)
	filter_option_button.add_item(tr("LEDGER_F_RENT"), 3)
	filter_option_button.add_item(tr("LEDGER_F_FINES"), 4)
	filter_option_button.add_item(tr("LEDGER_F_DEBT"), 5)

func _on_locale_changed(_loc: String) -> void:
	_setup_filters()

func _on_day_started(_day: int) -> void:
	all_entries.clear()
	_rebuild_display()

func _on_ledger_entry_added(description: String, amount: int, category: StringName) -> void:
	var entry: Dictionary = {"desc": description, "amt": amount, "cat": category}
	all_entries.append(entry)
	if all_entries.size() > MAX_ENTRIES:
		all_entries.pop_front()
		_rebuild_display()
		return
	if _matches(category):
		entries_container.add_child(_make_row(entry))

func _matches(category: StringName) -> bool:
	var cat: String = String(category).to_lower()
	match current_filter:
		&"income":
			return cat == "income"
		&"materials":
			return cat == "materials"
		&"rent":
			return cat == "rent" or cat == "overtime"
		&"fine":
			return cat == "fine" or cat == "refund"
		&"debt":
			return cat == "debt" or cat == "debt_added"
	return true

func _rebuild_display() -> void:
	for child in entries_container.get_children():
		entries_container.remove_child(child)
		child.queue_free()
	for entry in all_entries:
		if _matches(entry["cat"]):
			entries_container.add_child(_make_row(entry))

func _make_row(entry: Dictionary) -> HBoxContainer:
	var amount: int = int(entry["amt"])
	var positive: bool = amount > 0
	var good: bool = positive and String(entry["cat"]) != "debt_added"
	var color: Color = GamePalette.POSITIVE if good else GamePalette.NEGATIVE
	var row := HBoxContainer.new()

	var cat_label := Label.new()
	cat_label.text = "[%s]" % String(entry["cat"]).to_upper()
	cat_label.custom_minimum_size = Vector2(80, 0)
	row.add_child(cat_label)

	var desc_label := Label.new()
	desc_label.text = String(entry["desc"])
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.clip_text = true
	row.add_child(desc_label)

	var amt_label := Label.new()
	amt_label.text = ("+" if positive else "") + NumberFormat.format_credits(amount)
	amt_label.add_theme_color_override("font_color", color)
	row.add_child(amt_label)
	return row

func _on_filter_option_button_item_selected(index: int) -> void:
	match index:
		0:
			current_filter = &"ALL"
		1:
			current_filter = &"income"
		2:
			current_filter = &"materials"
		3:
			current_filter = &"rent"
		4:
			current_filter = &"fine"
		5:
			current_filter = &"debt"
	_rebuild_display()

func _on_close_button_pressed() -> void:
	visible = false

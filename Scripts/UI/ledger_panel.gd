# purpose: [v4] Financial ledger with redundant shape icons ([✓] income, [✗] expense, [▲] penalty) and GamePalette (spec §C10).
# depends on: Control, EventBus, NumberFormat, GamePalette
# signals emitted: none
# signals listened to: EventBus.ledger_entry_added

extends Control

@onready var entries_container: VBoxContainer = %EntriesContainer
@onready var filter_option_button: OptionButton = %FilterOptionButton

var all_entries: Array[Dictionary] = []
var current_filter: StringName = &"ALL"

func _ready() -> void:
	EventBus.ledger_entry_added.connect(_on_ledger_entry_added)
	_setup_filters()

func _setup_filters() -> void:
	filter_option_button.clear()
	filter_option_button.add_item("All Categories", 0)
	filter_option_button.add_item("Income [✓]", 1)
	filter_option_button.add_item("Materials [✗]", 2)
	filter_option_button.add_item("Lease / Rent [▲]", 3)
	filter_option_button.add_item("Fines & Fees [✗]", 4)
	filter_option_button.add_item("Debt Payments [✓]", 5)

func _on_ledger_entry_added(description: String, amount: int, category: StringName) -> void:
	all_entries.append({
		"desc": description,
		"amt": amount,
		"cat": category
	})
	_rebuild_display()

func _rebuild_display() -> void:
	for child in entries_container.get_children():
		child.queue_free()

	for entry in all_entries:
		var cat_str: String = str(entry["cat"]).to_lower()
		if current_filter != &"ALL":
			if current_filter == &"income" and cat_str != "income": continue
			elif current_filter == &"materials" and cat_str != "materials": continue
			elif current_filter == &"rent" and cat_str != "rent": continue
			elif current_filter == &"fine" and cat_str != "fine": continue
			elif current_filter == &"debt" and cat_str != "debt" and cat_str != "debt_added": continue

		var is_positive: bool = entry["amt"] > 0
		var row := HBoxContainer.new()

		var icon_label := Label.new()
		icon_label.text = "[✓] " if is_positive else "[✗] "
		icon_label.add_theme_color_override("font_color", GamePalette.get_color(is_positive))
		row.add_child(icon_label)

		var cat_label := Label.new()
		cat_label.text = "[%s]" % str(entry["cat"]).to_upper()
		cat_label.custom_minimum_size = Vector2(90, 0)
		row.add_child(cat_label)

		var desc_label := Label.new()
		desc_label.text = entry["desc"]
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(desc_label)

		var amt_label := Label.new()
		amt_label.text = ("+" if is_positive else "") + NumberFormat.format_credits(entry["amt"])
		amt_label.add_theme_color_override("font_color", GamePalette.get_color(is_positive))
		row.add_child(amt_label)

		entries_container.add_child(row)

func _on_filter_option_button_item_selected(index: int) -> void:
	match index:
		0: current_filter = &"ALL"
		1: current_filter = &"income"
		2: current_filter = &"materials"
		3: current_filter = &"rent"
		4: current_filter = &"fine"
		5: current_filter = &"debt"
	_rebuild_display()

func _on_close_button_pressed() -> void:
	visible = false

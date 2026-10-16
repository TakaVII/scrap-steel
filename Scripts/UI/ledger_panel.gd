# purpose: Ledger dialog displaying historical income and expenses categorized by type.
# depends: Control, EventBus
# signals emitted: none
# signals listened to: EventBus.ledger_entry_added

extends Control

@onready var entries_container: VBoxContainer = %EntriesContainer

func _ready() -> void:
	EventBus.ledger_entry_added.connect(_on_ledger_entry_added)

func _on_ledger_entry_added(description: String, amount: int, category: StringName) -> void:
	var row := HBoxContainer.new()
	var cat_label := Label.new()
	cat_label.text = "[%s]" % str(category).to_upper()
	cat_label.custom_minimum_size = Vector2(80, 0)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var amt_label := Label.new()
	amt_label.text = ("+" if amount > 0 else "") + NumberFormat.format_credits(amount)

	row.add_child(cat_label)
	row.add_child(desc_label)
	row.add_child(amt_label)
	entries_container.add_child(row)

func _on_close_button_pressed() -> void:
	visible = false

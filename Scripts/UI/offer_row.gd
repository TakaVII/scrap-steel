# purpose: One row of the morning offer list (portrait + two-line selectable button). Built from Scenes/UI/offer_row.tscn instead of code; the two lines are real Labels, so they can no longer overlap like the two-line Button text did.
# depends on: HBoxContainer, CommissionData, PortraitView, NumberFormat
# signals emitted: selected(offer_id: int)
# signals listened to: SelectButton.pressed (connected in _ready)

class_name OfferRow
extends HBoxContainer

signal selected(offer_id: int)

const PORTRAIT_PX: int = 22

@onready var portrait: PortraitView = %Portrait
@onready var select_button: Button = %SelectButton
@onready var title_label: Label = %TitleLabel
@onready var info_label: Label = %InfoLabel

var offer_id: int = -1

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)

## Call AFTER add_child (the @onready nodes must exist).
func setup(offer: CommissionData, group: ButtonGroup) -> void:
	offer_id = offer.id
	select_button.button_group = group
	portrait.setup(offer.client_id, PORTRAIT_PX)
	title_label.text = tr(offer.title_key)
	info_label.text = "T%d  %d %s  %s" % [offer.tier, offer.total_ap, tr("HUD_AP"), NumberFormat.format_credits(offer.base_payout)]
	select_button.tooltip_text = title_label.text

func set_selected(on: bool) -> void:
	select_button.set_pressed_no_signal(on)

func _on_select_pressed() -> void:
	selected.emit(offer_id)

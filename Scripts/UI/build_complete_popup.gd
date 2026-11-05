# purpose: The "YOU FINISHED THE BUILD!" moment. Shown the instant the Champion Build is registered (entry fee paid): dark dim, a burst of sparks, the panel pops in, the quality counts up, stamp + upgrade sounds and a shake. Lives in the ModalLayer of main.tscn and listens to EventBus.champion_build_completed by itself. Click Continue, press Esc or Enter to close.
# depends on: Control, EventBus, GameManager, CommissionData, NumberFormat, Juice, Sfx, SettingsManager, GamePalette
# signals emitted: none
# signals listened to: EventBus.champion_build_completed

extends Control

@onready var burst: CPUParticles2D = %Burst
@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var item_label: Label = %ItemLabel
@onready var sub_label: Label = %SubLabel
@onready var quality_label: Label = %QualityLabel
@onready var fee_label: Label = %FeeLabel
@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.champion_build_completed.connect(_on_champion_build_completed)

func _on_champion_build_completed(commission: Resource, quality: float, fee: int) -> void:
	var data: CommissionData = commission as CommissionData
	item_label.text = tr(data.title_key) if data != null else ""
	sub_label.text = tr("BUILD_DONE_MECH") if GameManager.pathway == &"mech" else tr("BUILD_DONE_DRIFT")
	fee_label.text = NumberFormat.render(tr("BUILD_DONE_FEE"), {"fee": NumberFormat.format_credits(fee)})
	quality_label.text = tr("BUILD_DONE_QUALITY") + " 0%"
	visible = true
	await get_tree().process_frame # container sizes must be real before the pivot is set
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.5, 0.5)
	panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.2)
	Juice.animate_number(self, quality_label, 0, roundi(quality * 100.0), tr("BUILD_DONE_QUALITY") + " ", "%", 0.9)
	burst.position = get_viewport_rect().size * 0.5
	burst.restart()
	burst.emitting = true
	Juice.shake(self, 4.0, 0.25)
	Sfx.play("stamp")
	Sfx.play("upgrade_buy")
	continue_button.grab_focus()

func _on_continue_button_pressed() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		visible = false

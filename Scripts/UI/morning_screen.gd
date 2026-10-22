# purpose: [v5] Morning briefing as master/detail (lists scroll, the Details numbers sit to the right of the key numbers, so nothing can push the buttons off screen). Left: compact offer rows (portrait, title, tier, AP, pay). Right: the selected offer with client portrait + greeting line, pay/AP/deadline, and (progressively disclosed) margin, pay per AP, power limit and material budget. Barter and Accept act on the selected offer.
# depends on: Control, GameManager, EconomyManager, TimeManager, CommissionManager, Balance, ClientRoster, PortraitView, NumberFormat, GamePalette
# signals emitted: none
# signals listened to: EventBus.phase_changed, BarterPanel.barter_resolved, BarterPanel.client_left

extends Control

## Day from which the advanced numbers are shown by default (the Details button can always toggle them).
const ADVANCED_FROM_DAY: int = 4
const ROW_PORTRAIT_PX: int = 22
const DETAIL_PORTRAIT_PX: int = 40

@onready var title_label: Label = %TitleLabel
@onready var bills_label: Label = %BillsLabel
@onready var banner_label: Label = %BannerLabel
@onready var offers_header: Label = %OffersHeader
@onready var offer_rows: VBoxContainer = %OfferRows
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var portrait_holder: Control = %PortraitHolder
@onready var client_name_label: Label = %ClientNameLabel
@onready var contract_title_label: Label = %ContractTitleLabel
@onready var badge_label: Label = %BadgeLabel
@onready var quote_label: Label = %QuoteLabel
@onready var key_info_label: Label = %KeyInfoLabel
@onready var advanced_label: Label = %AdvancedLabel
@onready var details_button: Button = %DetailsButton
@onready var barter_button: Button = %BarterButton
@onready var accept_button: Button = %AcceptButton
@onready var hint_label: Label = %HintLabel
@onready var open_shop_button: Button = %OpenShopButton
@onready var barter_panel: Control = %BarterPanel

var _group := ButtonGroup.new()
var _row_buttons: Dictionary = {} # offer id -> Button
var _selected_id: int = -1
var _portrait: PortraitView
var _show_advanced: bool = false

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	barter_panel.barter_resolved.connect(_on_barter_resolved)
	barter_panel.client_left.connect(_on_client_left)
	barter_panel.cancelled.connect(_on_barter_cancelled)
	details_button.toggled.connect(_on_details_toggled)
	barter_button.pressed.connect(_on_barter_pressed)
	accept_button.pressed.connect(_on_accept_pressed)
	open_shop_button.pressed.connect(_on_open_shop_pressed)
	_portrait = PortraitView.new()
	portrait_holder.add_child(_portrait)
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.MORNING:
		_refresh_morning_data()

func _refresh_morning_data() -> void:
	title_label.text = tr("MORNING_TITLE") + " - " + tr("HUD_DAY") + " %d" % TimeManager.day
	bills_label.text = tr("MORNING_RENT_CHARGED") + ": " + NumberFormat.format_credits(Balance.cfg.daily_rent)
	hint_label.text = tr("MORNING_HINT")
	_show_advanced = TimeManager.day >= ADVANCED_FROM_DAY
	details_button.set_pressed_no_signal(_show_advanced)
	_refresh_banner()
	_rebuild_offers()

func _refresh_banner() -> void:
	var lines: Array[String] = []
	var inst: Dictionary = EconomyManager.last_installment
	if int(inst.get("day", -1)) == TimeManager.day:
		lines.append(tr("MORNING_INSTALLMENT_DUE") + ": %s / %s" % [NumberFormat.format_credits(int(inst["paid"])), NumberFormat.format_credits(int(inst["due"]))])
	if EconomyManager.strikes > 0:
		lines.append(tr("MORNING_STRIKES_WARNING") + ": %d / %d" % [EconomyManager.strikes, Balance.cfg.max_strikes])
	banner_label.visible = not lines.is_empty()
	banner_label.text = "  |  ".join(lines)
	banner_label.add_theme_color_override("font_color", GamePalette.NEGATIVE)

# ---------------------------------------------------------------- offer list

func _refresh_header() -> void:
	var talks_left: int = maxi(0, Balance.cfg.max_inspections_per_day - CommissionManager.inspections_used_today)
	offers_header.text = "%s  %s %d/%d  %s %d/%d" % [
		tr("MORNING_OFFERS"), tr("MORNING_JOBS"), CommissionManager.normal_job_count(), Balance.cfg.max_active_jobs,
		tr("MORNING_TALKS"), talks_left, Balance.cfg.max_inspections_per_day]

func _rebuild_offers() -> void:
	for child in offer_rows.get_children():
		offer_rows.remove_child(child)
		child.queue_free()
	_row_buttons.clear()
	_refresh_header()

	var offers: Array[CommissionData] = CommissionManager.offers
	if offers.is_empty():
		var empty := Label.new()
		empty.text = tr("MORNING_NO_OFFERS")
		offer_rows.add_child(empty)
		detail_panel.visible = false
		_selected_id = -1
		return
	detail_panel.visible = true

	for offer in offers:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		var face := PortraitView.new()
		face.setup(offer.client_id, ROW_PORTRAIT_PX)
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(face)
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = _group
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_text = true
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 26)
		btn.text = "%s\nT%d  %d %s  %s" % [tr(offer.title_key), offer.tier, offer.total_ap, tr("HUD_AP"), NumberFormat.format_credits(offer.base_payout)]
		btn.pressed.connect(_select.bind(offer.id))
		row.add_child(btn)
		offer_rows.add_child(row)
		_row_buttons[offer.id] = btn

	var keep: int = _selected_id if _row_buttons.has(_selected_id) else offers[0].id
	_select(keep)

func _select(offer_id: int) -> void:
	_selected_id = offer_id
	for id in _row_buttons.keys():
		(_row_buttons[id] as Button).set_pressed_no_signal(id == offer_id)
	var offer: CommissionData = _find_offer(offer_id)
	if offer != null:
		_show_detail(offer)

func _find_offer(offer_id: int) -> CommissionData:
	for o in CommissionManager.offers:
		if o.id == offer_id:
			return o
	return null

# ---------------------------------------------------------------- detail

func _show_detail(offer: CommissionData) -> void:
	var has_client: bool = ClientRoster.get_client(offer.client_id).size() > 0
	portrait_holder.visible = has_client
	client_name_label.visible = has_client
	quote_label.visible = has_client
	if has_client:
		_portrait.setup(offer.client_id, DETAIL_PORTRAIT_PX)
		client_name_label.text = ClientRoster.display_name(offer.client_id)
		quote_label.text = "\"" + tr(ClientRoster.line_key(offer.client_id, "GREET")) + "\""
	contract_title_label.text = tr(offer.title_key)

	var type_key: String = "TYPE_CAR"
	var type_color: Color = GamePalette.ACCENT
	if offer.type == CommissionData.Type.MECH:
		type_key = "TYPE_MECH"
		type_color = GamePalette.NEON_CYAN
	elif offer.type == CommissionData.Type.CYBER:
		type_key = "TYPE_CYBER"
		type_color = GamePalette.NEON_MAGENTA
	badge_label.text = "T%d  %s" % [offer.tier, tr(type_key)]
	badge_label.add_theme_color_override("font_color", type_color)

	key_info_label.text = "%s: %s\n%s: %d %s\n%s: %d %s" % [
		tr("OFFER_PAY"), NumberFormat.format_credits(offer.base_payout),
		tr("OFFER_WORK"), offer.total_ap, tr("HUD_AP"),
		tr("OFFER_DEADLINE"), offer.deadline_days, tr("COMMON_DAYS")]

	var nominal_materials: int = roundi(offer.total_ap * Balance.cfg.payout_per_ap[offer.tier - 1] * Balance.cfg.material_cost_fraction)
	var margin: float = float(offer.base_payout - nominal_materials) / float(maxi(1, offer.base_payout))
	var per_ap: int = roundi(float(offer.base_payout) / float(maxi(1, offer.total_ap)))
	advanced_label.text = "%s: ~%d%%\n%s: %s\n%s: < %d W\n%s: %s" % [
		tr("OFFER_MARGIN"), roundi(margin * 100.0),
		tr("OFFER_PER_AP"), NumberFormat.format_credits(per_ap),
		tr("OFFER_POWER"), int(offer.power_limit_watts),
		tr("OFFER_BUDGET"), NumberFormat.format_credits(offer.budget_cap)]
	advanced_label.visible = _show_advanced

func _on_details_toggled(pressed: bool) -> void:
	_show_advanced = pressed
	advanced_label.visible = pressed

# ---------------------------------------------------------------- actions

func _on_barter_pressed() -> void:
	var offer: CommissionData = _find_offer(_selected_id)
	if offer == null:
		return
	if not barter_panel.open_for_offer(offer):
		hint_label.text = tr("MORNING_NEGOTIATIONS_USED")
		return
	_refresh_header()

func _on_barter_cancelled() -> void:
	_rebuild_offers() # the pay may have changed during the talk

## The client walked out of the negotiation: the offer is gone.
func _on_client_left(_offer_id: int, client_name: String) -> void:
	hint_label.text = NumberFormat.render(tr("NEG_LEFT"), {"name": client_name})
	_selected_id = -1
	_rebuild_offers()

func _on_accept_pressed() -> void:
	_try_accept(_selected_id, CommissionData.Barter.NONE)

func _on_barter_resolved(offer_id: int, choice: int) -> void:
	_try_accept(offer_id, choice)

func _try_accept(offer_id: int, choice: int) -> void:
	if offer_id < 0:
		return
	if not CommissionManager.accept_offer(offer_id, choice):
		hint_label.text = tr("MORNING_MAX_JOBS")
		return
	hint_label.text = tr("MORNING_HINT")
	_selected_id = -1
	_rebuild_offers()

func _on_open_shop_pressed() -> void:
	GameManager.begin_workshop()

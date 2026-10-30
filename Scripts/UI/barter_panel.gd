# purpose: [v4] Negotiation + contract terms. The player asks the client for +10/20/30% pay (odds depend on the client's mood, flex and CEILING: asking above the ceiling is an insult), then picks ONE contract term from the menu THIS client offers (each client offers different terms with different numbers) and signs. A live deal preview shows pay, budget, deadline and deposit for the chosen term. Opening a NEW negotiation uses one of the day's talks; reopening one already started is free.
# depends on: Control, CommissionData, CommissionManager, ClientRoster, PortraitView, Negotiation, BarterTerms, NumberFormat, GamePalette, Sfx
# signals emitted: barter_resolved(offer_id, choice), client_left(offer_id, client_name), cancelled()
# signals listened to: EventBus.day_started

extends Control

signal barter_resolved(offer_id: int, choice: int)
signal client_left(offer_id: int, client_name: String)
signal cancelled()

const PIP_SIZE: Vector2 = Vector2(8, 8)
const PIP_ON: Color = Color(0.992, 0.682, 0.38, 1.0)
const PIP_OFF: Color = Color(0.25, 0.22, 0.32, 1.0)
const TERM_BUTTON_WIDTH: float = 100.0

@onready var portrait_holder: Control = %PortraitHolder
@onready var name_label: Label = %NameLabel
@onready var mood_text_label: Label = %MoodTextLabel
@onready var pips_box: HBoxContainer = %PipsBox
@onready var rounds_label: Label = %RoundsLabel
@onready var quote_label: Label = %QuoteLabel
@onready var deal_label: Label = %DealLabel
@onready var ask10_button: Button = %Ask10Button
@onready var ask20_button: Button = %Ask20Button
@onready var ask30_button: Button = %Ask30Button
@onready var counter_button: Button = %CounterButton
@onready var terms_flow: HFlowContainer = %TermsFlow
@onready var term_desc_label: Label = %TermDescLabel
@onready var preview_label: Label = %PreviewLabel
@onready var walk_button: Button = %WalkButton
@onready var sign_button: Button = %SignButton

## offer id -> {"mood": int, "rounds": int, "bonus": int (percent won), "orig": int (original pay), "counter": int (percent offered), "quote": String}
var _states: Dictionary = {}
var _offer: CommissionData
var _term: int = CommissionData.Barter.NONE
var _term_group := ButtonGroup.new()
var _portrait: PortraitView
var _pips: Array[ColorRect] = []
var ask_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	ask_buttons.append(ask10_button)
	ask_buttons.append(ask20_button)
	ask_buttons.append(ask30_button)
	EventBus.day_started.connect(_on_day_started)
	_portrait = PortraitView.new()
	portrait_holder.add_child(_portrait)
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	for i in range(Negotiation.MAX_MOOD):
		var pip := ColorRect.new()
		pip.custom_minimum_size = PIP_SIZE
		pips_box.add_child(pip)
		_pips.append(pip)
	for i in range(ask_buttons.size()):
		ask_buttons[i].pressed.connect(_on_ask_pressed.bind(i))
	counter_button.pressed.connect(_on_counter_pressed)
	sign_button.pressed.connect(_on_sign_pressed)
	walk_button.pressed.connect(_on_walk_pressed)

func _on_day_started(_day: int) -> void:
	_states.clear()

## Returns false when the day's talks are used up (nothing opens).
func open_for_offer(offer: CommissionData) -> bool:
	if not _states.has(offer.id):
		if CommissionManager.inspections_used_today >= Balance.cfg.max_inspections_per_day:
			return false
		CommissionManager.inspections_used_today += 1
		_states[offer.id] = {
			"mood": ClientRoster.start_mood(offer.client_id),
			"rounds": Negotiation.MAX_ROUNDS,
			"bonus": 0,
			"orig": offer.base_payout,
			"counter": 0,
			"quote": tr("NEG_OPEN"),
		}
	_offer = offer
	_term = CommissionData.Barter.NONE
	_rebuild_terms()
	visible = true
	_refresh()
	return true

func _state() -> Dictionary:
	return _states[_offer.id]

# ---------------------------------------------------------------- terms menu (different for every client)

func _rebuild_terms() -> void:
	for child in terms_flow.get_children():
		terms_flow.remove_child(child)
		child.queue_free()
	for term in BarterTerms.available(_offer.client_id):
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = _term_group
		b.text = tr(BarterTerms.name_key(term))
		b.clip_text = true
		b.custom_minimum_size = Vector2(TERM_BUTTON_WIDTH, 20)
		b.pressed.connect(_set_term.bind(term))
		terms_flow.add_child(b)
		if term == CommissionData.Barter.NONE:
			b.set_pressed_no_signal(true)

func _set_term(choice: int) -> void:
	_term = choice
	_refresh_term_text()

func _refresh_term_text() -> void:
	term_desc_label.text = BarterTerms.describe(_offer, _term)
	var t: Dictionary = BarterTerms.apply(_offer, _term)
	var bits: Array[String] = []
	bits.append("%s: %s" % [tr("OFFER_PAY"), NumberFormat.format_credits(int(t["payout"]))])
	bits.append("%s: %s" % [tr("OFFER_BUDGET"), NumberFormat.format_credits(int(t["budget"]))])
	bits.append("%s: %d %s" % [tr("OFFER_DEADLINE"), int(t["deadline_days"]), tr("COMMON_DAYS")])
	if int(t["deposit"]) > 0:
		bits.append("+%s %s" % [NumberFormat.format_credits(int(t["deposit"])), tr("NEG_NOW")])
	preview_label.text = "  |  ".join(bits)

# ---------------------------------------------------------------- display

func _refresh() -> void:
	var st: Dictionary = _state()
	var has_client: bool = not ClientRoster.get_client(_offer.client_id).is_empty()
	portrait_holder.visible = has_client
	if has_client:
		_portrait.setup(_offer.client_id, 40)
	name_label.text = ClientRoster.display_name(_offer.client_id) if has_client else ""
	var mood: int = int(st["mood"])
	mood_text_label.text = tr("NEG_MOOD") + ": " + tr("NEG_MOOD_%d" % clampi(mood, 1, 3))
	for i in range(_pips.size()):
		_pips[i].color = PIP_ON if i < mood else PIP_OFF
	rounds_label.text = tr("NEG_ROUNDS") + " " + str(int(st["rounds"]))
	quote_label.text = String(st["quote"])
	deal_label.text = "%s: %s  |  %s: %d %s  |  %s: %s" % [
		tr("OFFER_PAY"), NumberFormat.format_credits(_offer.base_payout),
		tr("OFFER_DEADLINE"), _offer.deadline_days, tr("COMMON_DAYS"),
		tr("OFFER_BUDGET"), NumberFormat.format_credits(_offer.budget_cap)]

	var rating: float = Negotiation.current_rating()
	var has_bonus: bool = int(st["bonus"]) > 0
	for i in range(ask_buttons.size()):
		var pct: int = Negotiation.ASK_STEPS[i]
		var o: Dictionary = Negotiation.odds(i, mood, _offer.tier, rating, has_bonus, _offer.client_id)
		ask_buttons[i].text = NumberFormat.render(tr("NEG_ASK"), {"pct": pct}) + " - " + tr(Negotiation.odds_label_key(float(o["accept"])))
		ask_buttons[i].disabled = int(st["rounds"]) <= 0 or pct <= int(st["bonus"])
	var counter_pct: int = int(st["counter"])
	counter_button.visible = counter_pct > 0
	if counter_pct > 0:
		counter_button.text = NumberFormat.render(tr("NEG_ACCEPT_COUNTER"), {"pct": counter_pct})
	_refresh_term_text()

# ---------------------------------------------------------------- negotiation

func _apply_bonus(pct: int) -> void:
	var st: Dictionary = _state()
	st["bonus"] = pct
	_offer.base_payout = roundi(float(st["orig"]) * (1.0 + float(pct) / 100.0))
	_offer.budget_cap = roundi(_offer.base_payout * Balance.cfg.budget_cap_fraction)

func _on_ask_pressed(idx: int) -> void:
	var st: Dictionary = _state()
	if int(st["rounds"]) <= 0:
		st["quote"] = tr("NEG_NO_ROUNDS")
		_refresh()
		return
	st["rounds"] = int(st["rounds"]) - 1
	var pct: int = Negotiation.ASK_STEPS[idx]
	var o: Dictionary = Negotiation.odds(idx, int(st["mood"]), _offer.tier, Negotiation.current_rating(), int(st["bonus"]) > 0, _offer.client_id)
	var result: StringName = Negotiation.roll(o)
	var counter_pct: int = Negotiation.counter_pct(idx, _offer.client_id)
	if result == &"counter" and counter_pct <= int(st["bonus"]):
		result = &"refuse" # a counter that is not better than what you already won is a refusal
	st["counter"] = 0
	if result == &"accept":
		_apply_bonus(pct)
		st["quote"] = NumberFormat.render(tr("NEG_OK"), {"pct": pct})
		Sfx.play("credit_coin")
	elif result == &"counter":
		st["counter"] = counter_pct
		st["quote"] = NumberFormat.render(tr("NEG_COUNTER"), {"pct": counter_pct})
		Sfx.play("ui_click")
	else:
		var insult: bool = Negotiation.is_over_ceiling(idx, _offer.client_id)
		st["mood"] = int(st["mood"]) - (2 if insult else 1)
		Sfx.play("warning")
		if int(st["mood"]) <= 0:
			_client_walks_away()
			return
		if insult:
			st["quote"] = tr("NEG_INSULT")
		else:
			st["quote"] = tr("NEG_REFUSE_LAST") if int(st["mood"]) == 1 else tr("NEG_REFUSE")
	_refresh()

func _on_counter_pressed() -> void:
	var st: Dictionary = _state()
	var pct: int = int(st["counter"])
	if pct > int(st["bonus"]):
		_apply_bonus(pct)
	st["counter"] = 0
	st["quote"] = NumberFormat.render(tr("NEG_OK"), {"pct": pct})
	Sfx.play("credit_coin")
	_refresh()

func _client_walks_away() -> void:
	var offer_id: int = _offer.id
	var who: String = ClientRoster.display_name(_offer.client_id)
	CommissionManager.offers.erase(_offer)
	_states.erase(offer_id)
	visible = false
	client_left.emit(offer_id, who)

func _on_sign_pressed() -> void:
	visible = false
	barter_resolved.emit(_offer.id, _term)

func _on_walk_pressed() -> void:
	visible = false
	cancelled.emit()

# purpose: [v4 manual fix] Offers, barter, delivery payout (separate ledger lines), warranty, Champion Build, rating, and save/restore serialization.
# depends on: Balance, EventBus, EconomyManager, TimeManager, UpgradeManager, CraftingManager, ItemPartData, CommissionData, CommissionState
# signals emitted: EventBus.commission_accepted, commission_delivered, commission_failed, warranty_claim_charged
# signals listened to: none

extends Node

const PART_FILES: Dictionary = {
	ItemPartData.Archetype.MOTOR: "motor",
	ItemPartData.Archetype.CARBURETOR: "carburetor",
	ItemPartData.Archetype.COMPUTER_CHIP: "computer_chip",
	ItemPartData.Archetype.CAR_CHASSIS: "car_chassis",
	ItemPartData.Archetype.MECH_CHASSIS: "mech_chassis",
	ItemPartData.Archetype.ARMOR_PLATING: "armor_plating",
	ItemPartData.Archetype.HYDRAULIC_SERVO: "hydraulic_servo",
	ItemPartData.Archetype.SYNTH_LIMB: "synth_limb",
	ItemPartData.Archetype.NEURAL_CHIP: "neural_chip",
	ItemPartData.Archetype.SERVO_ACTUATOR: "servo_actuator",
	ItemPartData.Archetype.POWER_CELL: "power_cell",
}
# Fallback only when Data/Parts/*.tres is missing: [ap_cost, minigame_type, base_watts] (spec E1)
const FALLBACK_PARTS: Dictionary = {
	ItemPartData.Archetype.MOTOR: [2, ItemPartData.MinigameType.CALIBRATE, 120.0],
	ItemPartData.Archetype.CARBURETOR: [2, ItemPartData.MinigameType.CALIBRATE, 90.0],
	ItemPartData.Archetype.COMPUTER_CHIP: [1, ItemPartData.MinigameType.ASSEMBLE, 40.0],
	ItemPartData.Archetype.CAR_CHASSIS: [2, ItemPartData.MinigameType.FORGE, 0.0],
	ItemPartData.Archetype.MECH_CHASSIS: [2, ItemPartData.MinigameType.FORGE, 0.0],
	ItemPartData.Archetype.ARMOR_PLATING: [2, ItemPartData.MinigameType.FORGE, 0.0],
	ItemPartData.Archetype.HYDRAULIC_SERVO: [2, ItemPartData.MinigameType.CALIBRATE, 140.0],
	ItemPartData.Archetype.SYNTH_LIMB: [2, ItemPartData.MinigameType.FORGE, 30.0],
	ItemPartData.Archetype.NEURAL_CHIP: [1, ItemPartData.MinigameType.ASSEMBLE, 25.0],
	ItemPartData.Archetype.SERVO_ACTUATOR: [2, ItemPartData.MinigameType.CALIBRATE, 80.0],
	ItemPartData.Archetype.POWER_CELL: [1, ItemPartData.MinigameType.ASSEMBLE, 20.0],
}

var current_pathway: StringName = &"mech"
var offers: Array[CommissionData] = []
var active_contracts: Array[CommissionState] = []
## Each claim: {"day_due": int, "amount": int, "commission": CommissionData}
var pending_warranty_claims: Array[Dictionary] = []
var delivered_qualities: Array[float] = []
var inspections_used_today: int = 0
var champion_completed: bool = false
var champion_registration_paid: bool = false
var champion_contract: CommissionState = null
var _next_id: int = 1
var _archetypes_cache: Dictionary = {}

func _ready() -> void:
	_load_archetypes()

func new_run() -> void:
	offers.clear()
	active_contracts.clear()
	pending_warranty_claims.clear()
	delivered_qualities.clear()
	champion_completed = false
	champion_registration_paid = false
	champion_contract = null
	inspections_used_today = 0
	_next_id = 1

func set_pathway(p: StringName) -> void:
	current_pathway = p

func _load_archetypes() -> void:
	for arch in PART_FILES.keys():
		var path: String = "res://Data/Parts/%s.tres" % PART_FILES[arch]
		if ResourceLoader.exists(path):
			_archetypes_cache[arch] = load(path) as ItemPartData
			continue
		var spec: Array = FALLBACK_PARTS[arch]
		var fb := ItemPartData.new()
		fb.part_id = StringName(PART_FILES[arch])
		fb.display_key = "PART_" + String(PART_FILES[arch]).to_upper()
		fb.archetype = arch
		fb.ap_cost = spec[0]
		fb.minigame_type = spec[1]
		fb.base_power_watts = spec[2]
		_archetypes_cache[arch] = fb

func _part_for(arch: int) -> ItemPartData:
	return _archetypes_cache.get(arch) as ItemPartData

# ---------------------------------------------------------------- offers

func generate_offers(day: int) -> void:
	offers.clear()
	inspections_used_today = 0
	var count: int = Balance.cfg.offers_per_day
	if UpgradeManager.has_upgrade(&"client_rolodex"):
		count += 1
	for i in range(count):
		offers.append(_create_procedural_offer(day))
	if _champion_should_exist(day):
		_create_champion_contract()

func _champion_should_exist(day: int) -> bool:
	var path_ok: bool = current_pathway == &"mech" or current_pathway == &"drifter"
	return path_ok and champion_contract == null and not champion_completed \
			and day >= Balance.cfg.champion_unlock_day and day <= Balance.cfg.champion_deadline_day

func _create_champion_contract() -> void:
	var champ := CommissionData.new()
	champ.id = 999
	champ.is_champion_build = true
	champ.tier = 3
	champ.deadline_days = Balance.cfg.champion_deadline_day - Balance.cfg.champion_unlock_day
	champ.type = CommissionData.Type.MECH if current_pathway == &"mech" else CommissionData.Type.CAR
	champ.title_key = "CHAMPION_BUILD_TITLE_MECH" if current_pathway == &"mech" else "CHAMPION_BUILD_TITLE_DRIFT"
	champ.base_payout = 0
	champ.budget_cap = Balance.cfg.champion_build_cost_materials * 2
	champ.power_limit_watts = 600.0

	var pool: Array[int] = []
	if current_pathway == &"mech":
		pool = [ItemPartData.Archetype.MECH_CHASSIS, ItemPartData.Archetype.ARMOR_PLATING, ItemPartData.Archetype.HYDRAULIC_SERVO, ItemPartData.Archetype.MOTOR]
	else:
		pool = [ItemPartData.Archetype.CAR_CHASSIS, ItemPartData.Archetype.MOTOR, ItemPartData.Archetype.CARBURETOR, ItemPartData.Archetype.COMPUTER_CHIP]
	champ.part_archetypes = pool

	var state := CommissionState.new()
	state.data = champ
	state.tier = 3
	state.accepted_day = TimeManager.day
	state.deadline_day = Balance.cfg.champion_deadline_day
	state.budget_cap = champ.budget_cap
	state.payout = 0
	var ap_sum: int = 0
	for arch in pool:
		var p: ItemPartData = _part_for(arch)
		state.parts.append(p)
		state.part_scores.append(-1.0)
		state.part_power.append(0.0)
		ap_sum += p.ap_cost
	champ.total_ap = ap_sum
	champion_contract = state
	active_contracts.append(state)

func _create_procedural_offer(day: int) -> CommissionData:
	var data := CommissionData.new()
	data.id = _next_id
	_next_id += 1

	var roll: float = randf()
	if day <= 7:
		data.tier = 1 if roll < 0.80 else 2
	elif day <= 16:
		if roll < 0.30:
			data.tier = 1
		elif roll < 0.85:
			data.tier = 2
		else:
			data.tier = 3
	else:
		if roll < 0.10:
			data.tier = 1
		elif roll < 0.50:
			data.tier = 2
		else:
			data.tier = 3

	var favored: int = CommissionData.Type.MECH
	if current_pathway == &"reputation":
		favored = CommissionData.Type.CYBER
	elif current_pathway == &"drifter":
		favored = CommissionData.Type.CAR

	if randf() < 0.50:
		data.type = favored as CommissionData.Type
	else:
		var alt: Array[int] = []
		for t in [CommissionData.Type.CAR, CommissionData.Type.MECH, CommissionData.Type.CYBER]:
			if t != favored:
				alt.append(t)
		data.type = (alt[0] if randf() < 0.50 else alt[1]) as CommissionData.Type

	var pool: Array[int] = []
	match data.type:
		CommissionData.Type.CAR:
			pool = [ItemPartData.Archetype.MOTOR, ItemPartData.Archetype.CARBURETOR, ItemPartData.Archetype.COMPUTER_CHIP, ItemPartData.Archetype.CAR_CHASSIS]
			data.title_key = "CONTRACT_CAR_TITLE_%d" % ((data.id % 4) + 1)
		CommissionData.Type.MECH:
			pool = [ItemPartData.Archetype.MOTOR, ItemPartData.Archetype.MECH_CHASSIS, ItemPartData.Archetype.ARMOR_PLATING, ItemPartData.Archetype.HYDRAULIC_SERVO]
			data.title_key = "CONTRACT_MECH_TITLE_%d" % ((data.id % 4) + 1)
		CommissionData.Type.CYBER:
			pool = [ItemPartData.Archetype.SYNTH_LIMB, ItemPartData.Archetype.NEURAL_CHIP, ItemPartData.Archetype.SERVO_ACTUATOR, ItemPartData.Archetype.POWER_CELL]
			data.title_key = "CONTRACT_CYBER_TITLE_%d" % ((data.id % 4) + 1)

	var num_parts: int = 2 if randf() < 0.65 else 3
	var ap_sum: int = 0
	var watts_sum: float = 0.0
	for i in range(num_parts):
		var arch: int = pool[randi() % pool.size()]
		data.part_archetypes.append(arch)
		var p: ItemPartData = _part_for(arch)
		ap_sum += p.ap_cost
		watts_sum += p.base_power_watts

	data.total_ap = ap_sum
	var rate: float = Balance.cfg.payout_per_ap[data.tier - 1]
	if UpgradeManager.has_upgrade(&"client_rolodex"):
		rate *= 1.03
	data.base_payout = roundi(ap_sum * rate)
	data.budget_cap = roundi(data.base_payout * Balance.cfg.budget_cap_fraction)
	data.power_limit_watts = watts_sum * randf_range(1.04, 1.16)
	data.deadline_days = 2 if randf() < 0.70 else 3
	return data

func accept_offer(offer_id: int, barter_choice: int) -> bool:
	var normal_jobs: int = 0
	for c in active_contracts:
		if not c.data.is_champion_build:
			normal_jobs += 1
	if normal_jobs >= Balance.cfg.max_active_jobs:
		return false
	var idx: int = -1
	for i in range(offers.size()):
		if offers[i].id == offer_id:
			idx = i
			break
	if idx == -1:
		return false
	var offer: CommissionData = offers[idx]
	offers.remove_at(idx)

	var state := CommissionState.new()
	state.data = offer
	state.tier = offer.tier
	state.barter = barter_choice
	state.accepted_day = TimeManager.day
	state.deadline_day = TimeManager.day + (1 if barter_choice == CommissionData.Barter.RUSH else offer.deadline_days)
	state.budget_cap = roundi(offer.budget_cap * (0.85 if barter_choice == CommissionData.Barter.PROFIT_SHARE else 1.0))
	state.payout = offer.base_payout
	for arch in offer.part_archetypes:
		state.parts.append(_part_for(arch))
		state.part_scores.append(-1.0)
		state.part_power.append(0.0)

	if barter_choice == CommissionData.Barter.ADVANCE_DEPOSIT:
		# 20% paid now, total payout -10%. The deposit is an ADVANCE: it is subtracted at delivery.
		var deposit: int = roundi(offer.base_payout * 0.20)
		state.deposit_paid = deposit
		state.payout = roundi(offer.base_payout * 0.90)
		EconomyManager.add_credits(deposit, tr("LEDGER_BARTER_DEPOSIT"), &"income")
	elif barter_choice == CommissionData.Barter.RUSH:
		state.payout = roundi(offer.base_payout * 1.25)

	active_contracts.append(state)
	EventBus.commission_accepted.emit(offer)
	return true

func active_jobs() -> Array[CommissionState]:
	return active_contracts

# ---------------------------------------------------------------- evening

func resolve_evening(current_day: int) -> void:
	var remaining_claims: Array[Dictionary] = []
	for claim in pending_warranty_claims:
		if claim["day_due"] <= current_day:
			var amt: int = claim["amount"]
			if UpgradeManager.has_upgrade(&"warranty_insurance"):
				amt = roundi(amt * 0.50)
			var title: String = tr("LEDGER_WARRANTY_CLAIM")
			EconomyManager.charge_with_shortfall(amt, title, &"refund", title)
			EventBus.warranty_claim_charged.emit(claim["commission"], amt)
		else:
			remaining_claims.append(claim)
	pending_warranty_claims = remaining_claims

	var remaining_jobs: Array[CommissionState] = []
	for job in active_contracts:
		if job.data.is_champion_build:
			_check_champion_build_state(job, current_day)
			if not champion_completed:
				remaining_jobs.append(job)
		elif job.is_complete():
			_deliver_contract(job, current_day)
		elif current_day > job.deadline_day:
			job.late_days += 1
			if job.late_days >= 2:
				EventBus.commission_failed.emit(job.data, tr("COMMISSION_EXPIRED"))
			else:
				remaining_jobs.append(job)
		else:
			remaining_jobs.append(job)
	active_contracts = remaining_jobs

func _check_champion_build_state(job: CommissionState, current_day: int) -> void:
	if current_day > Balance.cfg.champion_deadline_day or not job.is_complete():
		return
	if job.calculate_quality() < Balance.cfg.champion_min_quality or champion_registration_paid:
		return
	if EconomyManager.try_spend(Balance.cfg.champion_build_sponsorship, tr("CHAMPION_SPONSORSHIP_PAID"), &"upgrade"):
		champion_registration_paid = true
		champion_completed = true
		job.delivered = true

func can_reforge_champion_part(part_index: int) -> bool:
	if champion_contract == null or champion_completed:
		return false
	if TimeManager.day > Balance.cfg.champion_deadline_day:
		return false
	if champion_contract.part_scores[part_index] < 0.0:
		return false
	if not champion_contract.reforging_parts.is_empty():
		return true
	return champion_contract.is_complete() and champion_contract.calculate_quality() < Balance.cfg.champion_min_quality

## Marks a finished part to be redone. AP is spent when the minigame is launched again; the redo costs only a fraction of the material cost.
func reforge_champion_part(part_index: int) -> bool:
	if not can_reforge_champion_part(part_index):
		return false
	if not champion_contract.reforging_parts.has(part_index):
		champion_contract.reforging_parts.append(part_index)
	champion_contract.part_scores[part_index] = -1.0
	champion_contract.part_power[part_index] = 0.0
	return true

static func _quality_multiplier(q: float) -> float:
	if q < 0.50:
		return 0.50
	if q < 0.75:
		return 0.85
	if q < 0.90:
		return 1.00
	return 1.10

## Order of operations (spec D8): barter -> quality -> power fine -> late penalty. Fines are separate ledger lines.
func _deliver_contract(contract: CommissionState, current_day: int) -> void:
	contract.delivered = true
	var q: float = contract.calculate_quality()
	delivered_qualities.append(q)
	while delivered_qualities.size() > Balance.cfg.rating_window:
		delivered_qualities.pop_front()

	var pay: float = float(contract.payout)
	if contract.barter == CommissionData.Barter.PROFIT_SHARE:
		if q >= 0.90:
			pay *= 1.30
		elif q < 0.75:
			pay *= 0.90
	pay *= _quality_multiplier(q)
	var gross: int = roundi(pay)

	var power_fine: int = 0
	if contract.total_power_draw() > contract.data.power_limit_watts:
		power_fine = roundi(gross * (1.0 - Balance.cfg.power_fine_mult))
	var after_power: int = gross - power_fine
	var late_fine: int = 0
	if current_day > contract.deadline_day:
		late_fine = roundi(after_power * (1.0 - Balance.cfg.late_payout_mult))
	var net: int = after_power - late_fine

	EconomyManager.add_credits(maxi(0, gross - contract.deposit_paid), tr("LEDGER_COMMISSION_PAYOUT"), &"income")
	if power_fine > 0:
		EconomyManager.charge_with_shortfall(power_fine, tr("LEDGER_POWER_FINE"), &"fine", tr("LEDGER_POWER_FINE"))
	if late_fine > 0:
		EconomyManager.charge_with_shortfall(late_fine, tr("LEDGER_LATE_PENALTY"), &"fine", tr("LEDGER_LATE_PENALTY"))
	EventBus.commission_delivered.emit(contract.data, q, net)

	EconomyManager.day_totals["jobs_delivered"] += 1
	EconomyManager.day_totals["quality_sum"] += q
	if q >= 0.90:
		EconomyManager.add_tech_points(2)
	elif q >= 0.75:
		EconomyManager.add_tech_points(1)

	# Warranty claim (spec C4): based on mean ASSEMBLE score, 0.8 when the job has none.
	var assemble_total: float = 0.0
	var assemble_count: int = 0
	for i in range(contract.parts.size()):
		if contract.parts[i].minigame_type == ItemPartData.MinigameType.ASSEMBLE:
			assemble_total += contract.part_scores[i]
			assemble_count += 1
	var avg_a: float = (assemble_total / assemble_count) if assemble_count > 0 else 0.80
	var warranty_prob: float = (1.0 - avg_a) * 0.50 + (0.40 if q < 0.50 else 0.0)
	if randf() < warranty_prob:
		pending_warranty_claims.append({
			"day_due": current_day + Balance.cfg.warranty_delay_days,
			"amount": roundi(net * Balance.cfg.warranty_cost_fraction),
			"commission": contract.data
		})

func shop_rating() -> float:
	if delivered_qualities.is_empty():
		return 0.0
	var sum_q: float = 0.0
	for q in delivered_qualities:
		sum_q += q
	return sum_q / delivered_qualities.size()

func pathway_objective_met() -> bool:
	if current_pathway == &"reputation":
		return EconomyManager.debt == 0 and EconomyManager.credits >= Balance.cfg.reserve_target and shop_rating() >= Balance.cfg.rating_five_star_quality
	if current_pathway == &"mech" or current_pathway == &"drifter":
		return EconomyManager.debt == 0 and champion_completed and champion_registration_paid
	return EconomyManager.debt == 0

# ---------------------------------------------------------------- save / restore

func _data_to_dict(d: CommissionData) -> Dictionary:
	return {
		"id": d.id, "type": d.type, "tier": d.tier, "client_id": String(d.client_id),
		"title_key": d.title_key, "archetypes": d.part_archetypes.duplicate(),
		"total_ap": d.total_ap, "base_payout": d.base_payout, "budget_cap": d.budget_cap,
		"power": d.power_limit_watts, "deadline_days": d.deadline_days, "champion": d.is_champion_build
	}

func _dict_to_data(s: Dictionary) -> CommissionData:
	var d := CommissionData.new()
	d.id = int(s.get("id", 0))
	d.type = int(s.get("type", 0)) as CommissionData.Type
	d.tier = int(s.get("tier", 1))
	d.client_id = StringName(s.get("client_id", ""))
	d.title_key = String(s.get("title_key", ""))
	for a in s.get("archetypes", []):
		d.part_archetypes.append(int(a))
	d.total_ap = int(s.get("total_ap", 0))
	d.base_payout = int(s.get("base_payout", 0))
	d.budget_cap = int(s.get("budget_cap", 0))
	d.power_limit_watts = float(s.get("power", 0.0))
	d.deadline_days = int(s.get("deadline_days", 2))
	d.is_champion_build = bool(s.get("champion", false))
	return d

func _state_to_dict(st: CommissionState) -> Dictionary:
	return {
		"data": _data_to_dict(st.data), "tier": st.tier, "barter": st.barter,
		"accepted_day": st.accepted_day, "deadline_day": st.deadline_day,
		"budget_cap": st.budget_cap, "payout": st.payout, "materials_spent": st.materials_spent,
		"part_scores": st.part_scores.duplicate(), "part_power": st.part_power.duplicate(),
		"delivered": st.delivered, "late_days": st.late_days, "deposit_paid": st.deposit_paid,
		"reforging": st.reforging_parts.duplicate()
	}

func _dict_to_state(s: Dictionary) -> CommissionState:
	var st := CommissionState.new()
	st.data = _dict_to_data(s["data"])
	st.tier = int(s.get("tier", 1))
	st.barter = int(s.get("barter", 0))
	st.accepted_day = int(s.get("accepted_day", 0))
	st.deadline_day = int(s.get("deadline_day", 0))
	st.budget_cap = int(s.get("budget_cap", 0))
	st.payout = int(s.get("payout", 0))
	st.materials_spent = int(s.get("materials_spent", 0))
	st.delivered = bool(s.get("delivered", false))
	st.late_days = int(s.get("late_days", 0))
	st.deposit_paid = int(s.get("deposit_paid", 0))
	for arch in st.data.part_archetypes:
		st.parts.append(_part_for(arch))
	for v in s.get("part_scores", []):
		st.part_scores.append(float(v))
	for v in s.get("part_power", []):
		st.part_power.append(float(v))
	for v in s.get("reforging", []):
		st.reforging_parts.append(int(v))
	return st

func serialize() -> Dictionary:
	var offers_out: Array = []
	for o in offers:
		offers_out.append(_data_to_dict(o))
	var active_out: Array = []
	for c in active_contracts:
		active_out.append(_state_to_dict(c))
	var claims_out: Array = []
	for cl in pending_warranty_claims:
		claims_out.append({"day_due": cl["day_due"], "amount": cl["amount"], "data": _data_to_dict(cl["commission"])})
	return {
		"pathway": String(current_pathway), "offers": offers_out, "active": active_out,
		"claims": claims_out, "qualities": delivered_qualities.duplicate(),
		"champion_completed": champion_completed, "champion_paid": champion_registration_paid,
		"inspections": inspections_used_today, "next_id": _next_id
	}

func restore(s: Dictionary) -> void:
	new_run()
	current_pathway = StringName(s.get("pathway", "mech"))
	for o in s.get("offers", []):
		offers.append(_dict_to_data(o))
	for a in s.get("active", []):
		active_contracts.append(_dict_to_state(a))
	for cl in s.get("claims", []):
		pending_warranty_claims.append({"day_due": int(cl["day_due"]), "amount": int(cl["amount"]), "commission": _dict_to_data(cl["data"])})
	for q in s.get("qualities", []):
		delivered_qualities.append(float(q))
	champion_completed = bool(s.get("champion_completed", false))
	champion_registration_paid = bool(s.get("champion_paid", false))
	inspections_used_today = int(s.get("inspections", 0))
	_next_id = int(s.get("next_id", 1))
	for st in active_contracts:
		if st.data.is_champion_build:
			champion_contract = st

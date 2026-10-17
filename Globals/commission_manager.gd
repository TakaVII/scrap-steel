# purpose: [v3] Commission manager with Champion Build logic, re-forge rules, and 5-star rating audits.
# depends on: Balance, EventBus, EconomyManager, TimeManager, UpgradeManager, ItemPartData, CommissionData, CommissionState, PartResult
# signals emitted: EventBus.commission_offered, commission_accepted, commission_delivered, commission_failed, warranty_claim_charged
# signals listened to: none

extends Node

var current_pathway: StringName = &"mech"
var offers: Array[CommissionData] = []
var active_contracts: Array[CommissionState] = []
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
	var map: Dictionary = {
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
		ItemPartData.Archetype.POWER_CELL: "power_cell"
	}
	for arch in map.keys():
		var path: String = "res://Data/Parts/%s.tres" % map[arch]
		if ResourceLoader.exists(path):
			_archetypes_cache[arch] = load(path) as ItemPartData
		else:
			var fallback := ItemPartData.new()
			fallback.part_id = StringName(map[arch])
			fallback.archetype = arch
			fallback.ap_cost = 2 if (arch == ItemPartData.Archetype.MOTOR or arch == ItemPartData.Archetype.CARBURETOR or arch == ItemPartData.Archetype.CAR_CHASSIS or arch == ItemPartData.Archetype.MECH_CHASSIS or arch == ItemPartData.Archetype.ARMOR_PLATING or arch == ItemPartData.Archetype.HYDRAULIC_SERVO or arch == ItemPartData.Archetype.SYNTH_LIMB or arch == ItemPartData.Archetype.SERVO_ACTUATOR) else 1
			fallback.minigame_type = ItemPartData.MinigameType.FORGE if (arch == ItemPartData.Archetype.CAR_CHASSIS or arch == ItemPartData.Archetype.MECH_CHASSIS or arch == ItemPartData.Archetype.ARMOR_PLATING or arch == ItemPartData.Archetype.SYNTH_LIMB) else (ItemPartData.MinigameType.ASSEMBLE if (arch == ItemPartData.Archetype.COMPUTER_CHIP or arch == ItemPartData.Archetype.NEURAL_CHIP or arch == ItemPartData.Archetype.POWER_CELL) else ItemPartData.MinigameType.CALIBRATE)
			fallback.base_power_watts = 50.0
			_archetypes_cache[arch] = fallback

func generate_offers(day: int) -> void:
	offers.clear()
	inspections_used_today = 0
	var count: int = Balance.cfg.offers_per_day
	if UpgradeManager.has_upgrade(&"client_rolodex"):
		count += 1

	for i in range(count):
		offers.append(_create_procedural_offer(day))

	# Champion Build generation on Day 15 for Mech/Drifter pathways
	if day == Balance.cfg.champion_unlock_day and (current_pathway == &"mech" or current_pathway == &"drifter") and not champion_contract:
		_create_champion_contract()

func _create_champion_contract() -> void:
	var champ := CommissionData.new()
	champ.id = 999
	champ.is_champion_build = true
	champ.tier = 3
	champ.deadline_days = Balance.cfg.champion_deadline_day - Balance.cfg.champion_unlock_day
	champ.type = CommissionData.Type.MECH if current_pathway == &"mech" else CommissionData.Type.CAR
	champ.title_key = "CHAMPION_BUILD_TITLE_MECH" if current_pathway == &"mech" else "CHAMPION_BUILD_TITLE_DRIFT"
	champ.base_payout = 0
	champ.budget_cap = 99999
	champ.power_limit_watts = 600.0

	var pool: Array[int] = [ItemPartData.Archetype.MECH_CHASSIS, ItemPartData.Archetype.ARMOR_PLATING, ItemPartData.Archetype.HYDRAULIC_SERVO, ItemPartData.Archetype.MOTOR] if current_pathway == &"mech" else [ItemPartData.Archetype.CAR_CHASSIS, ItemPartData.Archetype.MOTOR, ItemPartData.Archetype.CARBURETOR, ItemPartData.Archetype.COMPUTER_CHIP]
	champ.part_archetypes = pool
	champ.total_ap = 7

	var state := CommissionState.new()
	state.data = champ
	state.tier = 3
	state.accepted_day = Balance.cfg.champion_unlock_day
	state.deadline_day = Balance.cfg.champion_deadline_day
	state.budget_cap = 99999
	state.payout = 0
	for arch in pool:
		state.parts.append(_archetypes_cache.get(arch))
		state.part_scores.append(-1.0)
		state.part_power.append(0.0)
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
		if roll < 0.30: data.tier = 1
		elif roll < 0.85: data.tier = 2
		else: data.tier = 3
	else:
		if roll < 0.10: data.tier = 1
		elif roll < 0.50: data.tier = 2
		else: data.tier = 3

	var favored: int = CommissionData.Type.MECH
	if current_pathway == &"reputation": favored = CommissionData.Type.CYBER
	elif current_pathway == &"drifter": favored = CommissionData.Type.CAR

	if randf() < 0.50:
		data.type = favored
	else:
		var alt: Array[int] = []
		for t in [CommissionData.Type.CAR, CommissionData.Type.MECH, CommissionData.Type.CYBER]:
			if t != favored: alt.append(t)
		data.type = alt[0] if randf() < 0.50 else alt[1]

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
		var p: ItemPartData = _archetypes_cache.get(arch)
		ap_sum += p.ap_cost if p else 2
		watts_sum += p.base_power_watts if p else 50.0

	data.total_ap = ap_sum
	var rate: float = Balance.cfg.payout_per_ap[data.tier - 1]
	if UpgradeManager.has_upgrade(&"client_rolodex"):
		rate *= 1.03
	data.base_payout = int(round(ap_sum * rate))
	data.budget_cap = int(round(data.base_payout * Balance.cfg.budget_cap_fraction))
	data.power_limit_watts = watts_sum * randf_range(1.04, 1.16)
	data.deadline_days = 2 if randf() < 0.70 else 3
	return data

func accept_offer(offer_id: int, barter_choice: int) -> bool:
	if active_contracts.size() >= Balance.cfg.max_active_jobs:
		return false
	var idx: int = -1
	for i in range(offers.size()):
		if offers[i].id == offer_id:
			idx = i
			break
	if idx == -1: return false
	var offer: CommissionData = offers[idx]
	offers.remove_at(idx)

	var state := CommissionState.new()
	state.data = offer
	state.tier = offer.tier
	state.barter = barter_choice
	state.accepted_day = TimeManager.day
	state.deadline_day = TimeManager.day + (1 if barter_choice == CommissionData.Barter.RUSH else offer.deadline_days)
	state.budget_cap = int(round(offer.budget_cap * (0.85 if barter_choice == CommissionData.Barter.PROFIT_SHARE else 1.0)))
	state.payout = offer.base_payout

	for arch in offer.part_archetypes:
		state.parts.append(_archetypes_cache.get(arch))
		state.part_scores.append(-1.0)
		state.part_power.append(0.0)

	if barter_choice == CommissionData.Barter.ADVANCE_DEPOSIT:
		var deposit: int = int(round(offer.base_payout * 0.20))
		EconomyManager.add_credits(deposit, tr("LEDGER_BARTER_DEPOSIT"), &"income")
		state.payout = int(round(offer.base_payout * 0.90))
	elif barter_choice == CommissionData.Barter.RUSH:
		state.payout = int(round(offer.base_payout * 1.25))

	active_contracts.append(state)
	EventBus.commission_accepted.emit(offer)
	return true

func active_jobs() -> Array[CommissionState]:
	return active_contracts

func resolve_evening(current_day: int) -> void:
	var remaining_claims: Array[Dictionary] = []
	for claim in pending_warranty_claims:
		if claim["day_due"] <= current_day:
			var amt: int = claim["amount"]
			if UpgradeManager.has_upgrade(&"warranty_insurance"): amt = int(round(amt * 0.50))
			EconomyManager.try_spend(amt, tr("LEDGER_WARRANTY_CLAIM"), &"refund")
			EventBus.warranty_claim_charged.emit(claim["commission"].data, amt)
		else:
			remaining_claims.append(claim)
	pending_warranty_claims = remaining_claims

	var remaining_jobs: Array[CommissionState] = []
	for job in active_contracts:
		if job.data.is_champion_build:
			_check_champion_build_state(job)
			if not champion_completed:
				remaining_jobs.append(job)
		elif job.is_complete():
			_deliver_contract(job, current_day)
		else:
			if current_day > job.deadline_day:
				job.late_days += 1
				if job.late_days >= 2:
					EventBus.commission_failed.emit(job.data, tr("COMMISSION_EXPIRED"))
				else:
					remaining_jobs.append(job)
			else:
				remaining_jobs.append(job)
	active_contracts = remaining_jobs

func _check_champion_build_state(job: CommissionState) -> void:
	if not job.is_complete():
		return
	var q: float = job.calculate_quality()
	if q >= Balance.cfg.champion_min_quality:
		if not champion_registration_paid:
			if EconomyManager.try_spend(Balance.cfg.champion_build_sponsorship, tr("CHAMPION_SPONSORSHIP_PAID"), &"upgrade"):
				champion_registration_paid = true
				champion_completed = true
				job.delivered = true

func reforge_champion_part(part_index: int) -> bool:
	if not champion_contract or champion_completed:
		return false
	var part: ItemPartData = champion_contract.parts[part_index]
	var reforge_cost: int = int(round(part.nominal_material_cost(3) * 0.50))
	if not TimeManager.has_ap(part.ap_cost) or EconomyManager.credits < reforge_cost:
		return false
	TimeManager.spend_ap(part.ap_cost)
	EconomyManager.try_spend(reforge_cost, tr("CHAMPION_REFORGE_FEE"), &"materials")
	champion_contract.part_scores[part_index] = -1.0
	return true

func _deliver_contract(contract: CommissionState, current_day: int) -> void:
	contract.delivered = true
	var q: float = contract.calculate_quality()
	delivered_qualities.append(q)
	if delivered_qualities.size() > Balance.cfg.rating_window:
		delivered_qualities.pop_front()

	var final_payout: float = float(contract.payout)
	if contract.barter == CommissionData.Barter.PROFIT_SHARE:
		if q >= 0.90: final_payout *= 1.30
		elif q < 0.75: final_payout *= 0.90

	if q < 0.50: final_payout *= 0.50
	elif q < 0.75: final_payout *= 0.85
	elif q < 0.90: final_payout *= 1.00
	else: final_payout *= 1.10

	if contract.total_power_draw() > contract.data.power_limit_watts:
		var fine: int = int(round(final_payout * (1.0 - Balance.cfg.power_fine_mult)))
		final_payout *= Balance.cfg.power_fine_mult
		EventBus.ledger_entry_added.emit(tr("LEDGER_POWER_FINE"), -fine, &"fine")

	if current_day > contract.deadline_day:
		final_payout *= Balance.cfg.late_payout_mult

	var payout_int: int = int(round(final_payout))
	EconomyManager.add_credits(payout_int, tr("LEDGER_COMMISSION_PAYOUT"), &"income")
	EventBus.commission_delivered.emit(contract.data, q, payout_int)

	if q >= 0.90: EconomyManager.add_tech_points(2)
	elif q >= 0.75: EconomyManager.add_tech_points(1)

	var assemble_scores: Array[float] = []
	for i in range(contract.parts.size()):
		if contract.parts[i].minigame_type == ItemPartData.MinigameType.ASSEMBLE:
			assemble_scores.append(contract.part_scores[i])
	var avg_a: float = 0.80
	if not assemble_scores.is_empty():
		var sum_a: float = 0.0
		for s in assemble_scores: sum_a += s
		avg_a = sum_a / assemble_scores.size()

	var warranty_prob: float = (1.0 - avg_a) * 0.50 + (0.40 if q < 0.50 else 0.0)
	if randf() < warranty_prob:
		var claim_amt: int = int(round(payout_int * Balance.cfg.warranty_cost_fraction))
		pending_warranty_claims.append({
			"day_due": current_day + Balance.cfg.warranty_delay_days,
			"commission": contract,
			"amount": claim_amt
		})

func shop_rating() -> float:
	if delivered_qualities.is_empty(): return 1.0
	var sum_q: float = 0.0
	for q in delivered_qualities: sum_q += q
	return sum_q / delivered_qualities.size()

func pathway_objective_met() -> bool:
	if current_pathway == &"reputation":
		return EconomyManager.debt == 0 and EconomyManager.credits >= Balance.cfg.reserve_target and shop_rating() >= Balance.cfg.rating_five_star_quality
	elif current_pathway == &"mech" or current_pathway == &"drifter":
		return EconomyManager.debt == 0 and champion_completed and champion_registration_paid
	return EconomyManager.debt == 0

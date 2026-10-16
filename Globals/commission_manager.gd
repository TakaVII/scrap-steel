# purpose: Full commission system generating tiered contracts, enforcing barter options, resolving quality, power fines, and warranty claims.
# depends on: Balance, EventBus, EconomyManager, TimeManager, UpgradeManager, ItemPartData, CommissionData, CommissionState, PartResult
# signals emitted: EventBus.commission_offered, commission_accepted, commission_delivered, commission_failed, warranty_claim_charged
# signals listened to: none

extends Node

var current_pathway: StringName = &"mech"
var offers: Array[CommissionData] = []
var active_contracts: Array[CommissionState] = []
var pending_warranty_claims: Array[Dictionary] = [] # [{ "day_due": int, "commission": CommissionState, "amount": int }]
var delivered_qualities: Array[float] = [] # Last 8 deliveries for 5-star rating
var inspections_used_today: int = 0
var _next_id: int = 1
var _archetypes_cache: Dictionary = {} # Archetype -> ItemPartData

func _ready() -> void:
	_load_archetypes()

func new_run() -> void:
	offers.clear()
	active_contracts.clear()
	pending_warranty_claims.clear()
	delivered_qualities.clear()
	inspections_used_today = 0
	_next_id = 1

func set_pathway(p: StringName) -> void:
	current_pathway = p

func _load_archetypes() -> void:
	var archetypes_map: Dictionary = {
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
	for arch in archetypes_map.keys():
		var path: String = "res://Data/Parts/%s.tres" % archetypes_map[arch]
		if ResourceLoader.exists(path):
			_archetypes_cache[arch] = load(path) as ItemPartData
		else:
			# Fallback creation if EditorScript hasn't run yet
			var fallback := ItemPartData.new()
			fallback.part_id = StringName(archetypes_map[arch])
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
		var offer := _create_procedural_offer(day)
		offers.append(offer)
		EventBus.commission_offered.emit(offer)

func _create_procedural_offer(day: int) -> CommissionData:
	var data := CommissionData.new()
	data.id = _next_id
	_next_id += 1

	# 1. Tier determination based on day curve (spec §C4)
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

	# 2. Type skew based on selected pathway (50% chosen, 25% others)
	var type_roll: float = randf()
	var favored_type: int = CommissionData.Type.MECH
	if current_pathway == &"reputation": favored_type = CommissionData.Type.CYBER
	elif current_pathway == &"drifter": favored_type = CommissionData.Type.CAR

	if type_roll < 0.50:
		data.type = favored_type
	else:
		var other_types: Array[int] = []
		for t in [CommissionData.Type.CAR, CommissionData.Type.MECH, CommissionData.Type.CYBER]:
			if t != favored_type:
				other_types.append(t)
		data.type = other_types[0] if randf() < 0.50 else other_types[1]

	# 3. Archetype pools by type (spec §D6)
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
	var selected_archs: Array[int] = []
	var ap_sum: int = 0
	var base_power_sum: float = 0.0

	for i in range(num_parts):
		var arch: int = pool[randi() % pool.size()]
		selected_archs.append(arch)
		var part: ItemPartData = _archetypes_cache.get(arch)
		if part:
			ap_sum += part.ap_cost
			base_power_sum += part.base_power_watts
		else:
			ap_sum += 2
			base_power_sum += 50.0

	data.part_archetypes = selected_archs
	data.total_ap = ap_sum
	var payout_rate: float = Balance.cfg.payout_per_ap[data.tier - 1]
	if UpgradeManager.has_upgrade(&"client_rolodex"):
		payout_rate *= 1.03
	data.base_payout = int(round(ap_sum * payout_rate))
	data.budget_cap = int(round(data.base_payout * Balance.cfg.budget_cap_fraction))
	data.power_limit_watts = base_power_sum * randf_range(1.04, 1.16)
	data.deadline_days = 2 if randf() < 0.70 else 3
	return data

func can_inspect() -> bool:
	return inspections_used_today < 3

func inspect_offer(_offer_id: int) -> bool:
	if not can_inspect():
		return false
	inspections_used_today += 1
	return true

func accept_offer(offer_id: int, barter_choice: int) -> bool:
	if active_contracts.size() >= Balance.cfg.max_active_jobs:
		return false

	var offer_idx: int = -1
	for i in range(offers.size()):
		if offers[i].id == offer_id:
			offer_idx = i
			break
	if offer_idx == -1:
		return false

	var offer: CommissionData = offers[offer_idx]
	offers.remove_at(offer_idx)

	var state := CommissionState.new()
	state.data = offer
	state.tier = offer.tier
	state.barter = barter_choice
	state.accepted_day = TimeManager.day
	state.deadline_day = TimeManager.day + (1 if barter_choice == CommissionData.Barter.RUSH else offer.deadline_days)
	state.budget_cap = int(round(offer.budget_cap * (0.85 if barter_choice == CommissionData.Barter.PROFIT_SHARE else 1.0)))
	state.payout = offer.base_payout
	state.delivered = false

	# Resolve parts
	for arch in offer.part_archetypes:
		var part: ItemPartData = _archetypes_cache.get(arch)
		state.parts.append(part)
		state.part_scores.append(-1.0)
		state.part_power.append(0.0)

	# Barter A: Advance Deposit (+20% now, -10% final payout)
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

## Resolves contract deliveries, warranty claims, and late penalties at Evening
func resolve_evening(current_day: int) -> void:
	# 1. Process warranty claims due today
	var remaining_claims: Array[Dictionary] = []
	for claim in pending_warranty_claims:
		if claim["day_due"] <= current_day:
			var amount: int = claim["amount"]
			if UpgradeManager.has_upgrade(&"warranty_insurance"):
				amount = int(round(amount * 0.50))
			EconomyManager.try_spend(amount, tr("LEDGER_WARRANTY_CLAIM"), &"refund")
			EventBus.warranty_claim_charged.emit(claim["commission"].data, amount)
		else:
			remaining_claims.append(claim)
	pending_warranty_claims = remaining_claims

	# 2. Check active contracts for completed deliveries or expiry
	var remaining_contracts: Array[CommissionState] = []
	for contract in active_contracts:
		if contract.is_complete():
			_deliver_contract(contract, current_day)
		else:
			# Check deadline
			if current_day > contract.deadline_day:
				contract.late_days += 1
				if contract.late_days >= 2:
					# Cancelled job
					EventBus.commission_failed.emit(contract.data, tr("COMMISSION_EXPIRED"))
				else:
					remaining_contracts.append(contract)
			else:
				remaining_contracts.append(contract)
	active_contracts = remaining_contracts

func _deliver_contract(contract: CommissionState, current_day: int) -> void:
	contract.delivered = true
	var quality: float = contract.calculate_quality()
	delivered_qualities.append(quality)
	if delivered_qualities.size() > Balance.cfg.rating_window:
		delivered_qualities.pop_front()

	# Payout Order of Operations (spec §C4)
	# Step 1: Base payout after barter
	var final_payout: float = float(contract.payout)

	# Profit-share barter adjustment
	if contract.barter == CommissionData.Barter.PROFIT_SHARE:
		if quality >= 0.90: final_payout *= 1.30
		elif quality < 0.75: final_payout *= 0.90

	# Step 2: Quality multiplier
	if quality < 0.50: final_payout *= 0.50
	elif quality < 0.75: final_payout *= 0.85
	elif quality < 0.90: final_payout *= 1.00
	else: final_payout *= 1.10

	# Step 3: Power fine check (deterministic)
	if contract.total_power_draw() > contract.data.power_limit_watts:
		var fine: int = int(round(final_payout * (1.0 - Balance.cfg.power_fine_mult)))
		final_payout *= Balance.cfg.power_fine_mult
		EventBus.ledger_entry_added.emit(tr("LEDGER_POWER_FINE"), -fine, &"fine")

	# Step 4: Late penalty
	if current_day > contract.deadline_day:
		final_payout *= Balance.cfg.late_payout_mult

	var payout_int: int = int(round(final_payout))
	EconomyManager.add_credits(payout_int, tr("LEDGER_COMMISSION_PAYOUT"), &"income")
	EventBus.commission_delivered.emit(contract.data, quality, payout_int)

	# Award Tech Points
	if quality >= 0.90:
		EconomyManager.add_tech_points(2)
	elif quality >= 0.75:
		EconomyManager.add_tech_points(1)

	# Warranty Claim Roll (scheduled 3 days later)
	var assemble_scores: Array[float] = []
	for i in range(contract.parts.size()):
		if contract.parts[i].minigame_type == ItemPartData.MinigameType.ASSEMBLE:
			assemble_scores.append(contract.part_scores[i])

	var avg_assemble: float = 0.80
	if not assemble_scores.is_empty():
		var sum_a: float = 0.0
		for s in assemble_scores: sum_a += s
		avg_assemble = sum_a / assemble_scores.size()

	var warranty_prob: float = (1.0 - avg_assemble) * 0.50 + (0.40 if quality < 0.50 else 0.0)
	if randf() < warranty_prob:
		var claim_amt: int = int(round(payout_int * Balance.cfg.warranty_cost_fraction))
		pending_warranty_claims.append({
			"day_due": current_day + Balance.cfg.warranty_delay_days,
			"commission": contract,
			"amount": claim_amt
		})

func shop_rating() -> float:
	if delivered_qualities.is_empty():
		return 1.0
	var sum_q: float = 0.0
	for q in delivered_qualities: sum_q += q
	return sum_q / delivered_qualities.size()

func pathway_objective_met() -> bool:
	if current_pathway == &"reputation":
		return EconomyManager.debt == 0 and EconomyManager.credits >= Balance.cfg.reserve_target and shop_rating() >= Balance.cfg.rating_five_star_quality
	return EconomyManager.debt == 0

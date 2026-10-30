# purpose: [v2] Rules of the pay negotiation. The player asks for +10/20/30% pay; the client accepts, counters or refuses. Odds depend on the client's mood, shop rating, contract tier, greed (already won a bonus) AND the client's own flex and ceiling (ClientRoster). Asking above a client's ceiling is almost hopeless and an insult (mood -2). All numbers are constants here so they are easy to tune.
# depends on: RefCounted, CommissionManager, ClientRoster
# signals emitted: none
# signals listened to: none

class_name Negotiation
extends RefCounted

## Pay increase steps the player can ask for (percent).
const ASK_STEPS: Array[int] = [10, 20, 30]
## Chance the client accepts the ask outright, for a neutral client (mood 2, flex 0), rating 0.6, tier 1, no bonus yet.
const BASE_ACCEPT: Array[float] = [0.65, 0.40, 0.18]
## Chance the client counters with a smaller raise.
const COUNTER_CHANCE: Array[float] = [0.15, 0.25, 0.25]
## What the client offers when countering (percent), never above the client's ceiling.
const COUNTER_STEPS: Array[int] = [5, 10, 20]
const MAX_ROUNDS: int = 3
const MAX_MOOD: int = 3
## Each mood point above/below neutral (2) changes the accept chance by this much.
const MOOD_WEIGHT: float = 0.10
## Each 1.0 of shop rating above/below 0.6 changes the accept chance by this much.
const RATING_WEIGHT: float = 0.50
const NEUTRAL_RATING: float = 0.60
const TIER_PENALTY: float = 0.05
const GREED_PENALTY: float = 0.10
## The accept chance is multiplied by this when the ask is above the client's ceiling.
const OVER_CEILING_MULT: float = 0.12
const MIN_ACCEPT: float = 0.05
const MAX_ACCEPT: float = 0.90
## Odds labels: >= HIGH is "Likely", >= MID is "Risky", otherwise "Long shot".
const LABEL_HIGH: float = 0.60
const LABEL_MID: float = 0.35

## Shop rating (mean quality of the last deliveries); neutral until the player has delivered something.
static func current_rating() -> float:
	if CommissionManager.delivered_qualities.is_empty():
		return NEUTRAL_RATING
	return CommissionManager.shop_rating()

static func is_over_ceiling(step_idx: int, client_id: StringName) -> bool:
	return ASK_STEPS[step_idx] > ClientRoster.ceiling(client_id)

static func odds(step_idx: int, mood: int, tier: int, rating: float, has_bonus: bool, client_id: StringName) -> Dictionary:
	var accept: float = BASE_ACCEPT[step_idx]
	accept += float(mood - 2) * MOOD_WEIGHT
	accept += (rating - NEUTRAL_RATING) * RATING_WEIGHT
	accept -= float(tier - 1) * TIER_PENALTY
	accept += ClientRoster.flex(client_id)
	if has_bonus:
		accept -= GREED_PENALTY
	if is_over_ceiling(step_idx, client_id):
		accept *= OVER_CEILING_MULT
	accept = clampf(accept, MIN_ACCEPT, MAX_ACCEPT)
	var counter: float = minf(COUNTER_CHANCE[step_idx], 1.0 - accept)
	return {"accept": accept, "counter": counter, "refuse": 1.0 - accept - counter}

## Percent the client offers when countering this ask.
static func counter_pct(step_idx: int, client_id: StringName) -> int:
	return mini(COUNTER_STEPS[step_idx], ClientRoster.ceiling(client_id))

## Returns &"accept", &"counter" or &"refuse".
static func roll(o: Dictionary) -> StringName:
	var r: float = randf()
	if r < float(o["accept"]):
		return &"accept"
	if r < float(o["accept"]) + float(o["counter"]):
		return &"counter"
	return &"refuse"

static func odds_label_key(accept: float) -> String:
	if accept >= LABEL_HIGH:
		return "NEG_ODDS_HIGH"
	if accept >= LABEL_MID:
		return "NEG_ODDS_MID"
	return "NEG_ODDS_LOW"

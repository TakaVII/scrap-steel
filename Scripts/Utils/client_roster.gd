# purpose: [v2] Static roster of the 12 contract clients. v2: negotiation temper (flex, ceiling) and the contract terms each client offers, with their own numbers. Dialogue keys follow CLIENT_<ID>_GREET / _SATISFIED / _UNHAPPY in translations.csv.
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name ClientRoster
extends RefCounted

# type: 0 = CAR, 1 = MECH, 2 = CYBER (CommissionData.Type)
# mood: how patient the client is in a negotiation. 3 = friendly, 2 = neutral, 1 = impatient (walks away after one refusal).
# flex: added to the chance that the client accepts a pay raise (-0.10 stingy .. +0.10 generous).
# ceiling: the highest raise (%) the client will ever accept. Asking above it is an insult (mood -2).
# terms: contract terms offered besides Standard: deposit, profit, rush, extended, supplied.
# deposit / profit / rush: this client's numbers for those terms (share paid now, pay multiplier at quality 90%+, rush premium).
const CLIENTS: Array = [
	{"id": &"sparky", "mood": 2, "name": "Jax 'Sparky' Vane", "type": 0, "flex": 0.0, "ceiling": 20, "terms": ["deposit", "rush", "profit"], "deposit": 0.20, "profit": 1.30, "rush": 0.30},
	{"id": &"zero", "mood": 1, "name": "Cipher Zero", "type": 0, "flex": -0.10, "ceiling": 10, "terms": ["rush", "profit"], "profit": 1.25, "rush": 0.40},
	{"id": &"talia", "mood": 3, "name": "Talia Ramos", "type": 0, "flex": 0.05, "ceiling": 30, "terms": ["deposit", "extended", "supplied"], "deposit": 0.25},
	{"id": &"gideon", "mood": 2, "name": "Gideon Vex", "type": 0, "flex": 0.0, "ceiling": 20, "terms": ["profit", "rush", "extended"], "profit": 1.35, "rush": 0.25},
	{"id": &"mara", "mood": 3, "name": "Mara Chen", "type": 1, "flex": 0.05, "ceiling": 30, "terms": ["deposit", "supplied", "extended"], "deposit": 0.30},
	{"id": &"boris", "mood": 2, "name": "Boris 'Piston' Volkov", "type": 1, "flex": -0.05, "ceiling": 20, "terms": ["profit", "extended", "supplied"], "profit": 1.30},
	{"id": &"val", "mood": 1, "name": "Valerie Vance", "type": 1, "flex": -0.10, "ceiling": 10, "terms": ["rush", "deposit"], "deposit": 0.15, "rush": 0.35},
	{"id": &"ironhead", "mood": 1, "name": "Hector Ironhead", "type": 1, "flex": -0.10, "ceiling": 10, "terms": ["profit", "rush"], "profit": 1.40, "rush": 0.30},
	{"id": &"nyx", "mood": 2, "name": "Nyx Holliday", "type": 2, "flex": 0.0, "ceiling": 20, "terms": ["deposit", "profit", "rush"], "deposit": 0.20, "profit": 1.30, "rush": 0.30},
	{"id": &"seraph", "mood": 3, "name": "Unit Seraph-7", "type": 2, "flex": 0.05, "ceiling": 30, "terms": ["profit", "extended", "deposit"], "deposit": 0.25, "profit": 1.25},
	{"id": &"mira", "mood": 2, "name": "Mira Kuroda", "type": 2, "flex": 0.0, "ceiling": 20, "terms": ["supplied", "extended", "deposit"], "deposit": 0.20},
	{"id": &"juno", "mood": 3, "name": "Juno Okoro", "type": 2, "flex": 0.10, "ceiling": 30, "terms": ["deposit", "rush", "supplied", "extended"], "deposit": 0.25, "rush": 0.20},
]

static func get_client(id: StringName) -> Dictionary:
	for c in CLIENTS:
		if c["id"] == id:
			return c
	return {}

## Starting mood in a negotiation (1 impatient .. 3 friendly).
static func start_mood(id: StringName) -> int:
	return int(get_client(id).get("mood", 2))

## Added to the accept chance of a raise request.
static func flex(id: StringName) -> float:
	return float(get_client(id).get("flex", 0.0))

## Highest raise (%) this client accepts. Unknown clients (Champion Build) accept the smallest step only.
static func ceiling(id: StringName) -> int:
	return int(get_client(id).get("ceiling", 10))

## Term ids this client offers besides Standard.
static func term_ids(id: StringName) -> Array:
	return get_client(id).get("terms", [])

## This client's number for a term ("deposit", "profit", "rush"); fallback when the client has no override.
static func term_value(id: StringName, term: String, fallback: float) -> float:
	return float(get_client(id).get(term, fallback))

static func pick_for_type(type: int) -> Dictionary:
	var pool: Array = []
	for c in CLIENTS:
		if int(c["type"]) == type:
			pool.append(c)
	if pool.is_empty():
		return CLIENTS[0]
	return pool[randi() % pool.size()]

## The collector is not a client, but he speaks in dialogue.
static func display_name(id: StringName) -> String:
	if id == &"kane":
		return "Collector Kane"
	var c: Dictionary = get_client(id)
	return String(c.get("name", String(id)))

## kind: "GREET", "SATISFIED" or "UNHAPPY"
static func line_key(id: StringName, kind: String) -> String:
	return "CLIENT_%s_%s" % [String(id).to_upper(), kind]

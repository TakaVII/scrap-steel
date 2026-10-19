# purpose: Static roster of the 12 contract clients (type mapping now matches their dialogue). Replaces the runtime use of Data/Clients/*.tres. Dialogue keys follow CLIENT_<ID>_GREET / _SATISFIED / _UNHAPPY in translations.csv.
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name ClientRoster
extends RefCounted

# type: 0 = CAR, 1 = MECH, 2 = CYBER (CommissionData.Type)
const CLIENTS: Array = [
	{"id": &"sparky", "name": "Jax 'Sparky' Vane", "type": 0},
	{"id": &"zero", "name": "Cipher Zero", "type": 0},
	{"id": &"talia", "name": "Talia Ramos", "type": 0},
	{"id": &"gideon", "name": "Gideon Vex", "type": 0},
	{"id": &"mara", "name": "Mara Chen", "type": 1},
	{"id": &"boris", "name": "Boris 'Piston' Volkov", "type": 1},
	{"id": &"val", "name": "Valerie Vance", "type": 1},
	{"id": &"ironhead", "name": "Hector Ironhead", "type": 1},
	{"id": &"nyx", "name": "Nyx Holliday", "type": 2},
	{"id": &"seraph", "name": "Unit Seraph-7", "type": 2},
	{"id": &"mira", "name": "Mira Kuroda", "type": 2},
	{"id": &"juno", "name": "Juno Okoro", "type": 2},
]

static func get_client(id: StringName) -> Dictionary:
	for c in CLIENTS:
		if c["id"] == id:
			return c
	return {}

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

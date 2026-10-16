# purpose: Immutable static resource model for a generated client commission contract offer.
# depends on: Resource
# signals emitted: none
# signals listened to: none

class_name CommissionData
extends Resource

enum Type { CAR, MECH, CYBER }
enum Barter { NONE, ADVANCE_DEPOSIT, PROFIT_SHARE, RUSH }

@export var id: int
@export var type: Type
@export var tier: int = 1
@export var client_id: StringName
@export var title_key: String
@export var part_archetypes: Array[int] = [] # ItemPartData.Archetype enum ints
@export var total_ap: int
@export var base_payout: int
@export var budget_cap: int
@export var power_limit_watts: float
@export var deadline_days: int = 2
@export var is_champion_build: bool = false

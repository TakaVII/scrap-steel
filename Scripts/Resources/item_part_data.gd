# purpose: Resource class defining the specification for a component part archetype.
# depends on: Resource
# signals emitted: none
# signals listened to: none
# [v2] ap_for_tier(): AP cost now depends on the contract tier (Forge/Calibrate 1/2/3, Assemble 1/1/2). ap_cost stays the base value (used by the Champion Build).

class_name ItemPartData
extends Resource

enum Archetype {
	MOTOR,
	CARBURETOR,
	COMPUTER_CHIP,
	CAR_CHASSIS,
	MECH_CHASSIS,
	ARMOR_PLATING,
	HYDRAULIC_SERVO,
	SYNTH_LIMB,
	NEURAL_CHIP,
	SERVO_ACTUATOR,
	POWER_CELL
}

enum MinigameType {
	FORGE,
	CALIBRATE,
	ASSEMBLE
}

@export var part_id: StringName
@export var display_key: String
@export var archetype: Archetype
@export var minigame_type: MinigameType
@export var ap_cost: int = 1
@export var base_power_watts: float = 50.0
@export var icon: Texture2D

## AP cost of this part inside a normal contract of the given tier (1..3).
func ap_for_tier(tier: int) -> int:
	if minigame_type == MinigameType.ASSEMBLE:
		return 2 if tier >= 3 else 1
	return clampi(tier, 1, 3)

func nominal_material_cost(tier: int) -> int:
	var base_rate: float = Balance.cfg.payout_per_ap[tier - 1]
	return int(round(ap_for_tier(tier) * base_rate * Balance.cfg.material_cost_fraction))

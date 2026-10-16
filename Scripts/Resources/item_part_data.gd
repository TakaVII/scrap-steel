# purpose: Resource class defining the specification for a component part archetype.
# depends on: Resource
# signals emitted: none
# signals listened to: none

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

func nominal_material_cost(tier: int) -> int:
	var base_rate: float = Balance.cfg.payout_per_ap[tier - 1]
	return int(round(ap_cost * base_rate * Balance.cfg.material_cost_fraction))

# purpose: Resource specification for an R&D upgrade card with financial ROI payback metrics.
# depends on: Resource
# signals emitted: none
# signals listened to: none

class_name UpgradeData
extends Resource

@export var id: StringName
@export var title_key: String
@export var desc_key: String
@export var cost_credits: int = 800
@export var cost_tp: int = 2
@export var payback_days: float = 6.6
@export var icon: Texture2D

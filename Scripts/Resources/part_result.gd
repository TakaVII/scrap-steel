# purpose: Strongly typed result container holding the score and metrics of a completed component part.
# depends on: RefCounted, CommissionState, ItemPartData
# signals emitted: none
# signals listened to: none
# [v2] grade + quality (quality is filled by CraftingManager.apply_result)

class_name PartResult
extends RefCounted

var commission: CommissionState
var part_index: int
var part: ItemPartData
var score: float = 0.0
var power_watts: float = 0.0
var material_cost_charged: int = 0
## MaterialGrade.Grade (default Standard).
var grade: int = 1
var quality: float = 0.0

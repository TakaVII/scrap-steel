# purpose: Strongly typed result container holding the score and metrics of a completed component part.
# depends on: RefCounted, CommissionState, ItemPartData
# signals emitted: none
# signals listened to: none

class_name PartResult
extends RefCounted

var commission: CommissionState
var part_index: int
var part: ItemPartData
var score: float = 0.0
var power_watts: float = 0.0
var material_cost_charged: int = 0

# purpose: Static data resource holding client personality, dialogue lines, and preferred contract pathway.
# depends on: Resource
# signals emitted: none
# signals listened to: none

class_name ClientData
extends Resource

@export var client_id: StringName
@export var client_name: String
@export var preferred_type: int # CommissionData.Type
@export var greeting_key: String
@export var satisfied_key: String
@export var unhappy_key: String

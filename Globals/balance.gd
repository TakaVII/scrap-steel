# purpose: Autoload singleton providing access to the active BalanceConfig resource.
# depends on: BalanceConfig (res://Scripts/Resources/balance_config.gd)
# signals emitted: none
# signals listened to: none

extends Node

var cfg: BalanceConfig

func _ready() -> void:
	if ResourceLoader.exists("res://Data/balance_config.tres"):
		cfg = load("res://Data/balance_config.tres") as BalanceConfig
	if not cfg:
		push_warning("Balance: Could not load res://Data/balance_config.tres! Falling back to default instance.")
		cfg = BalanceConfig.new()

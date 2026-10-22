# purpose: [v2] Autoload singleton providing access to the active BalanceConfig resource. It is the first autoload, so it also starts the translation safety net (TranslationFallback) before any UI text is built.
# depends on: BalanceConfig (res://Scripts/Resources/balance_config.gd), TranslationFallback
# signals emitted: none
# signals listened to: none

extends Node

var cfg: BalanceConfig

func _ready() -> void:
	TranslationFallback.ensure_loaded()
	if ResourceLoader.exists("res://Data/balance_config.tres"):
		cfg = load("res://Data/balance_config.tres") as BalanceConfig
	if not cfg:
		push_warning("Balance: Could not load res://Data/balance_config.tres! Falling back to default instance.")
		cfg = BalanceConfig.new()

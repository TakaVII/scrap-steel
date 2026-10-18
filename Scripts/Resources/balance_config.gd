# purpose: Single source of truth resource definition for all gameplay balance numbers.
# depends on: Resource
# signals emitted: none
# signals listened to: none
# [v2 manual fix] added: assist preset values, max_inspections_per_day, champion_reforge_cost_fraction

class_name BalanceConfig
extends Resource

@export_group("Start")
@export var start_credits: int = 2000
@export var start_debt: int = 10000

@export_group("Assist Preset")
@export var assist_start_credits: int = 2500
@export var assist_start_debt: int = 7000
@export var assist_interest_rate: float = 0.01

@export_group("Economy")
@export var daily_interest_rate: float = 0.02
@export var daily_rent: int = 150
@export var late_fee_rate: float = 0.10
@export var seize_debt_threshold: int = 25000
@export var max_strikes: int = 3
@export var installment_days: Array[int] = [8, 15, 22, 29]
@export var installment_min: int = 400
@export var installment_pct: float = 0.08

@export_group("Time")
@export var campaign_days: int = 30
@export var base_ap: int = 6
@export var overtime_ap: int = 2
@export var overtime_cost: int = 150
@export var overtime_next_day_ap_penalty: int = 1

@export_group("Commissions")
@export var payout_per_ap: Array[float] = [304.0, 395.2, 516.8] # Tier 1, 2, 3
@export var material_cost_fraction: float = 0.50
@export var budget_cap_fraction: float = 0.65
@export var offers_per_day: int = 4
@export var max_active_jobs: int = 3
@export var max_inspections_per_day: int = 3
@export var forge_waste_reduction: float = 0.30
@export var warranty_delay_days: int = 3
@export var warranty_cost_fraction: float = 0.35
@export var late_payout_mult: float = 0.80
@export var power_fine_mult: float = 0.85

@export_group("Endings")
@export var champion_build_cost_materials: int = 7000
@export var champion_build_sponsorship: int = 2000
@export var champion_min_quality: float = 0.80
@export var champion_unlock_day: int = 15
@export var champion_deadline_day: int = 28
@export var champion_reforge_cost_fraction: float = 0.50
@export var reserve_target: int = 9000
@export var rating_five_star_quality: float = 0.80
@export var rating_window: int = 8

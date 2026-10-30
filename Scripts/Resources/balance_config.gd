# purpose: Single source of truth resource definition for all gameplay balance numbers.
# depends on: Resource
# signals emitted: none
# signals listened to: none
# [v2 manual fix] added: assist preset values, max_inspections_per_day, champion_reforge_cost_fraction
# [v3] payout_per_ap x0.90 (simulated with balance_sim_v3.py); material grades, market swing, graduated power fine, bad reviews

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
@export var payout_per_ap: Array[float] = [273.6, 355.7, 465.1] # Tier 1, 2, 3 (spec 304 / 395.2 / 516.8 x 0.90)
@export var material_cost_fraction: float = 0.50
@export var budget_cap_fraction: float = 0.65
@export var offers_per_day: int = 4
@export var max_active_jobs: int = 3
@export var max_inspections_per_day: int = 3
@export var forge_waste_reduction: float = 0.30
@export var warranty_delay_days: int = 3
@export var warranty_cost_fraction: float = 0.35
@export var late_payout_mult: float = 0.80
@export var power_fine_mult: float = 0.85 # legacy flat fine, no longer used (see power_fine_* below)

@export_group("Materials")
## Index 0 = Scrap, 1 = Standard, 2 = Premium.
@export var grade_cost_mult: Array[float] = [0.75, 1.0, 1.2]
## Minigame difficulty by grade (applied on top of the accessibility multipliers). Higher speed = harder; lower window = harder.
@export var grade_speed_mult: Array[float] = [0.9, 1.0, 1.15]
@export var grade_window_mult: Array[float] = [1.15, 1.0, 0.9]
@export var scrap_quality_cap: float = 0.68
@export var premium_quality_bonus: float = 0.08
## Added to the warranty-claim chance, multiplied by the share of Scrap parts in the job.
@export var scrap_warranty_add: float = 0.30
## Daily material price swing (+-): rolled every morning.
@export var market_swing: float = 0.15

@export_group("Penalties")
@export var power_fine_min: float = 0.05
@export var power_fine_max: float = 0.30
@export var power_fine_slope: float = 1.5
## A delivery with quality below this counts extra-badly in the shop rating.
@export var bad_review_quality: float = 0.50
@export var bad_review_penalty: float = 0.15

@export_group("Barter")
@export var deposit_pct_default: float = 0.20
## Final pay multiplier when an advance deposit was taken.
@export var deposit_final_mult: float = 0.90
@export var profit_budget_mult: float = 0.85
@export var profit_high_mult_default: float = 1.30
@export var profit_low_mult: float = 0.90
@export var rush_pct_default: float = 0.25
@export var extended_extra_days: int = 2
@export var extended_payout_mult: float = 0.90
## Client-supplied parts: material cost x this, final pay x supplied_payout_mult.
@export var supplied_cost_mult: float = 0.65
@export var supplied_payout_mult: float = 0.88

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

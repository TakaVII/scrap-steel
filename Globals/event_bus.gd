# purpose: Central decoupled signal bus for all game-wide events across economy, time, commissions, and meta.
# depends on: Node
# signals emitted: credits_changed, debt_changed, ledger_entry_added, installment_due, strike_issued, phase_changed, day_started, action_points_changed, night_summary_ready, commission_offered, commission_accepted, commission_delivered, commission_failed, warranty_claim_charged, minigame_started, minigame_finished, tech_points_changed, upgrade_purchased, run_ended, locale_changed, settings_changed
# signals listened to: none

extends Node

# --- Economy ---
signal credits_changed(new_balance: int, delta: int)
signal debt_changed(new_debt: int, delta: int)
signal ledger_entry_added(description: String, amount: int, category: StringName)
signal installment_due(day: int, amount: int)
signal strike_issued(strikes: int)

# --- Time ---
signal phase_changed(new_phase: int, old_phase: int)
signal day_started(day: int)
signal action_points_changed(current_ap: int, max_ap: int)
signal night_summary_ready(summary: Dictionary)

# --- Commissions ---
signal commission_offered(commission: Resource)
signal commission_accepted(commission: Resource)
signal commission_delivered(commission: Resource, quality: float, payout: int)
signal commission_failed(commission: Resource, reason: String)
signal warranty_claim_charged(commission: Resource, amount: int)

# --- Minigames ---
signal minigame_started(part: Resource, tier: int)
signal minigame_finished(result: RefCounted)

# --- Meta ---
signal tech_points_changed(points: int)
signal upgrade_purchased(upgrade_id: StringName)
signal run_ended(victory: bool, reason: StringName)
signal locale_changed(new_locale: String)
signal settings_changed()

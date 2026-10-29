# Batch B + C notes

## What changed in the economy (Batch C, part 1)
- **Material grade per part** (picker opens when you press a part): Scrap x0.75 cost, quality capped at 68%, easier minigame, +30% warranty-claim chance (scaled by the share of Scrap parts); Standard unchanged; Premium x1.20 cost, +8 quality points, harder minigame. The grade never changes the payout directly, only through quality (existing multipliers x0.5 / x0.85 / x1.0 / x1.1). Scrap is not allowed for the Champion Build.
- **Difficulty by grade** is applied in `minigame_controller.gd` through `speed_mult` and `window_mult` (Forge: cursor speed and time; Calibrator: target speed and bar size when easier; Assembler: time). The minigame scripts are unchanged. Premium's `window_mult` 0.9 only shortens time in Forge/Assembler (the Calibrator bar size ignores values below 1).
- **Daily material market**: +-15% every morning, shown in the workshop header and the picker. Champion Build ignores it.
- **AP by tier**: Forge/Calibrate 1/2/3 AP, Assemble 1/1/2 (T1/T2/T3). Offers' total AP and payout follow it. The Champion Build keeps the base AP.
- **Penalties you can see**: workshop shows materials vs budget, power draw vs limit ("!" when over) and current quality per contract. The power fine now scales with the overshoot (5% + 1.5 x overshoot, max 30%) and the ledger line shows the watts. A warranty claim is announced in the ledger at delivery ("expected: X on Day N"). Quality below 50% adds a bad review (rating counts quality - 0.15).
- **Payout x0.90** (`payout_per_ap` = 273.6 / 355.7 / 465.1). Simulated with balance_sim_v3.py (adaptive material policy, MECH): casual about 43% wins, good about 89%, expert about 95%. The simulator does not model the graduated power fine or minigame difficulty by grade: compare with `user://minigame_scores.csv` and `telemetry.csv` after a playtest.

## Still to come
- **C2**: barter redesign (client traits, per-client term menus, real risk).
- **D**: item blueprint preview and minigame game feel (sprites already in Batch A).
- Not touched: morning screen does not show the market price yet (it is in the workshop and the picker).

## Static checks done (no Godot available here)
Tab-only indentation, bracket balance, translation keys, unique-node names. NOT run: the game itself. See README for the test checklist.

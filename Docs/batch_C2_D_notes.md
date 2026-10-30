# Batch C2 + D notes

## C2: barter
- Each client has a temper (ClientRoster): `flex` (-0.10..+0.10 on the chance to accept a raise), `ceiling` (10/20/30: the most they will ever pay) and the TERMS they offer with their own numbers.
- Raises: base accept chances are now 65% / 40% / 18% for +10 / +20 / +30. Above a client's ceiling the chance is multiplied by 0.12 and a refusal is an insult (mood -2). A neutral client (ceiling 20) accepts +30% about 5% of the time; only friendly, generous clients (Talia, Mara, Seraph, Juno) can reach it with good odds.
- Counter-offers never exceed the client's ceiling and are ignored if they do not beat what you already won.
- Terms (menu differs per client): Standard, Deposit, Profit share, Rush, **Extended** (+2 days, final pay -10%), **Supplied** (client brings parts: materials x0.65, final pay x0.88).
- The panel shows a live deal preview (pay, budget, deadline, deposit now) for the chosen term. All term numbers live in `BalanceConfig > Barter` and `ClientRoster`.
- NOT simulated in balance_sim_v3.py: the new terms (Extended / Supplied) and per-client numbers. Watch telemetry.

## D: item preview and game feel
- **Workshop**: every contract shows a blueprint (car / mech / cyberware) that powers up as parts are finished, plus one slot per part with tier frame, material-grade badge and quality %. Quality is visible without colour: poor = rust + cracks + rattle, good = clean, excellent (90%+) = pulsing glow ring. A part that just finished snaps into its slot (scale pop, white flash, sparks, sound).
- **Minigames**: a live workpiece in the bottom-right corner of the panel. Forge: heats up and throws sparks on each strike (more for better hits). Calibrator: glows with sparks while the needle is inside the bar, vibrates when far away. Assembler: lights up with the wire, red burst on a short circuit. It reads the minigame's variables by name (`_strike_scores`, `_was_in_zone`, `_target_y`, `_bar_y`, `_bar_h`, `_player_path`, `_wire_budget`, `_hazards_hit`); if you rename them the effect just stays idle, nothing crashes.
- Needs the placeholder sprites from Batch A (or your own art with the same names). Without them it falls back to colored boxes and 3-letter labels.
- Reduced flashing turns off the pulse, flash and vibration.

## Not done yet
- Contract card preview in the morning screen (silhouette next to the offer).
- Music (no tracks yet), sprites (placeholders only).

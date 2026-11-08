# Scrap & Steel: Sprite Specification (v10)

Supersedes `Docs/sprite_spec.md` v8 and the file list in `Assets/Textures/README.txt`.
Everything is drawn by hand or taken from CC0 packs with credits. **No AI-generated art** (the jam frowns on it).

v10 was written by reading every script and scene that loads a texture (not by guessing from the old spec), so every size below is the size the code actually displays. Status values:

| Status | Meaning |
|---|---|
| **Wired** | A script loads it by filename. Drop the PNG in the right folder and it appears. No code change. |
| **Placeholder** | A PNG (and `.import`) already exists in the repo from Batch A/D. Replace the file, same name. |
| **Needs code** | Nothing loads it today. Not planned (see section 7). |

---

## Delivery status (art v1)

All 58 sprites in this inventory now exist as **working v1 files** in `Assets/Textures/`, with the exact names and sizes below (checked by script, none uses green). They were produced procedurally with the pxl pixel-art DSL, in a 16-bit indie style, so they are drop-in placeholders you can refine by hand: same filename, same size. `Docs/art_preview_v1.png` shows them all.

Extra files delivered: `icon.png` (128x128, project icon: set Project Settings > Application > Config > Icon to it), `Store/cover_630x500.png` (itch cover), `Backgrounds/light_glow.png` and `light_cone.png` (see 5.2).

**Jam note:** the jam frowns on AI-generated art. These files are code-generated, which you should disclose on the itch page, and hand-redrawing the visible ones (portraits first) is the safest route if the rules apply to you.

---

## 0. What changed since v8

1. **Three size mismatches found** between the old spec and the code (details in section 6). Sizes in this document already account for them: portraits are **40x40**, part art is **24x24**, assembler tiles stay **20x20** but need one small fix (W-1).
2. **Calibrator bar must be translucent**: the bar is drawn on top of the needle in `calibrator.tscn`. An opaque bar hides the needle exactly when the player is doing well.
3. **Part icons, tier frames, grade badges, rust/crack overlays, slot, glow ring and the three item blueprints are now Wired** (Batch D). v8 listed them as "not wired yet".
4. **Mood portraits are only needed for `mara` and `kane`** (the only characters whose mood is ever requested).
5. **Orphans found** (files exist but nothing loads them): `workpiece_*`, `fx_spark_sheet`, `icon_strike`, `icon_calendar`. Cut (section 8).
6. **Cut list rewritten** for the real calendar: today is Nov 5, the jam ends mid-November, Phase 6 feature freeze has passed. Only Wired items are planned.
7. Added **project icon / store assets**, which v8 did not cover. `icon.svg` is still the default Godot robot.

---

## 1. Visual strategy (what is art and what is not)

The UI is **UI-first**: panels, buttons, bars, tabs and cards come from the project Theme (`Assets/Themes/default_theme.tres`, `StyleBoxFlat`, 1 px neon borders, content margins 4/2 px). That is the right call for a 480x270 layout that has to survive three languages, RTL text and a 17 px font box. Do **not** replace panels with 9-slice textures now.

Sprites are used only for **content**:

| Role | Examples | Why it needs a sprite |
|---|---|---|
| Identity | client portraits, tutorial background | Narrative (spec C2): faces sell the story |
| Meaning in one glance | HUD icons, part icons, tier frames, grade badges | FinLit surfaces must read without text |
| Minigame feel | hammer, calibrator bar/needle, circuit tiles | Where "skill becomes money" is felt |
| Preview of the work | 3 item blueprints with part slots | Lote D: you see the car/mech/cyberware being built |

Everything else that moves is **code, not art**: sparks (`CPUParticles2D`), glow pulse (tween on `modulate`), screen shake, count-up numbers, hit-stop, confetti, the CRT overlay. Do not draw spark sheets or glow animations.

### Rules that follow from this

1. **Author at the size the code shows.** Godot scales with nearest filter; any non-integer scale gives uneven pixels. Section 6 lists the three places where the old sizes caused that.
2. **FX art is white/grey** (`fx_glow_ring`, overlays). The code tints it with `modulate` (cyan, magenta, red, amber).
3. **Content art is mid-tone.** `modulate` multiplies: dim (ghost `0.55`, blueprint `0.45`) or heat tint darkens it further. Avoid near-black fills on anything that is tinted.
4. **Shape carries meaning, colour reinforces** (spec C10). No green anywhere. Every state must differ by silhouette: check / cross / triangle / diamond / square.
5. **Check every asset at 2x with the CRT overlay on.** The overlay is a black layer with up to about 40% alpha at the corners; keep key information inside the central area.
6. **Pixel positions stay integer** (nothing in the art should rely on half pixels). Project stretch is `canvas_items` + integer scale; text is rasterised at window resolution, sprites at 2x nearest.

### Palette (24 colours, one shared set)

Keep the first seven exactly (they are in `GamePalette`).

| Role | Hex | Used for |
|---|---|---|
| Positive blue | `#2b83ba` | good results, credits, wire |
| Negative vermilion | `#d7191c` | debt, fines, hazards |
| Accent amber | `#fdae61` | highlights, warnings, hammer head, needle |
| Neutral text | `#e8e6f0` | text, white-ish metal |
| Background indigo | `#14111f` | darkest background, outlines |
| Neon cyan | `#00e5ff` | glow, sweet spot |
| Neon magenta | `#ff2a9d` | cyberware accent, nodes |
| Indigo 2 / 3 | `#1f1a33` / `#2c2547` | panels, deep shadows |
| Steel 1 to 5 | `#3a3f52` `#5b6078` `#8b90a8` `#c3c7d9` `#f4f3fa` | metal ramps |
| Blue ramp | `#1c5a82` `#5db2e6` | shading for blue |
| Red ramp | `#8f1a1c` `#f06a5b` | shading for vermilion |
| Amber ramp | `#a85a1b` `#ffd59a` | shading for amber, heat |
| Skin ramp | `#5a3a32` `#a86f58` `#e3b496` | portraits |
| Rust | `#7a3b22` | garage details, rust overlay |

Save it once as `scrap_steel.gpl` in your tool and never leave it.

### Global file rules

| Rule | Value |
|---|---|
| Format | PNG 32-bit with alpha, no anti-aliasing, no semi-transparent edge pixels (only where a section says so) |
| Names | `snake_case`, exactly as listed. A wrong name is silently ignored (the placeholder look stays) |
| Import (Import dock) | Filter Nearest (project default), Mipmaps off, Compress Lossless: the existing `.import` files already have this |
| Strips | Horizontal, equal frames, no padding, frame 0 = idle |
| Tool | Aseprite / LibreSprite / Piskel. Export "Sheet" as horizontal strip |
| Credits | Every CC0 asset goes into `Docs/credits.md` (itch page needs it) |

---

## 2. Master inventory

Hours are for a weak-at-art solo dev. `P0` = do first. `P1` = then. `P2` = only with leftover time (placeholders are good enough to ship).

| # | File | Folder | Size | Frames | Displayed at | Status | Pri | Est. h |
|---|---|---|---|---|---|---|---|---|
| 1 | `forge_hammer.png` | Minigames | 128x32 | 4 x 32x32 | 32x32 | Wired | P0 | 1.0 |
| 2 | `calibrator_bar.png` | Minigames | 24x24 (9-slice, margin 6) | 1 | 100 x 48/35/27 | Wired | P0 | 0.4 |
| 3 | `calibrator_needle.png` | Minigames | 40x12 | 1 | 40x12 | Wired | P0 | 0.3 |
| 4 | `tile_empty / power / output / node / node_lit / wire / hazard.png` | Minigames | 20x20 each | 1 each | 20x20 (needs W-1) | Wired | P0 | 1.5 |
| 5 | `icon_credit / debt / ap / tp.png` | UI | 10x10 each | 1 each | 10x10 | Wired | P0 | 0.5 |
| 6 | `mara.png`, `kane.png` + `_happy` / `_unhappy` of each | Portraits | 40x40 each | 1 each | 20 / 40 | Wired | P0 | 1.5 |
| 7 | `gideon.png`, `ironhead.png`, `seraph.png` (Day 12 speakers, also the car / mech / cyber archetypes) | Portraits | 40x40 each | 1 each | 20 / 40 | Wired | P1 | 1.0 |
| 8 | 9 more client portraits (palette swaps of #7, see section 4) | Portraits | 40x40 each | 1 each | 20 / 40 | Wired | P1 | 0.7 |
| 9 | `workshop_bg.png` (no baked lights) | Backgrounds | 480x270 | 1 | 480x270 | Wired | P1 | 2.0 |
| 9b | `light_glow.png`, `light_cone.png` (white light textures, in-game lighting) | Backgrounds | 64x64 / 64x96 | 1 each | integer multiples | Needs code | P2 | 0.3 |
| 10 | `icon.png` (project icon) + `Store/cover_630x500.png` | repo root / store | 128x128 / 630x500 | 1 | favicon / itch | Config | P1 | 0.5 |
| 11 | `item_blueprint_car / mech / cyber.png` | Parts | 120x80 each | 1 each | 120x80 | Placeholder | P2 | 2.5 |
| 12 | `part_<archetype>.png` x11 | Parts | 24x24 each | 1 each | 24x24 (W-3) | Placeholder | P2 | 2.75 |
| 13 | `frame_tier1_scrap / tier2_standard / tier3_prototype.png` | Parts | 24x24 each | 1 each | 24x24 | Placeholder | P2 | 0.6 |
| 14 | `badge_grade_scrap / standard / premium.png` | Parts | 12x12 each | 1 each | 12x12 | Placeholder | P2 | 0.4 |
| 15 | `overlay_rust.png`, `overlay_crack.png` | Parts | 24x24 each | 1 each | 24x24 | Placeholder | P2 | 0.3 |
| 16 | `slot_empty.png` | Parts | 28x28 | 1 | 28x28 | Placeholder | P2 | 0.1 |
| 17 | `fx_glow_ring.png` | Minigames | 24x24 | 1 | 24 and 24..48 | Placeholder | P2 | 0.1 |

**Totals:** P0 about 5.2 h, P1 about 4.2 h, P2 about 6.8 h. Plan P0 + P1 (about 9.4 h). Details and the schedule are in section 9.

---

## 3. Minigame art (P0, highest return per hour)

### 3.1 Forge: `Minigames/forge_hammer.png`

| Property | Value |
|---|---|
| Sheet | **128 x 32**, 4 frames of 32x32, horizontal |
| Loaded by | `forge.gd` through `SpriteKit.animated(...)` -> `AnimatedSprite2D` child of `StrikeBarPanel` |
| Animations (set in code) | `idle` = frame 0. `strike` = frames **1, 2, 3, 0** at **18 fps**, one shot (about 0.22 s) |
| Position (set in code) | Sprite **centre** at `(cursor centre x, -16)` relative to the bar. So the frame bottom edge sits exactly on the top of the bar |
| Hit-stop | The cursor freezes 0.06 s on a strike. Frame 2 (impact) shows 0.055 s after the strike, inside that freeze: the hit lands while the cursor is still |

| Frame | Pose |
|---|---|
| 0 idle | Hammer resting, raised up-right. Head lifted about 8 px above the bottom edge |
| 1 wind-up | Head high (about 14 to 18 px above the bottom), shortest-lived frame (55 ms) |
| 2 impact | **Hammer face touches the bottom edge** (face bottom at y = 30 or 31). Heat flash on the head in `#ffd59a` |
| 3 recoil | Bounce back, head about 4 to 6 px above the bottom |

Rules: the **head centre is at x = 16 in every frame** (the sprite follows the cursor, so the head must stay under it). Handle stays inside the frame. 1 px outline `#14111f`. Steel ramp for the head, amber only on the impact frame. **Do not draw sparks** (particles do that). The sprite sweeps the bar at several hundred px/s (faster after every strike), so keep the silhouette simple.

Scene note: the 32 px hammer overlaps the instruction label above the bar (separation is 10 px). If it covers the text, add a 24 px spacer above `StrikeBarPanel` in `forge.tscn`. That is a scene edit, not a script edit.

### 3.2 Calibrator: `calibrator_bar.png` and `calibrator_needle.png`

| File | Size | How it is used |
|---|---|---|
| `calibrator_bar.png` | **24x24**, 9-slice **margin 6** on all sides | `NinePatchRect` (`swap_panel_nine`). Shown at 100 px wide and **48 / 35 / 27 px** tall (tier 1 / 2 / 3: 30 / 22 / 17 % of a 160 px track) |
| `calibrator_needle.png` | **40 x 12** exactly | `TextureRect`, stretched to the needle size: `track width 100 x 0.4 = 40` by `12`. Exactly 1x only at 40x12 |

**Bar rules (important):**
1. In `calibrator.tscn` the order is `RpmTargetZone` (needle), then `TuningBar`. **The bar is drawn on top of the needle.** The bar centre must be **translucent or empty**: frame only, or a centre fill of about 25 to 35 % alpha. If the centre is opaque the needle disappears whenever the player is in the zone.
2. The centre 12x12 is stretched about 7x horizontally. Keep it flat: no gradients or patterns. Border and corner details live inside the 6 px margins.
3. With a sprite, the code does not swap the bar style when the needle is inside (it only does that for the flat fallback). "In zone" feedback comes from particles and the score bar. Do not rely on a second bar frame.
4. Blue ramp (`#2b83ba` / `#5db2e6`) with a 1 px cyan (`#00e5ff`) border. The in-zone particle trail is cyan.

**Needle rules:** amber (`#fdae61`) with a bright `#ffd59a` core line; arrow tips at **both** left and right ends so it is symmetric; the centre line is rows 5 and 6 (the code positions the needle by its centre). It blinks (`modulate.a` 0.35 to 1.0) before a dart, so keep all pixels opaque.

### 3.3 Assembler tiles (7 files, all 20x20)

Loaded by `assembler.gd` as `tile_<name>.png`, set as the **icon of each cell `Button`**. When a tile exists the cell text ("PWR", "C", "!"...) is blanked, so **the art itself must carry the meaning**.

| File | State | Design (shape, not colour) |
|---|---|---|
| `tile_empty.png` | Free cell | Dark board cell `#1f1a33`, faint solder pad dot, 1 px border `#2c2547` |
| `tile_power.png` | Start (PWR) | Plug or battery with a **+** mark, blue |
| `tile_output.png` | End (OUT) | Socket, amber. **Drawn at 40 % alpha while locked** (code), so use a bold 2 px outline |
| `tile_node.png` | Node not connected | Open **ring** (a "C" shape), magenta outline, dark inside |
| `tile_node_lit.png` | Node connected | Same ring **filled**, with a **check mark** shape inside |
| `tile_wire.png` | Player wire | Bright blue pad with a centre dot. One plain tile, **no directional corners** (cells have a 2 px gap) |
| `tile_hazard.png` | Short circuit | Vermilion **triangle with a lightning bolt**. Only shown when revealed (fog from tier 2) |

Rules: keep a 1 px transparent or dark border (cells pop to 135 % on click and the fx particles burst from the centre). Seven clearly different silhouettes: a colourblind player must tell `node` from `node_lit` and `empty` from `wire` without colour.

**Wiring requirement W-1 (see section 6):** with today's button theme a 20x20 tile is shown at about **12x12**. Fix it before judging the art.

---

## 4. Portraits (P0 mara + kane, P1 the rest)

| Property | Value |
|---|---|
| Path | `Assets/Textures/Portraits/<id>.png` |
| Size | **40 x 40**, bust, opaque or transparent. The code puts a dark `#14121f` square behind it |
| Optional moods | `<id>_happy.png`, `<id>_unhappy.png`. Falls back to the neutral file |
| Shown at | **40 px** in the morning detail, the barter panel and the dialogue box (after W-2). **20 px** in the offer list (0.5x). Draw with features at least 2 px thick so the face still reads at 20 px |
| Facing | Every bust turns slightly **right**, toward the text (portraits sit to the left of dialogue and detail text) |
| Light | Top-left, same palette for all. One signature item per character (goggles, scar, hat) |

**Which files are really needed**

| id | Character | Where it is seen | Pri |
|---|---|---|---|
| `mara` | Mara Chen | Tutorial (teaches the Forge), MECH offers. **Moods used:** happy, unhappy | P0 |
| `kane` | Collector Kane | Tutorial, installment reactions (Days 8/15/22/29), debt cleared, Day 28. **Moods used:** happy, unhappy | P0 |
| `gideon` | Gideon Vex | Day 12 speaker if Drifter. CAR archetype | P1 |
| `ironhead` | Hector Ironhead | Day 12 speaker if Mech. MECH archetype | P1 |
| `seraph` | Unit Seraph-7 | Day 12 speaker if Reputation. CYBER archetype | P1 |
| `sparky`, `zero`, `talia` | CAR clients | Offers only | P1 (swap of `gideon`) |
| `boris`, `val` | MECH clients | Offers only | P1 (swap of `ironhead`) |
| `nyx`, `mira`, `juno` | CYBER clients | Offers only | P1 (swap of `seraph`) |

Not needed: `player` and `narrator` have no portrait (the box hides it). Files for moods of anyone except `mara` and `kane` are never requested.

**Palette-swap plan:** draw `mara`, `kane`, `gideon`, `ironhead`, `seraph` for real (5 faces + 4 mood files = 9 files). Make the other 9 clients by copying the archetype and changing hair, skin ramp and the signature item. Each swap file still needs its exact `<id>.png` name. Until a file exists, `PortraitView` draws a coloured square with initials, so nothing breaks.

Full cast with look ideas (unchanged from v8): `sparky` racer with goggles; `zero` hooded with cyan visor; `talia` engineer, safety glasses; `gideon` slick jacket and scarf; `mara` welder, soot on cheek; `boris` huge beard, apron; `val` scar over one eye; `ironhead` steel jaw; `nyx` pale, magenta cyber eye; `seraph` plated android face; `mira` surgeon mask; `juno` wide hat, cyber ear; `kane` tall grey collar, cold eyes.

---

## 5. HUD icons, background, parts

### 5.1 HUD icons (P0): `Assets/Textures/UI/`

| File | Size | Meaning | Notes |
|---|---|---|---|
| `icon_credit.png` | **10x10** | Credits | Coin with a "cr" notch, blue/amber |
| `icon_debt.png` | **10x10** | Debt | Syndicate mark (hound head or chain link), **vermilion** |
| `icon_ap.png` | **10x10** | Action Points | Battery with a bolt, cyan |
| `icon_tp.png` | **10x10** | Tech Points | Circuit chip, magenta |

**Important:** when an icon file exists, `hud.gd` **removes the text tag** ("Credits", "Debt", "AP", "TP") and shows only the icon plus the number. The icons must be unambiguous. Name is `icon_tp.png`, not `icon_tech_point.png` (old README).

### 5.2 Tutorial background (P1): `Backgrounds/workshop_bg.png`

**480 x 270**, opaque, loaded by `pathway_select.gd` as `SceneArt` (keep-aspect-covered, so exactly 1x). Garage interior at night: bench, hanging lights, rain on a window, neon spill. Composition for what covers it:
- Bottom 80 px: the dialogue box and a 40 % black dim. Keep it low-detail.
- Top 32 px: the HUD (shown from Kane's debt line on).
- Centre about 420x220: the guided Forge panel. Put the interest at the **left and right edges**.

**Lights are not baked into the background.** The lamps, neon bar and window are drawn as fixtures only (bulbs, glass, sign), so the glow can be done in game with blending and shaders (flicker, pulse, colour change on installment days). Two white textures are provided for that: `light_glow.png` (64x64 round, dithered falloff) and `light_cone.png` (64x96 beam, apex at the top). Place them as `TextureRect`s above the background with a `CanvasItemMaterial` set to **Add**, tinted with `modulate`, at integer scale (2x glow = 128x128):

| Light | Position (bg pixels) | Texture | Tint | Idea |
|---|---|---|---|---|
| Lamp left | glow centre (66, 56), cone apex (66, 57) | glow 2x, cone 2x | amber `#fdae61` | slow flicker |
| Lamp centre | (240, 56) | glow 2x | steel `#c3c7d9` | steady, dimmer |
| Lamp right | (414, 56), cone apex (414, 57) | glow 2x, cone 2x | cyan `#00e5ff` | slow pulse |
| Neon bar | rect (180..300, 18..21) | glow stretched or 3 glows 2x | magenta `#ff2a9d` | buzz flicker |
| Window | rect (362..450, 34..118) | glow stretched | cyan / magenta mix | rain flashes |
| Floor pools | (120, 232) cyan, (380, 222) magenta | glow 2x flattened | low alpha | follows the lamps |

Additive `TextureRect`s are cheap in the Compatibility/web build. Real `PointLight2D` also works in Compatibility, but it needs a `CanvasModulate`, which would darken the whole UI layer: VERIFY in the 4.7.2 class reference (`Light2D`, `CanvasModulate`) before choosing it. The existing `neon_glow.gdshader` can drive the flicker. This is a scene-only change (no script needed beyond an optional tween) and is not applied in this update.

### 5.3 Parts and workshop preview (P2: placeholders already work)

All of these are loaded in `part_slot.gd`, `part_stage.gd` or `item_preview*.tscn`. Replace the placeholder files, keep the names.

| File | Size | Details |
|---|---|---|
| `part_<id>.png` x11: `motor, carburetor, computer_chip, car_chassis, mech_chassis, armor_plating, hydraulic_servo, synth_limb, neural_chip, servo_actuator, power_cell` | **24x24** | One icon per archetype; tier is shown by the frame, never by the icon. Draw in steel + one accent. They are **tinted by code** (ghost `0.55` before built, warm heat tint in the minigame), so avoid near-black fills. 11 distinct silhouettes |
| `frame_tier1_scrap.png`, `frame_tier2_standard.png`, `frame_tier3_prototype.png` | **24x24** | Transparent centre. Differ by **pattern**: T1 plain 1 px copper, T2 1 px silver plus corner brackets, T3 2 px gold/magenta with notched corners |
| `badge_grade_scrap.png`, `badge_grade_standard.png`, `badge_grade_premium.png` | **12x12** | Bottom-right of the icon. Scrap = jagged shard (triangle), Standard = square, Premium = diamond. Shape first, colour second |
| `overlay_rust.png` | 24x24 | Transparent with rust blotches (`#7a3b22`, `#a85a1b`). Code sets its alpha from 25 to 100 % by quality |
| `overlay_crack.png` | 24x24 | Dark crack lines on transparent. Shown only below 50 % quality |
| `slot_empty.png` | **28x28** | Dark socket with a dashed border. The icon sits 2 px inside it |
| `fx_glow_ring.png` (in `Minigames/`) | 24x24 | **White/grey** soft ring, additive. Tinted cyan (excellent), magenta (premium), red (error) by code |
| `item_blueprint_car.png`, `_mech.png`, `_cyber.png` | **120x80** | Shown centred at 1x. Blueprint outline of the finished item in **mid-tone** lines (`#5db2e6` / `#8b90a8`): code dims it to 45 % at the start. Keep the part spots open (table below) |

Part slots are 28x28 squares **centred** on these points (editable in the `item_preview_*.tscn` markers). Draw faint ghost shapes of the part there, and leave the rest of the item readable around them.

| Blueprint | Slot centres (x, y) |
|---|---|
| Car | `CAR_CHASSIS (60, 52)`, `MOTOR (30, 44)`, `CARBURETOR (44, 28)`, `COMPUTER_CHIP (82, 34)` |
| Mech | `MECH_CHASSIS (60, 40)`, `ARMOR_PLATING (60, 24)`, `HYDRAULIC_SERVO (46, 62)`, `MOTOR (80, 46)` |
| Cyber | `SYNTH_LIMB (34, 46)`, `NEURAL_CHIP (60, 22)`, `SERVO_ACTUATOR (86, 46)`, `POWER_CELL (60, 48)` |

Tint rules for the preview: the blueprint brightens from 45 % to 100 % as parts finish, and blends toward the quality colour. A quality label sits at bottom-left (x 2 to 40, y 66 to 78): keep that corner empty.

---

## 6. Findings that change how art is authored (code is not changed in this update)

None of these is a crash. All of them make correct art look wrong.

**W-1: assembler tiles are shown at about 12x12, not 20x20.** `assembler.gd` sets `btn.icon` with `expand_icon = true` on 20x20 cell buttons. The theme gives every `Button` content margins of 4 px (left/right) and 2 px (top/bottom), so the icon area is about 12x16 and the icon is fitted to 12x12 (0.6x, uneven pixels). VERIFY the exact fit rule in the 4.7.2 class reference for `Button.expand_icon`; the first test (see section 9) shows it directly. Fix, in `_build_ui_grid` after creating each `btn`:

```gdscript
	var flat := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, flat)
```

Hover feedback is then lost; cells already pop and burst on click.

**W-2: portrait sizes are not integer fractions of 48.** Constants today: offer row `22`, morning detail `40`, barter `40` (holder 36), dialogue `52`. This spec chooses **40x40 art** so the layout does not grow (the morning screen was the layout that overflowed before). Changes: `offer_row.gd` `PORTRAIT_PX = 22` to `20` (and the `Portrait` minimum size in `offer_row.tscn` to 20); `dialogue_box.gd` `setup(who, 52, ...)` to `40` (and `PortraitHolder` minimum 52 to 40 in `dialogue_box.tscn`); barter holder 36 to 40.

**W-3: part icons are scaled 0.75x in slots and 1.33x in the minigame corner.** Slot art is 24 px; `part_stage.gd` uses `ICON_PX = 32` (art scaled by the code). Set `ICON_PX = 24` (1x) or `ICON_PX = 48` and `STAGE_PX = 56` (2x, a bigger live workpiece). Frames, overlays and the ring follow the same constants.

**W-4: font glyph icons may not render in the web build.** `GamePalette` uses `[✓] [✗] [▲] [◆] [★]` as text. Peaberry may lack them, and the web build has no system font fallback. Test once in the **web export** (section 9, check 6). If they show as boxes, the fix is an 8x8 icon set (`icon_ok`, `icon_fail`, `icon_warn`, `icon_info`, `icon_star`) plus about 30 lines of code. Only if the test fails.

**W-5: UI stretch mode.** `project.godot` uses `canvas_items` + integer scale; the spec (D1) says `viewport`. Both work with this art. With `canvas_items` text is crisp at window resolution and sprites are 2x nearest. Do not switch now.

---

## 7. Needs code, not planned

Only start these after P0 and P1 are done, and only after an explicit go. Each one needs a node plus 5 to 30 lines.

| Item | Size | Where | Est. art + code |
|---|---|---|---|
| Main menu logo | about 160x40 | `main_menu.tscn` (title is a Label now) | 1.0 h |
| Pathway emblems `emblem_reputation / mech / drifter.png` | 32x32 | `pathway_select.tscn` cards | 1.2 h |
| Upgrade icons x5 (`UpgradeData.icon` exists but is never set) | 16x16 | `upgrade_card.tscn` | 1.5 h |
| Contract type icons car / mech / cyber | 10x10 | offer detail badge | 0.8 h |
| End screen rank badge S/A/B/C | 32x32 | `end_screen.tscn` (rank is a big Label now) | 1.0 h |
| Dialogue box 9-slice `dialogue_box_9s.png` | 16x16, margin 4 | theme `StyleBoxTexture` | 0.8 h |
| Glyph replacement icons (W-4) | 8x8 x5 | only if the web test fails | 1.5 h |

If you ever add 9-slice UI art, use `StyleBoxTexture` with `texture_margin_*` equal to the art margin, `axis_stretch` on tile for patterned borders, and keep the `content_margin_*` values the theme already uses so layouts do not move.

---

## 8. Cut and clean-up

| Item | Why |
|---|---|
| `Minigames/workpiece_ingot.png`, `workpiece_motor.png`, `workpiece_circuit.png` (+ `.import`) | Placeholder from Batch A. Nothing loads them: `part_stage.gd` shows the part icon instead. Delete |
| `Minigames/fx_spark_sheet.png` (+ `.import`) | Unreferenced. Sparks are `CPUParticles2D` without a texture. Delete |
| `UI/icon_strike.png`, `UI/icon_calendar.png` (+ `.import`) | Unreferenced. `HudPips` draws strikes and the 30-day track in code. Delete |
| v8 items "not wired yet": `forge_anvil`, `forge_workpiece`, `forge_bar_9s`, `calibrator_engine`, `calibrator_gauge_9s`, `prologue_garage` | Cut. Not in scope after feature freeze |
| `ItemPartData.icon`, `UpgradeData.icon` | Unused fields. Leave them; do not set |
| `client_silhouette_01..03`, `icon_tech_point`, `icon_*` at 16x16 (old `Assets/Textures/README.txt`) | Obsolete. The updated README replaces it |

---

## 9. Plan, test and acceptance

### Time against the calendar

Today is Nov 5; the jam ends in mid-November. At about 2 h/day that is roughly 22 h, and balance, QA, the web export and the itch page need about 10 h of it. That leaves **10 to 12 h** for art. Order of work:

| Step | Contents | Hours | Running total |
|---|---|---|---|
| 1 | P0: hammer, bar, needle, 7 tiles, 4 HUD icons, `mara` + `kane` (+ 4 moods) | 5.2 | 5.2 |
| 2 | P1: `gideon`, `ironhead`, `seraph`, 9 swaps, `workshop_bg`, project icon + cover | 4.2 | 9.4 |
| 3 | P2: replace placeholders (blueprints first, then part icons, frames, badges) | 6.8 | 16.2 |

Stop after step 2 if the schedule is tight. Step 3 only improves placeholders that already work.

### Test checklist (use the debug cheats)

1. **Tiles + W-1:** new run, F1 for credits, accept a contract with a Computer Chip (Assembler). All 7 tiles readable, crisp, no uneven pixels, `tile_output` visible while locked.
2. **Hammer:** start a Forge job. Idle frame sits above the bar; impact frame touches the bar at the strike; head stays under the cursor; it does not cover the instruction text.
3. **Calibrator:** the needle is visible **inside** the bar at all three tiers (use a tier 3 contract). The bar looks right at 48, 35 and 27 px.
4. **Portraits:** tutorial (mara, kane, moods on job result and installment lines), morning offers (list at 20 px, detail at 40 px), barter panel, Day 12 beat (press F2 to skip days until Day 12; F7 only jumps to Day 27).
5. **Workshop preview:** [Dev Sim] button on each part: slot ghost, tier frame, grade badge, quality overlay, glow ring on 90 %+.
6. **Web export (once):** HUD icons, glyphs `[✓] [✗] [▲] [◆] [★]`, Arabic text, portraits in Chrome and Firefox.

### Acceptance per batch

1. File name and folder match this document exactly.
2. Size matches exactly (the Import dock shows it).
3. Only palette colours, **no green**, no semi-transparent edge pixels (except the bar centre in 3.2).
4. Open the game: the placeholder disappears and the sprite shows with no distortion.
5. Look at it at 2x in the running window with the CRT overlay on, not only in your editor.

### What I could not verify

- The real pixel size of the PNG files already in the repo (only their `.import` files were available). If any placeholder is not the size in section 2, replace it, do not resize it.
- No `.import` exists in the snapshot for `forge_hammer`, `calibrator_*`, `tile_*`, any portrait or `workshop_bg`. If the PNGs exist but were never opened in the editor, Godot creates the imports on the next open.
- The in-engine fit rule behind W-1 (section 6), until you run test 1.

---

## 10. Where to find CC0 help (check each licence, keep credits)

- Kenney.nl (CC0): icons, UI, props. Recolour to the palette.
- OpenGameArt.org: filter by **CC0**. Avoid CC-BY-SA unless you accept share-alike.
- itch.io: search "CC0 pixel art" and read each page's licence line.
- Record author and licence of every asset in `Docs/credits.md` as you add it.

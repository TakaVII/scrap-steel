# Scrap & Steel: Sprite Specification (v8)

Everything here is drawn by hand or taken from CC0 packs with credits. **No AI-generated art** (the jam frowns on it).
Every file below is **optional**: the game already runs with placeholders. When you drop a PNG in the right folder with the exact name, the game picks it up with no code change (status column says which ones are already wired).

---

## 0. Global rules

| Rule | Value |
|---|---|
| Base viewport | 480 x 270 logical px. Draw at **1x**. The window shows it at 2x (960 x 540). |
| Format | PNG, 32-bit with transparency, **no anti-aliasing**, no semi-transparent edge pixels (except glow) |
| Scaling in Godot | Nearest filter (already the project default). Never scale art by non-integer amounts. |
| Palette | One shared palette of 20 to 24 colors for **every** asset (section 1) |
| Colorblind rule | **No green anywhere.** Every state is also readable by shape (check / cross / triangle), not by color alone |
| Animation sheets | **Horizontal strips**, frames of equal size, no padding, no gaps. Frame 0 is the idle pose |
| Origin | Unless stated, each sprite is centered in its frame. Keep 1 px of empty border so edges never touch the frame |
| File names | `snake_case`, lowercase, exactly as listed. A wrong name is simply ignored |
| Import | Godot imports PNGs automatically. Keep **Filter = Nearest**, **Mipmaps off**, **Compress = Lossless** (Import dock) |
| Tool | Aseprite (paid) / LibreSprite (free) / Piskel (free, browser). Export "Sheet" > horizontal strip, no padding |

Folder layout (already created in the update zip):

```
Assets/Textures/
  UI/            icons for the HUD and ledger
  Portraits/     clients and the collector
  Minigames/     Forge, Calibrator, Assembler art
  Backgrounds/   full-screen scenes
  Parts/         part icons and tier frames
```

## 1. Shared palette (24 colors)

Start from the colors the code already uses, then fill the rest. Keep the first six exactly (they are in `GamePalette`).

| Role | Hex | Used for |
|---|---|---|
| Positive blue | `#2b83ba` | good results, credits |
| Negative vermilion | `#d7191c` | debt, fines, hazards |
| Accent amber | `#fdae61` | highlights, warnings, hammer sparks |
| Neutral text | `#e8e6f0` | text, white-ish metal |
| Background indigo | `#14111f` | darkest background |
| Neon cyan | `#00e5ff` | glow, sweet spot |
| Neon magenta | `#ff2a9d` | cyberware accent, nodes |
| Indigo 2 / 3 | `#1f1a33` / `#2c2547` | panels, deep shadows |
| Steel 1 to 5 | `#3a3f52` `#5b6078` `#8b90a8` `#c3c7d9` `#f4f3fa` | metal, ramps |
| Blue ramp | `#1c5a82` `#5db2e6` | shading for positive blue |
| Red ramp | `#8f1a1c` `#f06a5b` | shading for vermilion |
| Amber ramp | `#a85a1b` `#ffd59a` | shading for amber, forge heat |
| Skin ramp (3) | `#5a3a32` `#a86f58` `#e3b496` | portraits (add a darker set if you want more variety) |
| Rust | `#7a3b22` | garage details |

Tip: build the palette once in your tool, save it as `scrap_steel.gpl`, and never leave it.

---

## 2. Minigame art (highest priority: this is where the game feel comes from)

### 2.1 Forge

| File | Size | Layout | What to draw | Status |
|---|---|---|---|---|
| `Minigames/forge_hammer.png` | **128 x 32** | 4 frames of 32 x 32 | Frame 0: hammer resting up-right. Frame 1: wound back. Frame 2: **impact** (hammer head touching the bar surface, head centered at the bottom middle, about x=16, y=30). Frame 3: recoil bounce back up. Played as `idle` (frame 0) and `strike` (1, 2, 3, 0 at 18 fps) | **Wired**. The sprite follows the cursor and sits 16 px above the bar, so draw the head at the bottom center of the frame |
| `Minigames/forge_anvil.png` | 48 x 24 | 1 frame | Anvil, side view, flat top. Sits under the bar | Not wired yet (needs a slot node in `forge.tscn`) |
| `Minigames/forge_workpiece.png` | **240 x 16** | 6 frames of 40 x 16 | The part being forged. Frame 0: cold dull ingot. Frames 1 to 4: gets flatter and shaped with each successful strike. Frame 5: finished and glowing. Heat color via the amber ramp | Not wired yet |
| `Minigames/forge_bar_9s.png` | 16 x 16, 9-slice, margin 4 | 1 | Frame of the heat bar | Not wired yet |

Sparks need **no art**: they are built from particles already.

### 2.2 Calibrator

| File | Size | Layout | What to draw | Status |
|---|---|---|---|---|
| `Minigames/calibrator_bar.png` | **24 x 24** | 1 frame, **9-slice with margin 6** | The player's tuning bar. It stretches vertically (bar height is 45 / 35 / 29 px by tier), so keep the middle area plain. Use blue ramp, cyan outline | **Wired** |
| `Minigames/calibrator_needle.png` | **40 x 12** | 1 frame | The target needle / RPM marker. Amber with a bright core, arrow tips at both ends | **Wired** |
| `Minigames/calibrator_engine.png` | 64 x 48 | 3 frames of 64 x 48 | Engine block that shakes (small offsets between frames) | Not wired yet |
| `Minigames/calibrator_gauge_9s.png` | 24 x 24, 9-slice, margin 6 | 1 | The track frame behind the bar | Not wired yet |

### 2.3 Assembler tiles (all 20 x 20)

Cells are exactly **20 x 20** logical pixels. Draw each at that size.

| File | What to draw | Status |
|---|---|---|
| `Minigames/tile_empty.png` | Dark circuit-board cell with a faint solder pad | **Wired** |
| `Minigames/tile_power.png` | The power source (start): a battery or plug, blue | **Wired** |
| `Minigames/tile_output.png` | The output (end): a socket, amber | **Wired** |
| `Minigames/tile_node.png` | Capacitor / node **not yet connected**: magenta outline, dark inside | **Wired** |
| `Minigames/tile_node_lit.png` | Same node **connected**: filled magenta with a check mark shape | **Wired** |
| `Minigames/tile_wire.png` | Cell where the player already laid wire: bright blue trace (one plain tile, no corners needed) | **Wired** |
| `Minigames/tile_hazard.png` | Short circuit: vermilion with a **triangle and lightning shape** (shape matters, not just color) | **Wired** |

Optional later: a 2-frame hazard flicker and spark overlays. They need a small code change; ask when you get there.

---

## 3. Characters and narrative

### 3.1 Portraits (48 x 48)

The game shows them at 22 px (offer list), 40 px (offer detail) and 52 px (dialogue), so the face must read when tiny: big shapes, strong silhouette, 1 signature item per character (goggles, scar, hat). Until the art exists, a colored square with initials is drawn.

File pattern: `Portraits/<id>.png` (neutral). Optional moods: `<id>_happy.png`, `<id>_unhappy.png` (used by dialogue lines that ask for a mood; falls back to neutral).

| id | Character | Type | Look idea |
|---|---|---|---|
| `sparky` | Jax "Sparky" Vane | Drift car | Racer, goggles on forehead, grin |
| `zero` | Cipher Zero | Drift car | Hooded, visor, neon cyan trim |
| `talia` | Talia Ramos | Drift car | Engineer, safety glasses, hair tied up |
| `gideon` | Gideon Vex | Drift car | Slick jacket, scarf, cocky smirk |
| `mara` | Mara Chen | Mech | Welder, cropped hair, soot on cheek. **Appears in the tutorial: draw her first** |
| `boris` | Boris "Piston" Volkov | Mech | Huge beard, bald, apron |
| `val` | Valerie Vance | Mech | Scar over one eye, armored shoulder |
| `ironhead` | Hector Ironhead | Mech | Steel jaw, arena champion, heavy brow |
| `nyx` | Nyx Holliday | Cyberware | Pale, cyber eye implant in magenta |
| `seraph` | Unit Seraph-7 | Cyberware | Elegant android, smooth plated face |
| `mira` | Mira Kuroda | Cyberware | Surgeon style, face mask, short bob |
| `juno` | Juno Okoro | Cyberware | Fixer, wide hat, cybernetic ear |
| `kane` | Collector Kane | (collector) | Tall gray coat collar, pale, calm, cold eyes. **Draw this one early too** |

Cheapest plan if time runs short: draw `mara` and `kane` first, then 1 portrait per type (`sparky`, `boris`, `nyx`) and reuse them with palette swaps. Each palette swap file still needs the exact `<id>.png` name.

### 3.2 Backgrounds

| File | Size | What | Status |
|---|---|---|---|
| `Backgrounds/workshop_bg.png` | **480 x 270** | The garage interior at night: bench, hanging lights, rain on a window. Shown behind the tutorial. Keep the center calm because UI sits on top | **Wired** (tutorial) |
| `Backgrounds/prologue_garage.png` | 480 x 135 | Garage exterior in the neon rain (optional establishing still) | Not wired |

---

## 4. HUD and UI icons

| File | Size | What | Status |
|---|---|---|---|
| `UI/icon_credit.png` | **10 x 10** | Coin with a "cr" notch | **Wired** (HUD) |
| `UI/icon_debt.png` | **10 x 10** | Syndicate mark: a hound head or chain link, vermilion | **Wired** (HUD) |
| `UI/icon_ap.png` | **10 x 10** | Battery with lightning bolt | **Wired** (HUD) |
| `UI/icon_tp.png` | **10 x 10** | Circuit chip | **Wired** (HUD) |

The HUD shows icons at 10 x 10. If you prefer 16 x 16, change the four icon nodes' `custom_minimum_size` in `hud.tscn` and raise the HUD height.

Later, 16 x 16 and not wired yet: `icon_strike.png` (warning triangle), `icon_calendar.png`, `icon_ledger.png` (book), `icon_ok.png` (check), `icon_fail.png` (cross), `icon_warn.png` (triangle). These replace the font glyphs `[✓] [✗] [▲]`, which may show as empty boxes in a web build if the pixel font lacks them (**verify in your web export**).

### Dialogue box
`UI/dialogue_box_9s.png`, 16 x 16, 9-slice margin 4, dark indigo with a cyan 1 px border. Not wired yet; today the panel uses the project theme.

---

## 5. Parts and frames (from the original spec, not wired yet)

| File | Size | Notes |
|---|---|---|
| `Parts/part_<archetype>.png` | 32 x 32 | 11 icons: motor, carburetor, computer_chip, car_chassis, mech_chassis, armor_plating, hydraulic_servo, synth_limb, neural_chip, servo_actuator, power_cell |
| `Parts/frame_tier1_scrap.png` | 32 x 32 | Bronze/copper frame |
| `Parts/frame_tier2_standard.png` | 32 x 32 | Silver/cyan frame |
| `Parts/frame_tier3_prototype.png` | 32 x 32 | Gold/magenta frame |
| `Parts/emblem_reputation.png`, `emblem_mech.png`, `emblem_drifter.png` | 32 x 32 | Pathway emblems |

---

## 6. Production order and time

| Order | Batch | Files | Estimated hours (weak at art) |
|---|---|---|---|
| 1 | Minigame feel | forge_hammer, calibrator_bar, calibrator_needle, 7 tiles | 4 to 5 |
| 2 | HUD icons | 4 icons at 10 x 10 | 1 |
| 3 | Story faces | `mara`, `kane`, then 3 more, then the rest | 3 to 6 |
| 4 | Backgrounds | workshop_bg | 2 |
| 5 | Everything else | anvil, workpiece, parts, emblems | only if time remains |

Total for batches 1 to 4: about **10 to 14 hours**. Batches 1 and 2 give the biggest improvement per hour.

## 7. Where to find CC0 help (check each license, keep credits)

- Kenney.nl (CC0): generic icons, UI, props. Recolor to your palette.
- OpenGameArt.org: filter by **CC0**. Avoid CC-BY-SA unless you accept the share-alike terms.
- itch.io: search "CC0 pixel art" and read each page's license line.
- Record every asset's author and license in `Docs/credits.md` as you add it (the itch page needs this list).

## 8. Quick acceptance checklist (per batch)

1. File name and folder match this document exactly.
2. Size matches exactly (the Import dock shows it).
3. Only palette colors, no green, no semi-transparent edge pixels.
4. Open the game: the placeholder disappears and the sprite shows with no distortion.
5. Check it at 2x in the running window, not only in your editor.

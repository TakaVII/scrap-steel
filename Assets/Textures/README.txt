SCRAP & STEEL - ASSETS/TEXTURES (v10)
=====================================
Authoritative spec: Docs/sprite_spec.md (sizes, animation, wiring, priorities).
This file is only the quick filename/size list. Names must match exactly; a wrong name is ignored.
Rules: PNG 32-bit, no anti-aliasing, 24-colour shared palette, NO green, Filter Nearest, Mipmaps off.

Minigames/   (P0)
  forge_hammer.png        128x32   4 frames of 32x32 (idle, wind-up, impact, recoil); head centred at x=16
  calibrator_bar.png      24x24    9-slice margin 6; centre must be translucent/empty (drawn over the needle)
  calibrator_needle.png   40x12    symmetric arrow tips
  tile_empty / tile_power / tile_output / tile_node / tile_node_lit / tile_wire / tile_hazard .png   20x20 each
  fx_glow_ring.png        24x24    white/grey soft ring (tinted by code)

UI/          (P0)
  icon_credit.png icon_debt.png icon_ap.png icon_tp.png     10x10 each

Portraits/   (40x40, bust facing slightly right)
  P0: mara.png kane.png + mara_happy/_unhappy.png kane_happy/_unhappy.png
  P1: gideon ironhead seraph, then sparky zero talia boris val nyx mira juno (palette swaps)

Backgrounds/ (P1)
  workshop_bg.png         480x270  (no baked lights)
  light_glow.png 64x64, light_cone.png 64x96   white textures for in-game additive lights (not loaded by code yet)

Parts/       (P2, placeholders already exist: replace, keep names)
  part_motor carburetor computer_chip car_chassis mech_chassis armor_plating
       hydraulic_servo synth_limb neural_chip servo_actuator power_cell .png   24x24 each
  frame_tier1_scrap.png frame_tier2_standard.png frame_tier3_prototype.png     24x24
  badge_grade_scrap.png badge_grade_standard.png badge_grade_premium.png       12x12
  overlay_rust.png overlay_crack.png                                           24x24
  slot_empty.png                                                               28x28
  item_blueprint_car.png item_blueprint_mech.png item_blueprint_cyber.png      120x80

DELIVERED v1: every file above exists (procedural placeholders, same names/sizes: refine by hand).
Project icon: icon.png at repo root. Store art: Store/cover_630x500.png.

OBSOLETE (delete): client_silhouette_*, icon_tech_point, 16x16 icons, workpiece_*, fx_spark_sheet,
icon_strike, icon_calendar.

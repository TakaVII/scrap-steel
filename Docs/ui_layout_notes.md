# UI layout notes (why the screens overflowed)

The project pixel font has a very tall line box: about **17 px per text line at size 8** (the glyphs are only 8 px). Every screen was laid out assuming roughly 10-11 px per line, so night summary, HUD, dialogue and barter overflowed by almost 2x.

## The fix
1. Copy this batch, then run **Scripts/Tools/tighten_font_spacing.gd** (open it in the Script editor, File > Run, Ctrl+Shift+X).
   - It measures the default font in `Assets/Themes/default_theme.tres` and sets `FontVariation.spacing_top / spacing_bottom` so a size-8 line is `FontTuner.TARGET_LINE_PX` (11) px tall.
   - The Output panel prints `line height at size 8: 17 px -> 11 px`. If it prints something else for "after", send me the line.
   - It does not touch styles or colours. Safe to run again.
2. `build_ui_theme.gd` (v4) does the same when you regenerate the theme from scratch.
3. If screens are still too tall: lower `TARGET_LINE_PX` in `Scripts/Utils/font_tuner.gd` (10), run the tool again. If text feels cramped: raise it (12).

## Also fixed
`Scenes/UI/hud.tscn`: the container had `grow_vertical = 2` (grow both ways), so when the HUD content was taller than 30 px it grew UPWARD and its top row was cut off. It now grows downward.

## Not verified
I could not run Godot here: `FontVariation.spacing_top/bottom` and `Font.get_height()` are used as documented for Godot 4 (VERIFY in the 4.7.2 class reference: FontVariation).

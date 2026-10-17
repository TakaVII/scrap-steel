SCRAP & STEEL FONT & LOCALIZATION ASSET GUIDE (v2)
==================================================

1. FONT CONFIGURATION & ARABIC FALLBACK:
- Primary Heading Font: res://Assets/Fonts/m5x7.ttf (Clean pixel art font for EN/ES uppercase headings).
- Primary Body Font: Clean sans-serif vector font for general UI strings.
- Arabic Font Fallback: res://Assets/Fonts/NotoSansArabic-Regular.ttf
  * Download Noto Sans Arabic (Google Fonts / SIL Open Font License).
  * Place in res://Assets/Fonts/NotoSansArabic-Regular.ttf.
  * In Godot Project Settings -> GUI -> Theme -> Custom Font, or on the master Theme:
	Select Font -> Fallbacks -> Add element -> Assign NotoSansArabic-Regular.ttf.
  * This guarantees correct Arabic letter shaping (initial, medial, final, isolated forms)
	without disconnected glyphs or square placeholder blocks.

2. TEXT SERVER ENGINE (Godot 4.7.2):
- Set Project Settings -> Internationalization -> Rendering -> Text Server:
  Value: "Advanced" (ICU/HarfBuzz-powered shaping engine).
  * VERIFY: Required for proper Arabic cursive joining, ligature synthesis, and BiDi layout.
  * In web single-threaded builds, ensure the Advanced text server is enabled in the export preset.

3. RIGHT-TO-LEFT (RTL) WINDOW LAYOUT:
- Root Window:
  get_window().layout_direction = Window.LAYOUT_DIRECTION_RTL (for Arabic)
  get_window().layout_direction = Window.LAYOUT_DIRECTION_LTR (for English/Spanish)
- Control Nodes:
  Leave layout_direction = Control.LAYOUT_DIRECTION_INHERITED (default).
  All HBoxContainer, MarginContainer, and GridContainer components will automatically
  mirror their horizontal flow (right to left).

4. DIRECTIONAL CUES & ARROWS:
- Do NOT use hardcoded left/right arrows ("->", "<-") for progression.
- Use symmetric icons or query Control.is_layout_rtl() to flip directional chevrons.

5. LATIN DIGITS INTEGRITY:
- Financial quantities (credits, debt, AP, percentages, days) remain formatted in Latin digits (0-9)
  via NumberFormat utility to maintain readable financial balance across all locales.

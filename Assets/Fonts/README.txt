SCRAP & STEEL — ASSETS/FONTS DIRECTORY SPECIFICATION
=====================================================

1. Primary Pixel Font (Headers, English, Spanish)
   - Filename: primary_pixel.ttf
   - Source suggestions: m5x7, monogram, or match-up
   - Size: 16px base
   - Character coverage: Basic Latin, Latin-1 Supplement (with accented vowels: á, é, í, ó, ú, ñ, ¿, ¡)

2. Arabic Vector Body Font (Arabic localization & fallbacks)
   - Filename: NotoSansArabic-Regular.ttf
   - Format: TrueType (.ttf) or OpenType (.otf)
   - Purpose: TextServer Advanced rendering for Arabic RTL shaping.
   - Note: Never use bitmap pixel fonts for Arabic as ligature shaping requires vector outlines.

Configuration in Godot:
Project Settings -> GUI -> Theme -> Custom Font Fallback -> add NotoSansArabic-Regular.ttf

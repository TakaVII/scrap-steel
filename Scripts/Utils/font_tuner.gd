# purpose: Calibrates the line height of a FontVariation. The project pixel font has a very tall line box (about 17 px at size 8), so every Label, HUD row and dialogue line was twice as tall as the 480x270 layouts were designed for. tighten() sets spacing_top / spacing_bottom so that the REAL line pitch of multi-line text (measured with a TextParagraph, not Font.get_height) becomes `target_px`.
# depends on: RefCounted, FontVariation, TextParagraph
# signals emitted: none
# signals listened to: none

class_name FontTuner
extends RefCounted

## Wanted line pitch in pixels for the base UI size (8 px glyphs + 3 px air). Raise it if text feels cramped, lower it if screens still overflow.
const TARGET_LINE_PX: int = 11
const MAX_PASSES: int = 4

## Real pitch between two lines of text, in pixels. This is what Labels, Buttons and wrapped text actually use.
static func measure_line(font: Font, size: int) -> float:
	var para := TextParagraph.new()
	para.add_string("Ag\nAg", font, size)
	return para.get_size().y / 2.0

## Resets the spacing, then corrects it until the measured line pitch equals target_px. Returns the final measured pitch.
static func tighten(variation: FontVariation, size: int, target_px: int = TARGET_LINE_PX) -> int:
	variation.spacing_top = 0
	variation.spacing_bottom = 0
	for i in range(MAX_PASSES):
		var delta: int = roundi(float(target_px) - measure_line(variation, size))
		if delta == 0:
			break
		var top: int = floori(float(delta) / 2.0)
		variation.spacing_top += top
		variation.spacing_bottom += delta - top
	return roundi(measure_line(variation, size))

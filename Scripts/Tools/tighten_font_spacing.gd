# purpose: One-click fix for tall text lines. Opens Assets/Themes/default_theme.tres, measures the REAL line pitch of the default font (two-line paragraph) and sets FontVariation spacing_top / spacing_bottom so a size-8 line is FontTuner.TARGET_LINE_PX tall. Does not touch styles or colours. Run: open this file in the Script editor, File > Run (Ctrl+Shift+X). Safe to run again (it always starts from spacing 0).
# depends on: EditorScript, FontTuner
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

const THEME_PATH: String = "res://Assets/Themes/default_theme.tres"
const BASE_SIZE: int = 8

func _run() -> void:
	var theme: Theme = load(THEME_PATH) as Theme
	if theme == null:
		printerr("TightenFont: could not load ", THEME_PATH)
		return
	var variation: FontVariation = theme.default_font as FontVariation
	if variation == null:
		var base: Font = theme.default_font
		if base == null:
			printerr("TightenFont: the theme has no default_font. Run build_ui_theme.gd first.")
			return
		variation = FontVariation.new()
		variation.base_font = base
		theme.default_font = variation
	var old_top: int = variation.spacing_top
	var old_bottom: int = variation.spacing_bottom
	var before: float = FontTuner.measure_line(variation, BASE_SIZE)
	variation.spacing_top = 0
	variation.spacing_bottom = 0
	var natural: float = FontTuner.measure_line(variation, BASE_SIZE)
	var after: int = FontTuner.tighten(variation, BASE_SIZE)
	print("TightenFont: line pitch at size %d: current %.1f px (spacing %d/%d), natural %.1f px -> now %d px (target %d). spacing_top=%d spacing_bottom=%d" % [BASE_SIZE, before, old_top, old_bottom, natural, after, FontTuner.TARGET_LINE_PX, variation.spacing_top, variation.spacing_bottom])
	var err: Error = ResourceSaver.save(theme, THEME_PATH)
	if err != OK:
		printerr("TightenFont: save failed, error ", err)
		return
	EditorInterface.get_resource_filesystem().scan()
	print("TightenFont: saved. Close and run the game again.")

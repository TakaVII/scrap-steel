# purpose: [v4] EditorScript that generates the project Theme: pixel font at an 8 px base size, line height tightened with FontTuner (the font's natural line box is ~17 px), compact StyleBoxFlat margins, optional Arabic fallback font. Prefer tighten_font_spacing.gd if you only want to fix the font on an existing theme.
# depends on: EditorScript, GamePalette, FontTuner
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

const FONT_PATH: String = "res://Assets/Fonts/primary_pixel.ttf"
const ARABIC_FONT_PATH: String = "res://Assets/Fonts/NotoSansArabic-Regular.ttf"
const SAVE_PATH: String = "res://Assets/Themes/default_theme.tres"
## Keep in sync with SettingsManager.FONT_SIZE_NORMAL.
const BASE_FONT_SIZE: int = 8

func _run() -> void:
	print("BuildUiTheme: generating theme (base font size %d)..." % BASE_FONT_SIZE)
	var da := DirAccess.open("res://")
	if not da.dir_exists("Assets/Themes"):
		da.make_dir_recursive("Assets/Themes")

	var theme := Theme.new()
	theme.default_font_size = BASE_FONT_SIZE
	_apply_font(theme)

	var c_positive := Color(0.169, 0.514, 0.729, 1.0)
	var c_accent := Color(0.992, 0.682, 0.380, 1.0)
	var c_text := Color(0.910, 0.902, 0.941, 1.0)
	var c_bg := Color(0.078, 0.067, 0.122, 1.0)

	var sb_panel := _box(c_bg, Color(0.0, 0.898, 1.0, 0.6), 4, 4)
	theme.set_stylebox("panel", "PanelContainer", sb_panel)
	theme.set_stylebox("panel", "Panel", sb_panel)

	var normal := _box(Color(0.12, 0.10, 0.18, 1.0), Color(0.25, 0.22, 0.35, 1.0), 4, 2)
	var hover := _box(Color(0.18, 0.15, 0.28, 1.0), c_accent, 4, 2)
	var pressed := _box(c_positive, Color.WHITE, 4, 2)
	var disabled := _box(Color(0.08, 0.07, 0.11, 0.8), Color(0.15, 0.14, 0.20, 0.8), 4, 2)
	for type_name in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type_name, normal)
		theme.set_stylebox("hover", type_name, hover)
		theme.set_stylebox("pressed", type_name, pressed)
		theme.set_stylebox("disabled", type_name, disabled)

	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.10, 0.08, 0.15, 1.0)
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = c_positive
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	theme.set_color("font_color", "Label", c_text)

	var err: Error = ResourceSaver.save(theme, SAVE_PATH)
	if err != OK:
		printerr("BuildUiTheme: save failed, error ", err)
		return
	EditorInterface.get_resource_filesystem().scan()
	print("BuildUiTheme: saved ", SAVE_PATH)

func _apply_font(theme: Theme) -> void:
	if not ResourceLoader.exists(FONT_PATH):
		push_warning("BuildUiTheme: %s not found. The project custom font stays in use." % FONT_PATH)
		return
	var variation := FontVariation.new()
	variation.base_font = load(FONT_PATH) as Font
	if ResourceLoader.exists(ARABIC_FONT_PATH):
		var fallback_list: Array[Font] = [load(ARABIC_FONT_PATH) as Font]
		variation.fallbacks = fallback_list
	else:
		push_warning("BuildUiTheme: NotoSansArabic missing: Arabic will NOT render in the web build.")
	var line_px: int = FontTuner.tighten(variation, BASE_FONT_SIZE)
	print("BuildUiTheme: font line height at size %d = %d px" % [BASE_FONT_SIZE, line_px])
	theme.default_font = variation

func _box(bg: Color, border: Color, margin_h: float, margin_v: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = margin_h
	sb.content_margin_right = margin_h
	sb.content_margin_top = margin_v
	sb.content_margin_bottom = margin_v
	return sb

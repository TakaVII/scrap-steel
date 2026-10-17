# purpose: [v2] EditorScript generating base Theme resource with colorblind-safe palette and 9-slice StyleBoxFlat panels (spec §C10). Uses GamePalette color constants.
# depends on: EditorScript, GamePalette
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

func _run() -> void:
	print("BuildUiTheme: Generating colorblind-safe Theme resource...")
	_ensure_directory()

	var theme := Theme.new()

	# 1. Colors
	var c_positive := Color(0.169, 0.514, 0.729, 1.0) # #2b83ba Blue
	var c_negative := Color(0.843, 0.098, 0.110, 1.0) # #d7191c Vermilion
	var c_accent := Color(0.992, 0.682, 0.380, 1.0)   # #fdae61 Amber
	var c_text := Color(0.910, 0.902, 0.941, 1.0)     # #e8e6f0
	var c_bg := Color(0.078, 0.067, 0.122, 1.0)       # #14111f

	# 2. PanelContainer StyleBox
	var sb_panel := StyleBoxFlat.new()
	sb_panel.bg_color = c_bg
	sb_panel.border_color = Color(0.0, 0.898, 1.0, 0.6) # Neon cyan border
	sb_panel.set_border_width_all(1)
	sb_panel.set_corner_radius_all(3)
	sb_panel.set_content_margin_all(8.0)
	theme.set_stylebox("panel", "PanelContainer", sb_panel)
	theme.set_stylebox("panel", "Panel", sb_panel)

	# 3. Button StyleBoxes
	var sb_btn_normal := StyleBoxFlat.new()
	sb_btn_normal.bg_color = Color(0.12, 0.10, 0.18, 1.0)
	sb_btn_normal.border_color = Color(0.25, 0.22, 0.35, 1.0)
	sb_btn_normal.set_border_width_all(1)
	sb_btn_normal.set_corner_radius_all(3)
	sb_btn_normal.set_content_margin_all(6.0)
	theme.set_stylebox("normal", "Button", sb_btn_normal)

	var sb_btn_hover := StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color(0.18, 0.15, 0.28, 1.0)
	sb_btn_hover.border_color = c_accent
	sb_btn_hover.set_border_width_all(1)
	sb_btn_hover.set_corner_radius_all(3)
	sb_btn_hover.set_content_margin_all(6.0)
	theme.set_stylebox("hover", "Button", sb_btn_hover)

	var sb_btn_pressed := StyleBoxFlat.new()
	sb_btn_pressed.bg_color = c_positive
	sb_btn_pressed.border_color = Color.WHITE
	sb_btn_pressed.set_border_width_all(1)
	sb_btn_pressed.set_corner_radius_all(3)
	sb_btn_pressed.set_content_margin_all(6.0)
	theme.set_stylebox("pressed", "Button", sb_btn_pressed)

	var sb_btn_disabled := StyleBoxFlat.new()
	sb_btn_disabled.bg_color = Color(0.08, 0.07, 0.11, 0.8)
	sb_btn_disabled.border_color = Color(0.15, 0.14, 0.20, 0.8)
	sb_btn_disabled.set_border_width_all(1)
	sb_btn_disabled.set_corner_radius_all(3)
	sb_btn_disabled.set_content_margin_all(6.0)
	theme.set_stylebox("disabled", "Button", sb_btn_disabled)

	# 4. ProgressBar StyleBoxes
	var sb_progress_bg := StyleBoxFlat.new()
	sb_progress_bg.bg_color = Color(0.10, 0.08, 0.15, 1.0)
	sb_progress_bg.set_corner_radius_all(2)
	theme.set_stylebox("background", "ProgressBar", sb_progress_bg)

	var sb_progress_fill := StyleBoxFlat.new()
	sb_progress_fill.bg_color = c_positive
	sb_progress_fill.set_corner_radius_all(2)
	theme.set_stylebox("fill", "ProgressBar", sb_progress_fill)

	# 5. Label Defaults
	theme.set_color("font_color", "Label", c_text)

	var save_path := "res://Assets/Themes/default_theme.tres"
	ResourceSaver.save(theme, save_path)
	EditorInterface.get_resource_filesystem().scan()
	print("BuildUiTheme: Created Theme successfully at ", save_path)

func _ensure_directory() -> void:
	var da := DirAccess.open("res://")
	if not da.dir_exists("Assets/Themes"):
		da.make_dir_recursive("Assets/Themes")

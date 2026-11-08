# purpose: EditorScript that wires the garage lights into the project. Adds the MenuBackdrop (workshop art + lights) to main.tscn and shows it only in the MENU phase (main.gd), and adds the lights to the tutorial scene (pathway_select.tscn). Idempotent: each edit is skipped when already applied; every file is backed up once as <file>.bak_lights. CLOSE main.tscn and pathway_select.tscn in the editor first. Run: open this file in the Script editor, File > Run (Ctrl+Shift+X).
# depends on: EditorScript
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

func _run() -> void:
	print("=== apply_lights_patch ===")
	var ok: bool = true
	ok = _patch("res://Scenes/Main/main.tscn", [
		{"guard": "id=\"17_bg\"", "anchor": "[ext_resource type=\"Script\" path=\"res://Scripts/Main/popup_closer.gd\" id=\"16_closer\"]", "after": true,
			"text": "[ext_resource type=\"Texture2D\" path=\"res://Assets/Textures/Backgrounds/workshop_bg.png\" id=\"17_bg\"]\n[ext_resource type=\"PackedScene\" path=\"res://Scenes/Main/workshop_lights.tscn\" id=\"18_lights\"]"},
		{"guard": "name=\"MenuBackdrop\"", "anchor": "[node name=\"MainMenu\" parent=\"ScreensLayer\" instance=ExtResource(\"3_menu\")]", "after": false,
			"text": _menu_backdrop_block()},
	]) and ok
	ok = _patch("res://Scenes/UI/pathway_select.tscn", [
		{"guard": "id=\"3_lights\"", "anchor": "[ext_resource type=\"PackedScene\" path=\"res://Scenes/UI/dialogue_box.tscn\" id=\"2_dialogue\"]", "after": true,
			"text": "[ext_resource type=\"PackedScene\" path=\"res://Scenes/Main/workshop_lights.tscn\" id=\"3_lights\"]"},
		{"guard": "name=\"WorkshopLights\"", "anchor": "[node name=\"MinigameHost\" type=\"Control\" parent=\".\"]", "after": false,
			"text": "[node name=\"WorkshopLights\" parent=\".\" instance=ExtResource(\"3_lights\")]\nlayout_mode = 1"},
	]) and ok
	ok = _patch("res://Scripts/Main/main.gd", [
		{"guard": "var menu_backdrop", "anchor": "@onready var story_dialogue: Control = %StoryDialogue", "after": true,
			"text": "@onready var menu_backdrop: Control = %MenuBackdrop"},
		{"guard": "menu_backdrop.visible", "anchor": "\tmain_menu.visible = (current_phase == GameManager.Phase.MENU)", "after": true,
			"text": "\tmenu_backdrop.visible = (current_phase == GameManager.Phase.MENU)"},
	]) and ok
	if ok:
		print("OK. Reload the files if the editor asks, then run the game (main menu and tutorial show the lights).")
	else:
		printerr("Some edits could NOT be applied; files with a missing anchor were left untouched. See PATCH_NOTES.md for the manual edits.")
	EditorInterface.get_resource_filesystem().scan()

func _menu_backdrop_block() -> String:
	var full_rect: String = "layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2"
	var lines: PackedStringArray = PackedStringArray([
		"[node name=\"MenuBackdrop\" type=\"Control\" parent=\"ScreensLayer\"]",
		"unique_name_in_owner = true",
		"layout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2",
		"",
		"[node name=\"Art\" type=\"TextureRect\" parent=\"ScreensLayer/MenuBackdrop\"]",
		full_rect + "\ntexture = ExtResource(\"17_bg\")\nexpand_mode = 1\nstretch_mode = 6",
		"",
		"[node name=\"Dim\" type=\"ColorRect\" parent=\"ScreensLayer/MenuBackdrop\"]",
		full_rect + "\ncolor = Color(0.078, 0.067, 0.122, 0.3)",
		"",
		"[node name=\"Lights\" parent=\"ScreensLayer/MenuBackdrop\" instance=ExtResource(\"18_lights\")]",
		"layout_mode = 1",
	])
	return "\n".join(lines)

## edits: Array of {guard, anchor, after: bool, text}. Returns false (and writes nothing for this file) if an anchor is missing.
func _patch(path: String, edits: Array) -> bool:
	if not FileAccess.file_exists(path):
		printerr("Missing file: ", path)
		return false
	var text: String = FileAccess.get_file_as_string(path)
	var original: String = text
	for e: Dictionary in edits:
		if text.contains(String(e["guard"])):
			print("  skip (already applied): ", path, " ", e["guard"])
			continue
		var idx: int = text.find(String(e["anchor"]))
		if idx == -1:
			printerr("  ANCHOR NOT FOUND in ", path, ": ", e["anchor"])
			return false
		if bool(e["after"]):
			idx += String(e["anchor"]).length()
			text = text.insert(idx, "\n" + String(e["text"]))
		else:
			text = text.insert(idx, String(e["text"]) + "\n\n")
		print("  applied: ", path, " ", e["guard"])
	if text == original:
		return true
	DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak_lights"))
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("Could not write ", path)
		return false
	f.store_string(text)
	f.close()
	return true

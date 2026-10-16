# purpose: EditorScript to automatically create the entire directory hierarchy for Scrap & Steel.
# depends on: Godot EditorScript API
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

func _run() -> void:
	var dirs: Array[String] = [
		"res://Globals",
		"res://Scripts/Resources",
		"res://Scripts/Minigames",
		"res://Scripts/UI",
		"res://Scripts/Main",
		"res://Scripts/Utils",
		"res://Scripts/Tools",
		"res://Scenes/Main",
		"res://Scenes/UI",
		"res://Scenes/Minigames",
		"res://Data",
		"res://Shaders",
		"res://Assets/Fonts",
		"res://Assets/Audio",
		"res://Assets/Textures",
		"res://Assets/Themes",
		"res://_reference"
	]

	var da := DirAccess.open("res://")
	if not da:
		printerr("SetupFolders: Failed to open res:// root directory.")
		return

	var created_count: int = 0
	for path in dirs:
		var rel_path: String = path.replace("res://", "")
		if not da.dir_exists(rel_path):
			var err: Error = da.make_dir_recursive(rel_path)
			if err == OK:
				print("Created folder: ", path)
				created_count += 1
			else:
				printerr("Failed to create folder: ", path, " (Error code: ", err, ")")
		else:
			print("Folder already exists: ", path)

	print("SetupFolders finished. Total new folders created: ", created_count)
	EditorInterface.get_resource_filesystem().scan()

# purpose: EditorScript to procedurally create all 11 ItemPartData archetypes and 12 ClientData .tres resources.
# depends on: EditorScript, ItemPartData, ClientData
# signals emitted: none
# signals listened to: none

@tool
extends EditorScript

func _run() -> void:
	print("GenerateData: Beginning generation of Part archetypes and Client dossiers...")
	_ensure_directories()
	_generate_parts()
	_generate_clients()
	EditorInterface.get_resource_filesystem().scan()
	print("GenerateData: Completed successfully. All .tres data files written to res://Data/")

func _ensure_directories() -> void:
	var da := DirAccess.open("res://")
	if not da.dir_exists("Data/Parts"):
		da.make_dir_recursive("Data/Parts")
	if not da.dir_exists("Data/Clients"):
		da.make_dir_recursive("Data/Clients")

func _generate_parts() -> void:
	var parts_def: Array[Dictionary] = [
		{"id": &"motor", "name": "PART_MOTOR", "arch": ItemPartData.Archetype.MOTOR, "mg": ItemPartData.MinigameType.CALIBRATE, "ap": 2, "watts": 120.0},
		{"id": &"carburetor", "name": "PART_CARBURETOR", "arch": ItemPartData.Archetype.CARBURETOR, "mg": ItemPartData.MinigameType.CALIBRATE, "ap": 2, "watts": 90.0},
		{"id": &"computer_chip", "name": "PART_COMPUTER_CHIP", "arch": ItemPartData.Archetype.COMPUTER_CHIP, "mg": ItemPartData.MinigameType.ASSEMBLE, "ap": 1, "watts": 40.0},
		{"id": &"car_chassis", "name": "PART_CAR_CHASSIS", "arch": ItemPartData.Archetype.CAR_CHASSIS, "mg": ItemPartData.MinigameType.FORGE, "ap": 2, "watts": 0.0},
		{"id": &"mech_chassis", "name": "PART_MECH_CHASSIS", "arch": ItemPartData.Archetype.MECH_CHASSIS, "mg": ItemPartData.MinigameType.FORGE, "ap": 2, "watts": 0.0},
		{"id": &"armor_plating", "name": "PART_ARMOR_PLATING", "arch": ItemPartData.Archetype.ARMOR_PLATING, "mg": ItemPartData.MinigameType.FORGE, "ap": 2, "watts": 0.0},
		{"id": &"hydraulic_servo", "name": "PART_HYDRAULIC_SERVO", "arch": ItemPartData.Archetype.HYDRAULIC_SERVO, "mg": ItemPartData.MinigameType.CALIBRATE, "ap": 2, "watts": 140.0},
		{"id": &"synth_limb", "name": "PART_SYNTH_LIMB", "arch": ItemPartData.Archetype.SYNTH_LIMB, "mg": ItemPartData.MinigameType.FORGE, "ap": 2, "watts": 30.0},
		{"id": &"neural_chip", "name": "PART_NEURAL_CHIP", "arch": ItemPartData.Archetype.NEURAL_CHIP, "mg": ItemPartData.MinigameType.ASSEMBLE, "ap": 1, "watts": 25.0},
		{"id": &"servo_actuator", "name": "PART_SERVO_ACTUATOR", "arch": ItemPartData.Archetype.SERVO_ACTUATOR, "mg": ItemPartData.MinigameType.CALIBRATE, "ap": 2, "watts": 80.0},
		{"id": &"power_cell", "name": "PART_POWER_CELL", "arch": ItemPartData.Archetype.POWER_CELL, "mg": ItemPartData.MinigameType.ASSEMBLE, "ap": 1, "watts": 20.0}
	]

	for p in parts_def:
		var part := ItemPartData.new()
		part.part_id = p["id"]
		part.display_key = p["name"]
		part.archetype = p["arch"]
		part.minigame_type = p["mg"]
		part.ap_cost = p["ap"]
		part.base_power_watts = p["watts"]
		var path: String = "res://Data/Parts/%s.tres" % str(p["id"])
		ResourceSaver.save(part, path)
		print("Generated part resource: ", path)

func _generate_clients() -> void:
	var clients_def: Array[Dictionary] = [
		{"id": &"sparky", "name": "Jax 'Sparky' Vane", "type": 0, "g": "CLIENT_SPARKY_GREET", "s": "CLIENT_SPARKY_SATISFIED", "u": "CLIENT_SPARKY_UNHAPPY"},
		{"id": &"mara", "name": "Mara Chen", "type": 1, "g": "CLIENT_MARA_GREET", "s": "CLIENT_MARA_SATISFIED", "u": "CLIENT_MARA_UNHAPPY"},
		{"id": &"zero", "name": "Cipher Zero", "type": 2, "g": "CLIENT_ZERO_GREET", "s": "CLIENT_ZERO_SATISFIED", "u": "CLIENT_ZERO_UNHAPPY"},
		{"id": &"boris", "name": "Boris 'Piston' Volkov", "type": 1, "g": "CLIENT_BORIS_GREET", "s": "CLIENT_BORIS_SATISFIED", "u": "CLIENT_BORIS_UNHAPPY"},
		{"id": &"talia", "name": "Talia Ramos", "type": 0, "g": "CLIENT_TALIA_GREET", "s": "CLIENT_TALIA_SATISFIED", "u": "CLIENT_TALIA_UNHAPPY"},
		{"id": &"dr_kane", "name": "Dr. Aris Kane", "type": 2, "g": "CLIENT_KANE_GREET", "s": "CLIENT_KANE_SATISFIED", "u": "CLIENT_KANE_UNHAPPY"},
		{"id": &"gideon", "name": "Gideon Scraphound", "type": 1, "g": "CLIENT_GIDEON_GREET", "s": "CLIENT_GIDEON_SATISFIED", "u": "CLIENT_GIDEON_UNHAPPY"},
		{"id": &"nyx", "name": "Nyx Holliday", "type": 0, "g": "CLIENT_NYX_GREET", "s": "CLIENT_NYX_SATISFIED", "u": "CLIENT_NYX_UNHAPPY"},
		{"id": &"seraph", "name": "Unit Seraph-7", "type": 2, "g": "CLIENT_SERAPH_GREET", "s": "CLIENT_SERAPH_SATISFIED", "u": "CLIENT_SERAPH_UNHAPPY"},
		{"id": &"val", "name": "Valerie Vance", "type": 0, "g": "CLIENT_VAL_GREET", "s": "CLIENT_VAL_SATISFIED", "u": "CLIENT_VAL_UNHAPPY"},
		{"id": &"ironhead", "name": "Hector Ironhead", "type": 1, "g": "CLIENT_IRONHEAD_GREET", "s": "CLIENT_IRONHEAD_SATISFIED", "u": "CLIENT_IRONHEAD_UNHAPPY"},
		{"id": &"mira", "name": "Mira Kuroda", "type": 2, "g": "CLIENT_MIRA_GREET", "s": "CLIENT_MIRA_SATISFIED", "u": "CLIENT_MIRA_UNHAPPY"}
	]

	for c in clients_def:
		var client := ClientData.new()
		client.client_id = c["id"]
		client.client_name = c["name"]
		client.preferred_type = c["type"]
		client.greeting_key = c["g"]
		client.satisfied_key = c["s"]
		client.unhappy_key = c["u"]
		var path: String = "res://Data/Clients/%s.tres" % str(c["id"])
		ResourceSaver.save(client, path)
		print("Generated client resource: ", path)

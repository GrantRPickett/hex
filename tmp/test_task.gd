extends SceneTree

func _init() -> void:
	print("Checking location target_id...")
	var task = load("res://Resources/level_data/zoo_test/stages/zoo_test_stage_discovery.tres").tasks[0]
	print("Task.target_id: ", task.target_id)
	print("Task.target_coord: ", task.target_coord)

	var loc = load("res://Resources/level_data/zoo_test/location_rows/zoo_test_stage_discovery_location_0.tres")
	print("Location.location_name: ", loc.location_name)
	print("Location.coord: ", loc.coord)

	if task.target_id == loc.location_name:
		print("Names MATCH!")
	else:
		print("Names DO NOT MATCH!")

	if task.target_coord == loc.coord:
		print("Coords MATCH!")
	else:
		print("Coords DO NOT MATCH!")

	quit()

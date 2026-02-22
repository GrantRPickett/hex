class_name LocationService
extends RefCounted

var _level: Resource:
	set(value):
		_level = value
	get:
		return _level

func get_all_locations_data() -> Array[Dictionary]:
	var locations_data: Array[Dictionary] = []
	if not _level:
		return locations_data

	# Assuming level_resource contains an array of Location resources or similar data
	# For now, this is a placeholder. We need to define how Location resources are stored in a level.
	# Let's assume for now the level_resource has a property 'locations' which is an Array<Location>

	if _level.has_method("get_locations") and _level.get_locations() is Array:
		for loc_resource in _level.get_locations():
			if loc_resource is Location: # Assuming Location is the class_name of Gameplay/location.gd
				locations_data.append({
					"name": loc_resource.name,
					"description": loc_resource.description,
					# "stat_boosts": loc_resource.stat_boosts if loc_resource.has("stat_boosts") else {} # If Location resource has stat_boosts
				})
			elif loc_resource is Dictionary: # If locations are just dictionaries
				locations_data.append({
					"name": loc_resource.get("name", "Unnamed Location"),
					"description": loc_resource.get("description", "No description."),
					# "stat_boosts": loc_resource.get("stat_boosts", {})
				})
	return locations_data

func get_location_data_at_coordinate(coord: Vector2i) -> Dictionary:
	# This would require iterating through locations and checking their coordinates
	# For now, a placeholder
	return {"name": "Test Location", "description": "This is a test location."}


func create_memento() -> Dictionary:
	var locs = get_all_locations_data()
	return {"locations": locs}

func restore_from_memento(memento: Dictionary) -> void:
	# This would require logic to restore locations based on the memento data
	# For now, this is a placeholder and does not actually restore anything
	set_locations_from_data(memento.get("locations", []))

func set_locations_from_data(locations_data: Array[Dictionary]) -> void:
	for loc_data in locations_data:
		loc_data = loc_data as Dictionary
		#TargetSpawner.spawn_or_update_location(loc_data, get_tree().current_scene, null)
		 # Assuming we want to spawn locations in the current scene and no grid for now
	pass

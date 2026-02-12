class_name LocationService
extends RefCounted

var _level_resource: Resource # The level resource that contains location data

func setup(level_resource: Resource) -> void:
	_level_resource = level_resource

func get_all_locations_data() -> Array[Dictionary]:
	var locations_data: Array[Dictionary] = []
	if not _level_resource:
		return locations_data

	# Assuming level_resource contains an array of Location resources or similar data
	# For now, this is a placeholder. We need to define how Location resources are stored in a level.
	# Let's assume for now the level_resource has a property 'locations' which is an Array<Location>

	if _level_resource.has_method("get_locations") and _level_resource.get_locations() is Array:
		for loc_resource in _level_resource.get_locations():
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

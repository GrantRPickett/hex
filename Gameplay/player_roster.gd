class_name PlayerRoster
extends Resource

@export var units: Array[PackedScene] = []

func get_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for scene in units:
		if scene:
			var unit = scene.instantiate()
			if unit is Unit:
				result.append(unit)
	return result

func update_roster(active_units: Array[Unit]) -> void:
	var permadeath := false
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		var save_manager = tree.root.get_node_or_null("SaveManager")
		if save_manager:
			permadeath = save_manager.get_value("permadeath", false)

	var new_units: Array[PackedScene] = []
	var active_counts: Dictionary = {}

	for unit in active_units:
		if not unit:
			continue

		var u_name = unit.unit_name
		active_counts[u_name] = active_counts.get(u_name, 0) + 1

		unit.prepare_for_save()
		var dup = unit.duplicate()

		# Clean up children that will be recreated by _ready to avoid duplicates
		for child in dup.get_children():
			if child is UnitInventory:
				child.free()

		_set_owner_recursive(dup, dup)

		var scene = PackedScene.new()
		scene.pack(dup)
		new_units.append(scene)
		dup.free()

	# If permadeath is disabled, restore missing units from the previous state
	if not permadeath:
		for scene in units:
			if not scene:
				continue
			var temp = scene.instantiate()
			if temp is Unit:
				var u_name = temp.unit_name
				if active_counts.get(u_name, 0) > 0:
					active_counts[u_name] -= 1
				else:
					new_units.append(scene)
			temp.free()

	units = new_units

func _set_owner_recursive(node: Node, root: Node) -> void:
	if node != root:
		node.owner = root
	for child in node.get_children():
		_set_owner_recursive(child, root)
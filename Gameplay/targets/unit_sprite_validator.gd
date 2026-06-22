# Unit Sprite Validator
# Audits all Units in the UnitManager to ensure they have valid sprites and textures.

extends RefCounted

static func validate_units(unit_manager: UnitManager) -> Dictionary:
	var results := {
		"total_units": 0,
		"valid_sprites": 0,
		"missing_sprites": [],
		"invalid_textures": [],
		"invalid_regions": [],
		"overlapping_coords": {},
		"misaligned_positions": []
	}

	if not is_instance_valid(unit_manager):
		return results

	var units = unit_manager.get_all_units()
	results.total_units = units.size()

	var coord_to_units := {} # Vector2i -> Array[Unit]

	for unit in units:
		if not is_instance_valid(unit):
			continue

		var coord = unit_manager.get_coord_by_unit(unit)
		if not coord_to_units.has(coord):
			coord_to_units[coord] = []
		coord_to_units[coord].append(unit)

		# 1. Sprite Presence
		var sprite = unit.get_node_or_null("Sprite2D")
		if not is_instance_valid(sprite):
			results.missing_sprites.append(unit.unit_name + " (" + unit.id + ")")
			continue
		
		results.valid_sprites += 1

		# 2. Texture Validity
		if sprite.texture == null:
			results.invalid_textures.append(unit.unit_name + " (" + unit.id + ")")
		
		# 3. Region Rect Validity
		if sprite.region_enabled:
			var rect = sprite.region_rect
			var tex = sprite.texture
			if tex:
				var tex_size = tex.get_size()
				if rect.position.x < 0 or rect.position.y < 0 or \
				   rect.position.x + rect.size.x > tex_size.x or \
				   rect.position.y + rect.size.y > tex_size.y:
					results.invalid_regions.append(unit.unit_name + " (" + unit.id + "): " + str(rect) + " out of bounds for " + str(tex_size))
				elif rect.size.x == 0 or rect.size.y == 0:
					results.invalid_regions.append(unit.unit_name + " (" + unit.id + "): Zero size region")

		# 4. Alignment
		if is_instance_valid(unit.grid_map):
			var expected_pos = unit.grid_map.map_to_local(coord)
			if unit.global_position.distance_to(expected_pos) > 0.1:
				results.misaligned_positions.append(unit.unit_name + " (" + unit.id + "): Pos " + str(unit.global_position) + " vs Expected " + str(expected_pos))

	# 5. Overlaps
	for c in coord_to_units:
		if coord_to_units[c].size() > 1:
			var names = []
			for u in coord_to_units[c]:
				names.append(u.unit_name)
			results.overlapping_coords[str(c)] = names

	return results

static func print_report(results: Dictionary) -> void:
	print("\n--- Unit Sprite Validation Report ---")
	print("Total Units Tracked: ", results.total_units)
	print("Valid Sprites: ", results.valid_sprites)
	
	if results.missing_sprites.size() > 0:
		print("\n[!] MISSING SPRITES:")
		for item in results.missing_sprites: print("  - ", item)
	
	if results.invalid_textures.size() > 0:
		print("\n[!] INVALID/NULL TEXTURES:")
		for item in results.invalid_textures: print("  - ", item)
		
	if results.invalid_regions.size() > 0:
		print("\n[!] INVALID REGION RECTS (Possibly off-texture):")
		for item in results.invalid_regions: print("  - ", item)

	if results.misaligned_positions.size() > 0:
		print("\n[!] MISALIGNED POSITIONS:")
		for item in results.misaligned_positions: print("  - ", item)

	if results.overlapping_coords.size() > 0:
		print("\n[!] OVERLAPPING UNIT COORDINATES:")
		for coord_str in results.overlapping_coords:
			print("  - ", coord_str, ": ", results.overlapping_coords[coord_str])
	
	print("\n--- End of Report ---\n")

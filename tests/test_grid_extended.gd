extends GdUnitTestSuite

# Test GridController and GridVisuals uncovered functions

const GridControllerScript = preload("res://Gameplay/map/grid_controller.gd")
const GridVisualsScript = preload("res://Gameplay/map/grid_visuals.gd")

func _add_and_free(node: Node) -> Node:
	add_child(node)
	return auto_free(node)

func test_grid_controller_on_loot_added() -> void:
	var gc = GridControllerScript.new()
	var grid = auto_free(TileMapLayer.new())
	_add_and_free(gc)

	gc.setup(grid)

	var loot = Loot.new()
	# Without adding to tree, just check properties
	gc.on_loot_added(loot, Vector2i(1, 1))

	# Loot should be child of grid
	assert_object(loot.get_parent()).is_equal(grid)

	loot.free()

class FakeDialogueService extends Node:
	var active = false
	func has_active_dialogue_with(_u1, _u2) -> bool: return active

class StubUnit extends Unit:
	var p_controlled = false
	func _init(p): p_controlled = p

class FakeUnitManager extends Node:
	var units = []
	func get_units() -> Array: return units
	func get_selected_unit() -> Unit: return units[0] if not units.is_empty() else null
	func get_selected_index() -> int: return 0 if not units.is_empty() else -1
	func is_player_controlled(idx: int) -> bool:
		if idx < 0 or idx >= units.size(): return false
		return units[idx].p_controlled

class FakeTerrainMap extends Node:
	func is_within_bounds(_c): return true

func test_grid_visuals_methods() -> void:
	var gv = GridVisualsScript.new()
	_add_and_free(gv)
	gv._ready()

	var grid = auto_free(TileMapLayer.new())
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(64, 64)
	grid.tile_set = tileset

	var um = auto_free(FakeUnitManager.new())
	var u1 = auto_free(StubUnit.new(true))
	var u2 = auto_free(StubUnit.new(false))
	um.units = [u1, u2]

	var d_svc = auto_free(FakeDialogueService.new())

	# Dialogue Indicators
	d_svc.active = true
	gv.update_dialogue_indicators(grid, um, d_svc)
	# Root should have children
	assert_bool(gv._dialogue_indicator_root.get_child_count() > 0).is_true()

	# Enemy Range
	assert_bool(gv.is_enemy_range_visible()).is_false()
	gv.toggle_enemy_range_view()
	assert_bool(gv.is_enemy_range_visible()).is_true()

	# Call update enemy range
	var tm = auto_free(FakeTerrainMap.new())
	gv.update_enemy_range_overlay(um, tm, grid)

	# Threatened path hex
	gv.show_threatened_path_hex(Vector2i(0, 0), grid)
	assert_bool(gv._threatened_path_hex.visible).is_true()

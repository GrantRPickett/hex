extends GdUnitTestSuite

# Test hover info manager specific occupancy methods.
const HoverInfoScript = preload("res://GUI/HUD/hover_info_manager.gd")

class FakeGrid extends TileMapLayer:
	func set_cell_at(_c, _d) -> void: pass

class FakeGameplay extends Node2D:
	@warning_ignore("native_method_override")
	func get_global_mouse_position() -> Vector2: return Vector2(0, 0)

class FakeGameState extends GameState:
	func _init() -> void:
		super ({})
		terrain_map = TerrainMap.new()
		map_controller = FakeMapController.new()

class FakeMapController extends MapController:
	func get_grid() -> TileMapLayer:
		return FakeGrid.new()

func test_hover_info_manager_get_occupants() -> void:
	var state = FakeGameState.new()
	var hm = HoverInfoScript.new(state)

	hm._gameplay_node = auto_free(FakeGameplay.new())
	hm._grid = state.map_controller.get_grid()

	# Add an occupant
	var occupant = auto_free(Unit.new())
	occupant.position = Vector2(0, 0)
	hm._grid.add_child(occupant)

	var occupants = hm.get_hex_occupants_at_mouse_position()
	assert_int(occupants.size()).is_equal(1)
	assert_object(occupants[0]).is_equal(occupant)

	var hovered_unit = hm.get_unit_at_mouse_position()
	assert_object(hovered_unit).is_equal(occupant)

	# Try non-visible
	occupant.visible = false
	var no_unit = hm.get_unit_at_mouse_position()
	assert_object(no_unit).is_null()

	state.map_controller.get_grid().queue_free()

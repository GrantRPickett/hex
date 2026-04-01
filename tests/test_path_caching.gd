extends GdUnitTestSuite

func test_reachable_state_get_path() -> void:
	var state := ReachableState.new()
	state.movement_origin = Vector2i(0, 0)
	state.action_origin = Vector2i(0, 0)
	
	# Mock lookup with parents: 0,0 -> 1,0 -> 1,1
	state.lookup = {
		Vector2i(0, 0): {"cost": 0, "parent": GameConstants.INVALID_COORD},
		Vector2i(1, 0): {"cost": 1, "parent": Vector2i(0, 0)},
		Vector2i(1, 1): {"cost": 2, "parent": Vector2i(1, 0)}
	}
	
	var path := state.get_path(Vector2i(1, 1))
	assert_array(path).contains_exactly([Vector2i(1, 0), Vector2i(1, 1)])

func test_path_reconstruction_with_origin() -> void:
	var state := ReachableState.new()
	state.movement_origin = Vector2i(5, 5)
	
	state.lookup = {
		Vector2i(5, 5): {"cost": 0, "parent": GameConstants.INVALID_COORD},
		Vector2i(5, 6): {"cost": 1, "parent": Vector2i(5, 5)}
	}
	
	var path := state.get_path(Vector2i(5, 6))
	assert_array(path).contains_exactly([Vector2i(5, 6)])

extends GdUnitTestSuite

const GridVisualsScene = preload("res://Gameplay/map/grid_visuals.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func _make_visuals() -> Node2D:
	var visuals = GridVisualsScene.new()
	add_child(visuals)
	return visuals

func after_test() -> void:
	for child in get_children():
		child.queue_free()

func test_loyalty_indicators_drawn() -> void:
	var visuals = _make_visuals()
	var grid = TileMapLayer.new()
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)
	
	var um = Stubs.FakeUnitManager.new()
	var tm = Stubs.FakeTerrainMap.new({}, 10, 10)
	
	# Create a neutral unit leaning PLAYER
	var unit_player = Stubs.FakeUnit.new()
	unit_player.unit_name = "NeutralPlayer"
	unit_player.faction = GameConstants.Faction.NEUTRAL
	unit_player.loyalty.neutral_loyalty = GameConstants.Faction.PLAYER
	unit_player.set_grid_location(Vector2i(1, 1))
	um.add_unit(unit_player, Vector2i(1, 1))
	
	# Create a neutral unit leaning ENEMY
	var unit_enemy = Stubs.FakeUnit.new()
	unit_enemy.unit_name = "NeutralEnemy"
	unit_enemy.faction = GameConstants.Faction.NEUTRAL
	unit_enemy.loyalty.neutral_loyalty = GameConstants.Faction.ENEMY
	unit_enemy.set_grid_location(Vector2i(2, 2))
	um.add_unit(unit_enemy, Vector2i(2, 2))
	
	# Create a neutral unit with no leaning
	var unit_none = Stubs.FakeUnit.new()
	unit_none.unit_name = "NeutralNone"
	unit_none.faction = GameConstants.Faction.NEUTRAL
	unit_none.loyalty.neutral_loyalty = GameConstants.Faction.NEUTRAL
	unit_none.set_grid_location(Vector2i(3, 3))
	um.add_unit(unit_none, Vector2i(3, 3))
	
	visuals.update_loyalty_indicators(um, tm, grid)
	
	# Should have 3 loyalty polygons (player-leaning, enemy-leaning, and convincable neutral)
	var root = visuals.get("_loyalty_indicator_root")
	assert_int(root.get_child_count()).is_equal(3)
	
	# Verify colors
	var poly_player = root.get_child(0) as Polygon2D
	assert_object(poly_player.color).is_equal(GameConstants.Colors.GRID_LOYALTY_PLAYER)
	
	var poly_enemy = root.get_child(1) as Polygon2D
	assert_object(poly_enemy.color).is_equal(GameConstants.Colors.GRID_LOYALTY_ENEMY)

	var poly_neutral = root.get_child(2) as Polygon2D
	assert_object(poly_neutral.color).is_equal(GameConstants.Colors.GRID_LOYALTY_NEUTRAL)
	
	grid.free()

func test_range_indicator_skips_occupied() -> void:
	var visuals = _make_visuals()
	var grid = TileMapLayer.new()
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)
	
	var um = Stubs.FakeUnitManager.new()
	
	# Selected player unit at (0,0)
	var unit = Stubs.FakeUnit.new()
	unit.faction = GameConstants.Faction.PLAYER
	unit.set_grid_location(Vector2i(0, 0))
	unit.movement_points = 2
	um.add_unit(unit, Vector2i(0, 0), true)
	um.set_player_controlled(0, true)
	um.select_index(0)
	
	# Other unit at (1,0) - should be skipped in range highlight
	var other_unit = Stubs.FakeUnit.new()
	other_unit.faction = GameConstants.Faction.ENEMY
	other_unit.set_grid_location(Vector2i(1, 0))
	um.add_unit(other_unit, Vector2i(1, 0))
	
	# Mock reachable to include (1,0) and (0,1)
	var reachable = {
		Vector2i(1, 0): 1,
		Vector2i(0, 1): 1
	}
	
	visuals._draw_range_indicators(grid, unit, um, reachable, Vector2i(0, 0))
	
	# Should only have 1 polygon (for 0,1), skipping 1,0 because it's occupied
	var root = visuals.get("_range_indicator_root")
	assert_int(root.get_child_count()).is_equal(1)
	
	grid.free()

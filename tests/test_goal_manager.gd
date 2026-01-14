extends GdUnitTestSuite

var _manager: GoalManager
var _grid: TileMapLayer
var _sprite1: Sprite2D
var _sprite2: Sprite2D

func before_test() -> void:
	_manager = auto_free(GoalManager.new())
	_grid = auto_free(TileMapLayer.new())
	_grid.tile_set = auto_free(TileSet.new())
	_sprite1 = auto_free(Sprite2D.new())
	_sprite2 = auto_free(Sprite2D.new())

	# Add children to a parent so they can be managed if needed,
	# though for unit tests we just need the references.
	add_child(_manager)

func test_setup_positions_sprites() -> void:
	var goals: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 4)]
	var sprites: Array[Sprite2D] = [_sprite1, _sprite2]

	_manager.setup(goals, sprites, _grid)

	assert_vector(_manager.get_target(0)).is_equal(Vector2i(3, 3))
	assert_vector(_manager.get_target(1)).is_equal(Vector2i(4, 4))

	# Verify sprites are visible
	assert_bool(_sprite1.visible).is_true()
	assert_bool(_sprite2.visible).is_true()

func test_setup_hides_unused_sprites() -> void:
	var goals: Array[Vector2i] = [Vector2i(3, 3)]
	var sprites: Array[Sprite2D] = [_sprite1, _sprite2]

	_manager.setup(goals, sprites, _grid)

	assert_bool(_sprite1.visible).is_true()
	assert_bool(_sprite2.visible).is_false()

func test_set_target_updates_value() -> void:
	var goals: Array[Vector2i] = [Vector2i(0, 0)]
	var sprites: Array[Sprite2D] = [_sprite1]
	_manager.setup(goals, sprites, _grid)
	_manager.set_target(0, Vector2i(5, 5))
	assert_vector(_manager.get_target(0)).is_equal(Vector2i(5, 5))

func test_get_targets() -> void:
	var goals: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2)]
	var sprites: Array[Sprite2D] = [_sprite1, _sprite2]
	_manager.setup(goals, sprites, _grid)
	var targets = _manager.get_targets()
	assert_array(targets).is_equal(goals)
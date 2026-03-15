extends GdUnitTestSuite

var _roster: EnemyRoster

func before_test() -> void:
	_roster = auto_free(EnemyRoster.new())

func test_get_enemy_scene_valid_index() -> void:
	var scene1: PackedScene = PackedScene.new()
	var scene2: PackedScene = PackedScene.new()
	_roster.units = [scene1, scene2]

	assert_object(_roster.get_unit_scene(0)).is_equal(scene1)
	assert_object(_roster.get_unit_scene(1)).is_equal(scene2)

func test_get_enemy_scene_invalid_index() -> void:
	var scene: PackedScene = PackedScene.new()
	_roster.units = [scene]

	assert_object(_roster.get_unit_scene(1)).is_null()
	assert_object(_roster.get_unit_scene(-1)).is_null()

func test_get_enemy_scene_empty_roster() -> void:
	_roster.units = []

	assert_object(_roster.get_unit_scene(0)).is_null()

func test_get_random_enemy_scene_empty() -> void:
	_roster.units = []

	assert_object(_roster.get_random_unit_scene()).is_null()

func test_get_random_enemy_scene_single() -> void:
	var scene: PackedScene = PackedScene.new()
	_roster.units = [scene]

	assert_object(_roster.get_random_unit_scene()).is_equal(scene)

func test_get_random_enemy_scene_multiple() -> void:
	var scene1: PackedScene = PackedScene.new()
	var scene2: PackedScene = PackedScene.new()
	var scene3: PackedScene = PackedScene.new()
	_roster.units = [scene1, scene2, scene3]

	var result = _roster.get_random_unit_scene()

	assert_object(result).is_not_null()
	assert_bool(_roster.units.has(result)).is_true()

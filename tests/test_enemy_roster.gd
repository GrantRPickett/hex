extends GdUnitTestSuite

var _roster: EnemyRoster

func before() -> void:
	_roster = auto_free(EnemyRoster.new())

func test_get_enemy_scene_valid_index() -> void:
	var scene1 = PackedScene.new()
	var scene2 = PackedScene.new()
	_roster.enemy_types = [scene1, scene2]

	assert_object(_roster.get_enemy_scene(0)).is_equal(scene1)
	assert_object(_roster.get_enemy_scene(1)).is_equal(scene2)

func test_get_enemy_scene_invalid_index() -> void:
	var scene = PackedScene.new()
	_roster.enemy_types = [scene]

	assert_object(_roster.get_enemy_scene(1)).is_null()
	assert_object(_roster.get_enemy_scene(-1)).is_null()

func test_get_enemy_scene_empty_roster() -> void:
	_roster.enemy_types = []

	assert_object(_roster.get_enemy_scene(0)).is_null()

func test_get_random_enemy_scene_empty() -> void:
	_roster.enemy_types = []

	assert_object(_roster.get_random_enemy_scene()).is_null()

func test_get_random_enemy_scene_single() -> void:
	var scene = PackedScene.new()
	_roster.enemy_types = [scene]

	assert_object(_roster.get_random_enemy_scene()).is_equal(scene)

func test_get_random_enemy_scene_multiple() -> void:
	var scene1 = PackedScene.new()
	var scene2 = PackedScene.new()
	var scene3 = PackedScene.new()
	_roster.enemy_types = [scene1, scene2, scene3]

	var result = _roster.get_random_enemy_scene()

	assert_object(result).is_not_null()
	assert_bool(_roster.enemy_types.has(result)).is_true()

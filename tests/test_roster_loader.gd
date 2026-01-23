extends GdUnitTestSuite

const RosterLoader := preload("res://Gameplay/roster_loader.gd")

func test_load_player_roster_prefers_provided_units() -> void:
	var loader := RosterLoader.new()
	var provided := PlayerRoster.new()
	provided.units.append(PackedScene.new())

	var result := loader.load_player_roster(provided, null)
	assert_object(result).is_equal(provided)

func test_load_player_roster_uses_default_resource_when_missing() -> void:
	var loader := RosterLoader.new()
	var result := loader.load_player_roster(null, null, RosterLoader.DEFAULT_PLAYER_ROSTER_PATH)
	assert_object(result).is_not_null()
	if ResourceLoader.exists(RosterLoader.DEFAULT_PLAYER_ROSTER_PATH):
		var default_resource = load(RosterLoader.DEFAULT_PLAYER_ROSTER_PATH)
		if default_resource is PlayerRoster:
			assert_object(result).is_equal(default_resource)

func test_load_enemy_roster_populates_units_from_default() -> void:
	var loader := RosterLoader.new()
	var result := loader.load_enemy_roster(null, RosterLoader.DEFAULT_ENEMY_ROSTER_PATH)
	assert_object(result).is_not_null()
	assert_bool(result is EnemyRoster).is_true()
	if ResourceLoader.exists(RosterLoader.DEFAULT_ENEMY_ROSTER_PATH):
		var default_resource = load(RosterLoader.DEFAULT_ENEMY_ROSTER_PATH)
		if default_resource is EnemyRoster:
			assert_int(result.units.size()).is_equal(default_resource.units.size())

func test_load_neutral_roster_populates_units_from_default() -> void:
	var loader := RosterLoader.new()
	var result := loader.load_neutral_roster(null, RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH)
	assert_object(result).is_not_null()
	assert_bool(result is NeutralRoster).is_true()
	if ResourceLoader.exists(RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH):
		var default_resource = load(RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH)
		if default_resource is NeutralRoster:
			assert_int(result.units.size()).is_equal(default_resource.units.size())

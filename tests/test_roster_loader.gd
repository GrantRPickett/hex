extends GdUnitTestSuite

const RosterLoader := preload("res://Gameplay/roster/roster_loader.gd")

func test_load_player_roster_prefers_provided_units() -> void:
	var loader := RosterLoader.new()
	var provided := PlayerRoster.new()
	provided.units.append(PackedScene.new())

	var result := loader.load_player_roster(provided, null)
	assert_object(result).is_equal(provided)

func test_load_player_roster_falls_back_when_empty() -> void:
	var loader := RosterLoader.new()
	var provided := PlayerRoster.new()
	var result := loader.load_player_roster(provided, null, RosterLoader.DEFAULT_PLAYER_ROSTER_PATH)
	if ResourceLoader.exists(RosterLoader.DEFAULT_PLAYER_ROSTER_PATH):
		var default_resource: Resource = load(RosterLoader.DEFAULT_PLAYER_ROSTER_PATH)
		if default_resource is PlayerRoster:
			assert_bool(result is PlayerRoster).is_true()
			assert_int(result.units.size()).is_equal(default_resource.units.size())

func test_load_player_roster_uses_default_resource_when_missing() -> void:
	var loader := RosterLoader.new()
	var result := loader.load_player_roster(null, null, RosterLoader.DEFAULT_PLAYER_ROSTER_PATH)
	assert_object(result).is_not_null()
	if ResourceLoader.exists(RosterLoader.DEFAULT_PLAYER_ROSTER_PATH):
		var default_resource: Resource = load(RosterLoader.DEFAULT_PLAYER_ROSTER_PATH)
		if default_resource is PlayerRoster:
			assert_bool(result is PlayerRoster).is_true()
			assert_int(result.units.size()).is_equal(default_resource.units.size())

func test_load_enemy_roster_populates_units_from_default() -> void:
	var loader := RosterLoader.new()
	var result := loader.load_enemy_roster(null, RosterLoader.DEFAULT_ENEMY_ROSTER_PATH)
	assert_object(result).is_not_null()
	assert_bool(result is EnemyRoster).is_true()
	if ResourceLoader.exists(RosterLoader.DEFAULT_ENEMY_ROSTER_PATH):
		var default_resource: Resource = load(RosterLoader.DEFAULT_ENEMY_ROSTER_PATH)
		if default_resource is EnemyRoster:
			assert_int(result.units.size()).is_equal(default_resource.units.size())

func test_load_enemy_roster_falls_back_when_provided_empty() -> void:
	var loader := RosterLoader.new()
	var provided := EnemyRoster.new()
	var result := loader.load_enemy_roster(provided, RosterLoader.DEFAULT_ENEMY_ROSTER_PATH)
	if ResourceLoader.exists(RosterLoader.DEFAULT_ENEMY_ROSTER_PATH):
		var default_resource: Resource = load(RosterLoader.DEFAULT_ENEMY_ROSTER_PATH)
		if default_resource is EnemyRoster:
			assert_object(result).is_equal(default_resource)

func test_load_neutral_roster_populates_units_from_default() -> void:
	var loader := RosterLoader.new()
	var result := loader.load_neutral_roster(null, RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH)
	assert_object(result).is_not_null()
	assert_bool(result is NeutralRoster).is_true()
	if ResourceLoader.exists(RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH):
		var default_resource: Resource = load(RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH)
		if default_resource is NeutralRoster:
			assert_int(result.units.size()).is_equal(default_resource.units.size())

func test_load_neutral_roster_falls_back_when_provided_empty() -> void:
	var loader := RosterLoader.new()
	var provided := NeutralRoster.new()
	var result := loader.load_neutral_roster(provided, RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH)
	if ResourceLoader.exists(RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH):
		var default_resource: Resource = load(RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH)
		if default_resource is NeutralRoster:
			assert_object(result).is_equal(default_resource)
func testbuild_core_player_roster_loads_core_characters() -> void:
	var loader := RosterLoader.new()
	var roster := loader.build_core_player_roster()
	assert_object(roster).is_not_null()
	assert_bool(roster is PlayerRoster).is_true()
	assert_int(roster.units.size()).is_greater(0)

func test_load_player_roster_falls_back_to_core_directory() -> void:
	var loader := RosterLoader.new()
	var result := loader.load_player_roster(null, null, "res://missing_default_roster.tres")
	assert_object(result).is_not_null()
	assert_int(result.units.size()).is_greater(0)

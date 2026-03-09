extends GdUnitTestSuite

const LevelRosterServiceClass = preload("res://level/level_roster_service.gd")
const RosterLoaderClass = preload("res://Gameplay/roster/roster_loader.gd")
const SaveManagerClass = preload("res://Core/save_manager.gd")
const PlayerRosterClass = preload("res://Gameplay/roster/player_roster.gd")

class FakeSaveManager extends Node:
	var name_val = "Alice"
	func get_leader_unit_name() -> String:
		return name_val
	func set_leader_unit_name(v: String) -> void:
		name_val = v

func test_refresh_player_roster() -> void:
	var srv = auto_free(LevelRosterServiceClass.new())
	var state = GameState.new({})
	var ro = PlayerRosterClass.new()
	state.player_roster = ro

	# just ensure no crash
	srv.refresh_player_roster(state)

func test_determine_leader_name() -> void:
	var srv = auto_free(LevelRosterServiceClass.new())
	var sm = auto_free(FakeSaveManager.new())
	var ro = auto_free(PlayerRosterClass.new())

	srv.setup(sm)
	var name = srv.determine_leader_name(ro)
	assert_str(name).is_equal("Alice")

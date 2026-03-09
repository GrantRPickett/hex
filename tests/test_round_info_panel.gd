extends GdUnitTestSuite

const RoundInfoPanelScene = preload("res://GUI/round_info_panel.tscn")

func _make_panel() -> Node:
	var p = RoundInfoPanelScene.instantiate()
	add_child(p)
	return p

func after_test() -> void:
	for child in get_children():
		child.queue_free()

func test_update_round() -> void:
	var panel = _make_panel()
	panel.update_round(5)
	
	# Verify it formatted correctly
	# The format string is usually "Round {num}", so we look for "5"
	var text = panel._round_label.text
	assert_bool(text.contains("5")).is_true()

func test_update_turn() -> void:
	var panel = _make_panel()
	panel.update_turn(0) # Player
	assert_bool(panel._turn_label.text.length() > 0).is_true()
	assert_object(panel._turn_label.modulate).is_equal(Color.GREEN)
	
	panel.update_turn(1) # Enemy
	assert_object(panel._turn_label.modulate).is_equal(Color.RED)
	
	panel.update_turn(2) # Neutral
	assert_object(panel._turn_label.modulate).is_equal(Color.GOLD)

func test_update_enabled() -> void:
	var panel = _make_panel()
	panel.update_enabled(false)
	assert_object(panel._turn_label.modulate).is_equal(Color.GRAY)
	
	panel.update_enabled(true)
	# Next turn update should reflect its normal state
	panel.update_turn(0)
	assert_object(panel._turn_label.modulate).is_equal(Color.GREEN)

func test_update_turn_status() -> void:
	var panel = _make_panel()
	var counts = {
		0: 2, # Player
		1: 3, # Enemy
		2: 0  # Neutral
	}
	panel.update_turn_status(counts)
	
	assert_str(panel._player_count_label.text).contains("2")
	assert_bool(panel._player_count_label.visible).is_true()
	
	assert_str(panel._enemy_count_label.text).contains("3")
	assert_bool(panel._enemy_count_label.visible).is_true()
	
	assert_bool(panel._neutral_count_label.visible).is_false()

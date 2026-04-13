extends GdUnitTestSuite

## Verification for Unit Visual Helpers (Squash & Stretch, Wiggle)

const UNIT_SCENE := preload("res://Gameplay/targets/unit.gd")

func test_ss_cycle_on_selection() -> void:
	var unit_manager = auto_free(UnitManager.new())
	var unit1 = auto_free(UNIT_SCENE.new())
	var unit2 = auto_free(UNIT_SCENE.new())
	
	# Add to tree so tweens can run
	get_tree().root.add_child(unit_manager)
	unit_manager.add_child(unit1)
	unit_manager.add_child(unit2)
	
	# Components are initialized in _ready
	unit1._ready()
	unit2._ready()
	
	# Mock units to be player controlled for selection cycle
	unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	unit_manager.add_unit(unit2, Vector2i(1, 0), true)
	
	# Initial selection (unit1 was selected when added)
	assert_bool(is_instance_valid(unit1.visual_helper._ss_tween)).is_true()
	assert_bool(is_instance_valid(unit2.visual_helper._ss_tween)).is_false()
	
	# Change selection to unit2
	unit_manager.select_index(1)
	
	# Unit1 should have stopped SS and reset
	assert_bool(is_instance_valid(unit1.visual_helper._ss_tween)).is_false()
	assert_object(unit1.get_node("Sprite2D").scale).is_equal(Vector2(2, 2))
	
	# Unit2 should have started SS
	assert_bool(is_instance_valid(unit2.visual_helper._ss_tween)).is_true()

func test_wiggle_behavior() -> void:
	var unit = auto_free(UNIT_SCENE.new())
	get_tree().root.add_child(unit)
	unit._ready()
	
	var sprite = unit.get_node("Sprite2D")
	
	# Initial state
	assert_float(sprite.rotation).is_equal(0.0)
	assert_bool(is_instance_valid(unit.visual_helper._wiggle_tween)).is_false()
	
	# Trigger wiggle
	unit.trigger_wiggle()
	assert_bool(is_instance_valid(unit.visual_helper._wiggle_tween)).is_true()
	
	# Stop wiggle
	unit.stop_wiggle()
	assert_bool(is_instance_valid(unit.visual_helper._wiggle_tween)).is_false()
	assert_float(sprite.rotation).is_equal(0.0)
	assert_object(sprite.scale).is_equal(Vector2(2, 2))

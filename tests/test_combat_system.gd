extends "res://tests/test_utils.gd"

const COMBAT_SYSTEM_PATH := "res://Gameplay/combat_system.gd"

var _combat_system: Node

func before_test() -> void:
	_combat_system = load(COMBAT_SYSTEM_PATH).new()
	add_child(_combat_system)

func after_test() -> void:
	_combat_system.queue_free()

func test_register_unit_sets_defaults() -> void:
	_combat_system.register_unit(0)
	assert_that(_combat_system.get_unit_hp(0)).is_equal(3)
	assert_that(_combat_system.is_unit_alive(0)).is_true()

func test_combat_damage_calculation() -> void:
	_combat_system.register_unit(1, 10, 3) # Attacker: 3 Attack
	_combat_system.register_unit(2, 10, 1) # Defender: 10 HP

	_combat_system.execute_combat(1, 2)

	assert_that(_combat_system.get_unit_hp(2)).is_equal(7)
	assert_that(_combat_system.get_unit_hp(1)).is_equal(10)

func test_unregister_unit() -> void:
	_combat_system.register_unit(1, 10, 3)
	assert_that(_combat_system.is_unit_alive(1)).is_true()
	_combat_system.unregister_unit(1)
	assert_that(_combat_system.is_unit_alive(1)).is_false()

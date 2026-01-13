class_name CombatSystem
extends Node

# Emitted when an attack occurs and damage is dealt
signal attack_occurred(attacker_index: int, defender_index: int, damage: int)
# Emitted when a unit's HP reaches 0
signal unit_defeated(unit_index: int)

# Dictionary to store stats: { unit_index: { "hp": int, "max_hp": int, "attack": int } }
var _unit_stats: Dictionary = {}

const DEFAULT_HP := 3
const DEFAULT_ATTACK := 1

func register_unit(unit_index: int, hp: int = DEFAULT_HP, attack: int = DEFAULT_ATTACK) -> void:
	_unit_stats[unit_index] = {
		"hp": hp,
		"max_hp": hp,
		"attack": attack
	}

func unregister_unit(unit_index: int) -> void:
	if _unit_stats.has(unit_index):
		_unit_stats.erase(unit_index)

func execute_combat(attacker_index: int, defender_index: int) -> void:
	if not _unit_stats.has(attacker_index) or not _unit_stats.has(defender_index):
		push_warning("CombatSystem: Unit indices not registered for combat.")
		return

	var damage: int = _unit_stats[attacker_index]["attack"]
	_unit_stats[defender_index]["hp"] -= damage

	attack_occurred.emit(attacker_index, defender_index, damage)

	if _unit_stats[defender_index]["hp"] <= 0:
		_unit_stats[defender_index]["hp"] = 0
		unit_defeated.emit(defender_index)

func get_unit_hp(unit_index: int) -> int:
	if _unit_stats.has(unit_index):
		return _unit_stats[unit_index]["hp"]
	return 0

func is_unit_alive(unit_index: int) -> bool:
	return get_unit_hp(unit_index) > 0
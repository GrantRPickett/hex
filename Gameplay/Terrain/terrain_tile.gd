class_name TerrainTile
extends Node2D

@export var passable: bool = true
@export var movement_penalty: int = 0
@export var movement_bonus: int = 0
@export var status_effect: StringName = StringName()
@export var blocks_action_after_move: bool = false
@export var color: Color = GameColors.WHITE
@export var texture_path: String = ""
@export var description: String = ""

func get_movement_adjustment() -> int:
	return movement_bonus - movement_penalty

func get_modified_movement_cost(weather_attribute: WeatherAttribute) -> int:
	var base_cost: int = 1 + movement_penalty - movement_bonus
	var modified_cost: int = base_cost

	if weather_attribute:
		# Apply general movement cost modifier from weather attribute
		modified_cost += roundi(base_cost * weather_attribute.movement_cost_modifier)

		# Apply humidity effects (example: wet weather might increase cost on grass/mud)
		# This is a generic example, more specific logic might be needed per terrain type
		if weather_attribute.humidity_effect > 0.5: # Very wet
			if passable and not (status_effect == "slippery"): # Example: not already slippery
				modified_cost += 1 # Increase cost for wet conditions
		elif weather_attribute.humidity_effect < -0.5: # Very dry
			# Potentially reduce cost for dry conditions on certain terrains, or add dust effects
			pass

		# Apply temperature effects (example: cold weather might increase cost on open terrain)
		if weather_attribute.temperature_effect < -0.5: # Very cold
			if passable:
				modified_cost += 1 # Increase cost for cold conditions
		elif weather_attribute.temperature_effect > 0.5: # Very hot
			# Potentially increase cost for hot conditions
			pass

	return max(1, modified_cost) # Ensure minimum cost is 1

func apply_to_unit(unit: Unit) -> void:
	if unit == null:
		return
	if not passable:
		unit.block_movement_this_turn()
		return
	var adjustment := get_movement_adjustment()
	if adjustment != 0:
		unit.adjust_remaining_movement(adjustment)
	if blocks_action_after_move:
		unit.block_action_this_turn()
	if not status_effect.is_empty():
		unit.status.apply_status_effect(status_effect)

func get_hover_info() -> String:
	var type_name: String = self.get_class().replace("Terrain", "")
	var info_text: String = tr("hud.label.terrain_name").format({"name": tr("terrain." + type_name.to_lower())})
	if not passable:
		info_text += "\n" + tr("terrain.impassable")
	else:
		if movement_penalty > 0:
			info_text += "\n" + tr("hud.label.movement_penalty").format({"val": movement_penalty})
		if movement_bonus > 0:
			info_text += "\n" + tr("hud.label.movement_bonus").format({"val": movement_bonus})
	if not status_effect.is_empty():
		info_text += "\n" + tr("terrain.effect_label").format({"name": tr("terrain.effect." + status_effect.to_lower())})
	if blocks_action_after_move:
		info_text += "\n" + tr("hud.label.ends_turn")
	if not description.is_empty():
		info_text += "\n" + tr(description)
	return info_text

## Null Object implementation for TerrainTile
class NullTerrain extends TerrainTile:
	func _init() -> void:
		passable = false
		movement_penalty = 999
		movement_bonus = 0
		status_effect = ""
		blocks_action_after_move = false

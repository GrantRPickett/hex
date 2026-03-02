class_name TerrainDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

var _type_label: Label
var _effect_label: Label
var _distance_label: Label


func _init() -> void:
	name = "TerrainDetailsPanel"


	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	add_child(vbox)

	_type_label = Label.new()
	_type_label.name = "TypeLabel"
	vbox.add_child(_type_label)

	_effect_label = Label.new()
	_effect_label.name = "EffectLabel"
	vbox.add_child(_effect_label)

	_distance_label = Label.new()
	_distance_label.name = "DistanceLabel"
	vbox.add_child(_distance_label)

var _last_terrain_uid: int = -1
var _last_distance: String = ""

func update_details(terrain: TerrainTile, distance: String) -> void:
	if not is_node_ready():
		return
	if terrain == null or (terrain is TerrainTile.NullTerrain):
		if visible:
			hide()
			_last_terrain_uid = -1
		return

	var terrain_uid = terrain.get_instance_id()
	if visible and terrain_uid == _last_terrain_uid and distance == _last_distance:
		return

	_last_terrain_uid = terrain_uid
	_last_distance = distance

	show()

	var type_name = LocalizationStrings.get_text("hud.terrain_fallback_name")
	if terrain.get_script() and terrain.get_script().resource_path:
		var script_path = terrain.get_script().resource_path
		var file_name = script_path.get_file().get_basename()
		type_name = file_name.replace("_terrain", "").capitalize()
	_type_label.text = LocalizationStrings.get_text("hud.terrain_type").format({"type": type_name})

	var effect_parts: Array[String] = []
	if not terrain.passable:
		effect_parts.append(LocalizationStrings.get_text("hud.terrain_effect_impassable"))
	else:
		var cost = 1 + terrain.movement_penalty - terrain.movement_bonus
		effect_parts.append(LocalizationStrings.get_text("hud.terrain_effect_cost").format({"cost": cost}))
		if terrain.blocks_action_after_move:
			effect_parts.append(LocalizationStrings.get_text("hud.terrain_effect_ends_turn"))
		if not terrain.status_effect.is_empty():
			effect_parts.append(terrain.status_effect)
	var effects_combined = ", ".join(effect_parts)
	_effect_label.text = LocalizationStrings.get_text("hud.terrain_effects").format({"effects": effects_combined})
	_distance_label.text = LocalizationStrings.get_text("hud.terrain_distance").format({"distance": distance})
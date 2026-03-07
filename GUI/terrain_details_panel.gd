class_name TerrainDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

@onready var _type_label: Label = $VBoxContainer/TerrainNameLabel
@onready var _effect_label: Label = $VBoxContainer/MovementCostLabel
@onready var _distance_label: Label = $VBoxContainer/DefenseBonusLabel

var _last_terrain_uid: int = -1
var _last_distance: String = ""

func _ready() -> void:
	super._ready()
	hide()

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

	var type_name = "stone"
	if terrain.get_script() and terrain.get_script().resource_path:
		var script_path = terrain.get_script().resource_path
		type_name = script_path.get_file().get_basename().replace("_terrain", "")
	_type_label.text = tr("hud.label.terrain_name").format({"name": tr("terrain." + type_name)})

	var effect_parts: Array[String] = []
	if not terrain.passable:
		effect_parts.append(tr("terrain.impassable"))
	else:
		var cost = 1 + terrain.movement_penalty - terrain.movement_bonus
		effect_parts.append(tr("hud.label.movement_penalty").format({"val": cost}))
		if terrain.blocks_action_after_move:
			effect_parts.append(tr("hud.label.ends_turn"))
		if not terrain.status_effect.is_empty():
			effect_parts.append(tr("terrain.effect." + terrain.status_effect.to_lower()))
	var effects_combined = ", ".join(effect_parts)
	_effect_label.text = tr("hud.label.terrain_effects").format({"effects": effects_combined})
	_distance_label.text = tr("hud.label.terrain_distance").format({"distance": distance})
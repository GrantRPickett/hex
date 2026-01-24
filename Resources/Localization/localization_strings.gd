extends RefCounted

const DEFAULT_LANGUAGE := "en"
const _STRINGS_BY_LANGUAGE := {
	"en": {
		"menus.title.heading": "HEX",
		"menus.title.play": "Play",
		"menus.title.quit": "Quit",
		"menus.title.level_select": "Level Select",
		"menus.title.continue": "Continue",
		"hud.end_turn": "End Turn",
		"hud.turn_counter": "Turn {turn_number}",
		"hud.round_label": "Round: {round}",
		"hud.turn_label": "Turn: {side}",
		"hud.turn_player": "Player",
		"hud.turn_enemy": "Enemy",
		"hud.active_unit_summary": "Active: {unit} (Action: {action}, Move: {move})",
		"hud.unit_name_fallback": "Unit",
		"hud.enemy_fallback": "Enemy",
		"hud.unit_stats": "{faction} | WP: {current}/{max}",
		"hud.movement_summary": "Moves: {moves}/{max_moves} | Action: {action}",
		"hud.status_stuck": "Status: STUCK!",
		"hud.status_ok": "Status: OK",
		"hud.generic_yes": "Yes",
		"hud.generic_no": "No",
		"hud.actions_hint": "Actions available",
		"hud.goal_label": "Goal: {name}",
		"hud.goal_fallback_name": "Goal",
		"hud.goal_type": "Type: {type}",
		"hud.goal_progress": "P: {player} / E: {enemy}",
		"hud.goal_required": "Required: {amount}",
		"hud.terrain_fallback_name": "Terrain",
		"hud.terrain_type": "Type: {type}",
		"hud.terrain_effects": "Effects: {effects}",
		"hud.terrain_effect_impassable": "Impassable",
		"hud.terrain_effect_cost": "Cost: {cost}",
		"hud.terrain_effect_ends_turn": "Ends Turn",
		"hud.terrain_distance": "Dist: {distance}",
		"hud.combat_preview.target": "Target: {name}",
		"hud.combat_preview.faction": "Faction: {faction}",
		"hud.combat_preview.willpower": "WP: {current}/{max}",
		"hud.combat_preview.range": "Range: {distance} / {max_range}",
		"hud.combat_preview.can_attack": "Can Attack: {value}",
		"combat.victory": "Victory",
		"combat.defeat": "Defeat",
	},
	"es": {
		"menus.title.heading": "HEX",
		"menus.title.play": "Jugar",
		"menus.title.quit": "Salir",
		"menus.title.level_select": "Seleccionar nivel",
		"menus.title.continue": "Continuar",
		"hud.end_turn": "Terminar turno",
		"hud.turn_counter": "Turno {turn_number}",
		"hud.round_label": "Ronda: {round}",
		"hud.turn_label": "Turno: {side}",
		"hud.turn_player": "Jugador",
		"hud.turn_enemy": "Enemigo",
		"hud.active_unit_summary": "Activo: {unit} (Acción: {action}, Movimiento: {move})",
		"hud.unit_name_fallback": "Unidad",
		"hud.enemy_fallback": "Enemigo",
		"hud.unit_stats": "{faction} | VP: {current}/{max}",
		"hud.movement_summary": "Mov.: {moves}/{max_moves} | Acción: {action}",
		"hud.status_stuck": "Estado: ATASCADO!",
		"hud.status_ok": "Estado: OK",
		"hud.generic_yes": "Sí",
		"hud.generic_no": "No",
		"hud.actions_hint": "Acciones disponibles",
		"hud.goal_label": "Objetivo: {name}",
		"hud.goal_fallback_name": "Objetivo",
		"hud.goal_type": "Tipo: {type}",
		"hud.goal_progress": "J: {player} / E: {enemy}",
		"hud.goal_required": "Requerido: {amount}",
		"hud.terrain_fallback_name": "Terreno",
		"hud.terrain_type": "Tipo: {type}",
		"hud.terrain_effects": "Efectos: {effects}",
		"hud.terrain_effect_impassable": "Impasable",
		"hud.terrain_effect_cost": "Costo: {cost}",
		"hud.terrain_effect_ends_turn": "Termina turno",
		"hud.terrain_distance": "Dist.: {distance}",
		"hud.combat_preview.target": "Objetivo: {name}",
		"hud.combat_preview.faction": "Facción: {faction}",
		"hud.combat_preview.willpower": "VP: {current}/{max}",
		"hud.combat_preview.range": "Alcance: {distance} / {max_range}",
		"hud.combat_preview.can_attack": "Puede atacar: {value}",
		"combat.victory": "Victoria",
		"combat.defeat": "Derrota",
	}
}

static func get_supported_languages() -> PackedStringArray:
	var languages := PackedStringArray()
	for code in _STRINGS_BY_LANGUAGE.keys():
		languages.append(code)
	return languages

static func has_language(language_code: StringName) -> bool:
	var normalized := _normalize_language(language_code)
	return _STRINGS_BY_LANGUAGE.has(normalized)

static func get_strings_for(language_code: StringName = DEFAULT_LANGUAGE) -> Dictionary:
	var resolved_language := _resolve_language(language_code)
	return _STRINGS_BY_LANGUAGE.get(resolved_language, _STRINGS_BY_LANGUAGE[DEFAULT_LANGUAGE]).duplicate(true)

static func has_key(key: String) -> bool:
	return _STRINGS_BY_LANGUAGE[DEFAULT_LANGUAGE].has(key)

static func get_text(key: String, language_code: StringName = DEFAULT_LANGUAGE) -> String:
	var resolved_language := _resolve_language(language_code)
	var language_table: Dictionary = _STRINGS_BY_LANGUAGE.get(resolved_language, _STRINGS_BY_LANGUAGE[DEFAULT_LANGUAGE])
	if language_table.has(key):
		return language_table[key]
	return _STRINGS_BY_LANGUAGE[DEFAULT_LANGUAGE].get(key, key)

static func _resolve_language(language_code: StringName) -> String:
	var normalized := _normalize_language(language_code)
	if _STRINGS_BY_LANGUAGE.has(normalized):
		return normalized
	if normalized.length() > 2:
		var short_code := normalized.substr(0, 2)
		if _STRINGS_BY_LANGUAGE.has(short_code):
			return short_code
	return DEFAULT_LANGUAGE

static func _normalize_language(language_code: StringName) -> String:
	if typeof(language_code) == TYPE_NIL:
		return DEFAULT_LANGUAGE
	var normalized_str := String(language_code).strip_edges().to_lower()
	if normalized_str.is_empty():
		return DEFAULT_LANGUAGE
	return normalized_str

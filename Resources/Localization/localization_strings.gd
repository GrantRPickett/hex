extends RefCounted

const HUD_NO_UNIT_SELECTED := "hud.no_unit_selected"
const HUD_ENEMY_UNIT_SELECTED := "hud.enemy_unit_selected"
const HUD_NO_ACTIONS_AVAILABLE := "hud.no_actions_available"
const HUD_SELECT_ATTRIBUTE := "hud.select_attribute"
const HUD_SELECT_TARGET := "hud.select_target"
const HUD_SELECT_ATTRIBUTE_TITLE := "hud.select_attribute_title"
const HUD_NO_ATTRIBUTES_AVAILABLE := "hud.no_attributes_available"
const HUD_ATTRIBUTE_VALUE := "hud.attribute_value"
const HUD_ACTION_ATTACK := "hud.action_attack"
const HUD_ACTION_BACK := "hud.action_back"
const HUD_TARGET_UNKNOWN := "hud.target_unknown"
const HUD_TARGET_MOVE_SUFFIX := "hud.target_move_suffix"
const HUD_TARGET_NA := "hud.target_na"
const HUD_TARGET_TRAPPED_LOOT := "hud.target_trapped_loot"
const HUD_TARGET_GENERIC := "hud.target_generic"
const HUD_PAUSE := "hud.pause"
const HUD_PAUSE_TOOLTIP := "hud.pause_tooltip"
const HUD_AUTO_BATTLE := "hud.auto_battle"
const HUD_AUTO_BATTLE_ON := "hud.auto_battle_on"
const HUD_AUTO_BATTLE_TOOLTIP := "hud.auto_battle_tooltip"

const HUD_ATTACKER := "hud.attacker"
const HUD_DEFENDER := "hud.defender"
const HUD_FORECAST_HOVER := "hud.forecast_hover"
const HUD_NO_FORECAST := "hud.no_forecast"
const HUD_FORECAST_POTENTIAL_DAMAGE := "hud.forecast_potential_damage"
const HUD_FORECAST_COUNTER_DAMAGE := "hud.forecast_counter_damage"
const HUD_ATTRIBUTES := "hud.attributes"
const HUD_ITEMS := "hud.items"
const HUD_LOCATION_NAME_LABEL := "hud.location_name_label"
const HUD_LOCATION_DESCRIPTION_LABEL := "hud.location_description_label"
const HUD_LOCATION_TASK_LABEL := "hud.location_task_label"
const HUD_LOCATION_ACTION_AVAILABLE_EXPLORE := "hud.location_action_available_explore"
const HUD_LOCATION_STAT_BOOSTS := "hud.location_stat_boosts"
const HUD_LOOT_EMPTY := "hud.loot_empty"
const HUD_LOOT_LABEL := "hud.loot_label"
const HUD_WEATHER_NEXT_ROUND := "hud.weather_next_round"
const HUD_WEATHER_NO_PRESSURES := "hud.weather_no_pressures"
const HUD_WEATHER_PRESSURES := "hud.weather_pressures"
const HUD_WEATHER_CURRENT := "hud.weather_current"

const HUD_TASK_NAME_LABEL := "hud.task_name_label"
const HUD_TASK_DESCRIPTION_LABEL := "hud.task_description_label"
const HUD_TASK_STATUS_LABEL := "hud.task_status_label"
const HUD_TASK_COMPLETED := "hud.task_completed"
const HUD_TASK_IN_PROGRESS := "hud.task_in_progress"
const HUD_TASK_UNKNOWN := "hud.task_unknown"
const HUD_ACTION_UNKNOWN := "hud.action_unknown"

const HUD_JOURNAL_SELECT_TOPIC := "hud.journal_select_topic"

const HUD_JOURNAL_SELECT_TOPIC_DESC := "hud.journal_select_topic_desc"
const HUD_JOURNAL_NO_TOPICS := "hud.journal_no_topics"
const HUD_JOURNAL_NO_TOPICS_DESC := "hud.journal_no_topics_desc"
const HUD_WEATHER_NO_ACTIVE := "hud.weather_no_active"

const HUD_MORALE_PLAYER := "hud.morale_player"


const HUD_MORALE_ENEMY := "hud.morale_enemy"
const HUD_MORALE_NEUTRAL := "hud.morale_neutral"

const HUD_DIRECTION_N := "hud.direction_n"

const HUD_DIRECTION_NE := "hud.direction_ne"
const HUD_DIRECTION_SE := "hud.direction_se"
const HUD_DIRECTION_S := "hud.direction_s"
const HUD_DIRECTION_SW := "hud.direction_sw"
const HUD_DIRECTION_NW := "hud.direction_nw"


const HUD_ACTION_MOVE_SPACES := "hud.action_move_spaces"
const HUD_ACTION_CONVINCE_UNIT := "hud.action_convince_unit"
const HUD_WEATHER_CHANNELING_BLOCKED := "hud.weather_channeling_blocked"
const HUD_ACTION_WAIT_END_TURN := "hud.action_wait_end_turn"
const HUD_ACTION_FIGHT := "hud.action_fight"
const HUD_ACTION_CONVINCE := "hud.action_convince"
const HUD_ACTION_MOVE_AND_INTERACT := "hud.action_move_and_interact"
const HUD_ACTION_MOVE_AND_INVESTIGATE := "hud.action_move_and_investigate"
const HUD_ACTION_MOVE_AND_GATHER := "hud.action_move_and_gather"
const HUD_ACTION_MOVE_AND_EXPLORE := "hud.action_move_and_explore"
const HUD_ACTION_MOVE_AND_VISIT := "hud.action_move_and_visit"

const HUD_ACTION_EXPLORE_LOCATION := "hud.action_explore_location"
const HUD_HINT_EXPLORE_LOCATION := "hud.hint_explore_location"
const HUD_ACTION_VISIT_LOCATION := "hud.action_visit_location"
const HUD_HINT_VISIT_LOCATION := "hud.hint_visit_location"
const HUD_HINT_CONVINCE_NEUTRAL := "hud.hint_convince_neutral"

const HUD_ACTION_FORMAT_ADJACENT := "hud.action_format_adjacent"
const HUD_ACTION_FORMAT_REACHABLE := "hud.action_format_reachable"
const HUD_ACTION_FORMAT_COMBINED := "hud.action_format_combined"
const HUD_ACTION_LABEL_ADJACENT := "hud.action_label_adjacent"
const HUD_ACTION_HINT_REACHABLE_FIGHT := "hud.action_hint_reachable_fight"
const HUD_ACTION_HINT_REACHABLE_CONVINCE := "hud.action_hint_reachable_convince"
const HUD_ACTION_LIST_SEPARATOR := "hud.action_list_separator"

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
		"hud.turn_neutral": "Neutral",
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
		"hud.location_label": "location: {name}",
		"hud.location_fallback_name": "location",
		"hud.location_type": "Type: {type}",
		"hud.location_progress": "P: {player} / E: {enemy}",
		"hud.location_required": "Required: {amount}",
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
		"hud.pause": "Pause",
		"hud.pause_tooltip": "Open game menu.",
		"hud.auto_battle": "Auto Act",
		"hud.auto_battle_on": "Auto Act (On)",
		"hud.auto_battle_tooltip": "Let the team handle actions until cancelled.",

		"hud.attacker": "Attacker: {name}",
		"hud.defender": "Defender: {name}",
		"hud.forecast_hover": "Hover to see forecast",
		"hud.no_forecast": "No forecast data",
		"hud.forecast_potential_damage": "Potential Damage: {dmg}",
		"hud.forecast_counter_damage": "Counter Damage: {counter}",
		"hud.attributes": "Attributes: {attributes}",
		"hud.items": "Items: {items}",
		"hud.location_name_label": "Location Name: {name}",
		"hud.location_description_label": "Description: {description}",
		"hud.location_task_label": "Task: {title} ({current}/{required})",
		"hud.location_action_available_explore": "[ACTION AVAILABLE: EXPLORE]",
		"hud.location_stat_boosts": "Stat Boosts:",
		"hud.loot_empty": "Loot: (Empty)",
		"hud.loot_label": "Loot:",
		"hud.weather_next_round": "Next Round: {name}",
		"hud.weather_no_pressures": "No pressures active.",
		"hud.weather_pressures": "Pressures: {pressures}",
		"hud.weather_current": "Current: {name}",
		"hud.task_name_label": "Task Name: {title}",
		"hud.task_description_label": "Task Description: {description}",
		"hud.task_status_label": "Status: {status}",
		"hud.task_completed": "Completed",
		"hud.task_in_progress": "In Progress",
		"hud.task_unknown": "Unknown Task",
		"hud.action_unknown": "Unknown Action",
		"hud.journal_select_topic": "Select a Topic",

		"hud.journal_select_topic_desc": "Choose a section and a topic from the lists on the left to view documentation.",
		"hud.journal_no_topics": "No Topics",
		"hud.journal_no_topics_desc": "No entries have been unlocked in this section yet.",
		"hud.weather_no_active": "No active weather.",
		"hud.morale_player": "Player: {ratio}%",


		"hud.morale_enemy": "Enemy: {ratio}%",
		"hud.morale_neutral": "Neutral: {ratio}%",
		"hud.direction_n": "N",

		"hud.direction_ne": "NE",
		"hud.direction_se": "SE",
		"hud.direction_s": "S",
		"hud.direction_sw": "SW",
		"hud.direction_nw": "NW",

		"hud.no_unit_selected": "No unit selected",
		"hud.enemy_unit_selected": "Enemy unit selected",
		"hud.no_actions_available": "No actions available",
		"hud.select_attribute": "Select an attribute for {action}",
		"hud.select_target": "Select Target",
		"hud.select_attribute_title": "Select Attribute",
		"hud.no_attributes_available": "No attributes available",
		"hud.attribute_value": "{attribute} ({value})",
		"hud.action_attack": "Attack",
		"hud.action_back": "Back",
		"hud.target_unknown": "Unknown Target",
		"hud.target_move_suffix": " (Move)",
		"hud.target_na": "N/A",
		"hud.target_trapped_loot": "Trapped Loot",
		"hud.target_generic": "Target",

		"location_opposed": "Explore",
		"location_unopposed": "Visit",
		"unit_opposed": "Fight",
		"unit_unopposed": "Talk",
		"item_opposed": "Investigate Trap",
		"item_unopposed": "Gather",

		"wait": "Wait / End Turn",
		"move": "Move ({spaces} spaces)",
		"skill": "{skill_name}",
		"action_convince": "Convince", # Special case handled by UI

		"action_move_and_interact": "Move & {action} {target} (M{move}/A{action_point})",
		"action_move_and_investigate": "Move & Investigate Trap (M{move}/A1)",
		"action_move_and_gather": "Move & Gather (M{move})",
		"action_move_and_explore": "Move & Explore (M{move}/A1)",
		"action_move_and_visit": "Move & Visit (M{move}/A1)",

		"hud.hint_explore_location": "Requires an attribute check to explore.",
		"hud.hint_visit_location": "Unopposed interaction.",
		"hud.hint_convince_neutral": "Persuade neutral unit.",

		"hud.action_format_adjacent": "{count} {label}",
		"hud.action_format_reachable": "{count} reachable",
		"hud.action_format_combined": "{base} ({details})",
		"hud.action_label_adjacent": "adjacent",
		"hud.action_label_here": "here",
		"hud.action_hint_reachable_fight": "Move adjacent to attack reachable enemies.",
		"hud.action_hint_reachable_convince": "Move adjacent to convince reachable neutrals.",
		"hud.action_list_separator": ", ",
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
		"hud.location_label": "Objetivo: {name}",
		"hud.location_fallback_name": "Objetivo",
		"hud.location_type": "Tipo: {type}",
		"hud.location_progress": "J: {player} / E: {enemy}",
		"hud.location_required": "Requerido: {amount}",
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
		"hud.pause": "Pausa",
		"hud.pause_tooltip": "Abrir menú del juego.",
		"hud.auto_battle": "Auto Actuar",
		"hud.auto_battle_on": "Auto Actuar (Act.)",
		"hud.auto_battle_tooltip": "Permitir que el equipo maneje las acciones hasta que se cancele.",

		"hud.attacker": "Atacante: {name}",
		"hud.defender": "Defensor: {name}",
		"hud.forecast_hover": "Pasa el ratón para ver el pronóstico",
		"hud.no_forecast": "Sin datos de pronóstico",
		"hud.forecast_potential_damage": "Daño Potencial: {dmg}",
		"hud.forecast_counter_damage": "Daño de Contraataque: {counter}",
		"hud.attributes": "Atributos: {attributes}",
		"hud.items": "Objetos: {items}",
		"hud.location_name_label": "Nombre de la ubicación: {name}",
		"hud.location_description_label": "Descripción: {description}",
		"hud.location_task_label": "Tarea: {title} ({current}/{required})",
		"hud.location_action_available_explore": "[ACCIÓN DISPONIBLE: EXPLORAR]",
		"hud.location_stat_boosts": "Mejoras de estadísticas:",
		"hud.loot_empty": "Botín: (Vacío)",
		"hud.loot_label": "Botín:",
		"hud.weather_next_round": "Siguiente Ronda: {name}",
		"hud.weather_no_pressures": "No hay presiones activas.",
		"hud.weather_pressures": "Presiones: {pressures}",
		"hud.weather_current": "Actual: {name}",
		"hud.task_name_label": "Nombre de la Tarea: {title}",
		"hud.task_description_label": "Descripción de la Tarea: {description}",
		"hud.task_status_label": "Estado: {status}",
		"hud.task_completed": "Completada",
		"hud.task_in_progress": "En Progreso",
		"hud.task_unknown": "Tarea Desconocida",
		"hud.action_unknown": "Acción Desconocida",
		"hud.journal_select_topic": "Selecciona un Tema",

		"hud.journal_select_topic_desc": "Elige una sección y un tema de las listas para ver la documentación.",
		"hud.journal_no_topics": "SIn Temas",
		"hud.journal_no_topics_desc": "Aún no se han desbloqueado entradas en esta sección.",
		"hud.weather_no_active": "Sin clima activo.",
		"hud.morale_player": "Jugador: {ratio}%",


		"hud.morale_enemy": "Enemigo: {ratio}%",
		"hud.morale_neutral": "Neutral: {ratio}%",
		"hud.direction_n": "N",

		"hud.direction_ne": "NE",
		"hud.direction_se": "SE",
		"hud.direction_s": "S",
		"hud.direction_sw": "SO",
		"hud.direction_nw": "NO",
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

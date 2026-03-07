extends RefCounted

# --- HUD Common ---
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

# --- Forecast & Combat ---
const HUD_ATTACKER := "hud.attacker"
const HUD_DEFENDER := "hud.defender"
const HUD_FORECAST_HOVER := "hud.forecast_hover"
const HUD_NO_FORECAST := "hud.no_forecast"
const HUD_FORECAST_POTENTIAL_DAMAGE := "hud.forecast_potential_damage"
const HUD_FORECAST_COUNTER_DAMAGE := "hud.forecast_counter_damage"
const HUD_ATTRIBUTES := "hud.attributes"
const HUD_ITEMS := "hud.items"

# --- Locations & Terrain ---
const HUD_LOCATION_NAME_LABEL := "hud.location_name_label"
const HUD_LOCATION_DESCRIPTION_LABEL := "hud.location_description_label"
const HUD_LOCATION_TASK_LABEL := "hud.location_task_label"
const HUD_LOCATION_ACTION_AVAILABLE_EXPLORE := "hud.location_action_available_explore"
const HUD_LOCATION_STAT_BOOSTS := "hud.location_stat_boosts"
const HUD_LOOT_EMPTY := "hud.loot_empty"
const HUD_LOOT_LABEL := "hud.loot_label"

# --- Weather ---
const HUD_WEATHER_NEXT_ROUND := "hud.weather_next_round"
const HUD_WEATHER_NO_PRESSURES := "hud.weather_no_pressures"
const HUD_WEATHER_PRESSURES := "hud.weather_pressures"
const HUD_WEATHER_CURRENT := "hud.weather_current"
const HUD_WEATHER_NO_ACTIVE := "hud.weather_no_active"
const HUD_WEATHER_CHANNELING_BLOCKED := "hud.weather_channeling_blocked"

# --- Tasks ---
const HUD_TASK_NAME_LABEL := "hud.task_name_label"
const HUD_TASK_DESCRIPTION_LABEL := "hud.task_description_label"
const HUD_TASK_STATUS_LABEL := "hud.task_status_label"
const HUD_TASK_COMPLETED := "hud.task_completed"
const HUD_TASK_IN_PROGRESS := "hud.task_in_progress"
const HUD_TASK_UNKNOWN := "hud.task_unknown"
const HUD_ACTION_UNKNOWN := "hud.action_unknown"

# --- Journal ---
const HUD_JOURNAL_SELECT_TOPIC := "hud.journal_select_topic"
const HUD_JOURNAL_SELECT_TOPIC_DESC := "hud.journal_select_topic_desc"
const HUD_JOURNAL_NO_TOPICS := "hud.journal_no_topics"
const HUD_JOURNAL_NO_TOPICS_DESC := "hud.journal_no_topics_desc"

# --- Morale & Factions ---
const HUD_MORALE_PLAYER := "hud.morale_player"
const HUD_MORALE_ENEMY := "hud.morale_enemy"
const HUD_MORALE_NEUTRAL := "hud.morale_neutral"
const HUD_FACTION_PLAYER := "hud.faction_player"
const HUD_FACTION_ENEMY := "hud.faction_enemy"
const HUD_FACTION_NEUTRAL := "hud.faction_neutral"

# --- Directions ---
const HUD_DIRECTION_N := "hud.direction_n"
const HUD_DIRECTION_NE := "hud.direction_ne"
const HUD_DIRECTION_SE := "hud.direction_se"
const HUD_DIRECTION_S := "hud.direction_s"
const HUD_DIRECTION_SW := "hud.direction_sw"
const HUD_DIRECTION_NW := "hud.direction_nw"

# --- Actions & Hints ---
const HUD_ACTION_MOVE_SPACES := "hud.action_move_spaces"
const HUD_ACTION_CONVINCE_UNIT := "hud.action_convince_unit"
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
const HUD_HINT_WAIT := "hud.hint_wait"
const HUD_HINT_UNDO := "hud.hint_undo"
const HUD_HINT_MOVE := "hud.hint_move"
const HUD_HINT_SKILL := "hud.hint_skill"
const HUD_HINT_AID := "hud.hint_aid"
const HUD_HINT_TALK := "hud.hint_talk"
const HUD_HINT_LOOT := "hud.hint_loot"
const HUD_HINT_TRAPPED := "hud.hint_trapped"
const HUD_HINT_FIGHT := "hud.action_hint_fight"

# --- Action Formats ---
const HUD_ACTION_FORMAT_ADJACENT := "hud.action_format_adjacent"
const HUD_ACTION_FORMAT_REACHABLE := "hud.action_format_reachable"
const HUD_ACTION_FORMAT_COMBINED := "hud.action_format_combined"
const HUD_ACTION_LABEL_ADJACENT := "hud.action_label_adjacent"
const HUD_ACTION_HINT_REACHABLE_FIGHT := "hud.action_hint_reachable_fight"
const HUD_ACTION_HINT_REACHABLE_CONVINCE := "hud.action_hint_reachable_convince"
const HUD_ACTION_LIST_SEPARATOR := "hud.action_list_separator"

# --- Round & Turn ---
const HUD_ROUND_LABEL := "hud.label.round"
const HUD_TURN_FORMAT := "hud.label.turn"
const HUD_STATUS_BUSY := "hud.status_busy"
const HUD_TURN_PLAYER := "hud.turn_player"
const HUD_TURN_ENEMY := "hud.turn_enemy"
const HUD_TURN_NEUTRAL := "hud.turn_neutral"

## Wrapper around Godot's tr() for backward compatibility and type safety.
static func get_text(key: String, _language_code: StringName = &"") -> String:
	# Note: language_code is ignored as we use the global TranslationServer locale.
	# TranslationServer.translate() is the static version of tr().
	return TranslationServer.translate(StringName(key))

static func has_key(key: String) -> bool:
	# Godot's TranslationServer doesn't have an easy has_key, 
	# but translate() returning the key itself usually indicates it's missing 
	# (though not always if the translation IS the key).
	var sn_key := StringName(key)
	return TranslationServer.translate(sn_key) != sn_key

static func get_supported_languages() -> PackedStringArray:
	return TranslationServer.get_loaded_locales()

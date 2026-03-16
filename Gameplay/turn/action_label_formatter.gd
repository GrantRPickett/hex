const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

static func format(base: String, near_count: int, reachable_count: int, imm_label: String = "near") -> String:
	var detail: Array[String] = []
	if near_count > 0:
		var imm_key = "hud.action_label_" + imm_label
		var localized_imm = LocalizationStrings.get_text(imm_key)
		detail.append(LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_NEAR).format({
			"count": near_count,
			"label": localized_imm
		}))

	if reachable_count > 0:
		var far_label = "far" if near_count > 0 or imm_label == "near" else "reachable"
		var far_key = "hud.action_label_" + far_label
		var localized_far = LocalizationStrings.get_text(far_key)
		detail.append(LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_REACHABLE).format({
			"count": reachable_count,
			"label": localized_far
		}))
	if detail.is_empty():
		return base
	return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_COMBINED).format({
		"base": base,
		"details": LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_LIST_SEPARATOR).join(detail)
	})

static func get_label(action: UnitAction, target_name: String = "") -> String:
	var aid = action.action_id
	if aid == "":
		return action.label if not action.label.is_empty() else LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_UNKNOWN)

	var params: = action.label_params.duplicate()

	# Special case: move_and_interact
	if action.type == UnitAction.Type.MOVE_AND_INTERACT:
		var sub_label = LocalizationStrings.get_text(action.action_id) # Using action_id as interaction_id here for simple mapping
		var composite_id: String = "hud.action_move_and_interact"

		# If it's a social attack on a neutral, use "Convince"
		if action.interact_action_type == UnitAction.Type.CONVINCE:
			sub_label = LocalizationStrings.get_text("action_convince")
		elif action.interact_action_type == UnitAction.Type.TRAPPED:
			composite_id = "hud.action_move_and_investigate"
		elif action.interact_action_type == UnitAction.Type.GATHER:
			composite_id = "hud.action_move_and_gather"
		elif action.interact_action_type == UnitAction.Type.EXPLORE:
			composite_id = "hud.action_move_and_explore"
		elif action.interact_action_type == UnitAction.Type.VISIT:
			composite_id = "hud.action_move_and_visit"

		return LocalizationStrings.get_text(composite_id).format({
			"action": sub_label,
			"target": target_name,
			"move": action.movement_cost,
			"action_point": action.action_cost
		})

	# Special case: UNIT_OPPOSED for social attacks
	if aid == GameConstants.ActionIds.UNIT_OPPOSED and params.get("is_convince", false):
		aid = "action_convince"

	# Handle composite counts
	if params.has("near") or params.has("far"):
		var base_label = LocalizationStrings.get_text(aid)
		return format(
			base_label,
			params.get("near", 0),
			params.get("far", 0),
			params.get("imm_label", "near")
		)

	# Standard localized string with params
	return LocalizationStrings.get_text(aid).format(params)

static func get_hint(action: UnitAction) -> String:
	if not action.hint.is_empty():
		return action.hint

	var aid = action.action_id
	if aid == "":
		return ""

	var hint_keys := {
		GameConstants.ActionIds.LOCATION_OPPOSED: LocalizationStrings.HUD_HINT_EXPLORE_LOCATION,
		GameConstants.ActionIds.LOCATION_UNOPPOSED: LocalizationStrings.HUD_HINT_VISIT_LOCATION,
		GameConstants.ActionIds.UNIT_UNOPPOSED: LocalizationStrings.HUD_HINT_TALK,
		GameConstants.ActionIds.ITEM_OPPOSED: LocalizationStrings.HUD_HINT_TRAPPED,
		GameConstants.ActionIds.ITEM_UNOPPOSED: LocalizationStrings.HUD_HINT_LOOT,
		GameConstants.ActionIds.WAIT: LocalizationStrings.HUD_HINT_WAIT,
		GameConstants.ActionIds.MOVE: LocalizationStrings.HUD_HINT_MOVE,
		GameConstants.ActionIds.SKILL: LocalizationStrings.HUD_HINT_SKILL,
		GameConstants.Commands.UNDO: LocalizationStrings.HUD_HINT_UNDO,
		GameConstants.Interactions.AID: LocalizationStrings.HUD_HINT_AID
	}

	if hint_keys.has(aid):
		return LocalizationStrings.get_text(hint_keys[aid])

	match action.type:
		UnitAction.Type.ATTACK, UnitAction.Type.OPEN_ATTACK_MENU:
			if action.label_params.get("far", 0) > 0 or action.label_params.get("reachable", 0) > 0:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_FIGHT)
			return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_FIGHT)
		UnitAction.Type.CONVINCE:
			if action.label_params.get("far", 0) > 0 or action.label_params.get("reachable", 0) > 0:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_CONVINCE)
			return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_CONVINCE_NEUTRAL)
		UnitAction.Type.MOVE_AND_INTERACT:
			if action.interact_action_type == UnitAction.Type.CONVINCE:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_CONVINCE_NEUTRAL)
			if action.interact_action_type == UnitAction.Type.ATTACK:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_FIGHT)
	return ""

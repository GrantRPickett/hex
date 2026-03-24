const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

static func format(base: String, near_count: int, reachable_count: int, suffix: String = "", imm_label: String = "near") -> String:
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
		return base + suffix
		
	# If format is "{base} ({details})", we want "{base}{suffix} ({details})"
	# This is a bit hacky but keeps it localized if the template allows.
	# We'll just manually construct it to ensure suffix placement if base is separate.
	return "%s%s (%s)" % [base, suffix, LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_LIST_SEPARATOR).join(detail)]

static func get_label(action: PlayerAction, target_name: String = "", suffix: String = "") -> String:
	var aid = action.action_id
	if aid == "":
		var base = action.ui_label if not action.ui_label.is_empty() else LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_UNKNOWN)
		return base + suffix

	var params := action.ui_label_params.duplicate()

	# Special case: move_and_interact
	if action.type == GameConstants.ActionType.MOVE_AND_INTERACT:
		var sub_label = LocalizationStrings.get_text(action.action_id)
		var composite_id: String = "hud.action_move_and_interact"

		if action.command_id == GameConstants.Commands.CommandID.CONVINCE:
			sub_label = LocalizationStrings.get_text("action_convince")
		elif action.command_id == GameConstants.Commands.CommandID.TRAPPED:
			composite_id = "hud.action_move_and_investigate"
		elif action.command_id == GameConstants.Commands.CommandID.LOOT:
			composite_id = "hud.action_move_and_gather"
		elif action.command_id == GameConstants.Commands.CommandID.EXPLORE:
			composite_id = "hud.action_move_and_explore"
		elif action.command_id == GameConstants.Commands.CommandID.VISIT:
			composite_id = "hud.action_move_and_visit"

		# For composite IDs, we just append suffix to the whole thing for now as they are complex sentences
		return LocalizationStrings.get_text(composite_id).format({
			"action": sub_label,
			"target": target_name,
			"move": action.move_cost,
			"action_point": action.action_cost
		}) + suffix

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
			suffix,
			params.get("imm_label", "near")
		)

	# Standard localized string with params
	return LocalizationStrings.get_text(aid).format(params) + suffix

static func get_hint(action: PlayerAction) -> String:
	if not action.ui_hint.is_empty():
		return action.ui_hint

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
		GameConstants.ActionType.ATTACK, GameConstants.ActionType.OPEN_ATTACK_MENU:
			if action.ui_label_params.get("far", 0) > 0 or action.ui_label_params.get("reachable", 0) > 0:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_FIGHT)
			return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_FIGHT)
		GameConstants.ActionType.CONVINCE:
			if action.ui_label_params.get("far", 0) > 0 or action.ui_label_params.get("reachable", 0) > 0:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_CONVINCE)
			return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_CONVINCE_NEUTRAL)
		GameConstants.ActionType.MOVE_AND_INTERACT:
			if action.command_id == GameConstants.Commands.CommandID.CONVINCE:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_CONVINCE_NEUTRAL)
			if action.command_id == GameConstants.Commands.CommandID.ATTACK:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_FIGHT)
	return ""

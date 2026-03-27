const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

static func format(base: String, near_count: int, far_count: int, suffix: String = "", near_suffix: String = "", far_suffix: String = "") -> String:
	var detail: Array[String] = []
	if near_count > 0:
		var imm_key = LocalizationStrings.HUD_ACTION_LABEL_NEAR
		detail.append(LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_NEAR).format({
			"count": near_count,
			"label": LocalizationStrings.get_text(imm_key)
		}) + near_suffix)

	if far_count > 0:
		var far_key = LocalizationStrings.HUD_ACTION_LABEL_FAR
		detail.append(LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_REACHABLE).format({
			"count": far_count,
			"label": LocalizationStrings.get_text(far_key)
		}) + far_suffix)

	if detail.is_empty():
		return base + suffix

	# If format is "{base} ({details})", we want "{base}{suffix} ({details})"
	# This is a bit hacky but keeps it localized if the template allows.
	# We'll just manually construct it to ensure suffix placement if base is separate.
	var final = "%s%s (%s)" % [base, suffix, LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_LIST_SEPARATOR).join(detail)]
	GameLogger.debug(GameLogger.Category.UI, "[ActionLabel] Formatted label: %s (base: %s, suffix: %s, details: %d)" % [final, base, suffix, detail.size()])
	return final

static func get_label(action: PlayerAction, target_name: String = "", suffix: String = "") -> String:
	var aid = action.action_id
	if aid == "":
		var base = action.ui_label if not action.ui_label.is_empty() else LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_UNKNOWN)
		var final = base + suffix
		GameLogger.debug(GameLogger.Category.UI, "[ActionLabel] Empty action id label: %s" % final)
		return final

	var params := action.ui_label_params.duplicate()

	# Handle composite counts
	if params.has("near") or params.has("far"):
		var base_label = LocalizationStrings.get_text(aid)
		if action.needs_attribute or action.targets.size() > 1 or action.reachable_targets.size() > 0:
			base_label += "…"

		var near_suffix_val: String = params.get(&"near_suffix", "")
		var far_suffix_val: String = params.get(&"far_suffix", "")

		if is_instance_valid(action.actor):
			var combat_system := action.actor.get_combat_system()
			if combat_system:
				var is_convince: bool = action.type == GameConstants.ActionType.CONVINCE
				var near_targets: Array[Target] = action.targets
				var far_targets: Array[Target] = action.reachable_targets
				var suffixes = combat_system.get_action_suffixes(action.actor, near_targets, far_targets, is_convince, action.target_to_task)
				near_suffix_val = suffixes.near
				far_suffix_val = suffixes.far

		return format(
			base_label,
			int(params.get(&"near", 0)),
			int(params.get(&"far", 0)),
			suffix,
			near_suffix_val,
			far_suffix_val
		)

	# Standard localized string with params
	var final := LocalizationStrings.get_text(aid).format(params)

	# Add IDLE circle for Wait/Idle actions
	if aid == GameConstants.ActionIds.WAIT or action.type == GameConstants.ActionType.WAIT:
		final += GameConstants.UI.Indicators.IDLE

	final += suffix
	GameLogger.debug(GameLogger.Category.UI, "[ActionLabel] get_label for %s: %s (suffix: %s)" % [aid, final, suffix])
	return final

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
		GameConstants.ActionType.FIGHT, GameConstants.ActionType.OPEN_ATTACK_MENU:
			if action.ui_label_params.get("far", 0) > 0 or action.ui_label_params.get("reachable", 0) > 0:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_FIGHT)
			return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_FIGHT)
		GameConstants.ActionType.CONVINCE:
			if action.ui_label_params.get("far", 0) > 0 or action.ui_label_params.get("reachable", 0) > 0:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_CONVINCE)
			return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_CONVINCE_NEUTRAL)
		GameConstants.ActionType.MOVE_AND_INTERACT:
			var interaction_type = action.command_payload.get("type", "")
			if interaction_type == GameConstants.Interactions.CONVINCE:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_CONVINCE_NEUTRAL)
			if interaction_type == GameConstants.Interactions.FIGHT:
				return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_HINT_REACHABLE_FIGHT)
	return ""

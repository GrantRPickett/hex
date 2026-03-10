class_name ActionTargetHandler
extends RefCounted

static func populate_target_lists(action: UnitAction) -> Dictionary:
	var attack_targets: Array[Target] = []
	var reachable_attack_targets: Array[Target] = []
	
	var targets: Array = action.targets.duplicate()
	if targets.is_empty() and action.target:
		targets.append(action.target)
		
	for candidate in targets:
		if candidate and candidate is Target and not attack_targets.has(candidate):
			attack_targets.append(candidate)
			
	for candidate in action.reachable_targets:
		if candidate and candidate is Target and not reachable_attack_targets.has(candidate):
			reachable_attack_targets.append(candidate)
			
	return {
		"attack_targets": attack_targets,
		"reachable_attack_targets": reachable_attack_targets
	}

static func get_target_name(target: Target, loc: GDScript) -> String:
	if not target: return loc.get_text(loc.HUD_TARGET_NA)
	if target is Unit: return target.unit_name
	if target is Location: return TranslationServer.translate(StringName(target.loc_name))
	if target is Loot: return loc.get_text(loc.HUD_TARGET_TRAPPED_LOOT)
	return loc.get_text(loc.HUD_TARGET_GENERIC)

static func format_target_button_text(target: Target, reachable_targets: Array[Target], move_info: Dictionary, loc: GDScript) -> String:
	if target == null: return loc.get_text(loc.HUD_TARGET_UNKNOWN)
	var suffix := ""
	if reachable_targets.has(target) or move_info.has(target):
		suffix = loc.get_text(loc.HUD_TARGET_MOVE_SUFFIX)
	return "%s%s" % [get_target_name(target, loc), suffix]

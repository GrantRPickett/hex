const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

static func format(base: String, adjacent_count: int, reachable_count: int, imm_label: String = "adjacent") -> String:
	var detail: Array[String] = []
	if adjacent_count > 0:
		var imm_key = "hud.action_label_" + imm_label
		var localized_imm = LocalizationStrings.get_text(imm_key)
		detail.append(LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_ADJACENT).format({
			"count": adjacent_count,
			"label": localized_imm
		}))
	if reachable_count > 0:
		detail.append(LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_REACHABLE).format({
			"count": reachable_count
		}))
	if detail.is_empty():
		return base
	return LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_FORMAT_COMBINED).format({
		"base": base,
		"details": LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_LIST_SEPARATOR).join(detail)
	})

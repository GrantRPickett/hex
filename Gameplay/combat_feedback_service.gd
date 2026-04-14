class_name CombatFeedbackService
extends Node

## Service for formatting combat and aid feedback messages.
## Decoupled from HUDController.


static func prepare_bark_data(initiator: Node, target: Node, attr_idx: int, amount: int) -> Dictionary:
	var attr_name = TranslationServer.translate("attr." + GameConstants.get_attribute_name(attr_idx).to_lower())
	var name_initiator = initiator.unit_name if "unit_name" in initiator else TranslationServer.translate("hud.unit_unknown")
	var name_partner = target.unit_name if "unit_name" in target else TranslationServer.translate("hud.unit_unknown")
	
	return {
		"initiator_name": name_initiator,
		"partner_name": name_partner,
		"attribute_name": attr_name,
		"amount": amount
	}

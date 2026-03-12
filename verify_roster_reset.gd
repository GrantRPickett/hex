@tool
extends SceneTree

func _init():
	print("--- Roster Reset Verification ---")
	
	# Wait a frame for Autoloads if needed, but in tool mode we might need to manually trigger
	# However, RosterLoader uses ItemRegistry which is an Autoload.
	# If running as a script, Autoloads might not be available unless we are in-game.
	
	var loader = RosterLoader.new()
	var roster = loader._build_core_player_roster()
	
	if roster == null:
		print("FAILED: Roster is null")
		quit(1)
		return
		
	print("Units in roster: ", roster.units.size())
	print("Items in stash: ", roster.stash_items.size())
	
	var bronze_count = 0
	for item in roster.stash_items:
		if item.get_item_name().to_lower().contains("bronze"):
			bronze_count += 1
			print(" - Found bronze item: ", item.get_item_name(), " (Template: ", item.template.item_id if item.template else "NONE", ")")
	
	if bronze_count == 6:
		print("SUCCESS: Found 6 bronze items in stash.")
	else:
		print("FAILED: Found ", bronze_count, " bronze items, expected 6.")
	
	quit(0 if bronze_count == 6 else 1)

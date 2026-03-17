extends SceneTree

func _init():
	print("Checking LootDiscovery...")
	var ld = LootDiscovery
	if ld:
		print("LootDiscovery found.")
		if "get_reachable_loot" in ld:
			print("get_reachable_loot FOUND")
		else:
			print("get_reachable_loot NOT FOUND")
	
	print("Checking TaskDiscovery...")
	var td = TaskDiscovery
	if td:
		print("TaskDiscovery found.")
		if "get_categorized_location_tasks" in td:
			print("get_categorized_location_tasks FOUND")
		else:
			print("get_categorized_location_tasks NOT FOUND")
	
	quit()

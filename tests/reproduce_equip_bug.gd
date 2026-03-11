extends GdUnitTestSuite

const SaveManagerScript := preload("res://Autoloads/save_manager.gd")
const RosterPersistenceScript := preload("res://Gameplay/roster/roster_persistence.gd")

func test_roster_equipment_persistence() -> void:
	var mgr: SaveManagerScript = auto_free(SaveManagerScript.new())
	add_child(mgr)
	var ROSTER_SAVE_PATH := "user://test_player_roster.tres"
	mgr.set("ROSTER_SAVE_PATH", ROSTER_SAVE_PATH) # Override path for test

	# Clean up
	if FileAccess.file_exists(ROSTER_SAVE_PATH):
		DirAccess.remove_absolute(ROSTER_SAVE_PATH)

	# 1. Create a unit from a scene so it has a valid scene_path for persistence
	var unit_scene = load("res://Gameplay/scene_templates/generic_unit.tscn")
	var unit: Unit = auto_free(unit_scene.instantiate() as Unit)
	unit.unit_name = "Test Hero"
	# Initialize components (if not already handled by _ready)
	UnitComponentFactory.create_components(unit)
	
	# 2. Create an item and equip it
	var item := InventoryItem.new()
	item.item_name = "Magic Sword"
	item.attribute_modifiers = {"grit": 5}
	unit.inv.add_item_to_inventory(item)
	unit.inv.equip_item(item)
	
	assert_bool(item.equipped).is_true()
	
	# 3. Save to roster
	var roster := PlayerRoster.new()
	roster.roster_entries = [RosterPersistence.unit_to_entry(unit)]
	# Manually update units array like update_roster does
	var scene = RosterPersistence.entry_to_scene(roster.roster_entries[0])
	roster.units = [scene]
	
	mgr.save_roster(roster)
	
	# 4. Load roster back
	var loaded_roster: PlayerRoster = mgr.load_roster()
	assert_object(loaded_roster).is_not_null()
	assert_int(loaded_roster.roster_entries.size()).is_equal(1)
	
	# Check roster_entries data
	var entry_data = loaded_roster.roster_entries[0].get("data", {})
	var items_data = entry_data.get("items", [])
	assert_int(items_data.size()).is_equal(1)
	assert_bool(items_data[0].get("equipped", false)).is_true()
	
	# 5. Instantiate from PackedScene (this is what gameplay does)
	var loaded_scene = loaded_roster.units[0]
	var loaded_unit: Unit = auto_free(loaded_scene.instantiate() as Unit)
	# Wait for ready or call _ready manually if needed? 
	# Unit._ready() handles saved_items.
	
	# Since it's not in tree, we can't wait for ready. 
	# But we can check saved_items before ready.
	assert_int(loaded_unit.saved_items.size()).is_equal(1)
	assert_bool(loaded_unit.saved_items[0].equipped).is_true()
	
	# Now let's see if it's equipped after _ready
	add_child(loaded_unit)
	# _ready should run now
	
	assert_bool(loaded_unit.inv.get_equipped_items().is_empty()).is_false()
	var equipped_item = loaded_unit.inv.get_equipped_items()[0]
	assert_str(equipped_item.item_name).is_equal("Magic Sword")
	assert_bool(equipped_item.equipped).is_true()

	# Clean up
	if FileAccess.file_exists(ROSTER_SAVE_PATH):
		DirAccess.remove_absolute(ROSTER_SAVE_PATH)
	# unit and mgr are auto_freed

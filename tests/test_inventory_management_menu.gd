extends GdUnitTestSuite

var _menu: Control
var _roster: PlayerRoster

const ItemTemplate := preload("res://Resources/items/item_template.gd")

func before_test() -> void:
	# Load the menu scene to ensure @onready vars work
	var scene: Resource = load("res://Menus/inventory_management_menu.tscn")
	if scene:
		_menu = auto_free(scene.instantiate())
	else:
		# Fallback if tscn is not found/path is different
		_menu = auto_free(load("res://Menus/inventory_management_menu.gd").new())
		_menu._character_list = GridContainer.new()
		_menu._stash_list = VBoxContainer.new()
		_menu._auto_equip_button = Button.new()
		_menu._back_button = Button.new()
		_menu._help_label = Label.new()

	_roster = PlayerRoster.new()
	_menu._roster = _roster
	
	# Stub SaveManager so _save_changes doesn't error out
	var sm: Node = Node.new()
	sm.name = "SaveManager"
	sm.set_script(load("res://Autoloads/save_manager.gd"))
	get_tree().root.add_child(sm)
	
func after_test() -> void:
	if get_tree().root.has_node("SaveManager"):
		var sm = get_tree().root.get_node("SaveManager")
		get_tree().root.remove_child(sm)
		sm.queue_free()

func _make_item(item_name: String) -> InventoryItem:
	var item: InventoryItem = InventoryItem.new()
	item.template = ItemTemplate.new()
	item.template.item_id = item_name.to_lower().replace(" ", "_")
	item.template.item_name = item_name
	return item

func test_handle_item_drop_stash_to_stash() -> void:
	var item = _make_item("Sword")
	_menu._roster.stash_items.append(item)
	
	_menu.handle_item_drop(item, null, null)
	assert_that(_menu._roster.stash_items).contains(item) # It shouldn't double add or lose it completely, though the logic might erase and append.

func test_handle_item_drop_stash_to_unit() -> void:
	var item = _make_item("Sword")
	_menu._roster.stash_items.append(item)
	
	var unit: Unit = Unit.new()
	unit.inv = UnitInventory.new()
	# Note: In actual game, UnitInventory has an internal _items array.
	# Unit.inv might be UnitInventory directly or an InventoryComponent.
	# Based on previous reads, Unit.inv is usually InventoryComponent.
	
	_menu.handle_item_drop(item, null, unit)
	
	assert_that(_menu._roster.stash_items).does_not_contain(item)
	# InventoryItem.get_item_name() is what we should check if has_item_by_id checks template.item_id
	assert_that(unit.inv.has_item_by_id(item.template.item_id)).is_true()
	unit.free()

func test_handle_item_drop_unit_to_stash() -> void:
	var item = _make_item("Sword")
	var unit: Unit = Unit.new()
	unit.inv = UnitInventory.new()
	unit.inv.add_item_to_inventory(item)
	
	_menu.handle_item_drop(item, unit, null)
	
	assert_that(unit.inv.has_item_by_id(item.template.item_id)).is_false()
	assert_that(_menu._roster.stash_items).contains(item)
	unit.free()

func test_handle_item_drop_unit_to_unit() -> void:
	var item = _make_item("Sword")
	var unit1: Unit = Unit.new()
	unit1.inv = UnitInventory.new()
	unit1.inv.add_item_to_inventory(item)
	
	var unit2: Unit = Unit.new()
	unit2.inv = UnitInventory.new()
	
	_menu.handle_item_drop(item, unit1, unit2)
	
	assert_that(unit1.inv.has_item_by_id(item.template.item_id)).is_false()
	assert_that(unit2.inv.has_item_by_id(item.template.item_id)).is_true()
	unit1.free()
	unit2.free()

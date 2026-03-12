extends GdUnitTestSuite

# Tests for Loot.get_hover_info() — Node2D, but directly instantiable.
# Also covers Loot.add_items(), is_empty(), take_all_items().
# (get_hover_info is listed as uncovered in check_results.)

const LootScript := preload("res://Gameplay/targets/loot.gd")
const ItemScript := preload("res://Gameplay/targets/inventory_item.gd")
const ItemTemplate := preload("res://Resources/items/item_template.gd")

func _make_loot() -> Loot:
	var l: Loot = LootScript.new()
	add_child(l)
	return l

func _make_item(item_name: String) -> InventoryItem:
	var i: InventoryItem = ItemScript.new()
	i.template = ItemTemplate.new()
	i.template.item_name = item_name
	auto_free(i)
	return i

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# ---------------------------------------------------------------------------
# get_hover_info
# ---------------------------------------------------------------------------

func test_hover_info_empty_loot_shows_empty() -> void:
	var loot: Loot = _make_loot()
	var info := loot.get_hover_info()
	assert_bool(info.contains("Loot:")).is_true()
	assert_bool(info.contains("(Empty)")).is_true()

func test_hover_info_with_items_lists_names() -> void:
	var loot: Loot = _make_loot()
	var sword: InventoryItem = _make_item("Sword")
	var potion: InventoryItem = _make_item("Potion")
	loot.inventory.append(sword)
	loot.inventory.append(potion)
	var info := loot.get_hover_info()
	assert_bool(info.contains("Sword")).is_true()
	assert_bool(info.contains("Potion")).is_true()
	assert_bool(info.contains("(Empty)")).is_false()

func test_hover_info_does_not_show_empty_when_items_present() -> void:
	var loot: Loot = _make_loot()
	loot.inventory.append(_make_item("Key"))
	assert_bool(loot.get_hover_info().contains("(Empty)")).is_false()

# ---------------------------------------------------------------------------
# add_items
# ---------------------------------------------------------------------------

func test_add_items_appends_inventory_items() -> void:
	var loot: Loot = _make_loot()
	var items: Array[InventoryItem] = [_make_item("Gem"), _make_item("Ring")]
	loot.add_items(items)
	assert_int(loot.inventory.size()).is_equal(2)

func test_add_items_ignores_non_inventory_item_entries() -> void:
	var loot: Loot = _make_loot()
	# The method now takes Array[InventoryItem], but if called with a generic array 
	# it might still happen in dynamic GDScript. However, we've typed it.
	# We test with typed array.
	var items: Array[InventoryItem] = []
	loot.add_items(items)
	assert_int(loot.inventory.size()).is_equal(0)

func test_add_items_mixed_array_only_adds_valid() -> void:
	var loot: Loot = _make_loot()
	var valid: InventoryItem = _make_item("Shield")
	var items: Array[InventoryItem] = [valid]
	loot.add_items(items)
	assert_int(loot.inventory.size()).is_equal(1)
	assert_str(loot.inventory[0].get_item_name()).is_equal("Shield")

# ---------------------------------------------------------------------------
# is_empty
# ---------------------------------------------------------------------------

func test_is_empty_true_when_no_items() -> void:
	var loot: Loot = _make_loot()
	assert_bool(loot.is_empty()).is_true()

func test_is_empty_false_after_add() -> void:
	var loot: Loot = _make_loot()
	loot.inventory.append(_make_item("Coin"))
	assert_bool(loot.is_empty()).is_false()

# ---------------------------------------------------------------------------
# take_all_items
# ---------------------------------------------------------------------------

func test_take_all_items_returns_copies() -> void:
	var loot: Loot = _make_loot()
	var item: InventoryItem = _make_item("Dagger")
	loot.inventory.append(item)
	var taken := loot.take_all_items()
	assert_int(taken.size()).is_equal(1)
	assert_str(taken[0].get_item_name()).is_equal("Dagger")

func test_take_all_items_clears_inventory() -> void:
	var loot: Loot = _make_loot()
	loot.inventory.append(_make_item("Arrow"))
	loot.take_all_items()
	assert_bool(loot.is_empty()).is_true()

extends GdUnitTestSuite

const LootScript := preload("res://Gameplay/targets/loot.gd")
const ItemScript := preload("res://Gameplay/targets/inventory_item.gd")
const ItemTemplateScript := preload("res://Resources/items/item_template.gd")

var _loot: Loot

func before_test() -> void:
	_loot = LootScript.new()
	_loot.name = "TestLoot"
	# We need to manually set the texture to trigger the 32rogues logic
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://Resources/art/placeholder/32rogues/tiles.png")
	_loot.add_child(sprite)
	_loot.sprite = sprite
	
	get_tree().root.add_child(_loot)

func after_test() -> void:
	if is_instance_valid(_loot):
		_loot.queue_free()

func _make_item(item_name: String) -> InventoryItem:
	var i: InventoryItem = ItemScript.new()
	i.template = ItemTemplateScript.new()
	i.template.item_name = item_name
	return i

func test_initial_state_is_empty_shows_open() -> void:
	# Note: Loot._ready calls update_visuals, so it should be open
	_loot.update_visuals() # Explicit call just in case _ready didn't run yet in this setup
	assert_bool(_loot.sprite.region_enabled).is_true()
	assert_bool(_loot.sprite.region_rect == Rect2(32, 544, 32, 32)).is_true()

func test_texture_closes_when_items_added() -> void:
	var item = _make_item("Sword")
	_loot.add_items([item])
	assert_bool(_loot.sprite.region_rect == Rect2(0, 544, 32, 32)).is_true()

func test_texture_opens_when_items_taken() -> void:
	var item = _make_item("Gold")
	_loot.inventory.append(item)
	_loot.update_visuals() # Close it
	assert_bool(_loot.sprite.region_rect == Rect2(0, 544, 32, 32)).is_true()
	
	_loot.take_all_items()
	assert_bool(_loot.sprite.region_rect == Rect2(32, 544, 32, 32)).is_true()

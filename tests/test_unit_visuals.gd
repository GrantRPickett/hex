extends GdUnitTestSuite

func test_neutral_unit_sprite_bounds() -> void:
	var u = auto_free(Unit.new())
	u.faction = Unit.FACTION.NEUTRAL
	u.unit_name = "Guard"
	u.id = "Guard"
	
	# Manually trigger sprite setup since we aren't in a full scene tree
	u._ensure_sprite_setup()
	
	# Test multiple "random" outcomes by changing name/id
	for i in range(100):
		u.unit_name = "Guard_" + str(i)
		u.id = "ID_" + str(i)
		u.update_visuals()
		
		var rect = u.sprite.region_rect
		assert_float(rect.position.y).is_less_equal(192.0)
		assert_float(rect.position.x).is_less_equal(192.0) # 224 - 32
		assert_float(rect.size.x).is_equal(32.0)
		assert_float(rect.size.y).is_equal(32.0)
		
		# Check explicitly for the y=224 case which was failing
		assert_float(rect.position.y).is_not_equal(224.0)

func test_enemy_unit_sprite_bounds() -> void:
	var u = auto_free(Unit.new())
	u.faction = Unit.FACTION.ENEMY
	u.unit_name = "Monster"
	u.id = "Monster"
	u._ensure_sprite_setup()
	
	for i in range(20):
		u.unit_name = "Monster_" + str(i)
		u.update_visuals()
		var rect = u.sprite.region_rect
		# Row 6 is y=160.
		assert_float(rect.position.y).is_equal(160.0)
		assert_float(rect.position.x).is_less_equal(128.0) # 5 columns: 0, 32, 64, 96, 128

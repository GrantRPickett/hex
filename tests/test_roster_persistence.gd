extends GdUnitTestSuite

const GenericUnitScene := preload("res://Gameplay/scene_templates/generic_unit.tscn")
const RosterPersistence := preload("res://Gameplay/roster/roster_persistence.gd")

func test_unit_to_entry_captures_unit_metadata() -> void:
	var unit = auto_free(GenericUnitScene.instantiate() as Unit)
	unit.unit_name = "Alpha"
	unit.willpower = 3

	var entry = RosterPersistence.unit_to_entry(unit)

	assert_str(entry.get("unit_name", "")).is_equal("Alpha")
	assert_str(entry.get("scene_path", "")).contains("generic_unit.tscn")
	assert_int(entry.get("data", {}).get("willpower", -1)).is_equal(3)

func test_entry_to_scene_restores_memento() -> void:
	var unit = auto_free(GenericUnitScene.instantiate() as Unit)
	unit.unit_name = "Bravo"
	unit.willpower = 1

	var entry = RosterPersistence.unit_to_entry(unit)
	var scene = RosterPersistence.entry_to_scene(entry)

	assert_bool(scene != null).is_true()

	var restored_unit = auto_free(scene.instantiate() as Unit)
	assert_int(restored_unit.willpower).is_equal(1)
	assert_str(restored_unit.unit_name).is_equal("Bravo")

func test_scene_to_entry_preserves_fallback_scene() -> void:
	var temp_unit = GenericUnitScene.instantiate() as Unit
	temp_unit.unit_name = "Legacy"

	var packed = PackedScene.new()
	packed.pack(temp_unit)
	temp_unit.queue_free()

	var entry = RosterPersistence.scene_to_entry(packed)

	assert_str(entry.get("unit_name", "")).is_equal("Legacy")
	assert_bool(entry.get("fallback_scene", null) == packed).is_true()

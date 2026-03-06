extends SceneTree

func _init() -> void:
    print("--- Verifying Unified Loyalty Implementation ---")

    # 1. Verify Location
    var loc = Location.new()
    print("Location default loyalty: ", loc.loyalty)
    if loc.loyalty != GameConstants.Loyalty.NEUTRAL:
        print("FAILED: Location default loyalty should be NEUTRAL")
        quit(1)

    loc.loyalty = GameConstants.Loyalty.STATIC
    print("Location set to STATIC: ", loc.loyalty)
    if loc.loyalty != GameConstants.Loyalty.STATIC:
        print("FAILED: Could not set Location loyalty to STATIC")
        quit(1)

    # 2. Verify Unit
    var unit = Unit.new()
    print("Unit default loyalty_type: ", unit.loyalty_type)
    if unit.loyalty_type != GameConstants.Loyalty.NEUTRAL:
        print("FAILED: Unit default loyalty_type should be NEUTRAL")
        quit(1)

    unit.loyalty_type = GameConstants.Loyalty.STATIC
    print("Unit set to STATIC: ", unit.loyalty_type)
    if unit.loyalty_type != GameConstants.Loyalty.STATIC:
        print("FAILED: Could not set Unit loyalty_type to STATIC")
        quit(1)

    # 3. Verify Level Entries
    var task_entry = LevelTaskEntry.new()
    if task_entry.loyalty != GameConstants.Loyalty.NEUTRAL:
        print("FAILED: LevelTaskEntry default loyalty should be NEUTRAL")
        quit(1)

    var spawn_entry = LevelUnitSpawnEntry.new()
    if spawn_entry.loyalty_type != GameConstants.Loyalty.NEUTRAL:
        print("FAILED: LevelUnitSpawnEntry default loyalty_type should be NEUTRAL")
        quit(1)

    print("SUCCESS: Unified loyalty properties verified for Locations, Units, and Level Entries.")
    quit(0)

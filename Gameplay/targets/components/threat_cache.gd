class_name ThreatCache
extends Resource

## Caches threatened hex calculations for a unit.
## Invalidates when hostile units move.

const INVALID_VERSION := -1

var _cached_version: int = INVALID_VERSION
var _cached_result: Dictionary = {}
var _unit_manager: UnitManager
var _unit_manager_callable: Callable
var _source_unit: Unit

func setup(source_unit: Unit, unit_manager: UnitManager = null) -> void:
	_source_unit = source_unit
	set_unit_manager(unit_manager)
	invalidate()

func set_unit_manager(unit_manager: UnitManager) -> void:
	if _unit_manager and _unit_manager_callable and _unit_manager.unit_moved.is_connected(_unit_manager_callable):
		_unit_manager.unit_moved.disconnect(_unit_manager_callable)
	_unit_manager = unit_manager
	_unit_manager_callable = Callable()
	if _unit_manager:
		var handler := func(_index: int, _coord: Vector2i) -> void:
			invalidate()
		_unit_manager_callable = handler
		_unit_manager.unit_moved.connect(_unit_manager_callable)

func get_cached_result(current_version: int) -> Dictionary:
	if _cached_version == current_version and _cached_version != INVALID_VERSION:
		return _cached_result
	return {}

func update_cache(result: Dictionary, version: int) -> void:
	_cached_result = result
	_cached_version = version

func invalidate() -> void:
	_cached_version = INVALID_VERSION
	_cached_result.clear()

func cleanup() -> void:
	set_unit_manager(null)
	invalidate()

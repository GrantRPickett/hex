class_name HUDConfig
extends Object

class Config:
	var components: HUDComponentFactory.Components
	var turn_system: TurnSystem
	var unit_manager: UnitManager
	var task_manager: TaskManager
	var loot_manager: LootManager
	var combat_system: CombatSystem
	var pause_handler: PauseHandler
	var terrain_map: TerrainMap
	var map_controller: MapController
	var animation_service
	var locations_list_panel: LocationsListPanel
	var location_details_panel: LocationDetailsPanel
	var tasks_list_panel: TasksListPanel
	var task_details_panel: TaskDetailsPanel
	var location_service: LocationService
	var task_controller: TaskController

class Builder:
	var _config := Config.new()

	func with_components(value: HUDComponentFactory.Components) -> Builder:
		_config.components = value
		return self

	func with_turn_system(value: TurnSystem) -> Builder:
		_config.turn_system = value
		return self

	func with_unit_manager(value: UnitManager) -> Builder:
		_config.unit_manager = value
		return self

	func with_task_manager(value: TaskManager) -> Builder:
		_config.task_manager = value
		return self

	func with_loot_manager(value: LootManager) -> Builder:
		_config.loot_manager = value
		return self

	func with_combat_system(value: CombatSystem) -> Builder:
		_config.combat_system = value
		return self

	func with_pause_handler(value: PauseHandler) -> Builder:
		_config.pause_handler = value
		return self

	func with_terrain_map(value: TerrainMap) -> Builder:
		_config.terrain_map = value
		return self

	func with_map_controller(value: MapController) -> Builder:
		_config.map_controller = value
		return self

	func with_animation_service(value) -> Builder:
		_config.animation_service = value
		return self

	func with_locations_list_panel(value: LocationsListPanel) -> Builder:
		_config.locations_list_panel = value
		return self

	func with_location_details_panel(value: LocationDetailsPanel) -> Builder:
		_config.location_details_panel = value
		return self

	func with_tasks_list_panel(value: TasksListPanel) -> Builder:
		_config.tasks_list_panel = value
		return self

	func with_task_details_panel(value: TaskDetailsPanel) -> Builder:
		_config.task_details_panel = value
		return self

	func with_task_controller(value: TaskController) -> Builder:
		_config.task_controller = value
		return self

	func with_location_service(value: LocationService) -> Builder:
		_config.location_service = value
		return self

	func build() -> Config:
		return _config

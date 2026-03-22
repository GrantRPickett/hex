class_name LevelInitializationOrchestrator
extends RefCounted

## Orchestrates the startup sequence of a level to ensure deterministic timing.
static func run_initialization_pipeline(level: Level, level_manager: Object, task_controller: Object) -> void:
	if not level:
		GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] No level resource provided. Skipping initialization.")
		return

	if not level_manager or not task_controller:
		var missing: Array = []
		if not level_manager: missing.append("LevelManager")
		if not task_controller: missing.append("TaskController")
		GameLogger.error(GameLogger.Category.MAP, "[Orchestrator] Missing required components for initialization: %s" % [", ".join(missing)])
		return

	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] --- STARTING LEVEL INITIALIZATION PIPELINE ---")

	# Phase 1: Data Preparation
	# Load row resources, refresh rosters, prep dialogues. No world changes yet.
	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Phase 1: Preparing level data...")
	level_manager.prepare_level_data()

	# Phase 2: World Clearance
	# Reset Managers and wipe the units/loot from the previous session if any.
	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Phase 2: Clearing world state...")
	level_manager.clear_world()

	# Phase 3: Environment Construction
	# Builds the terrain map and grid visuals. No logic units spawned yet.
	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Phase 3: Building environment (Terrain & Grid)...")
	level_manager.build_environment()
	
	if not level.starting_pressures.is_empty() and WeatherManager:
		GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Applying starting weather: ", level.starting_pressures)
		WeatherManager.set_current_pressures(level.starting_pressures)

	# Phase 4: Narrative Bootstrapping
	# Prepares the TaskManager context (Objective duplication & signal wiring).
	# Crucially, this happens BEFORE spawning logic units so the spawner sees the context.
	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Phase 4: Bootstrapping narrative context...")
	task_controller.bootstrap_level(level)

	# Phase 5: Global Content Spawning
	# Spawns units and objects defined at the Level level.
	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Phase 5: Spawning global level content...")
	level_manager.spawn_global_content()

	# Phase 6: Stage Activation
	# Triggers the first stage transitions and spawns stage-specific content.
	# This avoids narrative-driven dialogue appearing too early or context being missing.
	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Phase 6: Activating initial narrative stage...")
	task_controller.activate_initial_stage()

	# Phase 7: Technical Finalization
	# Finalizes camera, HUD, and re-enables turns if appropriate.
	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] Phase 7: Finalizing technical setup...")
	level_manager.finalize_setup()

	GameLogger.debug(GameLogger.Category.MAP, "[Orchestrator] --- INITIALIZATION PIPELINE COMPLETE ---")

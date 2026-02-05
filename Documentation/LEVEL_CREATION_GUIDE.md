# Godot Level Creation Guide: Using Resource Tables

## I. Introduction

This document provides a step-by-step guide for developers to create new levels within the Godot Engine, specifically utilizing the resource table (`.tres` files) system and managing level data through the editor. It also includes suggestions for improving the current workflow.

**Assumptions:**
*   Familiarity with the Godot Engine editor.
*   Basic understanding of GDScript.
*   Knowledge of the project's folder structure.

## II. Core Concepts

Understanding the primary resource types and how they interact is crucial for effective level creation.

*   **`Level` Resource (`res://Resources/Level.gd`)**: This is the central definition for a level. It orchestrates various other resources that define the level's specific characteristics (terrain, goals, rosters, etc.).
*   **`GoalDefinition` Resource (`res://Resources/goal_definition.gd`)**: Defines the conditions for a level's goal to be considered complete. This includes details like title, steps (objectives), and rewards.
*   **Level Row Resources (e.g., `LevelMetaRow`, `LevelStartRow`, `LevelTerrainRow`, `LevelLootRow`, `LevelGoalRow`)**: These are specialized data containers, each focusing on a particular aspect of the level. They are used to organize and load level-specific data.
	*   `LevelGoalRow`: Links a specific goal scene (e.g., a `Goal` node from a `.tscn` file) to a coordinate on the level's grid.
*   **`LevelCatalog.gd` (`res://Resources/levels/level_catalog.gd`)**: This GDScript file acts as a registry for all levels in the game, providing their IDs, paths to their `Level` resources, display names, prerequisites, and other meta-information.

## III. Step-by-Step Guide: Creating a New Level

This section outlines the manual process for creating and integrating a new level into the game.

### Step 1: Create the Main `Level` Resource

1.  **Navigate:** In the Godot editor's FileSystem dock, go to `res://Resources/levels/`.
2.  **Create New Resource:** Right-click in the FileSystem dock -> `New` -> `Resource...`.
3.  **Select `Level`:** In the "Create New Resource" dialog, search for and select `Level` (script class: `res://Resources/Level.gd`). Click `Create`.
4.  **Name the File:** Save the new resource with a descriptive name, e.g., `new_level.tres`.
5.  **Configure `new_level.tres`:** Select the newly created `new_level.tres` in the FileSystem dock. In the Inspector dock, configure its properties:
	*   **`Display Name`**: The name shown to the player (e.g., "The Whispering Woods").
	*   **`Next Level Path`**: (Optional) The path to the `Level` resource that should load after this one is completed (e.g., `res://Resources/levels/level_next.tres`). If empty, the game typically returns to the level selection menu.
	*   **`Terrain Data`**: (Usually a `LevelTerrainRow` resource) See Step 2a.
	*   **`Player Starts`**: An array of `Vector2i` coordinates where player units will spawn.
	*   **`Enemy Roster Definition`**: (Usually an `EnemyRoster` resource) Defines the enemies present in the level.
	*   **`Goals`**: An array of `LevelGoalEntry` resources. See Step 2b.
	*   **`Loot List Definition`**: (Usually a `LootListDefinition` resource) Defines loot available in the level.
	*   **`Dialogue Entries`**: An array of `LevelDialogueEntry` resources for level-specific dialogue.

### Step 2: Define Level Data Rows (as needed)

Many properties of the main `Level` resource refer to other resource files. You'll need to create and configure these supporting resources.

#### Step 2a: Creating `LevelTerrainRow` (Example for `Terrain Data`)

1.  **Navigate:** Go to `res://Resources/level_data/terrain_rows/`.
2.  **Create New Resource:** Right-click -> `New` -> `Resource...`.
3.  **Select `LevelTerrainRow`:** Create a new `LevelTerrainRow` resource.
4.  **Name the File:** Save it, e.g., `new_level_terrain.tres`.
5.  **Configure `new_level_terrain.tres`:** In the Inspector, define the grid layout and assign tile types.
6.  **Link to `Level` Resource:** Go back to `new_level.tres` (from Step 1) and drag `new_level_terrain.tres` from the FileSystem dock into the `Terrain Data` slot in the Inspector.

#### Step 2b: Creating `LevelGoalRow` and `GoalDefinition` (Example for `Goals`)

This involves two parts: defining *what* the goal is (`GoalDefinition`) and *where* it is placed in the level (`LevelGoalRow`).

1.  **Create `GoalDefinition`:**
	*   **Navigate:** Go to `res://Resources/goal_definitions/`.
	*   **Create New Resource:** Right-click -> `New` -> `Resource...` -> Select `GoalDefinition` (script class: `res://Resources/goal_definition.gd`).
	*   **Name the File:** Save it, e.g., `new_level_goal_def.tres`.
	*   **Configure `new_level_goal_def.tres`:**
		*   **`Title`**: A short title for the goal (e.g., "Find the Artifact").
		*   **`Is Optional`**: `true` if completing this goal is not mandatory.
		*   **`Goal Type`**: `COMMON` or `RARE`.
		*   **`Steps`**: This is crucial. Add elements to this array, each being a `GoalStep` resource.
			*   For each step, right-click on the array element -> `New` -> `Resource...` -> `GoalStep` (script class: `res://Resources/goal_step.gd`).
			*   Configure `step_name`, `description`, `required_attribute`, and `required_amount`. For simple "reach location" goals, you might use placeholder values for `required_attribute` and `required_amount` if they aren't explicitly checked by the `Goal` node's script. Ensure at least one step exists for the goal to be completable.
		*   **`Rewards`**: (Optional) Array of `GoalReward` resources.

2.  **Create `LevelGoalRow`:**
	*   **Navigate:** Go to `res://Resources/level_data/goal_rows/`.
	*   **Create New Resource:** Right-click -> `New` -> `Resource...` -> Select `LevelGoalRow` (script class: `res://Resources/level_data/level_goal_row.gd`).
	*   **Name the File:** Save it, e.g., `new_level_goal_placement.tres`.
	*   **Configure `new_level_goal_placement.tres`:**
		*   **`Level ID`**: Set this to the `id` you will use in `LevelCatalog.gd` (e.g., `"new_level"`).
		*   **`Coord`**: The `Vector2i` grid coordinate where this goal will appear in the level.
		*   **`Goal Scene`**: Drag the actual `Goal` scene (e.g., `res://Gameplay/goal.tscn` or a custom goal scene you've made) from the FileSystem dock into this slot. This scene's root node should extend `Goal` and have its `definition` property assigned to your `new_level_goal_def.tres`.
3.  **Link `LevelGoalRow` to Main `Level`:** Go back to `new_level.tres` (from Step 1) and add `new_level_goal_placement.tres` to the `Goals` array in the Inspector.

### Step 3: Register the Level in `LevelCatalog.gd`

This step makes your new level discoverable by the game's level manager.

1.  **Open `LevelCatalog.gd`:** In the Godot editor, double-click `res://Resources/levels/level_catalog.gd` to open it in the script editor.
2.  **Add New Entry:** Locate the `LEVELS` array constant. Add a new dictionary entry for your level:
	```gdscript
	const LEVELS: Array[Dictionary] = [
		# ... existing levels ...
		{
			"id": "new_level_id", # A unique string ID for your level
			"path": "res://Resources/levels/new_level.tres", # Path to your main Level resource
			"display_name": "The Whispering Woods", # Must match the display_name in your Level resource
			"prerequisites": ["previous_level_id"], # Array of IDs of levels that must be completed first
			"is_hometown": false, # Set to true if this is a hometown-like level
			"repeatable": true # Set to true if the level can be replayed
		},
	]
	```
3.  **Save `LevelCatalog.gd`:** Save the script file.

Your new level should now be integrated into the game!

## IV. Improving the Workflow (Suggestions)

The current resource-based level creation system is flexible but can be tedious and prone to manual errors. Here are suggestions for improvement:

### 1. Custom Editor Plugin/Tool: "Level Creation Wizard"

*   **Problem:** The process involves creating and linking many separate `.tres` files, which is repetitive and requires careful navigation. Missing links or incorrect paths are common.
*   **Proposed Solution:** Develop a custom Godot editor plugin that provides a "New Level Wizard" or a dedicated level editor interface.
	*   **Functionality:**
		*   **Guided Creation:** A wizard could prompt the user for essential level information (name, ID, size, basic terrain type).
		*   **Automated Resource Generation:** Automatically generate the main `Level.tres` and all associated `LevelMetaRow`, `LevelTerrainRow`, `LevelStartRow`, `LevelLootRow`, and `LevelGoalRow` resources. These could be pre-populated with sensible defaults.
		*   **Automated Linking:** The wizard would handle all the necessary internal references, linking the generated row resources back to the main `Level.tres` automatically.
		*   **`LevelCatalog` Integration:** Offer an option to automatically add the new level's entry to `LevelCatalog.gd`.
		*   **In-Editor Preview/Configuration:** For terrain, perhaps a basic grid-based editor could be integrated into the wizard to allow rapid prototyping of the level layout before final resource generation.

### 2. Enhanced `GoalDefinition` Management & Validation

*   **Problem:** `GoalDefinition`s can be created without any `steps`, leading to goals that are visually present but functionally impossible to complete (as observed with the "Leave Town" goal).
*   **Proposed Solutions:**
	*   **Custom Inspector Warnings:** Implement a custom inspector for `GoalDefinition` (`goal_definition.gd` should extend `EditorInspectorPlugin` or similar) that displays a prominent warning in the editor if the `steps` array is empty.
	*   **Default `GoalStep` Template:** When a new `GoalDefinition` is created, automatically populate its `steps` array with a default `GoalStep` (e.g., "Complete Objective") to guide the developer.
	*   **Runtime Validation:** Add checks in `goal.gd` or `goal_controller.gd` that log a warning or error if a `GoalDefinition` with no steps is encountered during gameplay.

### 3. More Flexible Level Registration (Beyond `LevelCatalog.gd`)

*   **Problem:** `LevelCatalog.gd` is a script file. Modifying it for every new level requires editing GDScript, which can be less artist-friendly and prone to merge conflicts in team environments.
*   **Proposed Solution:** Transition to a data-driven approach for level registration.
	*   **`LevelList.tres`:** Create a single `LevelList.tres` resource (e.g., an `Array[Level]` resource or a custom resource type) that holds references to all `Level.tres` files.
	*   **Dynamic Loading:** Modify `LevelManager` or `LevelCatalog` to load this `LevelList.tres` at runtime.
	*   **Benefits:** Allows level ordering, addition, and removal directly through the editor without touching code. Reduces merge conflicts and simplifies asset management.

By implementing these improvements, the level creation process can become significantly more intuitive, less error-prone, and more efficient for developers and designers.

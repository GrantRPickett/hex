# Level Creation Guide

This guide outlines the process of creating new levels for the game, utilizing Godot's resource system. Levels are defined as `Level` resources, which aggregate various other data resources to form a complete level definition.

## Two Approaches to Level Creation

There are two primary ways to define level data:

1.  **Manual Resource Creation:** Directly creating and configuring individual Godot resources for each part of the level (e.g., `LevelTerrainData`, `LevelGoalEntry`, `LevelDialogueEntry`). This method offers fine-grained control and is useful for unique, one-off level elements.
2.  **ResourceTables Workflow (Recommended):** Utilizing the custom "ResourceTables" editor tab (likely powered by the `resources_spreadsheet_view` addon) to define level data in a spreadsheet-like format. This workflow is generally more efficient for managing multiple levels and their various components by abstracting away the manual creation of individual sub-resources. This guide will focus on this workflow.

## 1. Using the ResourceTables Workflow (Recommended)

For creative and narrative best practices when designing your levels, see the [Level Design Guidelines](LEVEL_DESIGN_GUIDELINES.md).
For automated terrain generation tools, see the [Map Generator Features](MAP_GENERATOR_FEATURES.md).

This workflow streamlines level creation by allowing you to define level components in a tabular format, which are then processed to generate the final `Level` resource.

### Step 1: Open the ResourceTables Editor

1.  In the Godot editor, locate and open the **ResourceTables** tab. This is typically a custom editor dock or panel provided by a project-specific addon.
2.  Within the ResourceTables tab, select the **Level** section. This is where you will define the core properties of your new level.

### Step 2: Create a New Level Definition

1.  **Add a New Level ID:** Locate the section for `Level` definitions. You should see a list of existing level IDs. Add a new row and enter a unique `level_id` (e.g., `level_tutorial_01`, `level_forest_01`).
2.  **Configure Level Metadata (LevelMetaRow):**
	*   For your new `level_id`, fill in the columns corresponding to `LevelMetaRow` properties:
		*   `display_name`: The name shown to players (e.g., "The Old Farm").
		*   `initial_rotation`: (Float) The initial camera rotation for the level.
		*   `hex_offset_axis`: (Integer) The tile offset axis for the hexagonal grid (e.g., `0` for vertical, `1` for horizontal). Refer to Godot's `TileSet.TILE_OFFSET_AXIS_*` constants.
		*   `notes`: (String) Any internal notes for developers.

### Step 3: Define Terrain Data (LevelTerrainRow)

1.  In the ResourceTables tab, navigate to the **Level Terrain** section.
2.  Add a new row and link it to your `level_id`.
3.  Fill in the columns corresponding to `LevelTerrainRow` properties:
	*   `grid_width`: (Integer) The width of the hexagonal grid.
	*   `grid_height`: (Integer) The height of the hexagonal grid.
	*   `terrain_rows`: (Array of Strings) Define the terrain layout using a grid of characters. Each string represents a row, and each character within the string represents a tile type (e.g., `G` for Grass, `W` for Water, `M` for Mountain). Ensure the length of each string matches `grid_width`, and the number of strings matches `grid_height`.

### Step 4: Define Unit Spawns (LevelRosterRow and LevelUnitSpawnEntry)

1.  In the ResourceTables tab, navigate to the **Level Rosters** section.
2.  Add new rows linked to your `level_id` for Player, Enemy, and Neutral units.
3.  For each `LevelRosterRow`:
	*   `unit_type`: (Enum) Specify `PLAYER`, `ENEMY`, or `NEUTRAL`.
	*   `unit_entries`: (Array of `LevelUnitSpawnEntry` properties) For each unit you want to spawn:
		*   `unit_scene`: (PackedScene) The path to the unit's scene (e.g., `res://Gameplay/units/player_hero.tscn`).
		*   `coord`: (Vector2i) The grid coordinates `(x, y)` where the unit will spawn.

### Step 5: Define Goals (LevelGoalRow)

1.  In the ResourceTables tab, navigate to the **Level Goals** section.
2.  Add new rows linked to your `level_id`.
3.  For each `LevelGoalRow`:
	*   `coord`: (Vector2i) The grid coordinates `(x, y)` of the goal.
	*   `goal_scene`: (PackedScene) The path to the goal's scene (e.g., `res://Gameplay/goal.tscn`).

### Step 6: Define Loot (LevelLootRow)

1.  In the ResourceTables tab, navigate to the **Level Loot** section.
2.  Add new rows linked to your `level_id`.
3.  For each `LevelLootRow`:
	*   `coord`: (Vector2i) The grid coordinates `(x, y)` where the loot will spawn.
	*   `item_resource_paths`: (Array of Strings) A list of resource paths to the item resources (e.g., `res://Resources/items/health_potion.tres`).
	*   `count`: (Integer) The number of items to spawn at this location.

### Step 7: Define Dialogue Triggers (LevelDialogueRow)

1.  In the ResourceTables tab, navigate to the **Level Dialogue** section.
2.  Add new rows linked to your `level_id`.
3.  For each `LevelDialogueRow`:
	*   `initiator_name`: (StringName) The `unit_name` of the unit that can initiate the dialogue.
	*   `partner_name`: (StringName) The `unit_name` of the unit that is the dialogue partner.
	*   `partner_faction`: (Enum) The faction of the partner unit.
	*   `coord`: (Vector2i) The grid coordinates `(x, y)` where the dialogue trigger is active.
	*   `dialogue_resource_path`: (String) The resource path to a DialogueManager resource (e.g., `res://Dialogues/intro_dialogue.dialogue`).
	*   `action_label`: (String) The text displayed for the dialogue action (e.g., "Talk to NPC").
	*   `action_hint`: (String) A short hint for the action.
	*   `repeatable`: (Boolean) If true, the dialogue can be triggered multiple times.
	*   `requires_near`: (Boolean) If true, initiator and partner must be near.
	*   `consume_action`: (Boolean) If true, initiating dialogue consumes a unit's action.
	*   `group_id`: (StringName) An optional ID to group multiple dialogue triggers.

### Step 8: Generate/Export the Level Resource

1.  After defining all the rows for your new level in the ResourceTables, there should be an option (e.g., a button or a menu item) to **Generate Level Resources** or **Export Levels**.
2.  This process will take all the defined rows for your `level_id` and combine them into a single `Level.tres` resource file. The generated file will typically be saved in `res://Resources/level_data/`.

### Step 9: Register the New Level in LevelCatalog

1.  Open `res://level/level_catalog.gd`.
2.  Locate the `LEVELS` array constant.
3.  Add a new dictionary entry for your new level, following the existing format:

	```gdscript
	{"id": "your_level_id", "path": "res://Resources/level_data/your_level_name.tres", "display_name": "Your Level Name", "prerequisites": ["previous_level_id"]},
	```
	*   `id`: Should match the `level_id` you used in the ResourceTables.
	*   `path`: The resource path to the `.tres` file generated in Step 8.
	*   `display_name`: The name shown in level selection menus.
	*   `prerequisites`: (Array of Strings) A list of `level_id`s that must be completed before this level unlocks. Leave empty for initial levels.

## 2. Manual Resource Creation (Alternative for Specific Cases)

While the ResourceTables workflow is recommended, you can also create levels manually:

### Step 1: Create a New Level Resource

1.  In the Godot FileSystem dock, right-click in `res://Resources/level_data/` -> `Create New` -> `Resource...`
2.  Search for and select `Level`.
3.  Save the new resource (e.g., `new_manual_level.tres`).

### Step 2: Configure Level Properties

1.  Select the newly created `new_manual_level.tres` in the FileSystem dock.
2.  In the Inspector dock, you will see all the `@export` properties of the `Level` class.
3.  Fill in `display_name`, `initial_rotation`, etc., directly.

### Step 3: Create and Assign Sub-Resources

For complex properties like `terrain_data`, `enemy_roster_definition`, `goals`, `loot_list_definition`, and `dialogue_entries`, you will need to:

1.  For each, click on the property field in the Inspector.
2.  Select `New [ResourceTypeName]` (e.g., `New LevelTerrainData`, `New UnitRosterDefinition`).
3.  Godot will prompt you to save this new sub-resource. Save it in an appropriate location (e.g., `res://Resources/level_data/`, `res://Resources/rosters/`).
4.  Once created, select the new sub-resource in the FileSystem dock and configure its properties in the Inspector.
5.  If a property is an array (e.g., `player_starts`, `goals`, `dialogue_entries`), you will add elements to the array in the Inspector. For each element, you might need to create *another* sub-resource (e.g., `New LevelGoalEntry` for the `goals` array) and configure it.

### Step 4: Register the New Level in LevelCatalog

1.  Follow **Step 9** from the ResourceTables workflow above to add your manually created `Level.tres` to `res://level/level_catalog.gd`.

## Suggestions for Process Improvement

*   **Standardize Workflow:** Clearly define whether the ResourceTables workflow or manual resource creation is the primary method for new levels. Maintaining both can lead to confusion and inconsistencies. Given the existence of the `...Row` resources, the ResourceTables approach seems intended to be the main workflow.
*   **ResourceTables Tooling:**
	*   **Direct `.tres` Generation:** Ensure the ResourceTables tool has a clear and reliable "Generate Level" or "Export Level" function that creates/updates the final `Level.tres` files.
	*   **Validation:** Implement stronger validation within the ResourceTables editor. For example, warn if `grid_width` and `grid_height` don't match the dimensions of `terrain_rows`, or if `unit_scene` paths are invalid.
	*   **Pre-fill Defaults:** When adding new rows, pre-fill common default values (e.g., `hex_offset_axis = 0`, default `goal_scene` if applicable) to reduce manual input.
	*   **Error Reporting:** Provide clear and actionable error messages within the ResourceTables UI if data is incorrect or cannot be processed.
*   **Documentation for `...Row` Resources:** Create separate, concise documentation for each `LevelMetaRow`, `LevelTerrainRow`, `LevelUnitSpawnEntry`, `LevelGoalEntry`, `LevelLootEntry`, and `LevelDialogueEntry`, explaining each field and its purpose. This guide briefly touches on them, but dedicated docs would be beneficial.
*   **Visual Editor Integration:** For terrain, consider a visual editor within the ResourceTables tab where users can "paint" terrain types onto a grid instead of manually typing character strings.
*   **Unit/Loot Roster Previews:** In the ResourceTables, consider adding a way to preview unit scenes or item icons directly within the table rows, instead of just displaying a resource path.
*   **Level Preview:** Can the generated `Level.tres` be quickly opened in a scene or a dedicated preview mode to visually inspect the layout, unit placements, goals, and dialogue triggers?

By following these guidelines and considering the suggested improvements, developers can create new levels efficiently and consistently.

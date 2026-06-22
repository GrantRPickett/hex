# Dialogue Creation in HEX

HEX uses the [Dialogue Manager](https://github.com/nathanhoad/godot-dialogue-manager) addon for its narrative system. This document explains how to create dialogue and integrate it into the level system.

## 1. Creating Dialogue Files

1.  Open the **Dialogue** tab in the Godot editor.
2.  Create a new `.dialogue` file in `res://Resources/level_data/dialogues/`.
3.  Write your dialogue using the standard Dialogue Manager syntax.

### Example: `intro.dialogue`
```text
~ start
Narrator: Welcome to the Whispering Woods.
Nathan: I've got a bad feeling about this.
=> END
```

## 2. Integrating with Levels

Dialogue is integrated into levels via **LevelDialogueRow** resources. You can configure these in the ResourceTables or as manual resources.

### Dialogue Trigger Properties

| Property | Description |
| :--- | :--- |
| `initiator_name` | The name of the unit that can trigger the dialogue. |
| `partner_name` | (Optional) The name of the NPC/partner unit for the conversation. |
| `coord` | The grid coordinate where the dialogue can be triggered. |
| `dialogue_resource_path` | Path to your `.dialogue` file. |
| `start_title` | The title marker to start from (e.g., `~ start`). |
| `repeatable` | If false, the dialogue can only be triggered once per level run. |
| `requires_near` | If true, units must be next to each other to talk. |
| `consume_action` | If true, triggering dialogue uses the unit's action point. |

## 3. Global Mutations & Conditions

You can use global states in your dialogue to create branching narratives.

- **Conditions**: `[if GameState.turn_count > 5]`
- **Mutations**: `do AchievementManager.unlock("Talkative")`

## 4. Best Practices

- **Naming**: Name your dialogue files after the level they belong to (e.g., `level_forest_01_intro.dialogue`).
- **Organization**: Keep all narrative-specific dialogue in `res://Resources/level_data/dialogues/`.
- **Testing**: Use the "Test Dialogue" feature in the Dialogue Manager tab to verify your syntax before running the level.

For more details on dialogue syntax, see the [Basic Dialogue Guide](../docs/Basic_Dialogue.md).

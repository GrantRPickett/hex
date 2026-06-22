# Tutorial Batch Generation Guide

This document defines the structure and requirements for the 6-level tutorial flashback sequence. These levels are designed to introduce the core mechanics of HEX through a narrative lens.

## Core Requirements

Each level in the tutorial batch MUST include:

1. **Player Character**: A unique core character (Healer, Scout, Monk, Assassin, Berserker, Duelist).
2. **Required Task**: Exactly one task (measure of completion is handled by target willpower).
3. **Advanced Terrain**: Introduction of a terrain tile with movement costs or status effects (Monastery, Vines, Mud, Ruins, Fort, Ice).
4. **Weather Condition**: A weather state aligned with the player character's strongest attribute for that level.
5. **Treasure**: A reward (item or loot) keyed to the same attribute used for the task.
6. **Backstory Dialogue**: Journal and dialogue entries explaining the character's arrival at the starting area.

## Level Breakdown

### Batch 1: Unopposed Lessons

Introduce basic interaction types without threat.

| Level | Character | Stat | Tutorial Terrain | Interaction | Narrative Goal |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Healer | Shine | **Monastery** (Sanctuary) | Convince | Passing the gate guards via persuasion. |
| **2** | Scout | Flow | **Vines** (Entangled) | Visit | Speeding through the plains to reach an oasis. |
| **3** | Monk | Gusto | **Mud** (Sticky) | Gather | Scavenging for supplies in a harsh expanse. |

### Batch 2: Opposed Lessons

Introduce hazards and combat where the target fights back.

| Level | Character | Stat | Tutorial Terrain | Interaction | Narrative Goal |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **4** | Assassin | Shade | **Ruins** (Broken) | Explore | Navigating haunted ruins while staying hidden. |
| **5** | Berserker | Grit | **Fort** (Cover) | Fight | Pushing through a bandit outpost by force. |
| **6** | Duelist | Focus | **Ice** (Slippery) | Disarm | Picking a complex lock on the final vault. |

## JSON Template Structure

The generation script uses a schema-compliant JSON template. Key fields for the tutorial:

- `level_id`: `tutorial_XX`
- `starting_weather`: Aligned with the level's attribute.
- `objective`: Single stage with one task.
- `dialogue_journal_entries`: Backstory snippets.
- `terrain`: Mostly grass, featuring focus terrain as "obstructed patches" (e.g., a wall or dense cluster).

## Generation Script Logic

The `generate_tutorial_levels.py` script:

1. Iterates through the 6 level definitions.
2. Injects the specific core character into `roster_spawns`.
3. Injects the specific focus terrain feature (obstructing part of the path).
4. Targets: `loot_spawns`, `neutral_spawns`, or `enemy_spawns` required for the task.
5. Generates coordinates for player and target.
6. Outputs 6 JSON files to `Resources/level_data/tutorial/`.

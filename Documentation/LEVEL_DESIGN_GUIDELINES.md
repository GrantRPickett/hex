# Level Design Guidelines

This document provides creative and narrative guidelines for designing levels in HEX. Use these patterns to ensure a consistent player experience and narrative depth across the campaign.

## Related Documentation

- **[Level Creation Guide](../LEVEL_CREATION_GUIDE.md)**: Technical instructions for building levels in Godot.
- **[Map Generator Features](../MAP_GENERATOR_FEATURES.md)**: Details on the procedural terrain tool.

## Recommended Narrative Flow

A standard HEX level should follow a multi-stage progression that balances world-building, gameplay mechanics, and narrative tension.

### 1. Intro On-Ramp
*   **Trigger**: On enter Stage 1.
*   **Content**: Establish the "Who, What, Why" of the level.
*   **Goal**: Briefly explain why the party has arrived at this specific location and what their immediate objective is. Use dialogue to set the tone (tense, curious, hurried, etc.).

### 2. Stage 1: Development & Acquaintance
*   **Gameplay**: Focus on nearby **unopposed checks**.
*   **Content**: Allow the party to interact with the environment or neutral units as they get acquainted with the local setting.
*   **Twist**: Clarify that what they find is unexpected. This sets the stage for the upcoming conflict or problem.

### 3. Stage 2: The Twist & Threat
*   **Gameplay**: Transition to **opposed checks**.
*   **Content**: Introduce the core problem, threat, or antagonist of the level.
*   **Goal**: Force the player to resolve the unexpected discovery using their skills and combat prowess. This is where the primary mechanical challenge of the level usually resides.

### 4. Stage 3+: Reinforcement & Branching
*   **Gameplay**: Optional complexity.
*   **Content**: Provide reinforcement for previous choices, or branch the narrative to develop new progress.
*   **Goal**: Reveal deeper lore or consequences as needed. This stage can be used to reward exploration or handle multiple objective paths.

### 5. Narrative Off-Ramp
*   **Trigger**: On exit of the final Stage.
*   **Content**: Summarize the choices made during the level (if any) and their immediate impact.
*   **Goal**: Provide a sense of closure for the level while bridging the story to the next location in the campaign.

## Design Philosophy

*   **Pacing**: Start slow with narrative and easy interactions before ramping up to high-stakes opposed checks.
*   **Choice Matters**: Use the Narrative Off-Ramp to acknowledge player decisions, making each level feel like a part of a larger, reactive world.
*   **Environmental Storytelling**: Use terrain and stage transitions to reflect the shifting narrative state (e.g., Stage 1 is a "Calm" forest, Stage 2 introduces "Storm Winds" as the threat appears).

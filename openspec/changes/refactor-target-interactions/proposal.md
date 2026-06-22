# Refactor Target Interactions

## What Changes

Consolidate target interaction code paths and implement specific player-facing buttons and AI logic based on the target type, task status, and faction standings. This change introduces context-sensitive interactions across Items, Locations, and Units, and implements symmetrical interaction capabilities for AI-controlled factions.

## Why

Currently, interactions like "loot" and "work_on_task" are somewhat fragmented. We need a unified system that presents contextual actions (e.g., "loot" vs "trapped", "visit" vs "explore", "fight" vs "convince") depending on whether the interaction is unopposed (no task/traps, no loyalty opposition) or opposed (task, enemy faction, or loyal neutral). Additionally, neutral units require a more complex loyalty and willpower system, and AI needs to be able to symmetrically utilize these interactions (e.g., enemies convincing neutrals).

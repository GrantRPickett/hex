# Proposal: Refactor Level Loading Pipeline

## Why

The current level loading pipeline involves redundant steps and duplicated resource types: `json_to_tres.py` creates `*Row.gd` resources, which `LevelRowLoader` then maps at runtime into `*Entry.gd` resources before `TargetSpawner` finally creates nodes.

This pipeline:

- Duplicates properties (e.g. `LevelLootRow` vs `LevelLootEntry`), leading to syncing errors.
- Forces fragile property mapping logic in `LevelRowLoader`, like the recently patched `_copy_stats`.
- Makes the resource conversion flow harder to reason about and extends load times unnecessarily by creating intermediate objects at runtime.

The user explicitly requested: "using openspec review how the resources are eventually converted into nodes and suggest a way to avoid a bunch of unneeded steps" and "use composition not extends from extends from extends from".

## What Changes

**Eliminate the intermediate "Row" resources (`Level*Row.gd`).**

The conversion from JSON will directly yield the runtime "Entry" resources (`LevelUnitSpawnEntry`, `LevelLootEntry`, `LevelTaskEntry`, `LevelDialogueEntry`, etc.) that `TargetSpawner` and `LevelBuilder` expect.

`LevelRowLoader` will be drastically simplified to just load `.tres` entries into `Array`s on the `Level` object, avoiding the need to remap fields completely.

## Scope

1. **Remove Row resources**: Deprecate `LevelRosterRow`, `LevelLootRow`, `LevelTaskRow`, `LevelStartRow`, `LevelDialogueRow`, `LevelTerrainRow`, `LevelMetaRow`.
2. **Update Tooling**: Update `json_to_tres.py` to directly generate `LevelUnitSpawnEntry`, `LevelLootEntry`, etc. instead of the Row resources.
3. **Refactor Loader**: Refactor `LevelRowLoader` to load these final types and ditch all `_build_*` methods.
4. **Refactor Entries**: Ensure all Entry types use composition (`CombatStats`) rather than deep inheritance chains.

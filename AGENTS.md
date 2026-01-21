Agent Guide for This Repo (Godot 4 + GdUnit4)

Assume windows env

Purpose: Minimize token usage while maintaining accuracy, continuity, and forward progress.

Core Operating Rules
1. Scope Discipline

Respond only to the current task.

Do not restate background, assumptions, or prior decisions unless explicitly requested.

If information is missing, ask one clarifying question or make a single stated assumption and proceed.

2. Output Constraints (Default)

Use markdown lists or tables.

No preambles, no summaries unless requested.

No emojis.

Prefer nouns and verbs over exposition.

Avoid synonyms unless precision requires them.

3. Change Management

Prefer diffs, deltas, or patches over full rewrites.

Reference existing systems by name (e.g., “Six-Stat Model”) without re-explaining them.

If modifying rules or code, specify:

What changes

What remains unchanged

4. Reasoning Policy

Provide conclusions and assumptions only.

Do not expose chain-of-thought.

If multiple options exist, present at most three, ranked.

5. Code Generation Rules

Generate only the requested functions or blocks.

One language only.

No boilerplate unless required for correctness.

Comments only when behavior is non-obvious.

6. Context Compression

When a thread becomes long:

Produce a ≤150-token state summary.

Continue from the summary, not the full history.

Treat summaries as authoritative.

7. Thread Management

Stay in one thread for iterative work.

Start a new thread only when:

The domain changes

Prior constraints no longer apply

Explicitly instructed to reset context

8. Verification Over Verbosity

Flag uncertainty briefly (“Assumption:”).

Do not hedge with multiple disclaimers.

Prefer being approximately correct and revisable over exhaustive.

9. Default Refusal Behavior

If a request would require large restatement or redundancy:

Ask to confirm scope before generating.

10. Formatting Defaults

Bullets > paragraphs

Tables > prose

Headings only when they add structure

Standard Request Template (Optional)

Use this format when issuing tasks to reduce overhead:

Task:
Constraints:
Unchanged:
Output format:

Example (Compressed)
Task: Adjust morale damage formula
Constraints: No new stats, no randomness
Unchanged: Combat flow, turn order
Output format: Formula + 2 examples


Testing Architecture Guidelines (Godot + GdUnit)

This project prioritizes testability, determinism, and low coupling.
Excessive setup of autoloads and scene trees in tests is treated as a design smell, not a testing failure.

Core Principle

Most game logic must be testable without a running scene tree or autoloads.

Autoloads exist to wire systems together, not to own logic.

Test Layers
1. Unit Tests (Primary)

Goal: Fast, deterministic, isolated.

Characteristics

No scene tree

No autoload access

No get_tree(), get_node("/root"), or signals

Pure logic or plain objects

Examples

Combat math

AI scoring

Path cost evaluation

Morale calculations

Weather modifiers

If a test requires autoloads, it does not belong here.

2. Integration Tests (Limited)

Goal: Verify wiring and Godot-specific behavior.

Characteristics

Minimal scene tree

Real autoloads allowed

Small number of tests

Focused on boundaries

Examples

Autoload registration

Signal propagation

Scene bootstrapping

Save/load integration

Integration tests are expected to have setup and teardown. Unit tests are not.

Autoload Usage Rules
Allowed

Autoloads as composition roots

Autoloads holding references to services

Swapping service implementations in tests

Discouraged

Game logic inside autoloads

Classes that directly reach into /root

Logic that assumes load order or tree presence

Dependency Injection Standard

Game logic must not fetch its own dependencies.

Instead of
var units = GameState.get_units()

Prefer
func _init(game_state):
	_game_state = game_state


Dependencies are passed in:

via _init

via setters

via explicit parameters

This enables test doubles and removes global state coupling.

Pure Logic vs Godot Glue
Pure Modules

No Nodes

No Signals

No Autoloads

No Tree

These contain the rules of the game.

Glue Layers (Nodes / Autoloads)

Translate world state into inputs

Call pure logic

Apply results back to the scene

Only glue layers touch Godot APIs.

Service Container Pattern (Preferred Singleton Use)

If global access is needed, use one autoload:

Services


It stores references only:

rng

time

config

save

analytics

In tests, replace fields with fakes:

Services.rng = FakeRng.new()


Avoid multiple global managers.

Data Over Nodes

When possible, represent systems as:

Resources

Plain script classes

Value objects

Nodes are for presence and lifecycle, not rules.

GdUnit-Specific Guidance
Naming

test_*.gd → unit tests

itest_*.gd → integration tests

Setup Expectations

Unit tests should not require _before_each for world setup

Integration tests may, but should reuse a shared harness

Red Flags (Trigger Refactor)

Refactor when:

Most tests fail due to missing autoloads

Tests depend on scene load order

You must recreate half the game to test one method

Logic cannot be constructed without /root

These indicate architectural coupling, not a testing problem.

Refactor Strategy (Incremental)

Identify managers causing the most test friction

Extract pure logic into standalone modules

Keep Nodes/autoloads as adapters

Convert existing tests to unit tests first

Leave a small integration test surface

A single good extraction usually removes 70–90% of setup code.

Design Goal

Autoloads should be boring.
Tests should be cheap.
Logic should be portable.

If logic cannot be tested cheaply, it is not finished.


Overview

- This is a Godot 4 project that uses GdUnit4 for automated tests under `tests`.
- Primary gameplay and menus live under `Gameplay/` and `Menus/`. Shared globals are under `Autoloads/`.
- Tests generate HTML reports under `reports/` when run via the provided scripts.

Layout

- `project.godot` — Godot project file (lists autoloads, etc.).
- `Autoloads/` — Global singletons. Examples:
  - `input_mapper.gd` — Maps actions from key/button arrays. Note: cast ints to enums (Key/JoyButton).
  - `control_settings.gd` (referenced in tests) — Stores input preferences used by menus and gameplay.
- `Menus/` — Menu scenes and scripts, e.g. `title_screen.tscn`, `title_screen.gd`.
- `Gameplay/` — Gameplay scenes and scripts, e.g. `gameplay.tscn`.
- `Resources/` — Project resources (scripts, data, assets) used by scenes.
- `addons/` — Editor/runtime plugins (includes GdUnit4 and other tools).
- `tests/` — GdUnit4 test suites (`*.gd`). Look for patterns like `scene_runner`, `simulate_frames`, and signal waits.
- `scripts/` — Helper scripts for CI and local execution.

Running Tests

- Windows PowerShell: `scripts/run_tests.ps1`
  - Auto-resolves/downloads an appropriate Godot CLI via `scripts/godot_cli.ps1` if not provided.
  - Executes: `--headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`.
- CMD alternatives are available: `scripts/run_tests.cmd`, `scripts/godot_cli.cmd`.
- Set `HEX_GODOT_EXE` or `GODOT_EXE` to use a local Godot binary (skips download).

Common Test Utilities/Patterns

- `scene_runner(path)` creates a test harness instance and loads the scene.
- After instantiation, wait at least one frame so `_ready`/deferred calls complete:
  - `await runner.simulate_frames(1)`
- To drive time-based or process-driven behavior, advance multiple frames:
  - `await runner.simulate_frames(n)`
- Prefer signal waits when available for deterministic assertions:
  - `await runner.simulate_until_object_signal(tree, "scene_changed")`
- Input injection helpers (examples from tests):
  - Keys: create `InputEventKey`, set `keycode: Key`, `pressed = true`, and call `scene._unhandled_input(event)`.
  - Joy buttons: create `InputEventJoypadButton`, set `button_index: JoyButton`, `pressed = true`, then `_unhandled_input`.

Type and Enum Conventions (Godot 4)

- Be explicit with enums to avoid warnings/errors:
  - `InputEventKey.keycode: Key` → cast ints with `as Key`.
  - `InputEventJoypadButton.button_index: JoyButton` → cast ints with `as JoyButton`.
- Tests and gameplay code expect typed GDScript where practical.

Scenes Referenced in Tests

- `res://Menus/title_screen.tscn`
- `res://Gameplay/gameplay.tscn`

Helpful Commands

- Run tests: `pwsh -File scripts/run_tests.ps1`
- Get Godot CLI path: `pwsh -File scripts/godot_cli.ps1`
- Launch editor/engine directly (example): `pwsh -File scripts/godot_cli.ps1 -Run -- -e` (adds `-e` after `--`).
- Validate and generate suggestions/TODOs: `pwsh -File scripts/validate.ps1 -UpdateTodos`
- Prune old test reports (keep 10): `pwsh -File scripts/prune_reports.ps1 -Keep 10`

Authoring New Tests

- Load with `scene_runner`, wait 1 frame, then interact.
- Use `simulate_until_object_signal` when transitioning scenes or waiting for explicit events.
- For pure functions without frame dependencies, call directly and assert synchronously.
- When tests assert too early or are flaky, add one more `simulate_frames(1)` or prefer a signal wait.

Notes for Agents

- Avoid scanning `.godot/` except for config facts; it’s large and mostly editor cache.
- Most functional logic is in `Autoloads/`, `Menus/`, `Gameplay/`, and `Resources/`.
- Keep changes minimal and aligned with existing typed GDScript patterns.
- Do not modify plugin/addons code unless directly relevant to a task.

Agent Rules (Tests Required)

- When you add a new function in any `.gd` outside of `tests/`, `addons/`, `demo/`, `example/`, or `script_templates/`, you must:
  - Add or update a GdUnit4 test under `tests/` that references the function by name.
  - Prefer deterministic waits: `simulate_until_object_signal(...)` over fixed frames when feasible.
  - Use `await runner.simulate_frames(1)` after scene load and after input as needed.
- Before yielding work, run:
- `pwsh -File scripts/run_tests.ps1`
- `python scripts/check_function_tests.py` (ensures all project functions are referenced in tests)
- Or run the combined validator:
- `pwsh -File scripts/validate.ps1 -UpdateTodos` (runs tests, checks function coverage, and updates `TODO.md` with next steps)

Reports Retention

- Keep at most 10 report folders under `reports/` to reduce noise.
- After running tests, prune old reports using either:
  - `pwsh -File scripts/validate.ps1 -UpdateTodos` (auto-prunes to 10 by default)
  - or `pwsh -File scripts/prune_reports.ps1 -Keep 10`
- If tests fail, fix the code or tests you touched; do not edit unrelated areas.

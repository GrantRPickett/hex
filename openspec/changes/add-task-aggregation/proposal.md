# Change: Task Aggregation And Carryover

## Why
- Current narrative tasks assume a 1:1 mapping between task definitions and world targets, so we cannot represent pooled objectives (e.g., collect 3 relics from any source) or group loyalty bars.
- Stage transitions reset partially completed optional goals, creating narrative whiplash and punishing players when surprise events trigger.
- Designers want to mix task primitives (collect, defeat, convince) under a single logical quest that can span stages and even run in parallel with other factions.

## What Changes
- Introduce a task aggregation model that allows 1:N relationships between a task and the targets it monitors, including hidden/pooled targets.
- Persist task progress across stage transitions with explicit carryover rules so partial credit and optional objectives survive surprise changes.
- Allow multi-outcome logic at the task level (e.g., "get item OR kill boss") so designers can express composite goals without custom scripting.
- Define safeguards for narrative pacing (e.g., only optional tasks roll over, requirements for bracketing, and how bonuses affect other tasks).

## Impact
- Specs: task-system (new capability) describing aggregation, carryover, and branching requirements.
- Code: Task manager, stage/state controllers, UI surfaces that summarize aggregated tasks, save data schema.

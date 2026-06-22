## Context

The game uses a Task system where units interact with targets (Units, Locations, Loots). Some locations have specific "exploration" requirements that should feel more like a skill check than a simple interaction.

## Decisions

- **Reuse Task System**: We will leverage the existing `Task` class's `is_opposed` and `effort_required` properties.
- **Action Panel Integration**: `TaskActionProvider` will be updated to recognize `event_type == "explore"`.
- **Opposed Check**: The `Task.gd` already has `_calculate_event_progress` which handles `val - opp_val`. We will ensure the `Explore` action correctly passes the necessary event data.

## Risks / Trade-offs

- **One action per turn**: Exploring costs an investigation action point.

## ADDED Requirements

### Requirement: Mid-Stage Quest Rewards

The system SHALL support granting quest items directly to a unit's inventory upon completion of a task.

#### Scenario: Exploration reward

- **GIVEN** a task with a `reward_id` for a quest item
- **WHEN** a unit completes the task by exploring the target location
- **THEN** the quest item SHALL be added to that unit's inventory
- **AND** the item SHALL NOT be routed to the faction stash until the level concludes or the unit is defeated.

### Requirement: Survival Task Attribution

The system SHALL correctly attribute task completion to the `owning_faction` for duration-based tasks that have no specific unit actor.

#### Scenario: Survive for 5 turns

- **GIVEN** a task with `owning_faction` set to PLAYER and `duration_turns` set to 5
- **WHEN** 5 rounds pass while the condition still holds
- **THEN** the task SHALL be completed for the PLAYER faction.

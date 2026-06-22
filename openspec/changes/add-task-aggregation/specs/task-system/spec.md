## ADDED Requirements
### Requirement: Aggregated Task Targets
Tasks SHALL support a one-to-many relationship with world targets so designers can express pooled goals (e.g., collect any 3 relics, convince 2 units in a squad) without duplicating task definitions.

#### Scenario: Collecting pooled relics
- **GIVEN** a task configured with a pool of targets (loot nodes A, B, C)
- **AND** the task defines a completion threshold of 3 pickups
- **WHEN** the player loots any combination of three relics from that pool
- **THEN** the task SHALL mark progress for each pickup regardless of which target provided it
- **AND** the HUD SHALL display the pooled progress without exposing hidden targets until they are interacted with.

### Requirement: Task Carryover Across Stages
The system SHALL persist task progress (counts, flags, loyalty meters) across stage transitions according to explicit carryover rules so partial progress is not lost when a stage ends unexpectedly.

#### Scenario: Surprise stage change mid-collection
- **GIVEN** a task that requires convincing 4 citizens
- **AND** only 2 citizens have been convinced before an event forces the stage to advance
- **WHEN** the new stage begins
- **THEN** the task SHALL restore the partial progress (2/4)
- **AND** it SHALL continue tracking in the new stage if marked as carryover
- **AND** if the task was non-optional and the new stage disallows it, the system SHALL archive the partial progress and award any collateral rewards (e.g., minor reputation) defined by designers.

### Requirement: Composite Task Logic
Tasks SHALL support composite logic expressions (e.g., OR between multiple completion primitives, bonus progress on related tasks, or faction-specific outcomes) evaluated at the task level rather than per-stage.

#### Scenario: "Get item or defeat boss" composite
- **GIVEN** a task that is completed by either retrieving the Crown OR defeating the Warden
- **AND** the task awards +25 loyalty to an allied faction when either condition is met
- **WHEN** the player defeats the Warden while an allied faction simultaneously retrieves the Crown off-screen
- **THEN** the system SHALL resolve the task once either condition is satisfied, ignoring duplicate completions
- **AND** it SHALL apply the loyalty bonus exactly once and update any dependent tasks that consume that bonus progress.

### Requirement: Optional Task Safeguards
Optional tasks that roll over between stages SHALL be bracketed so they cannot block critical narrative progression, and designers SHALL be able to tag rewards that trigger branch-specific dialogue or auto-resolution when deferred.

#### Scenario: Optional scouting task during branching stage
- **GIVEN** an optional "Scout Ruins" task tagged as rollover-allowed
- **WHEN** the main narrative advances before the scout task is finished
- **THEN** the task SHALL move to the new stage in a suspended state
- **AND** if the player completes it later, the system SHALL fire any branch-specific dialogue defined for the completed stage
- **ELSE** if the player never completes it, the system SHALL auto-resolve the task using the designer-specified fallback (e.g., faction handles it off-screen) without blocking the main quest.

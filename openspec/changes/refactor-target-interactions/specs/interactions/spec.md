# Target Interactions

## ADDED Requirements

### Requirement: Item Interactions

Items MUST provide contextual actions based on whether they are trapped (tied to an opposed task).

#### Scenario: Safe Loot

When interacting with an item that has no opposed task, the "loot" action is available. This is an unopposed action that immediately grants the item.

#### Scenario: Trapped Loot

When interacting with an item that has an opposed task, the "trapped" action is available. This is an opposed action; the unit must pass the check to receive the item.

### Requirement: Location Interactions

Locations MUST provide contextual actions based on task presence.

#### Scenario: Unopposed Visit

When interacting with a location lacking an opposed task, the "visit" action is available. This is an unopposed action resulting in a reward (e.g., information dialogue or item).

#### Scenario: Opposed Explore

When interacting with a location tied to a task, the "explore" action is available. This is an opposed action required to clear the task and gain the reward.

### Requirement: Unit Interactions

Units MUST only interact with units of a different faction. Same-faction interactions SHALL be disabled. AI controls use symmetrical rules to player controls.

#### Scenario: Enemy Combat

When interacting with an enemy unit, the "fight" action is available. This is an opposed check regardless of task presence.

#### Scenario: Neutral Convincing

When interacting with a neutral unit that has no loyalty assigned, the "convince" action is available. This is an unopposed check.

#### Scenario: Loyal Neutral Combat

When interacting with a neutral unit that is loyal to the enemy, the "fight" action is available as an opposed check. (In hard mode, neutrals loyal to one side can attempt to convince unloyal neutrals).

### Requirement: Neutral Unit Willpower and Loyalty

Neutral units MUST follow specialized willpower limits and singular loyalty shifts.

#### Scenario: Inclination at Half Willpower

When a neutral unit's willpower drops to half, it sets its inclination loyalty. This loyalty starts neutral and flips only once per level (even if willpower regenerates).

#### Scenario: Retreat at Zero Willpower

When a neutral unit's willpower reaches 0, it retreats from the map and drops its loot immediately.

#### Scenario: End of Level Loot

If a neutral unit survives to the end of the level with non-zero willpower, it grants its remaining loot at that time.

### Requirement: Difficulty-scaled Loot Rules

The game difficulty settings MUST dictate how loot is awarded when the map is not fully routed.

#### Scenario: Difficulty Scaling

On Easy difficulty, all loot is dropped. On Mid difficulty, neutral loot is dropped but enemy loot requires loyalty or map routing. On Hard difficulty, no enemy or neutral loot is given without routing.

## MODIFIED Requirements

### Requirement: Faction-Aware Tasks

Tasks MUST be assigned to specific factions conceptually, allowing AI agents to evaluate tasks meant for their team.

#### Scenario: AI Pursues Team Tasks

When a level is built, tasks are filtered by team. An AI-controlled enemy unit will attempt to work on target tasks associated with its faction symmetrically to the player.

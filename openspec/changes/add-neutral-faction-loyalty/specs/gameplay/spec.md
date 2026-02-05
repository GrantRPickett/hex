## ADDED Requirements
### Requirement: Level Support For Missing Factions
Levels MUST operate deterministically regardless of which factions are present.

#### Scenario: Player-Only Level
- **GIVEN** a level roster that only spawns player-controlled units
- **WHEN** gameplay begins
- **THEN** turn sequencing, goals, and morale continue running without requiring enemy or neutral units
- **AND** level completion/failure checks behave the same as when other factions exist.

#### Scenario: No Neutral Units
- **GIVEN** a level that defines only player and enemy rosters
- **WHEN** the level loads
- **THEN** neutral-specific systems (morale bars, threat overlays, AI hooks) stay inactive with no warnings or crashes.

#### Scenario: No Enemy Units
- **GIVEN** a level that includes player and neutral units but zero enemies
- **WHEN** gameplay starts
- **THEN** the turn controller alternates among present factions
- **AND** win/loss conditions rely solely on goals and morale of existing sides.

### Requirement: Neutral Loyalty Behavior
Neutral units MUST track a temporary loyalty/leaning toward the player or enemy without changing direct control.

#### Scenario: Reaction To Aggression
- **GIVEN** a neutral unit with no current leaning
- **WHEN** the player (or enemy) attacks that unit
- **THEN** the neutral marks a defensive leaning against the aggressor and may retaliate on subsequent turns.

#### Scenario: Persuasion And Rallying
- **GIVEN** a neutral unit flagged as persuadable
- **WHEN** scripted dialogue, objectives, or other neutrals succeed at persuasion
- **THEN** the unit records a leaning toward the specified faction
- **AND** may influence nearby neutral units to adopt the same leaning while remaining outside direct player/enemy control.

### Requirement: Loyalty Reset Per Level Start
Neutral loyalty state MUST reset each time a level starts or reloads.

#### Scenario: Level Reload Clears Loyalty
- **GIVEN** one or more neutral units that previously leaned toward a faction
- **WHEN** the level restarts (new game, retry, or checkpoint restore)
- **THEN** every neutral unit returns to the default neutral alignment before gameplay resumes.

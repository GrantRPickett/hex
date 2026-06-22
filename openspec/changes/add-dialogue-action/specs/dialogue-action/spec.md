## ADDED Requirements
### Requirement: Author Level Dialogue Triggers
Each level resource MUST allow designers to declare visual-novel conversations by listing who can initiate them, who they can talk to, and the Dialogic timeline that should be played.

#### Scenario: Configure adjacency conversation
- **GIVEN** a level resource defines a dialogue trigger with an initiator unit id, a required near partner id (or faction), a unique flag id, and a Dialogic timeline resource
- **WHEN** the level loads
- **THEN** the gameplay systems MUST register that trigger with the dialogue service so it can be offered to players.

### Requirement: Expose Talk action when conditions pass
When a selected player unit is near to a valid dialogue partner and the trigger is not exhausted, the actions list MUST include a "Talk" entry that consumes the units action just like other interactions.

#### Scenario: Show talk action next to eligible partner
- **GIVEN** a player-controlled unit that still has an action
- **AND** the unit stands on a hex distance of 1 from a unit that satisfies a registered dialogue trigger
- **AND** the triggers seen flag is false
- **WHEN** the HUD requests available actions
- **THEN** the returned list MUST contain a "Talk" action describing the partner.

### Requirement: Run Dialogic visual novel flow
Starting a dialogue MUST hide the tactical HUD/controllers, show the Dialogic text layout, and restore gameplay once the timeline finishes. Completion flags MUST persist so each trigger can only run once per level unless marked repeatable.

#### Scenario: Start and finish dialogue
- **GIVEN** the player selects the "Talk" action
- **WHEN** the command executes
- **THEN** gameplay inputs MUST pause, HUD CanvasLayers MUST become invisible, and a Dialogic timeline MUST start that lets the player advance text until completion
- **AND** after the timeline resolves, HUD visibility and inputs MUST be restored, the triggers seen flag MUST toggle true, and the talk action MUST disappear until a reset occurs.

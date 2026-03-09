# Morale & Willpower Design

The Morale system in HEX translates the collective physical and mental state of a faction into gameplay consequences, specifically determining when a faction "breaks" and retreats.

## Core Concepts

### Willpower (WP)
- Willpower serves as the "Health" of a unit.
- When WP reaches 0, the unit is defeated and removed from the board.
- Willpower is also the primary driver of faction-wide Morale.

### Group Morale
- Morale is calculated as the ratio of **Current Faction Willpower** to **Initial Faction Willpower**.
- It is tracked independently for Player, Enemy, and Neutral factions.
- Initial Willpower is captured at the start of a level or when significant unit changes occur (spawns/removals).

## Retreat Mechanics

When a faction's total current Willpower drops below a specific threshold relative to its initial baseline, a **Retreat Trigger** occurs.

### Thresholds by Difficulty
Retreat thresholds are managed by the `DifficultyService`:
- **Easy**: 10% WP remaining. Factions are stubborn and stay longer.
- **Normal**: 20% WP remaining. Standard retreat behavior.
- **Hard**: 30% WP remaining. Factions are more cautious and break earlier.

### Trigger Consequences
When a retreat is triggered:
- The corresponding signal is emitted from the `MoralePanel`:
  - `player_retreat_triggered`
  - `enemy_retreat_triggered`
  - `neutral_retreat_triggered`
- External controllers (like `LevelStateController`) listen for these signals to handle level failure or victory conditions.

## Technical Implementation

### MoralePanel
Located at `GUI/morale_panel.gd`, this component:
1. Tracks all active units via the `UnitManager`.
2. Connects to the `willpower_changed` signal of every unit.
3. Updates the HUD display (labels and the Morale Advantage Bar).
4. Evaluates retreat conditions every time Willpower changes.

### Stability & Debugging
- To prevent debug stat boosts from affecting the "fair" morale calculation, `MoralePanel` uses a stable baseline that excludes debug-applied stats.
- Retreat triggers are one-way (once met, they remain met for the duration of the stage).

## Design Intent
The system is designed to provide a "soft" victory/failure condition. Instead of having to hunt down every last unit, the level can resolve once the tide of battle has clearly turned, reinforcing the narrative feel of a shifting conflict.

## Customer Voice Review (Player Experience)

The goal of the Morale system is to create a "cozy but tense" tactical experience rather than pure stress.

- **The "Cozy" Aspect**: Knowing that you don't need to eliminate every single enemy to win allows for more narrative exits. Seeing the Enemy ratio drop gives a sense of progress that is more satisfying than just "hp bars going down."
- **The "Stress" Aspect**: Factions breaking early on Hard difficulty (30%) can be surprising. Players need clear visual feedback (provided by the Morale Advantage Bar) to feel like they are in control of the situation.
- **Tunability**: The use of `DifficultyService` allows players to choose how much friction they want. Easy mode feels more like a heroic sweep, while Hard mode requires careful management of every unit's Willpower to prevent a premature retreat.

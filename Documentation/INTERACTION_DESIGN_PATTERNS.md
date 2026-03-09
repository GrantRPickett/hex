## Narrative Design: Interaction & Stake Patterns
This document outlines how to utilize the **Opposed** and **Unopposed** check systems to create meaningful narrative stakes across different target types (Locations, Loot, and Units).

### Core Philosophy
- **Unopposed Checks (Momentum)**: Represent preparation, established trust, or exploitation of an opening. They reward positioning and previous successes.
- **Opposed Checks (Friction)**: Represent conflict, environmental hazards, or complex problem-solving. They require attribute investment and risk stalling the party's progress.

---

### 1. The Interaction Matrix

| Target Type | Unopposed (Visit/Loot/Talk) | Opposed (Explore/Trap/Convince) |
| :--- | :--- | :--- |
| **Locations** | **Safe Havens**: Checkpoints, buff altars, or narrative triggers that reward reaching a specific tile. | **Wards & Barricades**: Magical or physical obstacles requiring specific attributes (Grit/Focus) to clear. |
| **Loot (Things)** | **Scavenged Supplies**: Items left in the open or granted by allies. Instant acquisition. | **Encased Items**: Trapped chests, frozen relics, or heavy machinery requiring effort over multiple turns. |
| **Units (People)** | **Allies & Defectors**: Units already inclined to help. Interactions provide instant intel or items. | **Rivals & Guardians**: Characters with their own agendas. Must be socially outmaneuvered or physically overcome. |

---

### 2. Level Stage Blueprints

#### Pattern A: The Silent Infiltration (Focus/Flow)
*Story Beat*: The party must bypass ancient magical wards without alerting nearby sentries.
*   **Location (Opposed)**: *Magical Wards*. Requires a **Focus** check to "dampen" the resonance. Low progress ratio means the alarm might sound before the party passes.
*   **Location (Unopposed)**: *Scrying Pool*. Reaching this grants a temporary "Cloak" status, making the next ward check Unopposed.
*   **Loot (Opposed)**: *Key of Silence*. Encased in a *Stasis Field*. Requires a **Flow** check to extract without shattering.

#### Pattern B: The Marketplace Standoff (Shine/Shade)
*Story Beat*: A three-way standoff between guards, citizens, and merchants.
*   **Unit (Unopposed)**: *Fleeing Witness*. Talking provides the "Truth" (Quest Item) instantly.
*   **Unit (Opposed)**: *Bribed Guard*. Loyal to the enemy. "Convincing" him is opposed by his **Shade** (Greed). Using **Shine** (Charisma) overcomes this.
*   **Location (Opposed)**: *Barricaded Gate*. Must use **Grit** to force open while the standoff escalates.

#### Pattern C: The Frozen Retreat (Gusto/Grit)
*Story Beat*: Survising a blizzard while being hunted.
*   **Loot (Opposed)**: *Frozen Warmth Crystal*. Encased in ice. Requires **Gusto** to break open. High opposition requires "Cumulative" effort from multiple units.
*   **Loot (Unopposed)**: *Discarded Supply Crate*. Found in the snow. Provides instant Willpower restoration.
*   **Task (Duration)**: "Survive for 5 Rounds" while defending the crystal.

---

### 3. Implementation Guide for Level Designers

To implement these in a `.tres` or `.json` level file, use the following `Task` metadata:

#### For Unopposed "Momentum"
```json
{
  "event_type": "visit",
  "is_opposed": false,
  "effort_required": 1
}
```

#### For Opposed "Friction"
```json
{
  "event_type": "explore",
  "is_opposed": true,
  "opposition_value": 15,
  "attribute_hint": "grit",
  "effort_required": 30
}
```

#### For Duration "Defend"
```json
{
  "event_type": "countdown",
  "duration_turns": 5,
  "duration_mode": "cumulative"
}
```

### 4. Integration with Difficulty
- **Easy**: `DifficultyService` reduces the weight of Opposed checks, making "Friction" easier to overcome.
- **Hard**: `DifficultyService` increases opposition values, making specialized units (high Grit/Focus) essential for clearing environmental obstacles.

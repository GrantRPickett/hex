## MODIFIED Requirements
### Requirement: Compact Target Selection
List entries in HUD panels SHALL automatically collapse into a scrollable or "more" menu if providing more than 3 distinct options.

#### Scenario: List overflow
- **GIVEN** a HUD panel has 4 or more list items
- **WHEN** the panel is rendered
- **THEN** it SHALL auto-collapse entries beyond the 3rd item.


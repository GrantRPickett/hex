# navigation Specification

## Purpose
TBD - created by archiving change refactor-navigation-to-astar. Update Purpose after archive.
## Requirements
### Requirement: AStar2D Pathfinding
The navigation system SHALL use Godot's native `AStar2D` for point-to-point pathfinding on hexagonal grids.

#### Scenario: Optimized path finding
- **WHEN** a unit requests a path between two hexes
- **THEN** the system SHALL return the lowest-cost path based on terrain weights using the `AStar2D` engine.

#### Scenario: Dynamic blocker avoidance
- **WHEN** a path is calculated
- **THEN** any blocked hexes in the current context SHALL be treated as disabled points in the AStar graph.

#### Scenario: Threatened hex weighting
- **WHEN** a path passes through threatened hexes
- **THEN** the cost of those steps SHALL be increased proportionally to prioritize safer routes.


# Design: AStar2D Navigation

## Context

Standardizing pathfinding on Godot's native engine to improve performance and maintainability.

## Goals

- Native C++ pathfinding performance.
- Clean integration with `TerrainMap`.
- Support for dynamic weights (threat zones).

## Decisions

- **Decision**: Keep BFS for range flood-fills.
- **Decision**: Use `TerrainMap` instance IDs for cache validation.

## Rationale

BFS is more efficient for full-range exploration than repeated A* calls.

## Risks

- **Risk**: Edge cases in hex coordinate mapping.
- **Mitigation**: Comprehensive unit tests.

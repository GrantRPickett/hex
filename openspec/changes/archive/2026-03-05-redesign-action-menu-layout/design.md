## Context

The action menu is the primary interface for player interactions. As the game grows, vertical lists are becoming cumbersome and obstructive.

## Goals / Non-Goals

- **Goals**:
  - Avoid grid overlap by using horizontal space better.
  - Group paired stats (Grit/Flow, Gusto/Focus, Shine/Shade) together in a 3x2 grid.
  - Simplify target selection when multiple targets are valid for an action.
- **Non-Goals**:
  - Changing the underlying combat or interaction logic.
  - Redesigning the entire HUD (focus is on the Actions Panel).

## Decisions

- **Decision: 3x2 Attribute Grid**:
  - Attributes will be displayed in 3 columns and 2 rows.
  - Columns represent the pairs: (Grit, Flow), (Gusto, Focus), (Shine, Shade).
  - This aligns with the game's "opposite" attribute mechanic.
- **Decision: Refined Target List**:
  - When an action needs a target (like Attack or Convince), targets will be listed clearly, potentially using a more compact format or grid if many are present.

## Risks / Trade-offs

- [Risk] Layout breaking on very narrow screens → [Mitigation] Ensure `CustomResizablePanel` handles minimum sizes correctly.

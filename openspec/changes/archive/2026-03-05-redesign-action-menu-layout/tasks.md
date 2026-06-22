## 1. Spec Update

- [ ] 1.1 Update `hud-actions` spec with new layout requirements

## 2. Implementation

- [x] 2.1 Refactor `ActionsPanel.gd` to support grid layout for attributes
- [x] 2.2 Update `show_attribute_menu` to use a `GridContainer` instead of a `VBoxContainer` for attribute buttons
- [x] 2.3 Group Grit/Flow, Gusto/Focus, Shine/Shade in the grid columns
- [x] 2.4 Refine target selection button generation for better spatial efficiency
- [x] 2.5 Ensure the panel resizing logic (`CustomResizablePanel`) accounts for the wider grid layout

## 3. Verification

- [ ] 3.1 Verify attribute pairs are correctly grouped (Grit/Flow, Gusto/Focus, Shine/Shade)
- [ ] 3.2 Verify no overlap with the game grid on standard resolutions
- [ ] 3.3 Verify target selection remains intuitive when multiple targets are nearby

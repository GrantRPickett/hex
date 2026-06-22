## 1. UI Navigation Improvements
- [ ] 1.1 Enable `bbcode_enabled` on `Layouts` RichTextLabel (DONE)
- [ ] 1.2 Audit and set `focus_mode` for all interactive elements in `settings_menu.tscn`
- [ ] 1.3 Implement `focus_neighbor` links in `SettingsMenu` code for dynamic rows

## 2. Input Architecture
- [ ] 2.1 Create `Autoloads/input_mode_manager.gd` with `Mode` enum and state tracking
- [ ] 2.2 Register `InputModeManager` as an Autoload in `project.godot`
- [ ] 2.3 Update `InputController.gd` or `InputCommandRouter.gd` to respect the active mode

## 3. Controller Mappings
- [ ] 3.1 Update `InputActions.gd` with Joypad defaults for Camera Pan, Rotation, and Selection
- [ ] 3.2 Verify all actions have at least one valid joypad binding

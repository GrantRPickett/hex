# Refactor TODO

## Longest Files to Split
1. Gameplay/gameplay.gd — 339 lines
2. Menus/title_screen.gd — 98 lines
3. Autoloads/control_settings.gd — 68 lines
4. Autoloads/game_config.gd — 67 lines
5. Autoloads/scene_transition.gd — 60 lines
6. Autoloads/level_manager.gd — 59 lines
7. Autoloads/audio_bus_controller.gd — 50 lines
8. Menus/level_select.gd — 43 lines
9. Menus/pause_menu.gd — 35 lines
10. Autoloads/input_mapper.gd — 34 lines

## Longest Functions to Break Up
1. Gameplay/gameplay.gd:169 _handle_mouse_button — 54 lines
2. Autoloads/scene_transition.gd:13 change_scene — 54 lines
8. Menus/level_select.gd:11 _populate_levels — 22 lines
9. Gameplay/gameplay.gd:87 _ready — 22 lines
10. Autoloads/level_manager.gd:49 _on_level_complete — 22 lines

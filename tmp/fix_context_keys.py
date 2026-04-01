import os

files = [
    r"tests\test_pathfinding_execution.gd",
    r"tests\test_talk_to_unit_command.gd",
    r"tests\test_input_commands.gd",
    r"tests\test_fix_verification.gd",
    r"tests\test_command_coverage.gd",
    r"tests\test_action_commands.gd",
    r"Gameplay\commands\aid_ally_command.gd",
    r"Gameplay\commands\attack_unit_command.gd",
    r"Gameplay\commands\cancel_move_command.gd",
    r"Gameplay\commands\command_history.gd",
    r"Gameplay\commands\confirm_move_command.gd",
    r"Gameplay\commands\explore_command.gd",
    r"Gameplay\commands\joy_move_command.gd",
    r"Gameplay\commands\loot_command.gd",
    r"Gameplay\commands\selection_cycle_command.gd",
    r"Gameplay\commands\toggle_enemy_range_command.gd",
    r"Gameplay\commands\SKILL_command.gd",
    r"Gameplay\commands\visit_command.gd",
    r"Gameplay\commands\wait_command.gd",
    r"Gameplay\commands\zoom_camera_command.gd",
    r"Gameplay\commands\undo_command.gd",
    r"Gameplay\commands\trapped_command.gd",
    r"Gameplay\commands\toggle_free_cam_command.gd",
    r"Gameplay\commands\talk_to_unit_command.gd",
    r"Gameplay\commands\select_index_command.gd",
    r"Gameplay\commands\primary_action_command.gd",
    r"Gameplay\commands\move_to_coord_command.gd",
    r"Gameplay\commands\move_action_command.gd",
    r"Gameplay\commands\game_command_context.gd",
    r"Gameplay\commands\convince_unit_command.gd"
]

base_path = r"c:\Users\grant\Documents\github\hex"

for rel_path in files:
    abs_path = os.path.join(base_path, rel_path)
    if os.path.exists(abs_path):
        with open(abs_path, 'r', encoding='utf-8') as f:
            content = f.read()

        new_content = content.replace("GameConstants.Context.", "GameConstants.ContextKeys.")

        if content != new_content:
            with open(abs_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated: {rel_path}")
        else:
            print(f"No changes: {rel_path}")
    else:
        print(f"Not found: {rel_path}")

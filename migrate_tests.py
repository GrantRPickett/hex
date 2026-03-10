import os
import re
import glob

test_files = glob.glob('tests/*.gd')
count = 0

for filepath in test_files:
	if 'base_test_suite.gd' in filepath or 'test_helpers.gd' in filepath:
		continue

	with open(filepath, 'r', encoding='utf-8') as f:
		content = f.read()

	original = content

	# helper method calls that need 'HexTestUtils.'
	content = re.sub(r'\bsetup_autoloads\(', 'HexTestUtils.setup_autoloads(get_tree(), ', content)
	content = re.sub(r'\bteardown_autoloads\(\)', 'HexTestUtils.teardown_autoloads(get_tree())', content)
	content = re.sub(r'\bensure_manager\(', 'HexTestUtils.ensure_manager(get_tree(), ', content)
	content = re.sub(r'\b_clear_save_game\(\)', 'HexTestUtils._clear_save_game()', content)
	content = re.sub(r'(?<!\.)\bfree_tree\(', 'HexTestUtils.free_tree(', content)
	content = re.sub(r'\b_mock_unit\(', 'HexTestUtils._mock_unit(self, ', content)
	content = re.sub(r'\b_create_scene_runner\(', 'HexTestUtils._create_scene_runner(self, ', content)
	content = re.sub(r'(?<!\.)\b_simulate_frames\(', 'HexTestUtils._simulate_frames(', content)
	content = re.sub(r'(?<!\.)\bassert_eq\(', 'HexTestUtils.assert_eq(self, ', content)

	# If a test uses setup_autoloads, it strongly implies it needs teardown_autoloads in after_test
	if 'setup_autoloads' in original and 'teardown_autoloads' not in original:
		if 'func after_test()' in content:
			# Inject teardown to the start of after_test()
			content = re.sub(r'(func after_test\(\)\s*(?:->\s*void)?\s*:\s*)',
							 r'\g<1>\n\tawait HexTestUtils.teardown_autoloads(get_tree())\n', content)
		else:
			# Create after_test() at the end
			content += "\nfunc after_test() -> void:\n\tawait HexTestUtils.teardown_autoloads(get_tree())\n"

	if content != original:
		with open(filepath, 'w', encoding='utf-8') as f:
			f.write(content)
		count += 1
		print(f"Updated {filepath}")

print(f"Migrated {count} test files.")

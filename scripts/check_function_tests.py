#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC_EXCLUDES = {
	ROOT / 'tests',
	ROOT / 'addons',
	ROOT / 'demo',
	ROOT / 'example',
	ROOT / 'script_templates',
	ROOT / '.git',
}

# Common Godot lifecycle/engine methods that we do not require to be referenced by tests
LIFECYCLE_METHODS: set[str] = {
	'_init',
	'_ready',
	'_enter_tree',
	'_exit_tree',
	'_process',
	'_physics_process',
	'_unhandled_input',
	'_input',
	'_notification',
	'_draw',
	'_gui_input',
}


def should_scan(path: Path) -> bool:
	for exclude in SRC_EXCLUDES:
		try:
			path.relative_to(exclude)
			return False
		except ValueError:
			continue
	return True


def collect_project_functions() -> list[tuple[str, str]]:
	functions: list[tuple[str, str]] = []
	for gd in ROOT.rglob('*.gd'):
		if not should_scan(gd):
			continue
		rel = gd.relative_to(ROOT)
		lines = gd.read_text(encoding='utf-8').splitlines()

		i = 0
		while i < len(lines):
			line = lines[i]
			match = re.match(r'^func\s+([A-Za-z0-9_]+)\s*\(', line)
			if not match:
				i += 1
				continue
			name = match.group(1)

			# Check decorators or "# no_test" on the line before
			if i > 0 and ('# no_test' in lines[i-1] or '# testing_todo' in lines[i-1]):
				i += 1
				continue

			# Measure function body size up to next unindented line or func
			body_lines = 0
			j = i + 1
			while j < len(lines):
				next_line = lines[j]
				stripped = next_line.strip()
				if not stripped or stripped.startswith('#'):
					j += 1
					continue
				# Check if it's indented (assuming scripts use tabs or spaces to indent)
				if not re.match(r'^[ \t]+', next_line):
					break
				body_lines += 1
				j += 1

			if body_lines <= 2:
				i += 1
				continue

			if name.startswith('test_') or name.startswith('_'):
				i += 1
				continue

			functions.append((str(rel).replace('\\', '/'), name))
			i += 1
	return functions


def strip_comments_and_strings(src: str) -> str:
	# Remove single-line comments and strings to reduce false positives
	src = re.sub(r'#[^\n]*', '', src)
	src = re.sub(r'"([^"\\]|\\.)*"', '""', src)
	src = re.sub(r"'([^'\\]|\\.)*'", "''", src)
	return src


def gather_tests_text() -> str:
	text_parts: list[str] = []
	tests_dir = ROOT / 'tests'
	if tests_dir.exists():
		for gd in tests_dir.rglob('*.gd'):
			raw = gd.read_text(encoding='utf-8')
			text_parts.append(strip_comments_and_strings(raw))
	return "\n".join(text_parts)


def main() -> None:
	tests_text = gather_tests_text()
	functions = collect_project_functions()
	missing: list[tuple[str, str]] = []
	
	# Mapping of function name to a list of files where it is defined
	function_map: dict[str, list[str]] = {}
	for rel_path, name in functions:
		if name not in function_map:
			function_map[name] = []
		function_map[name].append(rel_path)

	for rel_path, name in functions:
		# Look for likely identifier usage (call/property/type), not just bare word
		pattern = rf"\b{name}\s*(\(|\.|:|$)"
		if not re.search(pattern, tests_text):
			missing.append((rel_path, name))

	# Detect outdated tests: calls to methods that don't exist in project
	# We look for .method_name( patterns in tests
	outdated_calls: set[str] = set()
	# Whitelist of Godot built-in methods, GdUnit keywords, and common Variant methods
	WHITELIST = {
		'new', 'free', 'queue_free', 'add_child', 'remove_child', 'get_node', 'get_parent',
		'connect', 'disconnect', 'emit_signal', 'emit', 'has_signal', 'is_connected',
		'get', 'set', 'has_method', 'has_meta', 'get_meta', 'set_meta',
		'duplicate', 'print', 'print_debug', 'push_warning', 'push_error',
		'assert_that', 'assert_bool', 'assert_int', 'assert_float', 'assert_str', 'assert_object', 'assert_array',
		'is_equal', 'is_not_equal', 'is_null', 'is_not_null', 'is_true', 'is_false', 'is_empty', 'is_not_empty',
		'is_greater', 'is_less', 'is_approximately', 'is_approximately_equal',
		'auto_free', 'spy', 'mock', 'verify', 'any', 'any_int', 'any_string', 'any_bool',
		'size', 'append', 'remove_at', 'find', 'has', 'clear', 'duplicate', 'keys', 'values', 'get',
		'is_node_ready', 'ready', 'process_frame', 'create_timer', 'timeout',
		'Substring', 'StartsWith', 'EndsWith', 'replace', 'split', 'strip_edges',
		'get_tree', 'get_process_delta_time', 'get_physics_process_delta_time',
		'_init', '_ready', '_process', '_physics_process', '_input', '_unhandled_input',
		'is_instance_valid', 'str', 'int', 'float', 'bool', 'is_debug_build', 'tr',
		'bind', 'call_deferred', 'set_deferred', 'get_name', 'set_name',
	}
	
	test_files = list((ROOT / 'tests').rglob('*.gd'))
	outdated_found = False
	for test_file in test_files:
		raw = test_file.read_text(encoding='utf-8')
		stripped = strip_comments_and_strings(raw)
		# Look for calls like .method_name( or .method_name . or .method_name:
		# This is a bit broad but helps find suspicious calls
		calls = re.findall(r'\.([A-Za-z0-9_]+)\s*\(', stripped)
		for call in calls:
			if call not in function_map and call not in WHITELIST and not call.startswith('_'):
				if not outdated_found:
					print('Potential outdated test calls (calling non-existent project methods):')
					outdated_found = True
				print(f'  {test_file.relative_to(ROOT)}: {call}')

	if missing:
		print('Functions without test references:')
		for rel_path, name in missing:
			print(f'  {rel_path}: {name}')
		sys.exit(1)
	
	if outdated_found:
		print('\n❌ FAILURE: Outdated test calls detected. See above. (Add to WHITELIST if false positive)')
		sys.exit(1)

	print('Scan complete.')


if __name__ == '__main__':
	main()

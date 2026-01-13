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
		text = gd.read_text(encoding='utf-8')
		for match in re.finditer(r'^func\s+([A-Za-z0-9_]+)\s*\(', text, flags=re.MULTILINE):
			name = match.group(1)
			# Skip explicit tests
			if name.startswith('test_'):
				continue
			# Skip private and lifecycle methods
			if name.startswith('_'):
				if name in LIFECYCLE_METHODS:
					continue
				else:
					continue
			functions.append((str(rel).replace('\\', '/'), name))
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
	missing: list[tuple[str, str]] = []
	for rel_path, name in collect_project_functions():
		# Look for likely identifier usage (call/property/type), not just bare word
		pattern = rf"\b{name}\s*(\(|\.|:|$)"
		if not re.search(pattern, tests_text):
			missing.append((rel_path, name))
	if missing:
		print('Functions without test references:')
		for rel_path, name in missing:
			print(f'  {rel_path}: {name}')
		sys.exit(1)
	print('All functions referenced in tests.')


if __name__ == '__main__':
	main()

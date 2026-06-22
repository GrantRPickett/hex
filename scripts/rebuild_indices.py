#!/usr/bin/env python3
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTLINE_PATH = ROOT / "FUNCTION_OUTLINE.md"

EXCLUDES = {
	'.git',
	'.godot',
	'addons',
	'tests',
	'reports',
	'tmp',
}

def slugify(text: str) -> str:
	return re.sub(r'[^a-zA-Z0-9_]', '_', text).lower()

def extract_functions(file_path: Path) -> list[str]:
	functions = []
	try:
		content = file_path.read_text(encoding='utf-8')
		# Match 'func name(' or 'static func name('
		pattern = r'^\s*(?:static\s+)?func\s+([a-zA-Z0-9_]+)\s*\('
		matches = re.findall(pattern, content, re.MULTILINE)
		for m in matches:
			# Check for static
			line_pattern = rf'^\s*static\s+func\s+{m}\s*\('
			if re.search(line_pattern, content, re.MULTILINE):
				functions.append(f"static func {m}")
			else:
				functions.append(f"func {m}")
	except Exception as e:
		print(f"Error reading {file_path}: {e}")
	return functions

def main():
	print(f"Rebuilding indices from {ROOT}...")
	
	outline_content = ["# Project Function Outline\n"]
	
	# Group by directory
	grouped_files: dict[str, list[Path]] = {}
	
	for gd_file in ROOT.rglob("*.gd"):
		rel_path = gd_file.relative_to(ROOT)
		parts = rel_path.parts
		
		# Check excludes
		if any(exclude in parts for exclude in EXCLUDES):
			continue
			
		dir_name = parts[0] if len(parts) > 1 else "Root"
		if dir_name not in grouped_files:
			grouped_files[dir_name] = []
		grouped_files[dir_name].append(gd_file)
	
	# Sort directories
	for dir_name in sorted(grouped_files.keys()):
		outline_content.append(f"## {dir_name}\n")
		
		# Sort files in directory
		for gd_file in sorted(grouped_files[dir_name]):
			rel_path = str(gd_file.relative_to(ROOT)).replace('\\', '/')
			outline_content.append(f"### {rel_path}")
			
			funcs = extract_functions(gd_file)
			if funcs:
				for f in funcs:
					outline_content.append(f"- {f}()")
			else:
				outline_content.append("- (No functions defined)")
			outline_content.append("") # Spacer
			
	OUTLINE_PATH.write_text("\n".join(outline_content), encoding='utf-8')
	print(f"Successfully rebuilt {OUTLINE_PATH}")

if __name__ == "__main__":
	main()

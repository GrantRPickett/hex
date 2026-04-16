import os
import re

# Directories to scan
SCANDIRS = ["Gameplay", "GUI", "Menus", "level", "Autoloads"]
# Extensions to scan
EXTENSIONS = [".gd", ".tscn"]
# Patterns to ignore (already localized or technical)
IGNORE_PATTERNS = [
	r'res://', r'user://', r'uid://', # Godot paths
	r'print\(', r'print_debug\(', r'push_error\(', r'push_warning\(', # Logging
	r'tr\(', r'LocalizationStrings\.', # Already localized
	r'&"[^"]+"', # StringNames (often technical IDs)
	r'enum\s+\{', # Enums
	r'connect\(', r'emit_signal\(', # Signals
	r'get_node\(', r'get_node_or_null\(', r'\$', # Node paths
	r'name\s*=\s*"[^"]+"', # Node names
]

def audit():
	hardcoded = []

	# Regex for double-quoted strings
	# This is naive and will find many false positives, but it's a start
	string_regex = re.compile(r'"([^"\\\n]*(?:\\.[^"\\\n]*)*)"')

	for root_dir in SCANDIRS:
		for root, _, files in os.walk(root_dir):
			for file in files:
				if any(file.endswith(ext) for ext in EXTENSIONS):
					path = os.path.join(root, file)
					try:
						with open(path, 'r', encoding='utf-8') as f:
							for i, line in enumerate(f, 1):
								# Skip comments
								stripped = line.strip()
								if stripped.startswith("#") or stripped.startswith("//"):
									continue
								
								# Skip lines matching ignore patterns
								if any(re.search(pat, line) for pat in IGNORE_PATTERNS):
									continue

								# Simple comment stripping for inline comments
								content = line.split("#")[0].split("//")[0]

								matches = string_regex.findall(content)
								for match in matches:
									# Filter out technical strings
									if not match: continue
									if len(match) < 2: continue # likely technical
									if match.islower() and "_" in match: continue # likely ID
									if "/" in match or "." in match: continue # likely path or key
									
									# Heuristic for player-facing: contains spaces or starts with capital
									if match[0].isupper() or " " in match:
										# Additional filter: skip obvious Godot property names in .tscn
										if file.endswith(".tscn"):
											if "name =" in line or "type =" in line or "parent =" in line:
												continue
											if "unique_id =" in line or "resource_name =" in line:
												continue
										
										hardcoded.append((path, i, match))
					except Exception as e:
						print(f"Error reading {path}: {e}")

	if not hardcoded:
		print("No obvious hardcoded strings found. Good job!")
		return True
	else:
		print(f"Found {len(hardcoded)} potential hardcoded strings:")
		for path, line, text in hardcoded:
			print(f"{path}:{line} -> \"{text}\"")
		return False

if __name__ == "__main__":
	import sys
	if not audit():
		sys.exit(1)

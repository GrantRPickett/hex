import os
import re

def find_longest_functions(directory):
	func_pattern = re.compile(r'^\s*func\s+([a-zA-Z0-9_]+)\s*\((.*)\)\s*(->\s*[a-zA-Z0-9_]+)?\s*:', re.MULTILINE)
	results = []

	for root, _, files in os.walk(directory):
		for file in files:
			if file.endswith('.gd'):
				path = os.path.join(root, file)
				try:
					with open(path, 'r', encoding='utf-8') as f:
						lines = f.readlines()

					functions = []
					for i, line in enumerate(lines):
						match = func_pattern.match(line)
						if match:
							functions.append((match.group(1), i + 1))

					for i in range(len(functions)):
						name, start_line = functions[i]
						if i + 1 < len(functions):
							end_line = functions[i+1][1] - 1
						else:
							end_line = len(lines)

						# Remove trailing blank lines
						while end_line > start_line and not lines[end_line-1].strip():
							end_line -= 1

						length = end_line - start_line + 1
						if length > 40: # Threshold for "long"
							results.append({
								'file': path,
								'name': name,
								'length': length,
								'start': start_line,
								'end': end_line
							})
				except Exception as e:
					print(f"Error reading {path}: {e}")

	# Sort by length descending
	results.sort(key=lambda x: x['length'], reverse=True)
	return results

if __name__ == "__main__":
	base_dir = r"c:\Users\grant\Documents\github\hex"
	long_funcs = find_longest_functions(base_dir)

	with open('long_funcs_detailed.txt', 'w', encoding='utf-8') as f:
		for func in long_funcs[:20]: # Top 20
			f.write(f"File: {func['file']}\n")
			f.write(f"  Function: {func['name']}\n")
			f.write(f"  Length: {func['length']} lines\n")
			f.write(f"  Lines: {func['start']}-{func['end']}\n\n")

	print("Long functions report generated in long_funcs_detailed.txt")

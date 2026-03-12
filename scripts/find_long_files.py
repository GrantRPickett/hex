import os

def find_longest_files(directory, limit=20):
	files_list = []
	# Exclude these directories
	exclude_dirs = {'addons', 'scripts', '.git', '.godot', 'reports'}

	for root, dirs, files in os.walk(directory):
		# Filter out excluded directories
		dirs[:] = [d for d in dirs if d not in exclude_dirs]

		for file in files:
			if file.endswith('.gd'):
				path = os.path.join(root, file)
				try:
					with open(path, 'r', encoding='utf-8') as f:
						lines = f.readlines()
						files_list.append((path, len(lines)))
				except Exception:
					pass

	files_list.sort(key=lambda x: x[1], reverse=True)
	return files_list[:limit]

if __name__ == "__main__":
	longest_files = find_longest_files('.')
	with open('long_files_report.txt', 'w', encoding='utf-8') as f:
		f.write(f"{'Path':<80} | {'Lines':<10}\n")
		f.write("-" * 95 + "\n")
		for path, lines in longest_files:
			f.write(f"{path:<80} | {lines:<10}\n")
	print("Report written to long_files_report.txt")

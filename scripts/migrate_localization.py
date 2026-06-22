import re
import csv
import os

# Paths
INPUT_GD = "Resources/Localization/localization_strings.gd"
OUTPUT_CSV = "Resources/Localization/translations.csv"

def migrate():
	if not os.path.exists(INPUT_GD):
		print(f"Input file not found: {INPUT_GD}")
		return

	with open(INPUT_GD, "r", encoding="utf-8") as f:
		content = f.read()

	# Find the _STRINGS_BY_LANGUAGE dictionary
	# It's a complex regex because of nested dictionaries
	match = re.search(r"const _STRINGS_BY_LANGUAGE := \{(.*?)\n\}", content, re.DOTALL)
	if not match:
		print("Could not find _STRINGS_BY_LANGUAGE in the GDScript.")
		return

	dict_content = match.group(1)

	# Extract languages
	languages = re.findall(r'"([a-z]{2})": \{', dict_content)
	print(f"Found languages: {languages}")

	# For each language, extract its key-value pairs
	master_table = {} # key -> {lang -> value}

	for lang in languages:
		# Find the block for this language
		lang_match = re.search(rf'"{lang}": \{{(.*?)\n\t\}},', dict_content, re.DOTALL)
		if not lang_match:
			# Try without trailing comma for the last one
			lang_match = re.search(rf'"{lang}": \{{(.*?)\n\t\}}', dict_content, re.DOTALL)

		if lang_match:
			pairs = re.findall(r'"([^"]+)": "([^"]+)"', lang_match.group(1))
			for key, val in pairs:
				if key not in master_table:
					master_table[key] = {}
				master_table[key][lang] = val

	# Write to CSV
	os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)
	with open(OUTPUT_CSV, "w", encoding="utf-8", newline="") as f:
		writer = csv.writer(f)
		header = ["id"] + languages
		writer.writerow(header)

		# Sort keys for consistency
		for key in sorted(master_table.keys()):
			row = [key]
			for lang in languages:
				row.append(master_table[key].get(lang, ""))
			writer.writerow(row)

	print(f"Successfully migrated {len(master_table)} keys to {OUTPUT_CSV}")

if __name__ == "__main__":
	migrate()

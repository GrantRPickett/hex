import os
import re
import csv

def audit_dialogues():
    resources_dir = "Resources/level_data"
    dialogue_files = []
    referenced_dialogues = set()
    translation_ids = set()

    # 1. Find all .dialogue files
    for root, dirs, files in os.walk(resources_dir):
        for file in files:
            if file.endswith(".dialogue"):
                dialogue_files.append({
                    "full_path": os.path.join(root, file).replace("\\", "/"),
                    "name": os.path.splitext(file)[0]
                })

    # 2. Find references in the codebase
    ref_patterns = [
        re.compile(r'dialogue_id\s*=\s*&?"([^"]+)"'),
        re.compile(r'dialogue_resource\s*=\s*&?"([^"]+)"'),
        re.compile(r'"dialogue_id"\s*:\s*"([^"]+)"'),
        re.compile(r'"dialogue_resource"\s*:\s*"([^"]+)"'),
    ]

    for root, dirs, files in os.walk("."):
        if any(d in root for d in [".git", ".godot", "addons", "venv", "node_modules"]):
            continue
        for file in files:
            if file.endswith((".tres", ".json", ".gd", ".tscn")):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                        for pattern in ref_patterns:
                            matches = pattern.findall(content)
                            for m in matches:
                                ref = m.split("/")[-1].replace(".dialogue", "")
                                referenced_dialogues.add(ref)
                except Exception as e:
                    print(f"Error reading {path}: {e}")

    # 3. Load translation IDs
    trans_path = "Resources/Localization/translations.csv"
    if os.path.exists(trans_path):
        try:
            with open(trans_path, "r", encoding="utf-8") as f:
                reader = csv.reader(f)
                next(reader) # skip header
                for row in reader:
                    if row:
                        translation_ids.add(row[0])
        except Exception as e:
            print(f"Error reading translations: {e}")

    # 4. Report
    print("--- Dialogue Audit Report ---")
    
    # Orphan Check
    orphans = []
    for df in dialogue_files:
        if df["name"] not in referenced_dialogues:
            is_path_referenced = False
            for ref in referenced_dialogues:
                if ref in df["full_path"]:
                    is_path_referenced = True
                    break
            if not is_path_referenced:
                orphans.append(df["full_path"])

    if orphans:
        print(f"\n[!] Found {len(orphans)} potentially unused .dialogue files:")
        for o in orphans:
            print(f"  - {o}")
    else:
        print("\n[OK] No orphaned dialogue files found.")

    # Translation Check
    missing_ids = []
    total_lines = 0
    speech_pattern = re.compile(r'^\t*[^:]+:\s+.*')
    id_tag_pattern = re.compile(r'\[ID:(L[a-f0-9]{8})\]')

    for df in dialogue_files:
        try:
            with open(df["full_path"], "r", encoding="utf-8") as f:
                lines = f.readlines()
                for line_num, line in enumerate(lines, 1):
                    line = line.strip()
                    if speech_pattern.match(line):
                        total_lines += 1
                        match = id_tag_pattern.search(line)
                        if match:
                            trans_id = match.group(1)
                            if trans_id not in translation_ids:
                                missing_ids.append(f"{df['full_path']}:{line_num} - ID '{trans_id}' not in translations.csv")
                        else:
                            missing_ids.append(f"{df['full_path']}:{line_num} - Missing [ID:...] tag for speech line")
        except Exception as e:
            print(f"Error auditing content of {df['full_path']}: {e}")

    if missing_ids:
        print(f"\n[!] Found {len(missing_ids)} translation issues in {total_lines} speech lines:")
        # Limit output if there are too many
        for m in missing_ids[:20]:
            print(f"  - {m}")
        if len(missing_ids) > 20:
            print(f"  ... and {len(missing_ids) - 20} more.")
    else:
        print(f"\n[OK] All {total_lines} speech lines have valid translation IDs.")

    print(f"\nTotal .dialogue files: {len(dialogue_files)}")
    print(f"Total unique dialogue IDs referenced in codebase: {len(referenced_dialogues)}")

if __name__ == "__main__":
    audit_dialogues()

import os
import re

def check_uid_collisions(project_root):
    """
    Searches for .uid files in the given project root, extracts UIDs,
    and checks for any duplicate UIDs (collisions).
    Stores details of found UIDs and files where no UID was found,
    then reports collisions and provides a comprehensive summary.
    """
    uid_map = {}
    found_uids_list = []
    not_found_uids_list = []
    # Regex to find UIDs in various Godot formats: uid="xxxx", uid='xxxx', xxxx (raw alphanumeric), or uid://xxxx
    # Captures the UID itself in group 1.
    # Updated to include underscores in the alphanumeric part for Godot UIDs.
    pattern = re.compile(r'(?:uid=(?:["\'])|uid://)?([a-zA-Z0-9_]+)(?:["\'])?')
    
    for root, dirs, files in os.walk(project_root):
        # Prevent os.walk from descending into 'addons' directory
        if 'addons' in dirs:
            dirs.remove('addons')
        
        for file in files:
            if file.endswith('.uid'):
                file_path = os.path.join(root, file)
                relative_file_path = os.path.relpath(file_path, project_root)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        match = pattern.search(content)
                        if match:
                            uid = match.group(1) # Group 1 contains the actual UID
                            found_uids_list.append((uid, relative_file_path))
                            if uid not in uid_map:
                                uid_map[uid] = []
                            uid_map[uid].append(relative_file_path)
                        else:
                            # Not all .uid files (especially those from specific resource types or empty ones)
                            # explicitly contain a 'uid="xxxx"' or 'uid://xxxx' string within their file content.
                            not_found_uids_list.append(relative_file_path)
                except Exception as e:
                    # Capture read errors and add to not_found_uids_list for reporting
                    not_found_uids_list.append(f"{relative_file_path} (Error reading: {e})")

    collisions = {uid: paths for uid, paths in uid_map.items() if len(paths) > 1}

    if collisions:
        print("\n--- UID Collisions Found ---")
        for uid, paths in collisions.items():
            print(f"UID: {uid}")
            for path in paths:
                print(f"  - {path}")
        print("\nPlease investigate these collisions. Each UID in Godot projects should be unique to avoid resource conflicts.")
    else:
        print("\nNo UID collisions found. All UIDs are unique!")

    print(f"\n--- Summary ---")
    print(f"Total .uid files scanned (excluding 'addons'): {len(found_uids_list) + len(not_found_uids_list)}")
    print(f"UIDs successfully extracted: {len(found_uids_list)}")
    
    if found_uids_list:
        print(f"\n--- Found UIDs ---")
        # Sort by UID for easier readability
        for uid, path in sorted(found_uids_list, key=lambda x: x[0]):
            print(f"UID: {uid} | Path: {path}")

    if not_found_uids_list:
        print(f"\n--- Files where no UID pattern was found ---")
        # Sort for easier readability
        for path in sorted(not_found_uids_list):
            print(f"  - {path}")
    else:
        print("\nAll scanned .uid files contained a recognizable UID pattern.")

if __name__ == "__main__":
    current_directory = os.getcwd()
    print(f"Starting UID collision check in: {current_directory}")
    check_uid_collisions(current_directory)

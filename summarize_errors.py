import os
import re
from collections import Counter

reports_dir = r"c:\Users\grant\Documents\github\hex\reports"
error_patterns = [
    re.compile(r"SCRIPT ERROR: (.*)"),
    re.compile(r"ERROR: (.*)"),
    re.compile(r"at: (.*)"),
]

error_counts = Counter()
file_errors = {}

for filename in os.listdir(reports_dir):
    if filename.endswith(".log"):
        filepath = os.path.join(reports_dir, filename)
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            for line in lines:
                if "push_warning" in line or "resources still in use" in line:
                    continue
                for pattern in error_patterns:
                    match = pattern.search(line)
                    if match:
                        error_msg = match.group(0).strip()
                        if error_msg.startswith("at:") and "res://" not in error_msg:
                            continue
                        error_counts[error_msg] += 1
                        if filename not in file_errors:
                            file_errors[filename] = []
                        file_errors[filename].append(error_msg)

with open(r"c:\Users\grant\Documents\github\hex\error_summary.txt", "w", encoding='utf-8') as out:
    out.write("Top 50 Frequent Errors:\n")
    for err, count in error_counts.most_common(50):
        out.write(f"{count}: {err}\n")

    out.write("\nFiles with most errors:\n")
    file_err_counts = Counter({f: len(errs) for f, errs in file_errors.items()})
    for f, count in file_err_counts.most_common(20):
        out.write(f"{f}: {count}\n")


import os
import re

def find_longest_functions(directory):
    # Matches indented functions as well
    func_pattern = re.compile(r'^(\s*)func\s+([a-zA-Z0-9_]+)\s*\(', re.MULTILINE)
    exclude_dirs = {'addons', 'scripts', '.git', '.godot', 'reports'}
    results = []

    for root, dirs, files in os.walk(directory):
        # Filter out excluded directories
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        
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
                            indent = match.group(1)
                            name = match.group(2)
                            start_line = i + 1
                            functions.append({'name': name, 'start': start_line, 'indent': indent})

                    for i, func in enumerate(functions):
                        start_idx = func['start'] - 1
                        indent = func['indent']
                        
                        # Find end of function by looking for next line with same or less indentation
                        # and that isn't just whitespace or a comment.
                        end_line = len(lines)
                        for j in range(start_idx + 1, len(lines)):
                            line = lines[j]
                            if not line.strip() or line.strip().startswith('#'):
                                continue
                            
                            line_indent = line[:len(line) - len(line.lstrip())]
                            if len(line_indent) <= len(indent):
                                end_line = j # This line is outside the function
                                break
                        
                        # Trim trailing whitespace/comments from end_line
                        while end_line > func['start'] and (not lines[end_line-1].strip() or lines[end_line-1].strip().startswith('#')):
                            end_line -= 1
                            
                        length = end_line - func['start'] + 1
                        if length > 50: # Threshold for "long"
                            results.append({
                                'file': path,
                                'name': func['name'],
                                'length': length,
                                'start': func['start'],
                                'end': end_line
                            })
                except Exception as e:
                    print(f"Error reading {path}: {e}")

    # Sort by length descending
    results.sort(key=lambda x: x['length'], reverse=True)
    return results

if __name__ == "__main__":
    base_dir = "."
    long_funcs = find_longest_functions(base_dir)

    with open('long_funcs_detailed.txt', 'w', encoding='utf-8') as f:
        f.write(f"{'File':<60} | {'Function':<30} | {'Length':<10} | {'Lines':<15}\n")
        f.write("-" * 120 + "\n")
        for func in long_funcs[:30]: # Top 30
            f.write(f"{func['file']:<60} | {func['name']:<30} | {func['length']:<10} | {func['start']}-{func['end']}\n")

    print("Long functions report generated in long_funcs_detailed.txt")

import os
import re

def analyze_complexity(directory):
    # Matches indented functions
    func_pattern = re.compile(r'^(\s*)func\s+([a-zA-Z0-9_]+)\s*\(', re.MULTILINE)
    # Keywords that increase cyclomatic complexity
    complexity_keywords = [
        r'\bif\b', r'\belif\b', r'\bfor\b', r'\bwhile\b', r'\bmatch\b', 
        r'\bcase\b', r'\band\b', r'\bor\b', r'&&', r'\|\|'
    ]
    complexity_pattern = re.compile('|'.join(complexity_keywords))
    
    exclude_dirs = {'addons', 'scripts', '.git', '.godot', 'reports'}
    results = []

    for root, dirs, files in os.walk(directory):
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
                            indent_str = match.group(1)
                            # Convert tabs to 4 spaces for consistent depth calculation if needed
                            # but GDScript typically uses tabs or spaces consistently.
                            # We'll just count leading whitespace types.
                            indent_level = len(indent_str.replace('\t', '    ')) // 4
                            name = match.group(2)
                            start_line = i + 1
                            functions.append({
                                'name': name, 
                                'start': start_line, 
                                'base_indent': len(indent_str.replace('\t', '    '))
                            })

                    for i, func in enumerate(functions):
                        start_idx = func['start'] - 1
                        base_indent = func['base_indent']

                        # Find end of function
                        end_line = len(lines)
                        func_lines = []
                        max_depth = 0
                        complexity = 1 # Base complexity
                        
                        for j in range(start_idx + 1, len(lines)):
                            line = lines[j]
                            stripped = line.strip()
                            if not stripped or stripped.startswith('#'):
                                if j == start_idx + 1: # Header line
                                    continue
                                # Check if we reached the end by checking next non-empty line indent
                                continue

                            line_indent_str = line[:len(line) - len(line.lstrip())]
                            line_indent = len(line_indent_str.replace('\t', '    '))
                            
                            if line_indent <= base_indent:
                                end_line = j
                                break
                            
                            # Calculate depth relative to function start
                            depth = (line_indent - base_indent) // 4
                            if depth > max_depth:
                                max_depth = depth
                            
                            # Calculate complexity
                            complexity += len(complexity_pattern.findall(line))
                            
                            func_lines.append(line)
                            end_line = j + 1

                        results.append({
                            'file': path,
                            'name': func['name'],
                            'length': end_line - func['start'] + 1,
                            'complexity': complexity,
                            'max_depth': max_depth,
                            'start': func['start'],
                            'end': end_line
                        })
                except Exception as e:
                    print(f"Error reading {path}: {e}")

    return results

if __name__ == "__main__":
    base_dir = "."
    analysis = analyze_complexity(base_dir)

    # Sort by complexity descending
    analysis.sort(key=lambda x: x['complexity'], reverse=True)

    report_path = 'complexity_report.txt'
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(f"{'File':<50} | {'Function':<30} | {'Cmplx':<6} | {'Depth':<6} | {'Lines':<10}\n")
        f.write("-" * 115 + "\n")
        for item in analysis[:50]: # Top 50
            f.write(f"{item['file']:<50} | {item['name']:<30} | {item['complexity']:<6} | {item['max_depth']:<6} | {item['start']}-{item['end']}\n")

    print(f"Complexity report generated in {report_path}")
    
    # Generate Backlog Markdown
    backlog_dir = "backlog"
    if not os.path.exists(backlog_dir):
        os.makedirs(backlog_dir)
        
    backlog_path = os.path.join(backlog_dir, 'complexity_backlog.md')
    with open(backlog_path, 'w', encoding='utf-8') as f:
        f.write("# Refactoring Backlog (Complexity & Depth)\n\n")
        f.write("This file is auto-generated by `scripts/analyze_complexity.py`. It lists functions that exceed complexity or nesting thresholds.\n\n")
        
        f.write("## Top Refactoring Candidates\n\n")
        f.write("| File | Function | Complexity | Max Depth | Lines |\n")
        f.write("| :--- | :--- | :--- | :--- | :--- |\n")
        
        # Sort by complexity again for the table
        analysis.sort(key=lambda x: x['complexity'], reverse=True)
        for item in analysis[:30]: # Top 30 for backlog
            rel_path = os.path.relpath(item['file'], base_dir)
            f.write(f"| {rel_path} | `{item['name']}` | {item['complexity']} | {item['max_depth']} | {item['start']}-{item['end']} |\n")
            
        f.write("\n## Most Complex Files (Cumulative)\n\n")
        f.write("| Complexity | File |\n")
        f.write("| :--- | :--- |\n")
        
        file_complexity = {}
        for item in analysis:
            file_complexity[item['file']] = file_complexity.get(item['file'], 0) + item['complexity']
        
        sorted_files = sorted(file_complexity.items(), key=lambda x: x[1], reverse=True)
        for file, score in sorted_files[:15]:
            rel_path = os.path.relpath(file, base_dir)
            f.write(f"| {score} | {rel_path} |\n")

    print(f"Backlog markdown generated in {backlog_path}")
    
    # Also print summary of most complex files

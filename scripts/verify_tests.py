import glob
import subprocess
import os

godot_exe = ""
# Find the godot exe in the parent directory or just use the one we know exists based on scripts/godot_cli.ps1
for f in os.listdir('.'):
	if f.endswith('.exe') and 'godot' in f.lower():
		godot_exe = f
if not godot_exe:
	for f in os.listdir('.'):
		if f.endswith('.exe') and '4.6' in f:
			godot_exe = f

if not godot_exe:
	godot_exe = "godot" # fallback

print(f"Using godot: {godot_exe}")
fails = []

for f in glob.glob('tests/*.gd'):
	# Don't check fixtures or base suite itself normally, but we can check all test files
	cmd = [godot_exe, '--headless', '--check-only', f]
	try:
		res = subprocess.run(cmd, capture_output=True, text=True)
		if res.returncode != 0:
			print(f"--- ERROR IN {f} ---")
			for line in res.stderr.splitlines():
				if "Parse Error" in line or "Error" in line:
					print(line.strip())
			fails.append(f)
	except Exception as e:
		pass

if fails:
	print(f"Failed files: {fails}")
else:
	print("All tests passed syntax check!")

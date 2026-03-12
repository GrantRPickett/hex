import glob
import re

count = 0
for f in glob.glob('tests/*.gd'):
	if 'base_test_suite.gd' in f or 'test_helpers.gd' in f:
		continue
	with open(f, 'r', encoding='utf-8') as file:
		content = file.read()

	if 'HexTestUtils.' in content and 'const HexTestUtils' not in content:
		# insert right after extends GdUnitTestSuite
		content = re.sub(r'(extends GdUnitTestSuite\s*\n)', r'\g<1>const HexTestUtils = preload("res://tests/base_test_suite.gd")\n', content, count=1)
		with open(f, 'w', encoding='utf-8') as file:
			file.write(content)
		count += 1
		print(f"Injected in {f}")

print(f"Total injected: {count}")

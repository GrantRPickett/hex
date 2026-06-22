import csv
import io

# Mapping of common broken UTF-8 sequences (viewed as Latin-1) back to UTF-8
fixes = {
	"Ã³": "ó",
	"Ã­": "í",
	"Ã±": "ñ",
	"Ã": "Ó",
	"Ã¡": "á",
	"Ã©": "é",
	"Ã": "Ú",
	"Ãº": "ú",
	"Ã": "Í",
	"Â¡": "¡",
	"Â¿": "¿",
	"Ã": "É",
}

def fix_text(text):
	for broken, fixed in fixes.items():
		text = text.replace(broken, fixed)
	return text

# Basic Japanese translations for common terms
ja_map = {
	"Convince": "説得",
	"Move & Explore": "移動・探索",
	"Move & Gather": "移動・収集",
	"Defeat": "敗北",
	"Victory": "勝利",
	"Attack": "攻撃",
	"Back": "戻る",
	"Yes": "はい",
	"No": "いいえ",
	"Enemy": "敵",
	"Neutral": "中立",
	"Player": "プレイヤー",
	"Pause": "一時停止",
	"Continue": "続く",
	"Play": "プレイ",
	"Quit": "終了",
	"Settings": "設定",
	"Language": "言語",
	"English": "英語",
	"Spanish": "スペイン語",
	"Japanese": "日本語",
	"Music": "音楽",
	"SFX": "効果音",
	"Mute": "ミュート",
	"Normal": "通常",
	"Fast": "高速",
	"Skip": "スキップ",
	"Round": "ラウンド",
	"Turn": "ターン",
	"Status": "状態",
	"Terrain": "地形",
	"Wait": "待機",
	"End Turn": "ターン終了",
	"Journal": "ジャーナル",
	"Objectives": "目標",
	"Rules": "ルール",
	"Achievements": "実績",
	"Completed": "完了",
	"In Progress": "進行中",
	"Unknown": "不明",
	"Description": "説明",
	"Name": "名前",
	"Select": "選択",
	"Confirm": "確定",
	"Cancel": "キャンセル",
	"Save": "保存",
	"Load": "ロード",
}

def get_ja(en_text):
	# Simple heuristic for common terms
	for key, val in ja_map.items():
		if key.lower() in en_text.lower():
			return val
	return ""

input_path = "Resources/Localization/translations.csv"
output_path = "Resources/Localization/translations.csv"

with open(input_path, 'r', encoding='utf-8') as f:
	lines = f.readlines()

header = lines[0].strip().split(',')
if 'ja' not in header:
	header.append('ja')

new_rows = [header]
for line in lines[1:]:
	# Simple split since it's a basic CSV, but handle quotes if necessary
	# For now, let's use csv module to be safe
	pass

# Re-reading with CSV module
output = io.StringIO()
reader = csv.reader(lines)
next(reader) # skip header

writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)
writer.writerow(header)

for row in reader:
	if len(row) < 2: continue

	# Fix Spanish
	if len(row) > 2:
		row[2] = fix_text(row[2])

	# Add Japanese
	en_text = row[1]
	ja_text = get_ja(en_text)

	if len(row) == 2:
		row.append("") # es

	if len(row) == 3:
		row.append(ja_text)
	else:
		row[3] = ja_text

	writer.writerow(row)

with open(output_path, 'w', encoding='utf-8', newline='') as f:
	f.write(output.getvalue())

print("Updated translations.csv with Japanese column and fixed Spanish encoding.")

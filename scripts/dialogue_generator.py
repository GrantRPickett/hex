import os
import logging
import hashlib
import csv
from conversion_utils import slugify as _slugify

logger = logging.getLogger(__name__)

class DialogueGenerator:
	def __init__(self, project_root, default_output_base_dir, paths_helper, fs_path_func):
		self.project_root = project_root
		self.default_output_base_dir = default_output_base_dir
		self.paths_helper = paths_helper
		self.fs_path = fs_path_func
		self._translation_buffer = {}

	def generate_dialogue_line_id(self, level_id: str, entry_id: str, line_index: int) -> str:
		"""Generates a stable, unique ID for a dialogue line."""
		seed = f"{level_id}_{entry_id}_{line_index}"
		return hashlib.md5(seed.encode()).hexdigest()[:8]

	def register_translation(self, key: str, text: str):
		"""Registers or updates a translation key in the global buffer."""
		if not key or not text:
			return
		self._translation_buffer[key] = text

	def flush_translations(self):
		"""Writes all buffered translations to translations.csv in one pass."""
		if not self._translation_buffer:
			return

		csv_res_path = self.paths_helper.get_path("directories.localization") + "translations.csv" if self.paths_helper.get_path("directories.localization") else "res://Resources/Localization/translations.csv"
		csv_path = self.fs_path(csv_res_path)
		if not os.path.exists(csv_path):
			logger.warning(f"translations.csv not found at {csv_path}. Skipping flush.")
			return

		rows = []
		header = []
		found_keys = set()
		updated_count = 0

		try:
			with open(csv_path, 'r', encoding='utf-8') as f:
				reader = csv.reader(f)
				header = next(reader)
				for row in reader:
					if row:
						key = row[0]
						if key in self._translation_buffer:
							new_text = self._translation_buffer[key]
							if len(row) > 1 and row[1] != new_text:
								row[1] = new_text
								updated_count += 1
							found_keys.add(key)
						rows.append(row)
		except Exception as e:
			logger.error(f"Failed to read translations.csv during flush: {e}")
			return

		# Add new keys
		for key, text in self._translation_buffer.items():
			if key not in found_keys:
				new_row = [key, text] + ([""] * (len(header) - 2))
				rows.append(new_row)
				updated_count += 1

		if updated_count > 0:
			try:
				with open(csv_path, 'w', encoding='utf-8', newline='') as f:
					writer = csv.writer(f)
					writer.writerow(header)
					writer.writerows(rows)
				logger.info(f"Flushed translations: {updated_count} updates/new entries.")
			except Exception as e:
				logger.error(f"Failed to write translations.csv during flush: {e}")
		
		self._translation_buffer.clear()

	def ensure_dialogue_file_exists(self, level_id: str, dialogue_entry_id: str, title: str = "", description: str = "", template_type: str = "DEFAULT", next_info: str = "", metadata: dict = None) -> str:
		level_slug = _slugify(level_id)
		entry_slug = _slugify(dialogue_entry_id)

		dialogues_base_dir_res = f"{self.default_output_base_dir}/{level_slug}/dialogues"
		dialogues_base_dir_fs = self.fs_path(dialogues_base_dir_res)

		new_filename = f"{level_slug}_{entry_slug}.dialogue"
		new_resource_path = f"{dialogues_base_dir_res}/{new_filename}"
		new_local_path = f"{dialogues_base_dir_fs}/{new_filename}"

		if not os.path.exists(new_local_path):
			os.makedirs(os.path.dirname(new_local_path), exist_ok=True)

			def _line(speaker: str, text: str, index: int) -> str:
				line_id = f"L{self.generate_dialogue_line_id(level_id, dialogue_entry_id, index)}"
				self.register_translation(line_id, f"{speaker}: {text}")
				return f"{speaker}: {text} [ID:{line_id}]"

			# Determine speakers
			primary_speaker = "{{initiator_name}}"
			secondary_speaker = "{{partner_name}}"
			is_single_speaker = False
			
			if metadata:
				if metadata.get("is_loot"):
					is_single_speaker = True
				elif metadata.get("is_location"):
					if metadata.get("inhabited"):
						loc_name = metadata.get("location_name") or "the area"
						secondary_speaker = f"Person of {loc_name}"
					else:
						is_single_speaker = True
				# Target-specific unit (stretch)
				elif metadata.get("target_id") and metadata.get("target_kind") == "unit":
					secondary_speaker = metadata.get("target_id")
				# Stage-specific partner fallback
				elif metadata.get("partner_name"):
					secondary_speaker = metadata.get("partner_name")

			# Templates mapping
			default_next = next_info if next_info else "the next area"
			default_title = title if title else dialogue_entry_id
			default_desc = description if description else f"Pending narrative description for {dialogue_entry_id}..."

			header_lines = [
				f"{_line(primary_speaker, '[Title: ' + default_title + ']', 0)}",
				f"{_line(primary_speaker, '[Narrative Goal: ' + default_desc + ']', 1)}",
			]
			
			meta_lines = []
			if metadata:
				for k in ["task_id", "stage_id", "journal_id"]:
					if metadata.get(k):
						label = k.split("_")[0].capitalize()
						val = metadata[k]
						content = f"[{label}: {val}]"
						meta_lines.append(_line(primary_speaker, content, len(header_lines) + len(meta_lines)))

			body_lines = []
			if template_type == "STAGE_EXIT_TERMINAL":
				body_lines = [
					"if is_victory",
					f"\t{_line(primary_speaker, 'The mission was a success! The objective is secure.', len(header_lines) + len(meta_lines) + 0)}",
					f"\t{_line(secondary_speaker, 'You have done a great service today.', len(header_lines) + len(meta_lines) + 1)}",
					"else",
					f"\t{_line(primary_speaker, 'We have failed. The objective was lost.', len(header_lines) + len(meta_lines) + 2)}",
					f"\t{_line(secondary_speaker, 'Retreat and regroup! We will find another way.', len(header_lines) + len(meta_lines) + 3)}",
					"=> END"
				]
			elif template_type == "STAGE_EXIT_TRANSITION":
				body_lines = [
					f"{_line(primary_speaker, 'We have finished our work here for now.', len(header_lines) + len(meta_lines) + 0)}",
					f"{_line(primary_speaker, 'We must move on to our next objective: ' + default_next + '.', len(header_lines) + len(meta_lines) + 1)}",
					"=> END"
				]
			else: # DEFAULT
				body_lines = [
					f"{_line(primary_speaker, 'This is a placeholder for ' + dialogue_entry_id + '.', len(header_lines) + len(meta_lines) + 0)}"
				]
				if not is_single_speaker:
					body_lines.append(f"{_line(secondary_speaker, 'Indeed it is.', len(header_lines) + len(meta_lines) + 1)}")
				
				body_lines.append("=> END")

			all_lines = header_lines + meta_lines + body_lines
			
			# We include the specific entry ID as a label so DialogueActionService can find it,
			# and 'start' as a standard fallback.
			content = f"~ {dialogue_entry_id}\n"
			content += f"~ start\n"
			content += "\n".join(all_lines) + "\n"

			try:
				with open(new_local_path, "w", encoding="utf-8") as f:
					f.write(content)
				logger.info(f"Created placeholder dialogue file ({template_type}): {new_resource_path}")
			except IOError as e:
				logger.error(f"Failed to create placeholder dialogue file {new_resource_path}: {e}")

		return new_resource_path

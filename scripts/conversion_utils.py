import hashlib
import os
import re

def fs_path(res_path: str, project_root: str) -> str:
	"""Safely converts a res:// path to an absolute OS filesystem path."""
	if res_path.startswith("res://"):
		return os.path.join(project_root, res_path[6:]).replace(os.sep, '/')
	elif res_path.startswith("./"):
		return os.path.join(project_root, res_path[2:]).replace(os.sep, '/')
	return os.path.abspath(res_path).replace(os.sep, '/')

def generate_deterministic_uid(seed_string: str) -> str:
	"""Generates a stable UID string from a seed string."""
	hash_obj = hashlib.md5(seed_string.encode('utf-8'))
	return f"uid://{hash_obj.hexdigest()[:12]}"

def slugify(text: str) -> str:
	"""Converts a string to a filesystem-friendly slug."""
	text = text.lower()
	text = re.sub(r'[^a-z0-9_]', '_', text)
	return re.sub(r'_+', '_', text).strip('_')

def copy_props(target: dict, data: dict, keys: list, type_map: dict = None) -> None:
	"""
	Utility to copy keys from data to target.
	If type_map is provided, keys in it will be formatted (e.g., StringName with &").
	"""
	if type_map is None:
		type_map = {}
	for k in keys:
		if k in data:
			val = data[k]
			if k in type_map and type_map[k] == "StringName":
				target[k] = f'&"{val}"'
			else:
				target[k] = val

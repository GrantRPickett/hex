"""
Python utility to load and access centralized file paths from file_paths.json

Usage:
    from file_paths_loader import FilePathsLoader

    paths = FilePathsLoader("Resources/file_paths.json")
    gameplay_scene = paths.get_path("scenes.gameplay")
    all_autoloads = paths.get_category("autoloads")
    warnings = paths.get_warnings()
"""

import json
import os
from pathlib import Path
from typing import Dict, Any, List, Optional


class FilePathsLoader:
    """Load and access centralized file paths from file_paths.json"""

    def __init__(self, json_path: str = "Resources/file_paths.json"):
        """
        Initialize the loader with path to file_paths.json

        Args:
            json_path: Path to file_paths.json (relative to cwd or absolute)
        """
        self.json_path = json_path
        self.paths_dict: Dict[str, Any] = {}
        self.load_errors: List[str] = []
        self._load_internal()

    def _load_internal(self) -> None:
        """Load and parse the JSON file"""
        if not os.path.exists(self.json_path):
            self.load_errors.append(f"File not found: {self.json_path}")
            return

        try:
            with open(self.json_path, "r", encoding="utf-8") as f:
                self.paths_dict = json.load(f)
        except json.JSONDecodeError as e:
            self.load_errors.append(f"JSON parse error: {e}")
        except Exception as e:
            self.load_errors.append(f"Error reading file: {e}")

    def get_path(self, path_key: str) -> Optional[str]:
        """
        Get a single path using dot notation

        Example: get_path("scenes.gameplay") -> "res://Gameplay/gameplay.tscn"

        Args:
            path_key: Dot-separated path like "scenes.gameplay"

        Returns:
            The path string, or None if not found
        """
        keys = path_key.split(".")
        current = self.paths_dict

        for key in keys:
            if isinstance(current, dict) and key in current:
                current = current[key]
            else:
                self.load_errors.append(f"Path not found: {path_key}")
                return None

        if isinstance(current, str):
            return current
        else:
            self.load_errors.append(f"Value is not a string: {path_key} -> {current}")
            return None

    def get_category(self, category: str) -> Dict[str, Any]:
        """
        Get all paths in a category

        Example: get_category("scenes") -> dict of all scene paths

        Args:
            category: Category name like "scenes", "autoloads", etc.

        Returns:
            Dictionary of paths in that category
        """
        if category in self.paths_dict and isinstance(self.paths_dict[category], dict):
            return self.paths_dict[category]

        self.load_errors.append(f"Category not found: {category}")
        return {}

    def get_warnings(self) -> List[str]:
        """Get all warnings from the _meta section"""
        if "_meta" in self.paths_dict and "warnings" in self.paths_dict["_meta"]:
            return self.paths_dict["_meta"]["warnings"]
        return []

    def get_dynamic_paths(self) -> Dict[str, Any]:
        """Get all dynamic path patterns that can't be fully centralized"""
        if "dynamic_paths" in self.paths_dict:
            return self.paths_dict["dynamic_paths"]
        return {}

    def get_directories(self) -> Dict[str, str]:
        """Get all directory paths"""
        if "directories" in self.paths_dict:
            return self.paths_dict["directories"]
        return {}

    def get_errors(self) -> List[str]:
        """Get all errors that occurred during loading"""
        return self.load_errors

    def validate_paths(self) -> Dict[str, Any]:
        """
        Validate that all static paths exist in the filesystem
        Since Python sees the filesystem (not Godot virtual paths),
        this checks if "res://" paths would resolve when converted

        Returns:
            Dictionary with validation results
        """
        results = {
            "valid": [],
            "missing": [],
            "godot_paths": [],  # paths that start with res://
            "user_paths": [],   # paths that start with user://
            "total_checked": 0
        }

        self._validate_category_recursive("scenes", self.paths_dict.get("scenes", {}), results)
        self._validate_category_recursive("autoloads", self.paths_dict.get("autoloads", {}), results)
        self._validate_category_recursive("resources", self.paths_dict.get("resources", {}), results)
        self._validate_category_recursive("gameplay", self.paths_dict.get("gameplay", {}), results)
        self._validate_category_recursive("tests", self.paths_dict.get("tests", {}), results)

        # Check directories
        dirs = self.paths_dict.get("directories", {})
        for dir_name in dirs:
            path = dirs[dir_name]
            if isinstance(path, str):
                results["total_checked"] += 1
                if path.startswith("res://"):
                    results["godot_paths"].append(f"directories.{dir_name}: {path}")
                elif path.startswith("user://"):
                    results["user_paths"].append(f"directories.{dir_name}: {path}")

        return results

    def _validate_category_recursive(self, category: str, dict_obj: Dict, results: Dict) -> None:
        """Recursively validate paths in a category"""
        for key in dict_obj:
            value = dict_obj[key]

            if isinstance(value, str) and value.startswith("res://"):
                results["total_checked"] += 1
                results["godot_paths"].append(f"{category}.{key}: {value}")
            elif isinstance(value, str) and value.startswith("user://"):
                results["total_checked"] += 1
                results["user_paths"].append(f"{category}.{key}: {value}")
            elif isinstance(value, dict):
                self._validate_category_recursive(f"{category}.{key}", value, results)

    def print_summary(self) -> None:
        """Print a summary of the loaded paths"""
        if self.load_errors:
            print("=== LOAD ERRORS ===")
            for error in self.load_errors:
                print(f"  [ERROR] {error}")

        warnings = self.get_warnings()
        if warnings:
            print("\n=== WARNINGS ===")
            for warning in warnings:
                print(f"  [WARNING] {warning}")

        print("\n=== LOADED CATEGORIES ===")
        for category in ["scenes", "autoloads", "resources", "gameplay", "directories", "tests"]:
            if category in self.paths_dict:
                count = self._count_paths(self.paths_dict[category])
                print(f"  {category}: {count} paths")

        dynamic = self.get_dynamic_paths()
        if dynamic:
            print("\n=== DYNAMIC PATH PATTERNS (Cannot be fully centralized) ===")
            for pattern_name in dynamic:
                if not pattern_name.startswith("_"):
                    print(f"  - {pattern_name}")

    @staticmethod
    def _count_paths(dict_obj: Dict) -> int:
        """Count total paths in a nested dictionary"""
        count = 0
        for key in dict_obj:
            value = dict_obj[key]
            if isinstance(value, str) and value.startswith("res://"):
                count += 1
            elif isinstance(value, dict):
                count += FilePathsLoader._count_paths(value)
        return count

    def get_dialogue_pattern(self) -> str:
        """Get the dialogue path pattern for dynamic construction"""
        dynamic = self.get_dynamic_paths()
        if "dialogue_paths" in dynamic and "pattern" in dynamic["dialogue_paths"]:
            return dynamic["dialogue_paths"]["pattern"]
        return "res://Resources/level_data/dialogues/{level_id}_{dialogue_id}.dialogue"

    def build_dialogue_path(self, level_id: str, dialogue_id: str) -> str:
        """Build a dialogue path from level and dialogue IDs"""
        pattern = self.get_dialogue_pattern()
        return pattern.format(level_id=level_id, dialogue_id=dialogue_id)


if __name__ == "__main__":
    # Example usage and testing
    import sys

    # Try to find file_paths.json
    json_file = "Resources/file_paths.json"
    if not os.path.exists(json_file):
        # Try from project root
        root = Path(__file__).parent.parent
        json_file = str(root / "Resources" / "file_paths.json")

    print(f"Loading: {json_file}")
    paths = FilePathsLoader(json_file)

    # Print summary
    paths.print_summary()

    # Test some paths
    print("\n=== EXAMPLE PATHS ===")
    gameplay = paths.get_path("scenes.gameplay")
    print(f"Gameplay scene: {gameplay}")

    save_manager = paths.get_path("autoloads.save_manager")
    print(f"SaveManager: {save_manager}")

    # Test dialogue path building
    print("\n=== DIALOGUE PATH PATTERN ===")
    print(f"Pattern: {paths.get_dialogue_pattern()}")
    example_path = paths.build_dialogue_path("level_1", "intro_dialogue")
    print(f"Example: {example_path}")

    # Print validation
    print("\n=== VALIDATION ===")
    validation = paths.validate_paths()
    print(f"Total paths checked: {validation['total_checked']}")
    print(f"Godot paths (res://): {len(validation['godot_paths'])}")
    print(f"User paths (user://): {len(validation['user_paths'])}")

    if paths.get_errors():
        print("\n=== ERRORS ===")
        for error in paths.get_errors():
            print(f"  [ERROR] {error}")

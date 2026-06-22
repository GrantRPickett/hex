## 1. Preparation
- [ ] 1.1 Create migration script to convert `localization_strings.gd` to `translations.csv`
- [ ] 1.2 Export current English and Spanish strings to `Resources/Localization/translations.csv`

## 2. Generator Updates
- [ ] 2.1 Update `json_to_tres.py` to generate stable Line IDs for dialogue lines
- [ ] 2.2 Implement Line ID hashing based on level ID and line content
- [ ] 2.3 Update `json_to_tres.py` to append new lines to `translations.csv` if they don't exist

## 3. Integration
- [ ] 3.1 Update `DialogueActionService.gd` to rely on Godot's native translation server
- [ ] 3.2 Update `localization_strings.gd` to be a thin wrapper around `tr()` or remove if possible
- [ ] 3.3 Update Settings UI to use `TranslationServer` for locale switching

## 4. Validation
- [ ] 4.1 Re-generate `quest_competition` and verify Line IDs in `.dialogue` files
- [ ] 4.2 Verify translations display correctly in-game after switching locale

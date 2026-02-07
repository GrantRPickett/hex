# Change: Add Journal Feature

## Why
The game needs a way for players to keep track of important information they discover, such as lore, character details, and game rules. A journal will provide a centralized place for this information, improving the player experience.

## What Changes
- A new journal system will be added to the game.
- The journal will be organized into sections (e.g., People, Places, Rules).
- Journal entries can be unlocked through gameplay, such as completing quests or interacting with characters.
- Unlocked journal entries will be persisted in the save file.
- A new UI will be created to view the journal.

## Impact
- **Affected specs:** A new `journal` capability will be created.
- **Affected code:**
	- A new `JournalManager` autoload will be created.
	- The `SaveManager` will be modified to handle journal data.
	- UI scenes for the journal will be created.
	- Scripts that trigger journal unlocks will be modified (e.g., dialogue scripts).

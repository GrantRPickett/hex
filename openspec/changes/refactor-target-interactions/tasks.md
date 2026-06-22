# Tasks for Refactor Target Interactions

- [ ] **Location Interactions (Visit/Explore)**: Implement logic to show "visit" for locations without tasks (unopposed) and "explore" for locations with tasks (opposed). Consolidate the interaction handler to trigger the appropriate flow and reward (info/loot).
- [ ] **Interaction Command Routing**: Update target-based commands (loot/trapped, visit/explore, fight/attack, convince) and the move-and-interact executor so they all call TargetInteractionHandler.interact, ensuring opposed/unopposed handling stays centralized.
- [ ] **Item Interactions (Loot/Trapped)**: Refactor item interaction handling. Reveal the "loot" action for safe items (unopposed) and "trapped" action for items with opposed tasks.
- [ ] **Faction-Aware Task Refactoring**: Add faction parameters to tasks. Update level building to filter tasks per team, ensuring AI can symmetrically evaluate and perform their faction's tasks.
- [ ] **Unit Interaction Skeleton**: Refactor unit-to-unit interactions. Disable same-faction interaction. Enable "fight" (opposed) against open enemies. Enable "convince" (unopposed) against unloyal neutrals, and "fight" against enemy-loyal neutrals.
- [ ] **Neutral Unit Willpower Rules**: Update neutral unit state logic. Trigger loyalty set at half willpower (locks in once). Force retreat and drop loot at 0 willpower. Grant remaining loot at level end if willpower > 0.
- [ ] **Difficulty Loot Modifiers**: Introduce difficulty-based logic for enemy/neutral loot drops when standard routing logic concludes. Map Easy/Mid/Hard settings to the new loot inclusion rules.
- [ ] **Action Panel UI Update**: Update the player action UI to display these discrete actions ("loot", "trapped", "visit", "explore", "fight", "convince") instead of generic actions, leveraging the new interaction evaluation logic.
- [ ] **AI Symmetrical Logic**: Ensure the AI Action Manager and AI Controllers can accurately weigh and execute "convince" on neutrals, and prioritize faction-specific tasks, matching the player's new action palette.
- [ ] **Stage Location Spawns**: Update the level/stage loader so each stage instantiates and registers its location_spawns on activation (and removes them on exit) to keep visit/explore tasks scoped correctly.


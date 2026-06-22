## 1. Specification & Design

- [x] 1.1 Review current Task/Reward/Death logic (Completed)
- [x] 1.2 Draft Proposal and Design documents (Completed)
- [ ] 1.3 Draft Spec Deltas for Quests and Loot
- [ ] 1.4 Validate Proposal via `openspec validate`

## 2. Infrastructure Updates

- [ ] 2.1 Update `UnitDeathHandler.gd` to drop `quest` items regardless of difficulty
- [ ] 2.2 Update `TaskController.gd` to grant `TaskReward` mid-level to `actor` unit
- [ ] 2.3 Update `Task.gd` to correctly attribute duration/survival wins
- [ ] 2.4 Update `Task.gd` to handle `TaskReward` resource during completion

## 3. Level & Rule Verification

- [ ] 3.1 Create `quest_competition.json` with Stage A competition and Stage B survival
- [ ] 3.2 Add "Retrieve Item from Defeated Unit" task validation in `LevelRowValidator.gd`
- [ ] 3.3 Verify Stage A winner gets the item and Stage B correctly identifies the owner
- [ ] 3.4 Verify "Eliminate All" vs "Survival 5 Turns" OR logic in the level flow

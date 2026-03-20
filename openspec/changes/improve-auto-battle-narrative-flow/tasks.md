## 1. Setup & Context
- [ ] 1.1 Add `auto_battle_active` to `GameConstants.ContextKeys`
- [ ] 1.2 Update `GameCommandContext` to store and expose `auto_battle_active`
- [ ] 1.3 Update `InputCommandRouter` or `GameSession` to populate the flag from `ActionsPanel` or `HUDController` state

## 2. Interaction Log UI
- [ ] 2.1 Create `InteractionLogPanel.tscn` (Right-side, fixed width, scrollable container)
- [ ] 2.2 Implement `InteractionLogPanel.gd`
    - Display most recent 3 entries clearly
    - Scrollable history on hover
    - RichTextLabel for formatted logs
- [ ] 2.3 Integrate `InteractionLogPanel` into `HUDComponentFactory`

## 3. Narrative & Logging Logic
- [ ] 3.1 Update `TriggerDialogueCommand` to always append to `InteractionLogPanel`
    - Check `context.auto_battle_active` to decide whether to also show/skip the dialogue balloon
- [ ] 3.2 Update `HUDController` action/bark handlers to always log to `InteractionLogPanel`
    - Suppress combat barks/popups ONLY when in auto-battle mode

## 4. Verification
- [ ] 4.1 Write GdUnit4 test for dialogue suppression in auto-battle mode
- [ ] 4.2 Verify UI layout and hover-scrolling in-game

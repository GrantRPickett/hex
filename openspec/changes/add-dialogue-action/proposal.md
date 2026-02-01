## Why
- Gameplay request to add a dialogic-powered "talk" interaction between adjacent units.
- Need to temporarily hide HUD and present a VN-style textbox until the conversation ends.
- Dialogues must only run once per level and respect per-dialogue seen flags.

## What Changes
- Introduce level-authored dialogue triggers describing which units can start which Dialogic timeline.
- Add a dialogue action provider that exposes a "Talk" action when the initiator stands next to an eligible partner.
- Wire Dialogic to the gameplay scene, hide HUD during playback, and restore it after the timeline finishes while tracking completion flags.

## Impact
- Adds Dialogic autoload/plugin to the project configuration.
- Gameplay HUD/command stack gains awareness of story mode state to disable regular inputs while dialogue is active.
- Tests must cover dialogue availability logic and flag persistence.

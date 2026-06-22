# OpenSpec: Decoupled Audio Triggering System

## Goal
Implement a centralized, decoupled audio triggering system that uses the existing `EventBus` to play sound effects (SFX) for various game events (combat, UI, environmental). Initially, it will use empty placeholders.

## Architecture
The system will consist of:
1.  **EventBus Expansion**: New signals for audio-specific needs if current ones are insufficient.
2.  **AudioManager (Autoload)**: A central manager that:
	*   Connects to `EventBus` signals.
	*   Maps game events to sound resources (initially placeholders).
	*   Manages a pool of `AudioStreamPlayer` nodes for concurrent SFX playback.
	*   Interfaces with `AudioBusController` for bus routing (e.g., "SFX" bus).

## Decoupling Strategy
*   **Producers**: Gameplay and UI components emit signals via `EventBus`. They do NOT know about `AudioManager` or specific sound files.
*   **Consumer**: `AudioManager` listens to `EventBus` and decides what sound to play based on the event data.

## Implementation Steps
### 1. EventBus Updates
Ensure `EventBus` has signals for all major events that need audio:
*   `unit_attacked` (Existing)
*   `unit_damaged` (Existing)
*   `unit_died` (Existing)
*   `turn_changed` (Existing)
*   `ui_button_pressed` (New)
*   `ui_hover_triggered` (New)
*   `audio_trigger_requested(sound_id: String)` (New, for manual triggers)

### 2. AudioManager Autoload
*   Create `Autoloads/audio_manager.gd`.
*   Connect to `EventBus` signals in `_ready()`.
*   Maintain a dictionary mapping signals/events to dummy sound logic.
*   Function `play_sfx(sound_id: String)` to handle actual playback.

### 3. Integration Examples
*   Connect UI buttons to emit `EventBus.ui_button_pressed`.
*   Trigger `audio_trigger_requested` in specific gameplay commands if no specific signal exists.

## Success Criteria
*   Logs confirm `AudioManager` is receiving events from `EventBus`.
*   No direct references to sound files in gameplay logic.
*   Easily extensible to actual sound files later.

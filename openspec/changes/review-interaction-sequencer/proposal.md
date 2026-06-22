# Review Interaction Sequencer Dequeuing

## Problem Statement

The batch animation buffer idea is causing problems with the interaction sequencer. We need to ensure that the sequencer properly handles dequeuing all queued animations, sound effects, and other "juice" elements before updating the underlying action, reaction, willpower, and task states, regardless of settings that might skip parts of the process.

## Goals

- Review the InteractionSequencer to identify potential issues with dequeuing
- Ensure all queued effects are processed before state updates
- Make the system robust against settings that skip animations or delays
- Implement proactive settings checking to avoid unnecessary queuing
- Create a checklist for thorough review

## Scope

- Focus on `Gameplay/interaction/interaction_sequencer.gd`
- Review integration with animation service, dialogue service, HUD controller
- Check batch mode handling and skipping logic
- Ensure proper awaiting of completion signals

## Success Criteria

- All queued animations and effects are dequeued before state updates
- System works correctly in batch mode and normal mode
- No hanging or incomplete resolutions
- Proper handling of timeouts and error cases

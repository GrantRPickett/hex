# Interaction Sequencer

## Overview

The Interaction Sequencer orchestrates the high-level cinematic resolution of actions (Move + Interact), ensuring all visual effects, animations, sound effects, and narrative elements are properly sequenced and completed before updating underlying game state. This ensures that juice effects are fully resolved before the next unit's turn begins in a round-based system where each unit gets up to 1 full move, 1 action, and 1 reaction per round.

## Requirements

### MODIFIED Requirements

#### Sequencing Guarantee

The sequencer MUST ensure all queued animations, sound effects, and visual effects ("juice") are fully dequeued and completed before updating action, reaction, willpower, and task states.

##### Scenario: Batch Mode Resolution

Given the sequencer is in batch mode
When resolving multiple interactions
Then all effects must be queued and completed before any state updates occur

##### Scenario: Skip Settings

Given animation skipping is enabled
When resolving interactions
Then effects must still be queued and dequeued properly, even if not visually displayed

#### Queue Management

The sequencer MUST check settings proactively and only queue effects when they will actually be processed, avoiding unnecessary resource usage.

##### Scenario: Proactive Settings Check

Given settings that would skip animations or reduce motion
When resolving interactions
Then effects should not be queued at all, avoiding unnecessary processing

##### Scenario: Concurrent Interactions

Given multiple interactions are triggered simultaneously
When batch processing is active
Then each interaction's effects must be fully resolved before proceeding to the next

##### Scenario: Timeout Handling

Given an effect takes longer than expected
When timeout occurs
Then the sequencer must continue without hanging, ensuring state updates proceed

#### State Update Timing

Mechanical effects (damage, attribute changes) MUST be applied before juice effects begin, and juice effects MUST complete before final state updates.

##### Scenario: Combat Resolution

Given a successful attack interaction
When resolving the sequence
Then damage is applied first, then animations play, then willpower/tasks update

#### Error Resilience

The sequencer MUST handle invalid instances, missing services, and signal failures gracefully without breaking the resolution flow.

##### Scenario: Missing Service

Given the animation service is unavailable
When resolving an interaction
Then the sequencer continues with available services and logs the issue

## 1. Research
- [x] 1.1 Study `InputHandler`, `CameraHandler`, `InputController`, `PrimaryActionCommand` - COMPLETED

## 2. Implementation
- [ ] 2.1 Modify `InputHandler.gd` to detect mouse dragging and emit `drag_interacted(delta: Vector2)`
- [ ] 2.2 Modify `CameraHandler.gd` to implement `pan_camera(delta: Vector2)` method
- [ ] 2.3 Update `InputController.gd` to process drag events based on initial click target validity
- [ ] 2.4 Implement `drag_requested` command or signal forwarding in `CameraController.gd`

## 3. Verification
- [ ] 3.1 Write GdUnit4 tests for `CameraHandler` panning
- [ ] 3.2 Write GdUnit4 tests for `InputHandler` dragging
- [ ] 3.3 Manual verification in sandbox level

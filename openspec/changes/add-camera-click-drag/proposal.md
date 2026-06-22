# Change: Add Camera Click and Drag

## Why
Currently, the camera can only be moved via rotation or zoom, or by centering on the selected unit. Improving user experience by allowing intuitive click-and-drag panning of the map grid, especially for exploration or viewing distant areas.

## What Changes
- **NEW** Click-and-drag panning in `CameraHandler`.
- **MODIFIED** `InputHandler` to detect and emit mouse drag events.
- **MODIFIED** `InputController` to coordinate drag logic, ensuring it only activates when clicking "empty" space (outside map or out of movement range).
- **ADDED** `pan_camera` signal/method to `CameraHandler`.

## Impact
- Affected specs: `camera-control` (NEW), `interaction` (MODIFIED)
- Affected code: `InputHandler.gd`, `CameraHandler.gd`, `InputController.gd`, `PrimaryActionCommand.gd`

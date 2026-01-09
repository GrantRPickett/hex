# Code Review: Memory Leaks & Unhandled Awaits Analysis

**Project:** Hex (Godot 4 + GdUnit4)
**Date:** January 8, 2026
**Scope:** Tests and gameplay code

---

## Critical Issues Found

### 1. **TEST FILE: `test_gameplay_goal.gd` - SYNTAX ERROR + Missing Variables**

**Severity:** 🔴 **CRITICAL** - Test will not run

**Location:** Lines 47-72
```gdscript
func test_goal_reached_prevents_subsequent_moves() -> void:
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)  # ❌ PROBLEM: runner is not defined!

	scene.set_player_coord(Vector2i(0, 0))  # ❌ PROBLEM: scene is not defined!
	...
	@warning_ignore("redundant_awaitoord).is_equal(Vector2i(1, 0))  # ❌ GARBLED TEXT
```

**Issues:**
- Function declares no `runner` or `scene` variables
- Line 68 has corrupted syntax: `@warning_ignore("redundant_awaitoord).is_equal...`
- Test will crash immediately

**Fix:** Initialize runner/scene properly:
```gdscript
func test_goal_reached_prevents_subsequent_moves() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)
	...
```

---

### 2. **SIGNAL CONNECTION LEAK: `gameplay.gd` - Pause Menu Signal Connections**

**Severity:** 🟡 **HIGH** - Potential memory leak when pausing multiple times

**Location:** [gameplay.gd](gameplay.gd#L578-L580)
```gdscript
func _show_pause_menu() -> void:
	if _paused:
		return
	_paused = true
	...
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.controls_requested.connect(_on_pause_controls)
	_pause_menu.quit_requested.connect(_on_pause_quit)
	get_tree().paused = true
```

**Problem:**
- When `_show_pause_menu()` is called multiple times before `_hide_pause_menu()`, new signal connections are added without disconnecting old ones
- Creates duplicate callbacks and memory accumulation

**Impact:** Each pause-unpause cycle leaks one callback reference

---

### 3. **SIGNAL CONNECTION ISSUE: `level_manager.gd` - Redundant Disconnect Check**

**Severity:** 🟡 **MEDIUM** - Defensive but inefficient

**Location:** [level_manager.gd](level_manager.gd#L32-L33)
```gdscript
if scene.is_connected("level_complete", Callable(self, "_on_level_complete")):
    scene.disconnect("level_complete", Callable(self, "_on_level_complete"))
scene.level_complete.connect(_on_level_complete)
```

**Problem:**
- Godot 4 `disconnect()` silently succeeds even if not connected
- The check is redundant; direct disconnect is safer and simpler

---

### 4. **TIMER CALLBACK LEAK: `credits.gd` - Token Pattern (✅ GOOD)**

**Severity:** 🟢 **HANDLED CORRECTLY**

**Location:** [credits.gd](credits.gd#L14-L22)
```gdscript
func _start_timer() -> void:
	_timer_token += 1
	var token := _timer_token
	var timer := get_tree().create_timer(return_delay)
	timer.timeout.connect(Callable(self, "_on_return_timeout").bind(token))

func _on_return_timeout(token: int) -> void:
	if token != _timer_token:
		return  # ✅ Stale callback ignored
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
```

**Status:** ✅ **CORRECT** - Token pattern prevents stale callback execution when timer is recreated

---

### 5. **SCENE TRANSITION AWAITS - Potential Orphaned Await**

**Severity:** 🟡 **MEDIUM** - Edge case in error path

**Location:** [level_manager.gd](level_manager.gd#L43-L68)
```gdscript
func _on_quit_to_title() -> void:
	if SceneTransition.is_changing():
		print_debug("DBG level_manager _on_quit_to_title ignored: already changing")
		return
	await SceneTransition.change_scene(TITLE_SCENE)  # ⚠️ AWAIT NOT AWAITED
```

**Problem:**
- Signal handler `_on_quit_to_title()` is called by a signal emission
- The `await` is not awaited in the calling context
- If node is freed before await completes, this becomes a dangling async operation

**Same issue in:**
- [level_manager.gd](level_manager.gd#L62-L68) `_on_level_complete()` method

---

### 6. **TEST FILE: `test_level_chaining.gd` - Signal Handler Not Disconnected on Timeout**

**Severity:** 🟡 **MEDIUM** - Signal connection leak if timeout occurs

**Location:** [test_level_chaining.gd](test_level_chaining.gd#L16-L26)
```gdscript
func _await_scene_change(runner: GdUnitSceneRunner, tree: SceneTree, context: String) -> void:
    var changed := false
    var handler := func (_new_scene: Node) -> void:
        changed = true
    tree.scene_changed.connect(handler)
    var frames := 0
    while not changed and frames < SCENE_CHANGE_TIMEOUT_FRAMES:
        await runner.simulate_frames(1)
        frames += 1
    if tree.scene_changed.is_connected(handler):
        tree.scene_changed.disconnect(handler)
```

**Problem:** ✅ **ACTUALLY FIXED** - The check on line 25 correctly disconnects on timeout

**Status:** Code is correct but pattern could be simplified

---

### 7. **TEST FIXTURE LEAK: `test_title_screen.gd`**

**Severity:** 🟡 **MEDIUM** - Possible scene runner cleanup issue

**Location:** [test_title_screen.gd](test_title_screen.gd#L60-L65)
```gdscript
var instance := title_screen.instantiate()
add_child(instance)
...
instance.free()
# Ensure instance is freed
```

**Issue:**
- Manual `free()` on test node - GdUnit4 test harness should handle this
- Test runners typically auto-cleanup; manual free may cause double-free or orphaned references

---

## Summary Table

| Issue | File | Line | Severity | Type | Status |
|-------|------|------|----------|------|--------|
| Undefined variables + syntax error | test_gameplay_goal.gd | 47-72 | 🔴 CRITICAL | Unhandled | **NEEDS FIX** |
| Signal connection accumulation | gameplay.gd | 578-580 | 🟡 HIGH | Memory leak | **NEEDS FIX** |
| Redundant disconnect check | level_manager.gd | 32-33 | 🟡 MEDIUM | Code quality | **Can improve** |
| Orphaned awaits in signal handlers | level_manager.gd | 43-68 | 🟡 MEDIUM | Unhandled await | **Verify behavior** |
| Manual free() in tests | test_title_screen.gd | 63 | 🟡 MEDIUM | Test cleanup | **Review needed** |

---

## Recommendations

### Immediate Actions (Before Next Test Run)

1. **Fix `test_gameplay_goal.gd` test syntax error** - Currently non-functional
2. **Add signal disconnect in `gameplay.gd`** - Prevent accumulation on repeat pause
3. **Review `level_manager.gd` async flow** - Ensure signal handler awaits don't cause orphaned tasks

### Code Quality Improvements

1. Replace redundant `is_connected()` checks with direct `disconnect()`
2. Consider wrapping signal handlers that use `await` in coroutine cancellation guards
3. Remove manual `free()` calls in test fixtures - let GdUnit4 handle cleanup

### Testing Considerations

1. Add test to verify pause menu can be shown/hidden repeatedly without leaks
2. Test level_complete signal during scene transitions
3. Validate no dangling awaits on scene exit

---

## Files Analyzed

✅ Reviewed:
- `tests/test_gameplay_goal.gd`
- `tests/test_level_chaining.gd`
- `tests/test_title_screen.gd` (partial)
- `Gameplay/gameplay.gd`
- `Autoloads/level_manager.gd`
- `Autoloads/scene_transition.gd`
- `Menus/credits.gd`

---

## Notes

- **Godot 4 signal pattern:** Always prefer direct `disconnect()` over `is_connected()` check
- **Await in signal handlers:** Use task cancellation patterns when signal calls async code
- **Test cleanup:** GdUnit4 handles scene runner cleanup; avoid manual `free()` unless necessary
- **Timer callbacks:** Credits.gd demonstrates correct token pattern for callback invalidation

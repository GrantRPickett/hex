---
description: Run tests using the invariant runner to avoid repetitive approval prompts.
---

1. Update the `.test_targets` file in the project root with the `res://` paths of the tests you want to run (one per line).
2. Run the command:
```powershell
pwsh -File scripts/execute_test.ps1
```
// turbo
3. If you need verbose output, run:
```powershell
pwsh -File scripts/execute_test.ps1 -Verbose
```

> [!TIP]
> Once you mark the command `pwsh -File scripts/execute_test.ps1` as "Always Allow", you won't be prompted for approval again, even if you change which tests are being run in `.test_targets`.

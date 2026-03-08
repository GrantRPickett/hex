# Python 3 Development Skill

## Mission
Build and maintain repo tooling (validators, converters, generators) using modern Python 3 standards.

## Workflow
1. Align scripts with existing CLI entry points in `scripts/` and `openspec/`.
2. Prefer standard library modules before adding dependencies; document any third-party usage.
3. Write unit tests alongside helpers when feasible and integrate with repo validation scripts.
4. Optimize for clarity and logging so non-Python teammates can debug outputs.

## Best Practices
- Follow `black`/PEP8 style, type annotate critical functions, and guard main entrypoints with `if __name__ == "__main__":`.
- Handle Windows paths via `pathlib` and avoid hard-coded separators.
- Provide descriptive errors and exit codes for CI friendliness.
- Keep data conversions (e.g., JSON ↔ TRES) deterministic for reproducible builds.

## Collaboration
- Sync with Godot dev skill to match resource formats.
- Share script usage docs with Documentation skill and validation impacts with Product.
- Leave TODOs near scripts when upstream data contracts change.

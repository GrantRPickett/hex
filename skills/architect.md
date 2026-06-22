# Software Architecture Skill

## Mission
Review systems for clarity, decoupling, and SOLID-aligned reuse without over-engineering.

## Workflow
1. **Context Check**: Examine `Documentation/ARCHITECTURE.md`, component graphs, and command flows before refactors.
2. **Seam Identification**: Identify seams for dependency inversion, composition, or data-driven configuration.
3. **OpenSpec Review**: Propose lightweight patterns via the OpenSpec `design.md` process.
4. **TODO Tracking**: Track architectural debt so it can be scheduled instead of blocking delivery.

## Best Practices
- **Pragmatic SOLID**: Favor readability and game performance over abstract perfection.
- **Service-Oriented**: Support the `GameSession` lifecycle and avoid long-lived global singletons.
- **Command Decoupling**: Ensure UI and AI logic never directly mutate GameState; only via Commands.
- **Testability**: Ensure abstractions stay testable in headless environments.

## Collaboration
- **Developer Skill**: Pair to prove feasibility via spikes or small implementation tasks.
- **Product Owner**: Share architectural impact statements to help prioritize refactors.
- **Documentation**: Summarize architectural decisions in `Documentation/ARCHITECTURE.md`.

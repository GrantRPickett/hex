# Tasks: Refactor Core Architecture

- [ ] Define Capability: `unified-game-state` <!-- id: 0 -->
- [ ] Define Capability: `game-session-node` <!-- id: 1 -->
- [ ] Define Capability: `standardized-service-setup` <!-- id: 2 -->
- [ ] Implement `unified-game-state` <!-- id: 3 -->
	- [ ] Merge `GameSessionServices` and `GameState` <!-- id: 4 -->
	- [ ] Update all service references to use the new container <!-- id: 5 -->
- [ ] Implement `game-session-node` <!-- id: 6 -->
	- [ ] Create `GameSession.gd` <!-- id: 7 -->
	- [ ] Move builder logic into `GameSession` <!-- id: 8 -->
- [ ] Implement `standardized-service-setup` <!-- id: 9 -->
	- [ ] Update individual services to use `setup(session)` <!-- id: 10 -->
- [ ] Refactor `Gameplay.gd` to use `GameSession` <!-- id: 11 -->
- [ ] Verify with existing tests and add new ones if needed <!-- id: 12 -->

# Backlog: Narrative & Aesthetics

Meeting: 2026-03-08 | Participants: Narrative, Art, Sound

| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[MUST]** Branching Mission Outcomes (Fail Forward) | **L** | [ ] | **ND:** "New story paths on mission failure. Ensures defeat isn't just a restart." / **Arch:** "Map level IDs to narrative result flags in SaveManager." / **PO:** "High priority for campaign depth; creates a 'living world' feel." |
| **[SHOULD]** GraveyardService for Fallen Units | **M** | [ ] | **ND:** "Track dead units for narrative epilogues. Record their last deed." / **QA:** "Validate tombstone data persistence across scene transitions." / **Doc:** "Add to `DIALOGUE_CREATION.md` so writers can use 'DeadUnit' as a variable." |
| **[COULD]** Create placeholder sound/visual weather cues | **M** | [ ] | **Sound/Art:** "Storm/Heat hooks for transition feedback." / **Dev:** "Use `audio_bus_controller` to dynamically apply low-pass filters during 'Heavy Rain'." |
| **[COULD]** Ambience Zone Generation for Map Generator | **M** | [ ] | **Art/PyDev:** "Extend Python tool to include audio trigger zones. Use Perlin noise to find 'wet/dry' spots." / **Sound:** "Ensure zones don't overlap awkwardly; use faders." |
| **[COULD]** Unique hover sounds for HUD buttons | **XS** | [ ] | **Sound:** "Provide feedback for system interactions." / **QA:** "Ensure sounds don't double-trigger on rapid hovering." |
| **[SHOULD]** Better location sprite than a rock | **S** | [ ] | **Art:** "Need more descriptive/thematic sprites for key locations." |
| **[SHOULD]** Neutral loyalty color change on sprite and turn order | **M** | [ ] | **Art/UX:** "Visually distinguish neutral units and their turn order status." |
| **[SHOULD]** UI panel color style updates | **S** | [ ] | **Art:** "Refine colors for UI panels to match the game's aesthetic." |
| **[COULD]** Sprite facing or rotation? | **M** | [ ] | **Art/Dev:** "Evaluate if units should face targets or rotate." |
| **[SHOULD]** Before/After sprites for locations, loot, or danger | **M** | [ ] | **Art:** "Visual feedback for state changes on map items." |

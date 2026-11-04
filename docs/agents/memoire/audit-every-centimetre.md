---
name: audit-every-centimetre
description: "Level audits must be exhaustive (walk grid + screenshot grid, every room, both directions), not spot checks"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 859f48d8-d83e-4666-9a42-4295b9c6e433
  modified: 2026-11-04T14:47:41.144Z
---

When auditing a level (collisions, placement, hints, visuals), check every square centimetre: a 0.5 m walk grid over all walkable ground inside and out, a screenshot grid (every 4 m, 8 directions, room corners, ceilings) with every capture actually looked at, every stair walked fully up and down, every door/exit/interactable used from every place a player would expect, and every liquid joint (lava flow into crater lakes, rivers into basins) checked for seams.

**Why:** after several agent audit rounds the user still found many problems (lava flow not reaching the crater lakes in the Plaine, the Marais crypt only exitable from the bottom of the stairs) and said "il faut vraiment que les agents regardent chaque centimètre carré".

**How to apply:** brief level agents with this method (a copy lives in the session scratchpad as agents/PASSE_CENTIMETRE.md), require a PROBLEMES.md list with coordinates, and require before/after counts and captures in reports. Treat each reported bug as a symptom of a family of bugs to hunt. See [[game-context]].

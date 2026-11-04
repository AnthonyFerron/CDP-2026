---
name: commit-convention
description: CDP-2026 team commit message prefixes and branch workflow from the L1 framing note
metadata:
  node_type: memory
  type: project
  originSessionId: 859f48d8-d83e-4666-9a42-4295b9c6e433
  modified: 2026-11-03T09:03:05.632Z
---

The team's framing note (livrables/L1_Cadrage.pdf, on dev since 2026-11-02) sets commit prefixes: `features :`, `fix :`, `refactor :`, `docs :` (French message after the prefix). Workflow: feature branches split from dev and merge back into dev; dev merges into main.

**Why:** agreed team rule in the graded L1 deliverable; earlier commits in this repo predate it and don't follow it.
**How to apply:** prefix every commit message accordingly; never add a Claude co-author line (see CLAUDE.md). Related: [[game-context]].

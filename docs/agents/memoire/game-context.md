---
name: game-context
description: "CodeQuest official scenario (Scénario.pdf, given 2026-11-04): timeline, Vibelandia war, Mont Sam Altan, the four zones, puzzles, ending — the reference for every in-game text"
metadata:
  node_type: memory
  type: project
  originSessionId: 859f48d8-d83e-4666-9a42-4295b9c6e433
  modified: 2026-11-04T10:52:33.612Z
---

Game: "CodeQuest – La Recherche des livres oubliés" (team Ruminate Studio, Institut G4, Cercle de Projets 2026). Hosted at codequest.anthonyferron.com. The user supplied the official scenario PDF on 2026-11-04; it is the reference for all texts. A faithful French summary lives in the session scratchpad as `agents/SCENARIO.md`; key facts:

- **Timeline**: 5802 Devlyn and Codia beat the Four Dragons of Chaos (an old victory, not the cause of the ruins). 5804 the neighbouring kingdom **Vibelandia** declares war; king **Codeon V** asks retired hero Devlyn to lead the troops. Eight years of losing war; Devlyn returns gravely weakened; 5812 the king sends survivors to an old **underground bunker near the castle**; two years in the dark; the war ends. **5814**: plains burnt, villages ruined, forests dead.
- **Merlon**: old mage from an enchanted forest, nobody knew he was in the bunker. The volcano **Mont Sam Altan** is waking; scenario says eruption in 40 min, but **the user chose to keep 60 minutes in the game** (`GameState.TOTAL_TIME`); each puzzle error costs 5 minutes. Merlon opens portals with his last magic; the first appears outside the bunker near the **castle ruins**.
- **Books** (knowledge of the "anciens bâtisseurs"): Projenomicon (project management), Algonicon (algorithms), Logiconomicon (logic and cipher), Codonomicon (programming).
- **Zones**: *plaines d'Hexcole* (burnt grass, craters, ruined library, stone slab + six-slot tablet, six parchment fragments of the librarian/project-lead conversation, stairs to a stone lectern); *désert de Pythania* (cactus, animal bones, vulture skulls, monument, sand-covered stone trapdoor, dusty cave, round stone table, two engraved algorithms, runes in rooms/outside/under sand piles, a sand pile in a corner reveals a stone chest); *marais de Kernel Swamp* — puzzle "Le tombeau du chiffrement" (thick fog, crypt hidden by vegetation, long stairs, branching corridors to burial chambers, five-ring mechanism, CODIA ±3 → FLGFD, a tomb lid slides); *village détruit* (destroyed by Vibelandia, the town hall is the last intact building, 10 paper fragments = 2 per language, HTML/CSS/Python/PHP/JS-TS device, bookcase slides to a secret room with a stone lectern).
- **Feedback per puzzle**: error = red glow + tremor; success = green (Hexcole, Kernel Swamp) or blue (Pythania, village).
- **Ending**: return near castle ruins under ash clouds and red glow; throne room, four pedestals around an old magic circle, floor inscriptions light up per book, beams to the centre at the last; Merlon's incantation, energy wave, volcano sleeps, ash clears, land and buildings restore; Merlon collapses to his knees and smiles; survivors leave the bunker; books entrusted to a protected place; Devlyn hopes his retirement is final. Last line hints at future secrets of Codia.

**Why:** the user asked to keep the scenario in memory for what is built later; earlier lore in the game (war caused by the Dragons) was wrong.
**How to apply:** check every new text, sign, dialogue or puzzle against this; flag gameplay that departs from it (e.g. team rule: all NPCs stay in the bunker until victory, while the scenario has the king and Merlon waiting in the throne room on Devlyn's return). Related: [[commit-convention]], [[assets-kenney-only]].

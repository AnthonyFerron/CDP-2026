# Textes du jeu : deuxième passe de vérification (8 novembre)

Relecture de tout ce que le joueur lit : panneaux (`SignBoard`), parchemins, plaques, stèles, livres, enseignes, gravures (`Label3D`), dialogues des PNJ, invites, messages du HUD, indices (`ZONE_HINTS`, touche H), énigmes (consignes, fragments, messages d'erreur), écrans de fin et menus. Le scénario officiel (`SCENARIO.md`) fait foi.

## Méthode

- **Relevé exhaustif.** Chaque lieu est chargé dans Godot, et tous les textes portés par les nœuds sont vidés : `Readable` (invite, titre, texte), `SignBoard`, `Interactable`, `Label3D`, `Label`, `Button`. S'y ajoutent les chaînes des scripts (dialogues, messages, énigmes, interface) et les livres de la bibliothèque avec leur fragment.
- **Textes relus**, en comptant à part l'invite, le titre et le texte : environ 250 au hub (dont les 47 lettres du cercle), 95 à la Plaine, 84 au désert, 84 au marais, 100 au Village et 156 dans l'interface (menus, pause, HUD, indices, compte, synchronisation). Cela fait environ 770 en tout.
- **Typographie, vérifiée par un script sur tous ces textes :**
  - espace avant `: ; ! ?` ;
  - guillemets « » avec leurs espaces ;
  - apostrophes droites partout, sans apostrophe courbe mêlée ;
  - points de suspension « … » ;
  - pas de double espace.

  Aucune faute restante : les seules alertes sont du code (énigmes du Village, en-têtes HTTP) ou des heures (`59:44`).
- **Glyphes.** Chaque caractère affiché existe dans Lora et dans Cinzel, et la version web n'a pas de police de secours. Hors ASCII, on trouve : « » À Â É × à â ç è é ê î ô ù û œ — … −.
- **Lisibilité mesurée :**
  - **Lecteur du HUD**, qui ne défile pas. Les 110 textes lisibles ont été mesurés dans le vrai `hud.tscn`. Le plus haut est la lettre de la bibliothécaire : 889 px sur 1080, de y = 95 à 984, sous la plaque du chronomètre. Le dialogue de Merlon fait 846 px.
  - **Panneaux `SignBoard`.** Leur script réduit le texte jusqu'à ce qu'il tienne. Les 78 panneaux des cinq lieux tiennent tous. La plus petite ligne mesure 7 cm, sur l'affiche de la proclamation (Plaine), dont le texte complet se lit avec E.
  - **Fenêtre des indices :** 240 px au plus pour une zone de texte de 350.
  - **Titre de la bonne fin :** 262 px au plus pour un cadre de 302.
  - **Dispositif du Village.** L'épreuve JS/TS, longue de 12 lignes, tient dans sa page. Un testeur l'avait vue déborder.
  - **Carnet et dispositif :** les coupures de ligne des dix fragments ont été mesurées avec le `TextParagraph` de Godot. Il n'en reste plus aucune au milieu d'un mot ni d'une balise.

## Corrections

| Lieu | Endroit (source) | Avant | Après | Pourquoi |
| --- | --- | --- | --- | --- |
| Hub | Invite d'un piédestal garni (`hub.gd`) | L'algonicon repose ici | L'Algonicon repose ici | `String.capitalize()` mettait le reste du nom en minuscules |
| Hub | Message après la pose (`hub.gd`) | L'algonicon repose sur son piédestal. | L'Algonicon repose sur son piédestal. | idem |
| Hub | Panneau « L'allée des rois » (`write_hub_tscn.py`) | Codeon I, le bâtisseur ; Codeon II, le sage ; Codeon III, le jardinier ; Codeon IV, le prudent. | Codeon I, le Fondateur ; Codeon II, le Hardi ; Codeon III, le Prudent ; Codeon IV, le Juste. | Ce sont les surnoms gravés sur les tombeaux de la crypte du marais, qui portent l'énigme |
| Hub | Panneau « La Chope du Dragon » (`write_hub_tscn.py`) | la dernière bière tirée avant la guerre contre Vibelandia attend encore au fond d'un tonneau | la dernière bière brassée avant la guerre contre Vibelandia attend encore au fond d'un tonneau | Une bière tirée n'est plus dans le tonneau |
| Hub | Panneau « La mine d'argent » (`write_hub_tscn.py`) | Un écriteau est cloué au boisage : « Fermée par ordre du roi Codeon V. Les mineurs ont rejoint le bunker. » | Un écriteau est cloué au boisage : « Fermée par ordre du roi Codeon V. » Dessous, à la craie : « Les mineurs ont rejoint le bunker. » | L'écriteau en 3D ne porte que la première phrase |
| Hub | Panneau « Le lavoir de la rivière » (`write_hub_tscn.py`) | Le jour où le roi fit sonner les cloches, en 5812, les draps sont restés sur la corde | Le jour où le roi a fait sonner les cloches, en 5812, les draps sont restés sur la corde | Temps accordés, comme dans le dialogue d'Elda |
| Hub | Cahier du meunier (`build_hub.py`) | Sacs moulus pour la boulangerie et pour la garde, an 5812 : quatre cents | Sacs moulus pour la boulangerie et pour la garde, an 5812 : quarante | Le livre du boulanger ne compte que six sacs reçus en 5812 |
| Hub | Inscription du cercle, lue avec E (`write_hub_tscn.py`) | Gravé dans le mur du fond, face à la porte : « Quatre livres, quatre savoirs. Posés autour du cercle, ils rendront la vie à Codia. » | Gravé dans le mur du fond, face à la porte : « Quatre livres, quatre savoirs. » Selon la légende, posés autour du cercle, ils rendront la vie à Codia. | Le mur ne porte que « QUATRE LIVRES, QUATRE SAVOIRS » |
| Hub | Message du rituel (`hub.gd`) | Les survivants sortent du bunker. Merlon lève les mains au-dessus du cercle et prononce une ancienne incantation… | Merlon lève les mains au-dessus du cercle et prononce une ancienne incantation… | Dans le scénario, les survivants sortent après l'incantation |
| Hub | Titre de la bonne fin (`hub_ending.gd`) | … les arbres reprennent vie et Codia renaît. Mais qui sait… | … les arbres reprennent vie, Codia renaît et les survivants sortent enfin du bunker. Mais qui sait… | idem (épilogue du scénario) |
| Plaine | Stèle de la bibliothèque (`plaine.tscn`) | Sous la date, une devise | Sous le nom, une devise | Aucune date n'est gravée |
| Plaine | Stèle des défenseurs (`plaine.tscn`) | jusqu'à ce que leurs catapultes mettent le feu au toit. … : Aldric, Brune, Corentin, Doria, Edmond et Faye. | jusqu'à ce que les catapultes ennemies mettent le feu au toit. … : Anselme, Brune, Corentin, Doria, Edmond et Faye. | « leurs » renvoyait aux défenseurs ; Aldric est le garde royal, vivant, du bunker |
| Plaine | Notes du greffier (`plaine.tscn`) | ont parlé chacun son tour | ont parlé chacun à son tour | Grammaire |
| Plaine | Livre « Procès-verbaux de clôture » (`plaine.tscn`) | Des projets achevés, signés et tamponnés. | Des projets achevés, signés et scellés. | Le tampon encreur est moderne |
| Désert | Stèle de la chambre ouest (`write_desert_tscn.py`) | Stèle du levant, gravure LEVANT | Stèle du couchant, gravure COUCHANT | Le levant est l'est, et le soleil du désert éclaire depuis l'est |
| Désert | Stèle de la chambre est (`write_desert_tscn.py`) | Stèle du zénith, gravure ZÉNITH | Stèle du levant, gravure LEVANT | idem |
| Désert | Stèle de la salle des colonnes, au sud (`write_desert_tscn.py`) | Stèle du couchant, gravure COUCHANT | Stèle du midi, gravure MIDI | idem (le midi est le sud) |
| Marais | Épitaphe de la tombe du gardien (`write_marais_tscn.py`) | Ci-gît Aldric, gardien du marais. | Ci-gît Odon, gardien du marais. | Trois personnages s'appelaient Aldric : le garde royal du bunker garde son nom |
| Marais | Plaque de la tombe du gardien (`write_marais_tscn.py`) | Aldric / Gardien du marais / 5761 - 5803 | Odon / Gardien du marais / 5761 - 5803 | idem |
| Marais | Avis de la capitainerie (`write_marais_tscn.py`) | depuis la mort du gardien Aldric | depuis la mort du gardien Odon | idem |
| Marais | Épitaphe de Codeon IV (`write_marais_tscn.py`) | Il reprit la marche en avant, de trois pas encore, puis ferma la mine d'argent. | Il reprit la marche en avant, de trois pas encore, et fit creuser la mine d'argent. | Au hub, c'est Codeon V qui ferme la mine, pendant la guerre |
| Marais | Portail éteint (`marais.gd`) | Le portail reste éteint : trouvez le livre des marais. | Le portail reste éteint : trouvez le livre des marais de Kernel Swamp. | Nom complet, comme dans les autres lieux |
| Village | Portail éteint (`village.gd`) | Le portail reste éteint : trouvez le livre du Village. | Le portail reste éteint : trouvez le livre du village détruit. | Le lieu s'appelle « le village détruit » partout ailleurs |
| Village | Livre trouvé (`village.gd`) | Rapportez-le au château du hub : le portail du Village s'est rouvert. | Rapportez-le au château : le portail du village détruit s'est rouvert. | « hub » est un mot de développeur |
| Village | Meuble vide (`village.gd`) | Vous ouvrez l'armoire des archives : il ne contient que de la poussière. | Vous ouvrez l'armoire des archives : il n'y a que de la poussière. | « il » ne s'accordait pas avec les armoires |
| Village | Fragment « Notes de l'archiviste » (`village.gd`) | Chaque élément s'écrit entre `<li>` et `</li>` | Chaque élément de la liste s'écrit entre `<li>` et `</li>` | Dans le carnet, la ligne se coupait au milieu de la balise (« </ » puis « li> ») |
| Indices | Village, indice 2 (`hints.gd`) | Lisez chaque programme ligne par ligne, comme le ferait l'ordinateur. | Lisez chaque programme ligne par ligne, en notant la valeur de chaque variable à chaque étape. | Pas d'ordinateur dans un décor médiéval |
| Menu | But du jeu (`main_menu.gd`) | Retrouver les 4 livres en une heure | Retrouver les quatre livres en une heure | Nombre en lettres, comme dans tous les autres textes |

Les README du désert et du marais suivent ces noms. Les docstrings de `build_desert.py` aussi : ce sont des commentaires, ils ne changent pas les scènes. Les générateurs relancés ne produisent aucune dérive en dehors de ces chaînes.

## Laissés tels quels, volontairement

- **Fragments de la Plaine** (« établir un planning ») : ils sont cités mot pour mot dans le `README.md` racine, qui est figé.
- **« Royaume » avec une majuscule** dans l'hommage aux rois de la crypte : c'est la formule demandée par le testeur.
- **« bunker »** : c'est le mot du scénario officiel.
- **« navigateur », « développeur », `console.log`, `print`** dans les fragments et les épreuves du Village : l'énigme sur les langages les exige.
- **Noms internes des stèles du désert** (`Levant`, `Zenith`, `Couchant`) : les nœuds gardent leur nom, pour ne changer aucun chemin de scène. Seuls le titre et la gravure changent.
- **Invites « Lire : Le registre… »** au hub : c'est la forme « action : titre » de toutes les invites du hub, et non une phrase.
- **Menu de debug** : il est absent de l'export.

## Captures

Elles sont dans `~/cdp-dev/.claude/captures/verif-textes/shots/` :

- **`hub/` :**
  - lecteurs : dialogue de Merlon, allée des rois corrigée, mine ;
  - supports 3D : piédestal de l'Algonicon, inscription du trône, statue de Devlyn, mémorial.
- **`plaine/` :**
  - lecteurs : lettre de la bibliothécaire, stèle des défenseurs, notes du greffier ;
  - supports 3D : stèle de la bibliothèque, inscription de la dalle (de face et depuis la tablette).
- **`desert/` :**
  - supports 3D : les trois stèles renommées, les deux murs des algorithmes ;
  - lecteur : une stèle.
- **`marais/` :**
  - supports 3D : plaque du gardien, inscription du mur, nom de Codeon IV, devise du tombeau ;
  - lecteurs : épitaphe de Codeon IV, avis de la capitainerie.
- **`village/` :** épreuves 3 à 5 du dispositif, carnet avec les dix fragments.
- **`hud/` :** captures de `hud_shots.gd` (tablette, table des runes, cercles, dispositif, carnet, lecteur long, invites).

Outils de relevé et de mesure, hors du dépôt : `~/cdp-dev/.claude/captures/verif-textes/repro/`.

- `dump_texts.gd` : relevé des textes portés par les nœuds ;
- `strings.py` : chaînes des scripts ;
- `typo.py` : typographie ;
- `glyphs.gd` : glyphes ;
- `measure_reader.gd` : hauteur du lecteur ;
- `sign_fit.gd` : panneaux ;
- `hints_fit.gd` : indices ;
- `village_breaks.gd` : coupures de ligne ;
- `text_shots.gd` : captures devant un texte.

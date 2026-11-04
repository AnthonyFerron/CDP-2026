## Titre et équipe

Nom du jeu : CodeQuest

Code et nom de l'équipe : Equipe 3 - Ruminate Studio

Campus : Lyon

Membre et rôles :

| Membre   |      Rôle     |
|----------|:-------------:|
| FERRON Anthony |  Lead dev |
| KHASHIMOV Sherzod |    Chef de projet   |
| MARCHESSE Clement | Assistant chef de projet |
|DALIGAND Dorian|Développeur back/Responsable technique|
|ROBIN FAYET Mathéo|Développeur front/Game designer|
|SMATTI Abdelaziz|Designer|



## Jouer en 2 minutes
Lien pour jouer au jeu : https://codequest.anthonyferron.com/

## Comment jouer
Commandes : Se déplacer avec ZQSD,sauter avec ESPACE, et interagir avec E.

But du jeu : Rassembler les quatres livres légendaires

Fonctionnement des indices : Les indices sont récupérables dans l'environnement autour du lieu de l'énigme.

Chronometre : Le chronometre est descendant et part de 60 minutes. Lorsque le chronometre arrive à zero, la partie est finie et perdante.

## Solution complète

<u>Enigme 1 (La plaine) : </u>
| Ordre | Locuteur | Fragment de dialogue |
| --- | --- | --- |
| 1 | Bibliothécaire | « Nous devons organiser la restauration des archives avant la prochaine inspection. » |
| 2 | Employé | « Quels sont les objectifs prioritaires de cette restauration ? » |
| 3 | Bibliothécaire | « Nous devons d'abord inventorier les ouvrages endommagés et identifier les ressources nécessaires. » |
| 4 | Employé | « Une fois l'inventaire terminé, nous pourrons établir un planning et répartir les tâches. » |
| 5 | Bibliothécaire | « Exactement. Nous devrons également suivre l'avancement des travaux et anticiper les éventuels retards. » |
| 6 | Employé | « Lorsque les travaux seront terminés, nous vérifierons leur conformité avant de clôturer le projet. » |

<u>Enigme 2 (Le désert) : </u>
| Ligne | Algorithme 1 (Jarre sacrée) | Algorithme 2 (Entrée du temple) |
| --- | --- | --- |
| 1 | Prendre une jarre vide | Demander le mot de passe au voyageur |
| 2 | TANT QUE la jarre n'est pas pleine ⚠️ | SI le mot de passe est « Soleil » ⚠️ |
| 3 | Puiser de l'eau au puits ⚠️ | Ouvrir la porte du temple ⚠️ |
| 4 | Verser l'eau dans la jarre | SINON ⚠️ |
| 5 | FIN TANT QUE | Sonner l'alarme |
| 6 | Porter la jarre au temple ⚠️ | FIN SI |

⚠️ = rune manquante à récupérer (algorithme 1 : lignes 2, 3, 6 ; algorithme 2 : lignes 2, 3, 4)

<u>Enigme 3 (Le marais) : </u>

| Cercle | Lettre | Règle | Décomposition | Résultat |
| --- | --- | --- | --- | --- |
| 1 | C | +3 | C → D → E → F | F |
| 2 | O | −3 | O → N → M → L | L |
| 3 | D | +3 | D → E → F → G | G |
| 4 | I | −3 | I → H → G → F | F |
| 5 | A | +3 | A → B → C → D | D |

Code final : **FLGFD**

<u>Enigme 4 (Le village détruit) : </u>

| Code | Langage | Réponse | Explication |
| --- | --- | --- | --- |
| 1 | HTML | 3 | « Tour de garde » est dans un commentaire (`<!-- ... -->`) : seuls Forge, Moulin et Puits s'affichent |
| 2 | CSS | green | Le sélecteur `#maire` (id) est le plus spécifique ; il l'emporte sur la classe et la balise |
| 3 | Python | 10 | `recolte = 12 > 10` → `greniers = 3 + 2 = 5` ; `print(greniers * 2)` affiche 10 |
| 4 | PHP | 2 | `$pieces = 7 + 5 = 12` ; `12 % 5` renvoie le reste 2 |
| 5 | JS/TS | 12 | Valeurs paires additionnées, impaires −1 ; réponse officielle du jeu : 12 (l'extrait affiché produirait 16) |

Séquence de validation : 3 — green — 10 — 2 — 12 (chaque erreur coûte 5 minutes sur le chronomètre global)

## Comptes de test
Jouable sans compte, création de compte possible pour acces au classement

## Technologies

Moteur : Godot

Bibliothèques :

| Bibliothèque | Rôle |
|---|---|
| Jolt Physics | Physique |
| FreeType | Rendu des polices |
| HarfBuzz | Mise en forme du texte |
| ICU | Données Unicode |
| Graphite | Mise en forme du texte |
| Open Sans, Noto Sans | Polices du moteur |
| ENet | Réseau |
| Mbed TLS | Chiffrement | Apache 2.0 |
| Recast | Navigation |
| OggVorbis | Audio |
| Quite OK Audio | Audio |
| Basis Universal | Textures |
| Brotli | Compression |
| WebP | Images |

## Structure du dépot

Voici le tableau en Markdown :

| Dossier | Contenu |
|---|---|
| frontend/ | Projet Godot |
| frontend/assets/ | Modèles, textures, matériaux, audio et polices |
| frontend/assets/models/kenney/ | Kits de modèles Kenney, par kit (voir docs/assets.md) |
| frontend/scenes/levels/ | Niveaux |
| frontend/scenes/player/ | Personnage joueur (scène et script) |
| frontend/scenes/ui/ | Interfaces |
| frontend/scripts/ | Scripts partagés qui n'appartiennent à aucune scène |
| backend/ | API Python |
| docs/ | Documentation technique |
| infrastructure/ | Base de données locale et production avec Docker |

## Lancer en développement

Installation :

- Installer Godot 4.7 en GDScript
- Activer Git LFS, une seule fois par machine, **avant de cloner**
    - `git lfs install`
- Clôner le dépot, puis importer `fronted/project.godot` depuis le gestionnaire de projet de Godot.
- Lancer le jeu avec `F5`

## Crédits et liscences

[Lien](https://github.com/AnthonyFerron/CDP-2026/blob/main/LICENCES.md)

## IA

[Lien]()

## Limites connues

Pas de limite

# A FAIRE
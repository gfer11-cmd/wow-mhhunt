# MHHunt — Carnet du chasseur (v0.126)

Addon de chasse façon **Monster Hunter** pour WoW Forever : carnet des rares
et élites, contrats de guilde, ménagerie pixel-art, cuisine, armes et succès.
Tout est en français (repli anglais automatique selon le client).

## Structure (4 modules, ordre du `.toc`)

| Fichier | Rôle |
|---|---|
| `MHHuntData.lua` | Base des rares/élites (zones, niveaux, alias, coordonnées) |
| `mhhunt.lua` | Core : base de données sauvée, carnet, chasse, contrats, guilde, cuisine, options, musiques |
| `Specimens.lua` | Données de la ménagerie : fiches des capturables, enclos par biome (aucune logique) |
| `Menagerie.lua` | Page Ménagerie : enclos, pensionnaires animés, régisseur, météo (autonome via les ponts `MHH_L`/`MHH_DB`/`MHH_Carnet`) |

`MHHunt.toc` impose l'ordre : `MHHuntData → mhhunt → Specimens → Menagerie`.
SavedVariable par personnage : `LaChasseDB`.

## Installation

Copier le contenu du dépôt dans `Interface/AddOns/MHHunt/` (y compris
`MHHunt.toc` et `Textures/`). Rien d'autre à faire.

## Le carnet

- **Gibier** : toutes les bêtes du data file, groupées par zone/continent,
  recherche, filtre « Ma zone », fiches (niveau, élite, coordonnées, notes).
  Détection automatique par NPC ID — les graphies du serveur sont apprises
  et promues (ex. « Rochelance » pour « Lance-de-roche »).
- **Chasse** : cibler un rare du carnet démarre la chasse (musique, chrono,
  série sans mourir). Prise validée par journal de combat, viseur ou cadavre.
  Fuite = chasse suspendue, re-ciblage = reprise.
- **Contrats** : un contrat du jour par session, prime en points de guilde.
- **Guilde** : rangs (Aspirant → Légende de la chasse), portrait, titre de
  chasseur par famille, vitrine de succès, statistiques, et l'**histogramme
  des armes** (types utilisables par votre classe, colonnes fixes, libellés
  verticaux au singulier).
- **Cuisine** : recettes à base d'ingrédients récoltés en chasse (viande,
  miel, herbe…) ; un repas bonifie la prochaine prise. Boutons grisés sans
  composants.
- **Options** : tout ce qui se règle en slash est aussi cliquable.

## La ménagerie (mini-jeu)

**4 enclos par biome**, débloqués au fil du rang de guilde (onglets sur
l'onglet Ménagerie ; verrouillés = grisés + tooltip du rang requis) :
savane (rang 1), marais (rang 2), montagnes (rang 3), volcan (rang 4).

- **Capture** : tuer la bête pendant qu'elle est piégée l'envoie en enclos.
- **Soins** : nourrir (viande, +4 affinité), gâter au miel (+10), tout le
  monde (+2). L'affinité décroît de 2/jour sans soin.
- **Affinité** : Méfiant → Apprivoisé → Attaché → **Dévoué**. Un pensionnaire
  dévoué de la zone chassée applaudit votre prise (+10 % des points) et
  donne une **piste quotidienne** sur un rare de sa zone.
- **Intrus** : parfois un gibier sauvage saute la clôture et panique le
  troupeau (sprites en fuite) — il s'enfuit en vous soufflant son nom.
- **Météo réelle** : pluie/neige/tempête tombent dans l'enclos, teinte du ciel.
- Succès « Ami dévoué » et « Enclos complet ».

## Textures

**Sprites des pensionnaires** (`Textures/Specimens/`) : pixel-art 48x48 en
**vue 3/4 de dessus** (style farm sim), 2 frames d'animation
(`<slug>.tga` + `<slug>_2.tga`), rendus x2.4 dans l'enclos. Repli : grille
pixel intégrée si le TGA manque. Pour remplacer un sprite : dessiner un PNG
48x48 transparent puis `img.save("slug.tga")` (PIL).
Slugs (capturables historiques) : humar, takk, mazzranache, sarkoth,
flagglemurk, naraxis, snarlflare, morladim, crocplat, crocolisque, plus le
régisseur (regisseur, regisseur_dort).
Les **capturables étendus** (Bjarn, Dishu, Snort, Azzere, Veuve-sangsue,
Timber, Hematos, Volchan…) n'ont pas de sprite : ils s'affichent via leur
**icône du jeu** (`sansPixel`, `icone` dans `Specimens.lua`).

**Fonds d'enclos** (`Textures/`) : 532x176 (TGA RGBA), en **vue plongée**
comme les sprites — tout le cadre est du sol texturé, grange vue du dessus
en haut à droite, clôture en haut/à gauche, arbre en haut à gauche :
- `enclos_savane/marais/montagne/volcan.tga` — les 4 biomes
- `enclos_horde.tga` / `enclos_alliance.tga` — ranchs de faction (replis)
- `enclos.tga` — prairie neutre (dernier repli)

## Commandes slash

`/hunt` ouvre le carnet. Principales : `/hunt aide`, `/hunt gibier`,
`/hunt carte`, `/hunt armes`, `/hunt titre`, `/hunt langue`, `/hunt musique`,
`/hunt debug`, `/hunt reset`. (`/hunt commands` liste tout.)

## Historique récent

- v0.126 : plus aucun humanoïde en pension ; Edan le Hurleur retiré
- v0.120 : +6 capturables non-élites (Dishu, Snort, Azzere, Veuve-sangsue, Timber…)
- v0.119 : Mor'Ladim remplacé par Bjarn ; succès « découverte » sur les rencontres
- Refactor : monolithe découpé en 4 modules (core / données / ménagerie / page)

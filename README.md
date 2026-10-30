## MHHunt

Addon de chasse façon Monster Hunter pour WoW Forever (carnet + chasse de rares/élites + ménagerie pixel-art).

## Fichiers
- `MHHuntData.lua` — base des rares (à charger AVANT MHHunt.lua dans le .toc)
- `MHHunt.lua` — addon principal
- `Textures/Specimens/*.tga` — sprites pixel-art 32x32 de la ménagerie (transparents, origin bottom-left)

## Installation
Copier le tout dans `Interface/AddOns/MHHunt/` avec votre `MHHunt.toc` :
```
MHHuntData.lua
MHHunt.lua
```

## Sprites de la ménagerie
Les spécimens sont des sprites 48x48 en **vue 3/4 de dessus** (style farm sim),
2 frames d'animation (`<slug>.tga` + `<slug>_2.tga`), rendus x2.4 dans l'enclos.
Repli : grille pixel intégrée si le TGA manque. Pour remplacer un sprite :
dessiner un PNG 48x48 transparent puis `img.save("slug.tga")` (PIL).
Slugs : humar, takk, mazzranache, sarkoth, flagglemurk, naraxis, snarlflare,
morladim, crocplat, crocolisque, regisseur, regisseur_dort.

## Fond de l'enclos (vue 3/4 de dessus)
Le décor est en **vue plongée** (comme les sprites) : tout le cadre est du sol
texturé, grange vue du dessus en haut à droite, clôture en haut/à gauche,
arbre en haut à gauche. Sept fonds 532x176 (TGA RGBA) :
- `enclos_savane/marais/montagne/volcan.tga` — les 4 enclos par biome (rang de guilde)
- `enclos_horde.tga` / `enclos_alliance.tga` — ranch de faction (replis)
- `enclos.tga` — prairie neutre (dernier repli)

La météo et le cycle jour/nuit les teintent automatiquement. Les spécimens
48x48 (vue 3/4, 2 frames d'animation) sont rendus x2.4.

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

## Fond de l'enclos (par faction)
Le décor dépend de la faction du chasseur :
- `Textures/enclos_horde.tga` — ranch de la Horde (savane, accents rouges)
- `Textures/enclos_alliance.tga` — ranch de l'Alliance (prairie, accents bleus)
- `Textures/enclos.tga` — décor neutre (repli si le fichier de faction manque)

Chaque image fait 532x166 (TGA RGBA), remplaçable librement. La météo et le
cycle jour/nuit les teintent automatiquement. Les spécimens sont rendus x2.5
depuis les sprites 32x32 (`<slug>.tga` + frame d'animation `<slug>_2.tga`).

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
Les spécimens utilisent `Textures/Specimens/<slug>.tga` s'il existe (repli : grille
pixel intégrée). Régénérer un sprite : dessiner un PNG 32x32 transparent, puis
`magick sprite.png -depth 32 sprite.tga` (ou PIL `img.save("sprite.tga")`).
Slugs : humar, takk, mazzranache, sarkoth, flagglemurk, naraxis, snarlflare,
morladim, crocplat, crocolisque, regisseur, regisseur_dort.

## Fond de l'enclos
`Textures/enclos.tga` (532x166) : scène pixel-art complète — ciel dégradé,
nuages, soleil, collines, arbre, herbe texturée, chemin, clôture, grange.
Remplaçable par n'importe quelle image 532x166 (TGA RGBA). La météo et le
cycle jour/nuit la teintent automatiquement.

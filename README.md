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

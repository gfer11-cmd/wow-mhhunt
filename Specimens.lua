-- ================================================================
-- MHHunt — Specimens.lua (extrait de mhhunt.lua v0.68)
-- DONNÉES des pensionnaires de la ménagerie : fiches
-- (MHH_SPECIMENS), ordre stable d'affichage, enclos par biome et
-- index dérivés. Ne contient aucune logique.
-- ORDRE DE CHARGEMENT (.toc) :
--     MHHuntData.lua
--     mhhunt.lua      (définit MHH_L à sa fin)
--     Specimens.lua   (ce fichier)
--     Menagerie.lua
-- v0.119e : Mor'Ladim sorti des capturables, remplacé par Bjarn
-- (ours rare de Dun Morogh) dans l'enclos des montagnes.
-- v0.120 : +6 capturables non-élites — Dishu, Snort le Moqueur,
-- Azzere la Lame-des-cieux (savane), Veuve-sangsue (marais),
-- Timber (montagne). v0.126 : Edan le Hurleur retiré
-- (harpie = humanoïde, règle « plus aucun humanoïde »).
-- ================================================================

local L = MHH_L   -- pont vers la traduction du fichier principal
-- v0.126 : PLUS AUCUN HUMANOIDE en pension — Kazon (rendu « orc »
-- sur ce serveur), Furie Shelda et Edan le Hurleur (harpies) sont
-- retirés. Règle : orcs, gobelins, harpies, Dark Iron, humanoïdes
-- en général = hors ménagerie (le régisseur Gazlowe excepté).
-- v0.125 : palier 31-60 du volcan — 6 rares de feu ajoutés
-- (Rekk'tilac, Brûlar, Gueule-du-trépas, Lueur terrifiante, Hematos,
-- Volchan — sources : mhhuntdata.lua du joueur + ForeverDB/Wowhead).
-- v0.124 : palettes et grilles pixel (sprites « faits main ») retirées
-- du fichier ET du code — les pensionnaires sont rendus par les modèles
-- 3D du jeu (cf. Menagerie.lua MHH_DISPLAYS).

MHH_SPECIMENS = {
    ["Humar le Seigneur hautain"] = {
        famille = L("Félin"),
    },
    ["Takk le Bondisseur"] = {
        famille = "Raptor",
    },
    ["Mazzranache"] = {
        famille = "Haut-traqueur",
    },
    ["Sarkoth"] = {
        famille = "Scorpide",
    },
    ["Flagglemurk le Cruel"] = {
        famille = "Murloc",
    },
    ["Naraxis"] = {
        famille = L("Araignée"),
    },
    ["Snarlflare"] = {
        famille = "Dragonnet",
    },
    ["Bjarn"] = {
        famille = "Ours",
    },
    ["Capitaine Croc-Plat"] = {
        famille = "Sanglier",
    },
    ["Grand crocolisque du loch"] = {
        famille = "Crocolisque",
    },
    -- ===== v0.120 : nouveaux capturables (rares non-élites, data
    -- Forever/CMaNGOS vérifié) pour élargir la chasse par biome =====
    ["Dishu"] = {
        famille = L("Félin"),
    },
    ["Snort le Moqueur"] = {
        famille = L("Hyène"),
    },
    ["Azzere la Lame-des-cieux"] = {
        famille = L("Serpent des vents"),
    },
    ["Veuve-sangsue"] = {
        famille = L("Araignée"),
    },
    ["Timber"] = {
        famille = L("Loup"),
    },
}
-- Ordre stable d'affichage dans l'enclos
MHH_SPECIMENS_ORDRE = {
    "Humar le Seigneur hautain", "Takk le Bondisseur",
    "Mazzranache", "Dishu", "Snort le Moqueur",
    "Azzere la Lame-des-cieux",
    "Flagglemurk le Cruel", "Naraxis", "Veuve-sangsue",
    "Snarlflare", "Bjarn", "Sarkoth",
    "Capitaine Croc-Plat", "Timber",
    "Grand crocolisque du loch",
}

-- ================================================================
-- v0.122 : CANDIDATS ÉTENDUS. Objectif « tous les faire » : chaque
-- rare notoire du data file devient capturable, SANS pixel art — le
-- modèle 3D natif (SetCreature par NPC id, cf. Menagerie.lua) rend
-- le pensionnaire. La capture implique que le gibier ait été tué :
-- son modèle est donc en cache client, et SetCreature l'affiche.
-- Repli : silhouette sombre (garde dans CreerSpriteMenagerie).
-- cle = graphie du data (nom en jeu) ; familles/types vérifiés
-- ForeverDB (pas d'invention : les humanoïdes sont exclus).
-- ================================================================
MHH_SPECIMENS_EXTRA = {
    -- SAVANE (palier ≤ 30, puis palier 31-60 de novembre)
    { cle = "Écorcheur mortel",      biome = "savane",   famille = L("Scorpide"),          icone = "Ability_Hunter_Pet_Scorpid",      ech = 0.8, npc = 5828 },   -- lv11
    { cle = "Le Rake",              biome = "savane",   famille = L("Félin"),             icone = "Ability_Hunter_Pet_Cat",          ech = 1.0, npc = 5807 },   -- lv10
    { cle = "Hurleur fantomatique", biome = "savane",   famille = L("Loup"),             icone = "Ability_Hunter_Pet_Wolf",         ech = 1.1, npc = 3056 },   -- lv12
    { cle = "Traqueur du crépuscule", biome = "savane",  famille = L("Félin"),            icone = "Ability_Hunter_Pet_Cat",          ech = 0.9, npc = 14430 },  -- lv9
    { cle = "Ombregriffe",          biome = "savane",   famille = L("Félin"),            icone = "Ability_Hunter_Pet_Cat",          ech = 1.1, npc = 2175 },   -- lv13
    { cle = "Matriarche trotteuse", biome = "savane",   famille = L("Échassier"),        icone = "Ability_Hunter_Pet_Tallstrider",  ech = 1.2, npc = 2172 },   -- lv20
    { cle = "Trigore le Flagelleur", biome = "savane",  famille = "Raptor",              icone = "Ability_Hunter_Pet_Raptor",       ech = 1.1, npc = 3652 },   -- lv19 élite
    { cle = "Gesharahan",           biome = "savane",   famille = L("Serpent des vents"), icone = "Ability_Hunter_Pet_WindSerpent", ech = 1.2, npc = 3398 },   -- lv20 élite
    { cle = "Vif-crins",            biome = "savane",   famille = L("Zèvre"),            icone = "Ability_Hunter_Pet_Boar",         ech = 1.1, npc = 5831 },   -- lv21 élite
    { cle = "Moissonneur silithide", biome = "savane",  famille = L("Silithide"),        icone = "Ability_Hunter_Pet_Scorpid",      ech = 0.8, npc = 3253 },   -- lv24
    { cle = "Vultros",             biome = "savane",   famille = L("Charognard"),        icone = "Ability_Hunter_Pet_Owl",          ech = 1.1, npc = 462 },    -- lv26
    { cle = "Brèchedent",          biome = "savane",   famille = L("Félin"),            icone = "Ability_Hunter_Pet_Cat",          ech = 1.2, npc = 2850 },   -- lv37 (palier)
    { cle = "Arash-ethis",         biome = "savane",   famille = L("Serpent des vents"), icone = "Ability_Hunter_Pet_WindSerpent", ech = 1.3, npc = 5349 },   -- lv49 (palier)
    { cle = "Uhk'loc",             biome = "savane",   famille = L("Gorille"),          icone = "Ability_Hunter_Pet_Gorilla",      ech = 1.3, npc = 6585 },   -- lv52 (palier)
    { cle = "Gruff",               biome = "savane",   famille = L("Gorille"),          icone = "Ability_Hunter_Pet_Gorilla",      ech = 1.3, npc = 6583 },   -- lv57 élite (palier)
    { cle = "Roi Mosh",            biome = "savane",   famille = "Raptor",              icone = "Ability_Hunter_Pet_Raptor",       ech = 1.4, npc = 6584 },   -- lv60 élite (palier)
    { cle = "Zaricotl",           biome = "savane",   famille = L("Kodo"),             icone = nil,                                ech = 1.4, npc = 2931 },   -- lv55 élite (palier)
    -- MARAIS
    { cle = "Noiremousse le Fétide", biome = "marais",  famille = L("Tortue"),           icone = "Ability_Hunter_Pet_Turtle",       ech = 0.9, npc = 3535 },   -- lv13
    { cle = "Mère Croc",           biome = "marais",   famille = L("Araignée"),         icone = "Ability_Hunter_Pet_Spider",       ech = 0.8, npc = 471 },    -- lv10
    { cle = "Limace bestiale",     biome = "marais",   famille = L("Élémentaire"),      icone = "Spell_Arcane_StarFire",           ech = 0.8, npc = 3295 },   -- lv19
    { cle = "Ressan le Harceleur", biome = "marais",   famille = L("Chauve-souris"),    icone = "Ability_Hunter_Pet_Owl",          ech = 0.9, npc = 10357 },  -- lv11
    { cle = "Sri'skulk",           biome = "marais",   famille = L("Araignée"),         icone = "Ability_Hunter_Pet_Spider",       ech = 0.8, npc = 10359 },  -- lv13
    { cle = "Krethis Shadowspinner", biome = "marais", famille = L("Araignée"),         icone = "Ability_Hunter_Pet_Spider",       ech = 0.9, npc = 12433 },  -- lv15
    { cle = "Ribchaser",           biome = "marais",   famille = "Murloc",              icone = nil,                                ech = 0.9, npc = 14271 },  -- lv17 (icône ? : mystère, comme Flagglemurk)
    { cle = "Squiddic",            biome = "marais",   famille = "Murloc",              icone = nil,                                ech = 0.9, npc = 14270 },  -- lv19
    { cle = "Creepthess",          biome = "marais",   famille = L("Araignée"),         icone = "Ability_Hunter_Pet_Spider",       ech = 1.0, npc = 14279 },  -- lv24
    { cle = "Mirelow",             biome = "marais",   famille = L("Élémentaire"),      icone = "Spell_Arcane_StarFire",           ech = 1.0, npc = 14424 },  -- lv25
    -- MONTAGNE
    { cle = "Uruson",              biome = "montagne", famille = L("Ours"),             icone = "Ability_Hunter_Pet_Bear",         ech = 0.9, npc = 14428 },  -- lv7
    { cle = "Grimmaw",             biome = "montagne", famille = L("Loup"),            icone = "Ability_Hunter_Pet_Wolf",         ech = 1.0, npc = 14429 },  -- lv11
    { cle = "Gorefang",            biome = "montagne", famille = L("Loup"),            icone = "Ability_Hunter_Pet_Wolf",         ech = 1.1, npc = 12431 },  -- lv13
    { cle = "Vieux Vile mâchoire", biome = "montagne", famille = L("Ours"),            icone = "Ability_Hunter_Pet_Bear",         ech = 1.2, npc = 12432 },  -- lv14
    { cle = "Lupos",               biome = "montagne", famille = L("Loup"),            icone = "Ability_Hunter_Pet_Wolf",         ech = 1.2, npc = 521 },    -- lv23
    { cle = "Shanda la Tisseuse",  biome = "montagne", famille = L("Araignée"),        icone = "Ability_Hunter_Pet_Spider",       ech = 1.0, npc = 14266 },  -- lv19
    { cle = "Seigneur Condar",     biome = "montagne", famille = L("Charognard"),     icone = "Ability_Hunter_Pet_Owl",          ech = 1.1, npc = 14268 },  -- lv15
    { cle = "Grand-père Arctikus", biome = "montagne", famille = L("Yéti"),           icone = "Ability_Hunter_Pet_Gorilla",      ech = 1.2, npc = 1260 },   -- lv11
    { cle = "Snarlmane",           biome = "montagne", famille = L("Yéti"),           icone = "Ability_Hunter_Pet_Gorilla",      ech = 1.3, npc = 1948 },   -- lv23
    { cle = "Gros Samras",         biome = "montagne", famille = L("Ours"),           icone = "Ability_Hunter_Pet_Bear",         ech = 1.2, npc = 14280 },  -- lv27
    { cle = "Bayne",               biome = "montagne", famille = L("Loup"),            icone = "Ability_Hunter_Pet_Wolf",         ech = 1.0, npc = 10356 },  -- lv10
    { cle = "Ursol'lok",           biome = "montagne", famille = L("Ours"),           icone = "Ability_Hunter_Pet_Bear",         ech = 1.3, npc = 12037 },  -- lv31 (palier)
    { cle = "Grogneur",            biome = "montagne", famille = L("Loup"),            icone = "Ability_Hunter_Pet_Wolf",         ech = 1.2, npc = 5356 },   -- lv42 (palier)
    { cle = "Vieux Grisebedaine",  biome = "montagne", famille = L("Ours"),           icone = "Ability_Hunter_Pet_Bear",         ech = 1.3, npc = 5352 },   -- lv43 (palier)
    { cle = "Olm la Sage",         biome = "montagne", famille = L("Hibou"),           icone = "Ability_Hunter_Pet_Owl",          ech = 1.1, npc = 14343 },  -- lv52 (palier)
    -- VOLCAN — palier 31-60 (novembre) : les rares de feu de la Gorge
    -- des Vents brûlants et des Steppes Ardentes (mhhuntdata.lua).
    -- Écartés : Smoldar/Fumar (élémentaire de TERRE), Shleipnarr (type
    -- incertain), golems et humanoïdes Dark Iron (règle : pas d'invention).
    { cle = "Rekk'tilac",        biome = "volcan", famille = L("Araignée"),    icone = "Ability_Hunter_Pet_Spider", ech = 0.8, npc = 8277 },   -- lv48 (palier)
    { cle = "Brûlar",            biome = "volcan", famille = L("Élémentaire"), icone = "Spell_Arcane_StarFire",     ech = 1.0, npc = 8281 },   -- lv49 (palier)
    { cle = "Gueule-du-trépas",   biome = "volcan", famille = L("Loup"),        icone = "Ability_Hunter_Pet_Wolf",   ech = 1.1, npc = 10077 },  -- lv53 (palier)
    { cle = "Lueur terrifiante",  biome = "volcan", famille = L("Élémentaire"), icone = "Spell_Arcane_StarFire",     ech = 1.0, npc = 10078 },  -- lv55 (palier)
    { cle = "Hematos",           biome = "volcan", famille = "Dragonnet",       icone = nil,                          ech = 1.3, npc = 8976 },   -- lv60 élite (palier)
    { cle = "Volchan",           biome = "volcan", famille = L("Élémentaire"), icone = "Spell_Arcane_StarFire",     ech = 1.2, npc = 10119 },  -- lv60 élite (palier)
}
-- Enregistrement : specimen + ordre d'affichage + vignette de gibier
for _, ex in ipairs(MHH_SPECIMENS_EXTRA) do
    MHH_SPECIMENS[ex.cle] = { famille = ex.famille, sansPixel = true }
    table.insert(MHH_SPECIMENS_ORDRE, ex.cle)
    if ex.icone and MHH_VIGNETTES then MHH_VIGNETTES[ex.cle] = ex.icone end
end

-- ENCLOS PAR BIOME : chaque pensionnaire vit dans le biome de son habitat.
-- Un enclos se DÉBLOQUE au fil du rang de guilde — le régisseur agrandit
-- le ranch. Le fond de l'enclos change avec le biome sélectionné.
MHH_ENCLOS = {
    { cle = "savane",   nom = L("Enclos de la savane"),   rang = 1,
      specimens = { "Humar le Seigneur hautain", "Takk le Bondisseur",
                    "Mazzranache", "Dishu", "Snort le Moqueur",
                    "Azzere la Lame-des-cieux" } },
      -- v0.120 : la savane gagne 3 candidats (rares non-élites) —
      -- Sarkoth vit en montagne depuis la v0.119l
    { cle = "marais",   nom = L("Enclos des marais"),     rang = 2,
      specimens = { "Flagglemurk le Cruel", "Naraxis",
                    "Veuve-sangsue", "Grand crocolisque du loch" } },
    { cle = "montagne", nom = L("Enclos des montagnes"), rang = 3,
      specimens = { "Capitaine Croc-Plat", "Bjarn", "Sarkoth",
                    "Timber" } },
    { cle = "volcan",   nom = L("Enclos du volcan"),     rang = 4,
      specimens = { "Snarlflare" } }, -- la bête de feu vit dans la lave
}
-- v0.122 : les candidats étendus rejoignent l'enclos de leur biome
for _, ex in ipairs(MHH_SPECIMENS_EXTRA) do
    for _, enc in ipairs(MHH_ENCLOS) do
        if enc.cle == ex.biome then
            table.insert(enc.specimens, ex.cle)
            break
        end
    end
end
-- Zone d'un spécimen (habitat) -> enclos de rattachement
MHH_ENCLOS_DU_SPECIMEN = {}
for _, enc in ipairs(MHH_ENCLOS) do
    for _, nom in ipairs(enc.specimens) do
        MHH_ENCLOS_DU_SPECIMEN[nom] = enc.cle
    end
end
-- Rang de guilde requis pour un enclos (par clé)
MHH_ENCLOS_RANG = {}
for i, enc in ipairs(MHH_ENCLOS) do MHH_ENCLOS_RANG[enc.cle] = enc.rang end
-- INDEX de chaque enclos dans la rangée du fond (v0.64 : le fond montre
-- les 4 enclos d'un coup, chacun ~1/4 de la largeur) — savane à gauche,
-- lave à droite, comme sur l'image. GLOBALE (limite 200 locales).
MHH_ENCLOS_INDEX = {}
for i, enc in ipairs(MHH_ENCLOS) do MHH_ENCLOS_INDEX[enc.cle] = i end

-- CAPACITÉ PAR ENCLOS (v0.119h) : au-delà, la capture est refusée
-- (message au chat) — il faut d'abord relâcher un pensionnaire.
-- La savane est la plus grande, le volcan n'accepte que la bête de feu.
MHH_CAPACITE_ENCLOS = {
    savane = 8, marais = 8, montagne = 8, volcan = 2,
} -- v0.122 : ranch v0.122 — le catalogue de candidats compte
  -- désormais 18 savane / 13 marais / 17 montagne / 1 volcan :
  -- le régisseur agrandit (8 places), à TOI de choisir qui garde
  -- (relâche possible sur la fiche pensionnaire)
  -- pensionnaires, la montagne 5 (plus de choix : le catalogue
  -- compte 6/4/3/7 candidats par biome, volcan 1+6 feu :
  -- aucun rare de feu <= 30 n'existe ailleurs (Hematos est 60)

-- ================================================================
-- v0.121 : RÉSOLUTION DE GRAPHIES. Le nom VU EN JEU peut différer de
-- la clé du spécimen (le data file donne « Snort la Moqueuse » comme
-- nom serveur, la clé est « Snort le Moqueur »). MHH_SpecimenDe(nom)
-- renvoie TOUJOURS la clé canonique du spécimen, depuis n'importe
-- quelle graphie connue (nom, nomEn, alias du data, ou graphie
-- principale apprise en jeu). La capture stocke les pensionnaires
-- sous cette clé : enclos, sprites et fiches restent cohérents.
-- ================================================================
MHH_SPECIMEN_CLE = {}
for cleSpec in pairs(MHH_SPECIMENS) do
    MHH_SPECIMEN_CLE[cleSpec] = cleSpec
end
if type(MHHuntData) == "table" then
    for _, e in ipairs(MHHuntData) do
        local cles, cible = {}, nil
        if e.nom then cles[#cles + 1] = e.nom end
        if e.nomEn then cles[#cles + 1] = e.nomEn end
        if type(e.alias) == "table" then
            for _, a in ipairs(e.alias) do cles[#cles + 1] = a end
        end
        -- Une des graphies de cette entrée EST une clé de spécimen :
        -- toutes ses graphies pointent alors vers cette clé.
        for _, cle in ipairs(cles) do
            if MHH_SPECIMENS[cle] then cible = cle break end
        end
        if cible then
            for _, c2 in ipairs(cles) do MHH_SPECIMEN_CLE[c2] = cible end
        end
    end
end
function MHH_SpecimenDe(nom)
    if type(nom) ~= "string" or nom == "" then return nil end
    local cle = MHH_SPECIMEN_CLE[nom]
    if cle then return cle end
    -- Repli : graphie principale apprise en jeu (ApprendreParId)
    local p = MHH_NOM_AFFICHAGE and MHH_NOM_AFFICHAGE[nom]
    if p and p ~= nom and MHH_SPECIMEN_CLE[p] then return MHH_SPECIMEN_CLE[p] end
    if MHH_SPECIMENS[nom] then return nom end
    return nil
end

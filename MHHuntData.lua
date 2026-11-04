-- MHHuntData.lua — base des rares (source : ForeverDB.net, données CMaNGOS
-- Vanilla, croisées avec le catalogue FR du carnet).
-- Ce fichier doit être chargé AVANT MHHunt.lua dans le .toc :
--     MHHuntData.lua
--     MHHunt.lua
--
-- Champs d'une entrée :
--   nomEn  = nom anglais (source ForeverDB)
--   nom    = nom FR exact en jeu — SEULES les entrées avec `nom` sont
--            fusionnées dans le carnet (les autres attendent confirmation)
--   alias  = autres graphies reconnues (trad. serveur incertaine)
--   zone   = habitat tel que renvoyé par GetZoneText() en jeu (client FR)
--   zoneEn = nom anglais standard de la zone (client EN). NB : les zones
--            CUSTOM du serveur (ex. Les Tarides = Tarides) auront peut-être
--            un autre nom sur un client EN — à vérifier à la sortie via
--            /hunt export. Noms FR = officiels Blizzard FR (Bois de la
--            Pénombre, Clairières de Tirisfal…), source Forever Era FR.
--   niveau = niveau du rare (ForeverDB)
--   elite  = true si rare élite (ForeverDB)
--   id     = NPC id (si connu — sert à l'identification auto par GUID)
--   x, y   = coordonnées approximatives de spawn
--   vu     = signalé vu sur Forever par ForeverDB
--
-- Entrées sans `nom` : documentation en attendant le nom FR exact. Un rare
-- inconnu du carnet reste auto-découvert au ciblage, rien ne casse.

MHHuntData = {
    -- DUROTAR
    { nomEn = "Geolord Mottle", nom = "Géomaîtresse Mottle", alias = { "Géomaîtresse Mouchette", "Géoseigneur Mottle" },
      id = 5822, zone = "Durotar", zoneEn = "Durotar", niveau = 9, elite = false, x = 47.0, y = 49.0 },
    { nomEn = "Warlord Kolkanis", id = 5808, nom = "Seigneur de guerre Kolkanis", vu = true,
      zone = "Durotar", zoneEn = "Durotar", niveau = 9, elite = false },
    { nomEn = "Watch Commander Zalaphil", nom = "Commandant de la garde Zalaphil", alias = { "Commandant de guet Zalaphil" },
      id = 5826, zone = "Durotar", zoneEn = "Durotar", niveau = 9, elite = false, x = 59.0, y = 55.0 },
    { nomEn = "Captain Flat Tusk", nom = "Capitaine Plate-défense", alias = { "Capitaine Croc-Plat" },
      id = 5823, zone = "Durotar", zoneEn = "Durotar", niveau = 11, elite = true, x = 43.0, y = 50.0 },
    { nomEn = "Death Flayer", nom = "Écorcheur mortel", alias = { "Flagelleur de la mort" },
      id = 5828, zone = "Durotar", zoneEn = "Durotar", niveau = 11, elite = false, x = 39.0, y = 69.0 },
    { nomEn = "Felweaver Scornn", nom = "Gangretisseur Scornn", alias = { "Tisse-gangrène Scornn" }, vu = true,
      id = 5824, zone = "Durotar", zoneEn = "Durotar", niveau = 11, elite = true, x = 54.0, y = 10.0 },
    { nomEn = "Dishu", id = 5865, nom = "Dishu", zone = "Durotar", zoneEn = "Durotar", niveau = 13, elite = false },
    { nomEn = "Rathorian", id = 3470, nom = "Rathorian", zone = "Durotar", zoneEn = "Durotar", niveau = 15, elite = false },
    { nomEn = "Sarkoth", id = 3281, nom = "Sarkoth", zone = "Durotar", zoneEn = "Durotar", niveau = 5, elite = false },

    -- MULGORE
    { nomEn = "Mazzranache", nom = "Mazzranache", id = 3068,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 9, elite = false, x = 45.0, y = 40.0 },
    { nomEn = "Snagglespear", nom = "Travépieu", id = 5786,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 9, elite = false, x = 52.0, y = 42.0 },
    { nomEn = "The Rake", nom = "Le Rake", alias = { "Le Rateau" }, id = 5807,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 10, elite = false, x = 48.0, y = 16.0 },
    { nomEn = "Enforcer Emilgund", nom = "Massacreur Emilgund", alias = { "Exécutrice Emilgund" }, id = 5787,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 11, elite = false, x = 33.0, y = 48.0 },
    { nomEn = "Sister Hatelash", nom = "Sœur Cinglehaine", alias = { "Sœur Haine-Coups", "Soeur Cinglehaine" }, id = 5785,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 11, elite = true, x = 36.0, y = 20.0 },
    { nomEn = "Ghost Howl", nom = "Hurleur fantomatique", alias = { "Hurlement fantôme" }, id = 3056,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 12, elite = false, x = 31.0, y = 39.0 },
    { nomEn = "Geopriest Gukk'rok", nom = "Géoprêtresse Gukk'rok", alias = { "Géopêtresse Gukk'rok", "Géoprêtre Gukk'rok" }, id = 5863,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 19, elite = false },
    { nomEn = "Swinegart Spearhide", nom = "Peau-piquante Swinegart", alias = { "Swinegart Peau-de-lance" }, id = 5864,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 22, elite = true },

    -- GLADES DE TIRISFAL
    { nomEn = "Lost Soul", id = 1531, nom = "Ame égarée", alias = { "Âme perdue", "Âme égarée" },
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 6, elite = false },
    { nomEn = "Farmer Solliden", id = 1936, nom = "Fermier de Solliden", alias = { "Fermier Solliden" },
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 8, elite = false },
    { nomEn = "Tormented Spirit", id = 1533, nom = "Esprit tourmenté",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 8, elite = false },
    { nomEn = "Bayne", id = 10356, nom = "Bayne", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 10, elite = false },
    { nomEn = "Muad", id = 1910, nom = "Muad", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 10, elite = false },
    { nomEn = "Deeb", id = 1911, nom = "Deeb", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 12, elite = false },
    { nomEn = "Fellicent's Shade", id = 10358, nom = "Ombre de Fellicent",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 12, elite = false },
    { nomEn = "Ressan the Needler", id = 10357, nom = "Ressan le Harceleur", alias = { "Ressan le Piqueur" },
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 11, elite = false },
    { nomEn = "Sri'skulk", id = 10359, nom = "Sri'skulk", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 13, elite = false },
    { nomEn = "Krethis Shadowspinner", id = 12433, nom = "Krethis Shadowspinner", alias = { "Krethis Tisse-ombre" },
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 15, elite = false },

    -- TELDRASSIL
    { nomEn = "Threggil", id = 14432, nom = "Threggil", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 6, elite = false },
    { nomEn = "Uruson", id = 14428, nom = "Uruson", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 7, elite = false },
    { nomEn = "Fury Shelda", id = 14431, nom = "Furie Shelda", alias = { "Shelda la Furieuse" }, zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 8, elite = false },
    { nomEn = "Duskstalker", id = 14430, nom = "Traqueur du crépuscule", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 9, elite = false },
    { nomEn = "Blackmoss the Fetid", id = 3535, nom = "Noiremousse le Fétide", alias = { "Moussemois le Fétide" }, zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 13, elite = false },
    { nomEn = "Grimmaw", id = 14429, nom = "Grimmaw", -- nom identique en FR (JudgeHype Classic)
      zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 11, elite = false },

    -- SOMBRERIVAGE (Darkshore)
    { nomEn = "Shadowclaw", id = 2175, nom = "Ombregriffe", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 13, elite = false },
    { nomEn = "Licillin", id = 2191, nom = "Licillin", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 14, elite = false },
    { nomEn = "Lord Sinslayer", id = 7017, nom = "Seigneur Salvassio", alias = { "Seigneur Tueur-de-péchés" }, zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 15, elite = false },
    { nomEn = "Carnivous the Breaker", id = 2186, nom = "Carnivore le Casseur", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 16, elite = false },
    { nomEn = "Flagglemurk the Cruel", id = 7015, nom = "Flagglemurk le Cruel", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 16, elite = false },
    { nomEn = "Lady Moongazer", id = 2184, nom = "Dame Moongazer", alias = { "Dame Regardelune" }, zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 17, elite = false },
    { nomEn = "Firecaller Radison", id = 2192, nom = "Flamboyeur Radison", alias = { "Invocateur du feu Radison" }, zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 19, elite = false },
    { nomEn = "Lady Vespira", id = 7016, nom = "Dame Vespira", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 22, elite = false },
    { nomEn = "Strider Clutchmother", id = 2172, nom = "Matriarche trotteuse", alias = { "Mère de couvée des échassiers" }, zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 20, elite = false },

    -- BRACHLAND (The Barrens)
    { nomEn = "Elder Mystic Razorsnout", id = 3270, nom = "Ancienne mystique Tranchegroin", alias = { "Ancien mystique Museau-rasoir" }, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 15, elite = true },
    { nomEn = "Stonearm", id = 5837, nom = "Bras-de-pierre", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 15, elite = false },
    { nomEn = "Brokespear", id = 5838, nom = "Brokespear", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 17, elite = false },
    { nomEn = "Snort the Heckler", id = 5829, nom = "Snort la Moqueuse", alias = { "Snort le Moqueur" }, vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 17, elite = false },
    { nomEn = "Rocklance", nom = "Rochelance", alias = { "Lance-de-roche" }, id = 5841, vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 17, elite = true, x = 55.0, y = 42.0 },
    { nomEn = "Engineer Whirleygig", id = 5836, nom = "Ingénieur Whirleygig", alias = { "Ingénieur Tourniquet" }, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = false },
    { nomEn = "Foreman Grills", id = 5835, nom = "Contremaître Grills", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = false },
    { nomEn = "Sludge Beast", id = 3295, nom = "Limace bestiale", alias = { "Bête de boue" }, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = false },
    { nomEn = "Takk the Leaper", nom = "Takk le Bondisseur", id = 5842,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = true, x = 63.0, y = 37.0 },
    { nomEn = "Trigore the Lasher", nom = "Trigore le Flagelleur", id = 3652, -- CONFIRMÉ (fiche JudgeHype) — trad. JudgeHype Classic FR
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = true },
    { nomEn = "Boahn", id = 3672, nom = "Boahn", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 20, elite = true },
    { nomEn = "Gesharahan", id = 3398, nom = "Gesharahan", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 20, elite = true },
    { nomEn = "Swiftmane", id = 5831, nom = "Vif-crins", alias = { "Flinkmähne", "Vif-Crinière" },
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 21, elite = true },
    { nomEn = "Humar the Pridelord", nom = "Humar le Fier", alias = { "Humar le Seigneur hautain" }, vu = true, id = 5850, -- id corrigé : 5847 = Heggin Stonewhisker
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 23, elite = true, x = 27.0, y = 33.0 },
    { nomEn = "Digger Flameforge", nom = "Terrassier Flameforge", alias = { "Fossoyeur Forgeflamme" }, id = 5849,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false, x = 66.0, y = 44.0 },
    { nomEn = "Hannah Bladeleaf", id = 5799, nom = "Hannah Feuillelame", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = true },
    { nomEn = "Heggin Stonewhisker", id = 5847, nom = "Heggin Stonewhisker", alias = { "Heggin Museau-de-pierre" }, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false },
    { nomEn = "Marcus Bel", id = 5800, nom = "Marcus Bel", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = true },
    { nomEn = "Silithid Harvester", nom = "Moissonneur silithide", alias = { "Cueilleur silithide" }, id = 3253,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false, x = 47.0, y = 87.0 },
    { nomEn = "Thunderstomp", id = 5832, nom = "Grondeterre", alias = { "Pietinement-tonnerre" }, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false },
    { nomEn = "Aean Swiftriver", id = 5797, nom = "Aean Swiftriver", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 25, elite = true },
    { nomEn = "Azzere the Skyblade", nom = "Azzere la lame céleste", alias = { "Azzere la Lame-des-cieux" }, id = 5834,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 25, elite = false, x = 41.0, y = 14.0 },
    { nomEn = "Malgin Barleybrew", nom = "Malgin Barleybrew", alias = { "Malgin Brasse-d'orge" }, id = 5848,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 25, elite = false, x = 54.0, y = 46.0 },
    { nomEn = "Hagg Taurenbane", id = 5859, nom = "Hagg Taurenbane", alias = { "Hagg Fléau-des-taurens" }, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 26, elite = true },
    { nomEn = "Brontus", id = 5827, nom = "Brontus", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = true },
    { nomEn = "Captain Gerogg Hammertoe", id = 5851, nom = "Capitaine Gerogg Hammertoe", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = true },
    { nomEn = "Harb Foulmountain", id = 14426, nom = "Harb Foulmountain", alias = { "Harb Montagne-fétide" },
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = false },
    { nomEn = "Thora Feathermoon", id = 5798, nom = "Thora Feathermoon", alias = { "Thora Plume-de-lune" }, vu = true,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = true },

    -- SERRES-ROCHEUSES (Stonetalon)
    { nomEn = "Sister Rathtalon", id = 5830, nom = "Sœur Griffe-de-rat", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 19, elite = true },
    { nomEn = "Taskmaster Whipfang", id = 5932, nom = "Sous-chef Fouettecroc", alias = { "Chef de tâche Croc-fouet" }, zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 22, elite = true },
    { nomEn = "Foreman Rigger", id = 5931, nom = "Contremaître Rigger", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 24, elite = true },
    { nomEn = "Pridewing Patriarch", id = 4015, nom = "Patriarche Aile-fière", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 25, elite = false },
    { nomEn = "Sentinel Amarassan", id = 5916, nom = "Sentinelle Amarassan", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 27, elite = true },
    { nomEn = "Sorrow Wing", id = 5928, nom = "Ailes du désespoir", alias = { "Aile-de-chagrin" }, zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 27, elite = true },
    { nomEn = "Sister Riven", id = 5930, nom = "Sœur Riven", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 28, elite = true },
    { nomEn = "Brother Ravenoak", id = 5915, nom = "Frère Ravenoak", alias = { "Frère Chêneravin" }, zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 29, elite = true },
    { nomEn = "Vengeful Ancient", id = 4030, nom = "Ancien vengeur", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 29, elite = false },
    { nomEn = "Nal'taszar", id = 4066, nom = "Nal'taszar", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 30, elite = true },

    -- ORNEVAL (Ashenvale)
    { nomEn = "Apothecary Falthis", id = 3735, nom = "Apothicaire Falthis", zone = "Orneval", zoneEn = "Ashenvale", niveau = 22, elite = false },
    { nomEn = "Lady Vespia", id = 10559, nom = "Dame Vespia", zone = "Orneval", zoneEn = "Ashenvale", niveau = 22, elite = false },
    { nomEn = "Mist Howler", id = 10644, nom = "Hurleur des brumes", alias = { "Hurle-brume" }, zone = "Orneval", zoneEn = "Ashenvale", niveau = 22, elite = false },
    { nomEn = "Mugglefin", id = 10643, nom = "Mugglefin", zone = "Orneval", zoneEn = "Ashenvale", niveau = 23, elite = false },
    { nomEn = "Branch Snapper", id = 10641, nom = "Brise-branche", alias = { "Casse-branche" }, zone = "Orneval", zoneEn = "Ashenvale", niveau = 25, elite = false },
    { nomEn = "Rorgish Jowl", id = 10639, nom = "Rorgish Jowl", zone = "Orneval", zoneEn = "Ashenvale", niveau = 25, elite = false },
    { nomEn = "Akkrilus", id = 3773, nom = "Akkrilus", zone = "Orneval", zoneEn = "Ashenvale", niveau = 26, elite = false },
    { nomEn = "Eck'alom", id = 10642, nom = "Eck'alom", zone = "Orneval", zoneEn = "Ashenvale", niveau = 27, elite = false },
    { nomEn = "Oakpaw", id = 10640, nom = "Chênepatte", alias = { "Patte-de-chêne" }, zone = "Orneval", zoneEn = "Ashenvale", niveau = 27, elite = false },

    -- FORÊT DES PINS-ARGENTÉS (Silverpine)
    { nomEn = "Gorefang", id = 12431, nom = "Gorefang", vu = true, zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 13, elite = false },
    { nomEn = "Old Vicejaw", id = 12432, nom = "Vieux Vile mâchoire", alias = { "Vieux Vicejaw" }, zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 14, elite = false },
    { nomEn = "Dalaran Spellscribe", id = 1920, nom = "Copiste de Dalaran", alias = { "Scribe des sorts de Dalaran" }, zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 21, elite = false },
    { nomEn = "Ravenclaw Regent", id = 2283, nom = "Régent Ravenclaw", alias = { "Régent Serre-corbeau" }, zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 22, elite = false },

    -- COMTÉ DE L'ORNE (Elwynn)
    { nomEn = "Morgaine the Sly", id = 99, nom = "Morgaine la rusée", alias = { "Morgaine la Rusée" }, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 10, elite = false },
    { nomEn = "Mother Fang", id = 471, nom = "Mère Croc", vu = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 10, elite = false },
    { nomEn = "Narg the Taskmaster", id = 79, nom = "Narg le Sous-chef", alias = { "Narg le Chef-de-tâche" }, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 10, elite = false },
    { nomEn = "Thuros Lightfingers", id = 61, nom = "Thuros Doigts-agiles", alias = { "Thuros Doigts-légers" }, vu = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 11, elite = false },
    { nomEn = "Fedfennel", id = 472, nom = "Fedfennel", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 12, elite = false },
    { nomEn = "Gruff Swiftbite", id = 100, nom = "Gruff Mord-vite", alias = { "Gruff Morsure-vive" }, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 12, elite = false },
    { nomEn = "Lupos", id = 521, nom = "Lupos", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 23, elite = false },

    -- MARCHES DE L'OUEST (Westfall)
    { nomEn = "Master Digger", id = 1424, nom = "Maître Terrassier", alias = { "Maître Fossoyeur" }, zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 15, elite = false },
    { nomEn = "Slark", id = 519, nom = "Slark", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 15, elite = false },
    { nomEn = "Brainwashed Noble", nom = "Noble manipulé", id = 596, -- CONFIRMÉ (fiche JudgeHype) — trad. JudgeHype Classic FR
      zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 18, elite = true },
    { nomEn = "Marisa du'Paige", id = 599, nom = "Marisa du'Paige", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 18, elite = true },
    { nomEn = "Sergeant Brashclaw", id = 506, nom = "Sergent Brashclaw", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 18, elite = false },
    { nomEn = "Brack", id = 520, nom = "Brack", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 19, elite = false },
    { nomEn = "Leprithus", id = 572, nom = "Leprithus", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 19, elite = false },
    { nomEn = "Foe Reaper 4000", id = 573, nom = "Foe Reaper 4000", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 20, elite = false },
    { nomEn = "Vultros", id = 462, nom = "Vultros", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 26, elite = false },

    -- LES CARMINES (Redridge)
    { nomEn = "Ribchaser", id = 14271, nom = "Ribchaser", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 17, elite = false },
    { nomEn = "Snarlflare", id = 14272, nom = "Snarlflare", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 18, elite = false },
    { nomEn = "Squiddic", id = 14270, nom = "Squiddic", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 19, elite = false },
    { nomEn = "Seeker Aqualon", id = 14269, nom = "Aqualon le Chercheur", alias = { "Chercheur Aqualon" }, zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 21, elite = false },
    { nomEn = "Boulderheart", id = 14273, nom = "Rochecoeur", alias = { "Coeur-de-rocher" }, zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 25, elite = false },
    { nomEn = "Chatter", id = 35610, nom = "Chat", alias = { "Bavard" }, zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 23, elite = false },
    { nomEn = "Kazon", id = 584, nom = "Kazon", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 27, elite = false },
    { nomEn = "Rohh the Silent", id = 947, nom = "Rohh le silencieux", alias = { "Rohh le Silencieux" }, zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 26, elite = false },

    -- COLLINES DES CHAGRINS (Duskwood)
    { nomEn = "Naraxis", id = 574, nom = "Naraxis", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 27, elite = false },

    -- CONTREFORTS DE HAUTEBRANDE (Hillsbrad)
    { nomEn = "Creepthess", id = 14279, nom = "Creepthess",
      zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 24, elite = false },
    { nomEn = "Ro'Bark", id = 14278, nom = "Ro'Bark",
      zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 28, elite = false },
    { nomEn = "Tamra Stormpike", id = 14275, nom = "Tamra Stormpike", zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 28, elite = true },
    { nomEn = "Scargil", id = 14276, nom = "Scargil", zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 30, elite = false },

    -- LOCH MODAN
    { nomEn = "Lord Condar", id = 14268, nom = "Seigneur Condar", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 15, elite = false },
    { nomEn = "Emogg the Crusher", id = 14267, nom = "Emogg le Broyeur", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 19, elite = true },
    { nomEn = "Magosh", id = 1399, nom = "Magosh", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 21, elite = false },
    { nomEn = "Shanda the Spinner", id = 14266, nom = "Shanda la Tisseuse", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 19, elite = false },
    { nomEn = "Boss Galgosh", id = 1398, nom = "Boss Galgosh", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 22, elite = false },
    { nomEn = "Large Loch Crocolisk", id = 2476, nom = "Grand crocilisque du loch", alias = { "Grand crocolisque du loch" }, zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 22, elite = false },
    { nomEn = "Grizlak", id = 1425, nom = "Grizlak", -- nom identique en FR (JudgeHype Classic)
      zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 15, elite = false },

    -- DUN MOROGH
    { nomEn = "Edan the Howler", id = 1137, nom = "Edan le Hurleur", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 9, elite = false },
    { nomEn = "Timber", id = 1132, nom = "Timber", vu = true, zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 10, elite = false },
    { nomEn = "Gibblewilt", id = 8503, nom = "Gibblewilt", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 11, elite = false },
    { nomEn = "Great Father Arctikus", id = 1260, nom = "Grand-père Arctikus", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 11, elite = false },
    { nomEn = "Hammerspine", id = 1119, nom = "Hammerspine", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 12, elite = false },
    { nomEn = "Bjarn", id = 1130, nom = "Bjarn", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 12, elite = false },

    -- LES PALUNS (Wetlands)
    { nomEn = "Ma'ruk Wyrmscale", id = 2090, nom = "Ma'ruk Wyrmscale", alias = { "Ma'ruk Écaille-de-ver" }, vu = true, zone = "Les Paluns", zoneEn = "Wetlands", niveau = 23, elite = false },
    { nomEn = "Gnawbone", id = 14425, nom = "Gnawbone", zone = "Les Paluns", zoneEn = "Wetlands", niveau = 24, elite = false },
    { nomEn = "Leech Widow", id = 1112, nom = "Veuve sanguine", alias = { "Veuve-sangsue" }, zone = "Les Paluns", zoneEn = "Wetlands", niveau = 24, elite = false },
    { nomEn = "Mirelow", id = 14424, nom = "Mirelow", zone = "Les Paluns", zoneEn = "Wetlands", niveau = 25, elite = false },
    { nomEn = "Garneg Charskull", id = 2108, nom = "Garneg Charskull", alias = { "Garneg Crâne-brûlé" }, zone = "Les Paluns", zoneEn = "Wetlands", niveau = 29, elite = false },
    { nomEn = "Dragonmaw Battlemaster", nom = "Maître de guerre Dragonmaw", id = 1037, -- CONFIRMÉ (fiche JudgeHype) — trad. JudgeHype Classic FR
      zone = "Les Paluns", zoneEn = "Wetlands", niveau = 30, elite = false },
    { nomEn = "Razormaw Matriarch", nom = "Matriarche tranchegueules", id = 1140, -- CONFIRMÉ (fiche JudgeHype) — trad. JudgeHype Classic FR (npc 1140, niveau 31)
      zone = "Les Paluns", zoneEn = "Wetlands", niveau = 31, elite = false },
    { nomEn = "Sludginn", id = 14433, nom = "Sludginn",
      zone = "Les Paluns", zoneEn = "Wetlands", niveau = 30, elite = false },
    -- Mob custom Forever (hors ForeverDB) : ID fourni par une source externe,
    -- à vérifier en jeu.
    { nomEn = "Nightveiled Rotheap", nom = "Rotheap", alias = { "Nightveiled Rotheap" },
      -- id retiré : 14222 est celui d'Araga (Montagnes d'Alterac) ; identification par le nom
      zone = "Les Paluns", zoneEn = "Wetlands", niveau = 20, elite = true, x = 48.0, y = 39.0 },

    -- MONTAGNES D'ALTERAC
    { nomEn = "Rot Hide Bruiser", id = 1944, nom = "Cogneur Poil-Putride", alias = { "Bagarreur Peau-putride" }, -- FR à confirmer
      zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 22, elite = false },
    { nomEn = "Jimmy the Bleeder", id = 14281, nom = "Jimmy le Saignant", zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 23, elite = false },
    { nomEn = "Snarlmane", id = 1948, nom = "Snarlmane", zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 23, elite = false },
    { nomEn = "Lo'Grosh", id = 2453, nom = "Lo'Grosh", zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 28, elite = true },

    -- HAUTES-TERRES D'ARATHI
    { nomEn = "Big Samras", id = 14280, nom = "Gros Samras",
      zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 27, elite = false },

    -- MILLE POINTES
    { nomEn = "Gibblesnik", id = 14427, nom = "Gibblesnik", zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 28, elite = false },

    -- ============================================================
    -- PALIER 31-60 (sortie du serveur, novembre).
    -- Source : The Forever Era / wowclassicforever.info (données
    -- Classic CMaNGOS croisées Forever, 331 rares monde ouvert).
    -- Noms FR = traductions vanilla standard, marquées aConfirmer =
    -- true : elles fusionnent dans le carnet par nom, MAIS restent à
    -- valider en jeu à la sortie (/hunt export + /hunt add). Les noms
    -- de ZONES sont les FR standards — le serveur utilise des
    -- traductions custom (cf. « Les Tarides ») : à vérifier avec
    -- GetZoneText() à la sortie. Les ids NPC manquants seront
    -- collectés automatiquement à la découverte (champ id).
    -- ============================================================

    -- ORNEVAL (31-32)
    { nomEn = "Terrowulf Packlord", nom = "Chef de meute Frayeloup", alias = { "Chef de meute Terrowulf", "Terrowulf Chef-de-meute" }, id = 3792, zone = "Orneval", zoneEn = "Ashenvale", niveau = 31, elite = false },
    { nomEn = "Ursol'lok", nom = "Ursol'lok", id = 12037, zone = "Orneval", zoneEn = "Ashenvale", niveau = 31, elite = false },
    { nomEn = "Prince Raze", nom = "Prince Raze", id = 10647, zone = "Orneval", zoneEn = "Ashenvale", niveau = 32, elite = false },

    -- DÉSOLACE
    { nomEn = "Prince Kellen", nom = "Prince Kellen", id = 14225, zone = "Désolace", zoneEn = "Desolace", niveau = 33, elite = false },
    { nomEn = "Giggler", nom = "Glousse", alias = { "Glousseur" }, id = 14228, zone = "Désolace", zoneEn = "Desolace", niveau = 34, elite = false },
    { nomEn = "Accursed Slitherblade", nom = "Ondulame maudit", alias = { "Lame-rameuse maudite", "Slitherblade maudit" }, id = 14229, zone = "Désolace", zoneEn = "Desolace", niveau = 35, elite = false },
    { nomEn = "Hissperak", nom = "Hissperak", id = 14227, zone = "Désolace", zoneEn = "Desolace", niveau = 37, elite = false },
    { nomEn = "Kaskk", nom = "Kaskk", id = 14226, zone = "Désolace", zoneEn = "Desolace", niveau = 40, elite = false },
    { nomEn = "Cursed Centaur", nom = "Centaure maudit", id = 11688, zone = "Désolace", zoneEn = "Desolace", niveau = 43, elite = false },

    -- MILLE POINTES (31+)
    { nomEn = "Achellios the Banished", nom = "Achellios le Banni", id = 5933, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 31, elite = false },
    { nomEn = "Heartrazor", nom = "Tranchecoeur", id = 5934, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 32, elite = true },
    { nomEn = "Vile Sting", nom = "Dardeur", id = 5937, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 35, elite = true },
    { nomEn = "Silithid Ravager", nom = "Ravageur silithide", id = 4132, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 36, elite = false },
    { nomEn = "Ironeye the Invincible", nom = "Ferregard l'Invincible", alias = { "Ironeye l'Invincible",  "Œil-de-fer l'Invincible" }, id = 5935, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 37, elite = true },

    -- BRACHLAND (les Tarides — nom FR custom du serveur)
    { nomEn = "Ambassador Bloodrage", nom = "Ambassadeur Ragesang", alias = { "Ambassadeur Sanglerage" }, id = 7895, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 36, elite = true },
    { nomEn = "Darkmist Widow", nom = "Veuve de Sombrebrume", alias = { "Veuve de la Brume-sombre" }, id = 4380, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 40, elite = false },

    -- COLLINES DES CHAGRINS (Duskwood — nom FR serveur, cf. Naraxis)
    { nomEn = "Lord Malathrom", nom = "Seigneur Malathrom", id = 503, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 31, elite = false },
    { nomEn = "Commander Felstrom", nom = "Commandant Gangretrombe", alias = { "Commandant Felstrom" }, id = 771, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 32, elite = false },
    { nomEn = "Fenros", nom = "Fenros", id = 507, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 32, elite = false },
    { nomEn = "Nefaru", nom = "Nefaru", id = 534, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 34, elite = false },

    -- CONTREFORTS DE HAUTEBRANDE
    { nomEn = "Lady Zephris", nom = "Dame Zephris", id = 14277, zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 33, elite = false },

    -- MONTAGNES D'ALTERAC (32+)
    { nomEn = "Cranky Benj", nom = "Benj le teigneux", alias = { "Benj le Bougon", "Benj l'Aigri" }, id = 14223, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 32, elite = false },
    { nomEn = "Araga", nom = "Araga", id = 14222, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 35, elite = false },
    { nomEn = "Gravis Slipknot", nom = "Gravis Slipknot", alias = { "Gravis Noeud-coulant" }, id = 14221, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 36, elite = false },
    { nomEn = "Skhowl", nom = "Grybou", id = 2452, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 36, elite = false },
    { nomEn = "Stone Fury", nom = "Furie-de-pierre", alias = { "Furie de pierre" }, id = 2258, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 37, elite = false },
    { nomEn = "Narillasanz", nom = "Narillasanz", id = 2447, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 44, elite = true },

    -- HAUTES-TERRES D'ARATHI
    { nomEn = "Singer", nom = "Singer", id = 2600, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 34, elite = false },
    { nomEn = "Kovork", nom = "Kovork", id = 2603, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 36, elite = false },
    { nomEn = "Nimar the Slayer", nom = "Nimar le Pourfendeur", alias = { "Nimar le Tueur" }, id = 2606, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 37, elite = false },
    { nomEn = "Darbel Montrose", nom = "Darbel Montrose", id = 2598, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 39, elite = true },
    { nomEn = "Molok the Crusher", nom = "Molok l'Anéantisseur", alias = { "Molok le Broyeur", "Molok l’Anéantisseur" }, id = 2604, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 39, elite = false },
    { nomEn = "Ruul Onestone", nom = "Ruul Onestone", id = 2602, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 39, elite = true },
    { nomEn = "Geomancer Flintdagger", nom = "Géomancien Dague-de-silex", alias = { "Géomancien Silexdague", "Géomancien Silex-dague" }, id = 2609, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 40, elite = false },
    { nomEn = "Zalas Witherbark", nom = "Zalas Witherbark", alias = { "Zalas Fanécorce" }, id = 2605, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 40, elite = false },
    { nomEn = "Prince Nazjak", nom = "Prince Nazjak", id = 2779, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 41, elite = false },
    { nomEn = "Foulbelly", nom = "Foulbelly", alias = { "Ventre-Immonde", "Ventre-immonde" }, id = 2601, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 42, elite = true },

    -- TERRES INGRATES (Badlands)
    { nomEn = "War Golem", nom = "Golem de guerre", id = 2751, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 36, elite = false },
    { nomEn = "Broken Tooth", nom = "Brèchedent", alias = { "Dent-Cassée", "Croc-Cassé" }, id = 2850, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 37, elite = false },
    { nomEn = "Digmaster Shovelphlange", nom = "Maître des fouilles Shovelphlange", alias = { "Maître des fouilles Bêchephlange" }, id = 7057, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 38, elite = true },
    { nomEn = "Shadowforge Commander", nom = "Commandant Ombreforge", id = 2744, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 40, elite = false },
    { nomEn = "Siege Golem", nom = "Golem de siège", id = 2749, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 40, elite = true },
    { nomEn = "7:XT", nom = "7:XT", id = 14224, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 41, elite = false },
    { nomEn = "Anathemus", nom = "Anathemus", id = 2754, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 45, elite = true },
    { nomEn = "Rumbler", nom = "Grondeur du désert", id = 11746, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 45, elite = false },
    { nomEn = "Zaricotl", nom = "Zaricotl", id = 2931, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 55, elite = true },

    -- MARÉCAGE D'ÂPREFANGE (Dustwallow)
    { nomEn = "Drogoth the Roamer", nom = "Dorgoth le Vagabond", alias = { "Drogoth l'Errant" }, id = 14231, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 37, elite = false },
    { nomEn = "Burgle Eye", nom = "Pique-les-yeux", id = 14230, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 38, elite = false },
    { nomEn = "Dart", nom = "Flèche", id = 14232, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 38, elite = false },
    { nomEn = "Ripscale", nom = "Arrachécaille", id = 14233, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 39, elite = false },
    { nomEn = "Hayoc", nom = "Hayoc", id = 14234, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 41, elite = false },
    { nomEn = "Oozeworm", nom = "Ver de limon", id = 14237, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 42, elite = false },
    { nomEn = "The Rot", nom = "La Pourriture", id = 14235, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 43, elite = false },
    { nomEn = "Lord Angler", nom = "Seigneur Angler", alias = { "Seigneur Pêche-à-la-ligne" }, id = 14236, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 44, elite = false },
    { nomEn = "Brimgore", nom = "Soufresang", id = 4339, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 45, elite = true },

    -- MARAIS DES CHAGRINS (Swamp of Sorrows)
    { nomEn = "Lost One Cook", nom = "Cuisinier perdu", alias = { "Cuisinier des Perdus" }, id = 1106, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 37, elite = false },
    { nomEn = "Lost One Chieftain", nom = "Chef Perdu", alias = { "Chef des Perdus" }, id = 763, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 39, elite = false },
    { nomEn = "Molt Thorn", nom = "Rougeronce", id = 14448, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 42, elite = false },
    { nomEn = "Gilmorian", nom = "Gilmorian", id = 14447, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 43, elite = false },
    { nomEn = "Lord Captain Wyrmak", nom = "Seigneur-capitaine Wyrmak", alias = { "Seigneur capitaine Wyrmak", "Capitaine-seigneur Wyrmak" }, id = 14445, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 45, elite = true },
    { nomEn = "Jade", nom = "Jade", id = 1063, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 47, elite = true },
    { nomEn = "Veyzhak the Cannibal", nom = "Veyzhak le Cannibale", id = 5399, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 48, elite = true },
    { nomEn = "Zekkis", nom = "Zekkis", id = 5400, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 48, elite = true },

    -- VALLÉE DE STRANGLERONCE
    { nomEn = "Gluggle", nom = "Gluggle", id = 14487, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 37, elite = false },
    { nomEn = "Roloch", nom = "Roloch", id = 14488, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 38, elite = false },
    { nomEn = "Kurmokk", nom = "Kurmokk", id = 14491, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 42, elite = false },
    { nomEn = "Verifonix", nom = "Verifonix", id = 14492, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 42, elite = false },
    { nomEn = "Mosh'Ogg Butcher", nom = "Boucher Mosh'Ogg", id = 723, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 44, elite = true },
    { nomEn = "Rippa", nom = "Rippa", id = 14490, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 44, elite = false },
    { nomEn = "Lord Sakrasis", nom = "Seigneur Sakrasis", id = 2541, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 45, elite = false },
    { nomEn = "Scale Belly", nom = "Ventrécaille", id = 1552, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 45, elite = false },

    -- LES HINTERLANDS
    { nomEn = "Old Cliff Jumper", nom = "Vieux Saute-falaise", alias = { "Vieux Bondisseur", "Vieux Sauteur-de-falaises" }, id = 8211, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 42, elite = false },
    { nomEn = "Zul'arek Hatefowler", nom = "Zul'arek Volaillaîne", alias = { "Zul'arek Haineplume" }, id = 8219, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 43, elite = false },
    { nomEn = "Razortalon", nom = "Trancheserre", id = 8210, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 44, elite = false },
    { nomEn = "Witherheart the Stalker", nom = "Flétricoeur le Traqueur", alias = { "Witherheart le Traqueur" }, id = 8218, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 45, elite = false },
    { nomEn = "Retherokk the Berserker", nom = "Retherokk le Berserk", alias = { "Retherokk le Berserker" }, id = 8216, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 48, elite = false },
    { nomEn = "Jalinde Summerdrake", nom = "Jalinde Summerdrake", id = 8214, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 49, elite = false },
    { nomEn = "The Reak", nom = "Le Jonc", alias = { "Le Reak" }, id = 8212, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 49, elite = false },
    { nomEn = "Grimungous", nom = "Grimungous", id = 8215, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 50, elite = true },
    { nomEn = "Ironback", nom = "Dos-de-fer", id = 8213, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 51, elite = false },
    { nomEn = "Mith'rethis the Enchanter", nom = "Mith'rethis l'Enchanteur", id = 8217, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 52, elite = true },

    -- FÉRALAS
    { nomEn = "Snarler", nom = "Grogneur", id = 5356, zone = "Féralas", zoneEn = "Feralas", niveau = 42, elite = false },
    { nomEn = "Old Grizzlegut", nom = "Vieux Grisebedaine", id = 5352, zone = "Féralas", zoneEn = "Feralas", niveau = 43, elite = false },
    { nomEn = "Gnarl Leafbrother", nom = "Gnarl Frèrefeuilles", alias = { "Gnarl Feuille-frère", "Gnarl Frère-des-feuilles" }, id = 5354, zone = "Féralas", zoneEn = "Feralas", niveau = 44, elite = false },
    { nomEn = "Diamond Head", nom = "Tête-de-diamant", id = 5345, zone = "Féralas", zoneEn = "Feralas", niveau = 45, elite = false },
    { nomEn = "Lady Szallah", nom = "Dame Szallah", id = 5343, zone = "Féralas", zoneEn = "Feralas", niveau = 46, elite = false },
    { nomEn = "Qirot", nom = "Qirot", id = 5350, zone = "Féralas", zoneEn = "Feralas", niveau = 47, elite = false },
    { nomEn = "Antilus the Soarer", nom = "Antilus le Planeur", id = 5347, zone = "Féralas", zoneEn = "Feralas", niveau = 48, elite = false },
    { nomEn = "Bloodroar the Stalker", nom = "Rugissang le Traqueur", alias = { "Bloodroar le Traqueur" }, id = 5346, zone = "Féralas", zoneEn = "Feralas", niveau = 48, elite = false },
    { nomEn = "Arash-ethis", nom = "Arash-ethis", id = 5349, zone = "Féralas", zoneEn = "Feralas", niveau = 49, elite = false },
    { nomEn = "Skarr the Unbreakable", nom = "Bâlhafr l'Invaincu", id = 11498, -- CONFIRMÉ (fiche JudgeHype) — arène de Hache-tripes (trad. JudgeHype Classic FR)
      zone = "Féralas", zoneEn = "Feralas", niveau = 40, elite = true },
    { nomEn = "Mushgog", id = 11447, nom = "Mushgog", -- nom identique en FR (JudgeHype Classic)
      zone = "Féralas", zoneEn = "Feralas", niveau = 40, elite = true },
    { nomEn = "The Razza", nom = "La Razza", id = 11497, -- CONFIRMÉ (fiche JudgeHype) — arène de Hache-tripes (JudgeHype FR : « La Razza »)
      zone = "Féralas", zoneEn = "Feralas", niveau = 40, elite = true },

    -- TANARIS
    { nomEn = "Murderous Blisterpaw", nom = "Brûlepatte meurtrier", alias = { "Patte-ampoule meurtrière" }, id = 8208, zone = "Tanaris", zoneEn = "Tanaris", niveau = 43, elite = false },
    { nomEn = "Warleader Krazzilak", nom = "Chef de guerre Krazzilak", id = 8199, zone = "Tanaris", zoneEn = "Tanaris", niveau = 45, elite = true },
    { nomEn = "Greater Firebird", nom = "Grand oiseau de feu", alias = { "Oiseau de feu supérieur" }, id = 8207, zone = "Tanaris", zoneEn = "Tanaris", niveau = 46, elite = false },
    { nomEn = "Jin'Zallah the Sandbringer", nom = "Jin'Zallah Porte-sable", id = 8200, zone = "Tanaris", zoneEn = "Tanaris", niveau = 46, elite = true },
    { nomEn = "Kregg Keelhaul", nom = "Kregg Keelhaul", id = 8203, zone = "Tanaris", zoneEn = "Tanaris", niveau = 47, elite = false },
    { nomEn = "Cyclok the Mad", nom = "Cyclok le Fol", alias = { "Cyclok le Fou" }, id = 8202, zone = "Tanaris", zoneEn = "Tanaris", niveau = 48, elite = false },
    { nomEn = "Haarka the Ravenous", nom = "Haarka le Féroce", alias = { "Haarka le Vorace" }, id = 8205, zone = "Tanaris", zoneEn = "Tanaris", niveau = 50, elite = false },
    { nomEn = "Omgorn the Lost", nom = "Omgorn l'Égaré", id = 8201, zone = "Tanaris", zoneEn = "Tanaris", niveau = 50, elite = false },
    { nomEn = "Soriid the Devourer", nom = "Soriid le Dévoreur", id = 8204, zone = "Tanaris", zoneEn = "Tanaris", niveau = 50, elite = false },

    -- AZSHARA
    { nomEn = "The Evalcharr", nom = "L'Evalcharr", id = 8660, zone = "Azshara", zoneEn = "Azshara", niveau = 48, elite = false },
    { nomEn = "Varo'then's Ghost", nom = "Fantôme de Varo'then", id = 6118, zone = "Azshara", zoneEn = "Azshara", niveau = 48, elite = false },
    { nomEn = "Gatekeeper Rageroar", nom = "Portier Hurlerage", alias = { "Gardien Rageroar" }, id = 6651, zone = "Azshara", zoneEn = "Azshara", niveau = 49, elite = false },
    { nomEn = "Antilos", nom = "Antilos", id = 6648, zone = "Azshara", zoneEn = "Azshara", niveau = 50, elite = false },
    { nomEn = "General Fangferror", nom = "Général Crocdangoiffe", alias = { "Général Fangferror" }, id = 6650, zone = "Azshara", zoneEn = "Azshara", niveau = 50, elite = false },
    { nomEn = "Lady Sesspira", nom = "Dame Sesspira", id = 6649, zone = "Azshara", zoneEn = "Azshara", niveau = 51, elite = false },
    { nomEn = "Magister Hawkhelm", nom = "Magistère Hawkhelm", alias = { "Magistère Heaume-faucon" }, id = 6647, zone = "Azshara", zoneEn = "Azshara", niveau = 51, elite = false },
    { nomEn = "Master Feardred", nom = "Maître Trouilleffroi", alias = { "Maître Feardred" }, id = 6652, zone = "Azshara", zoneEn = "Azshara", niveau = 51, elite = false },
    { nomEn = "Scalebeard", nom = "Barbe-d'écailles", alias = { "Écaillebarbe" }, id = 13896, zone = "Azshara", zoneEn = "Azshara", niveau = 52, elite = true },
    { nomEn = "Monnos the Elder", nom = "Monnos l'Ancien", id = 6646, zone = "Azshara", zoneEn = "Azshara", niveau = 53, elite = true },

    -- GORGE DES VENTS BRÛLANTS (Searing Gorge)
    { nomEn = "Faulty War Golem", nom = "Golem de guerre défaillant", alias = { "Golem de guerre défectueux" }, id = 8279, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 46, elite = false },
    { nomEn = "Shleipnarr", nom = "Shleipnarr", id = 8280, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 47, elite = false },
    { nomEn = "Rekk'tilac", nom = "Rekk'tilac", id = 8277, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 48, elite = false },
    { nomEn = "Scald", nom = "Brûlar", id = 8281, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 49, elite = false },
    { nomEn = "Slave Master Blackheart", nom = "Maître des esclaves Blackheart", alias = { "Maître des esclaves Cœur-Noir", "Maître des esclaves Coeur-noir" }, id = 8283, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 50, elite = false },
    { nomEn = "Smoldar", nom = "Fumar", id = 8278, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 50, elite = false },
    { nomEn = "Highlord Mastrogonde", nom = "Généralissime Mastrogonde", id = 8282, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 51, elite = true },

    -- GANGREBOIS (Felwood)
    { nomEn = "Death Howl", nom = "Hurlemort", alias = { "Hurlement de la mort", "Hurlement de mort" }, id = 14339, zone = "Gangrebois", zoneEn = "Felwood", niveau = 49, elite = false },
    { nomEn = "Mongress", nom = "Mongress", id = 14344, zone = "Gangrebois", zoneEn = "Felwood", niveau = 50, elite = false },
    { nomEn = "Ragepaw", nom = "Ragepatte", id = 14342, zone = "Gangrebois", zoneEn = "Felwood", niveau = 51, elite = false },
    { nomEn = "The Ongar", nom = "L'Ongar", id = 14345, zone = "Gangrebois", zoneEn = "Felwood", niveau = 51, elite = false },
    { nomEn = "Olm the Wise", nom = "Olm la Sage", alias = { "Olm le Sage" }, id = 14343, zone = "Gangrebois", zoneEn = "Felwood", niveau = 52, elite = false },
    { nomEn = "Alshirr Banebreath", nom = "Alshirr Souffléau", alias = { "Alshirr Souffle-de-fléau" },
      id = 14340, zone = "Gangrebois", zoneEn = "Felwood", niveau = 54, elite = false },
    { nomEn = "Dessecus", nom = "Dessecus", id = 7104, zone = "Gangrebois", zoneEn = "Felwood", niveau = 56, elite = true },
    { nomEn = "Immolatus", nom = "Immolatus", id = 7137, zone = "Gangrebois", zoneEn = "Felwood", niveau = 56, elite = true },

    -- TERRES FOUDROYÉES (Blasted Lands)
    { nomEn = "Fingat", nom = "Fingat", id = 14446, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 43, elite = false },
    { nomEn = "Mojo the Twisted", nom = "Mojo le Tordu", id = 8296, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 48, elite = false },
    { nomEn = "Deatheye", nom = "Oeil-de-mort", id = 8302, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 49, elite = false },
    { nomEn = "Grunter", nom = "Grunter", id = 8303, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 50, elite = false },
    { nomEn = "Ravage", nom = "Ravage", id = 8300, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 51, elite = false },
    { nomEn = "Spiteflayer", nom = "Ecorchebile", id = 8299, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 52, elite = false },
    { nomEn = "Clack the Reaver", nom = "Clack le Ravageur", id = 8301, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 53, elite = false },
    { nomEn = "Akubar the Seer", nom = "Akubar le Prophète", alias = { "Akubar le Voyant" }, id = 8298, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 54, elite = false },
    { nomEn = "Magronos the Unyielding", nom = "Magronos l'Inflexible", id = 8297, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 56, elite = false },
    { nomEn = "Dreadscorn", nom = "Dériseffroi", id = 8304, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 57, elite = false },

    -- STEPPES ARDENTES (Burning Steppes)
    { nomEn = "The Behemoth", nom = "Le Béhémoth", id = 8924, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 50, elite = true },
    { nomEn = "Deathmaw", nom = "Gueule-du-trépas", alias = { "Gueule-de-mort" }, id = 10077, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 53, elite = false },
    { nomEn = "Gorgon'och", nom = "Gorgon'och", id = 9604, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 54, elite = false },
    { nomEn = "Hahk'Zor", nom = "Hahk'Zor", id = 9602, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 54, elite = false },
    { nomEn = "Scarshield Quartermaster", nom = "Intendant du Bouclier balafré", alias = { "Intendant Bouclier-scarifié" }, id = 9046, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 55, elite = true },
    { nomEn = "Terrorspark", nom = "Lueur terrifiante", id = 10078, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 55, elite = false },
    { nomEn = "Malfunctioning Reaver", nom = "Ravageur défectueux", id = 8981, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 56, elite = false },
    { nomEn = "Thauris Balgarr", nom = "Thauris Balgarr", id = 8978, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 57, elite = false },
    { nomEn = "Gruklash", nom = "Gruklash", id = 8979, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 59, elite = false },
    { nomEn = "Hematos", nom = "Hematos", alias = { "Hématos" }, id = 8976, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 60, elite = true },
    { nomEn = "Volchan", nom = "Volchan", id = 10119, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 60, elite = true },

    -- HURLEVENT
    { nomEn = "Sewer Beast", nom = "Bête des égouts", id = 3581, zone = "Hurlevent", zoneEn = "Stormwind City", niveau = 50, elite = false },

    -- MALETERRES DE L'OUEST (Western Plaguelands)
    { nomEn = "Foulmane", nom = "Vilcrin", id = 1847, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 52, elite = false },
    { nomEn = "Lord Maldazzar", nom = "Seigneur Maldazzar", id = 1848, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 56, elite = false },
    { nomEn = "Foreman Marcrid", nom = "Contremaître Marcrid", id = 1844, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 58, elite = false },
    { nomEn = "Putridius", nom = "Putridius", id = 1850, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 58, elite = true },
    { nomEn = "Scarlet Smith", nom = "Forgeron écarlate", id = 1885, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 58, elite = false },
    { nomEn = "Scarlet Executioner", nom = "Bourreau écarlate", id = 1841, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 60, elite = true },
    { nomEn = "Scarlet Judge", nom = "Juge écarlate", id = 1837, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 60, elite = false },
    { nomEn = "Scarlet Interrogator", nom = "Inquisiteur écarlate", alias = { "Interrogateur écarlate" }, id = 1838, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 61, elite = true },
    { nomEn = "Foreman Jerris", nom = "Contremaître Jerris", id = 1843, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 62, elite = true },
    { nomEn = "The Husk", nom = "La Bogue", id = 1851, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 62, elite = false },
    { nomEn = "Scarlet High Clerist", nom = "Grand prêtre écarlate", alias = { "Haut clerc écarlate" }, id = 1839, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 63, elite = true },

    -- MALETERRES DE L'EST (Eastern Plaguelands)
    { nomEn = "Duggan Wildhammer", nom = "Duggan Wildhammer", alias = { "Duggan Marteau-hardi" }, id = 10817, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 55, elite = false },
    { nomEn = "Deathspeaker Selendre", nom = "Nécrorateur Selendre", alias = { "Héraut de la mort Selendre" }, id = 10827, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 56, elite = false },
    { nomEn = "Gish the Unmoving", nom = "Gish l'Immobile", id = 10825, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 56, elite = false },
    { nomEn = "Hed'mush the Rotting", nom = "Hed'mush le Pourrissant", id = 10821, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 57, elite = false },
    { nomEn = "Lord Darkscythe", nom = "Seigneur Sombrefaux", alias = { "Seigneur Darkscythe", "Seigneur Faux-sombre" }, id = 10826, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 57, elite = false },
    { nomEn = "Warlord Thresh'jin", nom = "Seigneur de guerre Thresh'jin", id = 10822, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 58, elite = false },
    { nomEn = "High General Abbendis", nom = "Grand général Abbendis", id = 10828, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 59, elite = true },
    { nomEn = "Zul'Brin Warpbranch", nom = "Zul'Brin Warpbranch", id = 10823, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 59, elite = false },
    { nomEn = "Ranger Lord Hawkspear", nom = "Seigneur forestier Hawspear", alias = { "Seigneur rôdeur Hawkspear", "Seigneur traqueur Lance-faucon" }, id = 10824, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 60, elite = false },

    -- HIVERPEINT (Winterspring)
    { nomEn = "Mezzir the Howler", nom = "Mezzir le hurleur", alias = { "Mezzir le Hurlant", "Mezzir le Hurleur" }, id = 10197, zone = "Berceau-de-l'Hiver", zoneEn = "Winterspring", niveau = 55, elite = false },
    { nomEn = "General Colbatann", nom = "Général Colbatann", id = 10196, zone = "Berceau-de-l'Hiver", zoneEn = "Winterspring", niveau = 56, elite = true },
    { nomEn = "Rak'shiri", nom = "Rak'shiri", id = 10200, zone = "Berceau-de-l'Hiver", zoneEn = "Winterspring", niveau = 57, elite = false },
    { nomEn = "Azurous", nom = "Azurous", id = 10202, zone = "Berceau-de-l'Hiver", zoneEn = "Winterspring", niveau = 59, elite = true },
    { nomEn = "Grizzle Snowpaw", nom = "Grison Neigepatte", alias = { "Grizzle Patte-des-neiges" }, id = 10199, zone = "Berceau-de-l'Hiver", zoneEn = "Winterspring", niveau = 59, elite = false },
    { nomEn = "Kashoch the Reaver", nom = "Kashoch le ravageur", alias = { "Kashoch le Ravageur" }, id = 10198, zone = "Berceau-de-l'Hiver", zoneEn = "Winterspring", niveau = 60, elite = true },
    { nomEn = "Lady Hederine", nom = "Dame Hederine", id = 10201, zone = "Berceau-de-l'Hiver", zoneEn = "Winterspring", niveau = 61, elite = true },

    -- CRATÈRE D'UN'GORO
    { nomEn = "Ravasaur Matriarch", nom = "Matriarche ravasaure", alias = { "Matriarche Croc-rasoir" }, id = 6581, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 50, elite = false },
    { nomEn = "Uhk'loc", nom = "Uhk'loc", id = 6585, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 52, elite = false },
    { nomEn = "Clutchmother Zavas", nom = "Matriarche Zavas", alias = { "Mère de couvée Zavas" }, id = 6582, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 54, elite = false },
    { nomEn = "Gruff", id = 6583, nom = "Gruff", zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 57, elite = true },
    { nomEn = "King Mosh", nom = "Roi Mosh", id = 6584, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 60, elite = true },

    -- SILITHUS
    { nomEn = "Krellack", nom = "Krellack", id = 14476, zone = "Silithus", zoneEn = "Silithus", niveau = 56, elite = false },
    { nomEn = "Gretheer", nom = "Gretheer", id = 14472, zone = "Silithus", zoneEn = "Silithus", niveau = 57, elite = false },
    { nomEn = "Rex Ashil", nom = "Rex Ashil", id = 14475, zone = "Silithus", zoneEn = "Silithus", niveau = 57, elite = true },
    { nomEn = "Grubthor", nom = "Grubthor", id = 14477, zone = "Silithus", zoneEn = "Silithus", niveau = 58, elite = false },
    { nomEn = "Huricanian", nom = "Ouraganien", id = 14478, zone = "Silithus", zoneEn = "Silithus", niveau = 58, elite = false },
    { nomEn = "Zora", nom = "Zora", id = 14474, zone = "Silithus", zoneEn = "Silithus", niveau = 59, elite = true },
    { nomEn = "Lapress", nom = "Lapress", id = 14473, zone = "Silithus", zoneEn = "Silithus", niveau = 60, elite = true },
    { nomEn = "Twilight Lord Everun", nom = "Seigneur du crépuscule Everun", alias = { "Seigneur du Crépuscule Everun" }, id = 14479, zone = "Silithus", zoneEn = "Silithus", niveau = 60, elite = false },
    { nomEn = "Setis", nom = "Setis", id = 14471, zone = "Silithus", zoneEn = "Silithus", niveau = 61, elite = true },
}

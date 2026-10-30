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
    { nomEn = "Geolord Mottle", nom = "Géoseigneur Mottle", alias = { "Géomaîtresse Mouchette" },
      id = 5822, zone = "Durotar", zoneEn = "Durotar", niveau = 9, elite = false, x = 47.0, y = 49.0 },
    { nomEn = "Warlord Kolkanis", nom = "Seigneur de guerre Kolkanis", vu = true,
      zone = "Durotar", zoneEn = "Durotar", niveau = 9, elite = false },
    { nomEn = "Watch Commander Zalaphil", nom = "Commandant de guet Zalaphil",
      id = 5826, zone = "Durotar", zoneEn = "Durotar", niveau = 9, elite = false, x = 59.0, y = 55.0 },
    { nomEn = "Captain Flat Tusk", nom = "Capitaine Croc-Plat",
      id = 5823, zone = "Durotar", zoneEn = "Durotar", niveau = 11, elite = true, x = 43.0, y = 50.0 },
    { nomEn = "Death Flayer", nom = "Flagelleur de la mort",
      id = 5828, zone = "Durotar", zoneEn = "Durotar", niveau = 11, elite = false, x = 39.0, y = 69.0 },
    { nomEn = "Felweaver Scornn", nom = "Tisse-gangrène Scornn", vu = true,
      id = 5824, zone = "Durotar", zoneEn = "Durotar", niveau = 11, elite = true, x = 54.0, y = 10.0 },
    { nomEn = "Dishu", nom = "Dishu", zone = "Durotar", zoneEn = "Durotar", niveau = 13, elite = false },
    { nomEn = "Rathorian", nom = "Rathorian", zone = "Durotar", zoneEn = "Durotar", niveau = 15, elite = false },
    { nomEn = "Sarkoth", nom = "Sarkoth", zone = "Durotar", zoneEn = "Durotar", niveau = 5, elite = false },

    -- MULGORE
    { nomEn = "Mazzranache", nom = "Mazzranache", id = 3068,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 9, elite = false, x = 45.0, y = 40.0 },
    { nomEn = "Snagglespear", nom = "Travépieu", id = 5786,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 9, elite = false, x = 52.0, y = 42.0 },
    { nomEn = "The Rake", nom = "Le Rake", alias = { "Le Rateau" }, id = 5807,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 10, elite = false, x = 48.0, y = 16.0 },
    { nomEn = "Enforcer Emilgund", nom = "Exécutrice Emilgund", id = 5787,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 11, elite = false, x = 33.0, y = 48.0 },
    { nomEn = "Sister Hatelash", nom = "Sœur Haine-Coups", id = 5785,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 11, elite = true, x = 36.0, y = 20.0 },
    { nomEn = "Ghost Howl", nom = "Hurlement fantôme", id = 3056,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 12, elite = false, x = 31.0, y = 39.0 },
    { nomEn = "Geopriest Gukk'rok", nom = "Géopêtresse Gukk'rok", id = 5863,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 19, elite = false },
    { nomEn = "Swinegart Spearhide", nom = "Peau-piquante Swinegart", id = 5864,
      zone = "Mulgore", zoneEn = "Mulgore", niveau = 22, elite = true },

    -- GLADES DE TIRISFAL
    { nomEn = "Lost Soul", nom = "Âme perdue",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 6, elite = false },
    { nomEn = "Farmer Solliden", nom = "Fermier Solliden",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 8, elite = false },
    { nomEn = "Tormented Spirit", nom = "Esprit tourmenté",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 8, elite = false },
    { nomEn = "Bayne", nom = "Bayne", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 10, elite = false },
    { nomEn = "Muad", nom = "Muad", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 10, elite = false },
    { nomEn = "Deeb", nom = "Deeb", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 12, elite = false },
    { nomEn = "Fellicent's Shade", nom = "Ombre de Fellicent",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 12, elite = false },
    { nomEn = "Ressan the Needler", nom = "Ressan le Piqueur",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 11, elite = false },
    { nomEn = "Sri'skulk", nom = "Sri'skulk", zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 13, elite = false },
    { nomEn = "Krethis Shadowspinner", nom = "Krethis Tisse-ombre",
      zone = "Clairières de Tirisfal", zoneEn = "Tirisfal Glades", niveau = 15, elite = false },

    -- TELDRASSIL
    { nomEn = "Threggil", nom = "Threggil", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 6, elite = false },
    { nomEn = "Uruson", nom = "Uruson", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 7, elite = false },
    { nomEn = "Fury Shelda", nom = "Shelda la Furieuse", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 8, elite = false },
    { nomEn = "Duskstalker", nom = "Traqueur du crépuscule", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 9, elite = false },
    { nomEn = "Blackmoss the Fetid", nom = "Moussemois le Fétide", zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 13, elite = false },
    { nomEn = "Grimmaw", -- nom FR à confirmer
      zone = "Teldrassil", zoneEn = "Teldrassil", niveau = 11, elite = false },

    -- SOMBRERIVAGE (Darkshore)
    { nomEn = "Shadowclaw", nom = "Ombregriffe", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 13, elite = false },
    { nomEn = "Licillin", nom = "Licillin", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 14, elite = false },
    { nomEn = "Lord Sinslayer", nom = "Seigneur Tueur-de-péchés", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 15, elite = false },
    { nomEn = "Carnivous the Breaker", nom = "Carnivore le Casseur", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 16, elite = false },
    { nomEn = "Flagglemurk the Cruel", nom = "Flagglemurk le Cruel", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 16, elite = false },
    { nomEn = "Lady Moongazer", nom = "Dame Regardelune", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 17, elite = false },
    { nomEn = "Firecaller Radison", nom = "Invocateur du feu Radison", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 19, elite = false },
    { nomEn = "Lady Vespira", nom = "Dame Vespira", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 22, elite = false },
    { nomEn = "Strider Clutchmother", nom = "Mère de couvée des échassiers", zone = "Sombrerivage", zoneEn = "Darkshore", niveau = 20, elite = false },

    -- BRACHLAND (The Barrens)
    { nomEn = "Elder Mystic Razorsnout", nom = "Ancien mystique Museau-rasoir", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 15, elite = true },
    { nomEn = "Stonearm", nom = "Bras-de-pierre", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 15, elite = false },
    { nomEn = "Brokespear", nom = "Brokespear", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 17, elite = false },
    { nomEn = "Snort the Heckler", nom = "Snort le Moqueur", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 17, elite = false },
    { nomEn = "Rocklance", nom = "Lance-de-roche", alias = { "Rochelance" }, vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 17, elite = true },
    { nomEn = "Engineer Whirleygig", nom = "Ingénieur Tourniquet", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = false },
    { nomEn = "Foreman Grills", nom = "Contremaître Grills", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = false },
    { nomEn = "Sludge Beast", nom = "Bête de boue", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = false },
    { nomEn = "Takk the Leaper", nom = "Takk le Bondisseur", id = 5842,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = true, x = 63.0, y = 37.0 },
    { nomEn = "Trigore the Lasher", -- nom FR à confirmer
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 19, elite = true },
    { nomEn = "Boahn", nom = "Boahn", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 20, elite = true },
    { nomEn = "Gesharahan", nom = "Gesharahan", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 20, elite = true },
    { nomEn = "Swiftmane", nom = "Vif-Crinière", alias = { "Flinkmähne" },
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 21, elite = true },
    { nomEn = "Humar the Pridelord", nom = "Humar le Seigneur hautain", vu = true, id = 5847,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 23, elite = true, x = 27.0, y = 33.0 },
    { nomEn = "Digger Flameforge", nom = "Fossoyeur Forgeflamme", id = 5849,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false, x = 66.0, y = 44.0 },
    { nomEn = "Hannah Bladeleaf", nom = "Hannah Feuillelame", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = true },
    { nomEn = "Heggin Stonewhisker", nom = "Heggin Museau-de-pierre", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false },
    { nomEn = "Marcus Bel", nom = "Marcus Bel", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = true },
    { nomEn = "Silithid Harvester", nom = "Cueilleur silithide", id = 3253,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false, x = 47.0, y = 87.0 },
    { nomEn = "Thunderstomp", nom = "Pietinement-tonnerre", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 24, elite = false },
    { nomEn = "Aean Swiftriver", nom = "Aean Swiftriver", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 25, elite = true },
    { nomEn = "Azzere the Skyblade", nom = "Azzere la Lame-des-cieux", id = 5834,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 25, elite = false, x = 41.0, y = 14.0 },
    { nomEn = "Malgin Barleybrew", nom = "Malgin Brasse-d'orge", id = 5848,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 25, elite = false, x = 54.0, y = 46.0 },
    { nomEn = "Hagg Taurenbane", nom = "Hagg Fléau-des-taurens", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 26, elite = true },
    { nomEn = "Brontus", nom = "Brontus", vu = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = true },
    { nomEn = "Captain Gerogg Hammertoe", nom = "Capitaine Gerogg Hammertoe", zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = true },
    { nomEn = "Harb Foulmountain", nom = "Harb Montagne-fétide",
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = false },
    { nomEn = "Thora Feathermoon", nom = "Thora Plume-de-lune", vu = true,
      zone = "Les Tarides", zoneEn = "The Barrens", niveau = 27, elite = true },

    -- SERRES-ROCHEUSES (Stonetalon)
    { nomEn = "Sister Rathtalon", nom = "Sœur Griffe-de-rat", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 19, elite = true },
    { nomEn = "Taskmaster Whipfang", nom = "Chef de tâche Croc-fouet", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 22, elite = true },
    { nomEn = "Foreman Rigger", nom = "Contremaître Rigger", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 24, elite = true },
    { nomEn = "Pridewing Patriarch", nom = "Patriarche Aile-fière", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 25, elite = false },
    { nomEn = "Sentinel Amarassan", nom = "Sentinelle Amarassan", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 27, elite = true },
    { nomEn = "Sorrow Wing", nom = "Aile-de-chagrin", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 27, elite = true },
    { nomEn = "Sister Riven", nom = "Sœur Riven", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 28, elite = true },
    { nomEn = "Brother Ravenoak", nom = "Frère Chêneravin", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 29, elite = true },
    { nomEn = "Vengeful Ancient", nom = "Ancien vengeur", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 29, elite = false },
    { nomEn = "Nal'taszar", nom = "Nal'taszar", zone = "Les Serres-Rocheuses", zoneEn = "Stonetalon Mountains", niveau = 30, elite = true },

    -- ORNEVAL (Ashenvale)
    { nomEn = "Apothecary Falthis", nom = "Apothicaire Falthis", zone = "Orneval", zoneEn = "Ashenvale", niveau = 22, elite = false },
    { nomEn = "Lady Vespia", nom = "Dame Vespia", zone = "Orneval", zoneEn = "Ashenvale", niveau = 22, elite = false },
    { nomEn = "Mist Howler", nom = "Hurle-brume", zone = "Orneval", zoneEn = "Ashenvale", niveau = 22, elite = false },
    { nomEn = "Mugglefin", nom = "Mugglefin", zone = "Orneval", zoneEn = "Ashenvale", niveau = 23, elite = false },
    { nomEn = "Branch Snapper", nom = "Casse-branche", zone = "Orneval", zoneEn = "Ashenvale", niveau = 25, elite = false },
    { nomEn = "Rorgish Jowl", nom = "Rorgish Jowl", zone = "Orneval", zoneEn = "Ashenvale", niveau = 25, elite = false },
    { nomEn = "Akkrilus", nom = "Akkrilus", zone = "Orneval", zoneEn = "Ashenvale", niveau = 26, elite = false },
    { nomEn = "Eck'alom", nom = "Eck'alom", zone = "Orneval", zoneEn = "Ashenvale", niveau = 27, elite = false },
    { nomEn = "Oakpaw", nom = "Patte-de-chêne", zone = "Orneval", zoneEn = "Ashenvale", niveau = 27, elite = false },

    -- FORÊT DES PINS-ARGENTÉS (Silverpine)
    { nomEn = "Gorefang", nom = "Gorefang", vu = true, zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 13, elite = false },
    { nomEn = "Old Vicejaw", nom = "Vieux Vicejaw", zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 14, elite = false },
    { nomEn = "Dalaran Spellscribe", nom = "Scribe des sorts de Dalaran", zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 21, elite = false },
    { nomEn = "Ravenclaw Regent", nom = "Régent Serre-corbeau", zone = "Forêt des Pins-Argentés", zoneEn = "Silverpine Forest", niveau = 22, elite = false },

    -- COMTÉ DE L'ORNE (Elwynn)
    { nomEn = "Morgaine the Sly", nom = "Morgaine la Rusée", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 10, elite = false },
    { nomEn = "Mother Fang", nom = "Mère Croc", vu = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 10, elite = false },
    { nomEn = "Narg the Taskmaster", nom = "Narg le Chef-de-tâche", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 10, elite = false },
    { nomEn = "Thuros Lightfingers", nom = "Thuros Doigts-légers", vu = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 11, elite = false },
    { nomEn = "Fedfennel", nom = "Fedfennel", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 12, elite = false },
    { nomEn = "Gruff Swiftbite", nom = "Gruff Morsure-vive", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 12, elite = false },
    { nomEn = "Lupos", nom = "Lupos", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 23, elite = false },

    -- MARCHES DE L'OUEST (Westfall)
    { nomEn = "Master Digger", nom = "Maître Fossoyeur", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 15, elite = false },
    { nomEn = "Slark", nom = "Slark", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 15, elite = false },
    { nomEn = "Brainwashed Noble", -- nom FR à confirmer
      zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 18, elite = true },
    { nomEn = "Marisa du'Paige", nom = "Marisa du'Paige", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 18, elite = true },
    { nomEn = "Sergeant Brashclaw", nom = "Sergent Brashclaw", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 18, elite = false },
    { nomEn = "Brack", nom = "Brack", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 19, elite = false },
    { nomEn = "Leprithus", nom = "Leprithus", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 19, elite = false },
    { nomEn = "Foe Reaper 4000", nom = "Foe Reaper 4000", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 20, elite = false },
    { nomEn = "Vultros", nom = "Vultros", zone = "Marches de l'Ouest", zoneEn = "Westfall", niveau = 26, elite = false },

    -- LES CARMINES (Redridge)
    { nomEn = "Ribchaser", nom = "Ribchaser", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 17, elite = false },
    { nomEn = "Snarlflare", nom = "Snarlflare", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 18, elite = false },
    { nomEn = "Squiddic", nom = "Squiddic", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 19, elite = false },
    { nomEn = "Seeker Aqualon", nom = "Chercheur Aqualon", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 21, elite = false },
    { nomEn = "Boulderheart", nom = "Coeur-de-rocher", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 25, elite = false },
    { nomEn = "Chatter", nom = "Bavard", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 23, elite = false },
    { nomEn = "Kazon", nom = "Kazon", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 27, elite = false },
    { nomEn = "Rohh the Silent", nom = "Rohh le Silencieux", zone = "Les Carmines", zoneEn = "Redridge Mountains", niveau = 26, elite = false },

    -- COLLINES DES CHAGRINS (Duskwood)
    { nomEn = "Naraxis", nom = "Naraxis", zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 27, elite = false },

    -- CONTREFORTS DE HAUTEBRANDE (Hillsbrad)
    { nomEn = "Creepthess", nom = "Creepthess",
      zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 24, elite = false },
    { nomEn = "Ro'Bark", nom = "Ro'Bark",
      zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 28, elite = false },
    { nomEn = "Tamra Stormpike", nom = "Tamra Stormpike", zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 28, elite = true },
    { nomEn = "Scargil", nom = "Scargil", zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 30, elite = false },

    -- LOCH MODAN
    { nomEn = "Lord Condar", nom = "Seigneur Condar", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 15, elite = false },
    { nomEn = "Emogg the Crusher", nom = "Emogg le Broyeur", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 19, elite = true },
    { nomEn = "Magosh", nom = "Magosh", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 21, elite = false },
    { nomEn = "Shanda the Spinner", nom = "Shanda la Tisseuse", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 19, elite = false },
    { nomEn = "Boss Galgosh", nom = "Boss Galgosh", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 22, elite = false },
    { nomEn = "Large Loch Crocolisk", nom = "Grand crocolisque du loch", zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 22, elite = false },
    { nomEn = "Grizlak", -- rare lvl 15 (Wowhead Classic) — nom FR à confirmer en jeu
      zone = "Loch Modan", zoneEn = "Loch Modan", niveau = 15, elite = false },

    -- DUN MOROGH
    { nomEn = "Edan the Howler", nom = "Edan le Hurleur", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 9, elite = false },
    { nomEn = "Timber", nom = "Timber", vu = true, zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 10, elite = false },
    { nomEn = "Gibblewilt", nom = "Gibblewilt", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 11, elite = false },
    { nomEn = "Great Father Arctikus", nom = "Grand-père Arctikus", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 11, elite = false },
    { nomEn = "Hammerspine", nom = "Hammerspine", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 12, elite = false },
    { nomEn = "Bjarn", nom = "Bjarn", zone = "Dun Morogh", zoneEn = "Dun Morogh", niveau = 12, elite = false },

    -- LES PALUNS (Wetlands)
    { nomEn = "Ma'ruk Wyrmscale", nom = "Ma'ruk Écaille-de-ver", vu = true, zone = "Les Paluns", zoneEn = "Wetlands", niveau = 23, elite = false },
    { nomEn = "Gnawbone", nom = "Gnawbone", zone = "Les Paluns", zoneEn = "Wetlands", niveau = 24, elite = false },
    { nomEn = "Leech Widow", nom = "Veuve-sangsue", zone = "Les Paluns", zoneEn = "Wetlands", niveau = 24, elite = false },
    { nomEn = "Mirelow", nom = "Mirelow", zone = "Les Paluns", zoneEn = "Wetlands", niveau = 25, elite = false },
    { nomEn = "Garneg Charskull", nom = "Garneg Crâne-brûlé", zone = "Les Paluns", zoneEn = "Wetlands", niveau = 29, elite = false },
    { nomEn = "Dragonmaw Battlemaster", -- nom FR à confirmer
      zone = "Les Paluns", zoneEn = "Wetlands", niveau = 30, elite = false },
    { nomEn = "Razormaw Matriarch", -- raptor rare lvl 25, grotte de Raptor Ridge — nom FR à confirmer en jeu
      zone = "Les Paluns", zoneEn = "Wetlands", niveau = 25, elite = false },
    { nomEn = "Sludginn", nom = "Sludginn",
      zone = "Les Paluns", zoneEn = "Wetlands", niveau = 30, elite = false },
    -- Mob custom Forever (hors ForeverDB) : ID fourni par une source externe,
    -- à vérifier en jeu.
    { nomEn = "Nightveiled Rotheap", nom = "Rotheap",
      id = 14222, zone = "Les Paluns", zoneEn = "Wetlands", niveau = 20, elite = true, x = 48.0, y = 39.0 },

    -- MONTAGNES D'ALTERAC
    { nomEn = "Rot Hide Bruiser", nom = "Bagarreur Peau-putride", -- FR à confirmer
      zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 22, elite = false },
    { nomEn = "Jimmy the Bleeder", nom = "Jimmy le Saignant", zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 23, elite = false },
    { nomEn = "Snarlmane", nom = "Snarlmane", zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 23, elite = false },
    { nomEn = "Lo'Grosh", nom = "Lo'Grosh", zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 28, elite = true },

    -- HAUTES-TERRES D'ARATHI
    { nomEn = "Big Samras", nom = "Gros Samras",
      zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 27, elite = false },

    -- MILLE POINTES
    { nomEn = "Gibblesnik", nom = "Gibblesnik", zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 28, elite = false },

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
    { nomEn = "Terrowulf Packlord", nom = "Chef de meute Terrowulf", aConfirmer = true, zone = "Orneval", zoneEn = "Ashenvale", niveau = 31, elite = false },
    { nomEn = "Ursol'lok", nom = "Ursol'lok", aConfirmer = true, zone = "Orneval", zoneEn = "Ashenvale", niveau = 31, elite = false },
    { nomEn = "Prince Raze", nom = "Prince Raze", aConfirmer = true, zone = "Orneval", zoneEn = "Ashenvale", niveau = 32, elite = false },

    -- DÉSOLACE
    { nomEn = "Prince Kellen", nom = "Prince Kellen", aConfirmer = true, zone = "Désolace", zoneEn = "Desolace", niveau = 33, elite = false },
    { nomEn = "Giggler", nom = "Glousseur", aConfirmer = true, zone = "Désolace", zoneEn = "Desolace", niveau = 34, elite = false },
    { nomEn = "Accursed Slitherblade", nom = "Lame-rameuse maudite", aConfirmer = true, zone = "Désolace", zoneEn = "Desolace", niveau = 35, elite = false },
    { nomEn = "Hissperak", nom = "Hissperak", aConfirmer = true, zone = "Désolace", zoneEn = "Desolace", niveau = 37, elite = false },
    { nomEn = "Kaskk", nom = "Kaskk", aConfirmer = true, zone = "Désolace", zoneEn = "Desolace", niveau = 40, elite = false },
    { nomEn = "Cursed Centaur", nom = "Centaure maudit", aConfirmer = true, zone = "Désolace", zoneEn = "Desolace", niveau = 43, elite = false },

    -- MILLE POINTES (31+)
    { nomEn = "Achellios the Banished", nom = "Achellios le Banni", aConfirmer = true, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 31, elite = false },
    { nomEn = "Heartrazor", nom = "Heartrazor", aConfirmer = true, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 32, elite = true },
    { nomEn = "Vile Sting", nom = "Vile Sting", aConfirmer = true, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 35, elite = true },
    { nomEn = "Silithid Ravager", nom = "Ravageur silithide", aConfirmer = true, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 36, elite = false },
    { nomEn = "Ironeye the Invincible", nom = "Ironeye l'Invincible", alias = { "Œil-de-fer l'Invincible" }, aConfirmer = true, zone = "Mille Pointes", zoneEn = "Thousand Needles", niveau = 37, elite = true },

    -- BRACHLAND (les Tarides — nom FR custom du serveur)
    { nomEn = "Ambassador Bloodrage", nom = "Ambassadeur Ragesang", aConfirmer = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 36, elite = true },
    { nomEn = "Darkmist Widow", nom = "Veuve de la Brume-sombre", aConfirmer = true, zone = "Les Tarides", zoneEn = "The Barrens", niveau = 40, elite = false },

    -- COLLINES DES CHAGRINS (Duskwood — nom FR serveur, cf. Naraxis)
    { nomEn = "Lord Malathrom", nom = "Seigneur Malathrom", aConfirmer = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 31, elite = false },
    { nomEn = "Commander Felstrom", nom = "Commandant Felstrom", aConfirmer = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 32, elite = false },
    { nomEn = "Fenros", nom = "Fenros", aConfirmer = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 32, elite = false },
    { nomEn = "Nefaru", nom = "Nefaru", aConfirmer = true, zone = "Bois de la Pénombre", zoneEn = "Duskwood", niveau = 34, elite = false },

    -- CONTREFORTS DE HAUTEBRANDE
    { nomEn = "Lady Zephris", nom = "Dame Zephris", aConfirmer = true, zone = "Contreforts de Hautebrande", zoneEn = "Hillsbrad Foothills", niveau = 33, elite = false },

    -- MONTAGNES D'ALTERAC (32+)
    { nomEn = "Cranky Benj", nom = "Benj le Bougon", aConfirmer = true, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 32, elite = false },
    { nomEn = "Araga", nom = "Araga", aConfirmer = true, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 35, elite = false },
    { nomEn = "Gravis Slipknot", nom = "Gravis Slipknot", aConfirmer = true, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 36, elite = false },
    { nomEn = "Skhowl", nom = "Skhowl", aConfirmer = true, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 36, elite = false },
    { nomEn = "Stone Fury", nom = "Furie de pierre", aConfirmer = true, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 37, elite = false },
    { nomEn = "Narillasanz", nom = "Narillasanz", aConfirmer = true, zone = "Montagnes d'Alterac", zoneEn = "Alterac Mountains", niveau = 44, elite = true },

    -- HAUTES-TERRES D'ARATHI
    { nomEn = "Singer", nom = "Singer", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 34, elite = false },
    { nomEn = "Kovork", nom = "Kovork", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 36, elite = false },
    { nomEn = "Nimar the Slayer", nom = "Nimar le Tueur", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 37, elite = false },
    { nomEn = "Darbel Montrose", nom = "Darbel Montrose", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 39, elite = true },
    { nomEn = "Molok the Crusher", nom = "Molok le Broyeur", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 39, elite = false },
    { nomEn = "Ruul Onestone", nom = "Ruul Onestone", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 39, elite = true },
    { nomEn = "Geomancer Flintdagger", nom = "Géomancien Silexdague", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 40, elite = false },
    { nomEn = "Zalas Witherbark", nom = "Zalas Fanécorce", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 40, elite = false },
    { nomEn = "Prince Nazjak", nom = "Prince Nazjak", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 41, elite = false },
    { nomEn = "Foulbelly", nom = "Ventre-Immonde", aConfirmer = true, zone = "Hautes-terres d'Arathi", zoneEn = "Arathi Highlands", niveau = 42, elite = true },

    -- TERRES INGRATES (Badlands)
    { nomEn = "War Golem", nom = "Golem de guerre", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 36, elite = false },
    { nomEn = "Broken Tooth", nom = "Dent-Cassée", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 37, elite = false },
    { nomEn = "Digmaster Shovelphlange", nom = "Maître des fouilles Bêchephlange", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 38, elite = true },
    { nomEn = "Shadowforge Commander", nom = "Commandant Ombreforge", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 40, elite = false },
    { nomEn = "Siege Golem", nom = "Golem de siège", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 40, elite = true },
    { nomEn = "7:XT", nom = "7:XT", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 41, elite = false },
    { nomEn = "Anathemus", nom = "Anathemus", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 45, elite = true },
    { nomEn = "Rumbler", nom = "Rumbler", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 45, elite = false },
    { nomEn = "Zaricotl", nom = "Zaricotl", aConfirmer = true, zone = "Terres ingrates", zoneEn = "Badlands", niveau = 55, elite = true },

    -- MARÉCAGE D'ÂPREFANGE (Dustwallow)
    { nomEn = "Drogoth the Roamer", nom = "Drogoth l'Errant", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 37, elite = false },
    { nomEn = "Burgle Eye", nom = "Burgle Eye", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 38, elite = false },
    { nomEn = "Dart", nom = "Dart", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 38, elite = false },
    { nomEn = "Ripscale", nom = "Ripscale", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 39, elite = false },
    { nomEn = "Hayoc", nom = "Hayoc", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 41, elite = false },
    { nomEn = "Oozeworm", nom = "Oozeworm", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 42, elite = false },
    { nomEn = "The Rot", nom = "La Pourriture", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 43, elite = false },
    { nomEn = "Lord Angler", nom = "Seigneur Angler", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 44, elite = false },
    { nomEn = "Brimgore", nom = "Brimgore", aConfirmer = true, zone = "Marécage d'Âprefange", zoneEn = "Dustwallow Marsh", niveau = 45, elite = true },

    -- MARAIS DES CHAGRINS (Swamp of Sorrows)
    { nomEn = "Lost One Cook", nom = "Cuisinier des Perdus", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 37, elite = false },
    { nomEn = "Lost One Chieftain", nom = "Chef des Perdus", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 39, elite = false },
    { nomEn = "Molt Thorn", nom = "Molt Thorn", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 42, elite = false },
    { nomEn = "Gilmorian", nom = "Gilmorian", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 43, elite = false },
    { nomEn = "Lord Captain Wyrmak", nom = "Seigneur capitaine Wyrmak", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 45, elite = true },
    { nomEn = "Jade", nom = "Jade", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 47, elite = true },
    { nomEn = "Veyzhak the Cannibal", nom = "Veyzhak le Cannibale", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 48, elite = true },
    { nomEn = "Zekkis", nom = "Zekkis", aConfirmer = true, zone = "Marais des Chagrins", zoneEn = "Swamp of Sorrows", niveau = 48, elite = true },

    -- VALLÉE DE STRANGLERONCE
    { nomEn = "Gluggle", nom = "Gluggle", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 37, elite = false },
    { nomEn = "Roloch", nom = "Roloch", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 38, elite = false },
    { nomEn = "Kurmokk", nom = "Kurmokk", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 42, elite = false },
    { nomEn = "Verifonix", nom = "Verifonix", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 42, elite = false },
    { nomEn = "Mosh'Ogg Butcher", nom = "Boucher Mosh'Ogg", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 44, elite = true },
    { nomEn = "Rippa", nom = "Rippa", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 44, elite = false },
    { nomEn = "Lord Sakrasis", nom = "Seigneur Sakrasis", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 45, elite = false },
    { nomEn = "Scale Belly", nom = "Scale Belly", aConfirmer = true, zone = "Vallée de Strangleronce", zoneEn = "Stranglethorn Vale", niveau = 45, elite = false },

    -- LES HINTERLANDS
    { nomEn = "Old Cliff Jumper", nom = "Vieux Bondisseur", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 42, elite = false },
    { nomEn = "Zul'arek Hatefowler", nom = "Zul'arek Haineplume", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 43, elite = false },
    { nomEn = "Razortalon", nom = "Razortalon", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 44, elite = false },
    { nomEn = "Witherheart the Stalker", nom = "Witherheart le Traqueur", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 45, elite = false },
    { nomEn = "Retherokk the Berserker", nom = "Retherokk le Berserk", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 48, elite = false },
    { nomEn = "Jalinde Summerdrake", nom = "Jalinde Summerdrake", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 49, elite = false },
    { nomEn = "The Reak", nom = "The Reak", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 49, elite = false },
    { nomEn = "Grimungous", nom = "Grimungous", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 50, elite = true },
    { nomEn = "Ironback", nom = "Dos-de-fer", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 51, elite = false },
    { nomEn = "Mith'rethis the Enchanter", nom = "Mith'rethis l'Enchanteur", aConfirmer = true, zone = "Les Hinterlands", zoneEn = "The Hinterlands", niveau = 52, elite = true },

    -- FÉRALAS
    { nomEn = "Snarler", nom = "Snarler", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 42, elite = false },
    { nomEn = "Old Grizzlegut", nom = "Old Grizzlegut", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 43, elite = false },
    { nomEn = "Gnarl Leafbrother", nom = "Gnarl Feuille-frère", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 44, elite = false },
    { nomEn = "Diamond Head", nom = "Diamond Head", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 45, elite = false },
    { nomEn = "Lady Szallah", nom = "Dame Szallah", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 46, elite = false },
    { nomEn = "Qirot", nom = "Qirot", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 47, elite = false },
    { nomEn = "Antilus the Soarer", nom = "Antilus le Planeur", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 48, elite = false },
    { nomEn = "Bloodroar the Stalker", nom = "Bloodroar le Traqueur", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 48, elite = false },
    { nomEn = "Arash-ethis", nom = "Arash-ethis", aConfirmer = true, zone = "Féralas", zoneEn = "Feralas", niveau = 49, elite = false },
    { nomEn = "Skarr the Unbreakable", -- ogre rare de l'arène de Hache-tripes (niveau à confirmer en jeu) — nom FR à confirmer
      zone = "Féralas", zoneEn = "Feralas", niveau = 40, elite = true },
    { nomEn = "Mushgog", -- ogre rare de l'arène de Hache-tripes — nom FR à confirmer en jeu
      zone = "Féralas", zoneEn = "Feralas", niveau = 40, elite = true },
    { nomEn = "The Razza", -- chimère rare de l'arène de Hache-tripes — nom FR à confirmer en jeu
      zone = "Féralas", zoneEn = "Feralas", niveau = 40, elite = true },

    -- TANARIS
    { nomEn = "Murderous Blisterpaw", nom = "Murderous Blisterpaw", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 43, elite = false },
    { nomEn = "Warleader Krazzilak", nom = "Chef de guerre Krazzilak", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 45, elite = true },
    { nomEn = "Greater Firebird", nom = "Oiseau de feu supérieur", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 46, elite = false },
    { nomEn = "Jin'Zallah the Sandbringer", nom = "Jin'Zallah the Sandbringer", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 46, elite = true },
    { nomEn = "Kregg Keelhaul", nom = "Kregg Keelhaul", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 47, elite = false },
    { nomEn = "Cyclok the Mad", nom = "Cyclok le Fou", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 48, elite = false },
    { nomEn = "Haarka the Ravenous", nom = "Haarka le Vorace", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 50, elite = false },
    { nomEn = "Omgorn the Lost", nom = "Omgorn l'Égaré", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 50, elite = false },
    { nomEn = "Soriid the Devourer", nom = "Soriid le Dévoreur", aConfirmer = true, zone = "Tanaris", zoneEn = "Tanaris", niveau = 50, elite = false },

    -- AZSHARA
    { nomEn = "The Evalcharr", nom = "The Evalcharr", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 48, elite = false },
    { nomEn = "Varo'then's Ghost", nom = "Fantôme de Varo'then", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 48, elite = false },
    { nomEn = "Gatekeeper Rageroar", nom = "Gardien Rageroar", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 49, elite = false },
    { nomEn = "Antilos", nom = "Antilos", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 50, elite = false },
    { nomEn = "General Fangferror", nom = "General Fangferror", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 50, elite = false },
    { nomEn = "Lady Sesspira", nom = "Dame Sesspira", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 51, elite = false },
    { nomEn = "Magister Hawkhelm", nom = "Magister Hawkhelm", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 51, elite = false },
    { nomEn = "Master Feardred", nom = "Maître Feardred", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 51, elite = false },
    { nomEn = "Scalebeard", nom = "Scalebeard", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 52, elite = true },
    { nomEn = "Monnos the Elder", nom = "Monnos l'Ancien", aConfirmer = true, zone = "Azshara", zoneEn = "Azshara", niveau = 53, elite = true },

    -- GORGE DES VENTS BRÛLANTS (Searing Gorge)
    { nomEn = "Faulty War Golem", nom = "Golem de guerre défectueux", aConfirmer = true, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 46, elite = false },
    { nomEn = "Shleipnarr", nom = "Shleipnarr", aConfirmer = true, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 47, elite = false },
    { nomEn = "Rekk'tilac", nom = "Rekk'tilac", aConfirmer = true, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 48, elite = false },
    { nomEn = "Scald", nom = "Scald", aConfirmer = true, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 49, elite = false },
    { nomEn = "Slave Master Blackheart", nom = "Maître des esclaves Cœur-Noir", aConfirmer = true, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 50, elite = false },
    { nomEn = "Smoldar", nom = "Smoldar", aConfirmer = true, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 50, elite = false },
    { nomEn = "Highlord Mastrogonde", nom = "Généralissime Mastrogonde", aConfirmer = true, zone = "Gorge des Vents brûlants", zoneEn = "Searing Gorge", niveau = 51, elite = true },

    -- GANGREBOIS (Felwood)
    { nomEn = "Death Howl", nom = "Hurlement de la mort", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 49, elite = false },
    { nomEn = "Mongress", nom = "Mongress", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 50, elite = false },
    { nomEn = "Ragepaw", nom = "Ragepaw", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 51, elite = false },
    { nomEn = "The Ongar", nom = "The Ongar", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 51, elite = false },
    { nomEn = "Olm the Wise", nom = "Olm le Sage", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 52, elite = false },
    { nomEn = "Alshirr Banebreath", nom = "Alshirr Banebreath", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 54, elite = false },
    { nomEn = "Dessecus", nom = "Dessecus", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 56, elite = true },
    { nomEn = "Immolatus", nom = "Immolatus", aConfirmer = true, zone = "Gangrebois", zoneEn = "Felwood", niveau = 56, elite = true },

    -- TERRES FOUDROYÉES (Blasted Lands)
    { nomEn = "Fingat", nom = "Fingat", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 43, elite = false },
    { nomEn = "Mojo the Twisted", nom = "Mojo le Tordu", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 48, elite = false },
    { nomEn = "Deatheye", nom = "Deatheye", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 49, elite = false },
    { nomEn = "Grunter", nom = "Grunter", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 50, elite = false },
    { nomEn = "Ravage", nom = "Ravage", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 51, elite = false },
    { nomEn = "Spiteflayer", nom = "Spiteflayer", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 52, elite = false },
    { nomEn = "Clack the Reaver", nom = "Clack le Ravageur", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 53, elite = false },
    { nomEn = "Akubar the Seer", nom = "Akubar le Voyant", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 54, elite = false },
    { nomEn = "Magronos the Unyielding", nom = "Magronos l'Inflexible", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 56, elite = false },
    { nomEn = "Dreadscorn", nom = "Dreadscorn", aConfirmer = true, zone = "Terres foudroyées", zoneEn = "Blasted Lands", niveau = 57, elite = false },

    -- STEPPES ARDENTES (Burning Steppes)
    { nomEn = "The Behemoth", nom = "Le Béhémoth", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 50, elite = true },
    { nomEn = "Deathmaw", nom = "Deathmaw", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 53, elite = false },
    { nomEn = "Gorgon'och", nom = "Gorgon'och", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 54, elite = false },
    { nomEn = "Hahk'Zor", nom = "Hahk'Zor", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 54, elite = false },
    { nomEn = "Scarshield Quartermaster", nom = "Intendant Bouclier-scarifié", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 55, elite = true },
    { nomEn = "Terrorspark", nom = "Terrorspark", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 55, elite = false },
    { nomEn = "Malfunctioning Reaver", nom = "Ravageur défectueux", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 56, elite = false },
    { nomEn = "Thauris Balgarr", nom = "Thauris Balgarr", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 57, elite = false },
    { nomEn = "Gruklash", nom = "Gruklash", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 59, elite = false },
    { nomEn = "Hematos", nom = "Hématos", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 60, elite = true },
    { nomEn = "Volchan", nom = "Volchan", aConfirmer = true, zone = "Steppes Ardentes", zoneEn = "Burning Steppes", niveau = 60, elite = true },

    -- HURLEVENT
    { nomEn = "Sewer Beast", nom = "Bête des égouts", aConfirmer = true, zone = "Hurlevent", zoneEn = "Stormwind City", niveau = 50, elite = false },

    -- MALETERRES DE L'OUEST (Western Plaguelands)
    { nomEn = "Foulmane", nom = "Foulmane", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 52, elite = false },
    { nomEn = "Lord Maldazzar", nom = "Seigneur Maldazzar", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 56, elite = false },
    { nomEn = "Foreman Marcrid", nom = "Contremaître Marcrid", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 58, elite = false },
    { nomEn = "Putridius", nom = "Putridius", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 58, elite = true },
    { nomEn = "Scarlet Smith", nom = "Forgeron écarlate", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 58, elite = false },
    { nomEn = "Scarlet Executioner", nom = "Bourreau écarlate", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 60, elite = true },
    { nomEn = "Scarlet Judge", nom = "Juge écarlate", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 60, elite = false },
    { nomEn = "Scarlet Interrogator", nom = "Interrogateur écarlate", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 61, elite = true },
    { nomEn = "Foreman Jerris", nom = "Contremaître Jerris", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 62, elite = true },
    { nomEn = "The Husk", nom = "The Husk", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 62, elite = false },
    { nomEn = "Scarlet High Clerist", nom = "Haut clerc écarlate", aConfirmer = true, zone = "Maleterres de l'Ouest", zoneEn = "Western Plaguelands", niveau = 63, elite = true },

    -- MALETERRES DE L'EST (Eastern Plaguelands)
    { nomEn = "Duggan Wildhammer", nom = "Duggan Marteau-hardi", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 55, elite = false },
    { nomEn = "Deathspeaker Selendre", nom = "Héraut de la mort Selendre", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 56, elite = false },
    { nomEn = "Gish the Unmoving", nom = "Gish l'Immobile", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 56, elite = false },
    { nomEn = "Hed'mush the Rotting", nom = "Hed'mush le Pourrissant", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 57, elite = false },
    { nomEn = "Lord Darkscythe", nom = "Seigneur Darkscythe", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 57, elite = false },
    { nomEn = "Warlord Thresh'jin", nom = "Seigneur de guerre Thresh'jin", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 58, elite = false },
    { nomEn = "High General Abbendis", nom = "Grand général Abbendis", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 59, elite = true },
    { nomEn = "Zul'Brin Warpbranch", nom = "Zul'Brin Warpbranch", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 59, elite = false },
    { nomEn = "Ranger Lord Hawkspear", nom = "Seigneur rôdeur Hawkspear", aConfirmer = true, zone = "Maleterres de l'Est", zoneEn = "Eastern Plaguelands", niveau = 60, elite = false },

    -- HIVERPEINT (Winterspring)
    { nomEn = "Mezzir the Howler", nom = "Mezzir le Hurlant", aConfirmer = true, zone = "Hiverpré", zoneEn = "Winterspring", niveau = 55, elite = false },
    { nomEn = "General Colbatann", nom = "Général Colbatann", aConfirmer = true, zone = "Hiverpré", zoneEn = "Winterspring", niveau = 56, elite = true },
    { nomEn = "Rak'shiri", nom = "Rak'shiri", aConfirmer = true, zone = "Hiverpré", zoneEn = "Winterspring", niveau = 57, elite = false },
    { nomEn = "Azurous", nom = "Azurous", aConfirmer = true, zone = "Hiverpré", zoneEn = "Winterspring", niveau = 59, elite = true },
    { nomEn = "Grizzle Snowpaw", nom = "Grizzle Snowpaw", aConfirmer = true, zone = "Hiverpré", zoneEn = "Winterspring", niveau = 59, elite = false },
    { nomEn = "Kashoch the Reaver", nom = "Kashoch le Ravageur", aConfirmer = true, zone = "Hiverpré", zoneEn = "Winterspring", niveau = 60, elite = true },
    { nomEn = "Lady Hederine", nom = "Dame Hederine", aConfirmer = true, zone = "Hiverpré", zoneEn = "Winterspring", niveau = 61, elite = true },

    -- CRATÈRE D'UN'GORO
    { nomEn = "Ravasaur Matriarch", nom = "Matriarche ravasaure", aConfirmer = true, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 50, elite = false },
    { nomEn = "Uhk'loc", nom = "Uhk'loc", aConfirmer = true, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 52, elite = false },
    { nomEn = "Clutchmother Zavas", nom = "Mère de couvée Zavas", aConfirmer = true, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 54, elite = false },
    { nomEn = "Gruff", nom = "Gruff", aConfirmer = true, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 57, elite = true },
    { nomEn = "King Mosh", nom = "Roi Mosh", aConfirmer = true, zone = "Cratère d'Un'Goro", zoneEn = "Un'Goro Crater", niveau = 60, elite = true },

    -- SILITHUS
    { nomEn = "Krellack", nom = "Krellack", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 56, elite = false },
    { nomEn = "Gretheer", nom = "Gretheer", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 57, elite = false },
    { nomEn = "Rex Ashil", nom = "Rex Ashil", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 57, elite = true },
    { nomEn = "Grubthor", nom = "Grubthor", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 58, elite = false },
    { nomEn = "Huricanian", nom = "Huricanian", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 58, elite = false },
    { nomEn = "Zora", nom = "Zora", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 59, elite = true },
    { nomEn = "Lapress", nom = "Lapress", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 60, elite = true },
    { nomEn = "Twilight Lord Everun", nom = "Seigneur du Crépuscule Everun", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 60, elite = false },
    { nomEn = "Setis", nom = "Setis", aConfirmer = true, zone = "Silithus", zoneEn = "Silithus", niveau = 61, elite = true },
}
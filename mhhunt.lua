MHH_ADDON_NAME = "MHHunt"

-- ============================================
-- 1. BASE DE DONNÉES
-- ============================================
local defaults = {
    chasses = {},          -- [nom] = { kills = n, vu = true/false }
    missions = {},         -- [id mission] = date d'accomplissement
    decouverts = {},       -- rares Forever inconnus détectés automatiquement
    rencontres = {},       -- v0.119 : première rencontre de chaque rare (succès découverte)
    succes = {},           -- [id] = timestamp
    serie = 0,             -- chasses consécutives sans mourir
    zonesChassees = {},    -- [zone] = true
    points = 0,            -- points de guilde
    rangActuel = 1,        -- index dans RANGS (1 = Novice)
    contratHistorique = {}, -- [{ nom, date }] derniers contrats remplis
    primesGagnees = 0,     -- total de points gagnés via les primes
    menagerie = {},       -- spécimens capturés (piège + kill) : [{capture, nourri, gate}]
    enclosActif = nil,    -- biome de l'enclos affiché (savane par défaut)
    config = {
        banniere = true,
        son = true,
        emotePerdu = true, -- v0.35 : mise à genou quand le gibier est perdu (/hunt emote off)
        killSouple = true, -- true: participation compte, false: kill strict
        icone = "custom",  -- "wow" ou "custom" (Textures/carnet.tga)
        fond = "custom",   -- "wow" (couleur bois) ou "custom" (Textures/fond.tga parchemin)
        texUI = "custom",  -- "wow" ou "custom" : bandeau.tga / zone.tga / chrono.tga
        toast = "custom",  -- "custom" (toast1.tga validations + toast2.tga annonces) ou "wow"
        musique = "wow",   -- "off" | "wow" (MPQ du jeu) | "custom" (addon MHAmbiance)
        -- NB : taille d'affichage du bandeau custom FIXE (660x254, ratio
        -- de bandeau.tga) — les anciennes clés bandeauL/H sont ignorées
        chronoMode = "minimap", -- "full" (grand) | "minimap" (mini) | "off" (/hunt chrono)
        gibierVu = false,   -- intro guidée : l'onglet Gibier a-t-il été visité ?
        langue = "fr",      -- "fr" | "en" : langue de l'interface (/hunt langue)
    },
}

local DB
local RaffraichirCarnet -- déclarée ici, définie dans la section Carnet (UI)
local carnet            -- idem, créé dans la section Carnet
local RaffraichirAccueil -- idem, page Accueil (appellée par ContratQuotidien)
MHH_MontrerSerment = function() end -- forward : panneau du serment (voie
-- souple/stricte), défini dans la section tuto — GLOBALE préfixée MHH_
-- pour économiser les 200 locales du chunk principal (LUA_WARNING v0.62)

-- ============================================
-- 3. LOCALISATION (FR / EN) — publication
-- ============================================
-- Le code garde le texte FR en clair, enveloppé dans L("...") : L renvoie
-- le FR tel quel, sauf si /hunt langue en (DB.config.langue = "en") —
-- alors la table en = { ["<texte FR>"] = "<texte EN>" } prend le dessus.
-- Le dictionnaire ci-dessous est généré depuis la passe de traduction :
-- noms de bêtes/zones/identifiants volontairement ABSENTS (ils restent
-- FR : les noms affichés en jeu viennent du client de toute façon).
MH_TEXTES = {
    fr = {
        tab_accueil = "Accueil", tab_profil = "Guilde", tab_monstres = "Gibier",
        tab_contrats = "Contrats", tab_missions = "Missions", tab_succes = "Succès",
        tab_cuisine = "Cuisine", tab_menagerie = "Ménagerie", tab_options = "Options",
        langue_changee = "Langue de l'addon : Français. |cffa58b54(/reload pour rafraîchir le carnet)|r",
    },
    en = {
        tab_accueil = "Home", tab_profil = "Guild", tab_monstres = "Prey",
        tab_contrats = "Contracts", tab_missions = "Quests", tab_succes = "Achievements",
        tab_cuisine = "Cooking", tab_menagerie = "Menagerie", tab_options = "Options",
        langue_changee = "Addon language: English. |cffa58b54(/reload to refresh the journal)|r",
        ["Croiser pour la première fois un rare"] = "Encounter a rare for the first time",
        ["Croiser 5 rares différents"] = "Encounter 5 different rares",
        ["Croiser 10 rares différents"] = "Encounter 10 different rares",
        ["Croiser 25 rares différents"] = "Encounter 25 different rares",
        ["Croiser tous les rares d'une même région"] = "Encounter every rare of a single region",
        ["Avoir 5 pensionnaires en enclos"] = "Have 5 residents in the pen",
        ["Œil du traqueur"] = "Eye of the Tracker",
        ["Vieille connaissance des sentiers"] = "Old Trail Acquaintance",
        ["Naturaliste régional"] = "Regional Naturalist",
        ["Éleveur"] = "Breeder",
        ["|cffffd100[MH Hunt]|r Première rencontre : |cffffff00"] = "|cffffd100[MH Hunt]|r First encounter: |cffffff00",
        ["|cffffd100[MH Hunt]|r Tous les succès remis à zéro — ils se débloqueront de nouveau à la prochaine action qui les valide."] = "|cffffd100[MH Hunt]|r All achievements reset — they will unlock again the next time their condition is met.",
        ["|cffffd100[MH Hunt]|r Missions remises à zéro — mission active abandonnée, toutes les missions redeviennent disponibles."] = "|cffffd100[MH Hunt]|r Quests reset — active quest abandoned, all quests available again.",
        ["|cffffd100[MH Hunt]|r Enclos vidé — les spécimens sont partis dans la nature (fiches et trophées conservés)."] = "|cffffd100[MH Hunt]|r Pen emptied — the specimens are back in the wild (cards and trophies kept).",
        ["|cffffd100[MH Hunt]|r Carnet vidé — fiches et comptes de chasse effacés (succès, trophées et points de guilde conservés)."] = "|cffffd100[MH Hunt]|r Journal emptied — cards and kill counts erased (achievements, trophies and guild points kept).",
        [" chasse"] = " hunt",
        [" cm"] = " cm",
        [" chasses"] = " hunts",
        [" chasse, "] = " hunt, ",
        [" chasse au compteur."] = " hunt on the counter.",
        [" chasse réussie."] = " hunt successful.",
        ["Trophée prélevé : "] = "Trophy taken: ",
        ["Trophées prélevés : "] = "Trophies taken: ",
        [" découpe manquée (le morceau s'est abîmé)."] = " carve missed (the piece was ruined).",
        [" découpes manquées (les morceaux se sont abîmés)."] = " carves missed (the pieces were ruined).",
        [" gibier"] = " game",
        [" gibiers"] = " game",
        [" niv. "] = " lvl ",
        [" s !|r"] = "s!|r",
        [" au carnet|r"] = " to the journal|r",
        [" est suspendue."] = " is suspended.",
        [" et ciblez-le pour lancer la chasse."] = " and target it to start the hunt.",
        [" mort sous le viseur"] = " dead in the sights",
        [" pensionnaire(s) nourri(s) d'une viande chacun."] = " resident(s) fed one meat each.",
        [" se perd…|r Chasse suspendue — re-ciblez-la pour reprendre."] = " is lost…|r Hunt suspended — re-target it to resume.",
        [" spécimens en enclos."] = " specimens in the pen.",
        [" tombe à point nommé — le gibier ne devrait pas tarder."] = " comes at just the right time — the game can't be far.",
        [" — carnet complet !"] = " — journal complete!",
        [" — condition RÉUNIE, foncez !"] = " — condition MET, go get it!",
        [" — en piste, chasseur !"] = " — on the trail, hunter!",
        [" — encore "] = " — still ",
        [" — le carnet attend ses preuves"] = " — the journal awaits proof",
        [" — le chrono continue."] = " — the clock keeps running.",
        [" — objective : |cffffff00"] = " — objective: |cffffff00",
        [" — rang maximum atteint"] = " — max rank reached",
        [" — sous la "] = " — under the ",
        [" — verrouillé|r"] = " — locked|r",
        [" — « "] = " — \" ",
        [") : |cffffd100"] = "): |cffffd100",
        [") — /hunt add pour l'inscrire au carnet."] = ") — /hunt add to register it in the journal.",
        [") — clic droit sur la minimap pour supprimer."] = ") — right-click the minimap to remove.",
        [") — inscrit au carnet."] = ") — registered in the journal.",
        [") — prime : +20 points !"] = ") — bounty: +20 points!",
        [") — prime : +20 points.\n|cffa58b54Clic : ouvrir le carnet.|r"] = ") — bounty: +20 points.\n|cffa58b54Click: open the journal.|r",
        [") — votre contrat en cours prime."] = ") — your current contract takes priority.",
        ["). Rapportez-le pour +20 points !"] = "). Turn it in for +20 points!",
        [")\n|cffa58b54Rapportez cette prise pour la prime de +20 points.|r"] = ")\n|cffa58b54Turn in this kill for the +20 point bounty.|r",
        [")|r — "] = ")|r — ",
        [")|r — |cff8a6d3bnon abattu :|r "] = ")|r — |cff8a6d3bnot yet slain:|r ",
        [")|r — |cff8a6d3bpas en enclos :|r "] = ")|r — |cff8a6d3bnot in the pen:|r ",
        ["+10 points sur la prochaine prise."] = "+10 points on your next kill.",
        ["+25 points sur la prochaine prise."] = "+25 points on your next kill.",
        ["+60 points sur la prochaine prise."] = "+60 points on your next kill.",
        [", la traque attendra."] = ", the hunt can wait.",
        [", nourri il y a "] = ", fed ",
        ["/5) — /hunt lisere 0 pour revenir au rang réel."] = "/5) — /hunt lisere 0 to revert to your real rank.",
        ["10 chasses consécutives sans mourir"] = "10 consecutive hunts without dying",
        ["10 chasses réussies"] = "10 successful hunts",
        ["100 chasses réussies"] = "100 successful hunts",
        ["25 chasses réussies"] = "25 successful hunts",
        ["5 chasses consécutives sans mourir"] = "5 consecutive hunts without dying",
        ["5 découvertes de rares inconnus"] = "5 unknown rares discovered",
        ["Abandonne le contrat en cours. La prime du contrat (+5, +10 ou +20 points) est perdue, et la chasse en cours (s'il y en a une) continue normalement."] = "Abandons the current contract. The contract bounty (+5, +10 or +20 points) is lost, and any hunt in progress continues normally.",
        ["Abattre un monstre du carnet pris dans un piège"] = "Slain a journal monster caught in a trap",
        ["Abattre une bête rare de niveau >= au vôtre"] = "Slay a rare at least your own level",
        ["Abattre une bête rare de niveau supérieur au vôtre"] = "Slay a rare above your own level",
        ["Apprenti du carnet"] = "Journal Apprentice",
        ["Au-dessus de la piste : "] = "Above the trail: ",
        ["Aucune cible aujourd'hui — connectez-vous pour la découvrir."] = "No target today — log in to discover it.",
        ["Ami des profondeurs"] = "Friend of the Deep",
        ["Bannières de chasse"] = "Hunt banners",
        ["Bleu de la chasse"] = "Hunt Blue",
        ["Bleu du carnet"] = "Journal Blue",
        ["C'est LE moment : "] = "This is THE moment: ",
        ["CARTE DE CHASSEUR — "] = "HUNTER CARD — ",
        ["CHASSE EN COURS"] = "HUNT IN PROGRESS",
        ["CHASSE RÉUSSIE — MISSION ACCOMPLIE"] = "HUNT SUCCESSFUL — QUEST COMPLETE",
        ["CHASSE ÉCHOUÉE"] = "HUNT FAILED",
        ["CIBLE DU JOUR"] = "TARGET OF THE DAY",
        ["CONTRAT ACTIF"] = "ACTIVE CONTRACT",
        ["Capture-le : mène la chasse jusqu'au bout,"] = "Hunt it down to the very end,",
        ["Capturable"] = "Capturable",
        ["Une féline rapide et convoitée des chasseurs : sa cadence d'attaque fait des étincelles."] = "A quick, sought-after feline among hunters: her attack pace sparkles.",
        ["Une hyène qui ricane dans la poussière des Tarides — on l'entend avant de la voir."] = "A snickering hyena in the Barrens dust — you hear her before you see her.",
        ["Un serpent des vents qui plane au-dessus des Tarides : sa lame est un croc."] = "A wind serpent gliding over the Barrens: its blade is a fang.",
        ["Sa toile, près des marais des Paluns, boit plus vite qu'elle ne mord."] = "Her web, by the Wetlands marshes, drinks faster than she bites.",
        ["Une harpie du Dun Morogh : son hurlement glace le sang des nains au petit matin."] = "A Dun Morogh harpy: her howl chills dwarven blood at dawn.",
        ["Assiette du pisteur"] = "Tracker's Platter",
        ["Pain de miel du régisseur"] = "Steward's Honey Bread",
        ["Plat du jour — moitié prix"] = "Daily special — half cost",
        ["Plat du jour :"] = "Daily special:",
        ["CARNET COMPLET — tous les succès sont obtenus !"] = "COMPLETE JOURNAL — every achievement earned!",
        ["Tous les succès du chasseur sont obtenus !"] = "Every hunter achievement earned!",
        ["(moitié prix)"] = "(half cost)",
        ["Bourse du chasseur"] = "Hunter's pouch",
        ["Repas préparé"] = "Prepared meal",
        ["La première recette que l'on apprend au bivouac."] = "The first recipe every camper learns.",
        ["L'herbe aromatique réveille la viande de gibier."] = "Aromatic herbs wake up the game meat.",
        ["Le plat des vieux pisteurs : tient au corps pour de longues traques."] = "Old trackers' fare: hearty enough for long hunts.",
        ["Le péché mignon du régisseur — les pensionnaires en raffolent."] = "The steward's guilty pleasure — the menagerie loves it.",
        ["Un plat de légende, digne des plus grandes chasses."] = "A legendary dish, worthy of the greatest hunts.",
        ["Récoltée sur la dépouille (40% de chance par prise)."] = "Harvested from kills (40% chance per take).",
        ["Cueillette en zone de chasse (25% de chance)."] = "Gathered in hunting grounds (25% chance).",
        ["Butiné sur les rares abattus (10% de chance)."] = "Gathered from slain rares (10% chance).",
        ["Sac plein — cuisine pour libérer de la place."] = "Pouch full — cook to free up space.",
        ["Sac de viande plein — la prise se perd (cuisine !)."] = "Meat pouch full — the take is lost (cook!).",
        ["Pot de miel plein — la prise se perd (cuisine !)."] = "Honey jar full — the take is lost (cook!).",
        ["Sac d'herbes plein — la cueillette se perd (cuisine !)."] = "Herb pouch full — the pick is lost (cook!).",
        ["En bourse : "] = "In pouch: ",
        ["— s'appliquera à la prochaine prise."] = "— will apply to the next take.",
        ["Aucun — cuisinez pour bonifier la prochaine chasse."] = "None — cook to boost your next hunt.",
        ["Ingrédients :"] = "Ingredients:",
        ["Cuisiner"] = "Cook",
        ["Capturé"] = "Captured",
        ["Carnet usé"] = "Worn Journal",
        ["Carnet, heure de l'observation : "] = "Journal, time of the sighting: ",
        ["Cartographe des terres sauvages"] = "Wilderness Cartographer",
        ["Cataloguer 20 monstres"] = "Catalog 20 monsters",
        ["Cataloguer 50 monstres"] = "Catalog 50 monsters",
        ["Ce spécimen commence à être bien connu : "] = "This specimen is becoming well known: ",
        ["Ce worg mord avec l'ombre — les bûcherons en parlent encore à voix basse. Bois de la Pénombre, après minuit. Bonne chance."] = "This worg bites with shadow — the loggers still speak of it in whispers. Duskwood, past midnight. Good luck.",
        ["Ce worg mord avec l'ombre. Les chasseurs qui l'ont affronté en gardent des frissons noirs."] = "This worg bites with shadow. The hunters who faced it still get dark chills.",
        ["Cette chose rode dans le cimetière des Bois de la Pénombre. Les gardes n'osent plus y descendre."] = "This thing roams the Duskwood graveyard. The guards no longer dare go down there.",
        ["Chasse au couteau"] = "Knife Hunt",
        ["Chasse à la tombée de la nuit"] = "Hunt at Nightfall",
        ["Chasses : |cffffd100"] = "Hunts: |cffffd100",
        ["Chasses dans 10 zones différentes"] = "Hunts in 10 different zones",
        ["Chasses réussies dans 10 zones différentes"] = "Successful hunts in 10 different zones",
        ["Chasses totales : |cffffd100"] = "Total hunts: |cffffd100",
        ["Chasseur accompli"] = "Accomplished Hunter",
        ["Chasseur aguerri"] = "Seasoned Hunter",
        ["Chasseur de l'apocalypse"] = "Hunter of the Apocalypse",
        ["Chasseur de la guilde"] = "Guild Hunter",
        ["Chasseur de pièges"] = "Trapper",
        ["Chasseur nocturne"] = "Night Hunter",
        ["Chrono de chasse"] = "Hunt Timer",
        ["Civet épicé"] = "Spiced Stew",
        ["Clic : en faire votre contrat actif."] = "Click: make it your active contract.",
        ["Clic : famille de titre suivante"] = "Click: next title family",
        ["Épingler en favori"] = "Pin as favorite",
        ["Retirer des favoris"] = "Remove from favorites",
        ["Spécimen encore mal connu du carnet."] = "Specimen still poorly known to the journal.",
        ["Mission acceptée :"] = "Mission accepted:",
        ["mission en cours"] = "mission in progress",
        [" |cffa58b54(~"] = " |cffa58b54(~",
        [" cm d'envergure)|r"] = " cm wingspan)|r",
        ["Clic : le sélectionner (nourrir / gâter / relâcher)."] = "Click: select it (feed / pet / release).",
        ["Clic : voir ses conditions."] = "Click: view its conditions.",
        ["Clic droit : Succès"] = "Right-click: Achievements",
        ["Clic gauche : Carnet de chasse"] = "Left-click: Hunting Journal",
        ["Clé à molette du Junior (trophée)"] = "Junior's Wrench (trophy)",
        ["Compris !"] = "Got it!",
        ["Comptage des prises"] = "Kill Count",
        ["Contrat rempli"] = "Contract fulfilled",
        ["OFFRE DU JOUR"] = "DAILY OFFER",
        ["CONTRATS DE LA GUILDE"] = "GUILD CONTRACTS",
        ["(cible du jour)"] = "(target of the day)",
        [") — prime : +"] = ") — bounty: +",
        [" points !"] = " points!",
        [" !|r (+"] = " !|r (+",
        ["Nouvelles offres à minuit."] = "New offers at midnight.",
        ["|cff8a6d3bAucun contrat en cours — prenez une offre du jour ci-dessus.|r"] = "|cff8a6d3bNo active contract — take a daily offer above.|r",
        ["|cffffd100[MH Hunt]|r |cffc9a24aOffres de chasse du jour (+5 points chacune) : voir la fenêtre Contrats.|r"] = "|cffffd100[MH Hunt]|r |cffc9a24aDaily hunt offers (+5 points each): see the Contracts window.|r",
        ["Couteau de campagne du vieux Hemet"] = "Old Hemet's Field Knife",
        ["Croisé de l'aube"] = "Dawn Crusader",
        ["Cuisinez toujours avant une prime : la cible du jour mérite un repas de fête."] = "Always cook before a bounty: the target of the day deserves a feast.",
        ["Curieux de butin"] = "Curious About Loot",
        ["Cœur tendre"] = "Soft Heart",
        ["DERNIÈRE PRISE"] = "LATEST KILL",
        ["Danse de la pluie"] = "Rain Dance",
        ["Dernière : "] = "Latest: ",
        ["Dernière prise : |cffffd100"] = "Latest kill: |cffffd100",
        ["Découvertes : |cffffd100"] = "Discoveries: |cffffd100",
        ["Découvrir 5 rares inconnus"] = "Discover 5 unknown rares",
        ["Découvrir un rare inconnu"] = "Discover an unknown rare",
        ["Dénicheur de sentiers"] = "Trailblazer",
        ["ERREUR victoire : "] = "VICTORY ERROR: ",
        ["EXTÉNUÉ !"] = "EXHAUSTED!",
        ["Elle rôde sous une autre météo — le ciel, en ce moment : "] = "It roams under other weather — the sky right now: ",
        ["En chasse depuis "] = "Hunting for ",
        ["En cours"] = "In progress",
        ["Exorciste itinérant"] = "Wandering Exorcist",
        ["Famille : "] = "Family: ",
        ["Familles : "] = "Families: ",
        ["Faveur (à contre-cœur) de D.E.H.T.A."] = "(druidical) Favor of D.E.H.T.A.",
        ["Festin de légende"] = "Legendary Feast",
        ["Flamme tenace"] = "Tenacious Flame",
        ["Gabarit : inconnu"] = "Size: unknown",
        ["Gabarit : "] = "Size: ",
        ["Gabarit : non mesuré"] = "Size: not measured",
        ["Gabarit : ~"] = "Size: ~",
        ["2200 cm"] = "2200 cm",
        ["Niveau observé : "] = "Observed level: ",
        ["Niveaux observés : "] = "Observed levels: ",
        ["Gabarit : niv "] = "Size: lvl ",
        ["Grand gibier"] = "Big Game",
        ["Grotte du clan Mosh'Ogg"] = "Mosh'Ogg Clan Cave",
        ["HISTORIQUE DES PRIMES"] = "BOUNTY HISTORY",
        ["Habitat : "] = "Habitat: ",
        ["Habitat inconnu"] = "Unknown habitat",
        ["Herbe aromatique"] = "Aromatic Herb",
        ["Homme du terrain"] = "Field Man",
        ["Il ne ronronne pas, il ne piste pas : il attend. La panthère que l'on ne voit qu'une fois."] = "It doesn't purr, it doesn't stalk: it waits. The panther you only see once.",
        ["Il sort de la mer à la nuit tombée et remonte la rivière. Il en faut plusieurs pour le vaincre."] = "It comes out of the sea at nightfall and swims up the river. It takes more than one to bring it down.",
        ["Immobile entre les épis… jusqu'à ce qu'on s'approche"] = "Motionless among the wheat… until you get close",
        ["JOURNAL DE CHASSE"] = "HUNTING JOURNAL",
        ["Je ne chasse plus, moi, je porte les affaires. Mais pour celle-là… j'aimerais lire la fin du carnet."] = "I don't hunt anymore; I carry the gear. But for this one… I'd like to read the end of the journal.",
        ["L'araignée des Collines. Sa toile se tend à l'ouest, parmi les arbres morts."] = "The spider of Duskwood. Its web stretches to the west, among the dead trees.",
        ["L'ombre de l'Orne"] = "The Shadow of Duskwood",
        ["La chasse"] = "The Hunt",
        ["La chasse au couteau se prépare la veille : réparez, cuisinez, dormez."] = "The knife hunt is prepared the day before: repair, cook, sleep.",
        ["La faux qui fauche"] = "The Reaping Scythe",
        ["La nuit, les yeux brillent avant les crocs. Surveillez les fourrés sombres."] = "At night, the eyes shine before the fangs. Watch the dark thickets.",
        ["La veuve de la brume"] = "The Widow of the Mist",
        ["Le Rateau a distancé des cavaliers sur le plateau de Mulgore. Montre-lui qu'on ne gagne pas toujours en fuyant."] = "The Rake outran riders across the Mulgore plains. Show it that fleeing doesn't always win.",
        ["Le camp Nesingwary confie ses vieux dossiers. Une mission à la fois, dans l'ordre."] = "The Nesingwary camp hands out its old files. One quest at a time, in order.",
        ["Le carnet dit qu'elle paraît sous certains cieux. Ici, pour l'instant : "] = "The journal says it appears under certain skies. Here, right now: ",
        ["Le chasseur qui court laisse des traces ; le chasseur qui traque n'en laisse aucune."] = "The hunter who runs leaves tracks; the hunter who stalks leaves none.",
        ["Le ciel s'y prête : "] = "The sky is right for it: ",
        ["Le ciel, ici : "] = "The sky, here: ",
        ["Le colosse du cratère"] = "The Colossus of the Crater",
        ["Le démon du plateau"] = "The Demon of the Plateau",
        ["Le gibier de haut niveau zigzague : laissez-le s'essouffler, frappez au retour."] = "High-level game zigzags: let it tire itself out, strike on the turn.",
        ["Le lion noir qui dort sous le grand arbre, au nord de la Baie du Butin."] = "The black lion that sleeps beneath the great tree, north of Booty Bay.",
        ["Le naturaliste"] = "The Naturalist",
        ["Le piège posé avant la traque vaut dix potions avalées après le combat."] = "A trap set before the stalk is worth ten potions drunk after the fight.",
        ["Le premier croc"] = "The First Fang",
        ["Le record du carnet n'est pas une fierté : c'est un défi. Battez-le d'une seconde."] = "The journal record is no badge of pride: it's a challenge. Beat it by a second.",
        ["Le roi des courants d'air. Son ombre passe sur vous avant son cri."] = "The king of the updrafts. Its shadow crosses you before its cry.",
        ["Le seigneur à crinière"] = "The Maned Lord",
        ["Le sol tremble bien avant qu'on ne le voie"] = "The ground trembles long before you see it",
        ["Le vieux croc des marées. Sa mâchoire claque comme une porte de prison."] = "The old tide fang. Its jaw slams like a prison door.",
        ["Le zèbre rapide du plateau. Il faut des jambes pour le suivre."] = "The fast zebra of the plateau. You'll need legs to keep up.",
        ["Les crocs du crépuscule"] = "Fangs of the Dusk",
        ["Les empreintes fraîches ont des bords nets ; les vieilles s'effritent sous la pluie."] = "Fresh tracks have clean edges; old ones crumble in the rain.",
        ["Les miel et herbes ne se récoltent pas en fugue : la zone de chasse regorge de tout."] = "Honey and herbs aren't gathered at a run: the hunting zone abounds with everything.",
        ["Les éléments"] = "The Elements",
        ["Looter un objet bleu (ou mieux) sur un monstre du carnet"] = "Loot a blue (or better) item from a journal monster",
        ["Lunette usée du Junior"] = "Junior's Worn Scope",
        ["Légende de la chasse"] = "Hunt Legend",
        ["Légende vivante"] = "Living Legend",
        ["Légendes locales"] = "Local Legends",
        ["Ma zone"] = "My Zone",
        ["Main chaude"] = "Warm Hand",
        ["Meilleure série sans mourir : |cffffd100"] = "Best streak without dying: |cffffd100",
        ["Miel sauvage"] = "Wild Honey",
        ["Mission accomplie"] = "Quest complete",
        ["Mon père a raté la mâchoire de ce vieil ours il y a vingt ans. Termine ce qu'il a commencé — et ne me parle pas de chance."] = "My father missed this old bear's jaw twenty years ago. Finish what he started — and don't talk to me about luck.",
        ["Monstres catalogués : |cffffd100"] = "Monsters cataloged: |cffffd100",
        ["Mule de Barnil pour un voyage (clin d'œil)"] = "Barnil's Mule for a trip (wink)",
        ["Métamorphe des bois"] = "Shapeshifter of the Woods",
        ["Naturaliste débutant"] = "Beginning Naturalist",
        ["Nez fin"] = "Sharp Nose",
        ["Niveau "] = "Level ",
        ["Nouveau rang : "] = "New rank: ",
        ["Objectif : |cffffff00"] = "Objective: |cffffff00",
        ["Observations en cours."] = "Observations in progress.",
        ["Obtenus : |cffffd100"] = "Earned: |cffffd100",
        ["Ombre aux aguets"] = "Shadow on Watch",
        ["Pas encore : le ciel montre "] = "Not yet: the sky shows ",
        ["Patte du prédateur"] = "Predator's Paw",
        ["Points de chasse : "] = "Hunt points: ",
        ["Première : "] = "First: ",
        ["Première chasse"] = "First Hunt",
        ["Première découverte"] = "First Discovery",
        ["Première page du carnet d'Hemet"] = "First Page of Hemet's Journal",
        ["Preneur de notes"] = "Note Taker",
        ["Promotion de guilde"] = "Guild Promotion",
        ["Rang de chasseur : "] = "Hunter rank: ",
        ["Rapportez cette prise pour une prime de +20 points."] = "Turn in this kill for a +20 point bounty.",
        ["Rechercher un succès..."] = "Search an achievement...",
        ["Regardez les charognards : ils tournent là où le gibier blessé s'est couché."] = "Watch the carrion birds: they circle where wounded game has lain down.",
        ["Relâcher un spécimen de la ménagerie"] = "Release a menagerie specimen",
        ["Royaumes de l'Est"] = "Eastern Kingdoms",
        ["Réussir une chasse entre 22h et 6h (serveur)"] = "Complete a hunt between 10pm and 6am (server)",
        ["Réussir une chasse pendant une pluie de feu"] = "Complete a hunt during a firestorm",
        ["Réussir une chasse sous la neige"] = "Complete a hunt in the snow",
        ["Réussir une chasse sous la pluie"] = "Complete a hunt in the rain",
        ["Révélateur de légendes"] = "Legend Revealer",
        ["Rôde à la nuit tombée"] = "Roams at Nightfall",
        ["Rôti du chasseur"] = "Hunter's Roast",
        ["SPÉCIMEN CAPTURÉ !"] = "SPECIMEN CAPTURED!",
        ["Sage des esprits"] = "Spirit Sage",
        ["Sans égratignure : "] = "Without a scratch: ",
        ["Sans une égratignure"] = "Without a Scratch",
        ["Serpent des marais, patient comme la vase. On le voit trop tard, jamais deux fois."] = "Swamp serpent, patient as mud. You see it too late, never twice.",
        ["Ses bonds laissent des traces profondes dans la poussière des Tarides."] = "Its leaps leave deep tracks in the Barrens dust.",
        ["Ses griffes tombent plus vite que l'œil ne cligne. Les prairies l'entendent avant de le voir."] = "Its claws fall faster than the eye blinks. The plains hear it before they see it.",
        ["Sons de l'addon"] = "Addon Sounds",
        ["Sorcier de guerre"] = "Warlock",
        ["Spécimen capturé"] = "Specimen captured",
        ["Spécimen en enclos — "] = "Specimen in the pen — ",
        ["Spécimen en enclos"] = "Specimen in the pen",
        ["Spécimen encore mal connu du carnet. Première prise : "] = "Specimen still poorly known to the journal. First kill: ",
        ["Spécimen non capturé"] = "Specimen not captured",
        ["Succès obtenus : |cffffd100"] = "Achievements earned: |cffffd100",
        ["Sur la piste"] = "On the Trail",
        ["Série de 5"] = "Streak of 5",
        ["Série sans mourir : |cffffd100"] = "Streak without dying: |cffffd100",
        ["Teneur de registre"] = "Record Keeper",
        ["Tisse ses toiles quand la pluie bat le marais"] = "Spins its webs when the rain beats the swamp",
        ["Tout chasseur commence quelque part. Rapporte-moi le dard du Flagelleur, et on parlera des vrais trophées."] = "Every hunter starts somewhere. Bring me the Flayer's sting, and we'll talk real trophies.",
        ["Toute une panoplie"] = "A Full Kit",
        ["Traqueur de l'inconnu"] = "Tracker of the Unknown",
        ["Traqueur des neiges"] = "Snow Tracker",
        ["Traqueur des profondeurs"] = "Tracker of the Deep",
        ["Trophées prélevés : |cffffd100"] = "Trophies taken: |cffffd100",
        ["Tuer Humar, Vif-Crinière et Takk — les trois fiertés des plaines"] = "Slain Humar, Swiftmane and Takk — the three prides of the plains",
        ["Tuer Rotheap dans les Paluns"] = "Slain Rotheap in the Wetlands",
        ["Tuer son premier monstre du carnet"] = "Slain your first journal monster",
        ["Tuer un monstre du carnet sans perdre plus de 25% de vie"] = "Slain a journal monster losing no more than 25% health",
        ["Tuer un monstre du carnet sans perdre un point de vie"] = "Slain a journal monster without losing a single point of health",
        ["Un ancien de la Ruche-Sacrenuit, exilé loin de sa reine."] = "An elder of the Hive-Sacrenuit, exiled far from its queen.",
        ["Un lion des montagnes à crinière en broussaille. Les gnolls l'appellent « le mauvais temps »."] = "A mountain lion with a bramble mane. The gnolls call it \"bad weather\".",
        ["Un loup esprit qui hante les plaines. Blessez-le, et le hurlement qu'il rend ne s'oublie pas."] = "A spirit wolf haunting the plains. Wound it, and the howl it gives back is not forgotten.",
        ["Un monstre pris dans un piège révèle ses vraies faiblesses. Observez avant de frapper."] = "A monster caught in a trap reveals its true weaknesses. Observe before striking.",
        ["Un murloc qui chante faux, mais qui croque juste. Le bord de l'eau est à lui."] = "A murloc who sings off-key, but bites true. The water's edge is his.",
        ["Un rare ne se montre jamais deux fois au même endroit. Enfin... presque jamais."] = "A rare never shows itself twice in the same place. Well... almost never.",
        ["Une bête affamée sort à l'aube ; une bête repue dort au soleil. Choisissez votre heure."] = "A hungry beast comes out at dawn; a sated one sleeps in the sun. Choose your hour.",
        ["Une faux des champs qui a appris à faucher autre chose que le blé. Les épouvantails l'évitent."] = "A field scythe that learned to reap more than wheat. The scarecrows avoid it.",
        ["Une gueule d'un autre âge, pleine de dents usées qui tiennent encore bon."] = "A maw from another age, full of worn teeth that still hold fast.",
        ["Une moissonneuse qui a appris à faucher autre chose que le blé. Les champs sentent l'huile et la peur. Débrouillez-la."] = "A harvest reaper that learned to reap more than wheat. The fields smell of oil and fear. Unmake it.",
        ["Une nagà qui se prend pour une princesse de la côte. Sa couronnement, c'est vos os."] = "A naga who fancies herself a princess of the coast. Her coronation is your bones.",
        ["Une série sans mourir, ça se protège : le meilleur combat est celui qu'on évite."] = "A streak without dying is worth protecting: the best fight is the one you avoid.",
        ["Viande de gibier"] = "Game Meat",
        ["Vieil homme du métier"] = "Old Hand",
        ["Vieille connaissance du carnet — "] = "An old acquaintance of the journal — ",
        ["Vingt ans que je rêve de sa crinière noire. Le monde dira que j'ai vieilli — le carnet dira que j'ai eu raison."] = "Twenty years I've dreamed of its black mane. The world will say I've grown old — the journal will say I was right.",
        ["Zones de chasse visitées : |cffffd100"] = "Hunting zones visited: |cffffd100",
        ["Zones visitées : |cffffd100"] = "Zones visited: |cffffd100",
        ["Zoologue de terrain"] = "Field Zoologist",
        ["  |cffa0ff50(+20 points)|r"] = "  |cffa0ff50(+20 points)|r",
        ["  |cffc9a24a•|r |cffffd100/hunt add / remove|r : ajouter/retirer la cible au carnet (mode auto)."] = "  |cffc9a24a•|r |cffffd100/hunt add / remove|r: add/remove the target to the journal (auto mode).",
        ["  |cffc9a24a•|r |cffffd100/hunt banner on/off|r, |cffffd100/hunt sound on/off|r : bannières, sons."] = "  |cffc9a24a•|r |cffffd100/hunt banner on/off|r, |cffffd100/hunt sound on/off|r: banners, sounds.",
        ["  |cffc9a24a•|r |cffffd100/hunt carte <joueur>|r : envoyer votre carte de chasseur (rang, points, enclos) à un autre chasseur de l'addon."] = "  |cffc9a24a•|r |cffffd100/hunt carte <player>|r: send your hunter card (rank, points, pen) to another hunter using the addon.",
        ["  |cffc9a24a•|r |cffffd100/hunt chrono full/minimap/off|r : chrono de chasse. |cffffd100/hunt musique off/wow/custom|r : musiques."] = "  |cffc9a24a•|r |cffffd100/hunt chrono full/minimap/off|r: hunt timer. |cffffd100/hunt musique off/wow/custom|r: music.",
        ["  |cffc9a24a•|r |cffffd100/hunt debug|r : diagnostic. |cffffd100/hunt armes|r : diagnostic des armes. |cffffd100/hunt export|r : liste « nom | id | zone » des découvertes (réconciliation Forever). |cffc9a24a•|r |cffffd100/hunt reset succes|missions|menagerie|carnet|r : remises à zéro ciblées. |cffffd100/hunt reset|r : tout effacer (irréversible)."] = "  |cffc9a24a•|r |cffffd100/hunt debug|r: diagnostics. |cffffd100/hunt armes|r: weapons diagnostic. |cffffd100/hunt export|r: \"name | id | zone\" list of discoveries (Forever reconciliation). |cffc9a24a•|r |cffffd100/hunt reset succes|missions|menagerie|carnet|r: targeted resets. |cffffd100/hunt reset|r: erase everything (irreversible).",
        ["  |cffc9a24a•|r |cffffd100/hunt icon custom/wow|r, |cffffd100/hunt parchment custom/wow|r : icône minimap, fond du carnet."] = "  |cffc9a24a•|r |cffffd100/hunt icon custom/wow|r, |cffffd100/hunt parchment custom/wow|r: minimap icon, journal background.",
        ["  |cffc9a24a•|r |cffffd100/hunt kill loose/strict|r : participation ou coup de grâce pour valider une prise."] = "  |cffc9a24a•|r |cffffd100/hunt kill loose/strict|r: participation or killing blow to validate a kill.",
        ["  |cffc9a24a•|r |cffffd100/hunt test zone|banniere|chrono|en chasse|prime|wow|tampon alliance|horde|icones|griffe|patte|mission|rumeur|succes|promotion|intrus|menagerie|r : prévisualisations. |cffffd100/hunt test chemin <mp3>|r, |cffffd100/hunt test son <id>|r : essais audio."] = "  |cffc9a24a•|r |cffffd100/hunt test zone|banniere|chrono|en chasse|prime|wow|tampon alliance|horde|icones|griffe|patte|mission|rumeur|succes|promotion|intrus|menagerie|r: previews. |cffffd100/hunt test chemin <mp3>|r, |cffffd100/hunt test son <id>|r: audio tests.",
        ["  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r : textures bandeau/zone/chrono."] = "  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r: banner/zone/timer textures.",
        ["  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r : textures bandeau/zone/chrono. |cffffd100/hunt toast custom/wow|r : toast parchemin / plaque sombre."] = "  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r: banner/zone/timer textures. |cffffd100/hunt toast custom/wow|r: parchment toast / dark plate.",
        ["  |cffc9a24a•|r |cffffd100/hunt tuto|r : revoir le panneau de bienvenue. |cffffd100/hunt lisere <1-5|0>|r : couleur du liseré de rang."] = "  |cffc9a24a•|r |cffffd100/hunt tuto|r: show the welcome panel again. |cffffd100/hunt lisere <1-5|0>|r: rank trim color.",
        ["  |cffc9a24a•|r |cffffd100/hunt|r : ouvrir le carnet. |cffffd100/hunt gibier|contrats|succes|profil|cuisine|options|r : page directe."] = "  |cffc9a24a•|r |cffffd100/hunt|r: open the journal. |cffffd100/hunt gibier|contrats|succes|profil|cuisine|options|r: jump to a tab.",
        [" !|r (+20 points)"] = "!|r (+20 points)",
        [" (chassé : "] = " (hunted: ",
        [" Dernière prise : |cffa0ff50"] = " Latest kill: |cffa0ff50",
        [" ajouté au carnet."] = " added to the journal.",
        [" catalogué"] = " cataloged",
        [" chasses au compteur."] = " hunts on the counter.",
        [" chasses réussies."] = " successful hunts.",
        [" chasses, "] = " hunts, ",
        [" contrat(s) rempli(s)|r\n|cffa58b54Prochaine cible du jour : à minuit.|r"] = " contract(s) fulfilled|r\n|cffa58b54Next target of the day: at midnight.|r",
        [" en réserve)."] = " in reserve).",
        [" est exténué — il bave sur ses pattes…"] = " is exhausted — drooling on its paws…",
        [" est transféré dans l'enclos (onglet Ménagerie)."] = " is transferred to the pen (Menagerie tab).",
        [" points avant « "] = " points before \" ",
        [" points de chasse"] = " hunt points",
        [" points de chasse !"] = " hunt points!",
        [" points — "] = " points — ",
        [" points)"] = " points)",
        [" points|r |cffc9a24a("] = " points|r |cffc9a24a(",
        [" points|r\n|cffa58b54Prochaine cible du jour : à minuit.|r"] = " points|r\n|cffa58b54Next target of the day: at midnight.|r",
        [" points — nouvelles offres à minuit.|r"] = " points — new offers at midnight.|r",
        [" contrat(s) rempli(s) — nouvelles offres à minuit.|r"] = " contract(s) fulfilled — new offers at midnight.|r",
        [" prises au compteur."] = " kills on the counter.",
        [" prises, et toujours des restes à gratter."] = " kills, and always scraps to pick at.",
        [" rejoint l'enclos (Ménagerie)."] = " joins the pen (Menagerie).",
        [" retiré du carnet."] = " removed from the journal.",
        [" |cffff7a1a— gâté au miel !|r"] = " |cffff7a1a— honeyed and pampered!|r",
        [" »."] = "\".",
        [" — prise="] = " — kill=",
        [", contrat="] = ", contract=",
        [", points="] = ", points=",
        ["Gripesous usé de la famille Roundact"] = "Roundact Family's Worn Coinpurse",
        ["Lanterne sourde de la comté"] = "The County's Muffled Lantern",
        ["Maître bestiaire"] = "Bestiary Master",
        ["Nous ne pardonnons pas la chasse. Mais ce titan piétine les couvées de tout le cratère. Faites-le tomber, chasseur — et ne nous dites rien."] = "We do not forgive the hunt. But this titan tramples the nests of the whole crater. Bring it down, hunter — and tell us nothing.",
        ["Sa toile boit plus que la rosée. Les paluns évitent ses arbres depuis toujours."] = "Its web drinks more than the dew. The fen folk have always avoided its trees.",
        ["TRAQUE ENGAGÉE"] = "STALK ENGAGED",
        ["Textures du carnet"] = "Journal Textures",
        ["\n|cffa58b54Primes gagnées au total : |cffffd100"] = "\n|cffa58b54Total bounties earned: |cffffd100",
        ["ciel dégagé"] = "clear sky",
        ["grand encart pendant la chasse"] = "large overlay during the hunt",
        ["|cff8a6d3bAffiché : "] = " |cff8a6d3bShown: ",
        ["|cff8a6d3bAucun contrat en cours — ouvrez une fiche du Gibier, ou prenez la cible du jour.|r"] = "|cff8a6d3bNo active contract — open a Prey card, or take the target of the day.|r",
        ["|cff8a6d3bAucun contrat en cours.\nOuvrez une fiche du Gibier pour en prendre un.|r"] = "|cff8a6d3bNo active contract.\nOpen a Prey card to take one.|r",
        ["|cff8a6d3bAucun monstre catalogué dans cette zone.|r"] = "|cff8a6d3bNo monsters cataloged in this zone.|r",
        ["|cff8a6d3bAucun — cuisinez pour bonifier la prochaine chasse.|r"] = "|cff8a6d3bNone — cook to buff your next hunt.|r",
        ["|cff8a6d3bAucune chasse en cours.\nCiblez un monstre du carnet pour commencer.|r"] = "|cff8a6d3bNo hunt in progress.\nTarget a journal monster to begin.|r",
        ["|cff8a6d3bAucune cible aujourd'hui — connectez-vous pour la découvrir.|r"] = "|cff8a6d3bNo target today — log in to discover it.|r",
        ["|cff8a6d3bAucune prime à ce jour.|r\n|cffa58b54Primes gagnées au total : |cffffd100"] = "|cff8a6d3bNo bounties yet.|r\n|cffa58b54Total bounties earned: |cffffd100",
        ["|cff8a6d3bAucune prise à ce jour.|r"] = "|cff8a6d3bNo kills yet.|r",
        ["|cff8a6d3bDernière prise : aucune|r"] = "|cff8a6d3bLatest kill: none|r",
        ["|cff8a6d3bJournal de chasse — Guilde des chasseurs|r"] = "|cff8a6d3bHunting Journal — Hunters' Guild|r",
        ["|cff8a6d3bLes commandes /hunt restent valables — le carnet n'est qu'un raccourci confortable.|r"] = "|cff8a6d3b/hunt commands still work — the journal is just a handy shortcut.|r",
        ["|cff8a6d3bSélectionne un spécimen capturé pour le nourrir.|r"] = "|cff8a6d3bSelect a captured specimen to feed it.|r",
        ["|cffa0ff50TERMINÉE "] = " |cffa0ff50COMPLETED ",
        ["|cffa58b54L'enclos est vide — le régisseur dort.|r"] = "|cffa58b54The pen is empty — the keeper sleeps.|r",
        ["|cff4a3210Les enclos sont vides — le régisseur dort.|r"] = "|cff4a3210The pens are empty — the keeper sleeps.|r",
        ["|cffffd100Les enclos sont vides — le régisseur dort.|r"] = "|cffffd100The pens are empty — the keeper sleeps.|r",
        ["|cffa58b54Le carnet du chasseur : quatre repères de vieux chasseur|r"] = "|cffa58b54The hunter's journal: four marks of an old hunter|r",
        ["|cffa58b54RÉGION DE CHASSE|r"] = "|cffa58b54HUNTING REGION|r",
        ["|cffc9a24aIngrédients :|r "] = " |cffc9a24aIngredients:|r ",
        ["|cffc9a24aLa guilde des chasseurs salue|r"] = "|cffc9a24aThe hunters' guild salutes|r",
        ["|cffc9a24aRepas préparé :|r"] = "|cffc9a24aMeal prepared:|r",
        ["Le repas préparé"] = "The prepared meal",
        [" a refroidi — le repas préparé est perdu à la mort du chasseur.|r"] = " has gone cold — the prepared meal is lost on the hunter's death.|r",
        -- Rumeurs de guilde (missions cachées)
        ["La chasse à la cuillère"] = "The Spoon Hunt",
        ["Un nain, paraît-il, a dépiauté un worg à la cuillère. Toi, tu as une dague : fais honneur à la légende."] = "A dwarf, so they say, skinned a worg with a spoon. You have a dagger: do the legend justice.",
        ["Abats n'importe quel gibier du carnet avec une dague."] = "Slay any journal monster with a dagger.",
        ["Le récit du nain, illustré"] = "The dwarf's tale, illustrated",
        ["Le concert de minuit"] = "The Midnight Concert",
        ["Les grillons jouent, la guilde ronfle. Toi, tu chasses quand les tavernes ferment — la nuit t'appartient."] = "The crickets play, the guild snores. You hunt when the taverns close — the night is yours.",
        ["Réussis une prise entre minuit et 4h du matin (heure du jeu)."] = "Complete a kill between midnight and 4am (game time).",
        ["Bougie de veille du guetteur"] = "The watcher's vigil candle",
        ["Le conte de la neige"] = "The Snow Tale",
        ["Il neigeait. Il ne neige plus. Il neigera encore : prends ton gibier avant que la page ne tourne."] = "It was snowing. It is no more. It will snow again: take your game before the page turns.",
        ["Réussis une prise sous la neige."] = "Complete a kill in the snow.",
        ["Flocons pressés dans le carnet"] = "Snowflakes pressed in the journal",
        ["Le sort en baguette"] = "The Wand Wager",
        ["Un magicien a parié qu'aucun gibier du carnet ne tomberait sous une baguette. La guilde n'aime pas perdre les paris."] = "A mage bet no journal monster would ever fall to a wand. The guild hates losing bets.",
        ["Abats un gibier du carnet avec une baguette."] = "Slay a journal monster with a wand.",
        ["Le pari du magicien, au montant entier"] = "The mage's wager, paid in full",
        ["La poudre mouillée"] = "Wet Powder",
        ["Pluie sur les mèches, gibier dans les fourrés. Un vrai chasseur attend l'éclair pour tirer."] = "Rain on the powder, game in the thickets. A true hunter waits for the lightning to fire.",
        ["Abats un gibier du carnet avec une arme à feu, sous la pluie."] = "Slay a journal monster with a gun, in the rain.",
        ["Poudre tenue au sec, un miracle"] = "Powder kept dry, a miracle",
        ["Aveugle et sec"] = "Blind and Dry",
        ["La pluie colle les cils, la bête griffe l'air. Reviens sans une goutte de ton sang sur l'équipement."] = "Rain on your lashes, the beast claws the air. Come back without a drop of your blood on your gear.",
        ["Réussis une prise sous la pluie sans perdre un seul point de vie."] = "Complete a kill in the rain without losing a single point of health.",
        ["Ciré de l'ancien de la guilde"] = "The guild elder's oilskin",
        ["Le pari du fou"] = "The Madman's Bet",
        ["Plus haut niveau que toi, heures les plus noires, aucun témoin. La guilde prend les paris — ne perds pas."] = "Higher level than you, blackest hours, no witnesses. The guild takes bets — don't lose.",
        ["Prends un gibier de niveau supérieur au tien, entre minuit et 5h du matin."] = "Kill game above your level, between midnight and 5am.",
        ["Les dés du comptoir, pipés"] = "The counter's dice, loaded",
        ["Poings contre crocs"] = "Fists against Fangs",
        ["On a vu des poings d'arène finir des traques entières. La guilde veut voir ça de ses propres yeux."] = "Arena fists have finished whole stalks before. The guild wants to see it with its own eyes.",
        ["Abats un gibier du carnet à mains nues (armes de pugilat)."] = "Slay a journal monster bare-handed (fist weapons).",
        ["Bandages de la main droite"] = "Right-hand bandages",
        ["Le duel du sommet"] = "The Summit Duel",
        ["Le dernier murmure de la guilde ne se mérite qu'au sommet du rang : plus grand que toi, et pas une égratignure."] = "The guild's last whisper is earned only at the top rank: bigger than you, and not a scratch.",
        ["Prends un gibier de niveau supérieur au tien sans perdre un seul point de vie."] = "Kill game above your level without losing a single point of health.",
        ["Le dernier murmure de la guilde"] = "The guild's last whisper",
        ["Rumeur élucidée"] = "Rumor solved",
        ["|cffa0ff50ELUCIDÉE "] = "|cffa0ff50SOLVED ",
        ["|cffffd100[MH Hunt]|r |cffb97affUne rumeur étrange court dans la guilde…|r Onglet Missions, chasseur — on ne répète pas ce genre de choses."] = "|cffffd100[MH Hunt]|r |cffb97affA strange rumor runs through the guild…|r Missions tab, hunter — this sort of thing isn't repeated.",
        ["|cffffd100[MH Hunt]|r |cffb97affRumeur acceptée :|r "] = "|cffffd100[MH Hunt]|r |cffb97affRumor accepted:|r ",
        ["|cffffd100[MH Hunt]|r |cffb97affRumeur élucidée :|r "] = "|cffffd100[MH Hunt]|r |cffb97affRumor solved:|r ",
        [" — "] = " — ",
        ["Accepter la rumeur"] = "Accept the rumor",
        ["|cffb97affToutes les rumeurs ont été élucidées — la guilde applaudit, chasseur.|r"] = "|cffb97affAll rumors have been solved — the guild applauds, hunter.|r",
        ["|cffb97affDes chasses étranges courent les tavernes… mais la guilde ne murmure qu'aux rangs élevés.|r Rang requis : |cffffff00"] = "|cffb97affStrange hunts run through the taverns… but the guild only whispers to the higher ranks.|r Required rank: |cffffff00",
        ["|cffb97affAucune rumeur aujourd'hui — la guilde murmure à sa manière, revenez demain.|r"] = "|cffb97affNo rumor today — the guild whispers in its own way, come back tomorrow.|r",
        ["|cffc9a24aBourse à objets :|r"] = "|cffc9a24aItem pouch:|r",
        ["|cffc9a24aSensibilités :|r"] = "|cffc9a24aWeaknesses:|r",
        ["|cffc9a24aSensibilités :|r inconnues"] = "|cffc9a24aWeaknesses:|r unknown",
        ["|cffd87a6aAbandonner le contrat|r"] = "|cffd87a6aAbandon contract|r",
        ["|cffff7a1aEN CHASSE !|r"] = "|cffff7a1aON THE HUNT!|r",
        ["|cffffd100Astuce du vieux chasseur :|r "] = " |cffffd100Old hunter's tip:|r ",
        ["|cffffd100BONNE CHASSE !|r"] = "|cffffd100HAPPY HUNTING!|r",
        ["|cffffd100BONNE CHASSE, "] = " |cffffd100HAPPY HUNTING, ",
        ["|cffffd100Carnet de chasse|r"] = "|cffffd100Hunting Journal|r",
        ["|cffffd100Chasse|r : visez la bête en jeu pour engager EN CHASSE, un duel chronométré. Chaque prise rapporte des points pour faire progresser votre rang de chasseur."] = "|cffffd100Hunt|r: aim at the beast in game to go ON THE HUNT, a timed duel. Each kill earns points to raise your hunter rank.",
        ["|cffffd100Contrats|r : la cible du jour vaut une prime de +20 points. Prendre une mission engage la traque."] = "|cffffd100Contracts|r: the target of the day is worth a +20 point bounty. Taking a quest starts the stalk.",
        ["|cffffd100Cuisine|r : viande sur les prises, herbes en zone de chasse, miel sur les rares ; un repas bonifie la prise suivante."] = "|cffffd100Cooking|r: meat from kills, herbs in the hunting zone, honey from rares; a meal buffs your next kill.",
        ["|cffffd100Gibier|r : fiches, menace, gabarit, sensibilités. Cliquez une bête pour ouvrir sa fiche et la chasser."] = "|cffffd100Prey|r: cards, threat, size, weaknesses. Click a beast to open its card and hunt it.",
        ["|cffffd100MISSIONS DE CHASSE|r"] = "|cffffd100HUNTING QUESTS|r",
        ["|cffffd100Ma zone|r"] = "|cffffd100My zone|r",
        ["|cffffd100ORNEMENTS DE CHASSE|r"] = "|cffffd100HUNTING ORNAMENTS|r",
        ["|cffffd100PALMARÈS DES CHASSES|r"] = "|cffffd100HUNT RECORDS|r",
        ["|cffffd100Prendre le contrat|r"] = "|cffffd100Take contract|r",
        ["|cffffd100Remplacer le contrat|r"] = "|cffffd100Replace contract|r",
        ["|cffffd100RÉGLAGES DU CHASSEUR|r"] = "|cffffd100HUNTER SETTINGS|r",
        ["|cffffd100Révoquer le contrat|r"] = "|cffffd100Revoke contract|r",
        ["|cffffd100STATISTIQUES DE CHASSE|r"] = "|cffffd100HUNT STATISTICS|r",
        ["|cffffd100TROPHÉES DE CHASSE|r"] = "|cffffd100HUNTING TROPHIES|r",
        ["|cffffd100Titres de chasseur|r"] = "|cffffd100Hunter titles|r",
        ["|cffffd100Zone actuelle : |r"] = "|cffffd100Current zone: |r",
        ["|cffffd100[MH Hunt]|r %d entrées exportées."] = "|cffffd100[MH Hunt]|r %d entries exported.",
        ["|cffffd100[MH Hunt]|r Ambiance sonore du jeu réactivée (un vieux mute de l'addon traînait dans la config du client)."] = "|cffffd100[MH Hunt]|r Game ambience re-enabled (an old addon mute was lingering in the client config).",
        ["|cffffd100[MH Hunt]|r Bannière activée."] = "|cffffd100[MH Hunt]|r Banner enabled.",
        ["|cffffd100[MH Hunt]|r Bannière désactivée."] = "|cffffd100[MH Hunt]|r Banner disabled.",
        ["|cffffd100[MH Hunt]|r Base réinitialisée."] = "|cffffd100[MH Hunt]|r Database reset.",
        ["|cffffd100[MH Hunt]|r Bête inconnue du carnet : « "] = " |cffffd100[MH Hunt]|r Beast unknown to the journal: \" ",
        ["|cffffd100[MH Hunt]|r Carte de chasseur envoyée à |cffffff00"] = "|cffffd100[MH Hunt]|r Hunter card sent to |cffffff00",
        ["|cffffd100[MH Hunt]|r Carte de chasseur — "] = "|cffffd100[MH Hunt]|r Hunter card — ",
        ["|cffffd100[MH Hunt]|r Ce gibier n'a jamais été abattu — chasse-le d'abord."] = "|cffffd100[MH Hunt]|r This game has never been slain — hunt it first.",
        ["|cffffd100[MH Hunt]|r Ce spécimen n'est pas en enclos."] = "|cffffd100[MH Hunt]|r This specimen is not in the pen.",
        ["|cffffd100[MH Hunt]|r Cible du jour déjà en contrat actif."] = "|cffffd100[MH Hunt]|r Target of the day already active as contract.",
        ["|cffffd100[MH Hunt]|r Cible du jour suggérée : |cffffff00"] = "|cffffd100[MH Hunt]|r Suggested target of the day: |cffffff00",
        ["|cffffd100[MH Hunt]|r Ciblez d'abord une créature."] = "|cffffd100[MH Hunt]|r Target a creature first.",
        ["|cffffd100[MH Hunt]|r Contrat abandonné."] = "|cffffd100[MH Hunt]|r Contract abandoned.",
        ["|cffffd100[MH Hunt]|r Contrat du jour : |cffffff00"] = "|cffffd100[MH Hunt]|r Contract of the day: |cffffff00",
        ["|cffffd100[MH Hunt]|r Contrat pris : |cffffff00"] = "|cffffd100[MH Hunt]|r Contract taken: |cffffff00",
        ["|cffffd100[MH Hunt]|r Contrat révoqué : |cffffff00"] = "|cffffd100[MH Hunt]|r Contract revoked: |cffffff00",
        ["|cffffd100[MH Hunt]|r Debug : chasseActive="] = "|cffffd100[MH Hunt]|r Debug: huntActive=",
        ["|cffffd100[MH Hunt]|r En chasse : |cffffff00"] = "|cffffd100[MH Hunt]|r Hunting: |cffffff00",
        ["|cffffd100[MH Hunt]|r Fond WoW — nécessite /reload."] = "|cffffd100[MH Hunt]|r WoW background — requires /reload.",
        ["|cffffd100[MH Hunt]|r Icône WoW — nécessite /reload."] = "|cffffd100[MH Hunt]|r WoW icon — requires /reload.",
        ["|cffffd100[MH Hunt]|r Icône custom — nécessite /reload."] = "|cffffd100[MH Hunt]|r Custom icon — requires /reload.",
        ["|cffffd100[MH Hunt]|r Identifié par l'ID "] = " |cffffd100[MH Hunt]|r Identified by ID ",
        ["|cffffd100[MH Hunt]|r Il faut 5 viandes pour apprivoiser ce spécimen."] = "|cffffd100[MH Hunt]|r You need 5 meats to tame this specimen.",
        ["|cffffd100[MH Hunt]|r Il manque des ingrédients pour le "] = " |cffffd100[MH Hunt]|r Missing ingredients for the ",
        ["|cffffd100[MH Hunt]|r Kill strict (le coup de grâce doit être le vôtre)."] = "|cffffd100[MH Hunt]|r Strict kill (the killing blow must be yours).",
        ["|cffffd100[MH Hunt]|r Le monstre est pris au piège !"] = "|cffffd100[MH Hunt]|r The monster is caught in the trap!",
        ["|cffffd100[MH Hunt]|r Liseré : |cffffff00"] = "|cffffd100[MH Hunt]|r Trim: |cffffff00",
        ["|cffffd100[MH Hunt]|r Musique du jeu réactivée (un vieux mute de l'addon traînait dans la config du client)."] = "|cffffd100[MH Hunt]|r Game music re-enabled (an old addon mute was lingering in the client config).",
        ["|cffffd100[MH Hunt]|r Nouveau contrat : |cffffff00"] = "|cffffd100[MH Hunt]|r New contract: |cffffff00",
        ["|cffffd100[MH Hunt]|r Nouveau monstre découvert : |cffffff00"] = "|cffffd100[MH Hunt]|r New monster discovered: |cffffff00",
        ["|cffffd100[MH Hunt]|r Nouveau rang de chasseur : |cffffff00"] = "|cffffd100[MH Hunt]|r New hunter rank: |cffffff00",
        ["|cffffd100[MH Hunt]|r Objectif du contrat en vue : |cffffff00"] = "|cffffd100[MH Hunt]|r Contract objective in sight: |cffffff00",
        ["|cffffd100[MH Hunt]|r Parchemin custom — nécessite /reload."] = "|cffffd100[MH Hunt]|r Custom parchment — requires /reload.",
        ["|cffffd100[MH Hunt]|r Pas de miel — il se déniche sur les rares (10%)."] = "|cffffd100[MH Hunt]|r No honey — it's found on rares (10%).",
        ["|cffffd100[MH Hunt]|r Pas de viande — chasse pour en récolter (40% par prise)."] = "|cffffd100[MH Hunt]|r No meat — hunt to gather some (40% per kill).",
        ["|cffffd100[MH Hunt]|r Récolte : |cffff7a1a1 miel sauvage|r !"] = "|cffffd100[MH Hunt]|r Gathered: |cffff7a1a1 wild honey|r!",
        ["|cffffd100[MH Hunt]|r Récolte : |cffff7a1a1 viande de gibier|r."] = "|cffffd100[MH Hunt]|r Gathered: |cffff7a1a1 game meat|r.",
        ["|cffffd100[MH Hunt]|r Sons activés."] = "|cffffd100[MH Hunt]|r Sounds enabled.",
        ["|cffffd100[MH Hunt]|r Sons désactivés."] = "|cffffd100[MH Hunt]|r Sounds disabled.",
        ["|cffffd100[MH Hunt]|r Succès débloqué : |cffffff00"] = "|cffffd100[MH Hunt]|r Achievement unlocked: |cffffff00",
        ["|cffffd100[MH Hunt]|r Test : +20 viandes, +10 miels, 8 spécimens en enclos (dont un affamé et un gâté)."] = "|cffffd100[MH Hunt]|r Test: +20 meats, +10 honeys, 8 specimens in the pen (one hungry, one pampered).",
        ["|cffffd100[MH Hunt]|r Test : annonce de zone affichée."] = "|cffffd100[MH Hunt]|r Test: zone announcement shown.",
        ["|cffffd100LE SERMENT DU CHASSEUR|r"] = "|cffffd100THE HUNTER'S OATH|r",
        ["|cffa58b54Chaque prise validée demande un choix : comment comptent vos trophées ?|r"] = "|cffa58b54Every validated kill demands a choice: how do your trophies count?|r",
        ["|cffff8844La voie du compagnon|r — chasse souple"] = "|cffff8844The packmate's way|r — relaxed hunts",
        ["« Le gibier est tombé sous les crocs de la meute — et la meute, c'était vous. »"] = "« The beast fell to the pack's fangs — and you were the pack. »",
        ["|cffc9a24aImplique :|r participer au combat suffit (dégâts ou soins apportés), même sans porter le coup fatal. Idéal en groupe."] = "|cffc9a24aMeans:|r taking part in the fight is enough (damage or healing dealt), even without landing the killing blow. Ideal in groups.",
        ["|cff66ccffLa voie du loup solitaire|r — chasse stricte"] = "|cff66ccffThe lone wolf's way|r — strict hunts",
        ["« La traque se termine par VOTRE lame, ou elle ne compte pas. »"] = "« The hunt ends by YOUR blade, or it does not count. »",
        ["|cffc9a24aImplique :|r seul votre coup de grâce valide la prise. En groupe, la bête doit mourir sous votre main. Pour chasseurs exigeants."] = "|cffc9a24aMeans:|r only your killing blow validates the kill. In groups, the beast must die by your hand. For demanding hunters.",
        ["|cff88ff88• Votre voie actuelle|r"] = "|cff88ff88• Your current way|r",
        ["|cffa58b54La voie se change à tout moment : |cffffd100/hunt kill loose/strict|r"] = "|cffa58b54Your way can be changed anytime: |cffffd100/hunt kill loose/strict|r",
        ["Plus tard"] = "Later",
        ["Prononcer le serment !"] = "Swear the oath!",
        ["|cffffd100[MH Hunt]|r Choisissez d'abord une voie pour prononcer le serment."] = "|cffffd100[MH Hunt]|r Pick a way first to swear the oath.",
        ["|cffffd100[MH Hunt]|r Serment prononcé : |cffff8844la voie du compagnon|r (chasse souple — la participation compte)."] = "|cffffd100[MH Hunt]|r Oath sworn: |cffff8844the packmate's way|r (relaxed hunts — participation counts).",
        ["|cffffd100[MH Hunt]|r Serment prononcé : |cff66ccffla voie du loup solitaire|r (chasse stricte — votre coup de grâce, et rien d'autre)."] = "|cffffd100[MH Hunt]|r Oath sworn: |cff66ccffthe lone wolf's way|r (strict hunts — your killing blow, nothing else).",
        ["|cffff8844voie du compagnon|r"] = "|cffff8844packmate's way|r",
        ["|cff66ccffvoie du loup solitaire|r"] = "|cff66ccfflone wolf's way|r",
        [" — "] = " — ",
        ["Voie du chasseur"] = "Hunter's way",
        ["Comment comptent vos prises : participation (souple) ou coup de grâce (strict)."] = "How your kills count: participation (relaxed) or killing blow (strict).",
        ["Clic : revoir le serment et changer de voie."] = "Click: replay the oath and change your way.",
        ["|cffffd100[MH Hunt]|r Test : toast couronne d'or (griffe)."] = "|cffffd100[MH Hunt]|r Test: gold crown toast (claw icon).",
        ["|cffffd100[MH Hunt]|r Test : toast spécimen capturé (patte)."] = "|cffffd100[MH Hunt]|r Test: specimen captured toast (paw icon).",
        ["|cffffd100[MH Hunt]|r Test : toast mission (icône carrée de repli)."] = "|cffffd100[MH Hunt]|r Test: mission toast (square fallback icon).",
        ["|cffffd100[MH Hunt]|r Test : toast rumeur élucidée (icône carrée de repli)."] = "|cffffd100[MH Hunt]|r Test: rumor solved toast (square fallback icon).",
        ["|cffffd100[MH Hunt]|r Test : toast succès (icône carrée de repli)."] = "|cffffd100[MH Hunt]|r Test: achievement toast (square fallback icon).",
        ["|cffffd100[MH Hunt]|r Test : toast promotion (comme un succès — parchemin)."] = "|cffffd100[MH Hunt]|r Test: guild promotion toast (achievement style — parchment).",
        ["|cffffd100[MH Hunt]|r Test : toast intrus dans l'enclos (message simple, sans médaillon)."] = "|cffffd100[MH Hunt]|r Test: pen intruder toast (simple message, no medallion).",
        ["|cffffd100[MH Hunt]|r Test : bandeau En chasse éphémère (4 s), puis mini chrono en coin."] = "|cffffd100[MH Hunt]|r Test: ephemeral hunt banner (4 s), then mini timer in the corner.",
        ["|cffffd100[MH Hunt]|r Test : bannière centrale affichée."] = "|cffffd100[MH Hunt]|r Test: center banner shown.",
        ["|cffffd100[MH Hunt]|r Test : chrono lancé (10 s), fondu à l'entrée et à la sortie."] = "|cffffd100[MH Hunt]|r Test: timer running (10 s), fade in and out.",
        ["|cffffd100[MH Hunt]|r Test : cible du jour relancée (toast + plaque Accueil)."] = "|cffffd100[MH Hunt]|r Test: target of the day refreshed (toast + Home plate).",
        ["|cffffd100[MH Hunt]|r Test : toast validation affiché (toast1.tga)."] = "|cffffd100[MH Hunt]|r Test: validation toast shown (toast1.tga).",
        ["|cffffd100[MH Hunt]|r Test : toast sombre affiché (mode « wow », sans changer la config)."] = "|cffffd100[MH Hunt]|r Test: dark toast shown ('wow' style, config untouched).",
        ["|cffffd100[MH Hunt]|r Test : toast avec tampon "] = "|cffffd100[MH Hunt]|r Test: toast with ",
        ["|cffffd100[MH Hunt]|r Test : enclos vidé (l'apprivoisement reste testable, les fiches sont conservées)."] = "|cffffd100[MH Hunt]|r Test: pen emptied (taming still testable, cards kept).",
        ["|cffffd100[MH Hunt]|r Titre affiché : « "] = " |cffffd100[MH Hunt]|r Displayed title: \" ",
        ["|cffffd100[MH Hunt]|r Tous les compteurs de prises remis à zéro (fiches, trophées et points conservés)."] = "|cffffd100[MH Hunt]|r All kill counters reset to zero (cards, trophies and points kept).",
        ["|cffffd100[MH Hunt]|r Traçage des détections de mort : |cffffff00"] = "|cffffd100[MH Hunt]|r Death detection tracing: |cffffff00",
        ["|cffffd100[MH Hunt]|r Trophée prélevé : "] = " |cffffd100[MH Hunt]|r Trophy taken: ",
        ["|cffffd100[MH Hunt]|r |cff888888Découpe manquée : le morceau s'est abîmé.|r"] = " |cffffd100[MH Hunt]|r |cff888888Carve missed: the piece was ruined.|r",
        ["|cffffd100[MH Hunt]|r Usage : /hunt lisere <1-5> (0 = rang réel)."] = "|cffffd100[MH Hunt]|r Usage: /hunt lisere <1-5> (0 = real rank).",
        [" chargé. /hunt pour ouvrir le carnet. "] = " loaded. /hunt to open the journal. ",
        ["|cffffd100[MH Hunt]|r |cff8a6d3bMauvais temps pour la piste : garde l'œil sur ton gibier, pas sur le ciel.|r"] = "|cffffd100[MH Hunt]|r |cff8a6d3bBad weather for tracking: keep your eye on your game, not the sky.|r",
        ["|cffffd100[MH Hunt]|r |cff8a9bb0La météo tourne :|r "] = " |cffffd100[MH Hunt]|r |cff8a9bb0The weather turns:|r ",
        ["|cffffd100[MH Hunt]|r |cffa0ff50Chasse réussie : "] = " |cffffd100[MH Hunt]|r |cffa0ff50Hunt successful: ",
        ["|cffffd100[MH Hunt]|r |cffa58b54La bête est dans les parages…|r Gardez vos sens éveillés, chasseur."] = "|cffffd100[MH Hunt]|r |cffa58b54The beast is nearby…|r Keep your senses sharp, hunter.",
        ["|cffffd100[MH Hunt]|r |cffa58b54Le monstre vous a échappé…|r La chasse de "] = " |cffffd100[MH Hunt]|r |cffa58b54The monster escaped you…|r The hunt of ",
        ["|cffffd100[MH Hunt]|r |cffff5050Chasse échouée : "] = " |cffffd100[MH Hunt]|r |cffff5050Hunt failed: ",
        ["|cffffd100[MH Hunt]|r |cffff7a1aSpécimen captéré !|r "] = " |cffffd100[MH Hunt]|r |cffff7a1aSpecimen captured!|r ",
        ["|cffffd100[MH Hunt]|r |cffffc44cAide du chasseur :|r"] = "|cffffd100[MH Hunt]|r |cffffc44cHunter's help:|r",
        ["|cffffd100[MH Hunt]|r |cffffc44cExport de réconciliation — copie-colle ces lignes :|r"] = "|cffffd100[MH Hunt]|r |cffffc44cReconciliation export — copy-paste these lines:|r",
        ["|cffffd100[MH Hunt]|r |cffffc44cMission acceptée :|r "] = " |cffffd100[MH Hunt]|r |cffffc44cQuest accepted:|r ",
        ["|cffffd100[MH Hunt]|r |cffffc44cTraque engagée :|r pistez "] = " |cffffd100[MH Hunt]|r |cffffc44cStalk engaged:|r track ",
        ["|cffffd100[MH Hunt]|r |cffffc44cTraque engagée :|r pistez la bête et ciblez-la pour lancer la chasse."] = "|cffffd100[MH Hunt]|r |cffffc44cStalk engaged:|r track the beast and target it to start the hunt.",
        ["|cffffd100» Ton gibier t'attend ici|r"] = "|cffffd100\"Your game awaits you here|r",
        ["|r ajusté ("] = "|r adjusted (",
        ["|r est apprivoisé et rejoint l'enclos !"] = "|r is tamed and joins the pen!",
        ["|r joué — aucun son = identifiant inconnu sur ce client."] = "|r played — no sound = unknown ID on this client.",
        ["|r marqué sur la carte ("] = "|r marked on the map (",
        ["|r prise(s)."] = "|r kill(s).",
        ["|r préparé : "] = " |r prepared: ",
        ["|r repart dans la nature... bonne chance à lui, petit guy."] = "|r is released into the wild... good luck to him, little guy.",
        ["|r savouré : +"] = "|r savored: +",
        ["|r se régale d'une viande de gibier."] = "|r feasts on a game meat.",
        ["|r — s'appliquera à la prochaine prise."] = "|r — will apply to the next kill.",
        ["|r. Bonne chasse !"] = "|r. Happy hunting!",
        ["Émissaire de D.E.H.T.A."] = "D.E.H.T.A. Emissary",
        ["Étoile du découvreur"] = "Discoverer's Star",
        ["Vétéran"] = "Veteran",
        ["Sacré"] = "Holy",
        ["Félin"] = "Feline",
        ["Araignée"] = "Spider",
        ["Hyène"] = "Hyena",
        ["Serpent des vents"] = "Wind Serpent",
        ["Loup"] = "Wolf",
        ["Harpie"] = "Harpy",
        ["Scorpide"] = "Scorpid",
        ["Échassier"] = "Tallstrider",
        ["Zèvre"] = "Zhevra",
        ["Silithide"] = "Silithid",
        ["Charognard"] = "Carrion Bird",
        ["Tortue"] = "Turtle",
        ["Élémentaire"] = "Elemental",
        ["Chauve-souris"] = "Bat",
        ["Hibou"] = "Owl",
        ["Yéti"] = "Yeti",
        ["Griffon"] = "Gryphon",
        ["Kodo"] = "Kodo",
        ["Gorille"] = "Gorilla",
        ["Ours"] = "Bear",
        ["Rare"] = "Rare",
        ["tempête de sable"] = "sandstorm",
        ["pluie de feu"] = "firestorm",
        ["ciel couvert"] = "overcast sky",
        ["Rôdeur"] = "Ranger",
        ["Maître-archer"] = "Master Archer",
        ["SUCCÈS"] = "ACHIEVEMENTS",
        ["Révoquer"] = "Revoke",
        ["|cff888888VERROUILLÉE|r"] = "|cff888888LOCKED|r",
        ["|cffa0ff50Activé|r"] = "|cffa0ff50Enabled|r",
        ["|cffd87a6aDésactivé|r"] = "|cffd87a6aDisabled|r",
        ["|cffffd100MÉNAGERIE|r"] = "|cffffd100MENAGERIE|r",
        ["|cffd87a6aAffamé|r"] = "|cffd87a6aHungry|r",
        ["ACTIVÉ"] = "ENABLED",
        ["désactivé"] = "disabled",
        ["|cffffd100[MH Hunt]|r zone.tga ne charge pas — dimensions en puissance de 2 requises (ex. 256x64), TGA non compressé."] = "|cffffd100[MH Hunt]|r zone.tga won't load — power-of-2 dimensions required (e.g. 256x64), uncompressed TGA.",
        ["|cffffd100[MH Hunt]|r chrono.tga ne charge pas — dimensions en puissance de 2 requises (ex. 512x64), TGA non compressé."] = "|cffffd100[MH Hunt]|r chrono.tga won't load — power-of-2 dimensions required (e.g. 512x64), uncompressed TGA.",
        [" (MHAmbiance/Sounds : promotion.mp3, combat.mp3, traque.mp3 — fichiers ajoutés après lancement du jeu = redémarrage client requis.)"] = " (MHAmbiance/Sounds: promotion.mp3, combat.mp3, traque.mp3 — files added after the game launched = client restart required.)",
    },
}
local function L(cle)
    local cfg = (DB and DB.config) or (LaChasseDB and LaChasseDB.config)
    local lg = cfg and cfg.langue or "fr"
    return (MH_TEXTES[lg] and MH_TEXTES[lg][cle]) or MH_TEXTES.fr[cle] or cle
end
local function InitDB()
    if not LaChasseDB then LaChasseDB = {} end
    if LaChasseDB.config == nil then LaChasseDB.config = {} end
    for k, v in pairs(defaults.config) do
        if LaChasseDB.config[k] == nil then LaChasseDB.config[k] = v end
    end
    for k, v in pairs(defaults) do
        if k ~= "config" and LaChasseDB[k] == nil then
            if type(v) == "table" then LaChasseDB[k] = {} else LaChasseDB[k] = v end
        end
    end
    DB = LaChasseDB
    MHH_DB = DB -- pont Menagerie.lua (v0.67)
    -- v0.119 : RENCONTRES — le succès « découverte » compte désormais la
    -- PREMIÈRE RENCONTRE d'un rare (avec un data complet, plus aucun rare
    -- « inconnu » ne peut être découvert : le succès était mort). Les rares
    -- déjà chassés/découverts comptent comme rencontrés (première prise).
    if DB.rencontres == nil then DB.rencontres = {} end
    if DB.chasses then
        for nomR in pairs(DB.chasses) do
            if DB.rencontres[nomR] == nil then DB.rencontres[nomR] = 1 end
        end
    end
    if DB.decouverts then
        for nomR in pairs(DB.decouverts) do
            if DB.rencontres[nomR] == nil then DB.rencontres[nomR] = 1 end
        end
    end
    -- Migration : les prises antérieures étaient comptées sous la CLASSE
    -- « Arme » (bug d'indice GetItemInfo : la sous-classe est en 8e
    -- position, pas 7e). On les réattribue à la sous-classe de l'arme
    -- actuellement en main droite — l'arme du chasseur change rarement.
    if DB.armes and DB.armes["Arme"] then
        local nArme = DB.armes["Arme"]
        DB.armes["Arme"] = nil
        pcall(function()
            local idArmeMig = GetInventoryItemID and GetInventoryItemID("player", 16)
            if idArmeMig then
                local _, _, _, _, _, _, _, sousClasseMig = GetItemInfo(idArmeMig)
                if sousClasseMig and sousClasseMig ~= "" then
                    DB.armes[sousClasseMig] = (DB.armes[sousClasseMig] or 0) + nArme
                end
            end
        end)
    end
    -- Migration : zones renommées dans le data file (« Brachland » →
    -- « Les Tarides », « Hiverpeint » → « Hiverpré ») — les découvertes
    -- déjà enregistrées suivent, sinon elles s'affichaient sous une
    -- en-tête de zone orphelle qui n'existe plus nulle part.
    local RENOMMAGES_ZONES = { ["Brachland"] = "Les Tarides", ["Hiverpeint"] = "Hiverpré", ["Serres-Rocheuses"] = "Les Serres-Rocheuses" }
    if DB.decouverts then
        for _, d in pairs(DB.decouverts) do
            if d and d.zone and RENOMMAGES_ZONES[d.zone] then d.zone = RENOMMAGES_ZONES[d.zone] end
        end
    end
    if DB.cartes then
        for ancien, nouveau in pairs(RENOMMAGES_ZONES) do
            if DB.cartes[ancien] then DB.cartes[nouveau] = DB.cartes[ancien]; DB.cartes[ancien] = nil end
        end
    end
end

-- Les textures custom sont configurées dans LaChasseDB, qui n'est peuplé
-- qu'à ADDON_LOADED, donc on lit la base brute (et non DB) au chargement
local function TextureCustomActive(cle)
    return LaChasseDB and LaChasseDB.config and LaChasseDB.config[cle] == "custom"
end

-- Son blindé : C_Sound sur Midnight (PlaySound global y est protégé),
-- repli Classic, pcall en filet de sécurité
local function JouerSon(id, fort)
    if not id then return end
    -- Mode « fort » : le rugissement passe sur le canal MASTER (au-dessus
    -- du curseur SFX souvent baissé par le joueur). Repli SFX normal
    -- si le canal n'est pas accepté par ce client.
    if fort then
        if C_Sound and C_Sound.PlaySound then
            if pcall(C_Sound.PlaySound, id, "Master") then return end
        else
            if pcall(PlaySound, id, "Master") then return end
        end
    end
    if C_Sound and C_Sound.PlaySound then
        pcall(C_Sound.PlaySound, id)
    else
        pcall(PlaySound, id)
    end
end

-- Le rugissement de contrat/mission : le SoundKit 7274 est trop feutré.
-- Client moderne (Midnight) : PlaySound(SoundKitID) — on prend l'alarme
-- du Fel Reaver (10571), le « WWWHOOOM » qui fait trembler la péninsule.
-- Repli ancien : PlaySoundFile par chemin de fichier (renvoie nil si le
-- fichier manque) ; dernier repli : le SoundKit 7274.
local function JouerRugissement()
    -- 1. Cri de bête au hasard (SoundKits vérifiés) : ours, loup,
    -- raptor — l'aggro sonore de la créature, façon « la bête se dresse »
    local CRIS_BETE = {
        478,  -- BearAggro : le rugissement d'ours iconique
        390,  -- WolfAggro : le grognement de loup
        708,  -- RaptorAggro : le cri de raptor
    }
    local ok, jouera = pcall(PlaySound, CRIS_BETE[math.random(#CRIS_BETE)], "Master")
    if ok and jouera then return end
    -- 2. Repli : alarme du Fel Reaver (très audible, moins fin)
    local okF, joueraF = pcall(PlaySound, 10571, "Master")
    if okF and joueraF then return end
    -- 3. Chemins de fichiers (clients Classic)
    local CRIS_MONSTRE = {
        "Sound\\Creature\\Nefarian\\NefarianAggro.wav",   -- dragon, vanilla
        "Sound\\Creature\\Herod\\HerodEnrage01.wav",     -- hurlement de guerre, vanilla
    }
    for _, chemin in ipairs(CRIS_MONSTRE) do
        local okC, joueraC = pcall(PlaySoundFile, chemin, "Master")
        if okC and joueraC then return end
    end
    -- 4. Dernier repli
    JouerSon(7274, true)
end

-- Portrait : la méthode tex:SetPortraitTexture() est Classic-only,
-- sur Midnight c'est la fonction globale SetPortraitTexture(tex, unit)
local function DefinirPortrait(tex, unit)
    if not tex then return end
    if tex.SetPortraitTexture then
        pcall(tex.SetPortraitTexture, tex, unit)
    else
        pcall(SetPortraitTexture, tex, unit)
    end
end

-- Template Backdrop : indispensable sur Midnight (SetBackdrop sans ce
-- template = action « réservée à l'IU Blizzard »), inexistant sur Classic
MHH_TEMPLATE_BACKDROP = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Applique les textures custom une fois la base chargée (rempli après
-- la création du carnet et du bouton, appelé sur ADDON_LOADED)
local AppliquerTextures

-- ============================================
-- 2. CATALOGUE DES GRANDS MONSTRES (Vanilla)
--    Catalogue exhaustif des rares extérieurs (~280), par zone et continent.
--    Attention : noms localisés au mieux ; le mode auto découvre les rares
--    du catalogue dont le nom ne correspond pas exactement au client.
-- ============================================
MHH_CATALOGUE = {
    -- [nom exact en jeu] = zone
    -- Kalimdor
    ["Sarkoth"] = "Durotar",
    -- « Bête du Galet d'Argile » retirée : introuvable en jeu (Forever)
    ["Capitaine Croc-Plat"] = "Durotar",
    ["Flagelleur de la mort"] = "Durotar",
    ["Tisse-gangrène Scornn"] = "Durotar",
    ["Géoseigneur Mottle"] = "Durotar",
    ["Seigneur de guerre Kolkanis"] = "Durotar",
    ["Commandant de guet Zalaphil"] = "Durotar",
    ["Broyeur d'os"] = "Mulgore",
    ["Kroc-Pattes"] = "Mulgore",
    ["Arra'chea"] = "Mulgore",
    ["Prophète du mal Course-Sage"] = "Mulgore",
    ["Exécutrice Emilgund"] = "Mulgore",
    ["Hurlement fantôme"] = "Mulgore",
    ["Mazzranache"] = "Mulgore",
    ["« Pique » Mante-Épine"] = "Mulgore",
    ["Sœur Haine-Coups"] = "Mulgore",
    ["Lance-Museau"] = "Mulgore",
    ["Le Rateau"] = "Mulgore",
    ["Grince-Bois"] = "Teldrassil",
    ["Moussemois le Fétide"] = "Teldrassil",
    ["Traqueur du crépuscule"] = "Teldrassil",
    ["Shelda la Furieuse"] = "Teldrassil",
    ["Threggil"] = "Teldrassil",
    ["Uruson"] = "Teldrassil",
    ["Carnivore le Casseur"] = "Sombrerivage",
    ["Invocateur du feu Radison"] = "Sombrerivage",
    ["Flagglemurk le Cruel"] = "Sombrerivage",
    ["Dame Regardelune"] = "Sombrerivage",
    ["Dame Vespira"] = "Sombrerivage",
    ["Licillin"] = "Sombrerivage",
    ["Seigneur Tueur-de-péchés"] = "Sombrerivage",
    ["Ombregriffe"] = "Sombrerivage",
    ["Mère de couvée des échassiers"] = "Sombrerivage",
    ["Humar le Seigneur hautain"] = "Les Tarides",
    ["Flinkmähne"] = "Les Tarides",
    ["Takk le Bondisseur"] = "Les Tarides",
    ["Aean Swiftriver"] = "Les Tarides",
    -- Malcin cendrecœur : absent de ForeverDB (rares ≤ 30) — retiré,
    -- à réactiver s'il est vu en jeu
    ["Azzere la Lame-des-cieux"] = "Les Tarides",
    ["Boahn"] = "Les Tarides",
    ["Brokespear"] = "Les Tarides",
    ["Brontus"] = "Les Tarides",
    ["Capitaine Gerogg Hammertoe"] = "Les Tarides",
    ["Fossoyeur Forgeflamme"] = "Les Tarides",
    -- Dishu & Rathorian : Durotar d'après ForeverDB (pas Les Tarides)
    ["Dishu"] = "Durotar",
    ["Rathorian"] = "Durotar",
    ["Ancien mystique Museau-rasoir"] = "Les Tarides",
    ["Ingénieur Tourniquet"] = "Les Tarides",
    ["Contremaître Grills"] = "Les Tarides",
    -- Gukk'rok & Swinegart : Mulgore d'après ForeverDB (pas Les Tarides)
    ["Gesharahan"] = "Les Tarides",
    ["Hagg Fléau-des-taurens"] = "Les Tarides",
    ["Hannah Feuillelame"] = "Les Tarides",
    ["Heggin Museau-de-pierre"] = "Les Tarides",
    ["Malgin Brasse-d'orge"] = "Les Tarides",
    ["Marcus Bel"] = "Les Tarides",
    ["Lance-de-roche"] = "Les Tarides",
    ["Cueilleur silithide"] = "Les Tarides",
    -- Sister Rathtalon : Les Serres-Rocheuses d'après ForeverDB (pas Les Tarides)
    ["Sœur Griffe-de-rat"] = "Les Serres-Rocheuses",
    ["Bête de boue"] = "Les Tarides",
    ["Snort le Moqueur"] = "Les Tarides",
    ["Bras-de-pierre"] = "Les Tarides",
    ["Vif-Crinière"] = "Les Tarides",
    ["Thora Plume-de-lune"] = "Les Tarides",
    ["Pietinement-tonnerre"] = "Les Tarides",
    ["Frère Chêneravin"] = "Les Serres-Rocheuses",
    ["Contremaître Rigger"] = "Les Serres-Rocheuses",
    ["Nal'taszar"] = "Les Serres-Rocheuses",
    ["Patriarche Aile-fière"] = "Les Serres-Rocheuses",
    ["Sentinelle Amarassan"] = "Les Serres-Rocheuses",
    ["Sœur Riven"] = "Les Serres-Rocheuses",
    ["Aile-de-chagrin"] = "Les Serres-Rocheuses",
    ["Chef de tâche Croc-fouet"] = "Les Serres-Rocheuses",
    ["Ancien vengeur"] = "Les Serres-Rocheuses",
    ["Goret d'Orneval"] = "Orneval",
    ["Akkrilus"] = "Orneval",
    ["Apothicaire Falthis"] = "Orneval",
    ["Casse-branche"] = "Orneval",
    ["Eck'alom"] = "Orneval",
    ["Dame Vespia"] = "Orneval",
    ["Hurle-brume"] = "Orneval",
    ["Mugglefin"] = "Orneval",
    ["Patte-de-chêne"] = "Orneval",
    ["Prince Raze"] = "Orneval",
    ["Rorgish Jowl"] = "Orneval",
    ["Ursol'lok"] = "Orneval",
    ["Crusty"] = "Désolace",
    ["Centaure maudit"] = "Désolace",
    ["Glousseur"] = "Désolace",
    ["Hissperak"] = "Désolace",
    ["Kaskk"] = "Désolace",
    ["Prince Kellen"] = "Désolace",
    ["Goret de Mille Pointes"] = "Mille Pointes",
    ["Achellios le Banni"] = "Mille Pointes",
    ["Gibblesnik"] = "Mille Pointes",
    -- Harb Foulmountain : Les Tarides d'après ForeverDB (pas Mille Pointes)
    ["Harb Montagne-fétide"] = "Les Tarides",
    ["Rasoir-de-coeur"] = "Mille Pointes",
    ["Ferregard l'Invincible"] = "Mille Pointes",
    ["Ravageur silithide"] = "Mille Pointes",
    ["Dard-vil"] = "Mille Pointes",
    ["Soufresang"] = "Marécage d'Âprefange",
    -- Mor'Ladim : Duskwood (mal classé aux Carmines avant)
    ["Mor'Ladim"] = "Bois de la Pénombre",
    ["Pique-les-yeux"] = "Marécage d'Âprefange",
    ["Veuve de Sombrebrume"] = "Marécage d'Âprefange",
    ["Flèche"] = "Marécage d'Âprefange",
    ["Dorgoth le Vagabond"] = "Marécage d'Âprefange",
    ["Hayoc"] = "Marécage d'Âprefange",
    ["Ver-de-limace"] = "Marécage d'Âprefange",
    ["Écaille-déchirée"] = "Marécage d'Âprefange",
    ["La Pourriture"] = "Marécage d'Âprefange",
    ["Grukk"] = "Tanaris",
    ["Croquesable"] = "Tanaris",
    ["Cyclok le Fou"] = "Tanaris",
    ["Oiseau de feu supérieur"] = "Tanaris",
    ["Haarka le Vorace"] = "Tanaris",
    ["Jin'Zallah Porte-sable"] = "Tanaris",
    ["Kregg Keelhaul"] = "Tanaris",
    ["Omgorn l'Égaré"] = "Tanaris",
    ["Soriid le Dévoreur"] = "Tanaris",
    ["Chef de guerre Krazzilak"] = "Tanaris",
    ["Antilus le Planeur"] = "Féralas",
    ["Arash-ethis"] = "Féralas",
    ["Bloodroar le Traqueur"] = "Féralas",
    ["Tête-de-diamant"] = "Féralas",
    ["Dame Szallah"] = "Féralas",
    ["Vieux Ventre-grison"] = "Féralas",
    ["Qirot"] = "Féralas",
    ["Grogneur"] = "Féralas",
    ["Sablonneux"] = "Gangrebois",
    ["Alshirr Souffléau"] = "Gangrebois",
    ["Dessecus"] = "Gangrebois",
    ["Immolatus"] = "Gangrebois",
    ["Mongress"] = "Gangrebois",
    ["Olm le Sage"] = "Gangrebois",
    ["Patte-enragée"] = "Gangrebois",
    ["L'Ongar"] = "Gangrebois",
    ["Mère de couvée Zavas"] = "Cratère d'Un'Goro",
    ["Gruff"] = "Cratère d'Un'Goro",
    ["Roi Mosh"] = "Cratère d'Un'Goro",
    ["Uhk'loc"] = "Cratère d'Un'Goro",
    ["Gretheer"] = "Silithus",
    ["Grubthor"] = "Silithus",
    ["Ouraganien"] = "Silithus",
    ["Krellack"] = "Silithus",
    ["Lapress"] = "Silithus",
    ["Rex Ashil"] = "Silithus",
    ["Setis"] = "Silithus",
    ["Seigneur du Crépuscule Everun"] = "Silithus",
    ["Zora"] = "Silithus",
    ["Antilos"] = "Azshara",
    ["Gardien Rageroar"] = "Azshara",
    ["Dame Sesspira"] = "Azshara",
    ["Maître Feardred"] = "Azshara",
    ["Monnos l'Ancien"] = "Azshara",
    ["L'Evalcharr"] = "Azshara",
    ["Fantôme de Varo'then"] = "Azshara",
    ["Azurous"] = "Hiverpré",
    ["Général Colbatann"] = "Hiverpré",
    ["Kashoch le Ravageur"] = "Hiverpré",
    ["Mezzir le Hurleur"] = "Hiverpré",
    ["Rak'shiri"] = "Hiverpré",
    ["Sian-Rotam"] = "Berceau-de-l'Hiver",
    -- Royaumes de l'Est
    ["Vieux Florent"] = "Bois de la Pénombre",
    ["Porc-épic mangeur d'hommes"] = "Bois de la Pénombre",
    ["Fedfennel"] = "Bois de la Pénombre",
    ["Gruff Morsure-vive"] = "Bois de la Pénombre",
    ["Gug Chandelle-grasse"] = "Bois de la Pénombre",
    ["Morgaine la Rusée"] = "Bois de la Pénombre",
    ["Mère Croc"] = "Bois de la Pénombre",
    ["Narg le Chef-de-tâche"] = "Bois de la Pénombre",
    ["Thuros Doigts-légers"] = "Bois de la Pénombre",
    ["Bjarn"] = "Dun Morogh",
    ["Edan le Hurleur"] = "Dun Morogh",
    ["Gibblewilt"] = "Dun Morogh",
    ["Grand-père Arctikus"] = "Dun Morogh",
    ["Hammerspine"] = "Dun Morogh",
    ["Timber"] = "Dun Morogh",
    ["Bayne"] = "Clairières de Tirisfal",
    ["Deeb"] = "Clairières de Tirisfal",
    ["Fermier Solliden"] = "Clairières de Tirisfal",
    ["Ombre de Fellicent"] = "Clairières de Tirisfal",
    ["Âme perdue"] = "Clairières de Tirisfal",
    ["Muad"] = "Clairières de Tirisfal",
    ["Ressan le Piqueur"] = "Clairières de Tirisfal",
    ["Sri'skulk"] = "Clairières de Tirisfal",
    ["Esprit tourmenté"] = "Clairières de Tirisfal",
    ["Krethis Tisse-ombre"] = "Clairières de Tirisfal",
    ["Boss Galgosh"] = "Loch Modan",
    ["Emogg le Broyeur"] = "Loch Modan",
    ["Grizlak"] = "Loch Modan",
    ["Grand crocolisque du loch"] = "Loch Modan",
    ["Seigneur Condar"] = "Loch Modan",
    ["Magosh"] = "Loch Modan",
    ["Shanda la Tisseuse"] = "Loch Modan",
    ["Brack"] = "Marches de l'Ouest",
    ["Foe Reaper 4000"] = "Marches de l'Ouest",
    ["Leprithus"] = "Marches de l'Ouest",
    ["Marisa du'Paige"] = "Marches de l'Ouest",
    ["Maître Fossoyeur"] = "Marches de l'Ouest",
    ["Sergent Brashclaw"] = "Marches de l'Ouest",
    ["Slark"] = "Marches de l'Ouest",
    ["Vultros"] = "Marches de l'Ouest",
    ["Coeur-de-rocher"] = "Les Carmines",
    ["Bavard"] = "Les Carmines",
    ["Kazon"] = "Les Carmines",
    ["Ribchaser"] = "Les Carmines",
    ["Rohh le Silencieux"] = "Les Carmines",
    ["Chercheur Aqualon"] = "Les Carmines",
    ["Snarlflare"] = "Les Carmines",
    ["Squiddic"] = "Les Carmines",
    ["Commandant Gangretrombe"] = "Bois de la Pénombre",
    ["Fenros"] = "Bois de la Pénombre",
    ["Seigneur Malathrom"] = "Bois de la Pénombre",
    -- Lupos : Bois de la Pénombre d'après ForeverDB (pas Bois de la Pénombre)
    ["Lupos"] = "Bois de la Pénombre",
    ["Naraxis"] = "Bois de la Pénombre",
    ["Brûle-Buissons"] = "Bois de la Pénombre",
    ["Nefaru"] = "Bois de la Pénombre",
    ["Scribe des sorts de Dalaran"] = "Forêt des Pins-Argentés",
    ["Gorefang"] = "Forêt des Pins-Argentés",
    ["Vieux Vicejaw"] = "Forêt des Pins-Argentés",
    ["Régent Serre-corbeau"] = "Forêt des Pins-Argentés",
    -- Rot Hide Bruiser : Alterac d'après ForeverDB (FR à confirmer en jeu)
    ["Bagarreur Peau-putride"] = "Montagnes d'Alterac",
    -- Snarlmane : Alterac d'après ForeverDB (pas Les Serres-Rocheuses)
    ["Snarlmane"] = "Montagnes d'Alterac",
    ["Rotheap"] = "Les Paluns",
    ["Garneg Crâne-brûlé"] = "Les Paluns",
    ["Gazz le Chasseur-du-loch"] = "Les Paluns",
    ["Gnawbone"] = "Les Paluns",
    ["Veuve-sangsue"] = "Les Paluns",
    ["Ma'ruk Écaille-de-ver"] = "Les Paluns",
    ["Mirelow"] = "Les Paluns",
    ["Rufus Tir-sombre"] = "Les Paluns",
    ["Sarltooth"] = "Les Paluns",
    ["Sludginn"] = "Les Paluns",
    ["Deux-Orteils"] = "Les Paluns",
    -- Big Samras : Arathi d'après ForeverDB (pas Hautebrande)
    ["Gros Samras"] = "Hautes-terres d'Arathi",
    ["Creepthess"] = "Contreforts de Hautebrande",
    ["Dame Zephris"] = "Contreforts de Hautebrande",
    ["Ro'Bark"] = "Contreforts de Hautebrande",
    ["Scargil"] = "Contreforts de Hautebrande",
    ["Tamra Stormpike"] = "Contreforts de Hautebrande",
    ["Araga"] = "Montagnes d'Alterac",
    ["Jimmy le Saignant"] = "Montagnes d'Alterac",
    ["Lo'Grosh"] = "Montagnes d'Alterac",
    ["Narillasanz"] = "Montagnes d'Alterac",
    ["Grybou"] = "Montagnes d'Alterac",
    ["Furie-de-pierre"] = "Montagnes d'Alterac",
    ["Darbel Montrose"] = "Hautes-terres d'Arathi",
    ["Kovork"] = "Hautes-terres d'Arathi",
    ["Molok le Broyeur"] = "Hautes-terres d'Arathi",
    ["Nimar le Tueur"] = "Hautes-terres d'Arathi",
    ["Prince Nazjak"] = "Hautes-terres d'Arathi",
    ["Ruul Pierre-unique"] = "Hautes-terres d'Arathi",
    ["Singer"] = "Hautes-terres d'Arathi",
    ["Zalas Écorce-fanée"] = "Hautes-terres d'Arathi",
    ["Gluggle"] = "Vallée de Strangleronce",
    ["Kurmokk"] = "Vallée de Strangleronce",
    ["Seigneur Sakrasis"] = "Vallée de Strangleronce",
    ["Boucher Mosh'Ogg"] = "Vallée de Strangleronce",
    ["Rippa"] = "Vallée de Strangleronce",
    ["Roloch"] = "Vallée de Strangleronce",
    ["Ventre-écailleux"] = "Vallée de Strangleronce",
    ["Verifonix"] = "Vallée de Strangleronce",
    ["Grosse patte"] = "Marais des Chagrins",
    ["Fingat"] = "Marais des Chagrins",
    ["Gilmorian"] = "Marais des Chagrins",
    ["Chef des Perdus"] = "Marais des Chagrins",
    ["Cuisinier des Perdus"] = "Marais des Chagrins",
    ["Rougeronce"] = "Marais des Chagrins",
    ["7:XT"] = "Terres ingrates",
    ["Anathemus"] = "Terres ingrates",
    ["Grondeur du désert"] = "Terres ingrates",
    ["Commandant de l'Ombreforge"] = "Terres ingrates",
    ["Golem de siège"] = "Terres ingrates",
    ["Golem de guerre"] = "Terres ingrates",
    ["Zaricotl"] = "Terres ingrates",
    ["Golem de guerre défaillant"] = "Gorge des Vents brûlants",
    ["Généralissime Mastrogonde"] = "Gorge des Vents brûlants",
    ["Rekk'tilac"] = "Gorge des Vents brûlants",
    ["Brûlar"] = "Gorge des Vents brûlants",
    ["Shleipnarr"] = "Gorge des Vents brûlants",
    ["Fumar"] = "Gorge des Vents brûlants",
    ["Fourbasse"] = "Steppes Ardentes",
    ["Gorgon'och"] = "Steppes Ardentes",
    ["Gruklash"] = "Steppes Ardentes",
    ["Hahk'Zor"] = "Steppes Ardentes",
    ["Hematos"] = "Steppes Ardentes",
    ["Ravageur défectueux"] = "Steppes Ardentes",
    ["Étincelle-terreur"] = "Steppes Ardentes",
    ["Thauris Balgarr"] = "Steppes Ardentes",
    ["Volchan"] = "Steppes Ardentes",
    ["Akubar le Voyant"] = "Terres foudroyées",
    ["Clack le Ravageur"] = "Terres foudroyées",
    ["Oeil-de-mort"] = "Terres foudroyées",
    ["Dériseffroi"] = "Terres foudroyées",
    ["Grunter"] = "Terres foudroyées",
    ["Magronos l'Inflexible"] = "Terres foudroyées",
    ["Mojo le Tordu"] = "Terres foudroyées",
    ["Ravage"] = "Terres foudroyées",
    ["Ecorchebile"] = "Terres foudroyées",
    ["Murmure-effroi"] = "Maleterres de l'Ouest",
    ["Crinière-immonde"] = "Maleterres de l'Ouest",
    ["Seigneur Maldazzar"] = "Maleterres de l'Ouest",
    ["Bourreau écarlate"] = "Maleterres de l'Ouest",
    ["Haut clerc écarlate"] = "Maleterres de l'Ouest",
    ["Interrogateur écarlate"] = "Maleterres de l'Ouest",
    ["Juge écarlate"] = "Maleterres de l'Ouest",
    ["Forgeron écarlate"] = "Maleterres de l'Ouest",
    ["La Carcasse"] = "Maleterres de l'Ouest",
    ["Duggan Wildhammer"] = "Maleterres de l'Est",
    ["Gish l'Immobile"] = "Maleterres de l'Est",
    ["Hed'mush le Pourrissant"] = "Maleterres de l'Est",
    ["Grand général Abbendis"] = "Maleterres de l'Est",
    ["Contremaître nérubien"] = "Maleterres de l'Est",
    ["Seigneur de guerre Thresh'jin"] = "Maleterres de l'Est",
    ["Zul'Brin Rameau-tordu"] = "Maleterres de l'Est",
    ["Grimungous"] = "Les Hinterlands",
    ["Dos-de-fer"] = "Les Hinterlands",
    ["Jalinde Drake-d'été"] = "Les Hinterlands",
    ["Mith'rethis l'Enchanteur"] = "Les Hinterlands",
    ["Trancheserre"] = "Les Hinterlands",
    ["Witherheart le Traqueur"] = "Les Hinterlands",
    ["Zul'arek Haine-ramée"] = "Les Hinterlands",
    ["Casses-Cornes"] = "Gorges des Chants éternels",
}
-- (succès ménagerie ajoutés à la table par MHH_AjouterSuccesMenagerie,
-- juste après la déclaration — affinité 100 et enclos complet)

MHH_SUCCES = {
    -- La chasse
    { id = "premiere",   cat = L("La chasse"),        tex = "INV_Sword_09",                 nom = L("Première chasse"),      desc = L("Tuer son premier monstre du carnet") },
    { id = "veteran",    cat = L("La chasse"),        tex = "Ability_Hunter_BeastTaming",   nom = L("Vétéran"),               desc = L("10 chasses réussies") },
    { id = "accompli",   cat = L("La chasse"),        tex = "Ability_Hunter_AimedShot",     nom = L("Chasseur accompli"),     desc = L("25 chasses réussies") },
    { id = "legende",    cat = L("La chasse"),        tex = "Ability_Hunter_BeastTaming",    nom = L("Légende de la chasse"),  desc = L("100 chasses réussies") },
    { id = "grandgibier",cat = L("La chasse"),        tex = "Spell_Nature_Thorns",          nom = L("Grand gibier"),          desc = L("Abattre une bête rare de niveau >= au vôtre") },
    { id = "couteau",    cat = L("La chasse"),        tex = "Ability_Rogue_Eviscerate",   nom = L("Chasse au couteau"),     desc = L("Abattre une bête rare de niveau supérieur au vôtre") },
    { id = "nocturne",   cat = L("La chasse"),        tex = "Spell_Nature_Sleep",           nom = L("Chasseur nocturne"),     desc = L("Réussir une chasse entre 22h et 6h (serveur)") },
    { id = "imbattable", cat = L("La chasse"),        tex = "Ability_Warrior_BattleShout",  nom = "Imbattable",            desc = L("Tuer un monstre du carnet sans perdre plus de 25% de vie") },
    { id = "intact",     cat = L("La chasse"),        tex = "Ability_Stealth",              nom = L("Sans une égratignure"),  desc = L("Tuer un monstre du carnet sans perdre un point de vie") },
    -- Prouesses
    { id = "serie5",     cat = "Prouesses",       tex = "Ability_Hunter_BeastTaming",   nom = L("Série de 5"),            desc = L("5 chasses consécutives sans mourir") },
    { id = "serie10",    cat = "Prouesses",       tex = "Spell_Fire_FireBolt",          nom = L("Main chaude"),           desc = L("10 chasses consécutives sans mourir") },
    { id = "piege",      cat = "Prouesses",       tex = "Spell_Frost_Stun",             nom = L("Chasseur de pièges"),     desc = L("Abattre un monstre du carnet pris dans un piège") },
    { id = "coeur_tendre", cat = "Prouesses",     tex = "INV_Misc_Gift_01",            nom = L("Cœur tendre"),            desc = L("Relâcher un spécimen de la ménagerie") },
    { id = "naturaliste",cat = L("Le naturaliste"),  tex = "INV_Misc_Book_09",             nom = "Grand naturaliste",     desc = L("Cataloguer 20 monstres") },
    { id = "zoologue",   cat = L("Le naturaliste"),  tex = "INV_Misc_Book_09",             nom = L("Zoologue de terrain"),   desc = L("Cataloguer 50 monstres") },
    { id = "butin",      cat = L("Le naturaliste"),  tex = "Ability_Hunter_AimedShot",     nom = L("Curieux de butin"),      desc = L("Looter un objet bleu (ou mieux) sur un monstre du carnet") },
    -- Exploration
    { id = "globe",      cat = "Exploration",     tex = "Spell_Arcane_StarFire",        nom = "Globe-trotter",         desc = L("Chasses réussies dans 10 zones différentes") },
    { id = "decouverte", cat = "Exploration",     tex = "Spell_Arcane_StarFire",        nom = L("Première découverte"),   desc = L("Croiser pour la première fois un rare") },
    { id = "explorateur",cat = "Exploration",     tex = "Spell_Nature_Thorns",          nom = L("Traqueur des profondeurs"), desc = L("Croiser 5 rares différents") },
    { id = "rencontres10", cat = "Exploration",  tex = "Ability_Hunter_BeastTaming",   nom = L("Œil du traqueur"), desc = L("Croiser 10 rares différents") },
    { id = "rencontres25", cat = "Exploration",  tex = "Ability_Hunter_BeastTaming",   nom = L("Vieille connaissance des sentiers"), desc = L("Croiser 25 rares différents") },
    { id = "regioncomplete", cat = "Exploration", tex = "INV_Misc_Book_09",             nom = L("Naturaliste régional"), desc = L("Croiser tous les rares d'une même région") },
    -- Légendes locales
    { id = "brachland",  cat = L("Légendes locales"), tex = "Ability_Hunter_BeastTaming",  nom = L("Toute une panoplie"),    desc = L("Tuer Humar, Vif-Crinière et Takk — les trois fiertés des plaines") },
    { id = "rotheap",    cat = L("Légendes locales"), tex = "Spell_Frost_FrostBolt",      nom = L("Ami des profondeurs"),   desc = L("Tuer Rotheap dans les Paluns") },
    -- Les éléments (météo Forever via C_Weather)
    { id = "pluie",      cat = L("Les éléments"),      tex = "Spell_Frost_Frostbolt",        nom = L("Danse de la pluie"),     desc = L("Réussir une chasse sous la pluie") },
    { id = "feu",        cat = L("Les éléments"),      tex = "Spell_Fire_FireBolt",          nom = L("Chasseur de l'apocalypse"), desc = L("Réussir une chasse pendant une pluie de feu") },
    { id = "neige",      cat = L("Les éléments"),      tex = "Spell_Frost_FrostArmor",       nom = L("Traqueur des neiges"),   desc = L("Réussir une chasse sous la neige") },
    -- La ménagerie
    { id = "amidevoue",  cat = L("La ménagerie"), tex = "Ability_Hunter_BeastTaming", nom = L("Ami dévoué"), desc = L("Amener un pensionnaire à 100 d'affinité") },
    { id = "encloscomplet", cat = L("La ménagerie"), tex = "INV_Box_01", nom = L("Enclos complet"), desc = L("Avoir tous les spécimens de la savane en enclos") },
    { id = "eleveur", cat = L("La ménagerie"), tex = "Spell_Nature_SpiritWolf", nom = L("Éleveur"), desc = L("Avoir 5 pensionnaires en enclos") },
}

local function nbChasses()
    local n = 0
    for _, v in pairs(DB.chasses) do n = n + (v.kills or 0) end
    return n
end

local function nbCatalogues()
    local n = 0
    for _, v in pairs(DB.chasses) do if v.vu then n = n + 1 end end
    return n
end

local function nbDecouverts()
    -- v0.119 : compte les RENCONTRES (première fois qu'on cible un rare),
    -- pas seulement les rares hors carnet. Compteurs Guilde, titres
    -- « traqueur »/« Étoile du découvreur » et succès en découlent tous.
    local n = 0
    if DB.rencontres then
        for _ in pairs(DB.rencontres) do n = n + 1 end
    else
        for _ in pairs(DB.decouverts) do n = n + 1 end
    end
    return n
end

-- Toast de succès doré (style MH) — avec FILE d'attente : quand plusieurs
-- succès se déclenchent d'un coup (prise d'un rare), les toasts s'affichent
-- L'UN APRÈS L'AUTRE au lieu de se superposer.
local fileToasts = {}
local toastEnCours = false
-- Forward : la bannière est créée plus bas dans le fichier — le toast
-- l'attend pour ne pas s'afficher à moitié dessous (défini après sa
-- création)
local MHH_BanniereVisible = function() return false end
-- Anti-empilement : quand plusieurs toasts arrivent pendant que la
-- bannière occupe l'écran, UN SEUL timer de reprise doit exister —
-- sinon chaque reprise affiche un toast en même temps, au même
-- endroit : textes juxtaposés illisibles (rang + succès + prise).
local toastRepriseEnAttente = false
-- Icônes RONDES du médaillon (Textures/Circles/) : quand l'icône du jeu
-- a une version ronde, le toast parchemin l'utilise — sinon repli sur
-- l'icône carrée du jeu (v1 : griffe/patte/sceau — voir icones_rondes.py)
MHH_ICONES_RONDES = { -- GLOBALE préfixée (limite 200 locales du chunk)
    ["INV_Misc_MonsterClaw_04"] = "griffe",  -- prise validée + couronne d'or
    ["Ability_Hunter_BeastTaming"] = "patte", -- spécimen capturé + intrus
    ["INV_Misc_Note_01"] = "sceau",           -- contrat rempli
    ["INV_Misc_Coin_01"] = "sceau",           -- /hunt test prime
    ["INV_Misc_Dice_01"] = "rumor",             -- rumeur élucidée (v0.63)
}
function MHH_AppliquerIconeMedaillon(icone, texPath)
    -- Chemin complet -> nom de fichier seul, puis version ronde si dispo.
    -- Ronde = 74 px (elle rempli le médaillon, elle a sa propre bordure) ;
    -- carrée = 54 px (elle « flotte », le carré se fait discret).
    local base = texPath and texPath:match("([^\\]+)$")
    local ronde = base and MHH_ICONES_RONDES[base]
    if ronde then
        -- v0.150 : BUG 1.12 — SetTexture ne renvoie RIEN, donc « ok »
        -- valait TOUJOURS nil : les icônes RONDES n'étaient JAMAIS
        -- utilisées, même générées. Le bon test (cf. /hunt test icones)
        -- est GetTexture() ~= nil APRÈS le SetTexture.
        icone:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\Circles\\" .. ronde .. ".tga")
        if icone:GetTexture() then
            icone:SetSize(102, 102)
            return -- ronde chargée : fini
        end
    end
    icone:SetSize(54, 54)
    icone:SetTexture(texPath or "Interface\\Icons\\INV_Misc_QuestionMark")
end
local function ToastSuccesSuivant()
    -- File courtoise : quand le bandeau « CHASSE RÉUSSIE » occupe le
    -- haut de l'écran, le toast attend sa disparition (3 s) — avant,
    -- les deux se chevauchaient à moitié.
    if MHH_BanniereVisible() then
        if not toastRepriseEnAttente then
            toastRepriseEnAttente = true
            C_Timer.After(0.5, function()
                toastRepriseEnAttente = false
                ToastSuccesSuivant()
            end)
        end
        return
    end
    local args = table.remove(fileToasts, 1)
    if not args then
        toastEnCours = false
        return
    end
    toastEnCours = true
    local texPath, nom, desc = args[1], args[2], args[3]
    -- typeAff : type d'affichage du toast — « succes » = desc est une
    -- phrase (ancien système), sinon desc = nom (évent. avec zone entre
    -- parenthèses) affiché en grand — voir ToastSuccesSuivant
    local typeAff = args[5]
    -- forceMode : surcharge ponctuelle du mode (« wow » = ancien encart
    -- sombre, demandé pour la promotion de guilde et /hunt test wow)
    local forceMode = args[4] or MHH_ToastForceMode
    MHH_ToastForceMode = nil
    local mode = forceMode or DB.config.toast
    local t = CreateFrame("Frame", nil, UIParent)
    -- Position : remontée à la demande du joueur (2e itération) : en
    -- mode custom, -170 du haut ; en mode wow, -35. Les toasts arrivent
    -- après la bannière de victoire, éphémère — le chevauchement reste
    -- acceptable au profit de la visibilité.
    local yToast = (mode == "custom") and -170 or -35
    t:SetFrameStrata("HIGH")
    local tex, tdx -- titre + description (créés selon le mode ci-dessous)
    if mode == "custom" then
        -- Toast PARCHEMIN : fond toast1.tga (bannière de guilde), icône
        -- posée dans le médaillon à droite (~85% de la largeur), tampon
        -- de faction encre en bas à gauche. Ratio de toast1.tga : 2,6:1.
        t:SetSize(520, 200)
        t:SetPoint("TOP", UIParent, "TOP", 0, yToast)
        -- Plaque sombre de SECOURS sous la bannière : si toast1.tga est
        -- absente (première installation), le toast retombe de lui-même
        -- sur un fond sombre — le texte reste lisible quoi qu'il arrive.
        local secours = t:CreateTexture(nil, "BACKGROUND")
        secours:SetAllPoints()
        secours:SetColorTexture(0.06, 0.04, 0.02, 0.95)
        local parch = t:CreateTexture(nil, "ARTWORK")
        parch:SetAllPoints()
        pcall(function() parch:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\toast1.tga") end)
        -- Icône du jeu dans le médaillon (36-58 px : le médaillon fait
        -- ~30% de la hauteur de la bannière)
        local icone = t:CreateTexture(nil, "OVERLAY")
        -- Taille posée par AppliquerIconeMedaillon selon ronde/carrée
        -- (177, 1) : itération de recentrage finale (retours de test en jeu)
        icone:SetPoint("CENTER", t, "CENTER", 177, 1)
        -- Icône ronde si elle existe (Textures/Circles/), sinon carrée
        MHH_AppliquerIconeMedaillon(icone, texPath)
        -- Tampon de guilde : Alliance = lion bleu, Horde = worg rouge
        -- (tampons encre façon MH, découpe alpha circulaire)
        local tampon = t:CreateTexture(nil, "OVERLAY")
        tampon:SetSize(92, 92)
        -- Bien À L'INTÉRIEUR du parchemin : agrandi et descendu vers
        -- le coin bas-gauche, marge de sécurité conservée (retour test)
        tampon:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 20, 18)
        -- INCLINAISON -12° : un vrai coup de tampon n'est jamais droit.
        -- BUG CORRIGÉ : les coins doivent suivre la convention WoW
        -- (Y vers le BAS) — avec Y inversé, la rotation devenait un
        -- MIROIR et le lion paraissait « retourné ». Formule propre :
        -- le point affiché au coin (cx,cy) du cadre échantillonne la
        -- texture tournée en sens inverse : (cx·cosφ + cy·sinφ,
        -- -cx·sinφ + cy·cosφ) — déterminant +1 : rotation pure.
        local rad = math.rad(-12)
        local cR, sR = math.cos(rad), math.sin(rad)
        local function coinTampon(cx, cy)
            return 0.5 + cR * cx + sR * cy, 0.5 - sR * cx + cR * cy
        end
        -- Attention : seuls les DERNIERS appels d'une liste d'arguments
        -- sont expansés en valeurs multiples — on passe par des
        -- variables, sinon SetTexCoord ne reçoit que 5 valeurs (bug Lua)
        -- Coins du cadre en repère écran (Y vers le bas) :
        local ulx, uly = coinTampon(-0.5, -0.5)
        local llx, lly = coinTampon(-0.5, 0.5)
        local urx, ury = coinTampon(0.5, -0.5)
        local lrx, lry = coinTampon(0.5, 0.5)
        tampon:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
        -- Tampon de guilde : Alliance = lion bleu, Horde = worg rouge.
        -- MHH_ToastTestFaction : surcharge ponctuelle pour /hunt test tampon
        local faction = MHH_ToastTestFaction or "Alliance"
        if not MHH_ToastTestFaction then
            pcall(function() local f = UnitFactionGroup and UnitFactionGroup("player") if f then faction = f end end)
        end
        MHH_ToastTestFaction = nil
        tampon:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\tampon_"
            .. ((faction == "Horde") and "horde" or "alliance") .. ".tga")
        tampon:SetAlpha(0.9)
        -- garde la reference pour le fondu : le tampon fane PLUS VITE
        -- que le toast (retour de test : bleu plein, il restait visible
        -- un poil apres la disparition du parchemin beige)
        t.tamponRef = tampon
        -- Textes sur la zone centrale du parchemin (texte brun sombre :
        -- le fond est beige, le blanc classique y serait illisible)
        tex = t:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        -- MEME ZONE que le nom (x90..370, centre x250) : alignement
        -- parfait titre / filet / nom. Le « ! » des titres longs
        -- debordait sur le medaillon a droite (retour de test mission :
        -- le rond metallier commence a x386) — la zone s'arrete a x370,
        -- et la taille auto garantit qu'aucun titre ne l'atteint
        tex:SetPoint("TOPLEFT", t, "TOPLEFT", 110, -44)
        tex:SetWidth(280)
        tex:SetJustifyH("CENTER")
        -- Titre XXL : c'est LE moment « wahou » du toast. Plus
        -- prononcé : OUTLINE + ombre brune (l'outline prend la couleur
        -- de l'ombre) — brun MOYEN, pas foncé : un contour trop sombre
        -- faisait « autocollant », le brun moyen fait « encre pressée »
        -- TAILLE AUTO du titre : « MISSION ACCOMPLIE ! » (19 c.) se
        -- repliait sur deux lignes qui écrasaient le filet (retour de
        -- test) — le titre tient TOUJOURS sur une ligne désormais
        local titreTxt = string.upper(nom or "") .. " !"
        -- v0.64 : « CONTRAT REMPLI ! » (16 c.) en 30 px REPLIAIT sur
        -- deux lignes (retour de test) — paliers recalibres prudemment :
        -- 26 px des 14 caracteres (taille validee de « RUMEUR ÉLUCIDÉE ! »)
        local tailleTitre = #titreTxt <= 13 and 32
            or (#titreTxt <= 17 and 26)
            or (#titreTxt <= 18 and 24)
            or (#titreTxt <= 22 and 22)
            or 20
        pcall(function() tex:SetFont("Fonts\\FRIZQT__.TTF", tailleTitre, "OUTLINE") end)
        tex:SetTextColor(0.62, 0.47, 0.12) -- or encré, plus éclatant
        tex:SetShadowColor(0.42, 0.30, 0.14)
        tex:SetShadowOffset(0, 0)
        -- MAJUSCULES + « ! » : la façon Monster Hunter (QUÊTE
        -- ACCOMPLIE s'y affiche en grandes capitales d'or sur ruban)
        tex:SetText(titreTxt)
        -- Filet gravé sous le titre : délimiteur DORÉ (le brun sombre
        -- passait pour du noir — retour de test)
        local filetTitre = t:CreateTexture(nil, "OVERLAY")
        filetTitre:SetSize(220, 2)
        filetTitre:SetPoint("TOPLEFT", t, "TOPLEFT", 140, -92)
        filetTitre:SetColorTexture(0.78, 0.62, 0.28, 0.9)
        tdx = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        -- x100 largeur 280 : zone recentree ENTRE tampon (fin x112) et
        -- icone (debut x386) — retour de test missions : le texte et le
        -- tiret de la region passaient SOUS le tampon lion
        tdx:SetPoint("TOPLEFT", t, "TOPLEFT", 110, -102)
        tdx:SetWidth(280)
        tdx:SetJustifyH("CENTER")
        -- Description : « Rotheap (Les Paluns) » est éclatée en deux
        -- lignes — le NOM en 26 px avec fin contour d'encre (il pète
        -- presque comme le titre, retour de test : la police plate
        -- était trop « sage »), la RÉGION dessous en plus discret.
        -- Succès (typeAff) : desc est une phrase, pas un nom — même
        -- traitement auto, jamais de zone entre parenthèses.
        local nomEntite, region
        if typeAff == "succes" then
            nomEntite, region = desc, nil
        else
            nomEntite, region = (desc or ""):match("^(.-) %((.-)%)$")
            if not nomEntite then nomEntite, region = desc, nil end
        end
        -- PAS de region (rumeurs, succes) : le nom descend au milieu de
        -- l'espace libre — colle sous le filet, il laissait un grand vide
        -- sous lui et le bloc paraissait tout en haut (retour de test)
        if not region then tdx:SetPoint("TOPLEFT", t, "TOPLEFT", 110, -122) end
        tdx:SetText(nomEntite or "")
        -- TAILLE AUTO du nom : 26 px pour un nom de bête court, mais
        -- « Nettoyer la tannerie — Rivau » ou « Le dé pipé de Menara »
        -- débordaient sur le tampon (gauche) et l'icône (droite) —
        -- retour de test missions/rumeurs. Le texte reste entre les
        -- deux, quelle que soit sa longueur
        local tailleNom = #nomEntite <= 16 and 26 or (#nomEntite <= 28 and 21 or 17)
        -- Police PLEINE a toutes les tailles (retour de test : l'OUTLINE
        -- aux petites tailles rendait le texte trop gras / trop noir)
        pcall(function() tdx:SetFont("Fonts\\FRIZQT__.TTF", tailleNom) end)
        tdx:SetTextColor(0.32, 0.20, 0.06) -- encre profonde
        tdx:SetShadowColor(0.85, 0.72, 0.45)
        tdx:SetShadowOffset(1, -1)
        if region then
            local tdx2 = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            tdx2:SetPoint("TOPLEFT", t, "TOPLEFT", 110, -138)
            tdx2:SetWidth(280)
            tdx2:SetJustifyH("CENTER")
            pcall(function() tdx2:SetFont("Fonts\\FRIZQT__.TTF", #region <= 24 and 19 or 15) end)
            tdx2:SetTextColor(0.45, 0.34, 0.20) -- encre délavée, hiérarchie
            tdx2:SetShadowColor(0.85, 0.72, 0.45)
            tdx2:SetShadowOffset(1, -1)
            -- MAJUSCULES + tirets cadratins : la région se lit comme
            -- un cartouche de carte (retour de test : trop « sage »)
            tdx2:SetText("— " .. string.upper(region) .. " —")
        end
    else
        -- Toast classique (mode wow) : plaque sombre à liseré doré
        t:SetSize(380, 64)
        t:SetPoint("TOP", UIParent, "TOP", 0, yToast)
        -- Vrai liseré : l'ancien « bord » doré couvrait TOUT le cadre
        -- (SetAllPoints sur la couche du dessus) — le toast n'était qu'un
        -- aplat doré. Encadrement façon parchemin à la place : liseré
        -- brun-doré de 3 px, fond sombre inset, filet doré discret, et une
        -- barre d'accent le long de l'icône — comme une plaque de prime.
        local bord = t:CreateTexture(nil, "BACKGROUND")
        bord:SetAllPoints()
        bord:SetColorTexture(0.60, 0.44, 0.20, 0.98) -- liseré brun-doré
        local fond = t:CreateTexture(nil, "BORDER")
        fond:SetPoint("TOPLEFT", 3, -3)
        fond:SetPoint("BOTTOMRIGHT", -3, 3)
        fond:SetColorTexture(0.06, 0.04, 0.02, 0.95) -- fond sombre, liseré visible
        local filet = t:CreateTexture(nil, "BORDER")
        filet:SetPoint("TOPLEFT", 6, -6)
        filet:SetPoint("BOTTOMRIGHT", -6, 6)
        filet:SetColorTexture(0.78, 0.62, 0.25, 0.28) -- filet doré discret
        local accent = t:CreateTexture(nil, "BORDER")
        accent:SetSize(4, 52)
        accent:SetPoint("LEFT", 5, 0)
        accent:SetColorTexture(0.78, 0.62, 0.25, 0.90) -- barre à gauche de l'icône
        -- Icône du jeu (les emojis ne s'affichent pas dans WoW)
        local icone = t:CreateTexture(nil, "ARTWORK")
        icone:SetSize(36, 36)
        icone:SetPoint("LEFT", 14, -4) -- centré sur le bloc texte (titre +8, desc -12)
        icone:SetTexture(texPath or "Interface\\Icons\\INV_Misc_QuestionMark")
        tex = t:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        tex:SetPoint("LEFT", 62, 8)
        tex:SetText("|cffffd100" .. nom .. "|r")
        tdx = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tdx:SetPoint("LEFT", 64, -12)
        tdx:SetText(desc)
    end
    -- 4 s d'affichage puis fondu (retour de test : le toast partait
    -- un poil trop tard après la validation)
    C_Timer.After(4, function()
        for i = 1, 10 do
            C_Timer.After(i * 0.1, function()
                t:SetAlpha(1 - i / 10)
                -- Tampon : plus de surcharge — l'alpha du cadre
                -- s'applique aussi au tampon, fondu synchronise avec
                -- le parchemin (volonte de l'utilisateur)
            end)
        end
        C_Timer.After(1.2, function()
            t:Hide()
            -- Suite de la file : au toast suivant s'il en reste
            ToastSuccesSuivant()
        end)
    end)
    if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 888) end
end
local function ToastSucces(texPath, nom, desc, forceMode, typeAff)
    fileToasts[#fileToasts + 1] = { texPath, nom, desc, forceMode, typeAff }
    if not toastEnCours then ToastSuccesSuivant() end
end

-- Toast « Cible du jour » : bandeau cliquable à la connexion, façon
-- panneau d'annonce de prime MH. Clic = ouvrir le carnet sur l'Accueil.
local function ToastCibleDuJour(nom, zone)
    local t = CreateFrame("Frame", nil, UIParent)
    -- Notification compacte coin haut-droit : pas de grand encart centré,
    -- l'info reste discrète (l'icône donne l'accent, le texte habille).
    -- (v0.6 : l'encart parchemin toast2.tga a été testé puis retiré —
    -- la cible du jour reste sur ce format compact, à la demande.)
    t:SetSize(380, 66)
    t:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -260, -70)
    t:SetFrameStrata("HIGH")
    t:EnableMouse(true)
    -- Fond de secours en textures couleur : sur certains clients, SetBackdrop
    -- échoue silencieusement sur un cadre fraîchement créé hors ADDON_LOADED.
    local bord = t:CreateTexture(nil, "BACKGROUND")
    bord:SetAllPoints()
    bord:SetColorTexture(0.60, 0.44, 0.20, 0.95) -- liseré brun-doré, plus léger
    local fond = t:CreateTexture(nil, "BORDER")
    fond:SetPoint("TOPLEFT", 3, -3)
    fond:SetPoint("BOTTOMRIGHT", -3, 3)
    fond:SetColorTexture(0.06, 0.04, 0.02, 0.95) -- fond sombre
    -- Bordure standard par-dessus (double sécurité)
    pcall(function()
        t:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        t:SetBackdropColor(0.05, 0.03, 0.02, 0.92)
        t:SetBackdropBorderColor(0.60, 0.44, 0.20, 0.95)
    end)
    local icone = t:CreateTexture(nil, "ARTWORK")
    icone:SetSize(36, 36)
    icone:SetPoint("LEFT", 14, 0)
    icone:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    local tex = t:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tex:SetPoint("TOPLEFT", t, "TOPLEFT", 62, -9)
    tex:SetText("|cffffd100CIBLE DU JOUR|r")
    local tdx = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tdx:SetPoint("TOPLEFT", t, "TOPLEFT", 62, -30)
    tdx:SetWidth(304)
    tdx:SetJustifyH("LEFT")
    tdx:SetText("|cffffff00" .. nom .. "|r (" .. (zone or "?") .. L(") — prime : +20 points.\n|cffa58b54Clic : ouvrir le carnet.|r"))
    t:SetScript("OnMouseDown", function()
        OuvrirCarnet("contrats")
        t:Hide()
    end)
    C_Timer.After(6, function()
        for i = 1, 10 do
            C_Timer.After(i * 0.1, function() t:SetAlpha(1 - i / 10) end)
        end
        C_Timer.After(1.2, function() t:Hide() end)
    end)
    if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 888) end
end

local function DebloquerSucces(id)
    if DB.succes[id] then return end
    DB.succes[id] = time()
    for _, s in ipairs(MHH_SUCCES) do
        if s.id == id then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Succès débloqué : |cffffff00") .. s.nom .. "|r — " .. s.desc)
            ToastSucces("Interface\\Icons\\" .. (s.tex or "INV_Misc_QuestionMark"), s.nom, s.desc, nil, "succes")
            return
        end
    end
end

-- Rangs de guilde (seuils en points)
MHH_RANGS = {
    { seuil = 0,    nom = "Aspirant" },
    { seuil = 50,   nom = "Chasseur" },
    { seuil = 200,  nom = L("Chasseur aguerri") },
    { seuil = 500,  nom = L("Vétéran") },
    { seuil = 1500, nom = L("Légende de la chasse") },
}
-- (v0.59 : l'ancienne table hexa MHH_RANG_COULEURS de la v0.56 est retirée
-- au profit de MHH_RangHex, dérivé de la palette du liseré du carnet — une
-- seule famille de couleurs de rang dans tout l'addon.)
local function RangGuilde(points)
    local idx = 1
    for i, r in ipairs(MHH_RANGS) do
        if points >= r.seuil then idx = i end
    end
    return idx, MHH_RANGS[idx].nom
end

-- Signature du rang MAXIMUM : la Blackrock orchestrée (39 s) ne joue qu'une
-- fois — à la promotion qui t'emmène au dernier rang. Le sommet a sa fanfare,
-- les combats suivants restent dans les banques normales. (Déclarée ici, avant
-- la section musiques, car la promotion l'utilise depuis plus haut.)
MHH_PISTE_RANG_MAX = { id = 1080493, d = 39 }

-- Notes d'encyclopédie (fiche détail, façon carnet MH)
MHH_NOTES = {
    ["Humar le Seigneur hautain"] = L("Le lion noir qui dort sous le grand arbre, au nord de la Baie du Butin."),
    ["Takk le Bondisseur"] = L("Ses bonds laissent des traces profondes dans la poussière des Tarides."),
    ["Flinkmähne"] = L("Le zèbre rapide du plateau. Il faut des jambes pour le suivre."),
    ["Vif-Crinière"] = L("Le zèbre rapide du plateau. Il faut des jambes pour le suivre."),
    ["Rotheap"] = L("Il sort de la mer à la nuit tombée et remonte la rivière. Il en faut plusieurs pour le vaincre."),
    ["Naraxis"] = L("L'araignée des Collines. Sa toile se tend à l'ouest, parmi les arbres morts."),
    ["Mor'Ladim"] = L("Morgan Ladimore, chevalier mort sans sépulture — sa fille Sarah fleurit sa tombe, lui rôde."),
    ["Malcin cendrecœur"] = L("Un ancien de la Ruche-Sacrenuit, exilé loin de sa reine."),
    -- Iconiques sans contenu jusqu'ici : le naturaliste les couvre aussi
    ["Le Rateau"] = L("Ses griffes tombent plus vite que l'œil ne cligne. Les prairies l'entendent avant de le voir."),
    ["Hurlement fantôme"] = L("Un loup esprit qui hante les plaines. Blessez-le, et le hurlement qu'il rend ne s'oublie pas."),
    ["Lupos"] = L("Ce worg mord avec l'ombre. Les chasseurs qui l'ont affronté en gardent des frissons noirs."),
    ["Foe Reaper 4000"] = L("Une faux des champs qui a appris à faucher autre chose que le blé. Les épouvantails l'évitent."),
    ["Dame Vespira"] = L("Une naga qui se prend pour une princesse de la côte. Sa couronne, ce sont vos os."),
    ["Gesharahan"] = L("Le vieux croc des marées. Sa mâchoire claque comme une porte de prison."),
    ["Boahn"] = L("Serpent des marais, patient comme la vase. On le voit trop tard, jamais deux fois."),
    ["Squiddic"] = L("Un murloc qui chante faux, mais qui croque juste. Le bord de l'eau est à lui."),
    ["Rohh le Silencieux"] = L("Il ne ronronne pas, il ne piste pas : il attend. La panthère que l'on ne voit qu'une fois."),
    ["Vieux Vicejaw"] = L("Une gueule d'un autre âge, pleine de dents usées qui tiennent encore bon."),
    ["Seigneur Condar"] = L("Le roi des courants d'air. Son ombre passe sur vous avant son cri."),
    ["Veuve-sangsue"] = L("Sa toile boit plus que la rosée. Les paluns évitent ses arbres depuis toujours."),
    ["Snarlmane"] = L("Un lion des montagnes à crinière en broussaille. Les gnolls l'appellent « le mauvais temps »."),
}
-- Graphies officielles du client : les noms renommés pointent vers la
-- même note (les anciennes clés ci-dessus restent valables pour les
-- vieux carnets, façon alias de fusion).
MHH_NOTES["Humar le Fier"] = MHH_NOTES["Humar le Seigneur hautain"]
MHH_NOTES["Vif-crins"] = MHH_NOTES["Vif-Crinière"]
MHH_NOTES["Le Rake"] = MHH_NOTES["Le Rateau"]
MHH_NOTES["Hurleur fantomatique"] = MHH_NOTES["Hurlement fantôme"]
MHH_NOTES["Rohh le silencieux"] = MHH_NOTES["Rohh le Silencieux"]
MHH_NOTES["Vieux Vile mâchoire"] = MHH_NOTES["Vieux Vicejaw"]
MHH_NOTES["Veuve sanguine"] = MHH_NOTES["Veuve-sangsue"]
-- Passe LORE : notes documentées (quêtes, références Warcraft, notoriété
-- des familiers de chasseur) pour les rares qui ont une vraie histoire.
-- Pas d'invention : le reste du bestiaire reste au générateur.
MHH_NOTES["Brèchedent"] = L("La chatte la plus rapide d'Azeroth : cadence d'attaque éclair, le cauchemar des lanceurs de sorts.")
MHH_NOTES["Rak'shiri"] = L("Frostsaber d'exception, longtemps le félin le plus convoité des chasseurs d'Hiverpré.")
MHH_NOTES["Grogneur"] = L("Ce loup noir résiste au feu mieux qu'une forge — les chasseurs l'ont longtemps dressé pour ça.")
MHH_NOTES["Grunter"] = L("Un sanglier de guerre : il charge, il revient, il charge encore. Rien ne le calme.")
MHH_NOTES["Olm la Sage"] = L("Une chouette d'une sagesse proverbiale. Les elfes de Gangrebois la croisent un présage.")
MHH_NOTES["Fantôme de Varo'then"] = L("Capitaine de la garde d'Azshara, tombé à la guerre des Anciens : son fantôme hante encore la rive.")
MHH_NOTES["Grand général Abbendis"] = L("L'un des fondateurs de la Croisade écarlate : fanatique en vie, redoutable en mort.")
MHH_NOTES["Seigneur forestier Hawspear"] = L("Le seigneur des rôdeurs de Quel'Lithien : dernier rempart elfe contre le Fléau.")
MHH_NOTES["Seigneur du crépuscule Everun"] = L("Un lord du Marteau du crépuscule, venu préparer le réveil des silithides.")
MHH_NOTES["Chef Perdu"] = L("Chef des Perdus, ces draeneï brisés par les marais : sa tribu erre depuis la chute de Draenor.")
MHH_NOTES["Cuisinier perdu"] = L("Les Perdus sont des draeneï brisés par les magies des marais. Lui, c'est la cuisine qu'il a cassée.")
MHH_NOTES["Bête des égouts"] = L("Un crocilisque qui a grandi dans les canaux de Hurlevent. Les enfants jurent qu'il existe. Il existe.")
MHH_NOTES["Zaricotl"] = L("Un kodo mort-vivant qui n'aurait jamais dû se relever. Les caravanes détournent leur route depuis.")
MHH_NOTES["Uhk'loc"] = L("Le gorille blanc d'Un'Goro : chasseurs et badauds se le disputent depuis des années.")
MHH_NOTES["Roi Mosh"] = L("Le plus grand des diablesaures. Sa trace seule fait trembler le cratère entier.")
MHH_NOTES["Matriarche Zavas"] = L("La gardienne des couvées du cratère : approchez-vous, et la ruche entière se lève.")
MHH_NOTES["Timber"] = L("Le loup blanc du Dun Morogh, premier grand amour de générations de jeunes chasseurs nains.")
MHH_NOTES["Bjarn"] = L("L'ours des pentes enneigées : les nains jurent qu'il survit aux avalanches. En dessous.")
MHH_NOTES["Dishu"] = L("Une féline rapide et convoitée des chasseurs : sa cadence d'attaque fait des étincelles.")
MHH_NOTES["Snort le Moqueur"] = L("Une hyène qui ricane dans la poussière des Tarides — on l'entend avant de la voir.")
MHH_NOTES["Azzere la Lame-des-cieux"] = L("Un serpent des vents qui plane au-dessus des Tarides : sa lame est un croc.")
MHH_NOTES["Veuve-sangsue"] = L("Sa toile, près des marais des Paluns, boit plus vite qu'elle ne mord.")
MHH_NOTES["Edan le Hurleur"] = L("Une harpie du Dun Morogh : son hurlement glace le sang des nains au petit matin.")
MHH_NOTES["Intendant du Bouclier balafré"] = L("Il porte sur lui le sceau de l'Ascension : la clé des profondeurs du Pic Blackrock.")
MHH_NOTES["Fenros"] = L("Un worg des Bois de la Pénombre — les bûcherons jurent qu'il a des yeux d'homme.")
MHH_NOTES["Mère Croc"] = L("La mère des araignées du bois : pondre, mordre, recommencer.")
MHH_NOTES["Le Jonc"] = L("Une tortue géante endormie au large : les pêcheurs la prennent pour un îlot, à leurs dépens.")
MHH_NOTES["Narillasanz"] = L("Un dragonnet bleu égaré bien au sud : plus coriace que sa taille ne le laisse croire.")
MHH_NOTES["Azurous"] = L("Un drake bleu qui veille sur les neiges d'Hiverpré. Le ciel, ici, a un propriétaire.")
MHH_NOTES["Matriarche ravasaure"] = L("La mère des ravasaures : les traqueurs du cratère connaissent sa trace par cœur.")
MHH_NOTES["Dame Hederine"] = L("Démone de la gorge Sombre-Brume : elle collectionne les âmes des curieux.")
MHH_NOTES["Prince Nazjak"] = L("Prince des Fanécorce : la couronne de bois ne lui sied pas plus que la paix.")
MHH_NOTES["Molok l'Anéantisseur"] = L("Un ogre des Hautes-terres qui écrase d'abord — et ne pose jamais de questions après.")
MHH_NOTES["Le Béhémoth"] = L("Une montagne de muscles dans la poussière ardente : son ombre suffit à refroidir les téméraires.")
MHH_NOTES["Omgorn l'Égaré"] = L("Un ogre qui a perdu son navire, son équipage et son sens de l'orientation. Pas son appétit.")
MHH_NOTES["Kregg Keelhaul"] = L("Capitaine pirate échoué sur la côte : il n'a sauvé que son chapeau et sa rancune.")
MHH_NOTES["Veuve de Sombrebrume"] = L("Maîtresse de la grotte Sombrebrume : sa toile couvre toute l'entrée.")
MHH_NOTES["Chef de meute Frayeloup"] = L("La meute d'Orneval lui obéit au doigt et au croc.")
MHH_NOTES["Hurlemort"] = L("Son hurlement couvre le fracas des cascades de Gangrebois. On l'entend avant de le voir.")
MHH_NOTES["Alshirr Souffléau"] = L("Un satyre du Gangrebois, corrompu au souffle de soufre. Sa seule présence flétrit la forêt qu'il traverse.")
MHH_NOTES["Ancien vengeur"] = L("Un Ancien réveillé en colère — les elfes des Serres essaient de l'apaiser depuis des siècles.")

-- Descriptions du naturaliste pour TOUT le gibier : les bêtes sans note
-- manuelle ci-dessus reçoivent un texte dérivé de leur famille (mots-clés
-- du nom, mêmes familles que les sensibilités) et de leur zone de chasse.
-- Le choix est DÉTERMINISTE (somme des octets du nom) : un monstre garde
-- toujours la même description, même après un relog.
local MHH_NOTES_GEN = {
    { mots = { "araign", "veuve", "toile", "tisse", "naraxis", "chat", "aiguille" },
      txt = {
        L("Elle tisse plus vite qu'on ne coupe. Reculez d'un pas, elle a déjà bougé d'une toise."),
        L("Huit yeux dans la pénombre : elle vous voit bien avant que vous voyiez la sienne."),
        L("Sa toile s'étend de branche en branche, et ce qui s'y accroche y reste."),
      } },
    { mots = { "loup", "worg", "moloch", "hurleur", "claque-croc" },
      txt = {
        L("La meute l'évite : là où il passe, les autres loups se taisent."),
        L("Il chasse en tournant, jamais en ligne droite. Les pièges droits ne le prennent pas."),
        L("On l'entend hurler aux orages. Les bergers comptent les nuits sans lui."),
      } },
    { mots = { "lion", "panthère", "panthere", "tigre", "tigr", "félin", "felins", "rake", "humar" },
      txt = {
        L("Un prédateur patient : il ne court pas après le gibier, il l'attend au bon endroit."),
        L("Sa crinière porte les marques de vieux combats. Il n'a jamais fui le premier."),
        L("Les pistes se ressemblent toutes — sauf les siennes : griffes profondes, pas de bruit."),
      } },
    { mots = { "raptor" },
      txt = {
        L("Plus vite qu'un éclair sur pattes, et deux fois plus malin qu'il n'y paraît."),
        L("Il frappe, recule, revient. Tenez bon à la première passe, la deuxième est pire."),
        L("Ses plumes trahissent son humeur : quand elles se hérissent, c'est déjà trop tard."),
      } },
    { mots = { "sanglier", "broch", "snort", "groin", "razormaw", "tranchegueule" },
      txt = {
        L("Une masse de groins et de défenses qui charge tout ce qui brille."),
        L("Il laboure les sentiers à la recherche de racines — et de chasseurs distraits."),
        L("Son cuir épais encaisse les flèches. Visez sous l'épaule."),
      } },
    { mots = { "croco", "crocilis" },
      txt = {
        L("Deux yeux au ras de l'eau, et puis plus rien. Jusqu'au dernier moment."),
        L("Sa mâchoire claque comme une porte de prison : ce qui entre ne ressort pas."),
        L("Il attend au bord du gué, immobile pendant des heures. La patience est son arme."),
      } },
    { mots = { "scorp" },
      txt = {
        L("Sous les rochers chauds, sa queue compte les secondes avant de frapper."),
        L("Sa carapace dévie le fer. C'est la queue qui décide du combat."),
        L("Le sable retient sa chaleur, et lui, le souvenir de chaque piqûre."),
      } },
    { mots = { "silith", "insect", "krellack", "grubthor", "moissonneur" },
      txt = {
        L("Une carapace qui craque sous les bottes : le sol entier bouge quand il s'éveille."),
        L("Les mares s'évaporent sur son passage. Il ne laisse que des mandibules derrière lui."),
        L("Il travaille la terre en creusant, et défend son chantier avec cent bras."),
      } },
    { mots = { "dragon", "drak", "wyrm", "stégo", "stego", "grondeterre", "azur" },
      txt = {
        L("Écailles anciennes, yeux plus anciens encore. Il régnait ici bien avant les routes."),
        L("Sa seule présence fait taire les oiseaux. On le sent avant de le voir."),
        L("Son souffre fait tourner les lames de moulins à trois lieues."),
      } },
    { mots = { "murloc", "gluggle", "squiddic" },
      txt = {
        L("Il chante faux au bord de l'eau, mais ses dents, elles, chantent juste."),
        L("Le golgolgol de sa tribu précède chaque embuscade. Écoutez avant d'avancer."),
        L("Il ne quitte jamais la rive — sauf pour vous surprendre."),
      } },
    { mots = { "fantôme", "esprit", "âme", "ame", "spectre", "putride", "carcasse", "mort", "ombre", "moiss" },
      txt = {
        L("Ce qui le traverse ne le blesse pas ; ce qu'il touche, lui, s'en souvient."),
        L("Il rôde là où il est tombé. Le soir, les torches s'écartent de son chemin."),
        L("Une forme qui froisse l'air du soir. Le fer passe au travers, la peur non."),
      } },
    { mots = { "gangre", "démon", "demon", "imp", "satyre", "scornn", "faux-sombre", "souffle" },
      txt = {
        L("L'air autour de lui a un goût de cendre. Le sol garde ses empreintes brûlées."),
        L("Il n'a peur ni du fer, ni du feu — mais l'eau bénite l'agace prodigieusement."),
        L("Il murmure des promesses qu'il tient toujours, d'une manière ou d'une autre."),
      } },
    { mots = { "golem", "méca", "meca", "faux", "reaper", "verifonix", "défect", "defect" },
      txt = {
        L("Une mécanique qui a pris goût à la chasse. Huilez vos armes, pas lui."),
        L("Il tourne sans relâche, sans faim ni peur — c'est bien ça le problème."),
        L("Ses engrenages grincent avant l'attaque : c'est le seul avertissement."),
      } },
    { mots = { "feu", "flamme", "brûl", "brul", "immol", "volcan", "braise", "étincelle", "etincelle", "flamboy" },
      txt = {
        L("La terre fume sur son passage. Les flaques de la veille sont des cicatrices."),
        L("Il dort dans les cendres chaudes et se réveille en flammèches."),
        L("Le froid ne l'atteint pas, l'eau l'énerve. Prévoyez des seaux."),
      } },
    { mots = { "pierre", "roche", "rocher", "terre", "géom", "geom", "rhumbl" },
      txt = {
        L("Le sol tremble une seconde avant qu'il ne se lève. Comptez cette seconde."),
        L("Une montagne qui marche, lente comme l'hiver, et tout aussi difficile à arrêter."),
        L("Les mousses colonisent ses épaules : il est ici depuis très longtemps."),
      } },
    { mots = { "mage", "magi", "scribe", "copiste", "sorci", "dalaran", "invoc", "conjur", "enchante", "astral" },
      txt = {
        L("Il passe plus de temps dans les grimoires que dans la poussière des pistes."),
        L("Ses sorts partent vite ; ses bottes de citadin, elles, partent plus vite encore."),
        L("Le sol garde la trace de ses cercles d'invocation. N'y entrez jamais."),
      } },
    { mots = { "capitaine", "commandant", "seigneur", "sergent", "sœur", "soeur", "frère", "frere", "contremaître", "contremaitre", "exécut", "execut", "bourreau", "chef", "massacreur", "général", "general", "garde" },
      txt = {
        L("Il commande, il ne négocie pas. Son régiment le craint plus que l'ennemi."),
        L("Une carrure d'armoire et une voix qui porte jusqu'au prochain camp."),
        L("Il ne reculera pas : c'est écrit quelque part sur son uniforme, paraît-il."),
      } },
    { mots = { "serpent", "vipère", "vipere", "boa", "hydre", "anaconda", "slither" },
      txt = {
        L("Patient comme la vase : on le voit trop tard, jamais deux fois."),
        L("Sa langue goûte l'air avant vos pas. Il sait déjà où vous passerez."),
        L("Il ne poursuit personne. Il attend que le monde vienne à lui."),
      } },
    { mots = { "chauve", "harpi", "hippo", "wyvern", "chimère", "chimere", "aile", "vol" },
      txt = {
        L("Son ombre passe sur vous avant son cri. Regardez le ciel, pas le sol."),
        L("Elle fond du haut des falaises, plus vite que l'arc ne se bande."),
        L("Le vent des collines porte ses cris. Le silence, lui, annonce la charge."),
      } },
    { mots = { "limace", "boue", "sludge", "poisson", "rotheap", "marais", "nageur" },
      txt = {
        L("Une masse de vase et de viscères qui glisse là où l'eau s'arrête."),
        L("Il pue à trois toises et mord à une. Tenez la distance, gardez le sol ferme."),
        L("Ce qui le compose ne devrait pas marcher — et pourtant, ça traque."),
      } },
    { mots = { "gnoll", "hyène", "hyene" },
      txt = {
        L("Un rire de charognard dans la nuit, puis des crocs. Dans cet ordre."),
        L("Il creuse moins de pièges que de fosses à cadavres. Choisissez votre camp."),
        L("Sa meute le suit pour les restes. Le reste, c'est vous."),
      } },
    { mots = { "kobold", "trogg", "mineur", "terassier", "terrassier", "fossoyeur" },
      txt = {
        L("Vous ne lui prendrez pas sa bougie — ni sa galerie, si vous êtes sage."),
        L("Il connaît chaque tunnel de la région. La sortie, c'est autre chose."),
        L("Il creuse, il pille, il s'enfouit. La lumière du jour l'offusque."),
      } },
    { mots = { "naga", "sirène", "sirene", "vespia", "vespira", "azshara" },
      txt = {
        L("Une couronne d'écailles et de promesses noyées. Ne l'écoutez pas chanter."),
        L("Elle règne sur un royaume de coquillages vides — et voudrait le vôtre."),
        L("Elle vous traite en égal... jusqu'à ce que l'eau vous couvre la bouche."),
      } },
    { mots = { "anguille", "dilenaa", "serpent", "vipère", "vipere", "brochet", "poisson", "requin" },
      txt = {
        L("Un éclair d'écailles sous l'eau trouble : on ne le voit qu'au moment de mordre."),
        L("Le lac garde ses secrets — et celui-là garde le lac. Méfiez-vous des remous."),
        L("Souple comme une cravache et deux fois moins aimable. Ni l'acide ni les hameçons ne l'ont eu."),
      } },
    { mots = { "ours", "grizzli" },
      txt = {
        L("Une masse de muscles et de mauvaise humeur, réveillée trop tôt de son sommeil."),
        L("Il défend son territoire à pattes plates et griffes sorties. Écartez-vous."),
        L("Les baies des fourrés portent ses marques. Il n'est jamais loin de son garde-manger."),
      } },
}
-- Famille par défaut : bête non classée, texte de chasse générique
local MHH_NOTES_GEN_DEFAUT = {
    L("Un gibier d'expérience : il a survécu à tous les chasseurs de la région. Pas à vous."),
    L("Les vieux du coin baissent la voix quand on le nomme. C'est bon signe."),
    L("Sa réputation court les pistes plus vite que lui. Ce carnet n'admettra que des preuves."),
}
local MHH_NOTES_ZONE = {
    L(" Pistes fraîches côté "),
    L(" Aperçu récemment vers "),
    L(" Les voyageurs le croisent autour de "),
}
function MHH_NoteGeneree(nom)
    if type(nom) ~= "string" or nom == "" then return nil end
    local n = string.lower(nom)
    local phrases = nil
    for _, regle in ipairs(MHH_NOTES_GEN) do
        for _, mot in ipairs(regle.mots) do
            if string.find(n, mot, 1, true) then phrases = regle.txt break end
        end
        if phrases then break end
    end
    if not phrases then phrases = MHH_NOTES_GEN_DEFAUT end
    local h = 0
    for i = 1, #nom do h = h + string.byte(nom, i) * i end
    local phrase = phrases[(h % #phrases) + 1]
    local zone = MHH_CATALOGUE and MHH_CATALOGUE[nom]
    if zone and zone ~= "?" and zone ~= "" then
        local ztxt = MHH_NOTES_ZONE[(h % #MHH_NOTES_ZONE) + 1]
        phrase = phrase .. ztxt .. zone .. "."
    end
    return phrase
end


-- Sensibilités par monstre (icônes de sorts du jeu, façon panneau faiblesses MH)
-- Chemins d'icônes Classic ; à vérifier en jeu, on ajustera si l'une décoche
MHH_ECOLE = {
    feu     = { icone = "Interface\\Icons\\Spell_Fire_FireBolt",     nom = "Feu" },
    givre   = { icone = "Interface\\Icons\\Spell_Frost_FrostBolt",    nom = "Givre" },
    nature  = { icone = "Interface\\Icons\\Spell_Nature_Thorns",      nom = "Nature" },
    ombre   = { icone = "Interface\\Icons\\Spell_Shadow_ShadowBolt",  nom = "Ombre" },
    sacre   = { icone = "Interface\\Icons\\Spell_Holy_HolyBolt",      nom = L("Sacré") },
    arcane  = { icone = "Interface\\Icons\\Spell_Arcane_StarFire",   nom = "Arcane" },
}
-- Niveau de sensibilité façon MH (les étoiles du monstre) : 1 à 3 par
-- école. Les polices WoW ne rendent pas les glyphes étoiles → chiffres romains.
MHH_FAIBLESSES = {
    ["Mor'Ladim"]          = { { "sacre", 2 } },  -- mort-vivant
    ["Sans-visage"]        = { { "ombre", 2 } },  -- entité corrompue
    ["Naraxis"]            = { { "feu", 2 } },    -- créature de la forêt, toiles sèches
    ["Rotheap"]            = { { "feu", 3 }, { "givre", 1 } }, -- masse d'eau stagnante
    -- Iconiques : sensibilités documentées à la main
    ["Le Rateau"]          = { { "givre", 2 }, { "arcane", 1 } }, -- frappe si vite : le froid le ralentit
    ["Hurlement fantôme"]  = { { "sacre", 2 }, { "givre", 1 } }, -- esprit : le sacré le blesse
    ["Lupos"]              = { { "sacre", 1 }, { "givre", 2 } }, -- mord avec l'ombre
    ["Foe Reaper 4000"]    = { { "feu", 2 }, { "arcane", 1 } },  -- machine : chauffe et embue
    ["Dame Vespira"]       = { { "ombre", 2 }, { "givre", 1 } }, -- nagà lanceuse de sort
    ["Gesharahan"]         = { { "feu", 2 }, { "givre", 1 } },    -- croc des marées : sèche au soleil
    ["Boahn"]              = { { "givre", 2 }, { "feu", 1 } },     -- serpent à sang froid
    ["Squiddic"]           = { { "feu", 2 }, { "givre", 1 } },   -- amphibie : craint le soleil
    ["Rohh le Silencieux"] = { { "feu", 1 }, { "arcane", 2 } },  -- bête rusée, esprit simple
    ["Vieux Vicejaw"]      = { { "feu", 2 }, { "givre", 1 } },   -- vieille écaille desséchée
    ["Seigneur Condar"]    = { { "nature", 2 }, { "feu", 1 } },  -- volatile : plumes et vent
    ["Veuve-sangsue"]      = { { "feu", 2 }, { "ombre", 1 } },   -- toiles sèches
    ["Snarlmane"]         = { { "nature", 1 }, { "arcane", 2 } }, -- bête des montagnes
}

-- Sensibilités pour TOUT le gibier : les bêtes non documentées à la main
-- dans FAIBLESSES reçoivent une lecture de chasseur dérivée de leur nom
-- (école plausible façon MH). Modifiable/beaucoup affinable à la main.
MHH_REGLES_SENSI = {
    { mots = { "golem", "7:xt", "rageur défectueux", "mastr", "verifonix", "shleipnarr", "rekk", "fourbasse", "scald", "smoldar" },
      e = { { "arcane", 2 }, { "feu", 1 } } },                        -- mécanique/élémentaire de foudre
    { mots = { "fantôme", "esprit", "âme", "spectre", "carcasse", "putride", "pourriss", "mort", "ombre", "malda", "felstrom", "murmure", "visage", "néru" },
      e = { { "sacre", 2 }, { "feu", 1 } } },                         -- mort-vivant
    { mots = { "immol", "volcan", "feu", "brûl", "brul", "flamme", "braise", "éti", "fusée", "étincelle", "thauris", "gorgon", "gronn" },
      e = { { "givre", 2 }, { "nature", 1 } } },                      -- élémentaire de feu
    { mots = { "rocher", "pierre", "terres ingrates", "rumbler", "géosei", "contrem", "magosh", "croco", "dard", "silith", "krellack", "setis", "zora", "grubthor", "lapress", "kaskk" },
      e = { { "nature", 2 }, { "arcane", 1 } } },                     -- élémentaire de terre / insecte carapacé
    { mots = { "veuve", "araign", "toile", "naraxis", "tisse", "krith", "creepthess", "sri", "threk" },
      e = { { "feu", 2 }, { "ombre", 1 } } },                         -- arachnide, toiles sèches
    { mots = { "gangrène", "gangre", "démon", "brûlegangrène", "scornn", "ambassadeur", "malathrom", "dreadscorn", "spiteflayer", "maldazzar", "faux-sombre" },
      e = { { "sacre", 2 }, { "ombre", 1 } } },                      -- démon / corrompu
    { mots = { "écaille", "ecaille", "boue", "limace", "marécage", "marais", "sludg", "gluggle", "poisson", "pêche", "slither", "hydro", "nageur", "courant", "rotheap" },
      e = { { "feu", 2 }, { "givre", 1 } } },                         -- amphibes, dessèchent au soleil
    { mots = { "mors", "croc", "crocs", "griffe", "hurleur", "loup", "lion", "ours", "raptor", "sabre", "chasseur", "traqueur", "prédateur" },
      e = { { "nature", 1 }, { "arcane", 2 } } },                     -- bête puissante, esprit simple
    { mots = { "magistère", "scribe", "enchant", "magi", "sorci", "azshara", "dalaran", "hecaton", "thalass", "invocateur", "conjur", "astral" },
      e = { { "ombre", 2 }, { "sacre", 1 } } },                       -- lanceur de sorts
    { mots = { "écarlate", "capitaine", "seigneur de guerre", "général", "commandant", "sergent", "boss", "chef", "bricoleur", "forgeron", "contraître", "ingénieur", "sœur", "frère", "exécut", "bourreau", "juge", "interrogateur", "haut clerc", "abbendis" },
      e = { { "ombre", 1 }, { "nature", 2 } } },                      -- humanoïde organisé
}
local function SensibilitesAuto(nom)
    if type(nom) ~= "string" then return nil end
    local n = string.lower(nom)
    for _, regle in ipairs(MHH_REGLES_SENSI) do
        for _, mot in ipairs(regle.mots) do
            if string.find(n, mot, 1, true) then return regle.e end
        end
    end
    -- Faune sauvage non classée : sensible à la Nature, sans plus
    return { { "nature", 1 } }
end

-- Vignettes de gibier : icône propre à chaque monstre dans la grille et la
-- fiche. 1) table manuelle pour les célébrités ; 2) règles par mots-clés sur
-- le nom ; 3) point d'interrogation sinon (mystère : ciblez-le en jeu).
MHH_VIGNETTES = {
    ["Humar le Seigneur hautain"] = "Ability_Hunter_Pet_Cat",
    ["Sarkoth"]                  = "Ability_Hunter_Pet_Scorpid",
    ["Takk le Bondisseur"]        = "Ability_Hunter_Pet_Raptor",
    ["Mazzranache"]              = "Ability_Hunter_Pet_Tallstrider",
    ["Naraxis"]                  = "Ability_Hunter_Pet_Spider",
    ["Rotheap"]                  = "Ability_Hunter_Pet_Crab",
    ["Mor'Ladim"]                = "Spell_Shadow_RaiseDead",
    ["Bjarn"]                    = "Ability_Hunter_Pet_Bear",
    ["Timber"]                   = "Ability_Hunter_Pet_Wolf",
    ["Dishu"]                    = "Ability_Hunter_Pet_Cat",
    ["Snort le Moqueur"]         = "Ability_Hunter_Pet_Hyena",
    ["Azzere la Lame-des-cieux"] = "Ability_Hunter_Pet_WindSerpent",
    ["Veuve-sangsue"]            = "Ability_Hunter_Pet_Spider",
    ["Edan le Hurleur"]          = "Ability_Hunter_Pet_Owl",
    ["Grizzle Patte-des-neiges"] = "Ability_Hunter_Pet_Bear",
    ["Ursol'lok"]                = "Ability_Hunter_Pet_Bear",
    ["Araga"]                    = "Ability_Hunter_Pet_Wolf",
    ["Rak'shiri"]                = "Ability_Hunter_Pet_Cat",
    ["Sian-Rotam"]               = "Ability_Hunter_Pet_Cat",
    ["Gruff"]                    = "Ability_Hunter_Pet_Gorilla",
    ["Zaricotl"]                 = "Ability_Hunter_Pet_Owl",
    ["Dame Vespira"]             = "Ability_Hunter_Pet_Owl",
    ["Dame Vespia"]              = "Ability_Hunter_Pet_Owl",
    ["Foe Reaper 4000"]          = "Spell_Arcane_StarFire",
    ["7:XT"]                     = "Spell_Arcane_StarFire",
}
MHH_REGLES_VIGNETTES = {
    { mots = { "araign", "veuve", "tisse" },                 icone = "Ability_Hunter_Pet_Spider" },
    { mots = { "raptor", "sauro", "mante-épine", "uhk", "roi mosh" }, icone = "Ability_Hunter_Pet_Raptor" },
    { mots = { "ours", "urson", "arctikus" },               icone = "Ability_Hunter_Pet_Bear" },
    { mots = { "lion", "fauve", "lynx", "panthère", "tigre" }, icone = "Ability_Hunter_Pet_Cat" },
    { mots = { "sanglier", "goret", "porc" },               icone = "Ability_Hunter_Pet_Boar" },
    { mots = { "scorp", "silithide", "silith", "setis", "krellack", "zora" }, icone = "Ability_Hunter_Pet_Scorpid" },
    { mots = { "serpent", "vipère", "boahn", "wyrm" },      icone = "Ability_Hunter_Pet_WindSerpent" },
    { mots = { "tortue", "carapace" },                      icone = "Ability_Hunter_Pet_Turtle" },
    { mots = { "crabe", "crusty", "pince", "croquesable" }, icone = "Ability_Hunter_Pet_Crab" },
    { mots = { "hyène", "chacal" },                          icone = "Ability_Hunter_Pet_Hyena" },
    { mots = { "singe", "makr", "gorille" },                icone = "Ability_Hunter_Pet_Gorilla" },
    { mots = { "échassier" },                                icone = "Ability_Hunter_Pet_Tallstrider" },
    { mots = { "hibou", "chouette", "plume", "serres", "aile", "hurle", "vol", "planeur", "planeur" }, icone = "Ability_Hunter_Pet_Owl" },
    { mots = { "loup", "worg" },                             icone = "Ability_Hunter_Pet_Wolf" },
    { mots = { "fantôme", "esprit", "âme", "spectre", "carcasse", "putride", "pourriss", "mort", "squelette", "cadavre" }, icone = "Spell_Shadow_RaiseDead" },
    { mots = { "gangr", "démon", "satyre", "seigneur de l'effroi" }, icone = "Spell_Shadow_SummonFelhunter" },
    { mots = { "golem", "7:xt", "mécanique", "ravageur défectueux", "siège" }, icone = "Spell_Arcane_StarFire" },
    { mots = { "immol", "volcan", "brûl", "brul", "braise", "feu" }, icone = "Spell_Fire_FireBolt" },
    { mots = { "crocolisque", "croco" },                    icone = "Ability_Hunter_Pet_Crocolisk" },
    { mots = { "capitaine", "plate-défense", "plate-defense", "soldat", "sénéchal", "chevalier" }, icone = "Ability_Warrior_OffensiveStance" },
    -- Dragons féeriques (Nal'taszar…) : le feu féérique, plutôt que
    -- l'icône ronde « ? » du repli
    { mots = { "nal'taszar", "féerie", "feerie", "sprite", "darter" }, icone = "Spell_Nature_FaerieFire" },
}
local function IconeGibier(nom)
    if type(nom) ~= "string" then return nil end
    if MHH_VIGNETTES[nom] then return MHH_VIGNETTES[nom] end
    local n = string.lower(nom)
    for _, regle in ipairs(MHH_REGLES_VIGNETTES) do
        for _, mot in ipairs(regle.mots) do
            if string.find(n, mot, 1, true) then return regle.icone end
        end
    end
    return nil
end

-- Cartes façon Monster Hunter : dessin dédié par monstre dans le carnet.
-- VIGNETTE « MYSTÈRE » : inconnu.tga dans ce même dossier = illustration
-- des bêtes jamais rencontrées (ton interrogationmark3.jpg converti en
-- TGA 128x128, 32 bits). Elle s'affiche légèrement grisée ; sans le
-- fichier, repli gris sur l'icône de famille.
-- Dépose tes TGA dans MHHunt\Textures\Vignettes\ puis décommente la ligne
-- du monstre ci-dessous (une ligne = une carte). TGA carré, taille
-- puissance de 2 (64x64 ou 128x128), 32 bits non compressé — comme tes
-- autres textures. Une carte décommentée sans fichier = vignette vide :
-- décommente au fur et à mesure de tes dessins.
MHH_VIGNETTES_CUSTOM = {
    -- ["Humar le Seigneur hautain"] = "humar",
    -- ["Sarkoth"]                  = "sarkoth",
    -- ["Naraxis"]                  = "naraxis",
    -- ["Bjarn"]                    = "bjarn",
    -- ["Takk le Bondisseur"]        = "takk",
}
local function TextureVignette(nom)
    if type(nom) ~= "string" then return nil end
    local f = MHH_VIGNETTES_CUSTOM[nom]
    if f then return "Interface\\AddOns\\MHHunt\\Textures\\Vignettes\\" .. f .. ".tga" end
    return nil
end

-- ============================================
-- 3bis. DONNÉES EXTERNES (MHHuntData.lua)
-- ============================================
-- Fusion du fichier de données séparé (à charger AVANT MHHunt.lua dans
-- le .toc) : NPC id + coordonnées de spawn + rares supplémentaires.
-- Fichier absent ou chargé après = aucune erreur, l'addon marche sans.
-- BILINGUE : le data porte nom/nomEn et zone/zoneEn. Sur un client EN
-- (GetLocale), le carnet indexe AUSSI la graphie anglaise (nomEn) et
-- utilise zoneEn — GetZoneText() renvoie la langue du client, les
-- comparaisons de zone restent donc cohérentes. Zones CUSTOM du serveur
-- (Les Tarides…) : leur nom EN réel se vérifiera à la sortie (/hunt export).
MHH_COORDS = {}
MHH_RARES_PAR_ID = {}
-- Nom AFFICHABLE par clé du catalogue : le catalogue indexe chaque bête
-- sous TOUTES ses graphies (nom FR, nomEn, alias) pour matcher les noms
-- réels vus en jeu ; seule la graphie « principale » de ce client doit
-- apparaître dans les listes et les tirages — sinon doublon FR+EN.
-- Versionning : v1.0 = version de SORTIE. En attendant, on est en
-- pré-version 0.x — incrémenter la décimale à chaque jalon (icônes
-- de gibier, ménagerie, etc.) jusqu'à la sortie.
local MHH_VERSION = "0.60"

MHH_NOM_AFFICHAGE = {}
-- Traduction d'affichage EN -> FR (client FR uniquement) : quand le
-- serveur appelle une bête par sa graphie ANGLAISE, l'affichage la
-- remplace par le nom français du data file. Le matching, le comptage
-- et la détection restent sous la graphie en jeu.
MHH_AFFICHAGE_FR = {}
-- Niveau et statut élite par bête (data file) : affichés sous le portrait
MHH_NIVEAUX = {}
MHH_ELITES = {}
-- Rares non répertoriées par zone (graphies anglaises cachées) :
-- l'en-tête de zone du gibier affiche l'estimation
MHH_RARES_ESTIMES = {}
MHH_CLIENT_EN = GetLocale and (GetLocale() or ""):sub(1, 2) == "en" or false
local function ZonePourClient(e)
    if MHH_CLIENT_EN then return e.zoneEn or e.zone end
    return e.zone
end
if type(MHHuntData) == "table" then
    for _, e in ipairs(MHHuntData) do
        if type(e) == "table" and e.zone then
            -- Index par NPC id : sert à l'identification automatique
            if e.id then
                MHH_RARES_PAR_ID[e.id] = { zone = ZonePourClient(e), x = e.x, y = e.y, nom = e.nom, nomEn = e.nomEn, niveau = e.niveau, elite = e.elite }
            end
            -- Rares NON RÉPERTORIÉES : graphie anglaise jamais traduite —
            -- pas de fiche (au choix du joueur : pas de noms anglais dans
            -- le carnet). Le vrai nom appris en jeu (découverte/ID) crée
            -- la sienne. En attendant : estimation dans l'en-tête de zone.
            if e.nom and e.nom == e.nomEn then
                local zc = ZonePourClient(e)
                -- Pas d'estimation si la bête a DÉJÀ sa fiche au catalogue
                -- fait main (Sarkoth, Nal'taszar…) : sinon le ratio X/Y de
                -- l'en-tête de zone la comptait deux fois (fiche + estimée)
                if not MHH_CATALOGUE[e.nom] then
                    MHH_RARES_ESTIMES[zc] = (MHH_RARES_ESTIMES[zc] or 0) + 1
                end
            else
            -- nom principal + alias + nom EN : chaque graphie est une clé
            -- du catalogue (traductions serveur et clients FR/EN)
            local cles = {}
            if e.nom then cles[#cles+1] = e.nom end
            if e.nomEn then cles[#cles+1] = e.nomEn end
            if type(e.alias) == "table" then
                for _, a in ipairs(e.alias) do cles[#cles+1] = a end
            end
            -- Graphie principale selon le client : c'est le seul nom
            -- affiché (listes, contrat du jour, comptages de zone)
            local principal = MHH_CLIENT_EN and (e.nomEn or e.nom) or (e.nom or e.nomEn)
            if not MHH_CLIENT_EN and e.nom and e.nomEn and e.nom ~= e.nomEn then
                MHH_AFFICHAGE_FR[e.nomEn] = e.nom
            end
            for _, cle in ipairs(cles) do
                MHH_CATALOGUE[cle] = ZonePourClient(e)
                MHH_NOM_AFFICHAGE[cle] = principal
                MHH_NIVEAUX[cle] = e.niveau
                MHH_ELITES[cle] = e.elite
                if e.x and e.y then MHH_COORDS[cle] = { e.x, e.y } end
            end
            end
        end
    end
end

-- Une clé du catalogue est-elle une graphie PRINCIPALE pour ce client ?
-- (les alias/nomEn servent au matching, jamais à l'affichage)
function MHH_EstNomAffichable(nom)
    return not MHH_NOM_AFFICHAGE[nom] or MHH_NOM_AFFICHAGE[nom] == nom
end

-- Nom AFFICHÉ : en client FR, une graphie anglaise connue du data file
-- est rendue en français. Ailleurs (client EN, nom inconnu du data),
-- le nom passe tel quel.
function MHH_NomAffiche(nom)
    if type(nom) ~= "string" then return nom end
    if MHH_CLIENT_EN then return nom end
    return MHH_AFFICHAGE_FR[nom] or nom
end

-- Identification automatique par NPC id : le GUID contient l'ID, qui ne
-- dépend pas de la langue du client ni des traductions approximatives du
-- serveur. Dès qu'une bête du data file est ciblée ou survolée, son nom
-- EXACT en jeu est appris et inscrit au carnet — aucun /run manuel.
local function ApprendreParId(unite)
    local guid = UnitGUID(unite)
    if not guid then return end
    local idR = tonumber(guid:match("-(%d+)$"))
    if not idR or not MHH_RARES_PAR_ID[idR] then return end
    local nom = NomOrdinaire(UnitName(unite))
    -- v0.30 : nom secret (poison client) → impossible d'inscrire au carnet
    if not nom or nom == "" then return end
    local e = MHH_RARES_PAR_ID[idR]
    -- Le serveur appelle la bête autrement que le data file (ex. « Rochelance »
    -- vs « Lance-de-roche ») : le nom VU EN JEU devient la graphie principale
    -- (l'ancien reste une clé de matching, mais ne s'affiche plus). Sans ça,
    -- la bête restait invisible au carnet : l'alias n'est jamais « affichable ».
    if nom ~= "" and MHH_NOM_AFFICHAGE[nom] and MHH_NOM_AFFICHAGE[nom] ~= nom then
        local ancienPrincipal = MHH_NOM_AFFICHAGE[nom]
        MHH_NOM_AFFICHAGE[nom] = nom
        MHH_NOM_AFFICHAGE[ancienPrincipal] = nom -- l'ancien pointe vers le nouveau
    end
    if nom == "" or MHH_CATALOGUE[nom] or DB.decouverts[nom] then return end
    MHH_CATALOGUE[nom] = e.zone
    MHH_NOM_AFFICHAGE[nom] = nom -- nom réel appris : graphie principale
    MHH_NIVEAUX[nom] = e.niveau
    MHH_ELITES[nom] = e.elite
    if e.x and e.y then MHH_COORDS[nom] = { e.x, e.y } end
    DB.decouverts[nom] = { kills = 0, vu = true, zone = e.zone, decouvert = time(), id = idR, nouveau = true }
    DB.rencontres[nom] = DB.rencontres[nom] or time()
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Identifié par l'ID ") .. idR .. " : |cffffff00"
        .. nom .. "|r (" .. (e.nomEn or e.nom or "?") .. L(") — inscrit au carnet."))
    DebloquerSucces("decouverte")
    MHH_VerifierRencontres(nom)
end

-- v0.119 : VÉRIFICATION DES SUCCÈS DE RENCONTRE — appelée à chaque
-- première rencontre d'un rare. Compte les rares croisés (10 / 25) et
-- vérifie si la RÉGION du rare croisé est complète (tous ses rares du
-- data croisés, par graphie principale — les alias ne comptent qu'une fois).
MHH_VerifierRencontres = function(nom)
    if not (DB and DB.rencontres) then return end
    local n = 0
    for _ in pairs(DB.rencontres) do n = n + 1 end
    if n >= 10 then DebloquerSucces("rencontres10") end
    if n >= 25 then DebloquerSucces("rencontres25") end
    if type(MHHuntData) ~= "table" then return end
    local zone = (nom and MHH_CATALOGUE and MHH_CATALOGUE[nom]) or GetZoneText()
    if not zone then return end
    local total, vus = 0, 0
    for _, e in ipairs(MHHuntData) do
        if type(e) == "table" and e.zone and ZonePourClient(e) == zone then
            local principal = e.nom or e.nomEn
            if principal then
                principal = MHH_NOM_AFFICHAGE[principal] or principal
                total = total + 1
                if DB.rencontres[principal] or DB.decouverts[principal] then
                    vus = vus + 1
                end
            end
        end
    end
    -- garde total >= 5 : une région triviale de 2-3 rares ne vaut pas succès
    if total >= 5 and vus >= total then DebloquerSucces("regioncomplete") end
end

-- ============================================
-- 3ter. MÉNAGERIE : spécimens capturables (pixel art)
-- ============================================
-- La capture (v0.64, simplifiée pour la sortie) : achever un spécimen
-- pendant une chasse active suffit. Seuls ces spécimens rejoignent
-- l'enclos (onglet Ménagerie).
-- Dessin = grille 16x16, un caractère par pixel ('.' = transparent),
-- palette par monstre. Rendu : textures SetColorTexture, aucune image.
-- PIÈGES DE CAPTURE (auras de CONTRÔLE) : le monstre achevé pendant qu'il
-- est tenu (racine, stun, incapacite, metamorphose, peur, ban) est capturé
-- pour la ménagerie. Ouvert à toutes les classes qui contrôlent.
-- GLOBALE préfixée (limite 200 locales du chunk).
MHH_PIEGES_CAPTURE = {
    -- Racines / immobilisations
    [3355] = true,                                   -- Piège de glace (chasseur)
    [339] = true, [1062] = true, [5195] = true,       -- Entrave de la nature (druide)
    [5196] = true, [9852] = true, [9853] = true,
    [122] = true, [865] = true, [6131] = true, [10230] = true, -- Nova de givre (mage)
    -- Stuns
    [1833] = true,                                   -- Coup bas (voleur)
    [408] = true, [8643] = true,                      -- Aiguillon vital (voleur)
    [5211] = true, [6798] = true, [8983] = true,       -- Fracasser (druide)
    [9005] = true,                                    -- Traquenard (druide)
    [853] = true, [5588] = true, [5589] = true, [25773] = true, -- Marteau de la justice (paladin)
    [20549] = true,                                   -- Piétinement de guerre (tauren)
    [20253] = true,                                   -- Interception (guerrier)
    [7922] = true,                                    -- Charge (guerrier)
    [12809] = true,                                   -- Coup concussionnaire (guerrier)
    -- Incapacites / metamorphoses
    [1776] = true,                                    -- Coup sournois (voleur)
    [51724] = true, [1423] = true, [1424] = true,      -- Sap (voleur, id Classic + 1.12)
    [2094] = true,                                    -- Aveuglement (voleur)
    [19503] = true,                                   -- Tir de dispersion (chasseur)
    [118] = true, [12824] = true, [12825] = true, [12826] = true, -- Metamorphose (mage)
    [2637] = true, [18657] = true, [18658] = true,     -- Hibernation (druide)
    -- Peur / ban
    [5782] = true, [6213] = true, [6215] = true,       -- Peur (demoniste)
    [5484] = true,                                    -- Hurlement terrifiant (demoniste)
    [6789] = true,                                    -- Mort terrible (demoniste)
    [6358] = true,                                    -- Seduction (succube)
    [710] = true, [18647] = true,                      -- Bannissement (demoniste)
    [5246] = true,                                    -- Cri d'intimidation (guerrier)
    [8122] = true, [8124] = true, [10888] = true,      -- Cri psychique (pretre)
    [9484] = true, [10955] = true, [10909] = true,     -- Entrave des morts (pretre)
}
-- ===== DONNÉES SPECIMENS/ENCLOS : EXTRAITES (v0.68) =====
-- MHH_SPECIMENS, MHH_SPECIMENS_ORDRE, MHH_ENCLOS et les index
-- dérivés (MHH_ENCLOS_DU_SPECIMEN, MHH_ENCLOS_RANG,
-- MHH_ENCLOS_INDEX) vivent dans Specimens.lua, chargé APRÈS ce
-- fichier (voir .toc) — ils n'utilisent que MHH_L.


-- ============================================
-- 4. RANGS DE GUILDE, NOTES, ÉTAT DE CHASSE
-- ============================================
local chasseActive = nil   -- nom du monstre chassé
-- Déclarations anticipées : FinChasseVictoire/FinChasseEchec appellent la
-- musique AVANT sa définition (plus bas dans le fichier) — sans ceci, les
-- locaux y sont invisibles (erreur « attempt to call a nil value »)
local MHH_ArreterMusique
local MHH_JouerMusique
local JouerJingleVictoire -- carillon « quête terminée » (SoundKit 619), section musiques
local FinChasseVictoire -- déclaration anticipée : AnnoncerSuspension (différé) valide une prise manquée
local dernierJingleTemps -- horodatage du dernier carillon (protège le cut SFX différé)
-- Chasse suspendue (cible perdue hors combat, bête enfuie) : on garde tout
-- pour REPRENDRE la chasse là où elle en était si on re-cible la bête
-- rapidement — le chrono n'est PAS remis à zéro.
local chasseSuspendue = nil -- { nom, debutTemps, debutVie, niveau, rare, piegee }
local chasseDebutVie = nil -- vie du chasseur au début de la chasse

-- v0.24 : lecture TEXTUELLE d'une valeur protégée. Le secret de ce
-- client déclare type() = « number » mais EMPISONNE les comparaisons
-- (la dichotomie de NombreOrdinaire rend nil sans erreur visible).
-- S'il laisse passer tostring, on lit la valeur telle quelle et on
-- la parse — c'est la seule arme restante contre un faux nombre.
local function ParseSecret(s)
    -- v0.26 : boîte à outils 4 techniques contre les « secret strings » —
    -- tout est pcall, la bibliothèque string est appelée en FONCTION.
    if s == nil then return nil end
    local okN, n = pcall(tonumber, s)
    if okN and type(n) == "number" and n > 0 then return n end
    local okM, m = pcall(string.match, s, "%-?%d+%.?%d*")
    if okM and type(m) == "string" then
        local okT, v = pcall(tonumber, m)
        if okT and type(v) == "number" and v > 0 then return v end
    end
    local okF, f = pcall(string.format, "%s", s)
    if okF and type(f) == "string" then
        local okFM, fm = pcall(string.match, f, "%-?%d+%.?%d*")
        if okFM and type(fm) == "string" then
            local okT, v = pcall(tonumber, fm)
            if okT and type(v) == "number" and v > 0 then return v end
        end
    end
    local okC, c = pcall(function() return "" .. s end)
    if okC and type(c) == "string" then
        local okCM, cm = pcall(string.match, c, "%-?%d+%.?%d*")
        if okCM and type(cm) == "string" then
            local okT, v = pcall(tonumber, cm)
            if okT and type(v) == "number" and v > 0 then return v end
        end
    end
    return nil
end

-- v0.30 : ce client peut renvoyer un NOM D'UNITÉ en « secret string »
-- (observé au tab-targeting en donjon) : impossible à utiliser comme clé
-- de table — « attempted to index a table that cannot be indexed with
-- secret keys ». Le test pcall ci-dessous le détecte en une indexation
-- jetable ; les comparaisons ==, elles, restent autorisées.
local function NomOrdinaire(nom)
    if type(nom) ~= "string" then return nil end
    local ok = pcall(function() local t = {} t[nom] = true end)
    return ok and nom or nil
end

local function LireSecretTexte(unite, un)
    un = un or "target"
    local ok, s = pcall(function() return tostring(unite and unite(un)) end)
    if not ok then return nil end
    return ParseSecret(s)
end
local chasseVieTouchee = false -- vie passée sous son niveau de départ (suivi UNIT_HEALTH)
local chasseNiveau = nil   -- niveau du monstre chassé
local chasseRayon = nil    -- rayon de hitbox mesuré à l'engagement (repli)
-- Secret numbers de Midnight (UnitBoundingRadius & co.) : les
-- COMPARAISONS sont permises, l'ARITHMÉTIQUE est interdite — un
-- pcall autour d'une multiplication échoue en silence et le gabarit
-- n'est jamais enregistré. NombreOrdinaire() reconvertit une telle
-- valeur en nombre Lua ordinaire par DICHOTOMIE : des comparaisons
-- pures (aucune opération sur la valeur secrète) suffisent.
-- v0.22 : un secret peut être une TABLE (ou userdata) avec
-- métaméthodes __lt/__le — type(x) vaut alors « table », pas
-- « number », et l'ancien garde rejetait des valeurs pourtant
-- COMPARABLES (d'où « src=rien vh=nil » en debug). On accepte
-- désormais tout ce qui se compare. La plage est DYNAMIQUE :
-- un rayon de hitbox tient dans 0–64, mais des points de vie
-- montent aux dizaines de milliers — on double la borne haute
-- jusqu'à encadrer la valeur (jusqu'à ~1e9).
local function NombreOrdinaire(x)
    if x == nil then return nil end
    local ok, r = pcall(function()
        local bas, haut = 0.0, 64.0
        -- v0.23 : 40 doublements (plafond ~7e13) — sur un serveur
        -- custom, les PV d'un mob peuvent pulvériser l'ancien
        -- plafond de ~1e9, et la dichotomie rendait nil sans raison
        -- apparente (brut=number mais vh=nil en debug).
        for _ = 1, 40 do
            if x >= haut then
                bas, haut = haut, haut * 2
            else
                break
            end
        end
        if x >= haut then return nil end -- hors plage (> ~7e13)
        for _ = 1, 24 do
            local milieu = (bas + haut) / 2
            if x >= milieu then bas = milieu else haut = milieu end
        end
        return bas
    end)
    return ok and r or nil
end
local chasseRare = false   -- le monstre chassé est-il rare ?
local chasseDebutTemps = nil -- début du chronomètre
local chassePiegee = false   -- le monstre est-il pris dans un piège ?
local dernierTrigger = {} -- anti-spam bannière (30 s par monstre)
local dernierePrise = {} -- horodatage de la DERNIÈRE validation d'une prise
-- par monstre : empêche de re-chasser le CADAVRE dans la minute qui suit
-- la victoire (double comptage des kills quand UnitIsDead capote).
-- Indicateur « EN CHASSE » près du bouton minimap (défini plus bas, section Minimap)
local MettreAJourIndicateur = function() end

-- Bannière centrale
local banniere = CreateFrame("Frame", nil, UIParent)
banniere:SetSize(480, 90)
banniere:SetPoint("TOP", UIParent, "TOP", 0, -120)
banniere:SetFrameStrata("HIGH")
banniere:Hide()
local banniereFond = banniere:CreateTexture(nil, "BACKGROUND")
banniereFond:SetAllPoints()
banniereFond:SetColorTexture(0.03, 0.02, 0.01, 0.8)
local banniereTexte = banniere:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
banniereTexte:SetPoint("CENTER")

-- Branche le forward déclaré dans la section toasts : le toast succès
-- attend désormais la disparition du bandeau avant de s'afficher
MHH_BanniereVisible = function() return banniere:IsShown() end

-- Journal de diagnostic (/hunt debug) : trace chaque canal de détection
-- de mort — pour savoir QUI valide ou rate la prise quand ça coince.
local function DebugChasse(canal, texte)
    if DB and DB.config and DB.config.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff6aaaff[MH Hunt DBG]|r " .. MHH_VERSION ..
            " " .. canal .. " — " .. tostring(texte))
    end
end

local suspendAnnonce = {} -- [nom] = true si le message de suspension a
-- RÉELLEMENT été affiché (les suspensions sont annoncées en différé :
-- une bête qui meurt sous DoT juste après la perte de cible ne doit
-- pas générer « suspendue… reprise… réussie » en rafale).
-- Annonce de suspension RETARDÉE (3 s) : si la bête meurt entre-temps,
-- si la chasse reprend ou se conclut, le message n'est jamais envoyé.
local function AnnoncerSuspension(nom, libelle)
    if not (C_Timer and C_Timer.After) then
        suspendAnnonce[nom] = true
        DEFAULT_CHAT_FRAME:AddMessage(libelle)
        return
    end
    C_Timer.After(3, function()
        local fausseAlerte = false
        -- Suspension annulée entre-temps ? (prise, échec, reprise, autre chasse)
        if chasseActive == nom then return end
        if not chasseSuspendue or chasseSuspendue.nom ~= nom then return end
        if dernierePrise[nom] and time() - dernierePrise[nom] < 6 then return end
        -- Le chasseur s'est RE-ENGAGÉ (combat) ou a re-ciblé la bête ?
        -- La fuite était une fausse alerte : silence, la chasse suit son cours.
        pcall(function()
            if UnitAffectingCombat("player") then fausseAlerte = true end
            if UnitExists("target") and (UnitName("target") or "") == nom then fausseAlerte = true end
        end)
        if fausseAlerte then return end
        -- DERNIER FILET : la bête est morte sous un des viseurs ? Le scan
        -- de fin de combat l'avait ratée (cadavre apparu/despawné trop
        -- vite) — la prise est RÉELLE : on restaure l'état suspendu et
        -- on la valide, au lieu d'annoncer une fausse fuite.
        local morte = false
        pcall(function()
            for _, u in ipairs({ "target", "mouseover", "focus", "pettarget",
                "party1target", "party2target", "party3target", "party4target" }) do
                if UnitExists(u) and (UnitName(u) or "") == nom
                    and UnitIsDead(u) then morte = true end
            end
        end)
        if morte then
            local etat = chasseSuspendue
            chasseActive = nom
            chasseDebutTemps = etat.debutTemps
            chasseDebutVie = etat.debutVie
            chasseNiveau = etat.niveau
            chasseRare = etat.rare
            chassePiegee = etat.piegee
            chasseVieTouchee = etat.vieTouchee == true
            chasseSuspendue = nil
            DebugChasse("suspension", nom .. L(" — cadavre repéré au dernier filet différé : prise !"))
            FinChasseVictoire(nom)
            return
        end
        suspendAnnonce[nom] = true
        DEFAULT_CHAT_FRAME:AddMessage(libelle)
    end)
end

function AfficherBanniere(texte, r, g, b) -- globale : appelable depuis /hunt test
    if not DB.config.banniere then return end
    banniereTexte:SetText(texte)
    banniereTexte:SetTextColor(r, g, b)
    banniere:Show()
    banniere:SetAlpha(1)
    C_Timer.After(3, function() banniere:Hide() end)
end

local function DebutChasse(nom, classification, niveau)
    -- Pas de chasse pour un fantôme : être mort et cibler la bête ne
    -- compte pas (ni chrono, ni musique).
    if UnitIsDeadOrGhost("player") then return end
    -- ANTI-CADAVERE : prise validée il y a moins de 60 s sur CE monstre ?
    -- C'est son cadavre qui re-traîne (re-ciblage, filet viseur) — une
    -- bête morte une fois ne se prend pas deux fois. Les 30 s de
    -- dernierTrigger sont réarmées à la victoire, ce garde est le seul
    -- rempart fiable quand UnitIsDead échoue sur les cadavres (client
    -- custom : Toison d'or comptée double par ce trou).
    if nom and dernierePrise[nom] and time() - dernierePrise[nom] < 60 then
        DebugChasse("antirechasse", nom .. L(" — prise < 60 s, chasse refusée"))
        return
    end
    -- Pas de chasse sur un CADAVRE : re-cibler la bête morte juste après
    -- la victoire relançait une chasse que le filet « morte sous le
    -- viseur » validait aussitôt — prises fantômes dans le compteur.
    if UnitExists("target") and (UnitName("target") or "") == nom then
        local okMort, mort = pcall(function() return UnitIsDead("target") end)
        if okMort and mort then return end
    end
    -- Reprise d'une chasse suspendue (re-ciblage après désélection, alt-tab,
    -- etc.) : le chrono REPREND où il en était, pas de nouvelle bannière —
    -- seulement la musique de combat qui repart.
    if chasseSuspendue and chasseSuspendue.nom == nom
        and time() - (dernierTrigger[nom] or 0) < 300
        and not UnitIsDeadOrGhost("player") then -- jamais de reprise en fantôme
        chasseActive = nom
        chasseDebutTemps = chasseSuspendue.debutTemps
        chasseDebutVie = chasseSuspendue.debutVie
        chasseNiveau = chasseSuspendue.niveau
        chasseRare = chasseSuspendue.rare
        chassePiegee = chasseSuspendue.piegee
        chasseVieTouchee = chasseSuspendue.vieTouchee == true
        chasseSuspendue = nil
        -- Reprise SILENCIEUSE en combat : au moment où la bête meurt
        -- (DoT finissants), le message tombait en pleine action, pile
        -- quand le chrono « continuait » tout seul. Hors combat, la
        -- reprise reste annoncée.
        -- Reprise annoncée UNIQUEMENT si la suspension l'a été : une
        -- suspension passée inaperçue (bête morte sous DoT juste après)
        -- ne doit pas donner « Chasse reprise » juste avant « réussie ».
        if not UnitAffectingCombat("player") and suspendAnnonce[nom] then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffa0ff50Chasse reprise :|r " .. nom .. L(" — le chrono continue."))
        end
        suspendAnnonce[nom] = nil
        MettreAJourIndicateur()
        if MHH_LancerMusiqueCombat then MHH_LancerMusiqueCombat() end
        return
    end
    -- Déjà en chasse sur cette bête (re-ciblage en combat, etc.) : rien à
    -- refaire — le chrono continue tranquillement
    if chasseActive == nom then return end
    local maintenant = time()
    if dernierTrigger[nom] and maintenant - dernierTrigger[nom] < 30 then return end
    dernierTrigger[nom] = maintenant
    -- Zone RÉELLE du client : le data file peut nommer la zone autrement
    -- que le serveur (« Hiverpré » vs « Berceau-de-l'hiver ») — la bête
    -- restait introuvable dans l'onglet de SA vraie zone. On adopte le
    -- nom renvoyé par GetZoneText() à l'engagement : la bête chassée
    -- est dans son habitat à ce moment-là.
    pcall(function()
        local zc = GetZoneText()
        if zc and zc ~= "" and MHH_CATALOGUE[nom] and MHH_CATALOGUE[nom] ~= zc then
            DebugChasse("zone", nom .. " : " .. tostring(MHH_CATALOGUE[nom]) .. " → " .. zc)
            MHH_CATALOGUE[nom] = zc
        end
    end)
    chasseActive = nom
    chasseDebutVie = UnitHealth("player")
    -- [Retiré v0.29] PV de la cible à l'engagement + sondes de santé
    -- supprimés : ce client verrouille tout accès aux PV des mobs.
    chasseVieTouchee = false -- nouveau départ : remise à zéro du suivi
    chasseNiveau = LireSecretTexte(UnitLevel) or NombreOrdinaire(niveau)
    -- v0.25 : UnitLevel peut être empoisonné comme UnitHealth (type
    -- menteur, comparaisons interdites). On convertit ICI, cible
    -- vivante, par le texte puis la dichotomie — plus tard dans la
    -- chasse, chasseNiveau doit être un NOMBRE ORDINAIRE (comparé à
    -- nivMax/nivMin, au niveau du joueur… un secret ferait tout
    -- capoter en silence, dont le repli « estimation » du gabarit.
    -- Rayon de hitbox capturé TANT QUE LA CIBLE EST VIVANTE : à la mort,
    -- le client peut avoir libéré la cible — le repli sauve la mesure.
    chasseRayon = nil
    pcall(function()
        local b = UnitBoundingRadius and UnitBoundingRadius("target")
        if type(b) == "number" and b > 0 then chasseRayon = NombreOrdinaire(b) end
    end)
    chasseRare = (classification == "rare" or classification == "rareelite")
    chasseDebutTemps = maintenant
    chassePiegee = false
    -- Repérage : position du KILL = là où vivait la bête (meilleur
    -- indice pour le clic Carte). Au début de chasse on n'enregistre
    -- que s'il n'y en a pas encore (première rencontre) — sinon le
    -- marqueur tombait sur la position du joueur, pas de la bête.
    if not (DB.reperees and DB.reperees[nom]) then EnregistrerReperee(nom) end
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r En chasse : |cffffff00") .. nom .. "|r (" .. (classification or "?") .. L(" niv. ") .. (niveau or "?") .. ")")
    if DB.contrat == nom then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Objectif du contrat en vue : |cffffff00") .. nom .. "|r !")
    end
    MettreAJourIndicateur()
    -- Son de mise en chasse : court et percutant (préparation de groupe),
    -- pas le rugissement — réservé aux contrats et missions
    if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_READY_CHECK or 8960) end
    -- Bandeau « EN CHASSE » éphémère : 4 s à la sélection, puis il
    -- s'efface en fondu — reste seulement le mini chrono en coin.
    -- COURTOISIE INVERSE : la 1re découverte d'un rare affiche son
    -- toast pile au moment de l'engagement — le bandeau ATTEND la
    -- fin des toasts avant d'apparaître (jamais de chevauchement).
    local function MontrerBandeauChasse()
        if toastEnCours then
            C_Timer.After(0.5, MontrerBandeauChasse)
            return
        end
        if BandeauChasseEphemer then BandeauChasseEphemer() end
    end
    if C_Timer and C_Timer.After then
        MontrerBandeauChasse()
    elseif BandeauChasseEphemer then
        BandeauChasseEphemer()
    end
    -- La musique de combat démarre dès la sélection du gibier
    if MHH_LancerMusiqueCombat then MHH_LancerMusiqueCombat() end
end

-- ================= MÉTÉO (client Forever : API C_Weather) =================
-- Le client Forever expose C_Weather.GetCurrentWeather() -> { type, intensity }
-- et l'événement WEATHER_CHANGED. Absents sur d'autres clients : tout
-- s'écroule silencieusement, aucune erreur.
MHH_NOMS_METEO = {
    clear = L("ciel dégagé"), rain = "pluie", snow = "neige",
    sandstorm = L("tempête de sable"), firestorm = L("pluie de feu"), cloudy = L("ciel couvert"),
}
local dernierMeteoAnnonce = nil
local dernierScanMouseover = 0 -- garde-fou anti-spam (CURSOR_UPDATE est bavard)
-- Retourne (nomAffichage, typeBruit, intensité) ou nil si l'API manque
local function MeteoActuelle()
    if not C_Weather or not C_Weather.GetCurrentWeather then return nil end
    local ok, info = pcall(C_Weather.GetCurrentWeather)
    if ok and type(info) == "table" then
        local cle = string.lower(tostring(info.type or "clear"))
        -- Code brut non reconnu (ex. « 0 ») : pas de nom affichable.
        -- Mieux vaut ne rien dire qu'afficher « Météo : actuellement 0 ».
        if MHH_NOMS_METEO[cle] then return MHH_NOMS_METEO[cle], cle, info.intensity end
        return nil, cle, info.intensity
    end
    return nil
end

-- ================= MISSIONS DE CHASSE (le camp Nesingwary) =================
-- Quêtes scénarisées, SÉQUENTIELLES : chacune se déverrouille quand la
-- précédente est accomplie. Pas d'étape « accepter » : le carnet tient la
-- liste, tuer la cible pendant que la mission est déverrouillée la valide.
-- Les conditions (heure, météo) sont des informations de terrain AFFICHÉES :
-- l'API addon ne lit pas la météo, et le spawn suit les règles du serveur.
MHH_MISSIONS = {
    {
        id = "premier_croc", titre = L("Le premier croc"), pnj = "Hemet Nesingwary",
        citation = L("Tout chasseur commence quelque part. Rapporte-moi le dard du Flagelleur, et on parlera des vrais trophées."),
        cible = "Flagelleur de la mort", zone = "Durotar",
        points = 50, recompense = L("Couteau de campagne du vieux Hemet"),
        icone = "INV_Misc_MonsterClaw_04",
    },
    {
        id = "rateau_plateau", titre = L("Le démon du plateau"), pnj = "Hemet Nesingwary Jr.",
        citation = L("Le Rateau a distancé des cavaliers sur le plateau de Mulgore. Montre-lui qu'on ne gagne pas toujours en fuyant."),
        cible = "Le Rateau", zone = "Mulgore",
        points = 75, recompense = L("Lunette usée du Junior"),
        icone = "Ability_Hunter_Pet_Cat",
    },
    {
        id = "crocs_crepuscule", titre = L("Les crocs du crépuscule"), pnj = "Ajeck Roundact",
        citation = L("Mon père a raté la mâchoire de ce vieil ours il y a vingt ans. Termine ce qu'il a commencé — et ne me parle pas de chance."),
        cible = "Vieux Vicejaw", zone = "Forêt des Pins-Argentés",
        condition = L("Rôde à la nuit tombée"),
        points = 100, recompense = L("Gripesous usé de la famille Roundact"),
        icone = "Ability_Hunter_Pet_Bear",
    },
    {
        id = "veuve_brume", titre = L("La veuve de la brume"), pnj = "Barnil Stonepot",
        citation = L("Je ne chasse plus, moi, je porte les affaires. Mais pour celle-là… j'aimerais lire la fin du carnet."),
        cible = "Veuve de Sombrebrume", zone = "Marécage d'Âprefange",
        condition = L("Tisse ses toiles quand la pluie bat le marais"),
        meteo = "rain", -- vérifiée EN DIRECT via C_Weather (client Forever)
        points = 125, recompense = L("Mule de Barnil pour un voyage (clin d'œil)"),
        icone = "Ability_Hunter_Pet_Spider",
    },
    {
        id = "seigneur_criniere", titre = L("Le seigneur à crinière"), pnj = "Hemet Nesingwary",
        citation = L("Vingt ans que je rêve de sa crinière noire. Le monde dira que j'ai vieilli — le carnet dira que j'ai eu raison."),
        cible = "Humar le Seigneur hautain", zone = "Les Tarides",
        condition = "Noir comme le charbon, seul sous les acacias",
        points = 150, recompense = L("Première page du carnet d'Hemet"),
        icone = "Ability_Hunter_Pet_Cat",
    },
    {
        id = "colosse_cratere", titre = L("Le colosse du cratère"), pnj = L("Émissaire de D.E.H.T.A."),
        citation = L("Nous ne pardonnons pas la chasse. Mais ce titan piétine les couvées de tout le cratère. Faites-le tomber, chasseur — et ne nous dites rien."),
        cible = "Roi Mosh", zone = "Cratère d'Un'Goro",
        condition = L("Le sol tremble bien avant qu'on ne le voie"),
        points = 200, recompense = L("Faveur (à contre-cœur) de D.E.H.T.A."),
        icone = "Ability_Hunter_Pet_Gorilla",
    },
    {
        id = "ombre_de_lorne", titre = L("L'ombre de l'Orne"), pnj = "Ajeck Roundact",
        citation = L("Ce worg mord avec l'ombre — les bûcherons en parlent encore à voix basse. Bois de la Pénombre, après minuit. Bonne chance."),
        cible = "Lupos", zone = "Bois de la Pénombre",
        condition = L("Chasse à la tombée de la nuit"),
        points = 175, recompense = L("Lanterne sourde de la comté"),
        icone = "Ability_Hunter_Pet_Wolf",
    },
    {
        id = "faux_mecanique", titre = L("La faux qui fauche"), pnj = "Hemet Nesingwary Jr.",
        citation = L("Une moissonneuse qui a appris à faucher autre chose que le blé. Les champs sentent l'huile et la peur. Débrouillez-la."),
        cible = "Foe Reaper 4000", zone = "Marches de l'Ouest",
        condition = L("Immobile entre les épis… jusqu'à ce qu'on s'approche"),
        points = 150, recompense = L("Clé à molette du Junior (trophée)"),
        icone = "Trade_Engineering",
    },
}

-- Progression : appelée à chaque prise validée. Une mission déverrouillée
-- dont la cible vient d'être prise est accomplie — points + toast + carnet.
local function VerifierMissions(nom)
    if not DB.missions then DB.missions = {} end
    for i, q in ipairs(MHH_MISSIONS) do
        -- Une mission ne se valide que si elle est ACCEPTÉE (bouton
        -- « Accepter » de la carte) — l'acceptation marque l'intention
        if not DB.missions[q.id] and q.cible == nom and DB.missionActive == q.id then
            DB.missions[q.id] = date("%d/%m/%y")
            DB.missionActive = nil
            DB.points = DB.points + (q.points or 0)
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffa0ff50Mission accomplie :|r "
                    .. q.titre .. " ! (+" .. (q.points or 0) .. L(" points)"))
                ToastSucces("Interface\\Icons\\" .. (q.icone or "INV_Misc_Note_01"),
                    L("Mission accomplie"), q.titre .. " — " .. (q.pnj or ""))
                if MHH_RaffraichirMissions then MHH_RaffraichirMissions() end
        end
    end
end

-- Sous-classe d'une référence d'arme (lien ou id). Sur ce client, la
-- sous-classe est la 8e valeur retournée par GetItemInfo ; or pcall
-- décale tout d'un cran (le « ok » occupe la première place) — la version
-- naïve à 8 captures lisait donc la 7e valeur. D'où 9 captures ici.
local function sousClasseDe(ref)
    if not ref then return nil end
    local ok, _, _, _, _, _, _, _, sous = pcall(GetItemInfo, ref)
    if not ok then return nil end
    if sous == nil or sous == "" then return nil end
    return sous
end

-- TYPES D'ARMES canoniques (client FR) : l'histogramme affiche TOUS ces
-- types, même à 0 — un chasseur voit d'un coup d'œil ses armes de prédilection
-- et celles qu'il n'a jamais utilisées.
MHH_TYPES_ARMES = {
    "Dagues", "Epées", "Epées à deux mains", "Masses", "Masses à deux mains",
    "Haches", "Haches à deux mains", "Armes de pugilat", "Armes d'hast",
    "Arcs", "Arbalètes", "Bâtons", "Baguettes", "Armes à feu",
}
-- ARMES PAR CLASSE (compétences d'armes Vanilla) : l'histogramme ne montre
-- que les types EFFECTIVEMENT utilisables par la classe du chasseur — un
-- voleur n'a pas de fusil ni de hallebarde, inutile de les afficher.
MHH_ARMES_PAR_CLASSE = {
    WARRIOR = { "Dagues", "Epées", "Epées à deux mains", "Masses", "Masses à deux mains",
                "Haches", "Haches à deux mains", "Armes de pugilat", "Armes d'hast", "Arcs", "Armes à feu" },
    PALADIN = { "Masses", "Masses à deux mains", "Epées", "Epées à deux mains",
                "Haches", "Haches à deux mains", "Armes d'hast" },
    HUNTER = { "Arcs", "Arbalètes", "Armes à feu", "Haches", "Haches à deux mains",
                "Epées", "Epées à deux mains", "Armes de pugilat", "Dagues", "Armes d'hast" },
    ROGUE = { "Dagues", "Epées", "Masses", "Armes de pugilat", "Arbalètes", "Armes à feu", "Arcs" },
    PRIEST = { "Baguettes", "Masses", "Dagues" },
    SHAMAN = { "Masses", "Masses à deux mains", "Haches", "Haches à deux mains",
                "Dagues", "Armes de pugilat", "Bâtons" },
    MAGE = { "Baguettes", "Bâtons", "Epées", "Dagues" },
    WARLOCK = { "Baguettes", "Epées", "Dagues", "Bâtons" },
    DRUID = { "Dagues", "Masses", "Masses à deux mains", "Bâtons", "Armes de pugilat", "Epées à deux mains" },
}
-- Types d'armes affichés pour CE chasseur (sa classe ; repli : tout)
MHH_TYPES_ARMES_JOUEUR = nil
local function MHH_TypesArmesJoueur()
    if MHH_TYPES_ARMES_JOUEUR then return MHH_TYPES_ARMES_JOUEUR end
    local liste = nil
    pcall(function()
        local _, token = UnitClass("player")
        liste = MHH_ARMES_PAR_CLASSE[(token or ""):upper()]
    end)
    MHH_TYPES_ARMES_JOUEUR = liste or MHH_TYPES_ARMES
    return MHH_TYPES_ARMES_JOUEUR
end

-- Libellés COURTS (affichés horizontalement sous chaque colonne — pas de
-- rotation en Vanilla, les noms complets ne tiendraient pas)
MHH_TYPES_ARMES_COURT = {
    ["Dagues"] = "Dague", ["Epées"] = "Epee",
    ["Epées à deux mains"] = "Epee2M", ["Masses"] = "Masse",
    ["Masses à deux mains"] = "Masse2M", ["Haches"] = "Hache",
    ["Haches à deux mains"] = "Hache2M", ["Armes de pugilat"] = "Poing",
    ["Armes d'hast"] = "Hast", ["Arcs"] = "Arc",
    ["Arbalètes"] = "Arb.", ["Bâtons"] = "Baton",
    ["Baguettes"] = "Bagu.", ["Armes à feu"] = "Fusil",
}
-- v0.36 : icône par type d'arme façon Monster Hunter (à la place des
-- libellés verticaux). Mode custom : Textures/arme_<cle>.tga ; sinon
-- l'icône du jeu ; types sans icône connue → ancien libellé vertical.
MHH_CLE_ICONE_ARME = {
    ["Dagues"] = "dague", ["Epées"] = "epee", ["Epées à deux mains"] = "epee2m",
    ["Masses"] = "masse", ["Masses à deux mains"] = "masse2m",
    ["Haches"] = "hache", ["Haches à deux mains"] = "hache2m",
    ["Armes de pugilat"] = "poing", ["Armes d'hast"] = "hast",
    ["Arcs"] = "arc", ["Arbalètes"] = "arbalete", ["Bâtons"] = "baton",
    ["Baguettes"] = "baguette", ["Armes à feu"] = "fusil",
}
-- v0.40 : fichiers renommés par le chasseur (extraits Photopea) :
-- Textures/Weapons/weapon_<nom>.tga — table de correspondance clé→nom.
MHH_FICHIER_ARME = {
    ["dague"] = "dagger", ["epee"] = "sword", ["epee2m"] = "sword",
    ["masse"] = "mace", ["masse2m"] = "mace", ["hache"] = "axe",
    ["hache2m"] = "axe", ["poing"] = "gloves", ["hast"] = "lance",
    ["arc"] = "bow", ["arbalete"] = "crossbow", ["baton"] = "staff",
    ["baguette"] = "rode", ["fusil"] = "rifle",
}
MHH_ICONES_ARMES_WOW = {
    ["Dagues"] = "Interface\\Icons\\INV_Sword_04",
    ["Epées"] = "Interface\\Icons\\INV_Sword_06",
    ["Epées à deux mains"] = "Interface\\Icons\\INV_Sword_08",
    ["Masses"] = "Interface\\Icons\\INV_Mace_01",
    ["Masses à deux mains"] = "Interface\\Icons\\INV_Mace_02",
    ["Haches"] = "Interface\\Icons\\INV_Axe_01",
    ["Haches à deux mains"] = "Interface\\Icons\\INV_Axe_03",
    ["Arcs"] = "Interface\\Icons\\INV_Weapon_Bow_01",
    ["Armes à feu"] = "Interface\\Icons\\INV_Weapon_Rifle_02",
    ["Bâtons"] = "Interface\\Icons\\INV_Staff_02",
    ["Baguettes"] = "Interface\\Icons\\INV_Wand_01",
}
-- v0.36 : variante « à deux mains » d'une famille (départage par la
-- ligne « deux mains » du tooltip)
MHH_VARIANTES_2M = {
    ["Epées"] = "Epées à deux mains", ["Masses"] = "Masses à deux mains",
    ["Haches"] = "Haches à deux mains",
}
-- v0.38 : à l'AFFICHAGE, 1M et 2M vivent dans le même « sac » (une épée
-- est une épée) — le comptage interne reste DISTINCT, seules les
-- colonnes de l'histogramme sont regroupées (moins de colonnes, plus
-- lisible ; réversible, aucune donnée perdue)
MHH_GROUPE_ARME = {
    ["Epées à deux mains"] = "Epées",
    ["Masses à deux mains"] = "Masses",
    ["Haches à deux mains"] = "Haches",
}
-- Normalisation : le client FR écrit parfois « Epées » ou « Épées » (accent),
-- et le tooltip peut coller la classe de l'arme en majuscules.
-- Type d'arme deviné depuis le NOM de l'objet (« Dague de chagrin » →
-- « Dagues »). Dernière source de détection : sur ce client GetItemInfo
-- est nil ET le tooltip n'a AUCUNE ligne de sous-classe (diagnostic
-- /hunt armes : nom / niveau / lié / à une main / dégâts — sans « Dagues »).
-- Le nom des armes FR commence presque toujours par le type — c'est le
-- seul indice restant, et il est fiable.
local MHH_MOTS_NOM_ARME = {
    { "deux mains", nil }, -- traité à part ci-dessus (variantes 2M)
    { "dague", "Dagues" },
    { "poignard", "Dagues" }, { "kriss", "Dagues" }, { "stylet", "Dagues" },
    { "massue", "Masses" }, { "gourdin", "Masses" }, { "maillet", "Masses" },
    { "arbalète", "Arbalètes" }, { "arbalete", "Arbalètes" },
    { "baguette", "Baguettes" },
    { "épée", "Epées" }, { "epee", "Epées" },
    { "masse", "Masses" },
    { "hache", "Haches" },
    { "hallebarde", "Armes d'hast" }, { "lance", "Armes d'hast" },
    { "fusil", "Armes à feu" },
    { "bâton", "Bâtons" }, { "baton", "Bâtons" },
    { "poing", "Armes de pugilat" },
    -- v0.36 : noms FR exotiques qui ne contiennent PAS le type — le
    -- « Fendoir » d'un nain est une hache, mais rien dans le mot ne le
    -- dit ; idem espadon (épée 2M), serpe, faux, arquebuse…
    { "fendoir", "Haches" },
    { "espadon", "Epées à deux mains" },
    { "cimeterre", "Epées" }, { "sabre", "Epées" }, { "rapière", "Epées" },
    { "morgenstern", "Masses" }, { "fléau", "Masses" }, { "marteau", "Masses" },
    { "serpe", "Dagues" },
    { "faux", "Armes d'hast" }, { "faucille", "Armes d'hast" },
    { "pique", "Armes d'hast" }, { "javelot", "Armes d'hast" },
    { "arquebuse", "Armes à feu" }, { "pistolet", "Armes à feu" },
    { "griffes", "Armes de pugilat" }, { "gantelet", "Armes de pugilat" },
    { "arc", "Arcs" }, -- en dernier : « arc » est court
}
local function NomVersTypeArme(nom)
    if type(nom) ~= "string" or nom == "" then return nil end
    local bas = string.lower(nom)
    -- Variantes à deux mains : le nom le précise (« ... à deux mains »)
    if string.find(bas, "deux mains", 1, true) then
        if string.find(bas, "épée", 1, true) or string.find(bas, "epee", 1, true) then return "Epées à deux mains" end
        if string.find(bas, "masse", 1, true) then return "Masses à deux mains" end
        if string.find(bas, "hache", 1, true) then return "Haches à deux mains" end
    end
    for _, e in ipairs(MHH_MOTS_NOM_ARME) do
        local mot, canon = e[1], e[2]
        if canon and string.find(bas, mot, 1, true) then return canon end
    end
    return nil
end

local function NormaliserTypeArme(t)
    if not t then return nil end
    t = tostring(t)
    -- minuscules + sans accent brutal (le FR du serveur varie)
    local bas = string.lower(t)
    for _, canon in ipairs(MHH_TYPES_ARMES) do
        local canonBas = string.lower(canon)
        if bas == canonBas then return canon end
        -- correspondance partielle (ex. « haches » dans « haches à deux mains »)
        if string.find(bas, canonBas, 1, true) and #bas <= #canonBas + 2 then
            return canon
        end
    end
    -- graphies FR alternatives courantes
    local ALT = {
        ["épées"] = "Epées", ["epees"] = "Epées", ["épée"] = "Epées",
        ["épées à deux mains"] = "Epées à deux mains",
        ["dague"] = "Dagues", ["hache"] = "Haches",
        ["haches à deux mains"] = "Haches à deux mains",
        ["masse"] = "Masses", ["bâton"] = "Bâtons", ["baton"] = "Bâtons",
        ["arc"] = "Arcs", ["baguette"] = "Baguettes",
        ["armes de pugilat"] = "Armes de pugilat",
        ["armes d'hast"] = "Armes d'hast",
        ["armes à feu"] = "Armes à feu", ["arbalète"] = "Arbalètes",
    }
    return ALT[bas] or t
end

-- ================= RUMEURS DE GUILDE (missions cachées) =================
-- Missions bizarres, cachées, aléatoires : une seule par jour, tirée au
-- hasard dans celles que le RANG de chasseur débloque (2 = Chasseur →
-- 5 = Légende). Sous le rang requis, l'onglet Missions ne montre qu'un
-- murmure verrouillé. Une rumeur ACCEPTÉE reste en cours jusqu'à sa
-- résolution, même après le tirage du lendemain.
local function HeureJeu()
    local heure
    pcall(function()
        local a, b = GetGameTime()
        heure = b and a or math.floor((a or 0) / 60)
    end)
    return heure
end

-- Types d'armes tenues au moment de la prise (mains droite/gauche) —
-- les rumeurs « à la dague », « à la baguette »… s'y fient.
local function ArmesDeLaPrise()
    local t = {}
    for _, slot in ipairs({ 16, 17 }) do
        local sc = NormaliserTypeArme(sousClasseDe(GetInventoryItemLink and GetInventoryItemLink("player", slot)))
            or NormaliserTypeArme(sousClasseDe(GetInventoryItemID and GetInventoryItemID("player", slot)))
        if sc then t[#t + 1] = sc end
    end
    return t
end

-- RUMEURS & ARMES : certaines rumeurs imposent une arme que la classe
-- du chasseur ne sait pas porter (un guerrier n'a pas de baguette, un
-- magicien pas de fusil). Matrice d'armurerie VANILLA (clients FR/EN :
-- UnitClass renvoie la classe anglaise en 2e valeur) : le tirage du
-- jour ne propose jamais une rumeur infaisable pour la classe.
MHH_CLASSES_ARME = {
    ["Dagues"]            = { WARRIOR=1, HUNTER=1, ROGUE=1, PRIEST=1, MAGE=1, WARLOCK=1, SHAMAN=1, DRUID=1 },
    ["Baguettes"]         = { PRIEST=1, MAGE=1, WARLOCK=1 },
    ["Armes à feu"]       = { WARRIOR=1, HUNTER=1, ROGUE=1 },
    ["Armes de pugilat"]  = { WARRIOR=1, HUNTER=1, ROGUE=1, SHAMAN=1 },
}
local function ClassePeutUtiliser(armes)
    local ok, _, cls = pcall(UnitClass, "player")
    if not ok or not cls then return true end -- classe illisible : on ne filtre pas
    for _, arme in ipairs(armes) do
        local d = MHH_CLASSES_ARME[arme]
        if d and d[cls] then return true end
    end
    return false
end

MHH_MISSIONS_CACHEES = {
    { id = "rumeur_cuillere", rang = 2, points = 80,
      titre = L("La chasse à la cuillère"),
      citation = L("Un nain, paraît-il, a dépiauté un worg à la cuillère. Toi, tu as une dague : fais honneur à la légende."),
      objectif = L("Abats n'importe quel gibier du carnet avec une dague."),
      recompense = L("Le récit du nain, illustré"),
      icone = "Ability_Rogue_Backstab",
      armes = { "Dagues" },
      verifier = function(ctx)
          for _, a in ipairs(ArmesDeLaPrise()) do if a == "Dagues" then return true end end
          return false
      end },
    { id = "rumeur_minuit", rang = 2, points = 70,
      titre = L("Le concert de minuit"),
      citation = L("Les grillons jouent, la guilde ronfle. Toi, tu chasses quand les tavernes ferment — la nuit t'appartient."),
      objectif = L("Réussis une prise entre minuit et 4h du matin (heure du jeu)."),
      recompense = L("Bougie de veille du guetteur"),
      icone = "INV_Misc_PocketWatch_01",
      verifier = function(ctx)
          return ctx.heure ~= nil and ctx.heure >= 0 and ctx.heure < 4
      end },
    { id = "rumeur_neige", rang = 2, points = 60,
      titre = L("Le conte de la neige"),
      citation = L("Il neigeait. Il ne neige plus. Il neigera encore : prends ton gibier avant que la page ne tourne."),
      objectif = L("Réussis une prise sous la neige."),
      recompense = L("Flocons pressés dans le carnet"),
      icone = "Spell_Frost_FrostWard",
      verifier = function(ctx) return ctx.meteo == "snow" end },
    { id = "rumeur_baguette", rang = 3, points = 100,
      titre = L("Le sort en baguette"),
      citation = L("Un magicien a parié qu'aucun gibier du carnet ne tomberait sous une baguette. La guilde n'aime pas perdre les paris."),
      objectif = L("Abats un gibier du carnet avec une baguette."),
      recompense = L("Le pari du magicien, au montant entier"),
      icone = "INV_Wand_01",
      armes = { "Baguettes" },
      verifier = function(ctx)
          for _, a in ipairs(ArmesDeLaPrise()) do if a == "Baguettes" then return true end end
          return false
      end },
    { id = "rumeur_poudre", rang = 3, points = 120,
      titre = L("La poudre mouillée"),
      citation = L("Pluie sur les mèches, gibier dans les fourrés. Un vrai chasseur attend l'éclair pour tirer."),
      objectif = L("Abats un gibier du carnet avec une arme à feu, sous la pluie."),
      recompense = L("Poudre tenue au sec, un miracle"),
      icone = "INV_Weapon_Rifle_01",
      armes = { "Armes à feu" },
      verifier = function(ctx)
          if ctx.meteo ~= "rain" then return false end
          for _, a in ipairs(ArmesDeLaPrise()) do if a == "Armes à feu" then return true end end
          return false
      end },
    { id = "rumeur_aveugle", rang = 3, points = 110,
      titre = L("Aveugle et sec"),
      citation = L("La pluie colle les cils, la bête griffe l'air. Reviens sans une goutte de ton sang sur l'équipement."),
      objectif = L("Réussis une prise sous la pluie sans perdre un seul point de vie."),
      recompense = L("Ciré de l'ancien de la guilde"),
      icone = "Ability_Stealth",
      verifier = function(ctx) return ctx.meteo == "rain" and ctx.viePerdue == 0 end },
    { id = "rumeur_pari", rang = 4, points = 150,
      titre = L("Le pari du fou"),
      citation = L("Plus haut niveau que toi, heures les plus noires, aucun témoin. La guilde prend les paris — ne perds pas."),
      objectif = L("Prends un gibier de niveau supérieur au tien, entre minuit et 5h du matin."),
      recompense = L("Les dés du comptoir, pipés"),
      icone = "INV_Misc_Dice_01",
      verifier = function(ctx)
          return ctx.heure ~= nil and ctx.heure >= 0 and ctx.heure < 5
              and ctx.niveau ~= nil and ctx.niveauJoueur ~= nil and ctx.niveau > ctx.niveauJoueur
      end },
    { id = "rumeur_poings", rang = 4, points = 150,
      titre = L("Poings contre crocs"),
      citation = L("On a vu des poings d'arène finir des traques entières. La guilde veut voir ça de ses propres yeux."),
      objectif = L("Abats un gibier du carnet à mains nues (armes de pugilat)."),
      recompense = L("Bandages de la main droite"),
      icone = "INV_Gauntlets_05",
      armes = { "Armes de pugilat" },
      verifier = function(ctx)
          for _, a in ipairs(ArmesDeLaPrise()) do if a == "Armes de pugilat" then return true end end
          return false
      end },
    { id = "rumeur_sommet", rang = 5, points = 250,
      titre = L("Le duel du sommet"),
      citation = L("Le dernier murmure de la guilde ne se mérite qu'au sommet du rang : plus grand que toi, et pas une égratignure."),
      objectif = L("Prends un gibier de niveau supérieur au tien sans perdre un seul point de vie."),
      recompense = L("Le dernier murmure de la guilde"),
      icone = "INV_Misc_QuestionMark",
      verifier = function(ctx)
          return ctx.niveau ~= nil and ctx.niveauJoueur ~= nil and ctx.niveau > ctx.niveauJoueur
              and ctx.viePerdue == 0
      end },
}

local function MissionCacheeParId(id)
    if not id then return nil end
    for _, m in ipairs(MHH_MISSIONS_CACHEES) do
        if m.id == id then return m end
    end
    return nil
end

-- Tirage du jour : UNE rumeur au hasard parmi celles que le rang
-- débloque et non accomplies. Re-tirage si la rumeur du jour a été
-- élucidée (une promotion dans la journée ouvre alors aussitôt une
-- nouvelle rumeur, au prochain passage de zone / connexion).
local function TirageMissionCachee()
    if not DB then return end
    local aujourdhui = date("%y%m%d")
    local cur = DB.missionCacheeJour
    if cur and cur.date == aujourdhui and cur.id and not (DB.missions and DB.missions[cur.id]) then
        return -- rumeur du jour encore pendante : on la garde
    end
    local idxRang = RangGuilde(DB.points)
    local cand = {}
    for _, m in ipairs(MHH_MISSIONS_CACHEES) do
        if m.rang <= idxRang and not (DB.missions and DB.missions[m.id])
            -- rumeur d'arme : exclue si la classe ne sait pas la porter
            and (not m.armes or ClassePeutUtiliser(m.armes)) then
            cand[#cand + 1] = m
        end
    end
    local id = (#cand > 0) and cand[math.random(#cand)].id or nil
    DB.missionCacheeJour = { date = aujourdhui, id = id }
    if id and not DB.missionCacheeActive then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffb97affUne rumeur étrange court dans la guilde…|r Onglet Missions, chasseur — on ne répète pas ce genre de choses."))
    end
end

-- Validation : appelée à chaque prise validée avec le contexte de la
-- chasse (météo, vie perdue, niveau du gibier, heure). La rumeur
-- ACCEPTÉE seule compte — l'intention du chasseur, pas le hasard.
local function VerifierMissionsCachees(nom, ctx)
    if not DB or not DB.missionCacheeActive then return end
    local m = MissionCacheeParId(DB.missionCacheeActive)
    if not m then DB.missionCacheeActive = nil return end
    local ok, valide = pcall(m.verifier, ctx)
    if not ok or not valide then return end
    DB.missions = DB.missions or {}
    DB.missions[m.id] = date("%d/%m/%y")
    DB.missionCacheeActive = nil
    DB.points = DB.points + (m.points or 0)
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffb97affRumeur élucidée :|r ") .. m.titre .. " ! (+" .. (m.points or 0) .. L(" points)"))
    ToastSucces("Interface\\Icons\\" .. (m.icone or "INV_Misc_QuestionMark"),
        L("Rumeur élucidée"), m.titre)
    if MHH_RaffraichirMissions then MHH_RaffraichirMissions() end
end

-- Rumeur affichée sur la carte « Rumeur de guilde » : celle du jour,
-- ou celle acceptée si elle survit au changement de jour.
function MHH_RumeurDuJour()
    if not DB then return nil end
    if DB.missionCacheeActive then return MissionCacheeParId(DB.missionCacheeActive) end
    local cur = DB.missionCacheeJour
    if cur and cur.id and cur.date == date("%y%m%d") then
        return MissionCacheeParId(cur.id)
    end
    return nil
end

FinChasseVictoire = function(nom)
    -- Anti double-validation : la bête ne se prend qu'une fois (le journal
    -- de combat, le ticker chrono et UnitIsDead peuvent tous la signaler)
    if chasseActive ~= nom then return end
    -- Prise acquittée IMMÉDIATEMENT : même si une erreur survenait plus
    -- bas (contexte tainté de Midnight, « secret numbers »), la bête ne
    -- peut plus être validée deux fois ni boucler sur des demi-exécutions.
    chasseActive = nil
    chasseSuspendue = nil
    -- Réarmement de l'anti-spam : une bête re-tuée dans les 30 s doit
    -- pouvoir déclencher une nouvelle chasse (le compteur de kills
    -- comptait parfois une prise sur deux).
    dernierTrigger[nom] = nil
    -- PRISE HORODATÉE : pendant 60 s, aucune nouvelle chasse ne peut être
    -- ouverte sur ce monstre — la victoire vient d'être validée, tout
    -- redéclenchement (re-ciblage du cadavre, filet « morte sous le
    -- viseur ») serait un DOUBLE COMPTE (kills +1 fantôme, arme +1).
    dernierePrise[nom] = time()
    DebugChasse("victoire", nom)
    -- Repérage au kill : là où la bête est tombée = son point de spawn
    -- réel. C'est CETTE position que montrera le clic Carte quand le
    -- carnet n'a pas de coordonnées de spawn (318 rares sur 335).
    EnregistrerReperee(nom)
    VerifierMissions(nom)
    DB.chasses[nom] = DB.chasses[nom] or { kills = 0, vu = true }
    if (DB.chasses[nom].kills or 0) == 0 then DB.chasses[nom].nouveau = true end
    local info = DB.chasses[nom]
    info.kills = (info.kills or 0) + 1
    info.vu = true
    -- Réconciliation Forever : mémorise l'id NPC de la bête tuée (extrait
    -- du GUID à la découverte) pour l'export /hunt export
    if not info.id and DB.decouverts[nom] and DB.decouverts[nom].id then
        info.id = DB.decouverts[nom].id
    end
    -- Suivi profil : dernière prise (nom + date)
    DB.dernierePriseNom = nom
    DB.dernierePriseDate = date("%d/%m/%y")
    info.derniere = date("%d/%m/%y")
    if not info.premiere then info.premiere = info.derniere end
    if chasseNiveau then
        if not info.nivMax or chasseNiveau > info.nivMax then info.nivMax = chasseNiveau end
        if not info.nivMin or chasseNiveau < info.nivMin then info.nivMin = chasseNiveau end
    end
    -- Chasse sans mourir : aucune vie perdue pendant la chasse.
    -- Midnight : la vie peut être un « secret number » — arithmétique
    -- (soustraction/division) interdite, comparaisons permises. On ne
    -- soustrait donc JAMAIS : on compare la vie de fin au début.
    local viePerdue = 1 -- prudent : on suppose avoir été touché
    pcall(function()
        -- Le suivi continu (chasseVieTouchee) prime : des dégâts soignés
        -- avant la prise ne doivent pas passer pour « sans une égratignure ».
        if chasseVieTouchee then return end
        local vieFin = UnitHealth("player")
        if chasseDebutVie == nil
            or vieFin == chasseDebutVie or vieFin > chasseDebutVie then
            viePerdue = 0
        end
    end)
    if viePerdue == 0 then info.sansMourir = (info.sansMourir or 0) + 1 end
    -- Annonce IMMÉDIATE de la victoire : bannière + message au moment où
    -- la bête tombe, AVANT le détail (trophée, récoltes, points). La
    -- chasse réussie est l'événement ; le trophée n'en est que la suite.
    -- Sous contrat, seul « Contrat rempli » s'affiche (règle conservée).
    local contratRempliAnnonce = (DB.contrat == nom)
    local nomMeteoAnnonce, cleMeteoAnnonce = MeteoActuelle()
    if cleMeteoAnnonce == "rain" or cleMeteoAnnonce == "snow"
        or cleMeteoAnnonce == "firestorm" or cleMeteoAnnonce == "sandstorm" then
        nomMeteoAnnonce = L(" — sous la ") .. nomMeteoAnnonce
    else
        nomMeteoAnnonce = ""
    end
    AfficherBanniere(L("CHASSE RÉUSSIE — MISSION ACCOMPLIE"), 0.4, 1, 0.4)
    if contratRempliAnnonce then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffa0ff50Contrat rempli : " .. MHH_NomAffiche(nom) .. L(" !|r (+") .. (DB.contratPrime or 20) .. L(" points)"))
    else
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffa0ff50Chasse réussie : ") .. MHH_NomAffiche(nom) .. " !|r (" .. info.kills .. (info.kills == 1 and L(" chasse") or L(" chasses")) .. nomMeteoAnnonce .. ")")
    end
    -- La musique de chasse s'arrête à la prise : sans cet arrêt explicite,
    -- la piste de combat continuait jusqu'au relais suivant quand le kill
    -- était validé PENDANT le combat (UNIT_DIED / viseur) — REGEN_ENABLED
    -- ne la stoppait que si le joueur était déjà sorti du combat.
    MHH_ArreterMusique()
    -- Le carillon attend le fondu (1,2 s) + la coupure du canal (0,4 s)
    -- pour sonner à plein volume — il vit sur le même canal SFX.
    if DB.config.son and JouerJingleVictoire then
        if C_Timer and C_Timer.After then
            C_Timer.After(1.8, function() JouerJingleVictoire() end)
        else
            JouerJingleVictoire()
        end
    end
    -- Chronomètre : durée et record
    local duree = chasseDebutTemps and (time() - chasseDebutTemps) or nil
    if duree then
        if not info.recordMin or duree < info.recordMin then
            info.recordMin = duree
            if info.kills and info.kills > 1 then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Nouveau record : " .. math.floor(duree / 60) .. " min " .. (duree % 60) .. " s !")
            end
        end
    end
    -- Conversion « à peu près » en centimètres : la mesure est un rayon
    -- de hitbox en YARDS (1 yard = 91,44 cm) ; l'envergure estimée
    -- ≈ 2 rayons. Flaveur de carnet, pas une science exacte.
    function GabaritEnCm(t)
        if type(t) ~= "number" then return nil end
        return math.floor(t * 2 * 91.44 + 0.5)
    end
    -- Taille du gabarit façon MH : hitbox du client (UnitBoundingRadius,
    -- renvoyée en mètres) + variation aléatoire cohérente (85 %–130 %).
    -- Couronnes rares façon MH : argent dès 120 %, d'or à 127 % ; record mémorisé.
    -- Tout sous pcall : les « secret numbers » de Midnight peuvent
    -- interdire l'arithmétique sur cette valeur — l'échec est muet.
    pcall(function()
        local source = "hitbox"
        local b = UnitBoundingRadius and UnitBoundingRadius("target")
        -- Cible déjà libérée à la mort ? Repli sur la mesure prise à
        -- l'engagement (cible vivante) — le gabarit n'est plus perdu.
        if type(b) ~= "number" or b <= 0 then b = chasseRayon end
        -- Midnight : secret number → reconversion AVANT toute
        -- arithmétique (sinon la multiplication échoue en silence et
        -- la fiche reste « pas encore mesuré » pour toujours).
        b = NombreOrdinaire(b)
        -- DERNIER repli (clients Vanilla 1.12 sans UnitBoundingRadius) :
        -- estimation depuis le NIVEAU du gibier — bêtes minuscules au
        -- départ, gros gibier à haut niveau. Mesure de carnet façon MH,
        -- pas une science exacte : les records et couronnes restent
        -- comparables entre prises d'un même spécimen.
        if not b then
            local niv = NombreOrdinaire(chasseNiveau) or NombreOrdinaire(info.nivMax) or NombreOrdinaire(info.nivMin)
            -- v0.25 : derniers replis — niveau du JOUEUR puis 30 par
            -- défaut. Un gabarit estimé vaut mieux qu'aucun gabarit :
            -- « source: hitbox, rayon: nil » = fiche jamais mesurée.
            if not niv then niv = NombreOrdinaire(UnitLevel and UnitLevel("player")) end
            if not niv then niv = 30 end
            if type(niv) == "number" and niv > 0 then
                b = 0.30 + math.min(60, niv) * 0.02
                source = "estimation (niveau " .. tostring(niv) .. ")"
            end
        end
        DebugChasse("gabarit", "source : " .. source .. ", rayon : " .. tostring(b))
        if b and b > 0 then
            -- v0.24 : la BASE du spécimen (rayon avant facteur aléatoire)
            -- est mémorisée — c'est ELLE qui fixe l'échelle de la barre
            -- de gabarit, pour que la position du curseur corresponde
            -- au FACTEUR (couronnes comprises) : argent ≈ 78 % de la
            -- barre, or ≈ 93 %. Avant, la barre était construite sur
            -- les prises OBSERVÉES (min×0,85 ; record×1,30) : une prise
            -- couronnée d'argent pouvait s'afficher à 1/4 de la barre.
            info.rayonBase = b
            local facteur = 0.85 + math.random() * 0.45
            local taille = math.floor(b * facteur * 100 + 0.5) / 100
            info.taille = taille
            if not info.tailleRecord or taille > info.tailleRecord then
                info.tailleRecord = taille
            end
            if not info.tailleMin or taille < info.tailleMin then
                info.tailleMin = taille
            end
            local couronne
            if facteur >= 1.27 then couronne = "or"
            elseif facteur >= 1.20 then couronne = "argent" end
            if couronne then
                if couronne == "or" or info.couronne ~= "or" then
                    info.couronne = couronne
                end
            end
            local libelle = L("Gabarit mesuré : |cffffff00") .. taille .. L(" unités|r")
                .. L(" |cffa58b54(~") .. (GabaritEnCm and GabaritEnCm(taille) or "?")
                .. L(" cm d'envergure)|r")
            if couronne == "or" then
                ToastSucces("Interface\\Icons\\INV_Misc_MonsterClaw_04",
                    L("Mesure du gabarit"), libelle .. L(" — |cffffcc44COURONNE D'OR !|r"))
            elseif couronne == "argent" then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. libelle .. L(" — |cffc0c0c0couronne d'argent|r"))
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. libelle)
            end
        end
    end)
    -- Armes de la prise : les DEUX mains sont comptées (ambidextrie —
    -- un voleur aux deux dagues crédite chaque arme du kill). Triple
    -- source par arme : lien/id (souvent muets sur ce client), scan du
    -- tooltip, puis le NOM — la seule source fiable ici. Échec = message
    -- chat avec le nom lu (plus jamais muet) ; un bouclier en main
    -- gauche n'est PAS signalé (ce n'est pas une arme).
    do
        for _, slot in ipairs({ 16, 17 }) do -- main droite, main gauche
            local sousClasseArme = nil
            local mainsArme = nil -- v0.36 : 1 ou 2, lu sur la ligne « mains » du tooltip
            pcall(function()
                sousClasseArme = NormaliserTypeArme(sousClasseDe(GetInventoryItemLink and GetInventoryItemLink("player", slot)))
                    or NormaliserTypeArme(sousClasseDe(GetInventoryItemID and GetInventoryItemID("player", slot)))
            end)
            if not sousClasseArme and GameTooltip then
                pcall(function()
                    -- Scan de TOUTES les lignes du tooltip : la ligne du
                    -- type (« Haches », « Dagues »…) n'est pas toujours la
                    -- 2e ; « Niveau d'objet » n'est PAS un type.
                    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                    if GameTooltip.ClearLines then GameTooltip:ClearLines() end
                    GameTooltip:SetInventoryItem("player", slot)
                    local nbLig = GameTooltip:NumLines() or 0
                    local nomObjet = nil -- ligne 1 = nom de l'arme
                    for lig = 1, math.min(nbLig, 8) do
                        local fs = _G["GameTooltipTextLeft" .. lig]
                        local okTxt, txt = pcall(function() return fs and fs.GetText and fs:GetText() end)
                        if okTxt and txt and txt ~= "" then
                            if lig == 1 then nomObjet = txt end
                            -- v0.36 : la ligne « deux mains »/« une main »
                            -- du tooltip dit le port DUO ou SOLO — le nom
                            -- seul ne le dit pas (« Fendoir… » 1M ou 2M ?)
                            local basTxt = string.lower(txt)
                            if string.find(basTxt, "deux mains", 1, true) then mainsArme = 2 end
                            if string.find(basTxt, "une main", 1, true) then mainsArme = 1 end
                            if not string.find(string.lower(txt), "niveau d", 1, true) then
                                local norm = NormaliserTypeArme(txt)
                                for _, canon in ipairs(MHH_TYPES_ARMES) do
                                    if norm == canon then sousClasseArme = canon break end
                                end
                                if sousClasseArme then break end
                            end
                        end
                    end
                    if GameTooltip.Hide then GameTooltip:Hide() end
                    -- SOURCE 4 : le nom (sur ce client, AUCUNE ligne de
                    -- sous-classe — le nom est le seul indice)
                    if not sousClasseArme then
                        sousClasseArme = NomVersTypeArme(nomObjet)
                    end
                end)
            end
            -- Repli hors tooltip : nom extrait du lien (« [Dague...] »)
            if not sousClasseArme then
                pcall(function()
                    local lien = GetInventoryItemLink and GetInventoryItemLink("player", slot)
                    local nom = lien and string.match(lien, "%[(.-)%]")
                    sousClasseArme = NomVersTypeArme(nom)
                end)
            end
            -- v0.36 : le tooltip dit « deux mains » ? on bascule la
            -- famille sur sa variante 2M (une hache à deux mains n'est
            -- pas une hache à une main pour le carnet)
            if sousClasseArme and mainsArme == 2 and MHH_VARIANTES_2M[sousClasseArme] then
                sousClasseArme = MHH_VARIANTES_2M[sousClasseArme]
            end
            DB.armes = DB.armes or {}
            if sousClasseArme then
                DB.armes[sousClasseArme] = (DB.armes[sousClasseArme] or 0) + 1
            else
                -- Non reconnue ET ce n'est pas un bouclier : signaler le
                -- nom pour l'ajouter au dictionnaire
                local nomVu, bouclier = nil, false
                pcall(function()
                    local lien = GetInventoryItemLink and GetInventoryItemLink("player", slot)
                    nomVu = lien and string.match(lien, "%[(.-)%]") or nil
                    bouclier = nomVu and string.find(string.lower(nomVu), "bouclier", 1, true) ~= nil
                end)
                if nomVu and not bouclier then
                    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffa58b54Arme non identifiée à la prise : |r")
                        .. nomVu .. L(" |cffa58b54(à signaler pour l'ajouter au comptage)|r"))
                    DebugChasse("armes", L("arme non identifiée à la prise (essais GetItemInfo vides)"))
                end
            end
        end
    end
    -- Points de chasse : rare x3, bonus sans mourir, bonus de niveau
    local pts = chasseRare and 30 or 10
    if viePerdue == 0 then pts = pts + 10 end
    if chasseNiveau and chasseNiveau > UnitLevel("player") then
        pts = pts + math.min(25, (chasseNiveau - UnitLevel("player")) * 5)
    end
    -- Contrat : bonus si le monstre chassé était l'objectif du contrat actif
    local contratRempli = (DB.contrat == nom)
    if contratRempli then pts = pts + (DB.contratPrime or 20) end
    -- Cuisine : le repas préparé bonifie la prise (consommé après usage)
    if DB.repas then
        local r = CUISINE_RECETTES and CUISINE_RECETTES[DB.repas]
        if r then
            pts = pts + r.bonus
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffff7a1a" .. r.nom .. L("|r savouré : +") .. r.bonus .. L(" points de chasse !"))
        end
        DB.repas = nil
    end
    -- AMI DÉVOUÉ : un pensionnaire dévoué de cette zone encourage le
    -- chasseur depuis l'enclos — la guilde le récompense (+10% des points).
    local amiDevoue = ZoneAvecAmiDevoue(MHH_CATALOGUE[nom])
    if amiDevoue then
        local bonus = math.floor(pts * 0.1)
        if bonus > 0 then
            pts = pts + bonus
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff8800") .. amiDevoue
                .. L("|r, dévoué, applaudit votre prise depuis l'enclos : +") .. bonus .. L(" points !"))
        end
    end
    DB.points = (DB.points or 0) + pts
    local zone = MHH_CATALOGUE[nom] or GetZoneText()
    DB.zonesChassees[zone] = true
    DB.serie = DB.serie + 1
    -- Trophée façon MH (carving) : une pièce prélevée sur la dépouille —
    -- choisie par la FAMILLE de la bête (mêmes mots-clés que les icônes du
    -- carnet) et non plus par rotation de kills : un GORILLE ne lâche plus
    -- une plume (bug « Toison d'or »). Sans famille reconnue (humanoïdes,
    -- élémentaires…), rotation discrète pour garder la variété.
    local PIECES = {
        croc     = { nom = "croc",     article = "un"  },
        plume    = { nom = "plume",    article = "une" },
        ecaille  = { nom = "écaille",  article = "une" },
        carapace = { nom = "carapace", article = "une" },
        patte    = { nom = "patte",    article = "une" },
        fourrure = { nom = "fourrure", article = "une" },
    }
    local PIECES_FAMILLE = {
        { mots = { "plume", "hibou", "chouette", "serres", "aile", "hurle", "vol", "planeur", "échassier" }, piece = "plume" },
        { mots = { "tortue", "scorp", "silith", "crabe", "croquesable", "carapace" }, piece = "carapace" },
        { mots = { "araign", "veuve", "tisse" }, piece = "patte" },
        { mots = { "singe", "makr", "gorille", "ours", "urson", "toison" }, piece = "fourrure" },
        { mots = { "crocolisque", "croco", "serpent", "vipère", "boahn", "wyrm", "dragon" }, piece = "ecaille" },
    }
    local clePiece = string.lower(nom or "")
    local pieceDefaut
    for _, regle in ipairs(PIECES_FAMILLE) do
        for _, mot in ipairs(regle.mots) do
            if string.find(clePiece, mot, 1, true) then pieceDefaut = PIECES[regle.piece] break end
        end
        if pieceDefaut then break end
    end
    local rotation = { PIECES.croc, PIECES.plume, PIECES.ecaille, PIECES.patte }
    -- Carving façon MH : la dépouille offre un certain nombre de
    -- prélèvements (1 pour la bête commune, 2-3 pour un RARE), et
    -- chaque carve peut RATER (pièce abîmée, 15%). Le contenu est
    -- aléatoire par famille, la réussite n'est pas garantie.
    local nbCarves = chasseRare and (math.random(100) <= 50 and 3 or 2) or 1
    DB.trophees = DB.trophees or {}
    -- Anti-spam : une SEULE ligne de chat pour toute la dépouille —
    -- les trophées réussis groupés, les découpes manquées en rappel
    -- discret entre parenthèses. Plus de salve de messages par carve.
    local piecesOK, manques = {}, 0
    for i = 1, nbCarves do
        local piece = pieceDefaut or rotation[((info.kills or 1) + i - 2) % #rotation + 1]
        if math.random(100) <= 15 then
            manques = manques + 1
        else
            DB.trophees[piece.nom] = (DB.trophees[piece.nom] or 0) + 1
            piecesOK[#piecesOK + 1] = piece.article .. " " .. piece.nom
        end
    end
    do
        local extraits = {}
        if #piecesOK > 0 then
            extraits[#extraits + 1] = (#piecesOK == 1 and L("Trophée prélevé : ") or L("Trophées prélevés : "))
                .. table.concat(piecesOK, ", ") .. "."
        end
        if manques > 0 then
            extraits[#extraits + 1] = "|cff888888" .. manques
                .. (manques == 1 and L(" découpe manquée (le morceau s'est abîmé).") or L(" découpes manquées (les morceaux se sont abîmés).")) .. "|r"
        end
        if #extraits > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. table.concat(extraits, " "))
        end
    end
    -- Cuisine : récolte sur la dépouille (viande 40%, miel 10% sur rare)
    -- v0.121 : CAPACITÉ DU SAC — à saturation la récolte se perd : il
    -- faut cuisiner (le mini-sac affiche N/max, gris au plafond)
    if math.random(100) <= 40 then
        if (DB.viande or 0) >= (CUISINE_INGREDIENTS.viande.max or 20) then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Sac de viande plein — la prise se perd (cuisine !)."))
        else
            DB.viande = (DB.viande or 0) + 1
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Récolte : |cffff7a1a1 viande de gibier|r."))
        end
    end
    if chasseRare and math.random(100) <= 10 then
        if (DB.miel or 0) >= (CUISINE_INGREDIENTS.miel.max or 10) then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Pot de miel plein — la prise se perd (cuisine !)."))
        else
            DB.miel = (DB.miel or 0) + 1
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Récolte : |cffff7a1a1 miel sauvage|r !"))
        end
    end
    -- Succès « Imbattable » : ≤ 25% de vie perdue. Impossible à calculer
    -- avec des « secret numbers » (division interdite) : on le débloque
    -- seulement si aucune vie n'a été perdue (comparaisons pures).
    local viePerdueNulle = (viePerdue == 0)

    -- Succès
    DebloquerSucces("premiere")
    local total = nbChasses()
    if total >= 10 then DebloquerSucces("veteran") end
    if total >= 25 then DebloquerSucces("accompli") end
    if total >= 100 then DebloquerSucces("legende") end
    if nbCatalogues() >= 20 then DebloquerSucces("naturaliste") end
    if nbCatalogues() >= 50 then DebloquerSucces("zoologue") end
    if nbDecouverts() >= 5 then DebloquerSucces("explorateur") end
    if DB.serie >= 5 then DebloquerSucces("serie5") end
    if DB.serie >= 10 then DebloquerSucces("serie10") end
    local nbZones = 0
    for _ in pairs(DB.zonesChassees) do nbZones = nbZones + 1 end
    if nbZones >= 10 then DebloquerSucces("globe") end
    local heure = tonumber(date("%H"))
    if heure >= 22 or heure < 6 then DebloquerSucces("nocturne") end
    if viePerdue == 0 then DebloquerSucces("intact") end
    if viePerdueNulle then DebloquerSucces("imbattable") end
    local nivJoueur = UnitLevel("player")
    if chasseNiveau and chasseNiveau >= nivJoueur then DebloquerSucces("grandgibier") end
    if chasseNiveau and chasseNiveau > nivJoueur then DebloquerSucces("couteau") end
    if nom == "Rotheap" then DebloquerSucces("rotheap") end
    -- Chasse au piège : monstre tué alors qu'il était pris dans un piège
    if chassePiegee then DebloquerSucces("piege") end
    -- Capture SIMPLIFIÉE (v0.64, pour la sortie) : tout spécimen
    -- de l'enclos tué pendant une chasse est capturé — plus de
    -- condition piège/CC (fragile, et excluait la plupart des
    -- classes). La détection d'aura reste pour le succès chasseur.
    -- v0.121 : RÉSOLUTION DE GRAPHIES — le nom vu en jeu peut différer
    -- de la clé du spécimen (« Snort la Moqueuse » vs « Snort le
    -- Moqueur ») : on capture sous la clé CANONIQUE, jamais sous la
    -- graphie du serveur (enclos, sprites et fiche restent alignés).
    local cleSpec = (MHH_SpecimenDe and MHH_SpecimenDe(nom)) or (MHH_SPECIMENS[nom] and nom)
    if cleSpec then
        DB.menagerie = DB.menagerie or {}
        local m = DB.menagerie[cleSpec]
        -- v0.119h : LIMITE PAR ENCLOS — le régisseur refuse la bête
        -- de trop : il faut d'abord en relâcher une (fiche pensionnaire,
        -- bouton Relâcher).
        local enclosPlein = false
        if not m and MHH_CAPACITE_ENCLOS and MHH_ENCLOS_DU_SPECIMEN then
            local cleEnc = MHH_ENCLOS_DU_SPECIMEN[cleSpec]
            local cap = (cleEnc and MHH_CAPACITE_ENCLOS[cleEnc]) or 0
            if cap > 0 then
                local nbEnc = 0
                for nomE in pairs(DB.menagerie) do
                    if MHH_ENCLOS_DU_SPECIMEN[nomE] == cleEnc then
                        nbEnc = nbEnc + 1
                    end
                end
                if nbEnc >= cap then
                    enclosPlein = true
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r L'enclos ("
                        .. (cleEnc or "?") .. ") est plein (" .. nbEnc .. "/"
                        .. cap .. ") — rel\195\162che un pensionnaire avant d'en capturer un autre.")
                end
            end
        end
        if not m and not enclosPlein then
            DB.menagerie[cleSpec] = { capture = time(), nourri = time() }
            -- Grande annonce dorée : la capture est un moment MH, pas un
            -- simple message discret. Bandeau + toast deux lignes.
            AfficherBanniere(L("SPÉCIMEN CAPTURÉ !"), 0.95, 0.78, 0.25)
            ToastSucces("Interface\\Icons\\Ability_Hunter_BeastTaming",
                L("Spécimen capturé"), MHH_NomAffiche(cleSpec) .. L(" rejoint l'enclos (Ménagerie)."))
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff7a1aSpécimen captéré !|r ")
                .. MHH_NomAffiche(cleSpec) .. L(" est transféré dans l'enclos (onglet Ménagerie)."))
            -- v0.119 : succès ÉLEVEUR — 5 pensionnaires en enclos
            local nbPensionnaires = 0
            for _ in pairs(DB.menagerie) do nbPensionnaires = nbPensionnaires + 1 end
            if nbPensionnaires >= 5 then DebloquerSucces("eleveur") end
        elseif m then
            -- déjà capturé : le retour au bercail le remet d'aplomb
            m.nourri = time()
        end
    end
    -- Succès météo (C_Weather, client Forever) : la prise est signée
    -- sous les éléments
    local _, cleMeteoPrise = MeteoActuelle()
    if cleMeteoPrise == "rain" then DebloquerSucces("pluie") end
    if cleMeteoPrise == "firestorm" then DebloquerSucces("feu") end
    if cleMeteoPrise == "snow" then DebloquerSucces("neige") end
    -- Rumeurs de guilde (missions cachées) : condition bizarre vérifiée
    -- à la prise — dague, minuit, neige, pugilat… selon la rumeur active
    VerifierMissionsCachees(nom, {
        viePerdue = viePerdue,
        meteo = cleMeteoPrise,
        niveau = chasseNiveau,
        niveauJoueur = (UnitLevel and UnitLevel("player") or nil),
        heure = HeureJeu(),
    })
    local h, fm, tk = (DB.chasses["Humar le Seigneur hautain"] or DB.chasses["Humar le Fier"]),
        (DB.chasses["Flinkmähne"] or DB.chasses["Vif-Crinière"]
            or DB.chasses["Vif-crins"] or DB.chasses["Vif-Crins"]),
        DB.chasses["Takk le Bondisseur"]
    if h and fm and tk and h.kills > 0 and fm.kills > 0 and tk.kills > 0 then
        DebloquerSucces("brachland")
    end
    chasseActive = nil
    chasseVieTouchee = false
    chasseSuspendue = nil -- prise : plus de reprise possible
    if contratRempli then
        DB.contrat = nil
        -- Historique des primes (page Contrats) — prime réelle du contrat
        -- (cible du jour +20, offre du jour +10, 20 par défaut/anciennes)
        DB.primesGagnees = (DB.primesGagnees or 0) + (DB.contratPrime or 20)
        DB.contratHistorique = DB.contratHistorique or {}
        table.insert(DB.contratHistorique, 1, { nom = nom, date = date("%d/%m/%y"), prime = DB.contratPrime or 20 })
        if #DB.contratHistorique > 20 then table.remove(DB.contratHistorique) end
        -- (message « Contrat rempli » déjà affiché en tête de victoire)
        ToastSucces("Interface\\Icons\\INV_Misc_Note_01", L("Contrat rempli"), nom)
    end
    MettreAJourIndicateur()
    -- Montée de rang de chasseur
    local nouvelIdx, nomRang = RangGuilde(DB.points)
    if nouvelIdx > (DB.rangActuel or 1) then
        DB.rangActuel = nouvelIdx
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Nouveau rang de chasseur : |cffffff00") .. nomRang .. "|r ! (+" .. pts .. L(" points)"))
        -- Promotion : affichee comme un succes — parchemin custom, la
        -- desc « Nouveau rang : X » est une phrase (retour utilisateur)
        ToastSucces("Interface\\Common\\ReputationStar", L("Promotion de guilde"), L("Nouveau rang : ") .. nomRang, nil, "succes")
        -- Sommet atteint : la Blackrock orchestrée remplace la fanfare —
        -- elle ne jouera qu'ici, à ce moment précis. Une seule fois.
        if MHH_RANGS and nouvelIdx == #MHH_RANGS then
            MHH_JouerMusique("promotion", MHH_PISTE_RANG_MAX.d, tostring(MHH_PISTE_RANG_MAX.id))
        else
            MHH_JouerMusique("promotion", 45)
        end
    end
end

-- v0.35 : mise à genou du chasseur quand le gibier est perdu (fuite,
-- trace perdue, échec) — théâtral façon MH, mais SANS perdre la chasse :
-- la fuite reste une suspension reprise au re-ciblage, le contrat
-- continue. DoEmote peut être protégé sur ce client : pcall, et si
-- l'émote échoue on tente « faint » en repli (l'ancien comportement).
local function EmoteDeuilChasseur()
    if not (DB and DB.config and DB.config.emotePerdu ~= false) then return end
    if not pcall(DoEmote, "KNEEL") then pcall(DoEmote, "faint") end
end

local function FinChasseEchec(mort)
    -- Échec aussi si la chasse venait d'être suspendue (mort du chasseur :
    -- la cible se perd AVANT que PLAYER_DEAD n'arrive — sinon la suspension
    -- survivait à la mort et se « reprenait » au cimetière)
    if not chasseActive and not chasseSuspendue then return end
    local nom = chasseActive or (chasseSuspendue and chasseSuspendue.nom) or "?"
    DebugChasse("echec", nom)
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff5050Chasse échouée : ") .. MHH_NomAffiche(nom) .. "|r")
    -- Chasseur mort : PAS de bannière — elle apparaissait PAR-DESSUS
    -- l'encart de libération d'esprit du client (message chat suffit).
    -- NB : le flag UnitIsDeadOrGhost n'est PAS encore levé quand
    -- PLAYER_DEAD/REGEN arrivent sur ce client — les appelants
    -- contextes-mort passent donc « mort » explicitement.
    local okMortCh, mortCh = pcall(function()
        return UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
    end)
    if not (mort or (okMortCh and mortCh)) then
        AfficherBanniere(L("CHASSE ÉCHOUÉE"), 1, 0.3, 0.3)
    end
    -- Le chasseur s'écroule, façon MH quand le monstre s'échappe :
    -- emote de perte de connaissance si le client la connaît, sinon rien
    EmoteDeuilChasseur() -- v0.35 : à genou (KNEEL), repli faint
    -- Son d'échec différé : il vit sur le canal SFX, comme la piste de
    -- chasse — on attend la fin du fondu (1,2 s) + la coupure (0,4 s)
    -- pour qu'il sonne à plein volume. Fichier 620 : le SoundKit 845
    -- est muet sur ce client.
    if DB.config.son and JouerJingleEchec then
        if C_Timer and C_Timer.After then
            C_Timer.After(1.8, function() JouerJingleEchec() end)
        else
            JouerJingleEchec()
        end
    elseif DB.config.son then
        JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_FAILED or 845)
    end
    MHH_ArreterMusique() -- stoppe la musique et rend le décor sonore au jeu
    -- Mort du chasseur : on dégage l'écran — l'annonce de région (grand
    -- encart sombre en haut, visible ~5,5 s après un changement de zone)
    -- et la bannière ne doivent PAS traîner derrière la fenêtre de
    -- libération d'esprit du client.
    if mort then
        if annonceZoneFrame then
            annonceZoneFrame:SetAlpha(0)
            annonceZoneFrame:Hide()
        end
        banniere:Hide()
    end
    chasseActive = nil
    chasseVieTouchee = false
    chasseSuspendue = nil -- échec : plus de reprise possible
    DB.serie = 0
    MettreAJourIndicateur()
end

-- Suspend une chasse (cible perdue hors combat) : le chrono et l'état
-- sont mémorisés — re-cibler la bête la REPREND. NB : n'annule la chasse
-- active QUE si c'est encore elle (une autre peut avoir démarré).
local function SuspendreChasse(nom, etat)
    AnnoncerSuspension(nom, "|cffffd100[MH Hunt]|r |cffa58b54La trace de " .. nom .. L(" se perd…|r Chasse suspendue — re-ciblez-la pour reprendre."))
    EmoteDeuilChasseur() -- v0.35 : le chasseur tombe à genou
    chasseSuspendue = {
        nom = nom,
        debutTemps = etat.debutTemps,
        debutVie = etat.debutVie,
        niveau = etat.niveau,
        rare = etat.rare,
        piegee = etat.piegee,
        vieTouchee = etat.vieTouchee,
        quand = time(),
    }
    if chasseActive == nom then
        chasseActive = nil
        MHH_ArreterMusique() -- libère l'état musique (relance possible)
    end
    MettreAJourIndicateur()
end

-- Carte de la zone : l'addon apprend « nom de zone -> carte » au fil des
-- voyages (pas de table d'IDs codée en dur, fiable sur tous les clients)
local function EnregistrerCarteZone()
    if not DB then return end
    local zone = GetZoneText() or ""
    if zone == "" or not C_Map or not C_Map.GetBestMapForUnit then return end
    pcall(function()
        local id = C_Map.GetBestMapForUnit("player")
        if id then
            if not DB.cartes then DB.cartes = {} end
            DB.cartes[zone] = id
        end
    end)
end

-- Repérage : à chaque début de chasse, on note où la bête a été vue
-- (carte + position). « Voir sur la carte » pose ensuite un marqueur
-- (waypoint rond) sur ce point — idée de l'endroit où chercher.
function EnregistrerReperee(nom) -- globale : DebutChasse est définie avant
    pcall(function()
        if not C_Map or not C_Map.GetBestMapForUnit or not DB then return end
        local id = C_Map.GetBestMapForUnit("player")
        if not id then return end
        local x, y
        if C_Map.GetPlayerMapPosition then
            -- Selon les clients : (mapID, unit) ou (unit, mapID)
            local p = C_Map.GetPlayerMapPosition(id, "player")
            if p and type(p) == "table" then
                if p.GetXY then x, y = p:GetXY() else x, y = p.x, p.y end
            elseif p then
                p = C_Map.GetPlayerMapPosition("player", id)
                if p then
                    if p.GetXY then x, y = p:GetXY() else x, y = p.x, p.y end
                end
            end
        end
        if x and y and x > 0 and y > 0 then
            DB.reperees = DB.reperees or {}
            DB.reperees[nom] = { map = id, x = x, y = y, quand = time() }
        end
    end)
end

-- Résout l'uiMapID d'une zone : d'abord les zones déjà visitées
-- (DB.cartes), sinon recherche par nom dans l'arbre des continents —
-- le carnet peut ainsi montrer un habitat jamais foulé.
local function TrouverCarteZone(zone)
    if not zone or zone == "?" then return nil end
    DB.cartes = DB.cartes or {}
    if DB.cartes[zone] then return DB.cartes[zone] end
    if DB.cartesInconnues and DB.cartesInconnues[zone] then return nil end
    local id
    pcall(function()
        if not C_Map or not C_Map.GetMapChildrenInfo then return end
        -- 13 = Royaumes de l'Est, 14 = Kalimdor (système C_Map)
        for _, cont in ipairs({ 13, 14 }) do
            local enfants = C_Map.GetMapChildrenInfo(cont)
            if enfants then
                for _, m in ipairs(enfants) do
                    if m and m.name == zone then id = m.mapID break end
                end
            end
            if id then break end
        end
    end)
    if id then
        DB.cartes[zone] = id
    else
        -- négatif en cache : pas de re-scan à chaque clic sur la fiche
        DB.cartesInconnues = DB.cartesInconnues or {}
        DB.cartesInconnues[zone] = true
    end
    return id
end

-- Cercle de spawn sur la carte du monde : anneau doré en « ping sonar »
-- (se dilate et s'estompe, en rythme avec le son MAP_PING). Rien de tout
-- cela n'est garanti selon le client : chaque accès est sous pcall, et
-- un échec s'explique dans /hunt debug au lieu d'être invisible.
-- GLOBALES préfixées MHH_ : limite des 200 locales du chunk principal
-- (LUA_WARNING v0.62) — même sémantique, portée globale préfixée
local function CacherCercleCarte()
    if MHH_timerCercle then MHH_timerCercle:Cancel() MHH_timerCercle = nil end
    if MHH_cercleTicker then MHH_cercleTicker:Cancel() MHH_cercleTicker = nil end
    if MHH_cercleCarte then MHH_cercleCarte:Hide() end
end
local function PlacerCercleCarte(x, y)
    local okCercle, errCercle = pcall(function()
        local canvas = nil
        if WorldMapFrame then
            -- Canevas moderne (clients rétro-portés) : ScrollContainer.Child
            local sc = WorldMapFrame.ScrollContainer
            canvas = sc and (sc.Child or (sc.GetCanvas and sc:GetCanvas()))
            if not canvas and WorldMapFrame.GetCanvas then canvas = WorldMapFrame:GetCanvas() end
            if not canvas and WorldMapFrame.MapCanvas then canvas = WorldMapFrame.MapCanvas end
            -- UI carte « classique » 1.12 : tout vit dans WorldMapButton
            if not canvas and WorldMapButton then canvas = WorldMapButton end
        end
        if not canvas then
            DebugChasse("carte", "cercle : canevas introuvable (ni ScrollContainer, ni WorldMapButton)")
            return
        end
        if not MHH_cercleCarte then
            MHH_cercleCarte = CreateFrame("Frame", nil, canvas)
            MHH_cercleCarte:SetSize(96, 96)
            -- AU-DESSUS de l'art de la carte : sans strate haute, le disque
            -- reste DERRIÈRE la texture de la carte — invisible. C'est le
            -- probable coupable du ping jamais vu (le son jouait, le
            -- cercle se cachait derrière la peinture).
            pcall(function() MHH_cercleCarte:SetFrameStrata("HIGH") end)
            pcall(function() MHH_cercleCarte:SetFrameLevel(20) end)
            -- Zone ronde lisible sur tous les clients : un disque
            -- translucide + un anneau de points dessinés en textures
            -- (le MiniMap-TrackingBorder seul peut ne pas s'afficher)
            local fond = MHH_cercleCarte:CreateTexture(nil, "BACKGROUND")
            fond:SetAllPoints()
            fond:SetColorTexture(1, 0.82, 0.25, 0.13)
            for i = 0, 23 do
                local a = i * math.pi / 12
                local pt = MHH_cercleCarte:CreateTexture(nil, "OVERLAY")
                pt:SetSize(6, 6)
                pt:SetPoint("CENTER", math.cos(a) * 42, math.sin(a) * 42)
                pt:SetColorTexture(1, 0.75, 0.15, 0.95)
            end
            local t = MHH_cercleCarte:CreateTexture(nil, "OVERLAY")
            t:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            t:SetAllPoints()
            MHH_cercleCarte.texture = t
            -- le cercle disparaît avec la carte
            WorldMapFrame:HookScript("OnHide", CacherCercleCarte)
        end
        -- position en fraction de la carte (0-1) → pixels du canevas
        MHH_cercleCarte.fracX, MHH_cercleCarte.fracY = x, y
        local function RepositionnerCercle()
            if not MHH_cercleCarte or not MHH_cercleCarte:IsShown() then return end
            local c = canvas
            if not c or not c.GetWidth or c:GetWidth() <= 0 then return end
            MHH_cercleCarte:ClearAllPoints()
            MHH_cercleCarte:SetPoint("CENTER", c, "TOPLEFT",
                (MHH_cercleCarte.fracX or 0) * c:GetWidth(), (MHH_cercleCarte.fracY or 0) * c:GetHeight())
        end
        RepositionnerCercle()
        -- v0.58 : DIAGNOSTIC — identifier le canevas utilisé (nom + taille)
        -- et la position pixel visée : si le ping retombe sur le joueur,
        -- on saura si le canevas est l'art complet ou un sous-élément.
        DebugChasse("carte", "cercle : canevas=" .. tostring(canvas.GetName and canvas:GetName() or "?")
            .. " taille=" .. math.floor(canvas:GetWidth() + 0.5) .. "x" .. math.floor(canvas:GetHeight() + 0.5)
            .. " fraction=(" .. string.format("%.2f", x) .. "," .. string.format("%.2f", y) .. ")")
        MHH_cercleCarte:SetAlpha(1)
        MHH_cercleCarte:SetScale(1)
        MHH_cercleCarte:Show()
        -- Animation « ping sonar » : l'anneau se DILATE depuis le point
        -- tout en s'estompant, puis repart — le mouvement qu'on attend
        -- d'un ping, maintenant qu'on l'entend aussi (cycle d'une seconde).
        -- v0.58 : toutes les 0,2 s le cercle se RE-PLACE depuis ses
        -- fractions : si le canevas change de taille ou que la carte
        -- finit de se charger en retard, la position se corrige seule.
        if MHH_cercleTicker then MHH_cercleTicker:Cancel() end
        local phase = 0
        local tick = 0
        MHH_cercleTicker = C_Timer.NewTicker(0.04, function()
            if not MHH_cercleCarte or not MHH_cercleCarte:IsShown() then return end
            tick = tick + 1
            if tick % 5 == 0 then RepositionnerCercle() end
            phase = phase + 0.025
            if phase >= 1 then phase = 0 end
            MHH_cercleCarte:SetScale(1 + phase * 0.5) -- se dilate : 1 -> 1,5
            MHH_cercleCarte:SetAlpha(1 - phase * 0.7)  -- s'estompe : 1 -> 0,3
        end)
    end)
    if not okCercle and errCercle then
        DebugChasse("carte", "cercle : " .. tostring(errCercle))
    end
end

local function VoirSurCarte(zone, nom)
    if not zone or zone == "?" then return end
    local idCarte = TrouverCarteZone(zone)
    if not idCarte then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Carte introuvable pour « " .. zone .. L(" »."))
        return
    end
    if WorldMapFrame and WorldMapFrame.SetMapID then
        pcall(function()
            ShowUIPanel(WorldMapFrame)
            WorldMapFrame:SetMapID(idCarte)
            CacherCercleCarte()
            -- Point à marquer : le SPAWN du data file (MHH_COORDS) prime —
            -- le « repérage » (position du joueur au début de la chasse)
            -- n'est qu'un repli : c'est là où NOUS étions, pas la bête.
            -- Coordonnées 0-100 → 0-1.
            local point
            if nom and MHH_COORDS[nom] then
                point = { x = MHH_COORDS[nom][1] / 100, y = MHH_COORDS[nom][2] / 100, source = "spawn" }
            elseif nom and DB.reperees and DB.reperees[nom]
                and DB.reperees[nom].map == idCarte then
                point = { x = DB.reperees[nom].x, y = DB.reperees[nom].y, source = "repérage" }
            end
            if not point then
                -- Jamais de silence : sans repère connu, on le dit —
                -- le chasseur comprend que le mob n'a pas de spawn au carnet
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Aucun repère pour |cffffff00") .. (nom or "?")
                    .. L("|r : ni spawn au carnet, ni repérage en direct. Chassez-la pour la localiser."))
            else
                DebugChasse("carte", (nom or "?") .. " → " .. point.source
                    .. " x=" .. string.format("%.2f", point.x) .. " y=" .. string.format("%.2f", point.y))
                if C_Map and C_Map.SetUserWaypoint then
                    if C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
                    -- v0.57 : la flèche de minimap tombait sur le JOUEUR
                    -- quand le waypoint vit sur la carte du GIBIER et que
                    -- le chasseur est dans une AUTRE zone : le supertrack
                    -- du client ne traduit pas une position entre cartes.
                    -- On traduit donc les coordonnées vers la carte
                    -- courante du joueur (position monde au milieu) quand
                    -- les API existent — sinon comportement inchangé.
                    local wId, wx, wy = idCarte, point.x, point.y
                    local traduit = false
                    pcall(function()
                        if not C_Map.GetBestMapForUnit then return end
                        local carteActuelle = C_Map.GetBestMapForUnit("player")
                        if carteActuelle and carteActuelle ~= idCarte
                            and C_Map.GetWorldPosFromMapCoords
                            and C_Map.GetMapCoordsFromWorldPos then
                            local wposX, wposY, contId = C_Map.GetWorldPosFromMapCoords(idCarte, point.x, point.y)
                            if wposX then
                                local cx, cy = C_Map.GetMapCoordsFromWorldPos(contId, wposX, wposY, carteActuelle)
                                if cx and cy and cx >= 0 and cx <= 1 and cy >= 0 and cy <= 1 then
                                    wId, wx, wy = carteActuelle, cx, cy
                                    traduit = true
                                end
                            end
                        end
                    end)
                    if not traduit and DB.config.debug then
                        DebugChasse("carte", "traduction inter-carte indisponible : flèche minimap possiblement sur le joueur")
                    end
                    C_Map.SetUserWaypoint({ uiMapID = wId, position = { x = wx, y = wy } })
                    -- v0.61 : AddSuperTrackedUserWaypoint RETIRÉ — le debug
                    -- (v0.60) a montré des données JUSTES (waypoint relu au
                    -- bon endroit, carte correcte) mais le marqueur du
                    -- client se dessinait SUR LE JOUEUR : son rendu est
                    -- buggé sur ce client rétro-porté, rien à corriger de
                    -- notre côté. Le repère visuel est notre cercle sonar
                    -- (juste, lui) + le pin du waypoint (minimap).
                    -- Pour le réactiver un jour : pcall(function()
                    --   if C_SuperTrack and C_SuperTrack.AddSuperTrackedUserWaypoint then
                    --     C_SuperTrack.AddSuperTrackedUserWaypoint() end end)
                end
                -- Cercle placé une frame plus tard : juste après SetMapID le
                -- canvas n'a pas toujours encore ses nouvelles dimensions —
                -- le marqueur atterrissait alors au mauvais endroit
                if MHH_timerCercle then MHH_timerCercle:Cancel() end
                local px, py = point.x, point.y
                MHH_timerCercle = C_Timer.After(0.05, function()
                    PlacerCercleCarte(px, py)
                end)
                -- v0.58 : DIAGNOSTIC en différé — quelle carte est RÉELLEMENT
                -- affichée après le clic, et qu'a retenu le client du
                -- waypoint ? (le joueur voit le ping au mauvais endroit :
                -- ces lignes départagent carte-non-changée vs canevas
                -- trompeur vs waypoint ignoré)
                C_Timer.After(0.2, function()
                    pcall(function()
                        if WorldMapFrame and WorldMapFrame.GetMapID then
                            DebugChasse("carte", "affichée=" .. tostring(WorldMapFrame:GetMapID())
                                .. " attendue=" .. tostring(idCarte))
                        end
                    end)
                    pcall(function()
                        if C_Map and C_Map.GetUserWaypoint then
                            local wp = C_Map.GetUserWaypoint()
                            if wp then
                                local wx = wp.position and (wp.position.x or (wp.position.GetXY and select(1, wp.position:GetXY())) or "?")
                                local wy = wp.position and (wp.position.y or (wp.position.GetXY and select(2, wp.position:GetXY())) or "?")
                                DebugChasse("carte", "waypoint lu: map=" .. tostring(wp.uiMapID)
                                    .. " pos=" .. tostring(wx) .. "," .. tostring(wy))
                            else
                                DebugChasse("carte", "waypoint lu: NIL (SetUserWaypoint ignoré par ce client ?)")
                            end
                        end
                    end)
                end)
                -- Ping sonore du client : le point se repère à l'oreille
                -- sans chercher le marqueur des yeux (MAP_PING ~ 5274)
                if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.MAP_PING or 5274) end
                local srcTxt = point.source == "spawn"
                    and L("spawn du carnet") or L("repérage : lieu de votre dernière prise de cette bête — pas de spawn au carnet")
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffffff00" .. nom
                    .. L("|r marqué sur la carte à ") .. string.format("%.0f, %.0f", point.x * 100, point.y * 100)
                    .. L(" (") .. srcTxt .. L(") — clic droit sur la minimap pour supprimer."))
            end
        end)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Carte non disponible sur ce client.")
    end
end

-- ================= MUSIQUES D'AMBiance =================
-- Pistes par défaut = fichiers du jeu ; pistes custom = addon MHAmbiance
-- (tout ce qui n'est pas libre de droits y sera stocké) :
--   MHAmbiance/Sounds/promotion.mp3  = montée de rang (ex. Toward unseen horizons)
--   MHAmbiance/Sounds/combat.mp3     = combat de chasse
--   MHAmbiance/Sounds/traque.mp3     = entrée dans la zone du contrat
-- Sélection via /hunt musique off|wow|custom. NB : PlayMusic boucle
-- jusqu'à StopMusic ; chaque piste a donc une durée ou un événement d'arrêt.
MHH_MUSIQUES = {
    promotion = {
        wow = "Sound\\Music\\GlueScreenMusic\\wow_main_theme.mp3",
        custom = "Interface\\AddOns\\MHAmbiance\\Sounds\\promotion.mp3",
    },
    combat = {
        -- En mode "wow" : tirage dans une banque selon la menace (voir plus bas)
        custom = "Interface\\AddOns\\MHAmbiance\\Sounds\\combat.mp3",
    },
    traque = {
        -- En mode "wow" : tirage dans PISTES_CHASE
        custom = "Interface\\AddOns\\MHAmbiance\\Sounds\\traque.mp3",
    },
}

-- Banques de pistes testées en jeu (/hunt test son <id>) : id SoundKit +
-- durée mesurée en secondes. La durée sert au REMPLACEMENT automatique :
-- si le combat dure plus longtemps que la piste, on enchaîne sur une autre
-- (variation au lieu de boucle). Durée inconnue = joue une fois.
MHH_PISTES_COMBAT_EPIQUE = {
    { id = 1080514, d = 162 }, -- épique
    { id = 7690551, d = 177 }, -- épique
    { id = 2146583, d = 163 }, -- épique
    { id = 2143540, d = 137 }, -- épique mais pas trop
    { id = 1067561, d = 126 }, -- épique, mines
    { id = 3850487, d = 112 }, -- sombre épique
    { id = 3850493, d = 110 }, -- suite de la précédente
    { id = 1064170, d = 153 }, -- épique Warsong/Highmaul
    { id = 2143525, d = 80 },  -- épique horde
    { id = 1067075 },          -- gros mob méchant (suit en 1067076)
    { id = 1067076 },
    { id = 1067044 },           -- épique
    { id = 53225, d = 60 },     -- battle01 (SoundKit vanilla)
}
MHH_PISTES_COMBAT_NORMAL = {
    { id = 2146581, d = 163 }, -- normal, un poil épique
    { id = 4872464, d = 123 }, -- plutôt dur, pas trop épique
    { id = 4880363, d = 136 }, -- standard
    { id = 4880361, d = 106 }, -- standard, touche tauren
    { id = 441708, d = 80 },  -- standard, elfes de la nuit
    { id = 1067077, d = 101 }, -- normal/épique
    { id = 7690557, d = 132 }, -- sombre/normal
    { id = 1080417, d = 79 },  -- bataille normale (tambours/enclume)
    { id = 6074903, d = 50 },  -- bataille courte
    { id = 642230, d = 88 },   -- combat inquiet — insectes
    { id = 53687, d = 60 },    -- pvp4, entre-deux
}
MHH_PISTES_CHASE = {
    { id = 4872468, d = 133 }, -- chase, mob plutôt fort
    { id = 4880369, d = 115 }, -- chase
    { id = 4880367, d = 100 }, -- chase
    { id = 4423112, d = 132 }, -- chase Celestial
    { id = 441699, d = 90 },  -- chase tambours/flûte
    { id = 1080417, d = 139 }, -- chase tambours/enclume
    { id = 53230, d = 62 },   -- chase sombre (battle06)
    { id = 53229, d = 60 },    -- battle05 (traque de zone)
}
-- PISTE_RANG_MAX (Blackrock orchestrée) : déclarée près de RANGS, plus haut —
-- elle y joue uniquement à la promotion du dernier rang.
local musiqueEtat = nil -- "traque" | "combat" | "promotion" | nil
local cibleJourToastMontre = false -- le toast cible du jour : 1x par session
local musiqueTimer = nil
local musiqueBanque = nil -- banque de combat en cours (relance auto)
local dernierePiste = nil -- anti-répétition immédiate
local musiqueHandle = nil -- si le client renvoie un handle : coupure possible
local musiqueFadeEnCours = false -- fondu de sortie actif : aucune nouvelle
-- piste ne doit démarrer pendant lui (sinon l'ancienne fichier continue
-- en doublon : le scan de proximité relance la traque MÊME chasseur mort)
-- Tempo avant la musique de combat : le jingle « En chasse » doit finir
-- seul (pas de cacophonie). Un seul timer pendante à la fois.
local timerMusiqueCombat = nil
-- Battement de la traque : petit silence après le jingle « En chasse » /
-- le rugissement de contrat, pour que la piste s'installe APRÈS lui.
local timerBattementTraque = nil

-- Son environnant : pendant nos pistes (traque, combat, promotion), la
-- musique et l'ambiance du jeu sont étouffées (sinon cacophonie — PlaySoundFile
-- passe par le canal SFX et ne coupe rien) puis restaurées à l'arrêt.
local sonAmbiantCoupe = false
local sonAmbiantAvant = { 1, 1 }
local function CouperSonAmbiant()
    if sonAmbiantCoupe then return end
    pcall(function()
        -- Ne JAMAIS mémoriser un 0 comme « valeur d'avant » : si le mute a
        -- persisté dans la config du client (déconnexion pendant une piste),
        -- on ne doit pas le retenir comme état souhaité par le joueur.
        sonAmbiantAvant = {
            (tonumber(GetCVar("Sound_EnableMusic")) or 1) > 0 and 1 or 0,
            (tonumber(GetCVar("Sound_EnableAmbience")) or 1) > 0 and 1 or 0,
        }
        -- Si le joueur a déjà la musique coupée volontairement, on ne touche
        -- à rien : rien à restaurer, pas de risque de lui la coller.
        if sonAmbiantAvant[1] == 0 and sonAmbiantAvant[2] == 0 then return end
        SetCVar("Sound_EnableMusic", 0)
        SetCVar("Sound_EnableAmbience", 0)
        sonAmbiantCoupe = true
    end)
end
local function RestaurerSonAmbiant()
    if not sonAmbiantCoupe then return end
    pcall(function()
        SetCVar("Sound_EnableMusic", sonAmbiantAvant[1])
        SetCVar("Sound_EnableAmbience", sonAmbiantAvant[2])
    end)
    sonAmbiantCoupe = false
end

MHH_ArreterMusique = function()
    local etatAuStop = musiqueEtat
    musiqueEtat = nil
    if timerMusiqueCombat then pcall(function() timerMusiqueCombat:Cancel() end) timerMusiqueCombat = nil end
    if timerBattementTraque then pcall(function() timerBattementTraque:Cancel() end) timerBattementTraque = nil end
    if musiqueTimer then pcall(function() musiqueTimer:Cancel() end) musiqueTimer = nil end
    -- Le décor sonore du jeu revient (musique + ambiance restaurées)
    RestaurerSonAmbiant()
    -- Coupure franche : UNIQUEMENT en repli (client sans C_Timer, où le
    -- fondu de sortie ne peut pas tourner). Avec C_Timer, on laisse la
    -- piste vivante et le FONDU DE SORTIE ci-dessous l'emporte en douceur
    -- (StopSound marchait trop bien : la piste mourait avant le fondu,
    -- et la fin de chasse s'entendait comme un arrêt net, brutal).
    local fonduDispo = (etatAuStop and C_Timer and C_Timer.After) and true or false
    if musiqueHandle and not fonduDispo then
        pcall(function()
            if type(musiqueHandle) == "table" then
                if musiqueHandle.FadeOut then musiqueHandle:FadeOut(1000)
                elseif musiqueHandle.Stop then musiqueHandle:Stop() end
            else
                -- Handle numérique : l'arrêt passe par une API globale.
                -- On les essaie toutes — chaque client custom expose la
                -- sienne (StopSound retail, C_Sound.StopSound, etc.).
                if StopSound then StopSound(musiqueHandle) end
                if C_Sound and C_Sound.StopSound then C_Sound.StopSound(musiqueHandle) end
                if C_Sound and C_Sound.StopSoundFile then C_Sound.StopSoundFile(musiqueHandle) end
                if C_Sound and C_Sound.FadeoutSound then C_Sound.FadeoutSound(musiqueHandle, 1000) end
                if C_Sound and C_Sound.FadeOutSound then C_Sound.FadeOutSound(musiqueHandle, 1000) end
                -- Certains clients prennent le CHEMIN en argument :
                if C_Sound and C_Sound.StopSound then C_Sound.StopSound(tostring(musiqueHandle)) end
            end
        end)
        musiqueHandle = nil
    end
    -- FONDU DE SORTIE : la piste de combat vit sur le canal SFX de ce
    -- client (confirmé par /hunt test canal — aucune API d'arrêt ne la
    -- coupe). On ramp le volume SFX vers 0 sur ~1,6 s, en COURBE DOUCE
    -- (carrée : imperceptible au début, elle s'incurve à la fin — un
    -- fondu linéaire par paliers sonnait comme un escalier). Puis on
    -- coupe le canal 0,4 s : un son de fichier ne reprend jamais après
    -- un mute (0,15 s laissait la piste REPRENDRE à la restauration —
    -- testé), la piste est définitivement morte. Volume et canal sont
    -- ensuite restaurés. Abandonné si une nouvelle piste démarre pendant
    -- le fondu (le volume est alors rendu intact).
    if etatAuStop and C_Timer and C_Timer.After then
        pcall(function()
            local avantEnable = tonumber(GetCVar("Sound_EnableSFX"))
            if avantEnable == 0 then return end -- le joueur coupe déjà son SFX
            local vol = tonumber(GetCVar("Sound_SFXVolume"))
            if vol == nil then vol = tonumber(GetCVar("Sound_MasterVolume")) end
            if not vol or vol <= 0 then return end -- rien à fondre
            local cvarVol = (tonumber(GetCVar("Sound_SFXVolume")) ~= nil)
                and "Sound_SFXVolume" or "Sound_MasterVolume"
            -- Fondu CONTINU, frame par frame (OnUpdate) : des paliers
            -- espacés de 0,1 s s'entendaient comme un escalier — on
            -- règle le volume à CHAQUE frame (~60 fois par seconde), la
            -- descente est inaudible par crans.
            musiqueFadeEnCours = true
            -- v0.21 : fondu rallongé (1,2 → 1,6 s) et décroissance plus
            -- douce (demi-volume tous les 0,6 s) — la fin de chasse
            -- s'entendait encore comme une coupure un peu franche.
            local DUREE = 1.6
            local function rendre()
                musiqueFadeEnCours = false
                pcall(function() SetCVar(cvarVol, vol) end)
            end
            if not MHH_fadeFrame then MHH_fadeFrame = CreateFrame("Frame") end
            local ecoule = 0
            MHH_fadeFrame:Hide()
            MHH_fadeFrame:SetScript("OnUpdate", function(self, elapsed)
                ecoule = ecoule + (elapsed or 0)
                if musiqueEtat ~= nil then -- nouvelle piste : abandon
                    self:SetScript("OnUpdate", nil)
                    self:Hide()
                    rendre()
                    return
                end
                local t = ecoule / DUREE
                if t >= 1 then
                    -- Volume à zéro : on tue le fichier en coupant le
                    -- canal assez longtemps, puis tout revient.
                    self:SetScript("OnUpdate", nil)
                    self:Hide()
                    pcall(function() SetCVar("Sound_EnableSFX", 0) end)
                    C_Timer.After(0.4, function()
                        if musiqueEtat ~= nil then rendre() return end
                        pcall(function()
                            SetCVar("Sound_EnableSFX", 1)
                            SetCVar(cvarVol, vol)
                        end)
                        musiqueFadeEnCours = false
                    end)
                    return
                end
                -- Décroissance exponentielle (demi-volume tous les 0,5 s) :
                -- PERÇUE comme linéaire par l'oreille, contrairement à une
                -- rampe de volume qui s'entend comme un curseur tiré.
                pcall(function()
                    SetCVar(cvarVol, vol * (0.5 ^ (ecoule / 0.6)))
                end)
            end)
            MHH_fadeFrame:Show()
        end)
    end
    -- NB : plus aucun StopMusic — depuis qu'on passe par PlaySoundFile (canal
    -- SFX), StopMusic coupait inutilement la musique d'ambiance de la zone.
end

-- Lecture blindée d'un fichier/son (repli C_Sound comme JouerSon : sur ce
-- client PlaySoundFile global peut être protégé ou silencieux)
local function JouerFichierBlinde(fichier)
    if not fichier then return end
    local res
    if C_Sound and C_Sound.PlaySoundFile then
        local ok, r = pcall(C_Sound.PlaySoundFile, fichier)
        if ok then res = r end
    end
    if res == nil then
        local ok, r = pcall(PlaySoundFile, fichier)
        if ok then res = r end
    end
    return res
end

-- Carillon de victoire « quête terminée » : le SoundKit UI
-- (IG_QUEST_COMPLETE = 828) est muet sur ce client — on passe par
-- PlaySoundFile avec l'ID 619 (QUESTCOMPLETED,
-- Sound\Interface\QuestComplete.wav), le canal qui fait parler les
-- musiques de l'addon. Repli 828 si le fichier échoue.
JouerJingleVictoire = function()
    dernierJingleTemps = time()
    -- Mini jingle de victoire : la fanfare « mission de fief réussie »
    -- (kit 44294, présent dans les constantes de ce client — symétrique
    -- du stinger d'échec 43503). Fichier 619 en second essai (le « ding »
    -- de quête terminée, toujours là), repli SoundKit 828.
    if JouerFichierBlinde(44294) == nil then
        local res = JouerFichierBlinde(619)
        if res == nil then
            JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_COMPLETE or 828)
        end
    end
end

-- Son d'échec « chasse ratée » : le kit igQuestFailed n'EXISTE PAS dans
-- les SoundKitConstants de ce client Forever (845 = QuestLogClose, pas
-- QuestFailed — d'où le silence). L'équivalent thématique qui Y figure :
-- le stinger « mission échouée » des missions de fief, kit 43503
-- (UI_GARRISON_MISSION_COMPLETE_MISSION_FAIL_STINGER).
JouerJingleEchec = function()
    dernierJingleTemps = time()
    JouerSon(43503) -- stinger d'échec (constantes Forever)
end

local function JouerPisteWoW(piste)
    dernierePiste = piste.id
    musiqueHandle = nil
    local res = JouerFichierBlinde(piste.id)
    -- Handle de N'IMPORTE QUELLE forme : table (.Stop/.FadeOut) ou NUMÉRO
    -- (style retail : StopSound(id)). Avant, seul le type table était
    -- capturé — si le client renvoie un numéro, la piste de combat était
    -- impossible à couper et jouait jusqu'au bout après la mort de la bête.
    if res ~= nil and res ~= true then musiqueHandle = res end
    if DB and DB.config.debug then
        DebugChasse("musique", "handle=" .. tostring(musiqueHandle)
            .. " type=" .. type(musiqueHandle))
    end
    return piste.d
end

local function ChoisirDans(banque)
    if not banque or #banque == 0 then return nil end
    local choix = banque[math.random(#banque)]
    -- Pas deux fois la même d'affilée quand la banque le permet
    if #banque > 1 and choix.id == dernierePiste then
        local autre = math.random(#banque - 1)
        if banque[autre].id == choix.id then autre = #banque end
        choix = banque[autre]
    end
    return choix
end

-- Son environnant : pendant nos pistes (traque, combat, promotion), la
-- (déjà déclaré en tête de fichier : FinChasseVictoire l'appelle avant)
MHH_JouerMusique = function(evenement, duree, piste, banque)
    if not DB or (DB.config.musique or "wow") == "off" then return end
    -- Fondu de sortie en cours : démarrer une piste maintenant le ferait
    -- échouer (le fondu s'interrompt, l'ancienne piste survit en doublon)
    if musiqueFadeEnCours then return end
    local m = MHH_MUSIQUES[evenement]
    if not m then return end
    -- TEMPS DE BATTEMENT (traque uniquement, lancement à froid) : le
    -- jingle « En chasse » / le rugissement de contrat doit finir SEUL —
    -- la piste s'installe 1,5 s plus tard. Un rappel de traque pendant
    -- le battement est ignoré ; si un combat démarre entre-temps, le
    -- battement s'annule (la musique de combat prend le relais).
    if evenement == "traque" and not piste and not musiqueEtat then
        if timerBattementTraque then return end
        musiqueEtat = "traque" -- l'état est posé dès maintenant
        local dTraque = duree or 120
        local okTimer = pcall(function()
            timerBattementTraque = C_Timer.NewTimer(1.5, function()
                timerBattementTraque = nil
                if musiqueEtat == "traque" then MHH_JouerMusique("traque", dTraque) end
            end)
        end)
        if not okTimer or not timerBattementTraque then
            -- Client sans C_Timer : la piste démarre sans battement
            timerBattementTraque = nil
            musiqueEtat = nil
            MHH_JouerMusique("traque", dTraque)
        end
        return
    end
    musiqueEtat = evenement
    -- Une piste à nous se joue : le décor sonore du jeu se tait
    CouperSonAmbiant()
    -- Changement d'état (traque → combat surtout) : couper FRANCHEMENT la
    -- piste précédente. JouerPisteWoW écrase le handle sans l'arrêter —
    -- la traque continuait donc PAR-DESSUS la musique de combat
    -- (cacophonie à l'engagement).
    if musiqueHandle then
        pcall(function()
            if type(musiqueHandle) == "table" then
                if musiqueHandle.FadeOut then musiqueHandle:FadeOut(400)
                elseif musiqueHandle.Stop then musiqueHandle:Stop() end
            else
                if StopSound then StopSound(musiqueHandle) end
                if C_Sound and C_Sound.StopSound then C_Sound.StopSound(musiqueHandle) end
                if C_Sound and C_Sound.StopSoundFile then C_Sound.StopSoundFile(musiqueHandle) end
                if C_Sound and C_Sound.FadeOutSound then C_Sound.FadeOutSound(musiqueHandle, 400) end
            end
        end)
        musiqueHandle = nil
    end
    -- Canal SFX via PlaySoundFile : PlayMusic est muet sur ce serveur.
    -- Pas de boucle sur ce canal — la durée des pistes sert donc au relais.
    if piste then
        -- Piste explicite (tests) : jouée telle quelle, pas de repli
        JouerFichierBlinde(tonumber(piste) or piste)
        musiqueBanque = nil
    elseif (DB.config.musique == "custom" and m.custom)
        and JouerFichierBlinde(tonumber(m.custom) or m.custom) then
        -- Fichier custom de MHAmbiance : si PlaySoundFile renvoie nil
        -- (fichier absent/muet — le client le fait), on continue plus bas
        -- sur les banques du jeu : plus de silence total en mode custom.
        musiqueBanque = nil
    elseif evenement == "combat" then
        -- Banque de combat : épique ou normale selon la menace (choisie par
        -- l'appelant), rang max → sa signature d'abord
        musiqueBanque = banque or musiqueBanque or MHH_PISTES_COMBAT_NORMAL
        local choix = ChoisirDans(musiqueBanque)
        if not choix then musiqueEtat = nil return end
        if DB.config.debug then
            DebugChasse("musique", "piste combat id=" .. tostring(choix.id)
                .. " d=" .. tostring(choix.d) .. " (C_Sound="
                .. tostring(C_Sound and C_Sound.PlaySoundFile ~= nil) .. ")")
        end
        duree = JouerPisteWoW(choix)
    elseif evenement == "traque" then
        local choix = ChoisirDans(MHH_PISTES_CHASE)
        if not choix then musiqueEtat = nil return end
        duree = JouerPisteWoW(choix)
    else
        -- Promotion : chemin de fichier du jeu
        if m.wow then JouerFichierBlinde(m.wow) end
        duree = duree or 45
    end
    if musiqueTimer then pcall(function() musiqueTimer:Cancel() end) musiqueTimer = nil end
    if duree then
        pcall(function()
            musiqueTimer = C_Timer.NewTimer(duree, function()
                if musiqueEtat ~= evenement then return end
                if evenement == "combat" and UnitAffectingCombat("player") then
                    -- Le combat continue : enchaîner sur une autre piste
                    -- (variation automatique, jamais la même deux fois)
                    MHH_JouerMusique("combat")
                else
                    MHH_ArreterMusique()
                end
            end)
        end)
    end
end

-- Musique de combat : déclenchée dès la SÉLECTION du gibier (DebutChasse)
-- puis ré-armée à l'entrée effective en combat (PLAYER_REGEN_DISABLED).
-- Globale : DebutChasse est définie plus haut dans le fichier.
function MHH_LancerMusiqueCombat()
    if not chasseActive or not DB then return end
    if musiqueEtat == "combat" then return end -- déjà en marche
    -- Bête supérieure (+5 niveaux) ou rare élite → épique, sinon normale
    local nivJoueur = UnitLevel("player")
    local epique = chasseRare
        or (chasseNiveau and nivJoueur and chasseNiveau >= nivJoueur + 5)
    if DB.config.debug then
        DebugChasse("musique", "lancement combat — mode=" .. tostring(DB.config.musique)
            .. " epique=" .. tostring(epique) .. " etat=" .. tostring(musiqueEtat))
    end
    -- Décalage : le jingle de mise en chasse joue d'abord seul
    local banque = epique and MHH_PISTES_COMBAT_EPIQUE or MHH_PISTES_COMBAT_NORMAL
    if timerMusiqueCombat then pcall(function() timerMusiqueCombat:Cancel() end) timerMusiqueCombat = nil end
    if timerBattementTraque then pcall(function() timerBattementTraque:Cancel() end) timerBattementTraque = nil end
    pcall(function()
        timerMusiqueCombat = C_Timer.NewTimer(4, function()
            timerMusiqueCombat = nil
            -- La chasse a pu s'arrêter (bête désélectionnée, victoire
            -- rapide) pendant le jingle : ne pas lancer dans le vide
            if musiqueEtat == "combat" or not chasseActive then return end
            MHH_JouerMusique("combat", nil, nil, banque)
        end)
    end)
end

-- Contrat du jour : une cible proposée chaque jour (priorité à la zone
-- actuelle, sinon tirage au hasard dans le catalogue). Le contrat en
-- cours du joueur prime toujours.
local function ContratQuotidien()
    if not DB then return end
    local aujourdhui = date("%y%m%d")
    -- Déjà tiré aujourd'hui : rien à faire, SAUF si la liste d'offres est
    -- plus courte que 7 (sauvegarde d'une version antérieure à 5 lignes) :
    -- on COMPLÈTE la liste au log, sans retirer la cible du jour.
    local dejaTire = DB.contratJour == aujourdhui and DB.cibleJour
        and DB.offresJour and DB.offresJour.date == aujourdhui
    local offres = (dejaTire and DB.offresJour.noms) or {}
    if dejaTire and #offres >= 7 then return end
    DB.contratJour = aujourdhui
    local zone = GetZoneText() or ""
    local locaux, tous = {}, {}
    for nom, z in pairs(MHH_CATALOGUE) do
        if MHH_EstNomAffichable(nom) then
            tous[#tous + 1] = nom
            if z == zone then locaux[#locaux + 1] = nom end
        end
    end
    local source = (#locaux > 0) and locaux or tous
    if #source == 0 then return end
    local nom
    if dejaTire then
        nom = DB.cibleJour -- complément d'une liste courte : cible figée
    else
        nom = source[math.random(#source)]
        -- La cible du jour est TOUJOURS mémorisée (plaque Accueil), même
        -- si le joueur a déjà un contrat en cours (le sien prime).
        DB.cibleJour = nom
        DB.cibleJourZone = MHH_CATALOGUE[nom] or zone
    end
    -- Offres du jour (fenêtre Contrats) : la cible du jour (prime +20)
    -- et 6 gibiers piochés dans tout le carnet (prime +5 chacun : de quoi
    -- agrémenter le choix, sans concurrencer l'offre spéciale).
    local pris = {}
    for _, o in ipairs(offres) do pris[o] = true end
    if #offres == 0 then
        offres[#offres + 1] = nom
        pris[nom] = true
    end
    local gardes = 0
    while #offres < 7 and #tous > 1 and gardes < 400 do
        gardes = gardes + 1
        local cand = tous[math.random(#tous)]
        if not pris[cand] then
            pris[cand] = true
            offres[#offres + 1] = cand
        end
    end
    DB.offresJour = { date = aujourdhui, noms = offres }
    if dejaTire then return end -- complément silencieux : pas de toast
    ToastCibleDuJour(nom, MHH_CATALOGUE[nom] or zone)
    cibleJourToastMontre = true
    if not DB.contrat then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Contrat du jour : |cffffff00") .. nom .. "|r ("
            .. (MHH_CATALOGUE[nom] or "?") .. L("). Rapportez-le pour +20 points !"))
    else
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Cible du jour suggérée : |cffffff00") .. nom .. "|r ("
            .. (MHH_CATALOGUE[nom] or "?") .. L(") — votre contrat en cours prime."))
    end
    if #offres > 1 then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffc9a24aOffres de chasse du jour (+5 points chacune) : voir la fenêtre Contrats.|r"))
    end
    if RaffraichirAccueil and carnet and carnet:IsShown() then
        RaffraichirAccueil()
    end
end

-- PISTE QUOTIDIENNE du pensionnaire dévoué : une fois par jour, un ami à
-- 100 d'affinité « sent » un rare de sa zone et le signale au chasseur.
local function PisteQuotidienneAmi()
    if not (DB and DB.menagerie) then return end
    local aujourdhui = date("%y%m%d")
    if DB.pisteAmiDate == aujourdhui then return end -- déjà servie aujourd'hui
    -- premier pensionnaire dévoué trouvé
    local ami, zoneAmi
    for nom, m in pairs(DB.menagerie) do
        if Affinite(m) >= 100 then
            ami, zoneAmi = nom, MHH_CATALOGUE[nom]
            break
        end
    end
    if not ami then return end
    -- rares du catalogue dans cette zone (pas encore pris aujourd'hui)
    local candidats = {}
    for nomC, z in pairs(MHH_CATALOGUE) do
        if z == zoneAmi and MHH_EstNomAffichable(nomC) then
            candidats[#candidats + 1] = nomC
        end
    end
    if #candidats == 0 then return end
    DB.pisteAmiDate = aujourdhui
    local cible = candidats[math.random(#candidats)]
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff8800") .. ami
        .. L("|r lève le museau : un gibier rôde du côté de |cffffff00")
        .. zoneAmi .. L("|r — |cffffcc66") .. cible .. L("|r, selon lui."))
end

-- Annonce de zone : bandeau discret quand on entre dans une région qui
-- compte du gibier au catalogue (« Vous entrez dans les Taris » à la MH)
local annonceZoneFrame = nil
function MHH_AnnonceZone(force) -- globale : appelable depuis /hunt test
    if not DB then return end
    local zone = GetZoneText() or ""
    local n = 0
    for nom, z in pairs(MHH_CATALOGUE) do
        if z == zone and MHH_EstNomAffichable(nom) then n = n + 1 end
    end
    if n == 0 and not force then return end
    if n == 0 and force then n = 3 end -- test hors zone de chasse
    if not annonceZoneFrame then
        annonceZoneFrame = CreateFrame("Frame", nil, UIParent)
        annonceZoneFrame:SetSize(500, 284) -- ratio de zone.tga (1094x622 ≈ 1.76:1)
        annonceZoneFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
        annonceZoneFrame:SetFrameStrata("HIGH")
        pcall(function()
            annonceZoneFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false, edgeSize = 10,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            annonceZoneFrame:SetBackdropColor(0.05, 0.03, 0.01, 0.88)
            annonceZoneFrame:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.95)
        end)
        -- Carte façon MH : petit libellé, nom de région en grand, décompte
        annonceZoneFrame.t1 = annonceZoneFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        annonceZoneFrame.t1:SetPoint("TOP", 0, -116)
        annonceZoneFrame.t1:SetWidth(320)
        -- Petit libellé SANS contour : ombre sombre seule, façon texte
        -- « écrit » dans le parchemin (le contour donnait un rendu bavé)
        pcall(function() annonceZoneFrame.t1:SetFont("Fonts\\FRIZQT__.TTF", 13) end)
        annonceZoneFrame.t1:SetShadowColor(0.08, 0.05, 0.02, 0.9)
        annonceZoneFrame.t1:SetShadowOffset(1, -1)
        annonceZoneFrame.t1:SetTextColor(0.85, 0.75, 0.55, 1)
        annonceZoneFrame.t2 = annonceZoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        annonceZoneFrame.t2:SetPoint("TOP", 0, -138)
        annonceZoneFrame.t2:SetWidth(320)
        pcall(function() annonceZoneFrame.t2:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE") end)
        annonceZoneFrame.t3 = annonceZoneFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        annonceZoneFrame.t3:SetPoint("TOP", 0, -166)
        annonceZoneFrame.t3:SetWidth(340)
        pcall(function() annonceZoneFrame.t3:SetFont("Fonts\\FRIZQT__.TTF", 14) end)
        annonceZoneFrame.t3:SetShadowColor(0.08, 0.05, 0.02, 0.95)
        annonceZoneFrame.t3:SetShadowOffset(1, -1)
        annonceZoneFrame.t3:SetTextColor(0.30, 0.24, 0.14, 1)
        -- Fond texture optionnel (zone.tga via /hunt texui custom)
        annonceZoneFrame.zoneFond = annonceZoneFrame:CreateTexture(nil, "ARTWORK")
        annonceZoneFrame.zoneFond:SetAllPoints()
        annonceZoneFrame.zoneFond:Hide()
        -- BUGFIX : ce cadre est créé paresseusement, APRES l'ADDON_LOADED où
        -- AppliquerTexUI a déjà tourné — il faut donc charger zone.tga ici.
        if DB.config and DB.config.texUI == "custom" then
            if not annonceZoneFrame.zoneFond:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\zone.tga") then
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r zone.tga ne charge pas — dimensions en puissance de 2 requises (ex. 256x64), TGA non compressé."))
            end
            annonceZoneFrame.zoneFond:Show()
        end
    end
    annonceZoneFrame.t1:SetText(L("|cffa58b54RÉGION DE CHASSE|r"))
    annonceZoneFrame.t2:SetText("|cffffd100" .. zone .. "|r")
    annonceZoneFrame.t3:SetText("|cfffff8d0" .. n .. (n > 1 and L(" gibiers") or L(" gibier"))
        .. L(" catalogué") .. (n > 1 and "s" or "") .. L(" au carnet|r"))
    annonceZoneFrame:SetAlpha(0)
    annonceZoneFrame:Show()
    for i = 1, 5 do
        C_Timer.After(i * 0.06, function() annonceZoneFrame:SetAlpha(i / 5) end)
    end
    C_Timer.After(3.5, function()
        for i = 1, 10 do
            C_Timer.After(i * 0.1, function() annonceZoneFrame:SetAlpha(1 - i / 10) end)
        end
        C_Timer.After(1.6, function() annonceZoneFrame:Hide() end)
    end)
end

-- Loot : succès « Curieux de butin » (objet bleu+)
-- [Retiré v0.29] Clin d'œil MH « EXTÉNUÉ » (bave sous 25% de vie) :
-- abandonné — ce client interdit au Lua d'addon toute lecture des PV
-- des mobs (API, dichotomie, tostring, GUID, barres d'UI : tout muré).

-- Vérifie l'état de la cible chassée : mort sous le viseur (validation
-- tolérante de la prise). L'ancien clin d'œil « EXTÉNUÉ » a été retiré
-- en v0.29 (PV des mobs illisibles sur ce client).
-- Factorisée car appelée depuis DEUX endroits : le handler UNIT_HEALTH
-- et un ticker de secours (0,5 s) — sur certains clients, UNIT_HEALTH
-- ne se déclenche pas pour les PNJ ciblés, le ticker garantit que la
-- détection a lieu quoi qu'il arrive.
local function VerifierVieCible()
    if not chasseActive then return end
    if not UnitExists("target") then return end
    local okNom, nom = pcall(function() return UnitName("target") end)
    if not (okNom and nom == chasseActive) then return end
    -- Détection de la mise à mort TOLÉRANTE : dès que la bête chassée
    -- meurt sous le viseur, la prise vaut — quel que soit le canal.
    local okMort, mort = pcall(function() return UnitIsDead("target") end)
    if okMort and mort then
        DebugChasse("viseur", chasseActive .. L(" mort sous le viseur"))
        local nomPrise = chasseActive
        C_Timer.After(0, function()
            if chasseActive == nomPrise then FinChasseVictoire(nomPrise) end
        end)
        return
    end
    -- [Retiré v0.29] Clin d'œil MH « EXTÉNUÉ » sous 25% de vie :
    -- abandonné. Ce client verrouille TOUT accès aux PV des mobs
    -- pour le Lua d'addon : UnitHealth/Max/Percent, dichotomie,
    -- tostring puis match/format/concat, GUID, et même les barres
    -- d'UI ne sont pas exposées (sondes v0.20 à v0.28). La mort
    -- sous le viseur (ci-dessus) reste le seul signal utilisable.
end
-- Traitement de la sélection de cible : détecte le gibier et lance la
-- chasse. Factorisée car appelée depuis PLAYER_TARGET_CHANGED ET depuis
-- PLAYER_ALIVE (fantôme qui redevient vivant en gardant la cible).
local function TraiterCible()
    if not DB then return end
    -- Portrait live dans le carnet s'il est ouvert
    if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    if UnitExists("target") and not UnitIsFriend("player", "target") and not UnitIsPlayer("target") then
        -- v0.30 : nom parfois « secret » (tab-targeting en donjon) — sans
        -- nom utilisable, impossible de démarrer une chasse proprement.
        local nom = NomOrdinaire(UnitName("target"))
        if not nom then return end
        local classification = UnitClassification("target") -- "rare", "rareelite", "elite", "normal"
        local niveau = UnitLevel("target")
        if classification == "rare" or classification == "rareelite" then
            ApprendreParId("target") -- apprend le nom exact via le GUID
            if not DB.decouverts[nom] and not MHH_CATALOGUE[nom] then
                local idR = nil
                local guid = UnitGUID("target")
                if guid then idR = tonumber(guid:match("-(%d+)$")) end
                DB.decouverts[nom] = { kills = 0, vu = true, zone = GetZoneText(), decouvert = time(), id = idR, nouveau = true }
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Nouveau monstre découvert : |cffffff00") .. nom .. "|r (" .. GetZoneText() .. L(") — /hunt add pour l'inscrire au carnet."))
                DebloquerSucces("decouverte")
                MHH_VerifierRencontres(nom)
            elseif not DB.rencontres[nom] then
                -- v0.119 : PREMIÈRE RENCONTRE — le succès « découverte » ne
                -- pouvait plus tomber avec un carnet data complet : il compte
                -- désormais la première fois qu'on CROISE un rare du carnet.
                DB.rencontres[nom] = time()
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Première rencontre : |cffffff00") .. nom .. "|r.")
                DebloquerSucces("decouverte")
                MHH_VerifierRencontres(nom)
            end
            if nbDecouverts() >= 5 then DebloquerSucces("explorateur") end
            DebutChasse(nom, classification, niveau)
        elseif MHH_CATALOGUE[nom] or DB.decouverts[nom] then
            DebutChasse(nom, classification, niveau)
        end
    end
end
-- Un seul dispatcher propre pour tous les événements
local function OnEvenementPrincipal(self, event, ...)
    if event == "ADDON_LOADED" then
        local nom = ...
        if nom == MHH_ADDON_NAME then
            InitDB()
            -- ZONES RÉELLES (autofix « Mezzir ») : chaque fiche de
            -- découverte capture le GetZoneText() du SERVEUR au moment
            -- de la découverte — pas les traductions (parfois custom)
            -- du data file. On les applique au catalogue au chargement :
            -- une zone mal nommée dans le data ne peut plus cacher un
            -- gibier dans l'onglet de sa vraie zone.
            if DB.decouverts then
                for nomD, d in pairs(DB.decouverts) do
                    if type(d) == "table" and d.zone and d.zone ~= ""
                        and MHH_CATALOGUE[nomD] and MHH_CATALOGUE[nomD] ~= d.zone then
                        DebugChasse("zone", nomD .. " : " .. tostring(MHH_CATALOGUE[nomD]) .. " → " .. d.zone .. " (autofix découverte)")
                        MHH_CATALOGUE[nomD] = d.zone
                    end
                end
            end
            -- AUTO-RÉPARATION (une seule fois) : les versions antérieures
            -- pouvaient laisser Sound_EnableMusic/Ambience à 0 dans la
            -- config du client (déconnexion pendant une piste). On rend
            -- au joueur sa musique, avec un message pour l'avertir.
            if not DB.sonRepare then
                DB.sonRepare = true
                pcall(function()
                    if (tonumber(GetCVar("Sound_EnableMusic")) or 1) == 0 then
                        SetCVar("Sound_EnableMusic", 1)
                        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Musique du jeu réactivée (un vieux mute de l'addon traînait dans la config du client)."))
                    end
                    if (tonumber(GetCVar("Sound_EnableAmbience")) or 1) == 0 then
                        SetCVar("Sound_EnableAmbience", 1)
                        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Ambiance sonore du jeu réactivée (un vieux mute de l'addon traînait dans la config du client)."))
                    end
                end)
            end
            if AppliquerTextures then AppliquerTextures() end
            if AppliquerTexUI then AppliquerTexUI() end
            -- Piste du pensionnaire dévoué (une fois par jour, après l'init)
            pcall(PisteQuotidienneAmi)
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r ") .. "|cffa58b54" .. MHH_VERSION .. "|r" .. L(" chargé. /hunt pour ouvrir le carnet. ") .. nbChasses() .. (nbChasses() == 1 and L(" chasse au compteur.") or L(" chasses au compteur.")))
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Fin de combat : la musique de combat s'arrête quoi qu'il arrive
        if musiqueEtat == "combat" then MHH_ArreterMusique() end
        -- Fin de combat sans victoire : le monstre a reset/s'est enfui.
        -- Dernier filet avant ce verdict : si la bête est morte au viseur,
        -- c'est une prise, pas une fuite.
        -- La chasse est suspendue : re-cibler la bête la reprendra.
        if chasseActive then
            local okPrise, prise = pcall(function()
                return UnitExists("target")
                    and (UnitName("target") or "") == chasseActive
                    and UnitIsDead("target")
            end)
            DebugChasse("finCombat", chasseActive .. L(" — prise=") .. tostring(okPrise and prise or false))
            if okPrise and prise then
                -- Différé hors du contexte tainté : les valeurs « secrètes »
                -- de Midnight ne circulent que dans les exécutions
                -- restreintes (secure snippets) ; C_Timer.After retombe
                -- dans un contexte addon propre.
                local nomPrise = chasseActive
                C_Timer.After(0, function()
                    if chasseActive == nomPrise then FinChasseVictoire(nomPrise) end
                end)
            else
                -- Verdict DIFFÉRÉ : le coup de grâce peut tomber juste
                -- APRÈS la fin de combat du joueur (DoT, tick, dégâts
                -- différés qui tickent toutes les 2-3 s) — on laisse
                -- 3,5 s au journal de combat pour réclamer la prise AVANT
                -- de déclarer la fuite. Si UNIT_DIED valide la prise
                -- entre-temps, chasseActive change et ce verdict ne
                -- s'applique plus.
                local nomChasse = chasseActive
                DebugChasse("finCombat", nomChasse .. L(" — fuite annoncée dans 3,5 s si aucune prise"))
                C_Timer.After(3.5, function()
                    if chasseActive ~= nomChasse then return end
                    -- DERNIER FILET avant le verdict de fuite : la bête a pu
                    -- mourir APRÈS la perte de ciblage (DoT) et UNIT_DIED
                    -- peut manquer. On redemande au viseur ET au survol.
                    local encoreMorte = false
                    pcall(function()
                        -- Le cadavre peut être sous le viseur, le survol, le
                        -- focus, la cible du familier ou celle d'un coéquipier :
                        -- on les consulte TOUS avant de décréter la fuite.
                        for _, u in ipairs({ "target", "mouseover", "focus", "pettarget",
                            "party1target", "party2target", "party3target", "party4target" }) do
                            if UnitExists(u) and (UnitName(u) or "") == nomChasse
                                and UnitIsDead(u) then encoreMorte = true end
                        end
                    end)
                    if encoreMorte then
                        DebugChasse("finCombat", nomChasse .. L(" — cadavre repéré au dernier filet : prise !"))
                        FinChasseVictoire(nomChasse)
                        return
                    end
                    AnnoncerSuspension(nomChasse, L("|cffffd100[MH Hunt]|r |cffa58b54Le monstre vous a échappé…|r La chasse de ") .. nomChasse .. L(" est suspendue."))
                    EmoteDeuilChasseur() -- v0.35 : le chasseur tombe à genou
                    chasseSuspendue = {
                        nom = nomChasse,
                        debutTemps = chasseDebutTemps,
                        debutVie = chasseDebutVie,
                        niveau = chasseNiveau,
                        rare = chasseRare,
                        piegee = chassePiegee,
                        vieTouchee = chasseVieTouchee,
                        quand = time(),
                    }
                    chasseActive = nil
                    if MHH_ArreterMusique then MHH_ArreterMusique() end
                    MettreAJourIndicateur()
                end)
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entrée en combat pendant une chasse : la musique de combat
        -- (déjà lancée à la sélection du gibier) repart si elle s'était
        -- arrêtée entre-temps (relais géré par LancerMusiqueCombat)
        if chasseActive then MHH_LancerMusiqueCombat() end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if not DB then return end
        TraiterCible()
        -- Suspension : cible perdue (désélection, cible amie) OU tournée
        -- vers autre chose que la bête chassée, hors combat. Re-cibler la
        -- bête la REPREND (branche « reprise » de DebutChasse) — le double
        -- bloc « découverte » d'ici était du code mort (condition inversée).
        if chasseActive and not UnitAffectingCombat("player")
            and (not UnitExists("target") or (UnitName("target") or "") ~= chasseActive) then
            -- Jamais de suspension si le CHASSEUR est mort (PLAYER_DEAD
            -- clôt la chasse) : sinon elle se « reprenait » au cimetière
            if UnitIsDeadOrGhost("player") then
                FinChasseEchec(true)
            else
                -- Cible perdue sans combat (désélection, cible amie, gibier
                -- hors carnet) : la chasse est suspendue — mais re-cibler
                -- la bête la REPRENDRA avec son chrono (rien n'est perdu).
                -- Verdict DIFFÉRÉ comme pour la fin de combat : à la mort
                -- de la bête, la cible peut se vider et le drapeau combat
                -- tomber AVANT que le journal n'annonce la mort — on laisse
                -- 3,5 s à UNIT_DIED pour réclamer la prise.
                local nomChasseTC = chasseActive
                local etatTC = {
                    debutTemps = chasseDebutTemps, debutVie = chasseDebutVie,
                    niveau = chasseNiveau, rare = chasseRare, piegee = chassePiegee,
                    vieTouchee = chasseVieTouchee,
                }
                DebugChasse("cible", nomChasseTC .. L(" — trace perdue, verdict dans 3,5 s"))
                C_Timer.After(3.5, function()
                    if chasseActive == nomChasseTC then
                        -- Re-ciblée entre-temps ? La chasse continue, pas de suspension
                        if UnitExists("target") and (UnitName("target") or "") == nomChasseTC then return end
                        SuspendreChasse(nomChasseTC, etatTC)
                    elseif chasseActive then
                        -- Une AUTRE chasse a démarré entre-temps : l'ancienne
                        -- part en suspension (elle reste reprisable au ciblage)
                        SuspendreChasse(nomChasseTC, etatTC)
                    end
                    -- chasseActive nil = la prise (ou l'échec) a été validée : rien à faire
                end)
            end
        end
    elseif event == "PLAYER_ALIVE" then
        -- Le joueur redevient vivant (résurrection) : si la bête est
        -- encore ciblée, la chasse démarre maintenant — cibler en
        -- fantôme ne comptait pas.
        if not UnitIsDeadOrGhost("player") then TraiterCible() end
    elseif event == "PLAYER_DEAD" then
        -- CUISINE : mort du chasseur — le repas préparé est perdu (gâché),
        -- petit message au chat ; l'onglet Cuisine se rafraîchit à l'ouverture.
        if DB and DB.repas then
            local r = CUISINE_RECETTES and CUISINE_RECETTES[DB.repas]
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cff8a6d3b" .. (r and r.nom or L("Le repas préparé"))
                .. L(" a refroidi — le repas préparé est perdu à la mort du chasseur.|r"))
            DB.repas = nil
        end
        local chasseEnCours = (chasseActive ~= nil or chasseSuspendue ~= nil)
        FinChasseEchec(true)
        -- Mort face à un RARE sans chasse active (bête non répertoriée au
        -- carnet : aucune chasse n'a démarré, FinChasseEchec ne fait rien)
        -- : le son d'échec joue quand même — un rare qui vous tue mérite
        -- sa défaite, contrat ou pas. Seul le SON : pas de message ni de
        -- bannière (ça n'est pas une chasse).
        if not chasseEnCours and DB and DB.config.son and JouerJingleEchec then
            local okCls, cls = pcall(function()
                return UnitExists("target") and UnitClassification("target") or nil
            end)
            if okCls and cls and string.find(cls, "rare") then
                if musiqueFadeEnCours and C_Timer and C_Timer.After then
                    -- Fondu de piste en cours : attendre qu'il finisse
                    -- (le stinger vit sur le même canal SFX)
                    C_Timer.After(1.8, function() JouerJingleEchec() end)
                else
                    JouerJingleEchec()
                end
            end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not chasseActive then
            -- Filet de secours : la bête vient de mourir alors que la
            -- chasse était déjà suspendue — cas réel observé en jeu : le
            -- coup de grâce tombe APRÈS la sortie de combat du joueur
            -- (DoT, dégâts différés), la suspension a déjà été prononcée.
            -- Si la mort survient dans les 5 min, la prise est valide :
            -- on restaure la chasse et le verdict du journal prime.
            local _, sousEvent0, _, _, _, _, _, _, destNom0 = CombatLogGetCurrentEventInfo()
            if sousEvent0 == "UNIT_DIED" and chasseSuspendue
                and chasseSuspendue.nom == destNom0
                and time() - (chasseSuspendue.quand or 0) < 300 then
                chasseActive = chasseSuspendue.nom
                chasseDebutTemps = chasseSuspendue.debutTemps
                chasseDebutVie = chasseSuspendue.debutVie
                chasseNiveau = chasseSuspendue.niveau
                chasseRare = chasseSuspendue.rare
                chassePiegee = chasseSuspendue.piegee
                chasseVieTouchee = chasseSuspendue.vieTouchee == true
                chasseSuspendue = nil
                MettreAJourIndicateur()
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffa0ff50La bête est tombée après la fin de combat — prise validée !|r"))
                DebugChasse("journal", L("reprise de secours : la bête suspendue vient de mourir"))
            else
                return
            end
        end
        local infos = { CombatLogGetCurrentEventInfo() }
        local sousEvent = infos[2]
        local destNom = infos[9]
        if sousEvent == "UNIT_DIED" and chasseActive then
            DebugChasse("journal", "UNIT_DIED : " .. tostring(destNom) .. L(" (chassé : ") .. chasseActive .. ")")
        end
        if sousEvent == "UNIT_DIED" and chasseActive then
            -- TOLÉRANT : la position du nom de la victime VARIE selon les
            -- clients (Midnight) — si le nom chassé apparaît N'IMPORTE OÙ
            -- dans le payload, c'est lui qui est mort. L'ancien test sur
            -- la seule 9e valeur manquait des kills entiers (message
            -- « Le monstre vous a échappé » juste après une prise).
            local mortDuChasse = (destNom == chasseActive)
            if not mortDuChasse then
                for _, v in ipairs(infos) do
                    if v == chasseActive then mortDuChasse = true break end
                end
            end
            if mortDuChasse then
                local guidJoueur = UnitGUID("player")
                local parLeJoueur, parLeGroupe = false, false
                for _, v in ipairs(infos) do
                    if v == guidJoueur then parLeJoueur = true end
                    if type(v) == "string" and v ~= "" and v ~= chasseActive then
                        local dansGroupe = pcall(UnitInParty, v) or pcall(UnitInRaid, v)
                        if dansGroupe then parLeGroupe = true end
                    end
                end
                DebugChasse("journal", "killSouple=" .. tostring(DB.config.killSouple)
                    .. " parLeJoueur=" .. tostring(parLeJoueur)
                    .. " parLeGroupe=" .. tostring(parLeGroupe))
                -- pcall : si Midnight bloque quelque chose en contexte tainté,
                -- la prise reste acquittée (anti-double en tête de fonction)
                local okF, errF
                if DB.config.killSouple then
                    okF, errF = pcall(FinChasseVictoire, chasseActive)
                elseif parLeJoueur or parLeGroupe then
                    okF, errF = pcall(FinChasseVictoire, chasseActive)
                end
                if not okF then DebugChasse("journal", L("ERREUR victoire : ") .. tostring(errF)) end
            end
        elseif sousEvent == "AURA_APPLIED" and destNom == chasseActive then
            -- PIÈGE « FAÇON MH » : le monstre CONTRÔLÉ est capturé.
            -- Ouvert à toutes les classes qui contrôlent (retour de
            -- test : piège de glace seul = chasseur seulement) :
            -- racines, stuns, incapacités, métamorphoses, peurs, ban
            -- — cf. table MHH_PIEGES_CAPTURE.
            local spellId = select(12, CombatLogGetCurrentEventInfo())
            if MHH_PIEGES_CAPTURE and MHH_PIEGES_CAPTURE[spellId] then
                chassePiegee = true
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Le monstre est pris au piège !"))
            end
        end
    elseif event == "UPDATE_MOUSEOVER" or event == "CURSOR_UPDATE" then
        -- Survol d'une plaque de nom : si c'est un rare du data file,
        -- l'addon apprend son nom en jeu par l'ID — sans cibler ni /run.
        -- (UPDATE_MOUSEOVER n'existe pas partout : CURSOR_UPDATE est le
        -- repli, un peu plus bavard, d'où le garde-fou de 0,2 s)
        if not DB then return end
        local maintenant = GetTime()
        if maintenant - dernierScanMouseover < 0.2 then return end
        dernierScanMouseover = maintenant
        pcall(function()
            if UnitExists("mouseover") then
                local cl = UnitClassification("mouseover")
                if cl == "rare" or cl == "rareelite" then ApprendreParId("mouseover") end
            end
        end)
    elseif event == "WEATHER_CHANGED" then
        -- Météo (client Forever) : annonce d'ambiance au changement,
        -- avec anti-spam (seulement si le type change réellement)
        pcall(function()
            local nomMeteo, cleMeteo = MeteoActuelle()
            -- N'annonce que les types RECONNUS (le client peut renvoyer un
            -- code brut, ex. « 0 ») et seulement quand la zone est connue
            -- (au login, GetZoneText est encore vide)
            local zone = GetZoneText()
            if nomMeteo and cleMeteo and MHH_NOMS_METEO[cleMeteo]
                and zone ~= "" and nomMeteo ~= dernierMeteoAnnonce then
                dernierMeteoAnnonce = nomMeteo
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cff8a9bb0La météo tourne :|r ")
                    .. nomMeteo .. " sur " .. zone .. ".")
                -- Pendant une chasse, un conseil de vieux traqueur
                if chasseActive then
                    if nomMeteo == "pluie" then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cff8a6d3bLa pluie couvre tes pas… mais gomme aussi les traces.|r")
                    elseif nomMeteo == L("tempête de sable") or nomMeteo == L("pluie de feu") then
                        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cff8a6d3bMauvais temps pour la piste : garde l'œil sur ton gibier, pas sur le ciel.|r"))
                    end
                end
                if MHH_RaffraichirMissions then MHH_RaffraichirMissions() end
            end
        end)
    elseif event == "UNIT_HEALTH" then
        -- « Sans une égratignure » : suivi en direct — si la vie passe
        -- sous son niveau de départ pendant la chasse, la prise est
        -- marquée touchée, même si tout est rendu avant la fin (la
        -- comparaison au moment de la prise seule était trop indulgente).
        -- Comparaison pure : l'arithmétique sur la vie est interdite
        -- (« secret numbers »), les comparaisons sont permises.
        if chasseActive and chasseDebutVie and not chasseVieTouchee then
            pcall(function()
                if UnitHealth("player") < chasseDebutVie then chasseVieTouchee = true end
            end)
        end
        -- Mort sous le viseur : logique factorisée dans
        -- VerifierVieCible() (appelée aussi par le ticker de secours).
        if chasseActive then VerifierVieCible() end
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" or event == "COMBAT_LOG_EVENT" then
        -- Canaux de mort de repli (cf. v0.19) : le journal de combat
        -- filtré est PROTÉGÉ sur ce client. Ces canaux annoncent la
        -- mort d'un hostile — on ne valide QUE si le nom du gibier
        -- chassé figure dans le message (sinon ce n'est pas notre prise).
        -- COMBAT_LOG_EVENT passe des arguments numériques (timestamp…) :
        -- seul le texte exploitable est retenu.
        local texte = ...
        if chasseActive and type(texte) == "string" and string.find(texte, chasseActive, 1, true) then
            local nomPrise = chasseActive
            DebugChasse("combatMort", nomPrise .. L(" — mort signalée par le canal de combat (repli)"))
            C_Timer.After(0, function()
                if chasseActive == nomPrise then FinChasseVictoire(nomPrise) end
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        EnregistrerCarteZone()
        ContratQuotidien()
        TirageMissionCachee()
        MHH_AnnonceZone()
        -- Rappel du toast cible du jour à chaque connexion/reload
        -- (une fois par session ; ContratQuotidien l'affiche au tirage du jour)
        if DB.cibleJour and not cibleJourToastMontre then
            ToastCibleDuJour(DB.cibleJour, DB.cibleJourZone)
            cibleJourToastMontre = true
        end
        -- Musique de traque : on entre dans la zone du contrat actif
        if DB and DB.contrat and MHH_CATALOGUE[DB.contrat] == (GetZoneText() or "")
            and musiqueEtat ~= "combat" then
            MHH_JouerMusique("traque", 120)
        end
        -- Cuisine : cueillette (herbe aromatique, 25% en zone de chasse)
        if DB then
            local zoneCur = GetZoneText() or ""
            local nbGibiersZone = 0
            for nom, z in pairs(MHH_CATALOGUE) do
                if z == zoneCur and MHH_EstNomAffichable(nom) then nbGibiersZone = nbGibiersZone + 1 end
            end
            if nbGibiersZone > 0 and math.random(100) <= 25 then
                if (DB.herbe or 0) >= (CUISINE_INGREDIENTS.herbe.max or 10) then
                    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Sac d'herbes plein — la cueillette se perd (cuisine !)."))
                else
                    DB.herbe = (DB.herbe or 0) + 1
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Cueilli en chemin : |cffff7a1a1 herbe aromatique|r.")
                end
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Filet de sécurité : si une piste était en cours, restituer le son
        -- du jeu AVANT que le client ne sauvegarde sa config — sinon le
        -- mute persiste et le joueur perd sa musique pour de bon.
        MHH_ArreterMusique()
    elseif event == "CHAT_MSG_ADDON" then
        -- Carte de chasseur reçue d'un autre joueur de l'addon : rang,
        -- points, chasses, enclos, dernière prise — jamais le carnet
        local prefix, msg, canal, expediteur = ...
        if prefix == "MHHUNT" and type(msg) == "string" and msg:sub(1, 6) == "CARTE:" then
            -- v0.56 : 1er champ = INDEX du rang (l'expéditeur traduit le
            -- nom, le récepteur re-localise depuis son propre MHH_RANGS).
            local idxRang, points, chasses, captures, trophee = strsplit("|", msg:sub(7))
            if type(expediteur) == "string" then expediteur = strsplit("-", expediteur) end
            local idx = tonumber(idxRang) or 1
            local nomRang = (MHH_RANGS and MHH_RANGS[idx] and MHH_RANGS[idx].nom) or "?"
            -- v0.59 : palette du liseré du carnet (MHH_RangHex) + le rang
            -- s'affiche AVANT le pseudo, comme sur les cartes de MH.
            local col = MHH_RangHex and MHH_RangHex(idx) or "|cffa58b54"
            local nCh = tonumber(chasses) or 0
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Carte de chasseur — ")
                .. col .. "[" .. nomRang .. "]|r |cffffff00" .. (expediteur or "?") .. "|r : "
                .. (tonumber(points) or 0) .. " pts, " .. nCh
                .. (nCh == 1 and L(" chasse, ") or L(" chasses, "))
                .. (tonumber(captures) or 0) .. L(" spécimens en enclos.")
                .. ((trophee and trophee ~= "-" and trophee ~= "") and (L(" Dernière prise : |cffa0ff50") .. trophee .. "|r.") or ""))
            AfficherBanniere(L("CARTE DE CHASSEUR — ") .. col .. "[" .. nomRang .. "]|r "
                .. (expediteur or "?"), 1, 0.84, 0)
        end
    elseif event == "CHAT_MSG_LOOT" then
        local texte = ...
        if texte:find("Vous recevez le loot") or texte:find("You receive loot") then
            if texte:find("%|cff0070dd") or texte:find("%|cffa335ee") then
                DebloquerSucces("butin")
            end
        end
    end
end

local f = CreateFrame("Frame")
-- NB (correctif v0.18 du popup « réservé à l'UI de Blizzard ») : sur les
-- clients custom, l'enregistrement de certains événements est PROTÉGÉ —
-- COMBAT_LOG_EVENT_UNFILTERED déclenchait le blocage au chargement depuis
-- la première version. Tout passe donc par pcall : un événement absent
-- n'est qu'un canal de détection en moins, jamais un blocage. Les
-- autres canaux (viseur, ticker chrono, scan de cadavre à la fin du
-- combat, dernier filet différé) couvrent déjà la prise.
local function EnregistrerEvenement(evenement, note)
    local ok = pcall(function() f:RegisterEvent(evenement) end)
    if not ok and note then
        DebugChasse("evenements", evenement .. " : " .. note)
    end
    return ok
end
EnregistrerEvenement("ADDON_LOADED")
EnregistrerEvenement("PLAYER_TARGET_CHANGED")
EnregistrerEvenement("PLAYER_REGEN_ENABLED")
EnregistrerEvenement("PLAYER_REGEN_DISABLED")
EnregistrerEvenement("PLAYER_DEAD")
-- v0.31 : COMBAT_LOG_EVENT_UNFILTERED n'est plus DEMANDÉ du tout. Ce
-- canal est protégé sur ce client depuis la v0.18 : le pcall évitait le
-- popup, mais chaque tentative émettait quand même ADDON_ACTION_FORBIDDEN
-- (loggué par !BugGrabber à chaque chargement). Les canaux de repli
-- (CHAT_MSG_COMBAT_HOSTILE_DEATH, COMBAT_LOG_EVENT, viseur, ticker,
-- dernier filet) couvrent déjà la prise — on ne demande plus l'impossible.
EnregistrerEvenement("PLAYER_ALIVE") -- fantôme qui redevient vivant avec la cible
-- Canaux de mort de REPLI : l'annonce de mort d'un hostile du client
-- Vanilla (CHAT_MSG_COMBAT_HOSTILE_DEATH) — le canal de mort le plus
-- fiable de 1.12. NB v0.32 : COMBAT_LOG_EVENT est AUSSI protégé sur ce
-- client (ADDON_ACTION_FORBIDDEN à chaque chargement, loggué par
-- !BugGrabber) — tous les canaux du journal de combat sont murés, on ne
-- les demande plus du tout. La mort se détecte par l'annonce d'hostile,
-- le viseur, le ticker et le dernier filet.
EnregistrerEvenement("CHAT_MSG_COMBAT_HOSTILE_DEATH", L("canal de repli pour la détection des morts"))
EnregistrerEvenement("UNIT_HEALTH")
-- Ticker de secours (v0.20) : sur ce client, UNIT_HEALTH peut rester muet
-- pour les PNJ ciblés (vie « secret number »). On vérifie la cible
-- chassée toutes les 0,5 s quoi qu'il arrive : mort sous le viseur,
-- mort sous le viseur de la cible chassée.
if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(0.5, function()
        -- Correctif minuit : sans changement de zone ni reconnexion,
        -- aucun événement ne relançait ContratQuotidien après minuit —
        -- l'onglet Contrats restait alors vide jusqu'au /reload.
        if DB and DB.contratJour ~= date("%y%m%d") then
            pcall(ContratQuotidien)
        end
        -- Rumeurs de guilde : tirage au passage de minuit (idempotent —
        -- la rumeur du jour pendante est conservée)
        pcall(TirageMissionCachee)
        local ok, err = pcall(VerifierVieCible)
        if not ok and DB and DB.config and DB.config.debug then
            DebugChasse("err", "ticker : " .. tostring(err))
        end
    end)
end
-- UPDATE_MOUSEOVER est absent de certains clients Midnight : pcall + repli
-- sur CURSOR_UPDATE (même usage : survol des plaques pour l'auto-découverte)
EnregistrerEvenement("UPDATE_MOUSEOVER")
EnregistrerEvenement("CURSOR_UPDATE")
EnregistrerEvenement("WEATHER_CHANGED") -- client Forever uniquement
EnregistrerEvenement("CHAT_MSG_LOOT")
EnregistrerEvenement("PLAYER_ENTERING_WORLD")
EnregistrerEvenement("ZONE_CHANGED_NEW_AREA")
EnregistrerEvenement("CHAT_MSG_ADDON")
EnregistrerEvenement("PLAYER_LOGOUT") -- pour garantir la restitution du son du jeu
pcall(function() -- canal d'addon : carte de chasseur (/hunt carte <joueur>)
    if C_Chat and C_Chat.RegisterAddonMessagePrefix then
        C_Chat.RegisterAddonMessagePrefix("MHHUNT")
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("MHHUNT")
    end
end)
f:SetScript("OnEvent", OnEvenementPrincipal)

-- Diagnostic « MHHunt a été bloqué » : la popup du client ne dit pas
-- QUELLE fonction a été jugée « réservée à l'UI de Blizzard » (erreur
-- présente depuis la première version, cause inconnue). Quand le
-- client propose ces événements, ils nomment l'addon fautif et la
-- fonction bloquée : on les imprime dans le chat pour identifier
-- enfin le coupable — au prochain blocage, la ligne apparaîtra.
pcall(function()
    local d = CreateFrame("Frame")
    d:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    d:RegisterEvent("ADDON_ACTION_BLOCKED")
    d:SetScript("OnEvent", function(self, event, addon, func)
        if addon == "MHHunt" then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Action bloquée (" .. event .. ") : |cffffff00"
                .. tostring(func) .. "|r — |cffa58b54transmets cette ligne pour corriger le blocage au chargement.|r")
        end
    end)
end)

-- « La bête est dans les parages… » : scan des nameplates toutes les 2 s.
-- Si le monstre du contrat apparaît à l'écran (sans chasse active), petite
-- musique de traque + message d'ambiance. Tout en pcall : les nameplates
-- varient selon les clients/serveurs, échouer silencieusement est OK.
local dernierScanProximite = 0
pcall(function()
    C_Timer.NewTicker(2, function()
        if not DB or not DB.contrat or chasseActive then return end
        if musiqueEtat == "combat" then return end
        local maintenant = time()
        if maintenant - dernierScanProximite < 120 then return end
        local enfants = { WorldFrame:GetChildren() }
        for i = 1, #enfants do
            local nf = enfants[i]
            if nf and nf.GetName and nf:GetName() and nf:GetName():find("^NamePlate") then
                for _, region in pairs({ nf:GetChildren() }) do
                    if region and region.GetText and region.GetText(region)
                        and region.GetText(region) == DB.contrat then
                        dernierScanProximite = maintenant
                        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffa58b54La bête est dans les parages…|r Gardez vos sens éveillés, chasseur."))
                        MHH_JouerMusique("traque", 60)
                        return
                    end
                end
            end
        end
    end)
end)

-- Traque par les COORDONNÉES du contrat : le carnet connaît le point de
-- spawn du gibier du contrat (MHH_COORDS, 0-100). Quand le chasseur
-- approche ce point — la bête peut être hors écran, les nameplates ne
-- la voient pas — la musique de traque démarre (une fois par approche :
-- réarmée en sortant du rayon élargi ou en changeant de zone).
-- Uniquement pour le monstre du CONTRAT : on ignore les autres rares.
local traqueCoordsArmee = true
pcall(function()
    C_Timer.NewTicker(3, function()
        if not DB or not DB.contrat or chasseActive then return end
        if musiqueEtat == "combat" then return end
        local nom = DB.contrat
        local c = MHH_COORDS[nom]
        if not c then return end
        if (MHH_CATALOGUE[nom] or "") ~= (GetZoneText() or "") then
            traqueCoordsArmee = true -- autre zone : réarmée au retour
            return
        end
        local x, y
        pcall(function()
            if not C_Map or not C_Map.GetBestMapForUnit then return end
            local id = C_Map.GetBestMapForUnit("player")
            if not id or not C_Map.GetPlayerMapPosition then return end
            -- Selon les clients : (mapID, unit) ou (unit, mapID)
            local p = C_Map.GetPlayerMapPosition(id, "player")
            if p and type(p) == "table" then
                if p.GetXY then x, y = p:GetXY() else x, y = p.x, p.y end
            elseif p then
                p = C_Map.GetPlayerMapPosition("player", id)
                if p then
                    if p.GetXY then x, y = p:GetXY() else x, y = p.x, p.y end
                end
            end
        end)
        if not x or not y or (x <= 0 and y <= 0) then return end
        local sx, sy = c[1] / 100, c[2] / 100 -- coords carnet : 0-100
        local d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy)
        if d2 <= 0.0036 then -- ~6% de la carte autour du spawn
            if traqueCoordsArmee then
                traqueCoordsArmee = false
                local maintenant = time()
                if maintenant - dernierScanProximite >= 120 then
                    dernierScanProximite = maintenant
                    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffa58b54La bête est dans les parages…|r Gardez vos sens éveillés, chasseur."))
                end
                MHH_JouerMusique("traque", 60)
            end
        elseif d2 > 0.01 then -- sorti du voisinage élargi (~10%)
            traqueCoordsArmee = true
        end
    end)
end)

-- ============================================
-- 6. CARNET DE CHASSE (UI v2 — style « Guide de terrain » MH)
--    Onglets Monstres / Succès / Profil, grille + panneau détail
-- ============================================
carnet = CreateFrame("Frame", "LaChasseCarnet", UIParent, "BasicFrameTemplateWithInset")
-- Le carnet participe au système de panneaux WoW : Échap le ferme, et les
-- panneaux de interface (liste des add-ons, options…) le remplacent proprement
-- au lieu de passer dessous (strate MEDIUM, pas HIGH)
pcall(function()
    if UISpecialFrames then tinsert(UISpecialFrames, "LaChasseCarnet") end
end)
pcall(function()
    if UIPanelWindows then
        UIPanelWindows["LaChasseCarnet"] = { area = "center", pushable = 0, whileDead = 1 }
    end
end)
carnet:SetSize(640, 400)
carnet:SetPoint("CENTER")
carnet:SetMovable(true)
carnet:EnableMouse(true)
carnet:RegisterForDrag("LeftButton")
carnet:SetScript("OnDragStart", carnet.StartMoving)
carnet:SetScript("OnDragStop", carnet.StopMovingOrSizing)
-- v0.106 : strate DIALOG — en MEDIUM, la barre de skills du client
-- passait AU-DESSUS du carnet et de son contenu (retour utilisateur).
-- DIALOG = strate des fenêtres modales : le carnet et toutes ses
-- pages (ménagerie comprise) passent devant les barres et la minicarte.
carnet:SetFrameStrata("DIALOG")
carnet:Hide()

-- Ouverture standard : toujours recentré à l'écran (un drag accidentel ne
-- doit pas laisser le carnet perdu en bas de l'écran au prochain affichage)
OuvrirCarnet = function(onglet)
    if not carnet then return end
    carnet:ClearAllPoints()
    carnet:SetPoint("CENTER")
    if RaffraichirCarnet then RaffraichirCarnet() end
    carnet:Show()
    if onglet and AfficherOnglet then AfficherOnglet(onglet) end
end

-- Couche OVERLAY : indispensable pour passer AU-DESSUS du fond sombre
-- du template BasicFrameTemplateWithInset (sinon parchemin invisible)
local carnetFond = carnet:CreateTexture(nil, "OVERLAY")
carnetFond:SetAllPoints()
if TextureCustomActive("fond") then
    carnetFond:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\fond.tga")
else
    carnetFond:SetColorTexture(0.18, 0.13, 0.07, 0.95)
end

-- Liseré de rang : 4 filets fins sur les bords du carnet, AU-DESSUS du fond
-- (le fond.tga en OVERLAY recouvre la bordure du template, d'où ce contournement).
-- Colore par RaffraichirAccueil selon la couleur du rang du chasseur.
carnetLisere = {}
do
    -- Filet double façon cadre MH : bande de couleur (3 px) + filet sombre
    -- fin (1 px) juste à l'intérieur, pour un rendu de cadre gravé plutôt
    -- qu'une ligne plate de couleur.
    local function Filet(t, w, h)
        t:SetColorTexture(0.62, 0.48, 0.22, 0.95)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        t:SetDrawLayer("OVERLAY", 2)
        return t
    end
    -- Haut
    carnetLisere[1] = Filet(carnet:CreateTexture(nil, "OVERLAY"), nil, 3)
    carnetLisere[1]:SetPoint("TOPLEFT", carnet, "TOPLEFT", 0, 0)
    carnetLisere[1]:SetPoint("TOPRIGHT", carnet, "TOPRIGHT", 0, 0)
    -- Bas
    carnetLisere[2] = Filet(carnet:CreateTexture(nil, "OVERLAY"), nil, 3)
    carnetLisere[2]:SetPoint("BOTTOMLEFT", carnet, "BOTTOMLEFT", 0, 0)
    carnetLisere[2]:SetPoint("BOTTOMRIGHT", carnet, "BOTTOMRIGHT", 0, 0)
    -- Gauche
    carnetLisere[3] = Filet(carnet:CreateTexture(nil, "OVERLAY"), 3, nil)
    carnetLisere[3]:SetPoint("TOPLEFT", carnet, "TOPLEFT", 0, 0)
    carnetLisere[3]:SetPoint("BOTTOMLEFT", carnet, "BOTTOMLEFT", 0, 0)
    -- Droite
    carnetLisere[4] = Filet(carnet:CreateTexture(nil, "OVERLAY"), 3, nil)
    carnetLisere[4]:SetPoint("TOPRIGHT", carnet, "TOPRIGHT", 0, 0)
    carnetLisere[4]:SetPoint("BOTTOMRIGHT", carnet, "BOTTOMRIGHT", 0, 0)
    -- Seconds filets sombres, à 3 px à l'intérieur de chaque bord
    local carnetLisereOmbre = {}
    carnetLisereOmbre[1] = Filet(carnet:CreateTexture(nil, "OVERLAY"), nil, 1)
    carnetLisereOmbre[1]:SetColorTexture(0.10, 0.07, 0.03, 0.85)
    carnetLisereOmbre[1]:SetPoint("TOPLEFT", carnet, "TOPLEFT", 0, -3)
    carnetLisereOmbre[1]:SetPoint("TOPRIGHT", carnet, "TOPRIGHT", 0, -3)
    carnetLisereOmbre[2] = Filet(carnet:CreateTexture(nil, "OVERLAY"), nil, 1)
    carnetLisereOmbre[2]:SetColorTexture(0.10, 0.07, 0.03, 0.85)
    carnetLisereOmbre[2]:SetPoint("BOTTOMLEFT", carnet, "BOTTOMLEFT", 0, 3)
    carnetLisereOmbre[2]:SetPoint("BOTTOMRIGHT", carnet, "BOTTOMRIGHT", 0, 3)
    carnetLisereOmbre[3] = Filet(carnet:CreateTexture(nil, "OVERLAY"), 1, nil)
    carnetLisereOmbre[3]:SetColorTexture(0.10, 0.07, 0.03, 0.85)
    carnetLisereOmbre[3]:SetPoint("TOPLEFT", carnet, "TOPLEFT", 3, 0)
    carnetLisereOmbre[3]:SetPoint("BOTTOMLEFT", carnet, "BOTTOMLEFT", 3, 0)
    carnetLisereOmbre[4] = Filet(carnet:CreateTexture(nil, "OVERLAY"), 1, nil)
    carnetLisereOmbre[4]:SetColorTexture(0.10, 0.07, 0.03, 0.85)
    carnetLisereOmbre[4]:SetPoint("TOPRIGHT", carnet, "TOPRIGHT", -3, 0)
    carnetLisereOmbre[4]:SetPoint("BOTTOMRIGHT", carnet, "BOTTOMRIGHT", -3, 0)
end

-- Titre sur plaque encadrée rapportée sur la couverture (façon étiquette de registre)
local carnetPlaque = CreateFrame("Frame", nil, carnet, MHH_TEMPLATE_BACKDROP)
carnetPlaque:SetSize(216, 32)
carnetPlaque:SetPoint("TOP", carnet, "TOP", 0, 28)
pcall(function()
    carnetPlaque:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    carnetPlaque:SetBackdropColor(0.30, 0.22, 0.12, 0.98)
    carnetPlaque:SetBackdropBorderColor(0.78, 0.62, 0.25, 1)
end)
local carnetTitre = carnetPlaque:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
carnetTitre:SetPoint("CENTER")
carnetTitre:SetText(L("|cffffd100Carnet de chasse|r"))
-- Petit trait décoratif sous la plaque, façon en-tête de carnet
local carnetTitreTrait = carnet:CreateTexture(nil, "OVERLAY")
carnetTitreTrait:SetColorTexture(0.55, 0.45, 0.20, 0.7)
carnetTitreTrait:SetSize(140, 2)
carnetTitreTrait:SetPoint("TOP", carnetPlaque, "BOTTOM", 0, -3)

-- -------- Onglets --------
-- -------- Onglets : marque-pages sur le côté gauche --------
local onglets = {}
local function CreerOnglet(id, texte, y, icone)
    local b = CreateFrame("Button", nil, carnet, MHH_TEMPLATE_BACKDROP)
    b:SetSize(88, 28)
    b.decalageY = y
    -- Position gérée dynamiquement : l'onglet actif sort davantage,
    -- façon marque-page que l'on tire pour l'ouvrir
    b:SetPoint("TOPRIGHT", carnet, "TOPLEFT", 2, -y)
    b:SetText(texte)
    b:SetNormalFontObject("GameFontHighlightSmall")
    -- L'icône (16 px) mange la gauche du bouton : on décale le texte
    -- pour qu'il respire, sinon « Ménagerie » colle à l'icône
    local fs = b:GetFontString()
    if fs then fs:SetPoint("CENTER", b, "CENTER", 9, 0) end
    -- Icône du marque-page : chaque onglet sa signification, façon carnet
    if icone then
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetSize(16, 16)
        t:SetPoint("LEFT", 3, 0)
        t:SetTexture("Interface\\Icons\\" .. icone)
    end
    b.id = id
    local fond = b:CreateTexture(nil, "BACKGROUND")
    fond:SetAllPoints()
    fond:SetColorTexture(0.42, 0.35, 0.20, 0.9)
    b.fondTexture = fond
    pcall(function()
        b:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        b:SetBackdropBorderColor(0.45, 0.36, 0.2, 0.9)
    end)
    b:SetScript("OnClick", function() AfficherOnglet(id) end)
    onglets[id] = b
    return b
end

-- -------- Conteneurs d'onglets --------
local pageAccueil = CreateFrame("Frame", nil, carnet)
pageAccueil:SetAllPoints()
pageAccueil:Hide()
local pageMonstres = CreateFrame("Frame", nil, carnet)
pageMonstres:SetAllPoints()
pageMonstres:Hide()
local pageSucces = CreateFrame("Frame", nil, carnet)
pageSucces:SetAllPoints()
pageSucces:Hide()
local pageProfil = CreateFrame("Frame", nil, carnet)
pageProfil:SetAllPoints()
pageProfil:Hide()
local pageContrats = CreateFrame("Frame", nil, carnet)
pageContrats:SetAllPoints()
pageContrats:Hide()
local pageOptions = CreateFrame("Frame", nil, carnet)
pageOptions:SetAllPoints()
pageOptions:Hide()
local pageCuisine = CreateFrame("Frame", nil, carnet)
pageCuisine:SetAllPoints()
pageCuisine:Hide()
local pageMissions = CreateFrame("Frame", nil, carnet)
pageMissions:SetAllPoints()
pageMissions:Hide()
-- Refresh des nouvelles pages : définis dans leurs blocs do...end respectifs
-- idem : globales préfixées (limite 200 locales)

-- Couleurs par rang (globale : utilisée par l'Accueil pour le liseré du
-- carnet ET par le Profil pour la bordure du portrait)
MHH_COULEURS_RANG = {
    { 0.55, 0.42, 0.20 }, -- Novice : brun
    { 0.72, 0.45, 0.25 }, -- Chasseur : bronze
    { 0.75, 0.75, 0.78 }, -- Vétéran : argent
    { 0.78, 0.62, 0.25 }, -- Chasseur accompli : or
    { 0.95, 0.80, 0.35 }, -- Légende de la chasse : or vif
}

-- v0.60 : couleur du rang en code hexa pour le TEXTE coloré (carte
-- échangée, Accueil, onglet Guilde). Ici, palette « rareté WoW » : gris →
-- vert → bleu → violet → orange — lue instantanément par tout joueur.
-- Le liseré du carnet et le portrait gardent la palette bronze→or MH :
-- les deux familles cohabitent volontairement (retour chasseur v0.60).
local MHH_RANG_HEX_WOW = {
    "|cffa9a9a9", -- Aspirant : gris
    "|cff1eff0c", -- Chasseur : vert
    "|cff0070dd", -- Chasseur aguerri : bleu
    "|cffa335ee", -- Vétéran : violet
    "|cffff8000", -- Légende de la chasse : orange
}
function MHH_RangHex(idx)
    return MHH_RANG_HEX_WOW[idx or 1] or MHH_RANG_HEX_WOW[1]
end

-- ================= PAGE ACCUEIL =================
-- Vue d'ensemble : chasse en cours, dernière prise, journal, progression
-- (bloc do...end : limite de 200 locales par chunk Lua, chaque page
-- regroupe ses éléments pour libérer des slots dans le chunk principal)
do
local accueilFond = CreateFrame("Frame", nil, pageAccueil, MHH_TEMPLATE_BACKDROP)
accueilFond:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 44, -42)
accueilFond:SetSize(552, 314)
pcall(function()
    accueilFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    -- Fond beige transparent : laisse lire le parchemin du carnet dessous
    accueilFond:SetBackdropColor(0.48, 0.38, 0.24, 0.35)
    accueilFond:SetBackdropBorderColor(0.85, 0.68, 0.32, 0.95)
end)
local function LabelAccueil(x, y, texte, icone)
    -- Petite icône dorée devant le libellé : rythme visuel façon carnet MH
    if icone then
        local t = pageAccueil:CreateTexture(nil, "OVERLAY")
        t:SetSize(14, 14)
        t:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", x - 19, y + 1)
        t:SetTexture("Interface\\Icons\\" .. icone)
    end
    local l = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", x, y)
    l:SetText("|cffffd100" .. texte .. "|r")
    return l
end
local accueilContratLabel = LabelAccueil(84, -134, L("CONTRAT ACTIF"), "INV_Misc_Coin_01")
local accueilContratTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
accueilContratTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 84, -152)
accueilContratTxt:SetWidth(220)
accueilContratTxt:SetJustifyH("LEFT")
accueilContratTxt:SetTextColor(1, 1, 1)
accueilContratTxt:SetShadowColor(0, 0, 0, 1)
accueilContratTxt:SetShadowOffset(1, -1)
local accueilChasseLabel = LabelAccueil(84, -200, L("CHASSE EN COURS"), "INV_Misc_MonsterClaw_04")
local accueilChasseTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
accueilChasseTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 84, -218)
accueilChasseTxt:SetWidth(220)
accueilChasseTxt:SetJustifyH("LEFT")
accueilChasseTxt:SetTextColor(1, 1, 1)
-- Contour sombre : rend les caractères lisibles sur le beige de l'encart
accueilChasseTxt:SetShadowColor(0, 0, 0, 1)
accueilChasseTxt:SetShadowOffset(1, -1)
local accueilDerniereLabel = LabelAccueil(330, -290, L("DERNIÈRE PRISE"), "INV_Misc_Bone_01")
local accueilDerniereTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
accueilDerniereTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 330, -308)
accueilDerniereTxt:SetWidth(220)
accueilDerniereTxt:SetJustifyH("LEFT")
accueilDerniereTxt:SetTextColor(1, 1, 1)
accueilDerniereTxt:SetShadowColor(0, 0, 0, 1)
accueilDerniereTxt:SetShadowOffset(1, -1)
local accueilJournalLabel = LabelAccueil(330, -134, L("JOURNAL DE CHASSE"), "INV_Misc_Book_11")
local accueilJournalTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
accueilJournalTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 330, -152)
accueilJournalTxt:SetWidth(246)
accueilJournalTxt:SetJustifyH("LEFT")
accueilJournalTxt:SetSpacing(4)
accueilJournalTxt:SetTextColor(1, 1, 1)
accueilJournalTxt:SetShadowColor(0, 0, 0, 1)
accueilJournalTxt:SetShadowOffset(1, -1)
local accueilSuccesLabel = LabelAccueil(330, -240, L("SUCCÈS"), "INV_Misc_Gem_01")
local accueilSuccesTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
accueilSuccesTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 330, -258)
accueilSuccesTxt:SetWidth(246)
accueilSuccesTxt:SetJustifyH("LEFT")
accueilSuccesTxt:SetTextColor(1, 1, 1)
accueilSuccesTxt:SetShadowColor(0, 0, 0, 1)
accueilSuccesTxt:SetShadowOffset(1, -1)
-- v0.126 : plaque « CARNET COMPLET » (colonne droite, sous le bloc
-- succès) — affichée UNIQUEMENT quand tous les succès sont obtenus.
local accueilCompletPlaque = CreateFrame("Frame", nil, pageAccueil, MHH_TEMPLATE_BACKDROP)
accueilCompletPlaque:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 330, -292)
accueilCompletPlaque:SetSize(246, 36)
pcall(function()
    accueilCompletPlaque:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    accueilCompletPlaque:SetBackdropColor(0.30, 0.22, 0.08, 0.85)
    accueilCompletPlaque:SetBackdropBorderColor(0.85, 0.68, 0.32, 1)
end)
local accueilCompletTxt = accueilCompletPlaque:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pcall(function() accueilCompletTxt:SetFont("Fonts\\FRIZQT__.TTF", 14) end)
accueilCompletTxt:SetPoint("TOP", accueilCompletPlaque, "TOP", 0, -4)
accueilCompletTxt:SetText("|cffffd100CARNET COMPLET|r")
accueilCompletTxt:SetShadowColor(0, 0, 0, 1)
accueilCompletTxt:SetShadowOffset(1, -1)
local accueilCompletSous = accueilCompletPlaque:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
accueilCompletSous:SetPoint("TOP", accueilCompletPlaque, "TOP", 0, -21)
accueilCompletSous:SetText(L("|cffa0ff50" .. "Tous les succès du chasseur sont obtenus !" .. "|r"))
accueilCompletPlaque:Hide()
local accueilRangTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
accueilRangTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 84, -58)
accueilRangTxt:SetWidth(472)
accueilRangTxt:SetJustifyH("LEFT")
accueilRangTxt:SetShadowColor(0, 0, 0, 1)
accueilRangTxt:SetShadowOffset(1, -1)
-- La ligne de rang est CLIQUABLE : elle affiche la voie du chasseur
-- (souple/stricte), un clic rouvre le serment pour en changer
local accueilRangBtn = CreateFrame("Button", nil, pageAccueil)
accueilRangBtn:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 80, -54)
accueilRangBtn:SetSize(480, 22)
accueilRangBtn:SetScript("OnClick", function() MHH_MontrerSerment() end)
-- Pas de tooltip : il s'affichait sur toute la largeur de la ligne
-- (retour de test) — le clic suffit à expliquer le bouton.
-- Barre de progression du rang de guilde : tout en haut, c'est l'essentiel
local accueilBarreBord = pageAccueil:CreateTexture(nil, "BACKGROUND")
accueilBarreBord:SetSize(460, 14)
accueilBarreBord:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 84, -76)
accueilBarreBord:SetColorTexture(0.62, 0.48, 0.22, 0.9)
local accueilBarreFond = pageAccueil:CreateTexture(nil, "BACKGROUND")
accueilBarreFond:SetSize(456, 10)
accueilBarreFond:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 86, -78)
accueilBarreFond:SetColorTexture(0.18, 0.14, 0.08, 0.95)
local accueilBarreFill = pageAccueil:CreateTexture(nil, "ARTWORK")
accueilBarreFill:SetSize(0, 10)
accueilBarreFill:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 86, -78)
accueilBarreFill:SetColorTexture(0.95, 0.78, 0.30, 1)
local accueilBarreTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
accueilBarreTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 90, -96)
accueilBarreTxt:SetWidth(452)
accueilBarreTxt:SetJustifyH("LEFT")
accueilBarreTxt:SetTextColor(0.24, 0.17, 0.09)
-- Séparateurs dorés : sous la barre de rang, entre les sections hautes/basses
local accueilSeparateur = function(y, a)
    local s = pageAccueil:CreateTexture(nil, "OVERLAY")
    s:SetHeight(2)
    s:SetWidth(472)
    s:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 84, y)
    s:SetColorTexture(0.62, 0.48, 0.22, a or 0.65)
end
accueilSeparateur(-120)

-- Plaque « CIBLE DU JOUR » (colonne droite, bas de l'Accueil) : cible
-- quotidienne proposée par la guilde, cliquable pour en faire son contrat.
local ciblePlaque = CreateFrame("Button", nil, pageAccueil, MHH_TEMPLATE_BACKDROP)
ciblePlaque:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 66, -272)
ciblePlaque:SetSize(216, 44)
pcall(function()
    ciblePlaque:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    ciblePlaque:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    ciblePlaque:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
local cibleIcone = ciblePlaque:CreateTexture(nil, "ARTWORK")
cibleIcone:SetSize(30, 30)
cibleIcone:SetPoint("LEFT", 10, 0)
cibleIcone:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
local cibleLabel = ciblePlaque:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cibleLabel:SetPoint("TOPLEFT", ciblePlaque, "TOPLEFT", 50, -6)
cibleLabel:SetText("|cffffd100CIBLE DU JOUR|r")
local cibleTxt = ciblePlaque:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cibleTxt:SetPoint("TOPLEFT", ciblePlaque, "TOPLEFT", 50, -22)
cibleTxt:SetWidth(158)
cibleTxt:SetJustifyH("LEFT")
pcall(function() cibleTxt:SetWordWrap(false) end)
cibleTxt:SetShadowColor(0, 0, 0, 1)
cibleTxt:SetShadowOffset(1, -1)
-- Surbrillance pleine taille (UI-Quickslot2 fait 64x64 : trop petit ici)
local cibleSurbrillance = ciblePlaque:CreateTexture(nil, "HIGHLIGHT")
cibleSurbrillance:SetAllPoints()
cibleSurbrillance:SetColorTexture(1, 0.82, 0.35, 0.20)
pcall(function() ciblePlaque:SetHighlightTexture(cibleSurbrillance) end)
ciblePlaque:SetScript("OnClick", function()
    if not DB.cibleJour then return end
    local deja = (DB.contrat == DB.cibleJour)
    DB.contrat = DB.cibleJour
    if deja then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Cible du jour déjà en contrat actif."))
    elseif DB.contrat then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Nouveau contrat : |cffffff00") .. DB.cibleJour .. "|r (" .. (DB.cibleJourZone or "?") .. L(") — prime : +20 points !"))
        if DB.config.son then JouerRugissement() end -- rugissement de contrat
        -- Même cérémonie que le bouton contrat : la MISSION engage la
        -- traque (bannière + consigne), sauf si la bête est déjà chassée
        -- ou déjà dans le viseur.
        if not chasseActive
            and not (UnitExists("target") and (UnitName("target") or "") == DB.cibleJour) then
            AfficherBanniere(L("TRAQUE ENGAGÉE"), 0.98, 0.72, 0.30)
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffffc44cTraque engagée :|r pistez ") .. DB.cibleJour .. L(" et ciblez-le pour lancer la chasse."))
            if MHH_CATALOGUE[DB.contrat] == (GetZoneText() or "") then MHH_JouerMusique("traque", 120) end
        end
    end
    if RaffraichirCarnet then RaffraichirCarnet() end
    RaffraichirAccueil()
    MettreAJourIndicateur()
end)
ciblePlaque:SetScript("OnEnter", function(self)
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText("|cffffd100Cible du jour|r")
        if DB.cibleJour then
            GameTooltip:AddLine(DB.cibleJour .. " (" .. (DB.cibleJourZone or "?") .. ")", 1, 1, 1, true)
            GameTooltip:AddLine(L("Rapportez cette prise pour une prime de +20 points."), 1, 1, 1, true)
            GameTooltip:AddLine(L("Clic : en faire votre contrat actif."), 0.9, 0.8, 0.4, true)
        else
            GameTooltip:AddLine(L("Aucune cible aujourd'hui — connectez-vous pour la découvrir."), 1, 1, 1, true)
        end
        GameTooltip:Show()
    end
end)
ciblePlaque:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
ciblePlaque:Hide()

-- Astuce du jour : plaque marron à bordure dorée posée sur le bord bas de
-- l'encart (façon plaque de laiton), pour rester bien lisible par-dessus
-- l'enluminure du carnet. La sagesse tourne au fil de l'année.
local ASTUCES = {
    L("Un rare ne se montre jamais deux fois au même endroit. Enfin... presque jamais."),
    L("Le piège posé avant la traque vaut dix potions avalées après le combat."),
    L("Une bête affamée sort à l'aube ; une bête repue dort au soleil. Choisissez votre heure."),
    L("Regardez les charognards : ils tournent là où le gibier blessé s'est couché."),
    L("La chasse au couteau se prépare la veille : réparez, cuisinez, dormez."),
    L("Les empreintes fraîches ont des bords nets ; les vieilles s'effritent sous la pluie."),
    L("Un monstre pris dans un piège révèle ses vraies faiblesses. Observez avant de frapper."),
    L("Le record du carnet n'est pas une fierté : c'est un défi. Battez-le d'une seconde."),
    L("Cuisinez toujours avant une prime : la cible du jour mérite un repas de fête."),
    L("Les miel et herbes ne se récoltent pas en fugue : la zone de chasse regorge de tout."),
    L("Le chasseur qui court laisse des traces ; le chasseur qui traque n'en laisse aucune."),
    L("Une série sans mourir, ça se protège : le meilleur combat est celui qu'on évite."),
    L("Le gibier de haut niveau zigzague : laissez-le s'essouffler, frappez au retour."),
    L("La nuit, les yeux brillent avant les crocs. Surveillez les fourrés sombres."),
}
local accueilAstucePlaque = CreateFrame("Frame", nil, pageAccueil, MHH_TEMPLATE_BACKDROP)
-- Plaque centrée sur le bord bas de l'encart : elle passe PAR-DESSUS la
-- bordure grise (frame level supérieur + léger débord), comme les
-- plaques gravées du carnet
accueilAstucePlaque:SetPoint("BOTTOM", accueilFond, "BOTTOM", 0, -14)
accueilAstucePlaque:SetSize(500, 34)
accueilAstucePlaque:SetFrameLevel(8)
pcall(function()
    accueilAstucePlaque:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    accueilAstucePlaque:SetBackdropColor(0.24, 0.16, 0.08, 1)
    accueilAstucePlaque:SetBackdropBorderColor(0.78, 0.62, 0.25, 1)
end)
local accueilAstuceTxt = accueilAstucePlaque:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
accueilAstuceTxt:SetPoint("CENTER")
accueilAstuceTxt:SetWidth(476)
accueilAstuceTxt:SetJustifyH("CENTER")
accueilAstuceTxt:SetShadowColor(0, 0, 0, 1)
accueilAstuceTxt:SetShadowOffset(1, -1)

RaffraichirAccueil = function()
    -- Contrat actif
    if DB.contrat then
        local zc = MHH_CATALOGUE[DB.contrat] or (DB.decouverts[DB.contrat] and DB.decouverts[DB.contrat].zone) or "?"
        accueilContratTxt:SetText("|cffffd100" .. DB.contrat .. "|r\nHabitat : " .. zc)
    else
        accueilContratTxt:SetText(L("|cff8a6d3bAucun contrat en cours.\nOuvrez une fiche du Gibier pour en prendre un.|r"))
    end
    -- Chasse en cours
    if chasseActive then
        local d = chasseDebutTemps and (time() - chasseDebutTemps) or 0
        accueilChasseTxt:SetText(
            "|cffffd100" .. chasseActive .. "|r\n"
            .. (chasseNiveau and (L("Niveau ") .. chasseNiveau .. " — ") or "")
            .. (GetZoneText() or "?") .. "\n"
            .. L("En chasse depuis ") .. math.floor(d / 60) .. " min " .. (d % 60) .. " s"
        )
    else
        accueilChasseTxt:SetText(L("|cff8a6d3bAucune chasse en cours.\nCiblez un monstre du carnet pour commencer.|r"))
    end
    -- Dernière prise
    if DB.dernierePriseNom then
        accueilDerniereTxt:SetText("|cffffd100" .. DB.dernierePriseNom .. "|r" .. (DB.dernierePriseDate and (" (" .. DB.dernierePriseDate .. ")") or ""))
    else
        accueilDerniereTxt:SetText(L("|cff8a6d3bAucune prise à ce jour.|r"))
    end
    -- Journal
    local nbSucces = 0
    for _ in pairs(DB.succes) do nbSucces = nbSucces + 1 end
    local nbZones = 0
    for _ in pairs(DB.zonesChassees) do nbZones = nbZones + 1 end
    accueilJournalTxt:SetText(table.concat({
        L("Chasses totales : |cffffd100") .. nbChasses() .. "|r",
        L("Monstres catalogués : |cffffd100") .. nbCatalogues() .. "|r",
        L("Découvertes : |cffffd100") .. nbDecouverts() .. "|r",
        L("Série sans mourir : |cffffd100") .. (DB.serie or 0) .. "|r",
        L("Zones visitées : |cffffd100") .. nbZones .. "|r",
    }, "\n"))
    accueilSuccesTxt:SetText(L("Obtenus : |cffffd100") .. nbSucces .. "|r / " .. #MHH_SUCCES
        .. (nbSucces < #MHH_SUCCES and L(" — le carnet attend ses preuves") or L(" — carnet complet !")))
    -- v0.126 : plaque dorée quand tout est obtenu
    accueilCompletPlaque:SetShown(nbSucces >= #MHH_SUCCES and #MHH_SUCCES > 0)
    -- Rang + barre de progression vers le prochain rang
    local points = DB.points or 0
    local idx, rang = RangGuilde(points)
    -- Liseré du carnet aux couleurs du rang : le classeur se pare de l'or
    -- du chasseur (appellé à chaque rafraîchissement, suit les points)
    local cr = MHH_COULEURS_RANG[idx] or MHH_COULEURS_RANG[1]
    -- Filets de bordure (le fond.tga couvre la bordure du template, on
    -- colore donc nos 4 textures liseré directement)
    if carnetLisere then
        for i = 1, 4 do carnetLisere[i]:SetColorTexture(cr[1], cr[2], cr[3], 0.95) end
    end
    accueilRangTxt:SetText(L("Rang de chasseur : ") .. MHH_RangHex(idx) .. rang .. "|r"
        .. L(" — ") .. (DB.config.killSouple and L("|cffff8844voie du compagnon|r") or L("|cff66ccffvoie du loup solitaire|r")))
    local seuilBas = MHH_RANGS[idx].seuil
    local prochainSeuil = MHH_RANGS[idx + 1] and MHH_RANGS[idx + 1].seuil or nil
    if prochainSeuil then
        local frac = (points - seuilBas) / math.max(1, prochainSeuil - seuilBas)
        accueilBarreFill:SetWidth(456 * math.min(1, math.max(0, frac)))
        accueilBarreTxt:SetText(L("Points de chasse : ") .. (DB.points or 0) .. " / " .. prochainSeuil
            .. L(" — encore ") .. math.max(0, prochainSeuil - (DB.points or 0))
            .. L(" points avant « ") .. MHH_RANGS[idx + 1].nom .. " »")
    else
        accueilBarreFill:SetWidth(456)
        accueilBarreTxt:SetText(L("Points de chasse : ") .. (DB.points or 0) .. L(" — rang maximum atteint"))
    end
    -- Plaque cible du jour : visible dès qu'une cible est proposée
    if DB.cibleJour then
        ciblePlaque:Show()
        if DB.contrat == DB.cibleJour then
            cibleTxt:SetText("|cffffff00" .. DB.cibleJour .. "|r — |cffa0ff50actif|r")
        elseif DB.contrat then
            cibleTxt:SetText("|cffffff00" .. DB.cibleJour .. "|r — |cff8a6d3bremplacer|r")
        else
            cibleTxt:SetText("|cffffff00" .. DB.cibleJour .. "|r — |cffa0ff50prendre|r")
        end
    else
        ciblePlaque:Hide()
    end
    -- Astuce du jour : tourne au fil des jours de l'année
    local j = tonumber(date("%j")) or 1
    accueilAstuceTxt:SetText(L("|cffffd100Astuce du vieux chasseur :|r ")
        .. ASTUCES[((j - 1) % #ASTUCES) + 1])
end
end -- fin bloc page Accueil

-- ================= PAGE MONSTRES =================
-- Panneau gauche : grille de badges cliquables
do
local grilleScroll = CreateFrame("ScrollFrame", nil, pageMonstres, "UIPanelScrollFrameTemplate")
grilleScroll:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 44, -84)
-- Délimitation verticale entre la grille et la fiche détail (façon carnet
-- MH : filet doré net, embouti aux extrémités comme le guide de la faune)
local grilleSepVerticale = pageMonstres:CreateTexture(nil, "OVERLAY")
grilleSepVerticale:SetWidth(3)
grilleSepVerticale:SetHeight(262)
grilleSepVerticale:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 294, -82)
grilleSepVerticale:SetColorTexture(0.62, 0.48, 0.22, 0.95)
local grilleSepHaut = pageMonstres:CreateTexture(nil, "OVERLAY")
grilleSepHaut:SetWidth(11)
grilleSepHaut:SetHeight(3)
grilleSepHaut:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 290, -82)
grilleSepHaut:SetColorTexture(0.78, 0.62, 0.25, 1)
local grilleSepBas = pageMonstres:CreateTexture(nil, "OVERLAY")
grilleSepBas:SetWidth(11)
grilleSepBas:SetHeight(3)
grilleSepBas:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 290, -341)
grilleSepBas:SetColorTexture(0.78, 0.62, 0.25, 1)
-- Trait de séparation en bas de la liste : referme la zone de scroll
local grilleTraitBas = pageMonstres:CreateTexture(nil, "OVERLAY")
grilleTraitBas:SetHeight(2)
grilleTraitBas:SetWidth(208)
grilleTraitBas:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 60, -346)
grilleTraitBas:SetColorTexture(0.62, 0.48, 0.22, 0.85)
grilleScroll:SetSize(238, 258)
local grilleContenu = CreateFrame("Frame", nil, grilleScroll)
grilleContenu:SetSize(260, 1)
grilleScroll:SetScrollChild(grilleContenu)

local NB_COLONNES = 3
local TAILLE_ICONE = 56
local ESPACEMENT = 70
local boutonsMobs = {}
local mobSelectionne = nil

-- -------- Barre de filtres : recherche + zone en cours --------
local filtreRecherche = ""
local filtreMaZone = false
local MHH_scrollHaut = false -- après un clic/déclic « Ma zone » : la liste RECOMMENCE en haut
local barreFiltres = CreateFrame("Frame", nil, pageMonstres, MHH_TEMPLATE_BACKDROP)
barreFiltres:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 44, -44)
barreFiltres:SetSize(238, 22)
pcall(function()
    barreFiltres:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    barreFiltres:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    barreFiltres:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.8)
end)
local barreRecherche = CreateFrame("EditBox", nil, barreFiltres, MHH_TEMPLATE_BACKDROP)
barreRecherche:SetPoint("TOPLEFT", 2, 1)
barreRecherche:SetSize(163, 20)
barreRecherche:SetFontObject("GameFontHighlightSmall")
barreRecherche:SetAutoFocus(false)
barreRecherche:SetMaxLetters(20)
barreRecherche:SetJustifyH("LEFT")
barreRecherche:SetTextInsets(16, 4, 0, 0) -- texte décalé du bord de l'encart
-- Pas de bordure propre : celle de la barre de filtres sert de cadre
-- au champ (supprime tout désalignement de double bordure au pixel)
pcall(function()
    barreRecherche:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    barreRecherche:SetBackdropColor(0.56, 0.46, 0.29, 0.30)
end)
barreRecherche:SetScript("OnTextChanged", function(self)
    filtreRecherche = string.lower(self:GetText() or "")
    if RaffraichirCarnet then RaffraichirCarnet() end
end)
barreRecherche:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
barreRecherche.instructions = barreRecherche:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
barreRecherche.instructions:SetPoint("LEFT", 16, -1)
barreRecherche.instructions:SetTextColor(1, 1, 1)
barreRecherche.instructions:SetText("Rechercher...")
barreRecherche:SetScript("OnEditFocusGained", function(self) self.instructions:Hide() end)
barreRecherche:SetScript("OnEditFocusLost", function(self)
    if (self:GetText() or "") == "" then self.instructions:Show() end
end)
local boutonMaZone = CreateFrame("Button", nil, barreFiltres, MHH_TEMPLATE_BACKDROP)
boutonMaZone:SetPoint("TOPRIGHT", barreFiltres, "TOPRIGHT", -2, -2)
boutonMaZone:SetSize(72, 18)
boutonMaZone:SetNormalFontObject("GameFontHighlightSmall")
boutonMaZone:SetText(L("Ma zone"))
boutonMaZone:GetFontString():SetPoint("CENTER")
boutonMaZone:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
pcall(function()
    boutonMaZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 6,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    boutonMaZone:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    boutonMaZone:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.8)
end)
local function MajAspectMaZone()
    boutonMaZone:SetText(filtreMaZone and L("|cffffd100Ma zone|r") or L("Ma zone"))
end
boutonMaZone:SetScript("OnClick", function(self)
    filtreMaZone = not filtreMaZone
    MajAspectMaZone()
    -- Déclic : la liste complète revient — on RECOMMENCE en haut, qui est
    -- justement le continent du joueur (priorité continent ci-dessous),
    -- plutôt que de sauter au milieu de la liste au milieu du carnet
    MHH_scrollHaut = true
    if RaffraichirCarnet then RaffraichirCarnet() end
end)
-- Zone où se trouve le joueur, affichée sous la barre
local zoneEnCoursTxt = pageMonstres:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
zoneEnCoursTxt:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 46, -68)
zoneEnCoursTxt:SetWidth(236)
zoneEnCoursTxt:SetJustifyH("LEFT")
zoneEnCoursTxt:SetShadowColor(0, 0, 0, 0.9)
zoneEnCoursTxt:SetShadowOffset(1, -1)
zoneEnCoursTxt:SetText(L("|cffffd100Zone actuelle : |r") .. (GetZoneText() or "?"))
-- Délimitation sous la ligne de zone en cours
local zoneTrait = pageMonstres:CreateTexture(nil, "OVERLAY")
zoneTrait:SetHeight(2)
zoneTrait:SetWidth(238)
zoneTrait:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 44, -80)
zoneTrait:SetColorTexture(0.62, 0.48, 0.22, 0.85)
-- Message affiché quand le filtre L("Ma zone") ne trouve rien
local messageZoneVide = pageMonstres:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
messageZoneVide:SetPoint("TOPLEFT", pageMonstres, "TOPLEFT", 50, -90)
messageZoneVide:SetWidth(226)
messageZoneVide:SetJustifyH("LEFT")
messageZoneVide:SetText(L("|cff8a6d3bAucun monstre catalogué dans cette zone.|r"))
messageZoneVide:Hide()

-- Pastille de couleur par zone (MH : chaque biome sa couleur)
local ZONE_COULEURS = {
    ["Favoris"] = { 0.95, 0.82, 0.35 },
    ["Bois de la Pénombre"]      = {0.35, 0.60, 0.30},
    ["Comté de l'Ouest"]     = {0.40, 0.55, 0.85},
    ["Durotar"]              = {0.80, 0.35, 0.20},
    ["Mulgore"]              = {0.35, 0.50, 0.70},
    ["Teldrassil"]           = {0.25, 0.65, 0.35},
    ["Les Tarides"]            = {0.85, 0.70, 0.25},
    ["Les Carmines"]         = {0.55, 0.20, 0.25},
    ["Mille Pointes"]        = {0.75, 0.65, 0.40},
    ["Orneval"]              = {0.30, 0.55, 0.25},
    ["Steppes Ardentes"]     = {0.85, 0.40, 0.15},
    ["Marais des Chagrins"]  = {0.30, 0.50, 0.45},
    ["Les Paluns"]           = {0.35, 0.55, 0.75},
    ["Loch Modan"]           = {0.60, 0.55, 0.30},
    ["Gangrebois"]           = {0.55, 0.60, 0.25}, -- vert-jaune maladif : le bois n'est pas mort
    ["Tanaris"]               = {0.85, 0.75, 0.45},
    ["Gorges des Chants éternels"] = {0.50, 0.35, 0.65},
    ["Sombrerivage"]         = {0.30, 0.40, 0.60},
    ["Les Serres-Rocheuses"]     = {0.45, 0.40, 0.35},
    ["Désolace"]             = {0.55, 0.45, 0.40},
    ["Marécage d'Âprefange"] = {0.35, 0.45, 0.35},
    ["Féralas"]              = {0.40, 0.60, 0.40},
    ["Cratère d'Un'Goro"]    = {0.80, 0.50, 0.25},
    ["Silithus"]             = {0.70, 0.65, 0.35},
    ["Azshara"]              = {0.30, 0.45, 0.70},
    ["Hiverpré"]             = {0.85, 0.90, 0.95},
    ["Berceau-de-l'Hiver"]   = {0.85, 0.90, 0.95}, -- même neige : le serveur nomme Winterspring ainsi (v0.25)
    ["Dun Morogh"]           = {0.80, 0.85, 0.95},
    ["Clairières de Tirisfal"]   = {0.35, 0.35, 0.40},
    ["Marches de l'Ouest"]   = {0.70, 0.65, 0.35},
    ["Forêt des Pins-Argentés"] = {0.40, 0.45, 0.50},
    ["Contreforts de Hautebrande"] = {0.50, 0.60, 0.30},
    ["Montagnes d'Alterac"]  = {0.75, 0.75, 0.80},
    ["Hautes-terres d'Arathi"] = {0.50, 0.45, 0.35},
    ["Vallée de Strangleronce"] = {0.30, 0.65, 0.35},
    ["Terres ingrates"]      = {0.70, 0.50, 0.30},
    ["Gorge des Vents brûlants"] = {0.75, 0.45, 0.25},
    ["Terres foudroyées"]    = {0.60, 0.35, 0.30},
    ["Maleterres de l'Ouest"] = {0.55, 0.55, 0.60},
    ["Maleterres de l'Est"]  = {0.60, 0.50, 0.55},
    ["Les Hinterlands"]      = {0.35, 0.55, 0.40},
    ["Hurlevent"]            = {0.35, 0.50, 0.85}, -- bleu cité
}
local COULEUR_DEFAUT = {0.78, 0.62, 0.25} -- doré

-- Lookup insensible a la casse : le data file et le client n'écrivent
-- pas toujours les zones pareil (déja corrigé ci-dessus, ceinture +
-- bretelles pour l'avenir).
local ZONE_COULEURS_NORM = {}
for k, v in pairs(ZONE_COULEURS) do ZONE_COULEURS_NORM[string.lower(k)] = v end
local function CouleurZone(zone)
    if not zone then return COULEUR_DEFAUT end
    return ZONE_COULEURS_NORM[string.lower(zone)] or ZONE_COULEURS[zone] or COULEUR_DEFAUT
end

-- Fiche détail (panneau droit)
local detailFond = CreateFrame("Frame", nil, pageMonstres, MHH_TEMPLATE_BACKDROP)
detailFond:SetPoint("TOPRIGHT", pageMonstres, "TOPRIGHT", -44, -44)
detailFond:SetSize(288, 316)
-- Panneau encadré : distingue la fiche du parchemin (façon MH)
pcall(function()
    detailFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    detailFond:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    detailFond:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.8)
end)
local detailPortrait = detailFond:CreateTexture(nil, "ARTWORK")
detailPortrait:SetSize(104, 104)
detailPortrait:SetPoint("TOPLEFT", 14, -14)
-- Encadrement metal en 4 barres (meme style que la grille) autour du portrait
local detailPortraitCadres = {}
do
    local barres = {
        { w = 110, h = 3, p1 = "TOPLEFT",     rp = detailPortrait, p2 = "TOPLEFT",     x = -3, y = 3 },
        { w = 110, h = 3, p1 = "BOTTOMLEFT",  rp = detailPortrait, p2 = "BOTTOMLEFT",  x = -3, y = -3 },
        { w = 3,  h = 110, p1 = "TOPLEFT",     rp = detailPortrait, p2 = "TOPLEFT",     x = -3, y = 3 },
        { w = 3,  h = 110, p1 = "TOPRIGHT",    rp = detailPortrait, p2 = "TOPRIGHT",    x = 3,  y = 3 },
    }
    for _, bdef in ipairs(barres) do
        local t = detailFond:CreateTexture(nil, "OVERLAY")
        t:SetSize(bdef.w, bdef.h)
        t:SetPoint(bdef.p1, bdef.rp, bdef.p2, bdef.x, bdef.y)
        t:SetColorTexture(0.35, 0.30, 0.20, 0.9)
        detailPortraitCadres[#detailPortraitCadres + 1] = t
    end
end
-- Espace sous le portrait : niveau et statut de la bête (data file)
local detailNiveau = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailNiveau:SetPoint("TOPLEFT", 16, -122)
detailNiveau:SetJustifyH("LEFT")
detailNiveau:SetWidth(100)
local detailNom = detailFond:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
detailNom:SetPoint("TOPLEFT", 124, -16)
detailNom:SetJustifyH("LEFT")
detailNom:SetWidth(148)
local detailZone = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailZone:SetPoint("TOPLEFT", 140, -38)
-- Retour à la ligne pour les longs noms de zone (ne déborde plus de l'encart)
detailZone:SetWidth(138)
detailZone:SetJustifyH("LEFT")
detailZone:SetShadowColor(0, 0, 0, 1)
detailZone:SetShadowOffset(1, -1)
-- Pastille de couleur de l'habitat (façon bouton de biome MH)
local detailHabitatIcone = detailFond:CreateTexture(nil, "ARTWORK")
detailHabitatIcone:SetSize(12, 12)
detailHabitatIcone:SetPoint("TOPLEFT", 124, -37)
detailHabitatIcone:SetColorTexture(0.5, 0.5, 0.5, 0.95)
local detailMenace = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
detailMenace:SetPoint("TOPLEFT", 124, -70)
-- Rangée de menace : 5 pips carrés + 5 étoiles en texture (les glyphes texte
-- type étoile ne sont pas rendus par les polices WoW ; les textures si).
-- Doublure : si la texture étoile manque sur un client, les pips restent visibles.
MHH_pipsMenace, MHH_etoilesMenace = {}, {} -- globales préfixées (limite 200)
for i = 1, 5 do
    -- Ancrées sur le texte « Menace : » : alignement vertical exact,
    -- quel que soit le rendu de la police. Étoiles agrandies (16px).
    local pip = detailFond:CreateTexture(nil, "ARTWORK")
    pip:SetSize(12, 12)
    pip:SetPoint("LEFT", detailMenace, "RIGHT", 6 + (i - 1) * 16, -1)
    MHH_pipsMenace[i] = pip
    local et = detailFond:CreateTexture(nil, "OVERLAY")
    et:SetSize(16, 16)
    et:SetPoint("CENTER", pip, "CENTER")
    et:SetTexture("Interface\\Common\\FavoritesIcon")
    et:SetVertexColor(0.78, 0.62, 0.25, 0.95)
    MHH_etoilesMenace[i] = et
end
-- Encart « fiche d'identité » : regroupe menace / gabarit / sensibilités,
-- façon panneau MH. Niveau passé SOUS le fond de la fiche pour rester
-- derrière les textes (best effort selon les clients).
local detailEncart = CreateFrame("Frame", nil, detailFond)
detailEncart:SetPoint("TOPLEFT", 112, -78)
detailEncart:SetSize(164, 100)
pcall(function()
    detailEncart:SetFrameLevel(detailFond:GetFrameLevel() - 1)
    detailEncart:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    detailEncart:SetBackdropColor(0.30, 0.22, 0.10, 0.30)
    detailEncart:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.55)
end)
-- Sensibilités : icône + nom + NIVEAU façon MH (I à III, les glyphes
-- étoiles ne sont pas rendus par les polices WoW). Une ligne par école.
local detailFaiblesseLabel = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailFaiblesseLabel:SetPoint("TOPLEFT", 124, -132)
local faiblesseIcons = {}
local faiblesseNoms = {}
for i = 1, 3 do
    local t = detailFond:CreateTexture(nil, "ARTWORK")
    t:SetSize(12, 12)
    t:SetPoint("TOPLEFT", 124 + (i - 1) * 74, -147)
    t:Hide()
    faiblesseIcons[i] = t
    local n = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    n:SetPoint("TOPLEFT", t, "TOPRIGHT", 4, -1)
    n:SetJustifyH("LEFT")
    faiblesseNoms[i] = n
end
-- Barre « gabarit rencontré » (façon Hunted Size MH : plage de niveaux min–max)
-- Remontée à l'ancienne place des sensibilités : c'est l'info qu'on lit en premier.
local detailGabaritLabel = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailGabaritLabel:SetPoint("TOPLEFT", 124, -92)
local detailGabaritBg = detailFond:CreateTexture(nil, "BACKGROUND")
detailGabaritBg:SetSize(120, 8)
detailGabaritBg:SetPoint("TOPLEFT", 124, -104)
detailGabaritBg:SetColorTexture(0.25, 0.20, 0.12, 0.9)
local detailGabaritFill = detailFond:CreateTexture(nil, "ARTWORK")
detailGabaritFill:SetSize(0, 8)
detailGabaritFill:SetPoint("TOPLEFT", 124, -104)
detailGabaritFill:SetColorTexture(0.78, 0.62, 0.25, 0.95)
-- Légende de la jauge de gabarit : échelle des niveaux 1 -> 60
local detailGabaritMin = detailFond:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
detailGabaritMin:SetPoint("TOPLEFT", detailGabaritBg, "BOTTOMLEFT", -2, 0)
detailGabaritMin:SetText("0")
local detailGabaritMax = detailFond:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
detailGabaritMax:SetPoint("TOPRIGHT", detailGabaritBg, "BOTTOMRIGHT", 0, 0)
detailGabaritMax:SetText(L("2200 cm"))
-- Trophée de COURONNE du gabarit (façon bounty box MH) : médaille à
-- droite de la barre — dorée (couronne d'or) ou argentée (argent).
-- Les mesures restent détaillées dans la colonne de stats.
local detailCouronne = detailFond:CreateTexture(nil, "OVERLAY")
detailCouronne:SetSize(14, 14)
detailCouronne:SetPoint("TOPLEFT", 258, -98)
detailCouronne:SetTexture("Interface\\Common\\ReputationStar")
detailCouronne:Hide()
-- Délimitation légère entre le bloc d'identité et les statistiques
local detailTraitStats = detailFond:CreateTexture(nil, "OVERLAY")
-- Séparateur AU-DESSUS de la description, volontairement bien visible
-- (or plein, 2 px) : la note du naturaliste forme un encart net.
detailTraitStats:SetHeight(2)
detailTraitStats:SetWidth(256)
detailTraitStats:SetPoint("TOPLEFT", 16, -172)
detailTraitStats:SetColorTexture(0.82, 0.64, 0.28, 0.85)
-- Note du naturaliste (2 lignes max, texte intégral — plus de troncature
-- brutale : on répartit les stats en 2 colonnes pour gagner la place)
local detailNote = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailNote:SetPoint("TOPLEFT", 13, -180)
detailNote:SetJustifyH("CENTER")
detailNote:SetWidth(262)
detailNote:SetSpacing(3)
-- Dernière note affichée (pour l'infobulle de survol)
local derniereNote = nil
-- Survol de la note : texte INTÉGRAL dans une infobulle. Les notes
-- longues se replient sur plusieurs lignes dans la fiche — mais si
-- une coupure saute encore aux yeux, tout reste lisible ici.
local noteHover = CreateFrame("Frame", nil, detailFond)
noteHover:SetPoint("TOPLEFT", 8, -176)
noteHover:SetSize(272, 64)
noteHover:SetScript("OnEnter", function(self)
    if GameTooltip and derniereNote then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(L("|cffffd100Observations du naturaliste|r"), 1, 1, 1)
        GameTooltip:AddLine(derniereNote, 0.86, 0.78, 0.65, true)
        GameTooltip:Show()
    end
end)
noteHover:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
-- Stats de chasse : 2 colonnes gauche/droite (au lieu d'une pile haute
-- qui débordait sur les boutons quand la note était longue)
-- Séparateur SOUS la description (symétrique du trait du haut) :
-- la note est encadrée, la zone de stats démarre proprement.
local detailTraitNoteBas = detailFond:CreateTexture(nil, "OVERLAY")
detailTraitNoteBas:SetHeight(2)
detailTraitNoteBas:SetWidth(256)
detailTraitNoteBas:SetPoint("TOPLEFT", 16, -218)
detailTraitNoteBas:SetColorTexture(0.82, 0.64, 0.28, 0.85)
local detailStatsG = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailStatsG:SetPoint("TOPLEFT", 16, -230)
detailStatsG:SetJustifyH("LEFT")
detailStatsG:SetWidth(128)
detailStatsG:SetSpacing(4)
local detailStatsD = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailStatsD:SetPoint("TOPLEFT", 150, -230)
detailStatsD:SetJustifyH("LEFT")
detailStatsD:SetWidth(126)
detailStatsD:SetSpacing(4)
-- Bouton de contrat : texte mis à jour par RaffraichirDetail (définie juste après)
local MettreAJourBoutonContrat = function() end
-- Bouton favori : idem (défini après boutonCarte, appelé par RaffraichirDetail)
local MettreAJourBoutonFavori = function() end

local function EtoilesMenace(nom, info)
    -- Menace simple : 1 à 5. Jamais chassée ? L'estimation du data file
    -- (NIVEAUX) sert en attendant la première prise. Une rare ÉLITE
    -- gagne une étoile : le dragon doré du client se lit dans le carnet.
    local niv = (info and info.nivMax) or MHH_NIVEAUX[nom] or 0
    -- Menace ABSOLUE (dangerosité de la bête, pas du chasseur) : un
    -- joueur bas niveau voyait TOUT à 4-5 étoiles — illisible. Paliers
    -- sur l'échelle 1-60 ; l'élite gagne une étoile ; 5 = élite de haut
    -- niveau uniquement (le satyre de Gangrebois retombe à 4).
    local base = 1
    if niv >= 45 then base = 4
    elseif niv >= 30 then base = 3
    elseif niv > 0 then base = 2 end
    if MHH_ELITES[nom] then base = base + 1 end
    return math.min(base, MHH_ELITES[nom] and 5 or 4)
end

local function RaffraichirDetail()
    -- Consultation de la fiche : le badge NEW de ce monstre est effacé
    if mobSelectionne then
        if DB.chasses[mobSelectionne] then DB.chasses[mobSelectionne].nouveau = nil end
        if DB.decouverts[mobSelectionne] then DB.decouverts[mobSelectionne].nouveau = nil end
    end
    if not mobSelectionne then
        detailNom:SetText("")
        detailNote:SetText("")
        detailStatsG:SetText("")
        detailStatsD:SetText("")
        detailZone:SetText("")
        detailMenace:SetText("")
        for i = 1, 5 do
            MHH_pipsMenace[i]:Hide()
            MHH_etoilesMenace[i]:Hide()
        end
        detailPortrait:SetTexture(nil)
        return
    end
    local info = DB.chasses[mobSelectionne] or {}
    local zone = MHH_CATALOGUE[mobSelectionne] or (DB.decouverts[mobSelectionne] and DB.decouverts[mobSelectionne].zone) or "?"
    -- Statut sous le portrait : le niveau vit dans le gabarit (estimation
    -- ou observé) — ici, seulement le statut quand le data le connaît
    -- Une seule ligne claire : le niveau OBSERVÉ prime (vérité du terrain),
    -- sinon l'estimation du data file. L'élite s'ajoute derrière.
    local nivData = MHH_NIVEAUX[mobSelectionne]
    local statutNiv = ""
    if info.nivMin and info.nivMax then
        statutNiv = "|cffa58b54Niveau " .. info.nivMin
            .. (info.nivMin ~= info.nivMax and ("–" .. info.nivMax) or "")
            .. " observé|r"
    elseif nivData then
        statutNiv = "|cffa58b54Niveau " .. nivData .. "|r"
    end
    -- v0.120 : niveau de rareté toujours affiché — « Rare » doré pour
    -- tout le gibier, « Élite rare » rouge pour les élites (avant, les
    -- rares simples n'avaient aucune étiquette de rareté)
    if MHH_ELITES[mobSelectionne] then
        if statutNiv ~= "" then statutNiv = statutNiv .. "\n" end
        statutNiv = statutNiv .. "|cffff6a6aÉlite rare|r"
    else
        if statutNiv ~= "" then statutNiv = statutNiv .. "\n" end
        statutNiv = statutNiv .. "|cffffd100" .. L("Rare") .. "|r"
    end
    -- Mention CAPTURABLE (v0.64) : le spécimen rejoint l'enclos s'il est
    -- tué pendant une chasse — repère vert sous le portrait (retour
    -- utilisateur : rien ne le distinguait dans le gibier)
    local cleSpecFiche = (MHH_SpecimenDe and MHH_SpecimenDe(mobSelectionne))
    if cleSpecFiche then
        if statutNiv ~= "" then statutNiv = statutNiv .. "\n" end
        -- v0.119 : la mention devient DYNAMIQUE — elle dit ce qu'on a
        -- réellement (les libellés « Spécimen en enclos » existaient dans
        -- la traduction depuis la v0.64 mais n'étaient jamais affichés).
        -- v0.121 : résolu par clé canonique (graphies serveur incluses).
        if DB.menagerie and DB.menagerie[cleSpecFiche] then
            statutNiv = statutNiv .. "|cffa0ff50Capturé|r"
        else
            statutNiv = statutNiv .. "|cff88e48aCapturable|r"
        end
    end
    detailNiveau:SetText(statutNiv)
    detailNom:SetText((DB.contrat == mobSelectionne and "|cffff69b4» |r" or "") .. "|cffffd100" .. MHH_NomAffiche(mobSelectionne) .. "|r")
    -- Titre survolable : s'il est tronqué, le tooltip montre le nom entier
    detailNom.nomComplet = MHH_NomAffiche(mobSelectionne)
    detailNom:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.nomComplet then return end
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText("|cffffd100" .. self.nomComplet .. "|r")
        GameTooltip:Show()
    end)
    detailNom:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    -- Noms très longs (« Maître des esclaves cœur-noir »…) : police
    -- rétrogradée puis tronquée — jamais de débordement sur la fiche
    pcall(function()
        detailNom:SetFontObject("GameFontNormalLarge")
        if detailNom:GetStringWidth() > 148 then
            detailNom:SetFontObject("GameFontNormal")
        end
        local nomz = MHH_NomAffiche(mobSelectionne)
        while detailNom:GetStringWidth() > 148 and #nomz > 6 do
            nomz = string.sub(nomz, 1, #nomz - 1)
            detailNom:SetText((DB.contrat == mobSelectionne and "|cffff69b4» |r" or "")
                .. "|cffffd100" .. nomz .. "…|r")
        end
    end)
    -- Habitat : coordonnées de spawn si le data file en fournit
    -- Coordonnées : le spawn du data file si on l'a, SINON la position du
    -- repérage en jeu (là où la bête a été croisée/tuée) — la piste
    -- n'est plus laissée vide après une première rencontre.
    local coords = MHH_COORDS[mobSelectionne]
    local repere = (not coords) and DB.reperees and DB.reperees[mobSelectionne]
    if coords then
        detailZone:SetText(L("Habitat : ") .. zone
            .. " |cffc9a24a(" .. coords[1] .. ", " .. coords[2] .. ")|r")
    elseif repere and repere.x and repere.y and repere.x > 0 and repere.y > 0 then
        detailZone:SetText(L("Habitat : ") .. zone
            .. " |cffc9a24a(" .. math.floor(repere.x * 100 + 0.5)
            .. ", " .. math.floor(repere.y * 100 + 0.5) .. ")|r")
    else
        detailZone:SetText(L("Habitat : ") .. zone)
    end
    -- Couleur de l'habitat
    local cHabitat = CouleurZone(zone)
    detailHabitatIcone:SetColorTexture(cHabitat[1], cHabitat[2], cHabitat[3], 0.95)
    -- Menace : étoiles seules, le score numérique est dans le décompte des pips
    detailMenace:SetText("|cffc9a24aMenace :|r")
    for i = 1, 5 do
        -- Façon MH : seules les étoiles GAGNÉES s'affichent — les non
        -- acquises sont masquées, comme sur les menus de Monster Hunter
        if i <= EtoilesMenace(mobSelectionne, info) then
            MHH_pipsMenace[i]:Show()
            MHH_pipsMenace[i]:SetColorTexture(0.35, 0.30, 0.22, 0.85)
            MHH_etoilesMenace[i]:Show()
            MHH_etoilesMenace[i]:SetVertexColor(0.95, 0.78, 0.25, 1.0)
        else
            MHH_pipsMenace[i]:Hide()
            MHH_etoilesMenace[i]:Hide()
        end
    end
    -- Sensibilités : icône + nom + niveau (I à III), une ligne par école
    local faib = MHH_FAIBLESSES[mobSelectionne] or SensibilitesAuto(mobSelectionne)
    for i = 1, 3 do
        if faib and faib[i] and MHH_ECOLE[faib[i][1]] then
            local niveau = math.min(3, math.max(1, faib[i][2] or 1))
            faiblesseIcons[i]:SetTexture(MHH_ECOLE[faib[i][1]].icone)
            faiblesseIcons[i]:Show()
            faiblesseNoms[i]:SetText(MHH_ECOLE[faib[i][1]].nom
                .. " |cffffd100" .. string.rep("I", niveau) .. "|r")
        else
            faiblesseIcons[i]:Hide()
            faiblesseNoms[i]:SetText("")
        end
    end
    if faib and faib[1] then
        detailFaiblesseLabel:SetText(L("|cffc9a24aSensibilités :|r"))
    else
        detailFaiblesseLabel:SetText(L("|cffc9a24aSensibilités :|r inconnues"))
    end
    -- Gabarit : barre RELATIVE au spécimen. L'ancienne échelle fixe
    -- (0 → 2200 cm, calibrée pour une « taille » de hitbox à 12 unités)
    -- laissait tout gibier réel (~0,5–2 unités) à ~5% de remplissage :
    -- une barre morte. Désormais : la barre couvre la plage PLAUSIBLE de
    -- CE spécimen (de la plus petite prise ×0,85 au record ×1,30 — soit
    -- exactement les bornes du facteur de taille du gabarit), et le
    -- remplissage marque la DERNIÈRE prise dans cette plage. Elle vit au
    -- fil des chasses, et l'échelle dépend de la bête (un lapin et un
    -- dragon n'ont pas la même barre).
    local tailleAff = info.taille or info.tailleRecord
    if tailleAff then
        -- Taille MESUREE : envergure approximative en CENTIMETRES
        -- (flaveur MH : ~2 rayons de hitbox, 1 yard = 91,44 cm)
        local cmA = (GabaritEnCm and GabaritEnCm(tailleAff)) or "?"
        detailGabaritLabel:SetText(L("Gabarit : ~") .. cmA .. L(" cm"))
        local tMin, tMax
        if info.rayonBase and info.rayonBase > 0 then
            -- v0.24 : échelle EXACTE du spécimen — de base×0,85 à
            -- base×1,30, les vraies bornes du facteur : le remplissage
            -- correspond au facteur de la prise (argent ≈ 78 %, or ≈ 93 %).
            tMin = info.rayonBase * 0.85
            tMax = info.rayonBase * 1.30
        else
            -- Anciennes prises (sans base mémorisée) : repli sur
            -- l'heuristic précédente.
            tMin = (info.tailleMin or tailleAff) * 0.85
            tMax = (info.tailleRecord or tailleAff) * 1.30
        end
        -- Position de la dernière prise dans la plage PLAUSIBLE :
        -- le facteur aléatoire du gabarit va de 0,85 à 1,30 — la barre
        -- couvre donc toute la taille possible du spécimen, et la
        -- couronne d'or correspond au bout droit de la barre (~97%).
        -- Une prise unique tombe vers le tiers ; chaque nouvelle prise
        -- déplace le remplissage, et l'échelle « joue » d'un mob à
        -- l'autre (le pied de l'échelle dépend de la bête).
        local frac = (tailleAff - tMin) / math.max(1e-6, tMax - tMin)
        local cmMin = (GabaritEnCm and GabaritEnCm(tMin)) or "?"
        local cmMax = (GabaritEnCm and GabaritEnCm(tMax)) or "?"
        local x2 = 124 + 120 * math.min(1, math.max(0, frac))
        detailGabaritLabel:Show()
        detailGabaritBg:Show()
        detailGabaritMin:Show()
        detailGabaritMin:SetText(cmMin .. L(" cm"))
        detailGabaritMax:SetText(cmMax .. L(" cm"))
        detailGabaritMax:Show()
        detailGabaritFill:Show()
        detailGabaritFill:ClearAllPoints()
        detailGabaritFill:SetPoint("TOPLEFT", 124, -104)
        detailGabaritFill:SetSize(math.max(6, x2 - 124), 8)
        detailGabaritFill:SetColorTexture(0.78, 0.62, 0.25, 0.95)
    else
        -- Jamais mesuré : la barre RESTE (stable d'un mob a l'autre),
        -- grisée, "??" en guise de mesure — le carnet attend la prise.
        detailGabaritLabel:SetText("|cffa58b54Gabarit : pas encore mesuré|r")
        detailGabaritLabel:Show()
        detailGabaritBg:Show()
        detailGabaritFill:Hide()
        detailGabaritMin:Show()
        detailGabaritMin:SetText("?")
        detailGabaritMax:SetText("|cffa58b54?? cm|r")
        detailGabaritMax:Show()
    end
    -- Observations du naturaliste (2 lignes max, texte intégral), puis
    -- stats réparties en 2 colonnes : plus rien ne déborde sur les boutons.
    -- Description du naturaliste : elle ne se lit QUE sur une bête
    -- CONNUE (croisée en jeu ou déjà prise) — l'inconnue reste une
    -- énigme du carnet, façon MH. Le texte vient du bestiaire rédigé à
    -- la main, sinon du générateur (famille + zone), stable au relog.
    local note = MHH_NOTES[mobSelectionne]
    local nb = info.kills or 0
    local connu = (DB.decouverts and DB.decouverts[mobSelectionne]) or nb > 0
    if not connu then
        if info.premiere then
            note = L("Spécimen encore mal connu du carnet. Première prise : ") .. info.premiere .. "."
        else
            note = L("Spécimen encore mal connu du carnet.")
        end
    elseif not note then
        note = MHH_NoteGeneree(mobSelectionne)
    end
    note = note or L("Observations en cours.")
    -- Plus de troncature à 110 caractères : la note complète s'affiche
    -- (le bas de la fiche s'adapte à sa hauteur réelle) et le survol
    -- donne de toute façon le texte intégral. L'ancienne coupe
    -- tombait parfois AU MILIEU d'un code couleur |cff……. : la suite
    -- du texte passait dans la couleur de la météo.
    derniereNote = note
    -- Note du ciel : saveur météo SI le joueur est dans l'habitat du
    -- gibier (sinon on afficherait la météo d'ailleurs — fausse piste)
    local nomMeteoFiche = MeteoActuelle()
    if nomMeteoFiche and zone ~= "?" and GetZoneText() ~= "" and GetZoneText() == zone then
        local saveursCiel = {
            L("Le ciel, ici : ") .. nomMeteoFiche .. ".",
            L("Au-dessus de la piste : ") .. nomMeteoFiche .. ".",
            L("Carnet, heure de l'observation : ") .. nomMeteoFiche .. ".",
        }
        note = note .. "\n|cff7fb2ff" .. saveursCiel[math.random(#saveursCiel)] .. "|r"
    end
    detailNote:SetText("|cff8a6d3b« " .. note .. " »|r")
    -- Le satyre ecrivait 3 lignes : le separateur bas et les stats
    -- descendent dynamiquement selon la hauteur REELLE de la note.
    pcall(function()
        local hN = detailNote:GetStringHeight() or 30
        -- Équidistance : le texte flotte au centre de son encart,
        -- même espace (8 px) entre lui et chaque délimiteur.
        local yBas = -180 - hN - 8
        detailTraitNoteBas:SetPoint("TOPLEFT", 16, yBas)
        detailStatsG:SetPoint("TOPLEFT", 16, yBas - 12)
        detailStatsD:SetPoint("TOPLEFT", 150, yBas - 12)
    end)
    local colG = L("Chasses : |cffffd100") .. (info.kills or 0) .. "|r\n"
        .. L("Première : ") .. (info.premiere or "?") .. "\n"
        .. L("Dernière : ") .. (info.derniere or "?")
    detailStatsG:SetText(colG)
    local colD = L("Sans égratignure : ") .. (info.sansMourir or 0) .. "/" .. (info.kills or 0)
    if info.recordMin then
        colD = colD .. "\nRecord : |cffffd100" .. math.floor(info.recordMin / 60)
            .. " min " .. (info.recordMin % 60) .. " s|r"
    end
    -- Gabarit en stats : UNE ligne courte. « max » = le record connu
    -- (dernier gabarit s'il n'y a pas encore de record), en centimètres.
    -- La couronne se lit inline — la médaille graphique reste près de la
    -- barre de gabarit (haut droit de la fiche).
    if info.taille or info.tailleRecord then
        local tMax = info.tailleRecord or info.taille
        local cmMax = (GabaritEnCm and GabaritEnCm(tMax)) or "?"
        colD = colD .. "\n" .. L("Gabarit max : |cffffff00") .. cmMax .. L(" cm|r")
        if info.couronne == "or" then
            colD = colD .. L("  |cffffcc44(couronne d'or !)|r")
        elseif info.couronne == "argent" then
            colD = colD .. L("  |cffc0c0c0(couronne d'argent)|r")
        end
    else
        colD = colD .. "\n" .. L("|cffa58b54Gabarit max : ?? cm|r")
    end
    -- Médaille : or = couronne d'or, argentée = couronne d'argent
    if info.couronne == "or" then
        detailCouronne:Show()
        detailCouronne:SetVertexColor(1, 0.85, 0.35, 1)
    elseif info.couronne == "argent" then
        detailCouronne:Show()
        detailCouronne:SetVertexColor(0.72, 0.72, 0.80, 1)
    else
        detailCouronne:Hide()
    end
    detailStatsD:SetText(colD)
    -- Portrait : 3D si le mob est ciblé, sinon silhouette
    -- v0.30 : nom secret (poison client) → les == ne risquent rien, mais
    -- on blinde pour éviter toute surprise de ce client capricieux
    local nomCible = NomOrdinaire(UnitName("target")) or ""
    if nomCible == mobSelectionne then
        DefinirPortrait(detailPortrait, "target")
    else
        local vt = TextureVignette(mobSelectionne)
        if vt then
            detailPortrait:SetTexture(vt)
        else
            local v = IconeGibier(mobSelectionne)
            if v then
                detailPortrait:SetTexture("Interface\\Icons\\" .. v)
            else
                -- Repli CARRÉ (griffe) : le point d'interrogation était rond
                detailPortrait:SetTexture("Interface\\Icons\\INV_Misc_MonsterClaw_04")
            end
        end
        -- Portrait en couleur dès la RENCONTRE (découverte au ciblage
        -- ou bête déjà chassée) ; les JAMAIS rencontrés montrent la
        -- vignette MYSTÈRE (inconnu.tga) — comme dans la grille.
        local vuMob = (DB.decouverts and DB.decouverts[mobSelectionne]) or (info.kills and info.kills > 0)
        for _, t in ipairs(detailPortraitCadres) do
            if info.kills and info.kills > 0 then
                t:SetColorTexture(0.78, 0.62, 0.25, 0.95)
            else
                t:SetColorTexture(0.35, 0.30, 0.20, 0.9)
            end
        end
        if not vuMob then
            local okMyst = true
            pcall(function()
                local ok = detailPortrait:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\Specimens\\inconnu.tga")
                if ok == false then
                    ok = detailPortrait:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\Vignettes\\inconnu.tga")
                end
                if ok == false then okMyst = false end
            end)
            if okMyst then
                detailPortrait:SetTexCoord(0, 1, 0, 1)
                detailPortrait:SetDesaturated(false)
                detailPortrait:SetVertexColor(0.72, 0.72, 0.72)
            else
                detailPortrait:SetTexCoord(0, 1, 0, 1)
                detailPortrait:SetVertexColor(1, 1, 1)
                detailPortrait:SetDesaturated(true)
            end
        else
            detailPortrait:SetTexCoord(0, 1, 0, 1)
            detailPortrait:SetVertexColor(1, 1, 1)
            detailPortrait:SetDesaturated(false)
        end
    end
    MettreAJourBoutonContrat()
    MettreAJourBoutonFavori()
end

-- Les contrats se prennent désormais UNIQUEMENT dans la fenêtre
-- Contrats (offres du jour) — le bouton « Prendre le contrat » de la
-- fiche Gibier a été retiré. La fonction garde son nom (nombreux call
-- sites) et ne pilote plus que « Voir sur la carte ».
-- NB : boutonCarte est créé après, d'où la déclaration anticipée
local boutonCarte, boutonCarteTxt
MettreAJourBoutonContrat = function()
    if not mobSelectionne then
        boutonCarteTxt:SetText("")
        boutonCarte:Disable()
        return
    end
    -- Voir sur la carte : actif dès que la zone est résolue (visitée ou
    -- trouvée par nom dans l'arbre des cartes)
    local zoneCarte = MHH_CATALOGUE[mobSelectionne] or (DB.decouverts[mobSelectionne] and DB.decouverts[mobSelectionne].zone) or "?"
    boutonCarte:Enable()
    if zoneCarte ~= "?" and TrouverCarteZone(zoneCarte) then
        boutonCarteTxt:SetText("|cffffd100Voir sur la carte|r")
    else
        boutonCarteTxt:SetText("|cff8a6d3bCarte inconnue|r")
    end
end
-- Voir sur la carte : ouvre la carte de l'habitat du monstre affiché
boutonCarte = CreateFrame("Button", nil, detailFond, MHH_TEMPLATE_BACKDROP)
boutonCarte:SetPoint("BOTTOMLEFT", 28, 10)
boutonCarte:SetSize(128, 22)
pcall(function()
    boutonCarte:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    boutonCarte:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    boutonCarte:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
boutonCarteTxt = boutonCarte:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
boutonCarteTxt:SetPoint("CENTER")
boutonCarteTxt:SetTextColor(1, 1, 1)
boutonCarteTxt:SetShadowColor(0, 0, 0, 1)
boutonCarteTxt:SetShadowOffset(1, -1)
boutonCarte:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
boutonCarte:SetScript("OnClick", function()
    if not mobSelectionne then return end
    local zoneCarte = MHH_CATALOGUE[mobSelectionne] or (DB.decouverts[mobSelectionne] and DB.decouverts[mobSelectionne].zone) or "?"
    VoirSurCarte(zoneCarte, mobSelectionne)
end)

-- FAVORI : épingle la bête affichée — elle apparaît dans la catégorie
-- « ★ Favoris » en tête de la liste du gibier, EN PLUS de sa région.
local boutonFavori, boutonFavoriTxt, boutonFavoriStar
MettreAJourBoutonFavori = function()
    if not boutonFavoriTxt then return end
    -- NB : les glyphes ★/☆ n'existent pas dans la police du client (ils
    -- s'affichaient en crochets vides []) — l'étoile est une TEXTURE.
    -- Deux états LISIBLES, même taille de bouton :
    --  • pas favori : étoile or + texte blanc — clairement cliquable
    --  • favori     : CROIX ROUGE + texte doré — le clic le retire
    if mobSelectionne and DB.favoris and DB.favoris[mobSelectionne] then
        if boutonFavoriStar then
            boutonFavoriStar:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
            boutonFavoriStar:SetAlpha(1)
        end
        boutonFavoriTxt:SetText("|cffffd100Favori|r")
    else
        if boutonFavoriStar then
            boutonFavoriStar:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
            boutonFavoriStar:SetAlpha(1)
        end
        boutonFavoriTxt:SetText("|cffffffffFavori|r")
    end
end
boutonFavori = CreateFrame("Button", nil, detailFond, MHH_TEMPLATE_BACKDROP)
boutonFavori:SetPoint("BOTTOMLEFT", 164, 10)
boutonFavori:SetSize(96, 22)
pcall(function()
    boutonFavori:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    boutonFavori:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    boutonFavori:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
boutonFavoriStar = boutonFavori:CreateTexture(nil, "OVERLAY")
boutonFavoriStar:SetSize(14, 14)
-- (ancre étoile définie après la création du texte, voir plus bas)
boutonFavoriStar:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
boutonFavoriStar:SetAlpha(0.35)
boutonFavoriTxt = boutonFavori:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
boutonFavoriTxt:SetPoint("CENTER", 9, 0)
-- L'étoile se colle à gauche du texte : « ★ Favori » centré en groupe
boutonFavoriStar:SetPoint("RIGHT", boutonFavoriTxt, "LEFT", -4, 0)
boutonFavoriTxt:SetTextColor(1, 1, 1)
boutonFavoriTxt:SetShadowColor(0, 0, 0, 1)
boutonFavoriTxt:SetShadowOffset(1, -1)
boutonFavori:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
boutonFavori:SetScript("OnClick", function()
    if not mobSelectionne then return end
    DB.favoris = DB.favoris or {}
    if DB.favoris[mobSelectionne] then
        DB.favoris[mobSelectionne] = nil
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r ") .. mobSelectionne .. L("|r retiré des favoris."))
    else
        DB.favoris[mobSelectionne] = true
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r ") .. mobSelectionne .. L("|r épinglé en favori."))
    end
    MettreAJourBoutonFavori()
    if RaffraichirCarnet then RaffraichirCarnet() end
end)
-- Pas de tooltip de survol : l'état du bouton (étoile/croix) est
-- assez explicite comme ça, le message de chat confirme l'action.

-- Ordre des régions : Kalimdor puis Royaumes de l'Est (les zones de chasse
-- sont regroupées sous en-têtes de continent + de zone)
local CONTINENT = {
    -- Kalimdor
    ["Durotar"] = "Kalimdor", ["Mulgore"] = "Kalimdor", ["Teldrassil"] = "Kalimdor",
    ["Sombrerivage"] = "Kalimdor", ["Les Tarides"] = "Kalimdor",
    ["Les Serres-Rocheuses"] = "Kalimdor", ["Orneval"] = "Kalimdor",
    ["Désolace"] = "Kalimdor", ["Mille Pointes"] = "Kalimdor",
    ["Marécage d'Âprefange"] = "Kalimdor", ["Tanaris"] = "Kalimdor",
    ["Féralas"] = "Kalimdor", ["Gangrebois"] = "Kalimdor",
    ["Cratère d'Un'Goro"] = "Kalimdor", ["Silithus"] = "Kalimdor",
    ["Azshara"] = "Kalimdor", ["Hiverpré"] = "Kalimdor",
    ["Gorges des Chants éternels"] = "Kalimdor",
    -- Royaumes de l'Est
    ["Bois de la Pénombre"] = L("Royaumes de l'Est"), ["Dun Morogh"] = L("Royaumes de l'Est"),
    ["Clairières de Tirisfal"] = L("Royaumes de l'Est"), ["Loch Modan"] = L("Royaumes de l'Est"),
    ["Marches de l'Ouest"] = L("Royaumes de l'Est"), ["Les Carmines"] = L("Royaumes de l'Est"),
    ["Bois de la Pénombre"] = L("Royaumes de l'Est"),
    ["Forêt des Pins-Argentés"] = L("Royaumes de l'Est"), ["Les Paluns"] = L("Royaumes de l'Est"),
    ["Contreforts de Hautebrande"] = L("Royaumes de l'Est"),
    ["Montagnes d'Alterac"] = L("Royaumes de l'Est"),
    ["Hautes-terres d'Arathi"] = L("Royaumes de l'Est"),
    ["Vallée de Strangleronce"] = L("Royaumes de l'Est"),
    ["Marais des Chagrins"] = L("Royaumes de l'Est"),
    ["Terres ingrates"] = L("Royaumes de l'Est"),
    ["Gorge des Vents brûlants"] = L("Royaumes de l'Est"),
    ["Steppes Ardentes"] = L("Royaumes de l'Est"),
    ["Terres foudroyées"] = L("Royaumes de l'Est"),
    ["Maleterres de l'Ouest"] = L("Royaumes de l'Est"),
    ["Maleterres de l'Est"] = L("Royaumes de l'Est"),
    ["Les Hinterlands"] = L("Royaumes de l'Est"),
}
-- Ordre de parcours approximatif (Kalimdor puis Royaumes de l'Est, par niveau)
local ORDRE_ZONES = {
    "Durotar", "Mulgore", "Teldrassil", "Sombrerivage", "Les Tarides",
    "Les Serres-Rocheuses", "Orneval", "Désolace", "Mille Pointes",
    "Marécage d'Âprefange", "Tanaris", "Féralas", "Gangrebois",
    "Cratère d'Un'Goro", "Silithus", "Azshara", "Hiverpré",
    "Gorges des Chants éternels",
    "Bois de la Pénombre", "Dun Morogh", "Clairières de Tirisfal", "Loch Modan",
    "Marches de l'Ouest", "Les Carmines", "Bois de la Pénombre",
    "Forêt des Pins-Argentés", "Les Paluns", "Contreforts de Hautebrande",
    "Montagnes d'Alterac", "Hautes-terres d'Arathi", "Vallée de Strangleronce",
    "Marais des Chagrins", "Terres ingrates", "Gorge des Vents brûlants",
    "Steppes Ardentes", "Terres foudroyées", "Maleterres de l'Ouest",
    "Maleterres de l'Est", "Les Hinterlands",
}
local enTetesZone = {}
local enTetesRegion = {}

local function RaffraichirGrille()
    -- Zone où se trouve le joueur (texte sous la barre de filtres)
    zoneEnCoursTxt:SetText(L("|cffffd100Zone actuelle : |r") .. (GetZoneText() or "?"))
    -- Regroupement par zone (avec filtres recherche / zone en cours)
    local function PasseFiltre(nom, zone)
        if filtreRecherche ~= "" then
            -- Recherche par nom de monstre OU par nom de zone
            if string.find(string.lower(nom), filtreRecherche, 1, true) then return true end
            if zone and string.find(string.lower(zone), filtreRecherche, 1, true) then return true end
            return false
        end
        return true
    end
    local parZone = {}
    for nom, zone in pairs(MHH_CATALOGUE) do
        -- Une seule carte par bête : la graphie principale uniquement
        -- (sinon chaque bête indexée FR+EN apparaît deux fois)
        if MHH_EstNomAffichable(nom) and PasseFiltre(nom, zone) then
            parZone[zone] = parZone[zone] or {}
            parZone[zone][#parZone[zone] + 1] = nom
        end
    end
    for nom, info in pairs(DB.decouverts) do
        if not MHH_CATALOGUE[nom] and PasseFiltre(nom, info.zone) then
            local z = info.zone or "?"
            parZone[z] = parZone[z] or {}
            parZone[z][#parZone[z] + 1] = nom
        end
    end
    -- Filtre L("Ma zone") : ne garder que la zone où se trouve le joueur
    if filtreMaZone then
        local tmp = {}
        local zj = GetZoneText() or "?"
        if parZone[zj] then tmp[zj] = parZone[zj] end
        parZone = tmp
    end
    messageZoneVide:SetShown(filtreMaZone and not next(parZone))
    -- FAVORIS : pseudo-catégorie « Favoris » — les bêtes épinglées y
    -- figurent EN PLUS de leur région d'origine (aucune perte d'info).
    local favListe = {}
    for _, liste in pairs(parZone) do
        for _, nom in ipairs(liste) do
            if DB.favoris and DB.favoris[nom] then favListe[#favListe + 1] = nom end
        end
    end
    if #favListe > 0 then
        table.sort(favListe)
        parZone["Favoris"] = favListe
    end
    local zones = {}
    for z in pairs(parZone) do zones[#zones + 1] = z end
    -- Le continent où se trouve le joueur passe en premier. La table
    -- CONTINENT ne connaît que les zones de chasse : en ville, sous-zone
    -- ou zone hors liste, GetZoneText ne matche pas — on remonte alors
    -- l'arbre des cartes (C_Map) jusqu'au continent du joueur.
    local continentJoueur = CONTINENT[GetZoneText() or ""]
    if not continentJoueur then
        pcall(function()
            local id = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            local boucle = 0
            while id and boucle < 10 do
                boucle = boucle + 1
                local info = C_Map.GetMapInfo and C_Map.GetMapInfo(id)
                if not info then break end
                local nm = info.name
                if nm == "Kalimdor" then continentJoueur = "Kalimdor" break end
                if nm == "Royaumes de l'Est" or nm == "Eastern Kingdoms" then
                    continentJoueur = L("Royaumes de l'Est") break
                end
                local pid = info.parentMapID
                if not pid or pid == id or pid == 0 then break end
                id = pid
            end
        end)
    end
    table.sort(zones, function(a, b)
        -- « Favoris » passe toujours en tête de liste
        if a == "Favoris" then return true end
        if b == "Favoris" then return false end
        local ca, cb = CONTINENT[a], CONTINENT[b]
        local prioA = (ca == continentJoueur) and 0 or 1
        local prioB = (cb == continentJoueur) and 0 or 1
        if prioA ~= prioB then return prioA < prioB end
        local ia, ib = 99, 99
        for i, z in ipairs(ORDRE_ZONES) do
            if z == a then ia = i end
            if z == b then ib = i end
        end
        if ia ~= ib then return ia < ib end
        return a < b
    end)
    for _, z in ipairs(zones) do table.sort(parZone[z]) end

    -- Sélection par défaut : le premier monstre de la première zone
    -- (la fiche détail n'est jamais vide à l'ouverture)
    local premier = zones[1] and parZone[zones[1]] and parZone[zones[1]][1]
    if not mobSelectionne or (not MHH_CATALOGUE[mobSelectionne] and not DB.decouverts[mobSelectionne]) then
        mobSelectionne = premier
    end

    local nomCible = NomOrdinaire(UnitName("target")) or "" -- v0.30 : anti-secret
    local y = 10 -- petit respiration sous la barre de filtres
    local col = 0
    local ib = 0
    local ih = 0
    local ir = 0
    local continentCourant = nil
    local decalageZoneJoueur = nil
    local zoneJoueur = GetZoneText()

    for _, z in ipairs(zones) do
        -- En-tête de continent (Kalimdor / Royaumes de l'Est)
        local continent = CONTINENT[z]
        if continent and continent ~= continentCourant then
            continentCourant = continent
            ir = ir + 1
            local entete = enTetesRegion[ir]
            if not entete then
                entete = CreateFrame("Frame", nil, grilleContenu)
                entete:SetSize(240, 26)
                entete.texte = entete:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                entete.texte:SetPoint("TOPLEFT", 2, -4)
                entete.trait = entete:CreateTexture(nil, "BACKGROUND")
                entete.trait:SetHeight(2)
                entete.trait:SetColorTexture(0.55, 0.42, 0.2, 0.7)
                enTetesRegion[ir] = entete
            end
            entete:ClearAllPoints()
            entete:SetPoint("TOPLEFT", grilleContenu, "TOPLEFT", 0, -y)
            entete.trait:ClearAllPoints()
            entete.trait:SetPoint("TOPLEFT", 2, -20)
            entete.trait:SetWidth(236)
            entete.texte:SetText("|cffffd100" .. string.upper(continent) .. "|r")
            entete:Show()
            y = y + 26
        end
        -- En-tête de la zone (le nom seul, la couleur est donnée par le continent)
        if z == zoneJoueur then decalageZoneJoueur = y end
        ih = ih + 1
        local entete = enTetesZone[ih]
        if not entete then
            entete = CreateFrame("Frame", nil, grilleContenu)
            entete:SetSize(240, 22)
            entete.pastille = entete:CreateTexture(nil, "OVERLAY")
            entete.pastille:SetSize(11, 11)
            entete.pastille:SetPoint("TOPLEFT", 3, -5)
            entete.texte = entete:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            entete.texte:SetPoint("TOPLEFT", 20, -3)
            -- Estimation « rares non répertoriées » : petite police, calée
            -- à droite — plus de débordement hors de l'en-tête
            entete.estim = entete:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            entete.estim:SetPoint("TOPRIGHT", -8, -5)
            -- Délimitation sous chaque en-tête de zone
            entete.trait = entete:CreateTexture(nil, "OVERLAY")
            entete.trait:SetHeight(2)
            entete.trait:SetWidth(236)
            entete.trait:SetPoint("TOPLEFT", 4, -20)
            entete.trait:SetColorTexture(0.62, 0.48, 0.22, 0.85)
            enTetesZone[ih] = entete
        end
        entete:ClearAllPoints()
        entete:SetPoint("TOPLEFT", grilleContenu, "TOPLEFT", 4, -y)
        entete.pastille:SetColorTexture(CouleurZone(z)[1], CouleurZone(z)[2], CouleurZone(z)[3], 0.95)
        -- Décompte X/Y d'abord : on mesure SA largeur pour borner le nom
        -- de zone AVANT lui — jamais de chevauchement, même pour
        -- « Marécage d'Aprefange » (police réduite + troncature « … »)
        local total = #parZone[z] + (MHH_RARES_ESTIMES[z] or 0)
        local ratioTxt = total > 0 and ("|cffa58b54" .. #parZone[z] .. "/" .. total .. "|r") or ""
        entete.estim:SetText(ratioTxt)
        pcall(function()
            entete.texte:SetFontObject("GameFontNormalLarge")
            local nomz = z
            local coupure = false
            local estimW = 0
            if ratioTxt ~= "" then
                estimW = entete.estim:GetStringWidth() or 0
            end
            if estimW <= 0 then estimW = 46 end
            -- Le nom s'arrête juste AVANT le ratio, marge de 12 px
            local maxW = 220 - 20 - estimW - 12
            local function majTexte()
                entete.texte:SetText("|cffffd100" .. nomz .. (coupure and "…|r" or "|r"))
            end
            majTexte()
            if entete.texte:GetStringWidth() > maxW then
                entete.texte:SetFontObject("GameFontNormal")
                while entete.texte:GetStringWidth() > maxW and #nomz > 6 do
                    nomz = string.sub(nomz, 1, #nomz - 1)
                    coupure = true
                    majTexte()
                end
            end
        end)
        entete:Show()
        y = y + 26
        col = 0
        local c = CouleurZone(z)

        for _, nom in ipairs(parZone[z]) do
            ib = ib + 1
            local bouton = boutonsMobs[ib]
            if not bouton then
                bouton = CreateFrame("Button", nil, grilleContenu)
                bouton:SetSize(ESPACEMENT, TAILLE_ICONE + 26)
                bouton.icone = bouton:CreateTexture(nil, "ARTWORK")
                bouton.icone:SetSize(40, 40)
                bouton.icone:SetPoint("TOP", 0, -2)
                -- Encadrement FIN en 4 barres autour de l'icône : le
                -- carré plein 44x44 en OVERLAY recouvrait la vignette
                -- (rendu sombre au lieu du doré attendu).
                bouton.cadres = {}
                do
                    local barres = {
                        { w = 46, h = 3, p1 = "TOPLEFT",     rp = bouton.icone, p2 = "TOPLEFT",     x = -3, y = 3 },
                        { w = 46, h = 3, p1 = "BOTTOMLEFT",  rp = bouton.icone, p2 = "BOTTOMLEFT",  x = -3, y = -3 },
                        { w = 3,  h = 46, p1 = "TOPLEFT",     rp = bouton.icone, p2 = "TOPLEFT",     x = -3, y = 3 },
                        { w = 3,  h = 46, p1 = "TOPRIGHT",    rp = bouton.icone, p2 = "TOPRIGHT",    x = 3,  y = 3 },
                    }
                    for _, bdef in ipairs(barres) do
                        local t = bouton:CreateTexture(nil, "OVERLAY")
                        t:SetSize(bdef.w, bdef.h)
                        t:SetPoint(bdef.p1, bdef.rp, bdef.p2, bdef.x, bdef.y)
                        t:SetColorTexture(0.35, 0.30, 0.20, 0.9)
                        bouton.cadres[#bouton.cadres + 1] = t
                    end
                end
                bouton.pastille = bouton:CreateTexture(nil, "OVERLAY")
                bouton.pastille:SetSize(10, 10)
                bouton.pastille:SetPoint("TOPRIGHT", -6, -6)
                bouton.badge = bouton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                bouton.badge:SetPoint("TOPLEFT", bouton.icone, "TOPLEFT", 0, 2)
                bouton.badge:SetText("|cffee6644NEW|r")
                bouton.label = bouton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                bouton.label:SetPoint("TOP", bouton.icone, "BOTTOM", 0, -1)
                bouton.label:SetWidth(ESPACEMENT - 4)
                pcall(function() bouton.label:SetWordWrap(false) end)
                bouton:SetScript("OnClick", function(self)
                    mobSelectionne = self.nomMob
                    RaffraichirDetail()
                end)
                -- Noms longs (« Prophète du mal Course-Sage ») : le libellé
                -- de la cellule est tronqué par sa largeur — le tooltip
                -- montre le nom ENTIER. v0.21 : la zone de déclenchement
                -- était TOUTE la vignette (trop grosse — tooltip qui
                -- sautait au moindre survol) ; les FontStrings ne
                -- reçoivent pas de scripts en Vanilla, donc un bouton
                -- transparent couvre uniquement le LIBELLÉ, et le tooltip
                -- ne sort QUE si le nom est réellement tronqué.
                bouton.zoneLibelle = CreateFrame("Button", nil, bouton)
                bouton.zoneLibelle:SetPoint("TOPLEFT", bouton.icone, "BOTTOMLEFT", -6, -4)
                bouton.zoneLibelle:SetSize(ESPACEMENT + 2, 18)
                bouton.zoneLibelle.libelle = bouton.label
                bouton.zoneLibelle:SetScript("OnClick", function(self)
                    if self.nomMob then
                        mobSelectionne = self.nomMob
                        RaffraichirDetail()
                    end
                end)
                bouton.zoneLibelle:SetScript("OnEnter", function(self)
                    if not GameTooltip or not self.nomMob then return end
                    -- Pas de tooltip si le nom tient déjà dans la cellule.
                    local okT, tronque = pcall(function()
                        return self.libelle:GetStringWidth() > self.libelle:GetWidth() + 2
                    end)
                    if okT and not tronque then return end
                    -- Sous le pointeur : TOPLEFT ancre 12px SOUS la souris.
                    GameTooltip:SetOwner(self, "ANCHOR_NONE")
                    local ech = UIParent:GetScale()
                    local mx, my = GetCursorPosition()
                    GameTooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                        mx / ech + 12, my / ech - 12)
                    GameTooltip:SetText("|cffffd100" .. MHH_NomAffiche(self.nomMob) .. "|r")
                    GameTooltip:Show()
                end)
                bouton.zoneLibelle:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
                boutonsMobs[ib] = bouton
            end
            bouton:ClearAllPoints()
            bouton:SetPoint("TOPLEFT", grilleContenu, "TOPLEFT", col * ESPACEMENT + 8, -y)
            bouton:Show()
            bouton.nomMob = nom
            if bouton.zoneLibelle then bouton.zoneLibelle.nomMob = nom end
            local info = DB.chasses[nom] or {}
            -- Badge NEW : première chasse pas encore consultée, ou découverte récente
            local dec = DB.decouverts[nom]
            if (info.nouveau) or (dec and dec.nouveau) then
                bouton.badge:Show()
            else
                bouton.badge:Hide()
            end
            -- La couleur de zone est indiquée par la pastille de l'en-tête, plus ici
            bouton.pastille:Hide()
            local nomAff = MHH_NomAffiche(nom)
            bouton.label:SetText((DB.contrat == nom) and ("|cffff69b4» |cffe9dcc0" .. nomAff .. "|r") or ("|cffe9dcc0" .. nomAff .. "|r"))
            -- Encadrement : doré = chassé, gris = jamais chassé (barres fines)
            if info.kills and info.kills > 0 then
                for _, t in ipairs(bouton.cadres) do t:SetColorTexture(0.78, 0.62, 0.25, 0.95) end
            else
                for _, t in ipairs(bouton.cadres) do t:SetColorTexture(0.35, 0.30, 0.20, 0.9) end
            end
            if nom == nomCible then
                DefinirPortrait(bouton.icone, "target")
                bouton.icone:SetDesaturated(false)
                bouton.icone:SetVertexColor(1, 1, 1)
            else
                local vt = TextureVignette(nom)
                if vt then
                    bouton.icone:SetTexture(vt)
                else
                    local v = IconeGibier(nom)
                    if v then
                        bouton.icone:SetTexture("Interface\\Icons\\" .. v)
                    else
                        -- Repli CARRÉ (griffe) : le point d'interrogation était
                        -- rond et détonnait au milieu des vignettes carrées
                        bouton.icone:SetTexture("Interface\\Icons\\INV_Misc_MonsterClaw_04")
                    end
                end
                -- Couleur dès la RENCONTRE (découverte au ciblage ou
                -- bête déjà chassée) ; les JAMAIS rencontrées affichent la
                -- vignette MYSTÈRE (inconnu.tga, grisée volontairement) :
                -- l'apparence réelle reste une surprise du carnet. Si le
                -- fichier manque, repli sur l'ancienne silhouette grise.
                local vu = (DB.decouverts and DB.decouverts[nom]) or (info.kills and info.kills > 0)
                if vu then
                    -- MÊME cadrage que la vignette mystère (0.07-0.93) :
                    -- trouvé et inconnu s'alignent au pixel, plus de
                    -- « saut » d'un état à l'autre.
                    bouton.icone:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                    bouton.icone:SetDesaturated(false)
                    bouton.icone:SetVertexColor(1, 1, 1)
                else
                    local okMyst = true
                    pcall(function()
                        local ok = bouton.icone:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\Specimens\\inconnu.tga")
                        if ok == false then
                            ok = bouton.icone:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\Vignettes\\inconnu.tga")
                        end
                        if ok == false then okMyst = false end
                    end)
                    if okMyst then
                        -- « grisée un peu » : voile gris clair sur le
                        -- dessin (0.72 : lisible, moins funebre), bords
                        -- rogne de 7 % (texcoords) si l'image deborde.
                        bouton.icone:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                        bouton.icone:SetDesaturated(false)
                        bouton.icone:SetVertexColor(0.72, 0.72, 0.72)
                    else
                        -- Fichier absent : ancien rendu (icône famille
                        -- désaturée) — pas d'icône vide en attendant
                        bouton.icone:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                        bouton.icone:SetVertexColor(1, 1, 1)
                        bouton.icone:SetDesaturated(true)
                    end
                end
            end
            col = col + 1
            if col >= NB_COLONNES then
                col = 0
                y = y + TAILLE_ICONE + 12
            end
        end
        if col > 0 then y = y + TAILLE_ICONE + 12 end
        y = y + 2 -- écart entre zones
    end

    for i = ib + 1, #boutonsMobs do boutonsMobs[i]:Hide() end
    for i = ih + 1, #enTetesZone do enTetesZone[i]:Hide() end
    for i = ir + 1, #enTetesRegion do enTetesRegion[i]:Hide() end
    grilleContenu:SetHeight(y + 8)
    -- Défilement : après un clic/déclic « Ma zone », on RECOMMENCE en haut
    -- (le joueur voit son continent en premier, donc « ses » régions).
    -- Sinon, saut vers la zone où se trouve le joueur (comportement habituel)
    if MHH_scrollHaut then
        MHH_scrollHaut = false
        pcall(grilleScroll.SetVerticalScroll, grilleScroll, 0)
    elseif decalageZoneJoueur and grilleScroll.SetVerticalScroll then
        pcall(grilleScroll.SetVerticalScroll, grilleScroll, math.max(0, decalageZoneJoueur - 4))
    end
end

RaffraichirCarnet = function()
    RaffraichirGrille()
    RaffraichirDetail()
end
end -- fin bloc page Gibier

-- ================= PAGE CONTRATS =================
-- Feuille des contrats : cible du jour, contrat actif, historique des primes
do
local contratsFond = CreateFrame("Frame", nil, pageContrats, MHH_TEMPLATE_BACKDROP)
contratsFond:SetPoint("TOPLEFT", pageContrats, "TOPLEFT", 44, -42)
contratsFond:SetSize(552, 320)
pcall(function()
    contratsFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    contratsFond:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    contratsFond:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
local function ContratsLabel(x, y, texte)
    local l = contratsFond:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("TOPLEFT", contratsFond, "TOPLEFT", x, y)
    l:SetText("|cffffd100" .. texte .. "|r")
    return l
end
ContratsLabel(20, -14, L("OFFRE DU JOUR"))
-- Séparateur : distingue l'offre spéciale (cible du jour) des contrats
-- d'appoint en dessous — hiérarchie visuelle façon panneau de guilde MH
local offresSep = contratsFond:CreateTexture(nil, "OVERLAY")
offresSep:SetSize(512, 2)
offresSep:SetPoint("TOPLEFT", contratsFond, "TOPLEFT", 20, -58)
offresSep:SetColorTexture(0.62, 0.48, 0.22, 0.7)
ContratsLabel(20, -68, L("CONTRATS DE LA GUILDE"))
-- Prise d'un contrat depuis une offre du jour : cible du jour = +20,
-- autres offres = +10. Flux unique (l'ancien bouton « Prendre » de la
-- cible du jour) : message + rugissement, EN CHASSE si déjà ciblée,
-- sinon bannière de traque + musique de traque dans la zone.
local function PrendreOffreContrat(nom, prime)
    if not nom then return end
    DB.contrat = nom
    DB.contratPrime = prime or 20
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Nouveau contrat : |cffffff00") .. nom .. "|r ("
        .. (MHH_CATALOGUE[nom] or "?") .. L(") — prime : +") .. DB.contratPrime .. L(" points !"))
    if DB.config.son then JouerRugissement() end -- rugissement de contrat
    -- La bête est déjà dans le viseur : EN CHASSE immédiat
    if UnitExists("target") and (UnitName("target") or "") == nom then
        DebutChasse(nom, UnitClassification("target"), UnitLevel("target"))
    elseif not chasseActive then
        -- Sinon : traque engagée (étape 1 de la chasse, façon MH)
        AfficherBanniere(L("TRAQUE ENGAGÉE"), 0.98, 0.72, 0.30)
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffffc44cTraque engagée :|r pistez la bête et ciblez-la pour lancer la chasse."))
        if MHH_CATALOGUE[DB.contrat] == (GetZoneText() or "") then MHH_JouerMusique("traque", 120) end
    end
    if RaffraichirCarnet then RaffraichirCarnet() end
    if RaffraichirAccueil then RaffraichirAccueil() end
    if RaffraichirContrats then RaffraichirContrats() end
    MettreAJourIndicateur()
end
-- 1 offre spéciale (cible du jour, +20) puis 4 contrats d'appoint qui
-- agrémentent le choix à moindre prime (+5). L'offre est RELUE au clic
-- (les offres du jour tournent à minuit, capturer la valeur figerait
-- l'ancienne).
local offresLignes = {}
for i = 1, 7 do
    -- Ligne 1 = offre spéciale, sous « OFFRE DU JOUR ». Les 4 contrats
    -- d'appoint vivent sous « CONTRATS DE LA GUILDE », d'où le décalage.
    local y = (i == 1) and -32 or (-88 - (i - 2) * 24)
    local l = contratsFond:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local b = CreateFrame("Button", nil, contratsFond, MHH_TEMPLATE_BACKDROP)
    b:SetPoint("TOPRIGHT", contratsFond, "TOPRIGHT", -16, y)
    b:SetSize(104, 20)
    b:SetText("Prendre")
    -- Le texte est ancré AU BOUTON, même référence verticale : le centre
    -- du texte colle au centre du bouton, quelle que soit la fonte.
    l:SetPoint("LEFT", b, "RIGHT", -496, 0)
    l:SetWidth(360)
    l:SetJustifyH("LEFT")
    l:SetShadowColor(0, 0, 0, 1)
    l:SetShadowOffset(1, -1)
    b:SetNormalFontObject("GameFontHighlightSmall")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    pcall(function()
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        b:SetBackdropColor(0.30, 0.22, 0.10, 0.85)
        b:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
    end)
    b:SetScript("OnClick", function()
        local of = DB.offresJour and DB.offresJour.noms
        local nomC = of and of[i]
        if not nomC then return end
        -- Offre active : le clic RÉVOQUE le contrat au lieu de la prendre
        if DB.contrat == nomC then
            DB.contrat = nil
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Contrat révoqué : |cffffff00") .. nomC .. "|r.")
            if RaffraichirCarnet then RaffraichirCarnet() end
            if RaffraichirAccueil then RaffraichirAccueil() end
            RaffraichirContrats()
            MettreAJourIndicateur()
            return
        end
        PrendreOffreContrat(nomC, (i == 1 and 20) or 5)
    end)
    offresLignes[i] = { txt = l, btn = b }
end
-- (Le bouton Révoquer séparé a été retiré : le bouton de l'offre
-- active affiche « Révoquer » directement — l'état « contrat en cours »
-- se lit déjà sur l'accueil et l'indicateur minimap.)
-- Séparateur bas : ferme la liste des contrats avant l'historique,
-- symétrique de celui de l'offre du jour
local histoSep = contratsFond:CreateTexture(nil, "OVERLAY")
histoSep:SetSize(512, 2)
histoSep:SetPoint("TOPLEFT", contratsFond, "TOPLEFT", 20, -232)
histoSep:SetColorTexture(0.62, 0.48, 0.22, 0.7)
ContratsLabel(20, -242, L("HISTORIQUE DES PRIMES"))
local contratsHistoTxt = contratsFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
contratsHistoTxt:SetPoint("TOPLEFT", contratsFond, "TOPLEFT", 40, -258)
contratsHistoTxt:SetWidth(500)
contratsHistoTxt:SetJustifyH("LEFT")
contratsHistoTxt:SetSpacing(2)
contratsHistoTxt:SetShadowColor(0, 0, 0, 1)
contratsHistoTxt:SetShadowOffset(1, -1)

RaffraichirContrats = function()
    if not DB then return end
    -- Offres du jour : 7 lignes — cible du jour (+20) puis 6 offres de
    -- guilde (+5). Le contrat pris porte son statut sur sa ligne.
    local aujourdhui = date("%y%m%d")
    -- Correctif « onglet vide » : si les offres date d'un jour passé
    -- (session traversant minuit sans changement de zone), on RETIRE
    -- les offres du jour AVANT d'afficher — sinon l'onglet restait vide
    -- jusqu'au prochain /reload ou changement de zone.
    if not (DB.offresJour and DB.offresJour.date == aujourdhui) then
        ContratQuotidien()
        if RaffraichirAccueil and carnet and carnet:IsShown() then RaffraichirAccueil() end
    end
    local offres = (DB.offresJour and DB.offresJour.date == aujourdhui) and DB.offresJour.noms or nil
    for i = 1, 7 do
        local ligne = offresLignes[i]
        local nom = offres and offres[i] or nil
        if nom then
            local prime = (i == 1) and 20 or 5
            ligne.txt:SetText("|cffffff00" .. nom .. "|r (" .. (MHH_CATALOGUE[nom] or "?") .. ")"
                .. (i == 1 and (" |cffffcc66• " .. L("(cible du jour)")) or "")
                .. (DB.contrat == nom and (" |cffffd100• " .. L("mission en cours") .. " (+" .. (DB.contratPrime or 20) .. ")|r") or ""))
            if DB.contrat == nom then
                -- Le bouton de l'offre active EST le révoquer (l'état
                -- « en cours » se lit déjà sur l'accueil et la minimap) :
                -- un bouton inactif « En cours » n'apportait rien.
                ligne.btn:SetText("|cffff8800" .. L("Révoquer") .. "|r")
                ligne.btn:Enable()
            else
                ligne.btn:SetText("Prendre (+" .. prime .. ")")
                ligne.btn:Enable()
            end
        else
            ligne.txt:SetText(i == 1 and L("|cff8a6d3bAucune cible aujourd'hui — connectez-vous pour la découvrir.|r") or "")
            ligne.btn:SetText("—")
            ligne.btn:Disable()
        end
    end
    -- Historique des primes (3 dernières — le cadre est plus compact)
    local histo = DB.contratHistorique or {}
    if #histo == 0 then
        contratsHistoTxt:SetText(L("|cff8a6d3bAucune prime à ce jour.|r\n|cffa58b54Primes gagnées au total : |cffffd100")
            .. (DB.primesGagnees or 0) .. L(" points — nouvelles offres à minuit.|r"))
    else
        local lignes = {}
        for i = 1, math.min(#histo, 3) do
            lignes[#lignes + 1] = "|cffffff00" .. histo[i].nom .. "|r"
                .. (histo[i].date and ("  —  " .. histo[i].date) or "")
                .. "  |cffa0ff50(+" .. (histo[i].prime or 20) .. " points)|r"
        end
        contratsHistoTxt:SetText(table.concat(lignes, "\n")
            .. L("\n|cffa58b54Primes gagnées au total : |cffffd100") .. (DB.primesGagnees or 0) .. L(" points — ")
            .. #histo .. L(" contrat(s) rempli(s) — nouvelles offres à minuit.|r"))
    end
end
end -- fin bloc page Contrats

-- ================= PAGE MISSIONS =================
-- Les quêtes scénarisées du camp Nesingwary : cartes parchemin empilées,
-- verrouillées/terminées façon carnet de chasse MH. Séquentielles.
do
local missionsFond = CreateFrame("Frame", nil, pageMissions, MHH_TEMPLATE_BACKDROP)
missionsFond:SetPoint("TOPLEFT", pageMissions, "TOPLEFT", 44, -42)
missionsFond:SetSize(552, 320)
pcall(function()
    missionsFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    missionsFond:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    missionsFond:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.8)
end)
local missionsTitre = missionsFond:CreateFontString(nil, "OVERLAY", "GameFontNormal")
missionsTitre:SetPoint("TOP", 0, -8)
missionsTitre:SetText(L("|cffffd100MISSIONS DE CHASSE|r"))
local missionsSousTitre = missionsFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
missionsSousTitre:SetPoint("TOP", 0, -26)
missionsSousTitre:SetText(L("Le camp Nesingwary confie ses vieux dossiers. Une mission à la fois, dans l'ordre."))
-- Liste défilante : cartes agrandies, toutes les missions ne tiennent
-- pas dans la vue — même patron que la page Succès
local missionsScroll = CreateFrame("ScrollFrame", nil, missionsFond, "UIPanelScrollFrameTemplate")
missionsScroll:SetPoint("TOPLEFT", missionsFond, "TOPLEFT", 10, -42)
missionsScroll:SetSize(508, 268)
local missionsContenu = CreateFrame("Frame", nil, missionsScroll)
missionsContenu:SetSize(508, 1)
missionsScroll:SetScrollChild(missionsContenu)
local cartesMission = {}
-- Empilement : hauteur variable selon le contenu de la carte — pas de
-- place morte sous les missions sans condition ni météo
local yMission = 0
for i, q in ipairs(MHH_MISSIONS) do
    local c = CreateFrame("Frame", nil, missionsContenu, MHH_TEMPLATE_BACKDROP)
    -- Corps : citation (2 lignes) + ligne vide + objectif + ligne vide
    -- + récompense ; condition = +1 ligne, bloc météo = +2 (vide + texte)
    local hCarte = 114
        + ((q.condition and q.condition ~= "") and 12 or 0)
        + (q.meteo and 24 or 0)
    c:SetPoint("TOPLEFT", missionsContenu, "TOPLEFT", 0, -yMission)
    c:SetSize(508, hCarte)
    yMission = yMission + hCarte + 6
    pcall(function()
        c:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        c:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
        c:SetBackdropBorderColor(0.45, 0.36, 0.20, 0.9)
    end)
    local icone = c:CreateTexture(nil, "ARTWORK")
    icone:SetSize(52, 52)
    icone:SetPoint("LEFT", 10, 0)
    icone:SetTexture("Interface\\Icons\\" .. (q.icone or "INV_Misc_Note_01"))
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT", 72, -8)
    local s = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s:SetPoint("TOPRIGHT", -10, -8)
    local corps = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    corps:SetPoint("TOPLEFT", 72, -30)
    corps:SetWidth(424)
    corps:SetJustifyH("LEFT")
    -- Bouton « Accepter » : une mission déverrouillée doit être acceptée
    -- pour que ses prises comptent — l'intention du chasseur, pas le hasard.
    -- Il PREND LA PLACE du statut (pas de « DISPONIBLE » redondant) : aucun
    -- risque de chevaucher le texte d'objectif en dessous.
    local accepter = CreateFrame("Button", nil, c, MHH_TEMPLATE_BACKDROP)
    accepter:SetPoint("TOPRIGHT", c, "TOPRIGHT", -10, -8)
    accepter:SetSize(118, 20)
    pcall(function()
        accepter:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        accepter:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
        accepter:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
    end)
    local accepterTxt = accepter:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    accepterTxt:SetPoint("CENTER")
    accepterTxt:SetText("|cffffd100Accepter la mission|r")
    accepter:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    accepter:SetScript("OnClick", function()
        DB.missionActive = q.id
        if DB.config.son then JouerRugissement() end -- rugissement d'engagement
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffffc44cMission acceptée :|r ")
            .. q.titre .. L(" — objective : |cffffff00") .. q.cible .. "|r.")
        MHH_RaffraichirMissions()
    end)
    cartesMission[i] = { titre = t, etat = s, corps = corps, carte = c, accepter = accepter }
end
-- ================= RUMEUR DE GUILDE =================
-- Carte violette, sous la pile des missions : la mission cachée du jour
-- (rang minimum requis — sous ce rang, seul un murmure s'affiche).
local rumeur = CreateFrame("Frame", nil, missionsContenu, MHH_TEMPLATE_BACKDROP)
rumeur:SetPoint("TOPLEFT", missionsContenu, "TOPLEFT", 0, -yMission)
rumeur:SetSize(508, 118)
yMission = yMission + 118 + 6
pcall(function()
    rumeur:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    rumeur:SetBackdropColor(0.18, 0.10, 0.26, 0.8)
    rumeur:SetBackdropBorderColor(0.55, 0.40, 0.75, 0.9)
end)
local rumeurIcone = rumeur:CreateTexture(nil, "ARTWORK")
rumeurIcone:SetSize(52, 52)
rumeurIcone:SetPoint("LEFT", 10, 0)
rumeurIcone:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
local rumeurTitre = rumeur:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rumeurTitre:SetPoint("TOPLEFT", 72, -8)
local rumeurEtat = rumeur:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rumeurEtat:SetPoint("TOPRIGHT", -10, -8)
local rumeurCorps = rumeur:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rumeurCorps:SetPoint("TOPLEFT", 72, -30)
rumeurCorps:SetWidth(424)
rumeurCorps:SetJustifyH("LEFT")
local rumeurBtn = CreateFrame("Button", nil, rumeur, MHH_TEMPLATE_BACKDROP)
rumeurBtn:SetPoint("TOPRIGHT", rumeur, "TOPRIGHT", -10, -8)
rumeurBtn:SetSize(118, 20)
pcall(function()
    rumeurBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    rumeurBtn:SetBackdropColor(0.25, 0.14, 0.35, 0.85)
    rumeurBtn:SetBackdropBorderColor(0.55, 0.40, 0.75, 0.9)
end)
local rumeurBtnTxt = rumeurBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rumeurBtnTxt:SetPoint("CENTER")
rumeurBtnTxt:SetText(L("Accepter la rumeur"))
rumeurBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
rumeurBtn:SetScript("OnClick", function()
    local m = MHH_RumeurDuJour and MHH_RumeurDuJour()
    if not m or DB.missions[m.id] then return end
    DB.missionCacheeActive = m.id
    if DB.config.son then JouerRugissement() end
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffb97affRumeur acceptée :|r ")
        .. m.titre .. L(" — ") .. m.objectif)
    MHH_RaffraichirMissions()
end)
-- Hauteur du contenu : somme des hauteurs cumulées + l'interstice final
missionsContenu:SetHeight(yMission)
-- RaffraichirMissions : globale (appelée par AfficherOnglet et par
-- VerifierMissions au fil des prises)
MHH_RaffraichirMissions = function()
    if not DB.missions then DB.missions = {} end
    for i, q in ipairs(MHH_MISSIONS) do
        local ui = cartesMission[i]
        local faite = DB.missions[q.id]
        local deverrouillee = (i == 1) or DB.missions[MHH_MISSIONS[i-1].id]
        local acceptee = (DB.missionActive == q.id)
        ui.titre:SetText("|cffffd100" .. i .. ". " .. q.titre .. "|r — |cffc9a24a" .. q.pnj .. "|r")
        if faite then
            ui.etat:SetText(L("|cffa0ff50TERMINÉE ") .. faite .. "|r")
            ui.accepter:Hide()
        elseif deverrouillee and acceptee then
            ui.etat:SetText("|cffffc44cEN COURS|r")
            ui.accepter:Hide()
        elseif deverrouillee then
            ui.etat:SetText("")
            ui.accepter:Show()
        else
            ui.etat:SetText(L("|cff888888VERROUILLÉE|r"))
            ui.accepter:Hide()
        end
        -- Aération : condition météo et récompense ont chacune leur ligne
        local cond = (q.condition and q.condition ~= "") and ("\n|cffd9b56a" .. q.condition .. "|r") or ""
        -- Condition météo vérifiable : affichage en direct (client Forever)
        local meteoTxt = ""
        if q.meteo then
            local nomMeteo, cleMeteo = MeteoActuelle()
            if nomMeteo then
                if cleMeteo == q.meteo then
                    local saveursReunies = {
                        L("Le ciel s'y prête : ") .. nomMeteo .. L(" — condition RÉUNIE, foncez !"),
                        L("C'est LE moment : ") .. nomMeteo .. L(" — en piste, chasseur !"),
                        nomMeteo .. L(" tombe à point nommé — le gibier ne devrait pas tarder."),
                    }
                    meteoTxt = "\n\n|cffa0ff50" .. saveursReunies[math.random(#saveursReunies)] .. "|r"
                else
                    local saveursAttente = {
                        L("Elle rôde sous une autre météo — le ciel, en ce moment : ") .. nomMeteo,
                        L("Pas encore : le ciel montre ") .. nomMeteo .. L(", la traque attendra."),
                        L("Le carnet dit qu'elle paraît sous certains cieux. Ici, pour l'instant : ") .. nomMeteo,
                    }
                    meteoTxt = "\n\n|cff7fb2ff" .. saveursAttente[math.random(#saveursAttente)] .. "|r"
                end
            else
                meteoTxt = "\n\n|cff888888Le ciel ne se lit pas d'ici — guette-le sur place|r"
            end
        end
        ui.corps:SetText("|cffd9b56a« " .. q.citation .. " »|r\n\n"
            .. L("Objectif : |cffffff00") .. q.cible .. "|r (" .. q.zone .. ")" .. cond
            .. meteoTxt
            .. "\n\n|cffffd100+" .. q.points .. L(" points|r |cffc9a24a(") .. q.recompense .. ")|r")
        pcall(function()
            if not deverrouillee and not faite then
                ui.carte:SetBackdropColor(0.15, 0.12, 0.07, 0.75)
            else
                ui.carte:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
            end
        end)
    end
    -- Rumeur de guilde : révélée au tirage du jour, « EN COURS » une fois
    -- acceptée ; sous le rang requis, seul un murmure verrouillé s'affiche.
    local m = MHH_RumeurDuJour and MHH_RumeurDuJour() or nil
    if m then
        local faite = DB.missions[m.id]
        rumeurTitre:SetText("|cffb97affRUMEUR — " .. m.titre .. "|r")
        rumeurIcone:SetTexture("Interface\\Icons\\" .. (m.icone or "INV_Misc_QuestionMark"))
        if faite then
            rumeurEtat:SetText(L("|cffa0ff50ELUCIDÉE ") .. faite .. "|r")
            rumeurBtn:Hide()
        elseif DB.missionCacheeActive == m.id then
            rumeurEtat:SetText("|cffffc44cEN COURS|r")
            rumeurBtn:Hide()
        else
            rumeurEtat:SetText("")
            rumeurBtn:Show()
        end
        rumeurCorps:SetText("|cffb97aff« " .. m.citation .. " »|r\n\n"
            .. L("Objectif : |cffffff00") .. m.objectif .. "|r\n\n"
            .. "|cffffd100+" .. m.points .. L(" points|r |cffc9a24a(") .. m.recompense .. ")|r")
    else
        rumeurTitre:SetText("|cffb97affRUMEUR DE GUILDE|r")
        rumeurEtat:SetText("")
        rumeurBtn:Hide()
        -- Quel murmure ? selon le rang et les rumeurs restant à élucider
        local idxRang = RangGuilde(DB.points)
        local rangMin, toutesFaites = nil, true
        for _, mm in ipairs(MHH_MISSIONS_CACHEES) do
            if not DB.missions[mm.id] then
                toutesFaites = false
                if not rangMin or mm.rang < rangMin then rangMin = mm.rang end
            end
        end
        if toutesFaites then
            rumeurCorps:SetText(L("|cffb97affToutes les rumeurs ont été élucidées — la guilde applaudit, chasseur.|r"))
        elseif rangMin and idxRang < rangMin then
            rumeurCorps:SetText(L("|cffb97affDes chasses étranges courent les tavernes… mais la guilde ne murmure qu'aux rangs élevés.|r Rang requis : |cffffff00")
                .. MHH_RANGS[rangMin].nom .. "|r")
        else
            rumeurCorps:SetText(L("|cffb97affAucune rumeur aujourd'hui — la guilde murmure à sa manière, revenez demain.|r"))
        end
    end
end
end

-- ================= PAGE SUCCÈS =================
do
local succesScroll = CreateFrame("ScrollFrame", nil, pageSucces, "UIPanelScrollFrameTemplate")
-- Fond encadré derrière la liste (cohérent avec la fiche monstre)
local succesFond = CreateFrame("Frame", nil, pageSucces, MHH_TEMPLATE_BACKDROP)
succesFond:SetPoint("TOPLEFT", pageSucces, "TOPLEFT", 44, -46)
succesFond:SetSize(552, 310)
pcall(function()
    succesFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    succesFond:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    succesFond:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.8)
end)

-- Barre de recherche des succès (même style que la page Monstres)
local filtreSucces = ""
-- RaffraichirSucces : globale (l'onglet Succès l'appelle depuis l'extérieur)
local succesBarreFond = CreateFrame("Frame", nil, pageSucces, MHH_TEMPLATE_BACKDROP)
succesBarreFond:SetPoint("TOPLEFT", pageSucces, "TOPLEFT", 44, -25)
succesBarreFond:SetSize(206, 22)
pcall(function()
    succesBarreFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    succesBarreFond:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    succesBarreFond:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.8)
end)
local succesRecherche = CreateFrame("EditBox", nil, succesBarreFond, MHH_TEMPLATE_BACKDROP)
succesRecherche:SetPoint("TOPLEFT", 0, 0)
succesRecherche:SetSize(206, 22)
succesRecherche:SetFontObject("GameFontHighlightSmall")
succesRecherche:SetAutoFocus(false)
succesRecherche:SetMaxLetters(20)
succesRecherche:SetJustifyH("LEFT")
succesRecherche:SetTextInsets(12, 4, 0, 0) -- texte décalé du bord de l'encart
pcall(function()
    succesRecherche:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 6,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    succesRecherche:SetBackdropColor(0.56, 0.46, 0.29, 0.30)
    succesRecherche:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.95)
end)
succesRecherche:SetScript("OnTextChanged", function(self)
    filtreSucces = string.lower(self:GetText() or "")
    if RaffraichirSucces then RaffraichirSucces() end
end)
succesRecherche:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
succesRecherche.instructions = succesRecherche:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
succesRecherche.instructions:SetPoint("LEFT", 12, 0)
succesRecherche.instructions:SetText(L("Rechercher un succès..."))
succesRecherche.instructions:SetTextColor(1, 1, 1)
succesRecherche:SetScript("OnEditFocusGained", function(self) self.instructions:Hide() end)
succesRecherche:SetScript("OnEditFocusLost", function(self)
    if (self:GetText() or "") == "" then self.instructions:Show() end
end)

succesScroll:SetPoint("TOPLEFT", pageSucces, "TOPLEFT", 58, -58)
succesScroll:SetSize(520, 280)
local succesContenu = CreateFrame("Frame", nil, succesScroll)
succesContenu:SetSize(520, 1)
succesScroll:SetScrollChild(succesContenu)

-- v0.126 : bandeau « CARNET COMPLET » en tête de liste quand tous
-- les succès sont obtenus — caché sinon (la liste décale de 44px).
local succesBanniere = CreateFrame("Frame", nil, succesContenu)
succesBanniere:SetSize(520, 34)
succesBanniere:SetPoint("TOPLEFT", succesContenu, "TOPLEFT", 0, 0)
local sbFond = succesBanniere:CreateTexture(nil, "BACKGROUND")
sbFond:SetAllPoints()
sbFond:SetColorTexture(0.30, 0.22, 0.08, 0.92)
local sbTrait = succesBanniere:CreateTexture(nil, "OVERLAY")
sbTrait:SetHeight(2)
sbTrait:SetWidth(504)
sbTrait:SetPoint("TOPLEFT", 8, -2)
sbTrait:SetColorTexture(0.78, 0.62, 0.25, 1)
local sbTxt = succesBanniere:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pcall(function() sbTxt:SetFont("Fonts\\FRIZQT__.TTF", 14) end)
sbTxt:SetPoint("CENTER", 0, 0)
sbTxt:SetShadowColor(0, 0, 0, 1)
sbTxt:SetShadowOffset(1, -1)
succesBanniere:Hide()

local lignesSucces = {} -- pool de lignes réutilisées (icône + texte)
RaffraichirSucces = function()
    local y = 0
    local n = 0
    local function Ligne()
        n = n + 1
        local l = lignesSucces[n]
        if not l then
            l = CreateFrame("Frame", nil, succesContenu)
            l:SetSize(520, 26)
            l.barre = l:CreateTexture(nil, "BACKGROUND")
            l.barre:SetAllPoints()
            l.barre:SetColorTexture(0.55, 0.45, 0.20, 0.9)
            -- Trait doré sous les en-têtes de catégorie, façon titre de chapitre
            l.trait = l:CreateTexture(nil, "OVERLAY")
            l.trait:SetHeight(2)
            l.trait:SetWidth(504)
            l.trait:SetPoint("TOPLEFT", 8, 2)
            l.trait:SetColorTexture(0.78, 0.62, 0.25, 0.8)
            l.trait:Hide()
            l.icone = l:CreateTexture(nil, "ARTWORK")
            l.icone:SetSize(22, 22)
            l.icone:SetPoint("LEFT", 4, 0)
            l.texte = l:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            l.texte:SetPoint("LEFT", l.icone, "RIGHT", 10, 0)
            l.texte:SetWidth(440)
            l.texte:SetJustifyH("LEFT")
            -- Case à cocher : carré vide, coché quand le succès est obtenu
            l.caseFond = l:CreateTexture(nil, "ARTWORK")
            l.caseFond:SetSize(16, 16)
            l.caseFond:SetPoint("RIGHT", -8, 0)
            l.caseFond:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
            l.caseCoche = l:CreateTexture(nil, "OVERLAY")
            l.caseCoche:SetSize(16, 16)
            l.caseCoche:SetPoint("RIGHT", -8, 0)
            l.caseCoche:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            l.caseCoche:Hide()
            -- Mini barre de progression de la catégorie (en-têtes uniquement)
            l.progFond = l:CreateTexture(nil, "ARTWORK")
            l.progFond:SetSize(80, 8)
            l.progFond:SetPoint("RIGHT", -34, 0)
            l.progFond:SetColorTexture(0.18, 0.14, 0.08, 0.95)
            l.progFill = l:CreateTexture(nil, "OVERLAY")
            l.progFill:SetSize(0, 8)
            l.progFill:SetPoint("RIGHT", -34, 0)
            l.progFill:SetColorTexture(0.95, 0.78, 0.30, 1)
            l.progPct = l:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            l.progPct:SetPoint("RIGHT", -6, 0)
            l.progFond:Hide()
            l.progFill:Hide()
            l.progPct:SetText("")
            lignesSucces[n] = l
        end
        l:ClearAllPoints()
        l:SetPoint("TOPLEFT", succesContenu, "TOPLEFT", 0, y)
        l:Show()
        return l
    end
    -- v0.126 : bandeau complet en tête de liste (44px réservés)
    local nbObtS = 0
    for _, s in ipairs(MHH_SUCCES) do
        if DB.succes[s.id] then nbObtS = nbObtS + 1 end
    end
    if nbObtS >= #MHH_SUCCES and #MHH_SUCCES > 0 then
        succesBanniere:Show()
        sbTxt:SetText("|cffffd100" .. L("CARNET COMPLET — tous les succès sont obtenus !") .. "|r")
        y = -44
    else
        succesBanniere:Hide()
    end
    -- Filtrage (nom, description, catégorie) puis comptage par catégorie
    local function MatchSucces(s)
        if filtreSucces == "" then return true end
        if string.find(string.lower(s.nom), filtreSucces, 1, true) then return true end
        if string.find(string.lower(s.desc), filtreSucces, 1, true) then return true end
        if string.find(string.lower(s.cat), filtreSucces, 1, true) then return true end
        return false
    end
    local compte = {}
    for _, s in ipairs(MHH_SUCCES) do
        local c = compte[s.cat] or { total = 0, obt = 0, visible = 0 }
        c.total = c.total + 1
        if DB.succes[s.id] then c.obt = c.obt + 1 end
        compte[s.cat] = c
    end
    local cat = nil
    for _, s in ipairs(MHH_SUCCES) do
        if MatchSucces(s) then
            if s.cat ~= cat then
                -- Respiration avant le titre d'une nouvelle catégorie
                if cat then y = y - 14 end
                cat = s.cat
                local c = compte[s.cat]
                local l = Ligne()
                l.icone:Hide()
                l.barre:Show()
                l.caseFond:Hide()
                l.caseCoche:Hide()
                l.trait:Show()
                l.texte:SetFontObject("GameFontNormal")
                l.texte:SetText("|cffffd100  " .. string.upper(s.cat) .. "  —  " .. c.obt .. "/" .. c.total .. "|r")
                l.progFond:Show()
                l.progFill:Show()
                l.progFill:SetWidth(80 * c.obt / math.max(1, c.total))
                l.progPct:SetText(math.floor(100 * c.obt / math.max(1, c.total) + 0.5) .. "%")
                y = y - 32
            end
            local l = Ligne()
            l.icone:Show()
            l.barre:Hide()
            l.caseFond:Show()
            l.trait:Hide()
            l.progFond:Hide()
            l.progFill:Hide()
            l.progPct:SetText("")
            l.texte:SetFontObject("GameFontHighlight")
            l.icone:SetTexture("Interface\\Icons\\" .. (s.tex or "INV_Misc_QuestionMark"))
            if DB.succes[s.id] then
                l.caseCoche:Show()
                l.texte:SetText("|cffa0ff50" .. s.nom .. "|r — " .. s.desc)
                -- Icône en couleurs : succès obtenu
                pcall(function() l.icone:SetDesaturated(false) end)
                l.icone:SetVertexColor(1, 1, 1)
            else
                l.caseCoche:Hide()
                l.texte:SetText("|cff9a8a6a" .. s.nom .. " — " .. s.desc .. "|r")
                -- Icône grisée/désaturée : succès verrouillé
                pcall(function() l.icone:SetDesaturated(true) end)
                l.icone:SetVertexColor(0.45, 0.45, 0.45)
            end
            y = y - 26
        end
    end
    for i = n + 1, #lignesSucces do lignesSucces[i]:Hide() end
    succesContenu:SetHeight(math.max(1, -y + 26))
end
end -- fin bloc page Succès

-- ================= PAGE PROFIL =================
-- Fond encadré, cohérent avec les autres pages
do
local boutonTitre -- forward : créé plus bas, référencé par RaffraichirProfil
local profilStatsLabel -- forward : le bouton armes masque ce bloc à l'ouverture
local profilStats -- forward : idem (bloc statistiques de la page Guilde)
local profilFond = CreateFrame("Frame", nil, pageProfil, MHH_TEMPLATE_BACKDROP)
profilFond:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 44, -42)
profilFond:SetSize(552, 314)
pcall(function()
    profilFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    profilFond:SetBackdropColor(0.48, 0.38, 0.24, 0.35)
    profilFond:SetBackdropBorderColor(0.75, 0.60, 0.30, 0.9)
end)

-- « Photo de chasseur » : portrait 3D du perso, encadré façon journal
local profilPortrait = CreateFrame("Frame", nil, pageProfil, MHH_TEMPLATE_BACKDROP)
profilPortrait:SetSize(100, 100)
profilPortrait:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 64, -70)
pcall(function()
    profilPortrait:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
    })
    profilPortrait:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.9)
end)
profilPortrait.tex = profilPortrait:CreateTexture(nil, "ARTWORK")
profilPortrait.tex:SetPoint("TOPLEFT", 6, -6)
profilPortrait.tex:SetSize(88, 88)
-- Fond photo personnalisé (TGA de test) : portrait.tga / portrait1.tga
-- déposés dans le dossier de l'addon. Le premier chemin qui répond
-- gagne ; le portrait 3D live s'affiche PAR-DESSUS (calque ARTWORK)
profilPortrait.fond = profilPortrait:CreateTexture(nil, "BACKGROUND")
profilPortrait.fond:SetPoint("TOPLEFT", 6, -6)
profilPortrait.fond:SetSize(88, 88)
profilPortrait.fond:Hide()
pcall(function()
    local CHEMINS_FOND = {
        "Interface\\AddOns\\MHHunt\\Textures\\portrait.tga",
        "Interface\\AddOns\\MHHunt\\Textures\\portrait1.tga",
        "Interface\\AddOns\\MHHunt\\portrait.tga",
        "Interface\\AddOns\\MHHunt\\portrait1.tga",
    }
    for _, chemin in ipairs(CHEMINS_FOND) do
        if profilPortrait.fond:SetTexture(chemin) then
            profilPortrait.fond:Show()
            break
        end
    end
end)

local profilIdentite = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
profilIdentite:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 184, -66)
-- Arme emblème selon la classe WoW (icône à côté du rang)
local CLASSES_ARMES = {
    WARRIOR = "INV_Sword_04",
    PALADIN = "INV_Hammer_01",
    HUNTER = "INV_Weapon_Bow_02",
    ROGUE = "INV_Weapon_ShortBlade_01",
    PRIEST = "INV_Mace_01",
    SHAMAN = "INV_Mace_01",
    MAGE = "INV_Misc_Book_09",
    WARLOCK = "INV_Misc_Book_11",
    DRUID = "INV_Misc_MonsterClaw_04",
}
-- Titre-flavor par classe (clin d'œil chasseur, vocabulaire générique :
-- pas de noms déposés Monster Hunter, juste l'esprit « guilde de chasse »)
local CLASSES_FLAVOR = {
    WARRIOR = "Lame de la guilde",
    PALADIN = L("Croisé de l'aube"),
    HUNTER = L("Maître-archer"),
    ROGUE = L("Ombre aux aguets"),
    PRIEST = L("Exorciste itinérant"),
    SHAMAN = L("Sage des esprits"),
    MAGE = L("Sorcier de guerre"),
    WARLOCK = "Invocateur maudit",
    DRUID = L("Métamorphe des bois"),
}
-- Rang : libellé + nom fusionnés sur une ligne, toujours au-dessus du
-- séparateur (même « Légende de la chasse » ne peut plus déborder)
local profilRangTexte = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
profilRangTexte:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 184, -90)
profilRangTexte:SetWidth(300)
profilRangTexte:SetJustifyH("LEFT")
pcall(function() profilRangTexte:SetWordWrap(false) end)
profilRangTexte:SetShadowColor(0, 0, 0, 1)
profilRangTexte:SetShadowOffset(1, -1)
-- Classe + petite icône d'arme, puis titre juste dessous (sans séparateur :
-- plus compact, et le bouton « Changer le titre » trouve sa place dessous)
local profilClasseIcone = pageProfil:CreateTexture(nil, "ARTWORK")
profilClasseIcone:SetSize(22, 22)
profilClasseIcone:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 182, -110)
profilClasseIcone:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
local profilClasseTxt = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
profilClasseTxt:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 208, -114)
profilClasseIcone:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    local classeFr, token = UnitClass("player")
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("|cffffd100" .. (classeFr or "?") .. "|r")
    GameTooltip:AddLine("|cff8a6d3b" .. (CLASSES_FLAVOR[(token or ""):upper()] or L("Chasseur de la guilde")) .. "|r", 1, 1, 1, true)
    GameTooltip:Show()
end)
profilClasseIcone:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
-- Histogramme « armes de chasse » (façon carte de guilde MH) : l'icône de
-- classe est CLIQUABLE — un panneau s'ouvre dessous avec les armes les
-- plus utilisées, barres horizontales triées par nombre de prises.
MHH_armesBtn = CreateFrame("Button", nil, pageProfil)
MHH_armesBtn:SetSize(22, 22)
MHH_armesBtn:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 182, -110)
MHH_armesBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
MHH_armesBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("|cffffd100" .. L("Armes de chasse") .. "|r")
    GameTooltip:AddLine(L("|cff8a6d3bCliquez : armes les plus utilisées.|r"), 1, 1, 1, true)
    GameTooltip:Show()
end)
MHH_armesBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
MHH_armesPan = CreateFrame("Frame", nil, pageProfil, MHH_TEMPLATE_BACKDROP)
-- Le panneau SE SUPERPOSE au bloc statistiques (la page est dense) : l'ouvrir
-- masque les stats, le fermer les rend. Positionné pile sur la zone stats.
MHH_armesPan:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 58, -192)
MHH_armesPan:SetSize(280, 158)
MHH_armesPan:Hide()
-- v0.118t : RÉGRESSION encart invisible — plus de SetFrameStrata("HIGH")
-- (un enfant de strate supérieure à son parent ne rend plus sur ce
-- client hybride). On reste dans la strate de la page et on monte en
-- NIVEAU à la place, l effet visuel est le même.
MHH_armesPan:SetFrameLevel(50)
-- L'histogramme suit la fenêtre et l'onglet : jamais d'encart orphelin
-- qui survit à la fermeture du carnet ou à un changement d'onglet.
-- (fermeture de l'histogramme gérée par le HookScript OnHide plus bas :
--  il rend aussi le bloc statistiques)
pcall(function()
    MHH_armesPan:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    MHH_armesPan:SetBackdropColor(0.16, 0.12, 0.07, 0.97)
    MHH_armesPan:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.95)
end)
MHH_armesPanTitre = MHH_armesPan:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MHH_armesPanTitre:SetPoint("TOP", 0, -6)
MHH_armesPanTitre:SetText(L("|cffffd100ARMES DE CHASSE|r"))
MHH_armesVide = MHH_armesPan:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_armesVide:SetPoint("TOP", 0, -34)
MHH_armesVide:SetText(L("|cffa58b54Aucune prise mesurée encore — l'arme de vos victoires s'inscrira ici.|r"))
MHH_armesVide:SetWidth(196)
MHH_armesVide:Hide()
MHH_armesBarres = {}
-- HISTOGRAMME — colonnes fines, barres petites, libellés VERTICAUX en
-- diagonale (une lettre par ligne, décalée d'un espace à chaque étage :
-- astuce Vanilla, SetRotation n'existe pas sur ce client).
MHH_armesNettoyees = false
function MHH_RaffraichirArmesHistogramme()
    if not DB then return end
    -- NETTOYAGE UNIQUE des entrées parasites : d'anciennes versions ont
    -- pu enregistrer des lignes de tooltip entières (« Niveau d'objet 17 »)
    -- comme type d'arme. Clé non reconnue = jetée ; graphie différente =
    -- fusionnée dans sa forme canonique. (Ici, pas dans InitDB : la fonction
    -- de normalisation est définie plus bas dans le fichier.)
    if not MHH_armesNettoyees and DB.armes then
        MHH_armesNettoyees = true
        for k, n in pairs(DB.armes) do
            local canon = NormaliserTypeArme(k)
            if not canon then
                DB.armes[k] = nil
            elseif canon ~= k then
                DB.armes[canon] = (DB.armes[canon] or 0) + n
                DB.armes[k] = nil
            end
        end
    end
    local types = MHH_TypesArmesJoueur()
    -- v0.38 : fusion 1M/2M à l'affichage (même sac, cf. MHH_GROUPE_ARME)
    local typesAff = {}
    local vuType = {}
    for _, t in ipairs(types) do
        local p = MHH_GROUPE_ARME[t] or t
        if not vuType[p] then vuType[p] = true; typesAff[#typesAff + 1] = p end
    end
    types = typesAff
    local comptes = {}
    for _, canon in ipairs(types) do comptes[canon] = 0 end
    if DB.armes then
        for arme, n in pairs(DB.armes) do
            local canon = NormaliserTypeArme(arme)
            if canon then canon = MHH_GROUPE_ARME[canon] or canon end
            if comptes[canon] then comptes[canon] = comptes[canon] + n end
        end
    end
    local total = 0
    for _, n in pairs(comptes) do total = total + n end
    MHH_armesVide:SetShown(total == 0)
    local nbTypes = #types
    -- géométrie (panneau 280x158, tout ancré depuis le BAS)
    -- MARGE de sûreté : les colonnes vivent entre « marge » et
    -- « largeur - marge » — aucune piste ni libellé ne peut coller ou
    -- déborder du bord du panneau. ADAPTATIF : si la classe a beaucoup
    -- de types d'armes (chasseur = 10), pistes et libellés se resserrent
    -- d'eux-mêmes — l'affichage ne peut pas déborder, quelle que soit
    -- la classe.
    local largPan = 280
    local marge = 10
    local pas = (largPan - 2 * marge) / nbTypes
    -- GROS COMPTES : la hauteur est NORMALISÉE sur hMax — la plus grosse
    -- barre plafonne à hMax, les autres à proportion. AGRANDI puis
    -- RÉDUIT d'un poil (72 → 60) : trop haut à l'œil ; il reste ~25 px
    -- au-dessus pour le chiffre du compte.
    local hMax = 60
    -- l'axe est HAUT : sous lui, la place des libellés verticaux (la plus
    -- longue étiquette « Haches 2M » = 8 lettres x 9px = 72px de descente)
    -- axe abaissé : l'ensemble descend de 8 px pour s'équilibrer dans
    -- le panneau (garde ~15 px de marge sous le plus long libellé)
    local axe = 46                        -- ligne d'axe depuis le bas (v0.43 : abaissé encore de 14 px — l'espace vide était tout en bas du panneau, l'ensemble remplit maintenant la hauteur)
    -- Alignement texte/colonne, réglé à l'œil en jeu : les textes
    -- penchaient à droite à 0 et 3 — 8 px pour tomber sur la colonne.
    -- ATTENTION : decal apparié aux pistes de 18 px ci-dessous (combo
    -- 18 px + 8 px = celui validé à l'œil ; à 24 px de piste ou 4 px de
    -- decal, les textes redécalaient à droite — ne pas changer l'un
    -- sans l'autre).
    local decal = 8
    -- Décalage d'ENSEMBLE : l'histogramme paraît collé à gauche dans le
    -- panneau — on pousse tout (colonnes, comptes, noms) vers la droite.
    local offsetX = 10
    for i, canon in ipairs(types) do
        local barre = MHH_armesBarres[i]
        if not barre then
            barre = {}
            barre.fond = MHH_armesPan:CreateTexture(nil, "BACKGROUND")
            -- PISTE BIEN VISIBLE : sombre et contrastée sur le fond du
            -- panneau (les essais beige étaient invisibles à l'œil)
            barre.fond:SetColorTexture(0.09, 0.07, 0.04, 1)
            barre.fill = MHH_armesPan:CreateTexture(nil, "ARTWORK")
            barre.fill:SetColorTexture(0.78, 0.62, 0.25, 0.95)
            barre.txt = MHH_armesPan:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            barre.txt:SetJustifyH("CENTER")
            barre.count = MHH_armesPan:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            barre.count:SetJustifyH("CENTER")
            barre.ic = MHH_armesPan:CreateTexture(nil, "ARTWORK") -- v0.36 : icône du type d'arme
            MHH_armesBarres[i] = barre
        end
        local n = comptes[canon]
        local cx = marge + pas * (i - 0.5) + offsetX
        local colW = pas
        -- piste : élargie en v0.45 (26 → 32 px max) pour équilibrer les
        -- grosses icônes — l'ancienne mise en garde « 24 px décrochait les
        -- textes » est caduque : les libellés verticaux sont remplacés par
        -- des icônes calées sur cx, indépendantes de la piste. Toujours
        -- resserrée automatiquement si beaucoup de colonnes.
        local pisteW = math.min(colW - 10, 32)
        -- PISTE : repère sous le compte, de l'axe à axe+hMax
        barre.fond:SetSize(pisteW, hMax)
        barre.fond:ClearAllPoints()
        barre.fond:SetPoint("BOTTOM", MHH_armesPan, "BOTTOMLEFT", cx + 4 - pisteW / 2, axe)
        -- BARRE : monte de l'axe — MÊME À 0, un bout de colonne reste
        -- visible (moche sinon : colonne fantôme sans repère)
        -- v0.46 : stub 4 → 8 px — avec des pistes de 32 px, un quartier
        -- de 4 px paraissait écrasé à l'œil.
        local h = 8
        -- Montée TRÈS LENTE : le palier de croissance passe de 64 à 128 —
        -- chaque prise ajoute encore moins de hauteur (1 ≈ 5 px, 4 ≈ 11,
        -- 9 ≈ 16, 16 ≈ 21, 36 ≈ 32, 128 prises = hauteur max). Les
        -- colonnes restent comparables (la plus fournie plafonne à hMax
        -- quand elle dépasse le palier de référence).
        local h = 4
        if n > 0 then
            local nmax = 1
            for _, v in pairs(comptes) do
                if v > nmax then nmax = v end
            end
            local ref = math.max(nmax, 128) -- palier de croissance étalé
            h = math.max(8, math.floor(hMax * math.sqrt(n) / math.sqrt(ref) + 0.5))
            if h > hMax then h = hMax end
        end
        barre.fill:ClearAllPoints()
        barre.fill:SetSize(pisteW, h)
        barre.fill:SetPoint("BOTTOM", MHH_armesPan, "BOTTOMLEFT", cx + 4 - pisteW / 2, axe)
        barre.fill:Show()
        if n == 0 then
            -- gris clair : visible même à 0 sur la piste sombre
            pcall(function() barre.fill:SetVertexColor(0.55, 0.48, 0.36, 0.95) end)
        else
            pcall(function() barre.fill:SetVertexColor(1, 1, 1, 1) end)
        end
        -- COMPTE : au sommet de la barre. Correction optique : le glyphe
        -- « 1 » est décentré dans sa boîte (plus de vide à gauche), il
        -- paraît à droite de sa colonne — 1 px de rabattage le recentre.
        -- v0.48 : COMPTE encore 4 px plus à gauche (-16 px — retour à l'œil
        -- après le v0.47 jugé encore trop à droite).
        barre.count:ClearAllPoints()
        barre.count:SetPoint("BOTTOM", MHH_armesPan, "BOTTOMLEFT", cx - 12, axe + h + 1)
        barre.count:SetText(n > 0 and ("|cffffd100" .. n .. "|r") or "|cff7777770|r")
        -- v0.36 : ICÔNE du type d'arme façon Monster Hunter — le
        -- libellé vertical ne reste que pour les types sans icône.
        -- Custom : Textures/arme_<cle>.tga ; sinon l'icône du jeu.
        local cleIcone = MHH_CLE_ICONE_ARME[canon]
        local cheminIcone = nil
        if cleIcone and DB.config.texUI == "custom" then
            cheminIcone = "Interface\\AddOns\\MHHunt\\Textures\\Weapons\\weapon_" .. (MHH_FICHIER_ARME[cleIcone] or cleIcone) .. ".tga"
        elseif cleIcone then
            cheminIcone = MHH_ICONES_ARMES_WOW[canon]
        end
        if cheminIcone then
            pcall(function()
                -- v0.43 : 34 px max (retour à l'œil : 28 encore petit),
                -- resserrage automatique si beaucoup de types.
                local icW = math.min(34, math.max(16, pas - 2))
                -- calage : 4 px sous l'axe ; décalé de 12 px à GAUCHE
                -- (retour à l'œil : l'icône paraissait à droite de sa
                -- colonne — même correction optique que les comptes)
                barre.ic:SetTexture(cheminIcone)
                barre.ic:ClearAllPoints()
                barre.ic:SetPoint("CENTER", MHH_armesPan, "BOTTOMLEFT", cx - 16, axe - 4 - icW / 2)
                barre.ic:SetSize(icW, icW)
                barre.ic:Show()
            end)
            barre.txt:SetText("")
            barre.txt:Hide()
        else
            barre.ic:Hide()
            -- LIBELLÉ VERTICAL SIMPLE : une lettre par ligne, centré sous
            -- l'axe (types sans icône : Pugilat/Hast/Arbalète/Baguette
            -- en mode icônes du jeu — texte vertical seul, singulier, court)
            local court = MHH_TYPES_ARMES_COURT[canon] or canon
            -- libellé trop long ? on abrège avec un point, pas grave
            if #court > 6 then court = court:sub(1, 5) .. "." end
            local lignes = {}
            for li = 1, #court do
                local c = court:sub(li, li)
                if c ~= " " then lignes[#lignes + 1] = c end
            end
            barre.txt:ClearAllPoints()
            -- séparé de l'axe par 4 px : le texte ne colle plus à la colonne
            barre.txt:SetPoint("TOP", MHH_armesPan, "BOTTOMLEFT", cx - decal, axe - 5)
            barre.txt:SetWidth(math.max(colW, 10))
            barre.txt:SetJustifyH("CENTER")
            barre.txt:SetText("|cffd8c9a3" .. table.concat(lignes, "\n") .. "|r")
            barre.txt:Show()
        end
    end
end

MHH_armesBtn:SetScript("OnClick", function()
    if MHH_armesPan:IsShown() then
        MHH_armesPan:Hide()
        -- le bloc statistiques revient
        if profilStatsLabel then profilStatsLabel:Show() end
        if profilStats then profilStats:Show() end
    else
        MHH_RaffraichirArmesHistogramme()
        -- le bloc statistiques laisse la place à l'histogramme
        if profilStatsLabel then profilStatsLabel:Hide() end
        if profilStats then profilStats:Hide() end
        MHH_armesPan:Show()
    end
end)
-- Refermer l'histogramme (et rendre les stats) quand on quitte l'onglet Guilde
pageProfil:HookScript("OnHide", function()
    if MHH_armesPan and MHH_armesPan:IsShown() then
        MHH_armesPan:Hide()
        if profilStatsLabel then profilStatsLabel:Show() end
        if profilStats then profilStats:Show() end
    end
end)

local profilSousTitre = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
profilSousTitre:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 184, -138)
profilSousTitre:SetWidth(150)
profilSousTitre:SetJustifyH("LEFT")
pcall(function() profilSousTitre:SetWordWrap(false) end)
profilSousTitre:SetShadowColor(0, 0, 0, 1)
profilSousTitre:SetShadowOffset(1, -1)
profilSousTitre:SetText(L("|cff8a6d3bJournal de chasse — Guilde des chasseurs|r"))

-- Vitrine de trophées : LES DERNIERS SUCCÈS OBTENUS, du plus récent au
-- plus ancien (5 emplacements). Tant qu'aucun succès n'est obtenu, on
-- garde le lot vedette grisé — une vitrine vide attend ses pièces.
-- Verrouillés = icône grise/délavée ; débloqués = icône en couleur, tooltip.
local vitrineLabel = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
vitrineLabel:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -70)
vitrineLabel:SetText(L("|cffffd100TROPHÉES DE CHASSE|r"))
local TROPHEES = { "premiere", "intact", "nocturne", "grandgibier", "piege" }
local vitrineTrophees = {}
local sucInfo = {}
for _, s in ipairs(MHH_SUCCES) do sucInfo[s.id] = s end
for i = 1, 5 do
    local b = CreateFrame("Button", nil, pageProfil)
    b.idVitrine = TROPHEES[i] -- réécrit à chaque rafraîchissement du profil
    b:SetSize(30, 30)
    b:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368 + (i - 1) * 36, -88)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexture("Interface\\Icons\\" .. (sucInfo[TROPHEES[i]] and sucInfo[TROPHEES[i]].tex or "INV_Misc_QuestionMark"))
    b.icon:SetDesaturated(true)
    b.icon:SetVertexColor(0.45, 0.40, 0.34, 0.9)
    vitrineTrophees[i] = b
    b:SetScript("OnEnter", function(self)
        local s = sucInfo[self.idVitrine]
        if not s then return end
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if DB.succes[self.idVitrine] then
                GameTooltip:AddLine("|cffffd100" .. s.nom .. "|r")
                GameTooltip:AddLine(s.desc, 1, 1, 1, true)
                local tS = tonumber(DB.succes[self.idVitrine])
                if tS then
                    GameTooltip:AddLine("|cffa0ff50Obtenu —|r " .. date("%d/%m/%y", tS), 1, 1, 1, true)
                else
                    GameTooltip:AddLine("|cffa0ff50Obtenu|r", 1, 1, 1, true)
                end
            else
                GameTooltip:AddLine("|cff808080" .. s.nom .. L(" — verrouillé|r"))
                GameTooltip:AddLine(s.desc, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self) if GameTooltip then GameTooltip:Hide() end end)
end
-- Derniers succès obtenus, du plus récent au plus ancien (les dates sont
-- les timestamps stockés par DebloquerSucces dans DB.succes[id])
local function DerniersSucces(nMax)
    local obtenus = {}
    for id, t in pairs(DB.succes) do
        obtenus[#obtenus + 1] = { id = id, t = t }
    end
    table.sort(obtenus, function(a, b) return (a.t or 0) > (b.t or 0) end)
    local res = {}
    for i = 1, math.min(nMax or 5, #obtenus) do res[i] = obtenus[i].id end
    return res
end

-- Titres de chasseur : 4 familles au choix (bouton du profil), paliers progressifs
local TITRES = {
    naturaliste = { -- monstres catalogués
        { seuil = 0,   nom = L("Apprenti du carnet") },
        { seuil = 5,   nom = L("Preneur de notes") },
        { seuil = 10,  nom = L("Naturaliste débutant") },
        { seuil = 25,  nom = "Grand naturaliste" },
        { seuil = 50,  nom = L("Zoologue de terrain") },
        { seuil = 100, nom = L("Maître bestiaire") },
    },
    chasseur = { -- chasses totales
        { seuil = 0,   nom = L("Bleu de la chasse") },
        { seuil = 5,   nom = L("Teneur de registre") },
        { seuil = 10,  nom = "Pisteur" },
        { seuil = 25,  nom = "Limier" },
        { seuil = 50,  nom = L("Homme du terrain") },
        { seuil = 100, nom = L("Vieil homme du métier") },
        { seuil = 250, nom = L("Légende vivante") },
    },
    explorateur = { -- zones de chasse visitées
        { seuil = 0,   nom = "Casanier" },
        { seuil = 3,   nom = "Voyageur" },
        { seuil = 6,   nom = L("Rôdeur") },
        { seuil = 10,  nom = L("Dénicheur de sentiers") },
        { seuil = 15,  nom = "Globe-trotter" },
        { seuil = 25,  nom = L("Cartographe des terres sauvages") },
    },
    traqueur = { -- découvertes de rares inconnus
        { seuil = 0,   nom = L("Bleu du carnet") },
        { seuil = 1,   nom = "Œil vif" },
        { seuil = 3,   nom = L("Nez fin") },
        { seuil = 5,   nom = L("Sur la piste") },
        { seuil = 10,  nom = L("Traqueur de l'inconnu") },
        { seuil = 20,  nom = L("Révélateur de légendes") },
    },
}
local function ValeurTitre(famille)
    if famille == "chasseur" then return nbChasses() end
    if famille == "explorateur" then
        local n = 0
        for _ in pairs(DB.zonesChassees) do n = n + 1 end
        return n
    end
    if famille == "traqueur" then return nbDecouverts() end
    return nbCatalogues()
end
local function TitreDeFamille(famille)
    local palier = TITRES[famille] or TITRES.naturaliste
    local nom = palier[1].nom
    for _, t in ipairs(palier) do
        if ValeurTitre(famille) >= t.seuil then nom = t.nom end
    end
    return nom
end
-- Bordure du portrait : couleur qui s'enrichit avec le rang de guilde
-- (COULEURS_RANG : définie en tête de fichier, partagée avec l'Accueil)

-- Palmarès : top 3 des chasses + dernière prise (moitié droite, sous la vitrine)
local palmaresTitre = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
palmaresTitre:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -138)
palmaresTitre:SetText(L("|cffffd100PALMARÈS DES CHASSES|r"))
local couleursPalmares = {
    { 0.95, 0.78, 0.25 }, -- or
    { 0.78, 0.78, 0.82 }, -- argent
    { 0.72, 0.45, 0.25 }, -- bronze
}
local palmaresPips, palmaresTextes = {}, {}
for i = 1, 3 do
    local pip = pageProfil:CreateTexture(nil, "ARTWORK")
    pip:SetSize(10, 10)
    pip:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -162 - (i - 1) * 24)
    pip:SetColorTexture(couleursPalmares[i][1], couleursPalmares[i][2], couleursPalmares[i][3], 0.95)
    pip:Hide()
    palmaresPips[i] = pip
    local t = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 384, -160 - (i - 1) * 24)
    t:SetWidth(192)
    t:SetJustifyH("LEFT")
    pcall(function() t:SetWordWrap(false) end)
    t:SetShadowColor(0, 0, 0, 1)
    t:SetTextColor(1, 1, 1)
    t:SetShadowOffset(1, -1)
    palmaresTextes[i] = t
end
local palmaresDerniere = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
palmaresDerniere:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -238)
palmaresDerniere:SetShadowColor(0, 0, 0, 1)
palmaresDerniere:SetTextColor(1, 1, 1)
palmaresDerniere:SetShadowOffset(1, -1)
palmaresDerniere:SetWidth(208)
palmaresDerniere:SetJustifyH("LEFT")

-- Ornaments de chasse : médailons débloqués selon les statistiques
-- (calculés en direct, rien à stocker — façon carte de guilde MH)
local ornementLabel = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ornementLabel:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -280)
ornementLabel:SetText(L("|cffffd100ORNEMENTS DE CHASSE|r"))
local ORNEMENTS = {
    { tex = "Ability_Hunter_BeastTaming", nom = L("Patte du prédateur"), desc = L("10 chasses réussies"),             valeur = function() return nbChasses() end,  objectif = 10 },
    { tex = "Ability_Hunter_AimedShot",  nom = "Œil du viseur",      desc = L("25 chasses réussies"),             valeur = function() return nbChasses() end,  objectif = 25 },
    { tex = "Spell_Fire_FireBolt",       nom = L("Flamme tenace"),      desc = L("5 chasses consécutives sans mourir"), valeur = function() return DB.serie or 0 end, objectif = 5 },
    { tex = "Ability_Rogue_Eviscerate",  nom = "Sang-froid",          desc = L("10 chasses consécutives sans mourir"), valeur = function() return DB.serie or 0 end, objectif = 10 },
    { tex = "INV_Misc_Book_09",          nom = L("Carnet usé"),          desc = L("Chasses dans 10 zones différentes"),
      valeur = function() local n = 0 for _ in pairs(DB.zonesChassees) do n = n + 1 end return n end, objectif = 10 },
    { tex = "Spell_Arcane_StarFire",     nom = L("Étoile du découvreur"), desc = L("5 découvertes de rares inconnus"), valeur = function() return nbDecouverts() end, objectif = 5 },
}
local ornementIcons = {}
for i, med in ipairs(ORNEMENTS) do
    local b = CreateFrame("Button", nil, pageProfil)
    b:SetSize(24, 24)
    b:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368 + (i - 1) * 32, -302)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexture("Interface\\Icons\\" .. med.tex)
    b.icon:SetDesaturated(true)
    b.icon:SetVertexColor(0.45, 0.40, 0.34, 0.9)
    ornementIcons[i] = b
    b:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local v = med.valeur()
            if v >= med.objectif then
                GameTooltip:AddLine("|cffffd100" .. med.nom .. "|r")
                GameTooltip:AddLine(med.desc, 1, 1, 1, true)
                GameTooltip:AddLine("|cffa0ff50Obtenu|r", 1, 1, 1, true)
            else
                GameTooltip:AddLine("|cff808080" .. med.nom .. "|r")
                GameTooltip:AddLine(med.desc .. " (" .. v .. "/" .. med.objectif .. ")", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

-- Séparation verticale entre la colonne identité et la colonne décorative
local profilSeparateur = pageProfil:CreateTexture(nil, "OVERLAY")
profilSeparateur:SetWidth(2)
profilSeparateur:SetHeight(240)
profilSeparateur:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 346, -76)
profilSeparateur:SetColorTexture(0.62, 0.48, 0.22, 0.85)
-- (La barre de progression de guilde vit désormais sur la page Accueil)

-- Séparateur après le bloc titre : les statistiques commencent une section
local profilSeparateur2 = pageProfil:CreateTexture(nil, "OVERLAY")
profilSeparateur2:SetHeight(2)
profilSeparateur2:SetWidth(264)
profilSeparateur2:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 64, -186)
profilSeparateur2:SetColorTexture(0.62, 0.48, 0.22, 0.65)
profilStatsLabel = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profilStatsLabel:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 64, -198)
profilStatsLabel:SetText(L("|cffffd100STATISTIQUES DE CHASSE|r"))
profilStats = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
profilStats:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 64, -224)
profilStats:SetWidth(270)
profilStats:SetJustifyH("LEFT")
profilStats:SetShadowColor(0, 0, 0, 1)
profilStats:SetShadowOffset(1, -1)
profilStats:SetTextColor(1, 1, 1)
profilStats:SetSpacing(4)

RaffraichirProfil = function()
    -- Histogramme des armes : rafraîchi mais PAS rouvert d'office — il ne
    -- s'ouvre QUE sur clic du bouton (l'icône de classe) et se referme à
    -- chaque sortie d'onglet ; les stats restent visibles par défaut.
    MHH_RaffraichirArmesHistogramme()
    -- Photo du chasseur (portrait live)
    DefinirPortrait(profilPortrait.tex, "player")
    local total = nbChasses()
    local points = DB.points or 0
    local idx, rang = RangGuilde(points)
    profilIdentite:SetText("|cffffd100" .. (UnitName("player") or "?") .. "|r")
    profilRangTexte:SetText("|cff8a6d3bRang : " .. MHH_RangHex(idx) .. rang .. "|r")
    local classeFr, token = UnitClass("player")
    -- Affichage : titre-flavor « chasseur » ; la classe WoW reste en tooltip
    profilClasseTxt:SetText("|cffa58b54"
        .. (CLASSES_FLAVOR[(token or ""):upper()] or classeFr or "?") .. "|r")
    profilClasseIcone:SetTexture("Interface\\Icons\\"
        .. (CLASSES_ARMES[(token or ""):upper()] or "INV_Misc_QuestionMark"))
    -- Cadre du portrait : se pare des couleurs du rang
    local cr = MHH_COULEURS_RANG[idx] or MHH_COULEURS_RANG[1]
    pcall(function() profilPortrait:SetBackdropBorderColor(cr[1], cr[2], cr[3], 0.95) end)
    -- Titre de chasseur : famille au choix via le bouton du profil, palier selon les stats
    local famille = DB.titreFamille or "naturaliste"
    local titreComplet = TitreDeFamille(famille)
    profilSousTitre:SetText("|cff8a6d3bTitre : |cffffd100« " .. titreComplet .. " »|r")
    -- Le titre est souvent tronqué (150 px de large) : le tooltip le montre entier
    profilSousTitre.titreComplet = titreComplet
    profilSousTitre:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        -- ANCHOR_CURSOR : collé au pointeur (l'ancien ANCHOR_RIGHT
        -- s'éloignait du bord droit de la fenêtre du carnet)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText("|cffffd100« " .. (self.titreComplet or "?") .. " »|r")
        GameTooltip:Show()
    end)
    profilSousTitre:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    -- Vitrine de trophées : LES DERNIERS SUCCÈS OBTENUS (couleur, du plus
    -- récent au plus ancien). Emplacements inutilisés : masqués. Si aucun
    -- succès n'est encore obtenu, lot vedette grisé (vitrine en attente).
    local derniers = DerniersSucces(5)
    for i = 1, 5 do
        local b = vitrineTrophees[i]
        if #derniers > 0 then
            local id = derniers[i]
            if id then
                local s = sucInfo[id]
                b.idVitrine = id
                b.icon:SetTexture("Interface\\Icons\\" .. (s and s.tex or "INV_Misc_QuestionMark"))
                b.icon:SetDesaturated(false)
                b.icon:SetVertexColor(1, 1, 1, 1)
                b:Show()
            else
                b:Hide()
            end
        else
            local idDefaut = TROPHEES[i]
            local s = sucInfo[idDefaut]
            b.idVitrine = idDefaut
            b.icon:SetTexture("Interface\\Icons\\" .. (s and s.tex or "INV_Misc_QuestionMark"))
            b.icon:SetDesaturated(true)
            b.icon:SetVertexColor(0.45, 0.40, 0.34, 0.9)
            b:Show()
        end
    end
    -- (La barre de progression vit sur l'Accueil, plus ici)
    -- Palmarès : top 3 des proies les plus chassées
    local proies = {}
    for nom, info in pairs(DB.chasses) do
        if (info.kills or 0) > 0 then proies[#proies + 1] = { nom = nom, kills = info.kills } end
    end
    for nom, info in pairs(DB.decouverts) do
        if (info.kills or 0) > 0 then proies[#proies + 1] = { nom = nom, kills = info.kills } end
    end
    table.sort(proies, function(a, b)
        if a.kills ~= b.kills then return a.kills > b.kills end
        return a.nom < b.nom
    end)
    for i = 1, 3 do
        local p = proies[i]
        if p then
            palmaresPips[i]:Show()
            palmaresTextes[i]:SetText("|cffffd100" .. p.nom .. "|r — " .. p.kills .. (p.kills > 1 and L(" chasses") or L(" chasse")))
        else
            palmaresPips[i]:Hide()
            palmaresTextes[i]:SetText("|cff8a6d3b—|r")
        end
    end
    if DB.dernierePriseNom then
        palmaresDerniere:SetText(L("Dernière prise : |cffffd100") .. DB.dernierePriseNom .. "|r" .. (DB.dernierePriseDate and (" (" .. DB.dernierePriseDate .. ")") or ""))
    else
        palmaresDerniere:SetText(L("|cff8a6d3bDernière prise : aucune|r"))
    end
    local nbSucces = 0
    for _ in pairs(DB.succes) do nbSucces = nbSucces + 1 end
    local nbZones = 0
    for _ in pairs(DB.zonesChassees) do nbZones = nbZones + 1 end
    local nbTrophees = 0
    for _, v in pairs(DB.trophees or {}) do nbTrophees = nbTrophees + v end
    -- Ornaments : médailons colorés dès que l'objectif est atteint
    for i, med in ipairs(ORNEMENTS) do
        local b = ornementIcons[i]
        if med.valeur() >= med.objectif then
            b.icon:SetDesaturated(false)
            b.icon:SetVertexColor(1, 1, 1, 1)
        else
            b.icon:SetDesaturated(true)
            b.icon:SetVertexColor(0.45, 0.40, 0.34, 0.9)
        end
    end
    profilStats:SetText(table.concat({
        L("Chasses totales : |cffffd100") .. total .. "|r",
        L("Monstres catalogués : |cffffd100") .. nbCatalogues() .. "|r",
        L("Découvertes : |cffffd100") .. nbDecouverts() .. "|r",
        L("Succès obtenus : |cffffd100") .. nbSucces .. "|r/" .. #MHH_SUCCES,
        L("Zones de chasse visitées : |cffffd100") .. nbZones .. "|r",
        L("Meilleure série sans mourir : |cffffd100") .. (DB.serie or 0) .. "|r",
        L("Trophées prélevés : |cffffd100") .. nbTrophees .. "|r",
    }, "\n"))
end

-- Sélecteur de titre : bouton posé sur la ligne du titre (suit sa longueur)
-- (placement en fin de section : RaffraichirProfil doit déjà exister)
local FAMILLES_TITRES = { "naturaliste", "chasseur", "explorateur", "traqueur" }
boutonTitre = CreateFrame("Button", nil, pageProfil, MHH_TEMPLATE_BACKDROP)
boutonTitre:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 184, -156)
boutonTitre:SetSize(108, 18)
pcall(function()
    boutonTitre:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    boutonTitre:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    boutonTitre:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
local boutonTitreTxt = boutonTitre:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
boutonTitreTxt:SetPoint("CENTER")
boutonTitreTxt:SetText("|cffffd100Changer le titre|r")
boutonTitreTxt:SetShadowColor(0, 0, 0, 1)
boutonTitreTxt:SetShadowOffset(1, -1)
-- Surbrillance au survol : texture pleine taille (épouse exactement le bouton)
local boutonTitreSurbrillance = boutonTitre:CreateTexture(nil, "HIGHLIGHT")
boutonTitreSurbrillance:SetAllPoints()
boutonTitreSurbrillance:SetColorTexture(1, 0.85, 0.4, 0.35)
boutonTitre:SetHighlightTexture(boutonTitreSurbrillance)
boutonTitre:SetScript("OnClick", function()
    local courant = DB.titreFamille or "naturaliste"
    local i = 1
    for k, f in ipairs(FAMILLES_TITRES) do
        if f == courant then i = k end
    end
    DB.titreFamille = FAMILLES_TITRES[(i % #FAMILLES_TITRES) + 1]
    RaffraichirProfil()
end)
boutonTitre:SetScript("OnEnter", function(self)
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("|cffffd100Titres de chasseur|r"))
        GameTooltip:AddLine(L("Clic : famille de titre suivante"), 1, 1, 1, true)
        GameTooltip:AddLine(L("Familles : ") .. table.concat(FAMILLES_TITRES, ", "), 1, 1, 1, true)
        GameTooltip:AddLine(L("|cff8a6d3bAffiché : ") .. (DB.titreFamille or "naturaliste") .. L(" — « ") .. TitreDeFamille(DB.titreFamille or "naturaliste") .. " »|r", 1, 1, 1, true)
        GameTooltip:Show()
    end
end)
boutonTitre:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end -- fin bloc page Profil

-- ================= PAGE CUISINE =================
-- Version simplifiée du système MH : récolte en chassant (viande sur la
-- dépouille, herbe en zone de chasse, miel sur les rares), cuisine au
-- bivouac, le repas bonifie la prochaine prise. Pas de stock complexe ni
-- de buffs réels : juste de la saveur de chasseur.
-- Globales : lues par FinChasseVictoire (définie plus haut dans le fichier).
CUISINE_INGREDIENTS = {
    -- v0.121 : max = capacité du sac (à saturation, la récolte se perd :
    -- il faut cuisiner — le compteur affiche N/max, gris au plafond)
    -- v0.125 : même icône que la plaque viandes de la ménagerie (Food_17)
    viande = { nom = L("Viande de gibier"), icone = "INV_Misc_Food_17", max = 20 },
    herbe  = { nom = L("Herbe aromatique"), icone = "INV_Misc_Herb_17", max = 10 },
    miel   = { nom = L("Miel sauvage"),     icone = "INV_Misc_Food_01", max = 10 },
}
CUISINE_RECETTES = {
    roti = {
        nom = L("Rôti du chasseur"), icone = "INV_Misc_Food_16", bonus = 10,
        cout = { viande = 2 },
        desc = L("+10 points sur la prochaine prise."),
        note = L("La première recette que l'on apprend au bivouac."),
    },
    civet = {
        nom = L("Civet épicé"), icone = "INV_Misc_Food_15", bonus = 25,
        cout = { viande = 2, herbe = 1 },
        desc = L("+25 points sur la prochaine prise."),
        note = L("L'herbe aromatique réveille la viande de gibier."),
    },
    piste = {
        nom = L("Assiette du pisteur"), icone = "INV_Misc_Food_48", bonus = 40,
        cout = { viande = 3, herbe = 1 },
        desc = L("+40 points sur la prochaine prise."),
        note = L("Le plat des vieux pisteurs : tient au corps pour de longues traques."),
    },
    miel = {
        nom = L("Pain de miel du régisseur"), icone = "INV_Misc_Food_13", bonus = 50,
        cout = { viande = 1, miel = 2 },
        desc = L("+50 points sur la prochaine prise."),
        note = L("Le péché mignon du régisseur — les pensionnaires en raffolent."),
    },
    festin = {
        nom = L("Festin de légende"), icone = "INV_Misc_Food_37", bonus = 60,
        cout = { viande = 3, herbe = 2, miel = 1 },
        desc = L("+60 points sur la prochaine prise."),
        note = L("Un plat de légende, digne des plus grandes chasses."),
    },
}
-- Sources des ingrédients (tooltip de la bourse)
CUISINE_SOURCES = {
    viande = L("Récoltée sur la dépouille (40% de chance par prise)."),
    herbe  = L("Cueillette en zone de chasse (25% de chance)."),
    miel   = L("Butiné sur les rares abattus (10% de chance)."),
}
do
local cuisineFond = CreateFrame("Frame", nil, pageCuisine, MHH_TEMPLATE_BACKDROP)
cuisineFond:SetPoint("TOPLEFT", pageCuisine, "TOPLEFT", 44, -42)
-- v0.161 : RETOUR à 314, la taille standard des autres onglets
-- (retour : « l'encart gris dépasse le contour du parchemin » —
-- les attaches latérales). La place se regagne en resserrant le
-- bloc du haut SANS faire chevaucher (cf. cartouches 36 px).
cuisineFond:SetSize(552, 314)
pcall(function()
    cuisineFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    cuisineFond:SetBackdropColor(0.48, 0.38, 0.24, 0.35)
    cuisineFond:SetBackdropBorderColor(0.75, 0.60, 0.30, 0.9)
end)
local cuisineTitre = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cuisineTitre:SetPoint("TOP", cuisineFond, "TOP", 0, -10)
cuisineTitre:SetText("|cffffd100CUISINE DE CAMP|r")
local function MHH_NumJour()
    local ok, j = pcall(date, "%j")
    return (tonumber(j) or 0)
end
-- v0.160 : la CITATION du cuistot est RETIRÉE (retour : « au pire
-- tu retires la citation, à minima ça sera plus aéré ») — tout le
-- bloc bourse/repas remonte de 12 px, les rangées passent à 42 px.
-- Trait séparateur doré façon carnet MH
local function TraitCuisine(y)
    local t = pageCuisine:CreateTexture(nil, "OVERLAY")
    t:SetHeight(2)
    t:SetWidth(480)
    t:SetPoint("TOP", cuisineFond, "TOP", 0, y)
    t:SetColorTexture(0.62, 0.48, 0.22, 0.85)
end
-- ===== Bourse : cartouches icône + compteur, tooltip de source =====
local ordreIngredients = { "viande", "herbe", "miel" }
local cuisineSacLabel = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cuisineSacLabel:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 32, -30)
cuisineSacLabel:SetText(L("|cffc9a24aBourse du chasseur|r"))
local cuisineCartComptes, cuisineCartMax = {}, {}
for k, ing in ipairs(ordreIngredients) do
    local info = CUISINE_INGREDIENTS[ing]
    local cart = CreateFrame("Frame", nil, pageCuisine, MHH_TEMPLATE_BACKDROP)
    -- v0.161 : 72x44 -> 62x36 (retour : « trop larges »), icône 20 px,
    -- compteurs resserrés — tout tient dans la cartouche sans baver.
    cart:SetSize(62, 36)
    cart:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 30 + (k - 1) * 78, -42)
    pcall(function()
        cart:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        cart:SetBackdropColor(0.18, 0.14, 0.08, 0.65)
        cart:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
    end)
    local ic = cart:CreateTexture(nil, "ARTWORK")
    ic:SetSize(20, 20)
    ic:SetPoint("LEFT", cart, "LEFT", 7, 0)
    ic:SetTexture("Interface\\Icons\\" .. info.icone)
    local cpt = cart:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cpt:SetPoint("LEFT", cart, "LEFT", 33, 5)
    cpt:SetWidth(24)
    cpt:SetJustifyH("CENTER")
    cpt:SetText("|cffffd1000|r")
    local cptMax = cart:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cptMax:SetPoint("LEFT", cart, "LEFT", 33, -8)
    cptMax:SetWidth(24)
    cptMax:SetJustifyH("CENTER")
    cptMax:SetText("|cff8a6d3b/" .. (info.max or "?") .. "|r")
    cuisineCartComptes[ing] = cpt
    cuisineCartMax[ing] = cptMax
    cart:EnableMouse(true)
    cart:SetScript("OnEnter", function()
        if not GameTooltip then return end
        GameTooltip:SetOwner(cart, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffd100" .. info.nom .. "|r")
        GameTooltip:AddLine(CUISINE_SOURCES[ing], 1, 1, 1)
        local nIng = (DB and (DB[ing] or 0)) or 0
        local mx = info.max or 99
        GameTooltip:AddLine(L("En bourse : ") .. nIng .. "/" .. mx, 0.8, 0.8, 0.8)
        if nIng >= mx then
            GameTooltip:AddLine(L("Sac plein — cuisine pour libérer de la place."), 1, 0.6, 0.1)
        end
        GameTooltip:Show()
    end)
    cart:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end
-- ===== Repas préparé : panneau icône + nom + effet, à droite =====
local cuisineRepasLabel = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cuisineRepasLabel:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 292, -30)
cuisineRepasLabel:SetText(L("|cffc9a24aRepas préparé|r"))
-- v0.121 : le repas devient la 4e CASE du mini-sac (cadre assorti)
local cuisineRepasCart = CreateFrame("Frame", nil, pageCuisine, MHH_TEMPLATE_BACKDROP)
-- v0.161 : 44x44 -> 44x36 : aligné sur les cartouches de la bourse
cuisineRepasCart:SetSize(44, 36)
cuisineRepasCart:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 292, -42)
pcall(function()
    cuisineRepasCart:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    cuisineRepasCart:SetBackdropColor(0.18, 0.14, 0.08, 0.65)
    cuisineRepasCart:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
local cuisineRepasIcone = cuisineRepasCart:CreateTexture(nil, "ARTWORK")
cuisineRepasIcone:SetSize(24, 24)
cuisineRepasIcone:SetPoint("CENTER", cuisineRepasCart, "CENTER", 0, 0)
cuisineRepasCart:EnableMouse(true)
cuisineRepasCart:SetScript("OnEnter", function()
    if not GameTooltip then return end
    GameTooltip:SetOwner(cuisineRepasCart, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L("|cffc9a24aRepas préparé|r"))
    local rec = (DB and DB.repas) and CUISINE_RECETTES[DB.repas]
    if rec then
        GameTooltip:AddLine("|cffff7a1a" .. rec.nom .. "|r")
        GameTooltip:AddLine(rec.desc, 1, 0.55, 0.1)
        GameTooltip:AddLine(L("— s'appliquera à la prochaine prise."), 0.8, 0.8, 0.8)
    else
        GameTooltip:AddLine(L("Aucun — cuisinez pour bonifier la prochaine chasse."), 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
end)
cuisineRepasCart:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
local cuisineRepasNom = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cuisineRepasNom:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 344, -46)
cuisineRepasNom:SetWidth(196) -- v0.125 : 240 dépassait le bord droit du fond
cuisineRepasNom:SetJustifyH("LEFT")
local cuisineRepasEff = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
-- v0.159 : -68 -> -72 et largeur 206 : l'effet respire sous le nom
-- (retour : « texte complètement serré » quand la phrase se repliait).
cuisineRepasEff:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 344, -64)
cuisineRepasEff:SetWidth(206)
cuisineRepasEff:SetJustifyH("LEFT")
-- ===== Recettes : 5 rangées avec tooltip détaillé =====
local cuisineBoutons, cuisineCouts, cuisineNoms = {}, {}, {}
local ordreRecettes = { "roti", "civet", "piste", "miel", "festin" }
local function CoutDuJour(rec, pj)
    -- Plat du jour : coût réduit de moitié (arrondi au-dessus)
    local out = {}
    for ing, qte in pairs(rec.cout) do
        out[ing] = (pj and math.ceil(qte / 2)) or qte
    end
    return out
end
local function IndicePlatJour()
    return MHH_NumJour() % #ordreRecettes + 1
end
TraitCuisine(-80) -- v0.161 : remonte (cartouches 36 px)
-- v0.125 : le « Plat du jour » vit sur SON PROPRE bandeau (retour :
-- le ★ s'affichait « [] » dans la police du client 1.12 et son texte
-- se téléscopait avec la colonne des effets).
local cuisinePlatJour = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cuisinePlatJour:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 32, -84)
cuisinePlatJour:SetWidth(480)
cuisinePlatJour:SetJustifyH("LEFT")
-- v0.127 : LES RECETTES PASSENT EN SCROLLFRAME (retour : ça débordait
-- en bas du fond et les rangées manquaient d'air). Rangées de 44px,
-- barre de défilement à droite — prêt pour de futures recettes.
local cuisineRecettesScroll = CreateFrame("ScrollFrame", nil, pageCuisine, "UIPanelScrollFrameTemplate")
-- v0.150 : -142 -> -160 : le bandeau « Plat du jour » avalait le haut
-- de la 1re recette (retour : « un peu mangée »).
-- v0.153 : -160 -> -150 (retour : trop d'air) — le rognage du haut de
-- la 1re recette se règle par le PADDING interne du contenu, ci-dessous.
cuisineRecettesScroll:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 10, -104)
-- v0.161 : -98 -> -104 (retour : « marge légère mais PLUS GRANDE
-- entre le plat du jour et la liste ») : ~9 px d'air sous le bandeau.
cuisineRecettesScroll:SetPoint("BOTTOMRIGHT", cuisineFond, "BOTTOMRIGHT", -28, 8)
-- v0.158 : -114/-6 -> -110/-10 : la zone visible gagne 8 px et la
-- dernière rangée respire (18 px d'air sous elle au total).
local cuisineRecettesContenu = CreateFrame("Frame", nil, cuisineRecettesScroll)
-- v0.153 : hauteur RÉELLE du contenu (avant : 1 px) + 8 px de marge
-- HAUTE pour que la 1re rangée ne touche jamais le bord de découpe du
-- ScrollFrame (retour : « recette 1 rognée sur le haut »).
-- v0.161 : rangées 42 -> 38 px (retour au fond standard 314) ;
-- les 5 recettes tiennent ENTIÈRES sans scroll ni chevauchement.
cuisineRecettesContenu:SetSize(500, 6 + #ordreRecettes * 38 + 4)
cuisineRecettesScroll:SetScrollChild(cuisineRecettesContenu)
for i, rid in ipairs(ordreRecettes) do
    local r = CUISINE_RECETTES[rid]
    local y = -6 - (i - 1) * 38 -- v0.161 : rangée 38 px, fond 314
    local ic = cuisineRecettesContenu:CreateTexture(nil, "ARTWORK")
    ic:SetSize(28, 28)
    ic:SetPoint("TOPLEFT", cuisineRecettesContenu, "TOPLEFT", 10, y)
    ic:SetTexture("Interface\\Icons\\" .. r.icone)
    local n = cuisineRecettesContenu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    n:SetPoint("TOPLEFT", cuisineRecettesContenu, "TOPLEFT", 46, y + 2)
    n:SetWidth(170)
    n:SetJustifyH("LEFT")
    cuisineNoms[i] = n
    local c = cuisineRecettesContenu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c:SetPoint("TOPLEFT", cuisineRecettesContenu, "TOPLEFT", 46, y - 15)
    c:SetWidth(170)
    c:SetJustifyH("LEFT")
    cuisineCouts[i] = c
    local e = cuisineRecettesContenu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    e:SetPoint("TOPLEFT", cuisineRecettesContenu, "TOPLEFT", 222, y + 2)
    e:SetWidth(100)
    e:SetJustifyH("LEFT")
    e:SetText("|cffff7a1a" .. r.desc .. "|r")
    local b = CreateFrame("Button", nil, cuisineRecettesContenu, MHH_TEMPLATE_BACKDROP)
    b:SetSize(100, 24)
    b:SetPoint("TOPLEFT", cuisineRecettesContenu, "TOPLEFT", 330, y - 6)
    pcall(function()
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        b:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
        b:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
    end)
    local bt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bt:SetPoint("CENTER")
    bt:SetText("|cffffd100" .. L("Cuisiner") .. "|r")
    local survol = b:CreateTexture(nil, "HIGHLIGHT")
    survol:SetAllPoints()
    survol:SetColorTexture(1, 0.82, 0.35, 0.30)
    b:SetHighlightTexture(survol)
    b:SetScript("OnClick", function()
        if not DB then return end
        local rec = CUISINE_RECETTES[rid]
        local pj = (i == IndicePlatJour())
        local cout = CoutDuJour(rec, pj)
        for ing, qte in pairs(cout) do
            if (DB[ing] or 0) < qte then
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Il manque des ingrédients pour le ") .. rec.nom .. ".")
                return
            end
        end
        for ing, qte in pairs(cout) do DB[ing] = (DB[ing] or 0) - qte end
        DB.repas = rid
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffff7a1a" .. rec.nom .. L("|r préparé : ") .. rec.desc)
        if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 845) end
        MHH_RaffraichirCuisine()
    end)
    cuisineBoutons[i] = b
    -- Surface transparente capteur de survol pour le tooltip détaillé
    local surf = CreateFrame("Frame", nil, cuisineRecettesContenu)
    surf:SetWidth(320) -- ne couvre PAS le bouton Cuisiner (à x330)
    surf:SetHeight(42)
    surf:SetPoint("TOPLEFT", cuisineRecettesContenu, "TOPLEFT", 4, y)
    surf:EnableMouse(true)
    surf:SetScript("OnEnter", function()
        if not GameTooltip then return end
        GameTooltip:SetOwner(surf, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffd100" .. r.nom .. "|r")
        local pj = (i == IndicePlatJour())
        local cout = CoutDuJour(r, pj)
        for ing, qte in pairs(cout) do
            GameTooltip:AddLine(qte .. " " .. CUISINE_INGREDIENTS[ing].nom, 1, 0.82, 0.35)
        end
        if pj then
            GameTooltip:AddLine("|cffff8c00" .. L("Plat du jour — moitié prix") .. "|r", 1, 0.6, 0.2)
        end
        GameTooltip:AddLine(r.desc, 1, 0.55, 0.1)
        GameTooltip:AddLine(r.note, 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    surf:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end
cuisineRecettesContenu:SetHeight(#ordreRecettes * 46)

MHH_RaffraichirCuisine = function()
    if not DB then return end
    -- Bourse : compteurs des cartouches
    for _, ing in ipairs(ordreIngredients) do
        local nIng, mx = DB[ing] or 0, (CUISINE_INGREDIENTS[ing].max or 99)
        -- Compteur GRIS quand la case est pleine : il faut cuisiner
        cuisineCartComptes[ing]:SetText((nIng >= mx)
            and ("|cff8a8a8a" .. nIng .. "|r")
            or ("|cffffd100" .. nIng .. "|r"))
        cuisineCartMax[ing]:SetText("|cff8a6d3b/" .. mx .. "|r")
    end
    -- Repas préparé
    if DB.repas and CUISINE_RECETTES[DB.repas] then
        local rec = CUISINE_RECETTES[DB.repas]
        cuisineRepasIcone:SetTexture("Interface\\Icons\\" .. rec.icone)
        cuisineRepasNom:SetText("|cffff7a1a" .. rec.nom .. "|r")
        cuisineRepasEff:SetText(L("— s'appliquera à la prochaine prise."))
    else
        cuisineRepasIcone:SetTexture("Interface\\Icons\\" .. CUISINE_INGREDIENTS.viande.icone)
        -- v0.159 : « Aucun » seul sur sa ligne (l'ancienne phrase
        -- longue se repliait sur 3 lignes serrées dans 196 px).
        cuisineRepasNom:SetText("|cff8a6d3b" .. L("Aucun") .. "|r")
        cuisineRepasEff:SetText("|cff8a6d3b" .. L("Cuisinez pour bonifier la chasse.") .. "|r")
    end
    -- Bandeau plat du jour (v0.125)
    local pjRec = CUISINE_RECETTES[ordreRecettes[IndicePlatJour()]]
    cuisinePlatJour:SetText("|cffff8c00" .. L("Plat du jour :") .. "|r |cffffd100"
        .. pjRec.nom .. "|r |cffff8c00" .. L("(moitié prix)") .. "|r")
    -- Recettes : coût affiché (moitié si plat du jour), grisage
    for i, rid in ipairs(ordreRecettes) do
        local rec = CUISINE_RECETTES[rid]
        local pj = (i == IndicePlatJour())
        local cout = CoutDuJour(rec, pj)
        cuisineNoms[i]:SetText(pj and ("|cffff8c00" .. rec.nom .. "|r")
            or ("|cffffd100" .. rec.nom .. "|r"))
        local coutsTxt, ok = {}, true
        for ing, qte in pairs(cout) do
            coutsTxt[#coutsTxt + 1] = qte .. " " .. CUISINE_INGREDIENTS[ing].nom
            if (DB[ing] or 0) < qte then ok = false end
        end
        cuisineCouts[i]:SetText(L("|cffc9a24aIngrédients :|r ") .. table.concat(coutsTxt, ", "))
        if ok then
            cuisineBoutons[i]:Enable()
            pcall(function()
                cuisineBoutons[i]:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
                cuisineBoutons[i]:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
            end)
        else
            cuisineBoutons[i]:Disable()
            pcall(function()
                cuisineBoutons[i]:SetBackdropColor(0.15, 0.13, 0.10, 0.75)
                cuisineBoutons[i]:SetBackdropBorderColor(0.30, 0.28, 0.25, 0.8)
            end)
        end
    end
end
end

-- ================= PAGE OPTIONS =================
-- Panneau de réglages du carnet : tout ce qui se règle en /hunt devient
-- cliquable. Les commandes slash restent disponibles (raccourcis).
do
local optionsFond = CreateFrame("Frame", nil, pageOptions, MHH_TEMPLATE_BACKDROP)
optionsFond:SetPoint("TOPLEFT", pageOptions, "TOPLEFT", 44, -42)
optionsFond:SetSize(552, 314)
pcall(function()
    optionsFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    optionsFond:SetBackdropColor(0.48, 0.38, 0.24, 0.35)
    optionsFond:SetBackdropBorderColor(0.75, 0.60, 0.30, 0.9)
end)
local optionsTitre = pageOptions:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
optionsTitre:SetPoint("TOP", optionsFond, "TOP", 0, -12)
optionsTitre:SetText(L("|cffffd100RÉGLAGES DU CHASSEUR|r"))
local optionsBoutonsTxt = {}
local OPTIONS_DEF = {
    { cle = "banniere",   label = L("Bannières de chasse"),   type = "bool" },
    { cle = "son",        label = L("Sons de l'addon"),         type = "bool" },
    { cle = "killSouple", label = L("Comptage des prises"),  type = "bool",
      labels = { "strict (kill final)", "souple (participation)" } },
    { cle = "texUI",      label = L("Textures du carnet"),   type = "cycle", valeurs = { "wow", "custom" } },
    { cle = "musique",    label = "Musiques",             type = "cycle", valeurs = { "off", "wow", "custom" } },
    { cle = "chronoMode", label = L("Chrono de chasse"),     type = "cycle", valeurs = { "full", "minimap", "off" } },
}
for i, def in ipairs(OPTIONS_DEF) do
    local y = -60 - (i - 1) * 34
    local l = pageOptions:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    l:SetPoint("TOPLEFT", optionsFond, "TOPLEFT", 40, y - 4)
    l:SetText("|cffc9a24a" .. def.label .. "|r")
    local b = CreateFrame("Button", nil, pageOptions, MHH_TEMPLATE_BACKDROP)
    b:SetSize(170, 22)
    b:SetPoint("TOPLEFT", optionsFond, "TOPLEFT", 300, y + 2)
    pcall(function()
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        b:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
        b:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
    end)
    local bt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bt:SetPoint("CENTER")
    optionsBoutonsTxt[i] = bt
    b:SetScript("OnClick", function()
        if not DB then return end
        if def.type == "bool" then
            DB.config[def.cle] = not DB.config[def.cle]
        else
            local cur = DB.config[def.cle] or def.valeurs[1]
            local idx = 1
            for k, v in ipairs(def.valeurs) do if v == cur then idx = k end end
            DB.config[def.cle] = def.valeurs[(idx % #def.valeurs) + 1]
        end
        if def.cle == "texUI" and AppliquerTexUI then AppliquerTexUI() end
        if def.cle == "musique" then MHH_ArreterMusique() end
        if def.cle == "chronoMode" and chasseActive then MettreAJourIndicateur() end
        MHH_RaffraichirOptions()
    end)
end
local optionsNote = pageOptions:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
optionsNote:SetPoint("BOTTOMLEFT", optionsFond, "BOTTOMLEFT", 40, 16)
optionsNote:SetWidth(480)
optionsNote:SetJustifyH("LEFT")
optionsNote:SetText(L("|cff8a6d3bLes commandes /hunt restent valables — le carnet n'est qu'un raccourci confortable.|r"))

MHH_RaffraichirOptions = function()
    if not DB then return end
    for i, def in ipairs(OPTIONS_DEF) do
        local v = DB.config[def.cle]
        local txt
        if def.type == "bool" then
            if def.labels then
                txt = "|cffffd100" .. (v and def.labels[2] or def.labels[1]) .. "|r"
            else
                txt = v and L("|cffa0ff50Activé|r") or L("|cffd87a6aDésactivé|r")
            end
        else
            txt = "|cffffd100" .. tostring(v) .. "|r"
        end
        optionsBoutonsTxt[i]:SetText(txt)
    end
end
end

-- ================= GESTION DES ONGLETS =================
-- ================= PAGE MÉNAGERIE : EXTRAITE =================
-- v0.67 : la page Ménagerie (enclos, pensionnaires, régisseur,
-- bâtiments, météo, boucle d'anim) vit dans Menagerie.lua,
-- chargé APRÈS ce fichier (voir .toc). Ponts : MHH_L, MHH_Carnet,
-- MHH_MeteoActuelle (fin de ce fichier), MHH_DB (ADDON_LOADED),
-- MHH_pageMenagerie (Menagerie.lua). RaffraichirMenagerie et
-- ArreterMenagerieGlobal restent des globales — rien à changer
-- dans les événements de ce fichier.


function AfficherOnglet(id)
    pageAccueil:SetShown(id == "accueil")
    pageMonstres:SetShown(id == "monstres")
    pageSucces:SetShown(id == "succes")
    pageProfil:SetShown(id == "profil")
    pageContrats:SetShown(id == "contrats")
    pageCuisine:SetShown(id == "cuisine")
    pageMissions:SetShown(id == "missions")
    MHH_pageMenagerie:SetShown(id == "menagerie")
    pageOptions:SetShown(id == "options")
    for oid, b in pairs(onglets) do
        if oid == id then
            b.fondTexture:SetColorTexture(0.78, 0.62, 0.25, 1)
            if b.SetBackdropBorderColor then pcall(b.SetBackdropBorderColor, b, 0.9, 0.75, 0.35, 1) end
            b:ClearAllPoints()
            b:SetPoint("TOPRIGHT", carnet, "TOPLEFT", 8, -b.decalageY)
        else
            b.fondTexture:SetColorTexture(0.42, 0.35, 0.20, 0.9)
            if b.SetBackdropBorderColor then pcall(b.SetBackdropBorderColor, b, 0.45, 0.36, 0.2, 0.9) end
            b:ClearAllPoints()
            b:SetPoint("TOPRIGHT", carnet, "TOPLEFT", 2, -b.decalageY)
        end
    end
    if id == "accueil" then RaffraichirAccueil()
    elseif id == "monstres" then RaffraichirCarnet()
    elseif id == "contrats" then RaffraichirContrats()
    elseif id == "succes" then RaffraichirSucces()
    elseif id == "profil" then RaffraichirProfil()
    elseif id == "cuisine" then MHH_RaffraichirCuisine()
    elseif id == "missions" then MHH_RaffraichirMissions()
    elseif id == "menagerie" then RaffraichirMenagerie()
    elseif id == "options" then MHH_RaffraichirOptions() end
end

CreerOnglet("accueil", L("tab_accueil"), 56, "INV_Misc_Note_01")
CreerOnglet("profil", L("tab_profil"), 84, "INV_Misc_Book_09")
CreerOnglet("monstres", L("tab_monstres"), 112, "INV_Misc_MonsterClaw_04")
CreerOnglet("contrats", L("tab_contrats"), 140, "INV_Misc_Coin_01")
CreerOnglet("missions", L("tab_missions"), 168, "INV_Scroll_03")
CreerOnglet("succes", L("tab_succes"), 196, "INV_Misc_Gem_01")
CreerOnglet("cuisine", L("tab_cuisine"), 224, "INV_Misc_Food_16")
CreerOnglet("menagerie", L("tab_menagerie"), 252, "Ability_Hunter_BeastTaming")
CreerOnglet("options", L("tab_options"), 280, "INV_Misc_Wrench_01")

-- ================= TUTO DE BIENVENUE =================
-- Panneau « Bonne chasse, {nom} ! » : 4 repères de vieux chasseur par-dessus
-- le carnet, façon écran d'accueil MH. Case « Ne plus afficher » (mémorisée
-- dans DB.tutoPanVu) ; ré-affichable à tout moment avec /hunt tuto.
MHH_tutoPan = CreateFrame("Frame", nil, carnet)
MHH_tutoPan:SetAllPoints()
MHH_tutoPan:SetFrameStrata("HIGH")
MHH_tutoPan:SetFrameLevel(20)
MHH_tutoPan:EnableMouse(true)
MHH_tutoFond = MHH_tutoPan:CreateTexture(nil, "BACKGROUND")
MHH_tutoFond:SetAllPoints()
MHH_tutoFond:SetColorTexture(0.02, 0.01, 0.01, 0.80)
MHH_tutoCadre = CreateFrame("Frame", nil, MHH_tutoPan, MHH_TEMPLATE_BACKDROP)
MHH_tutoCadre:SetSize(480, 308)
MHH_tutoCadre:SetPoint("CENTER")
pcall(function()
    MHH_tutoCadre:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    MHH_tutoCadre:SetBackdropColor(0.06, 0.04, 0.02, 0.97)
    MHH_tutoCadre:SetBackdropBorderColor(0.78, 0.62, 0.25, 1)
end)
MHH_tutoTitre = MHH_tutoCadre:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
MHH_tutoTitre:SetPoint("TOP", MHH_tutoCadre, "TOP", 0, -18)
MHH_tutoTitre:SetText(L("|cffffd100BONNE CHASSE !|r"))
MHH_tutoSoustitre = MHH_tutoCadre:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_tutoSoustitre:SetPoint("TOP", MHH_tutoCadre, "TOP", 0, -42)
MHH_tutoSoustitre:SetText(L("|cffa58b54Le carnet du chasseur : quatre repères de vieux chasseur|r"))
MHH_TUTO_REPERES = {
    { "Interface\\Icons\\INV_Misc_MonsterClaw_04",
      L("|cffffd100Gibier|r : fiches, menace, gabarit, sensibilités. Cliquez une bête pour ouvrir sa fiche et la chasser.") },
    { "Interface\\Icons\\INV_Misc_Coin_01",
      L("|cffffd100Contrats|r : la cible du jour vaut une prime de +20 points. Prendre une mission engage la traque.") },
    { "Interface\\Icons\\INV_Misc_Food_16",
      L("|cffffd100Cuisine|r : viande sur les prises, herbes en zone de chasse, miel sur les rares ; un repas bonifie la prise suivante.") },
    { "Interface\\Icons\\INV_Weapon_Bow_01",
      L("|cffffd100Chasse|r : visez la bête en jeu pour engager EN CHASSE, un duel chronométré. Chaque prise rapporte des points pour faire progresser votre rang de chasseur.") },
}
for i, rep in ipairs(MHH_TUTO_REPERES) do
    local y = -68 - (i - 1) * 48
    local ic = MHH_tutoCadre:CreateTexture(nil, "ARTWORK")
    ic:SetSize(26, 26)
    ic:SetPoint("TOPLEFT", MHH_tutoCadre, "TOPLEFT", 30, y + 2)
    ic:SetTexture(rep[1])
    local t = MHH_tutoCadre:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT", MHH_tutoCadre, "TOPLEFT", 68, y + 8)
    t:SetPoint("RIGHT", MHH_tutoCadre, "RIGHT", -30, 0)
    t:SetJustifyH("LEFT")
    t:SetShadowColor(0, 0, 0, 1)
    t:SetShadowOffset(1, -1)
    t:SetText(rep[2])
end
MHH_tutoCoche = CreateFrame("CheckButton", nil, MHH_tutoCadre, "UICheckButtonTemplate")
MHH_tutoCoche:SetSize(24, 24)
MHH_tutoCoche:SetPoint("BOTTOMLEFT", MHH_tutoCadre, "BOTTOMLEFT", 24, 16)
pcall(function() MHH_tutoCoche:SetChecked(false) end)
MHH_tutoCocheTxt = MHH_tutoCadre:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_tutoCocheTxt:SetPoint("LEFT", MHH_tutoCoche, "RIGHT", 6, 0)
MHH_tutoCocheTxt:SetText("|cffa58b54Ne plus afficher|r")
MHH_tutoCocheTxt:SetShadowColor(0, 0, 0, 1)
MHH_tutoCocheTxt:SetShadowOffset(1, -1)
-- Forward : le serment (défini plus bas) s'affiche après « Compris ! »
-- (déjà déclaré en tête de fichier : forward pour le tuto ci-dessous)
MHH_tutoBouton = CreateFrame("Button", nil, MHH_tutoCadre, MHH_TEMPLATE_BACKDROP)
MHH_tutoBouton:SetSize(150, 26)
MHH_tutoBouton:SetPoint("BOTTOM", MHH_tutoCadre, "BOTTOM", 15, 16)
MHH_tutoBouton:SetText(L("Compris !"))
MHH_tutoBouton:SetNormalFontObject("GameFontHighlight")
pcall(function()
    MHH_tutoBouton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    MHH_tutoBouton:SetBackdropColor(0.30, 0.22, 0.10, 0.85)
    MHH_tutoBouton:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
local function MontrerTuto()
    -- Nom du chasseur : lu à l'affichage (fiable sur tous les clients,
    -- UnitName peut être vide au chargement du fichier)
    MHH_tutoTitre:SetText(L("|cffffd100BONNE CHASSE, ")
        .. string.upper((UnitName("player") or "") ~= "" and UnitName("player") or "CHASSEUR") .. " !|r")
    pcall(function() MHH_tutoCoche:SetChecked(false) end)
    MHH_tutoPan:Show()
end
MHH_tutoBouton:SetScript("OnClick", function()
    MHH_tutoPan:Hide()
    if DB and MHH_tutoCoche:GetChecked() then DB.tutoPanVu = true end
    if DB and DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 845) end
    -- Le serment suit la bienvenue (première fois OU relecture /hunt tuto)
    if DB and MHH_sermentPan then MHH_MontrerSerment() end
end)
MHH_tutoPan:SetScript("OnHide", function()
    if DB and MHH_tutoCoche:GetChecked() then DB.tutoPanVu = true end
end)
MHH_tutoPan:Hide()

-- Limite 200 locales : la section serment vit dans son bloc do (ses
-- ~10 locales se libèrent à la fin du bloc)
do
-- SECOND PANNEAU DU TUTO : « LE SERMENT DU CHASSEUR » — le choix de
-- la voie (kill souple/strict) avec flaveur MH. Apparaît après le
-- panneau de bienvenue à la première ouverture du carnet ; revisible
-- via /hunt tuto. Modifiable ensuite par /hunt kill loose/strict.
MHH_sermentPan = CreateFrame("Frame", nil, carnet)
MHH_sermentPan:SetAllPoints()
MHH_sermentPan:SetFrameStrata("HIGH")
MHH_sermentPan:SetFrameLevel(21)
MHH_sermentPan:EnableMouse(true)
local sermentFond = MHH_sermentPan:CreateTexture(nil, "BACKGROUND")
sermentFond:SetAllPoints()
sermentFond:SetColorTexture(0.02, 0.01, 0.01, 0.80)
local sermentCadre = CreateFrame("Frame", nil, MHH_sermentPan, MHH_TEMPLATE_BACKDROP)
sermentCadre:SetSize(480, 308)
sermentCadre:SetPoint("CENTER")
pcall(function()
    sermentCadre:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    sermentCadre:SetBackdropColor(0.06, 0.04, 0.02, 0.97)
    sermentCadre:SetBackdropBorderColor(0.78, 0.62, 0.25, 1)
end)
local sermentTitre = sermentCadre:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
sermentTitre:SetPoint("TOP", sermentCadre, "TOP", 0, -18)
sermentTitre:SetText(L("|cffffd100LE SERMENT DU CHASSEUR|r"))
local sermentSous = sermentCadre:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sermentSous:SetPoint("TOP", sermentCadre, "TOP", 0, -44)
sermentSous:SetText(L("|cffa58b54Chaque prise validée demande un choix : comment comptent vos trophées ?|r"))
sermentSous:SetShadowColor(0, 0, 0, 1)
sermentSous:SetShadowOffset(1, -1)
-- Les deux voies : participation (souple) ou coup de grâce (strict).
-- Chaque plaque : icône + nom + flaveur (citation) + implications.
local MHH_SERMENTS = {
    {
        souple = true,
        icone = "Interface\\Icons\\INV_Weapon_Bow_01",
        nom = L("|cffff8844La voie du compagnon|r — chasse souple"),
        flaveur = L("« Le gibier est tombé sous les crocs de la meute — et la meute, c'était vous. »"),
        implique = L("|cffc9a24aImplique :|r participer au combat suffit (dégâts ou soins apportés), même sans porter le coup fatal. Idéal en groupe."),
    },
    {
        souple = false,
        icone = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
        nom = L("|cff66ccffLa voie du loup solitaire|r — chasse stricte"),
        flaveur = L("« La traque se termine par VOTRE lame, ou elle ne compte pas. »"),
        implique = L("|cffc9a24aImplique :|r seul votre coup de grâce valide la prise. En groupe, la bête doit mourir sous votre main. Pour chasseurs exigeants."),
    },
}
local sermentPlaques = {}
local sermentChoix = nil -- voie sélectionnée (avant validation)
local MaJVoiesSerment = function() end -- forward : définie après le loop
for i, s in ipairs(MHH_SERMENTS) do
    local p = CreateFrame("Button", nil, sermentCadre, MHH_TEMPLATE_BACKDROP)
    p:SetSize(216, 158)
    p:SetPoint("TOPLEFT", sermentCadre, "TOPLEFT", 22 + (i - 1) * 224, -62)
    p:SetNormalFontObject("GameFontHighlight")
    pcall(function()
        p:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        p:SetBackdropColor(0.08, 0.05, 0.02, 0.95)
    end)
    local ic = p:CreateTexture(nil, "ARTWORK")
    ic:SetSize(30, 30)
    ic:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -10)
    ic:SetTexture(s.icone)
    local nom = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nom:SetPoint("TOPLEFT", p, "TOPLEFT", 48, -14)
    nom:SetPoint("RIGHT", p, "RIGHT", -8, 0)
    nom:SetJustifyH("LEFT")
    nom:SetText(s.nom)
    nom:SetShadowColor(0, 0, 0, 1)
    nom:SetShadowOffset(1, -1)
    local flv = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    flv:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -48)
    flv:SetPoint("RIGHT", p, "RIGHT", -10, 0)
    flv:SetJustifyH("LEFT")
    flv:SetHeight(34)
    flv:SetText(s.flaveur)
    flv:SetTextColor(0.65, 0.55, 0.38)
    flv:SetShadowColor(0, 0, 0, 1)
    flv:SetShadowOffset(1, -1)
    local imp = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    imp:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -88)
    imp:SetPoint("RIGHT", p, "RIGHT", -10, 0)
    imp:SetPoint("BOTTOM", p, "BOTTOM", 0, 10)
    imp:SetJustifyH("LEFT")
    imp:SetText(s.implique)
    imp:SetTextColor(0.82, 0.74, 0.60)
    imp:SetShadowColor(0, 0, 0, 1)
    imp:SetShadowOffset(1, -1)
    local badge = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badge:SetPoint("BOTTOM", p, "BOTTOM", 0, -18)
    badge:SetText(L("|cff88ff88• Votre voie actuelle|r"))
    badge:SetShadowColor(0, 0, 0, 1)
    badge:SetShadowOffset(1, -1)
    -- v0.62 : cliquer une plaque ne valide PLUS direct — ça la
    -- SÉLECTIONNE (liseré doré), et le bouton « Valider » en bas
    -- confirme (retour de test : validation involontaire trop facile)
    p:SetScript("OnClick", function()
        sermentChoix = s.souple
        if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
        MaJVoiesSerment()
    end)
    sermentPlaques[i] = { p = p, badge = badge, souple = s.souple }
end
-- Rafraîchit les liserés : plaque sélectionnée = or vif, voie
-- actuelle = or moyen, le reste = grisonné
MaJVoiesSerment = function()
    for _, pl in ipairs(sermentPlaques) do
        local etat
        if sermentChoix ~= nil and sermentChoix == pl.souple then
            etat = "choix"
        elseif sermentChoix == nil and DB and DB.config.killSouple == pl.souple then
            -- Or moyen UNIQUEMENT hors sélection : dès qu'on choisit,
            -- la non-sélection passe sombre (retour de test : le liseré
            -- « voie actuelle » restait trop clair à côté du choix)
            etat = "actuel"
        else
            etat = "off"
        end
        pcall(function()
            if etat == "choix" then
                pl.p:SetBackdropBorderColor(1, 0.84, 0.35, 1)
            elseif etat == "actuel" then
                pl.p:SetBackdropBorderColor(0.78, 0.62, 0.25, 1)
            else
                pl.p:SetBackdropBorderColor(0.16, 0.12, 0.06, 0.9)
            end
        end)
        -- Badge : suit la SÉLECTION (prévisualisation du serment) ; tant
        -- qu'on n'a rien cliqué, il marque la config en vigueur
        pl.badge:SetShown(etat == "choix" or etat == "actuel")
    end
end
local sermentNote = sermentCadre:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sermentNote:SetPoint("BOTTOM", sermentCadre, "BOTTOM", 0, 42)
sermentNote:SetText(L("|cffa58b54La voie se change à tout moment : |cffffd100/hunt kill loose/strict|r"))
sermentNote:SetShadowColor(0, 0, 0, 1)
sermentNote:SetShadowOffset(1, -1)
-- BOUTON VALIDER : applique la voie sélectionnée (sélection → validation)
local sermentValider = CreateFrame("Button", nil, sermentCadre, MHH_TEMPLATE_BACKDROP)
sermentValider:SetSize(150, 26)
sermentValider:SetPoint("BOTTOM", sermentCadre, "BOTTOM", -70, 12)
sermentValider:SetText(L("Prononcer le serment !"))
sermentValider:SetNormalFontObject("GameFontHighlight")
pcall(function()
    sermentValider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    sermentValider:SetBackdropColor(0.30, 0.22, 0.10, 0.85)
    sermentValider:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
sermentValider:SetScript("OnClick", function()
    if sermentChoix == nil then
        -- Aucune voie sélectionnée : on le dit, pas de fermeture sauvage
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Choisissez d'abord une voie pour prononcer le serment."))
        return
    end
    DB.config.killSouple = sermentChoix
    DB.sermentVu = true
    MHH_sermentPan:Hide()
    if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 845) end
    if sermentChoix then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Serment prononcé : |cffff8844la voie du compagnon|r (chasse souple — la participation compte)."))
    else
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Serment prononcé : |cff66ccffla voie du loup solitaire|r (chasse stricte — votre coup de grâce, et rien d'autre)."))
    end
end)
local sermentFermer = CreateFrame("Button", nil, sermentCadre, MHH_TEMPLATE_BACKDROP)
sermentFermer:SetSize(110, 24)
sermentFermer:SetPoint("BOTTOM", sermentCadre, "BOTTOM", 80, 13)
sermentFermer:SetText(L("Plus tard"))
sermentFermer:SetNormalFontObject("GameFontHighlight")
pcall(function()
    sermentFermer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    sermentFermer:SetBackdropColor(0.30, 0.22, 0.10, 0.85)
    sermentFermer:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
sermentFermer:SetScript("OnClick", function()
    DB.sermentVu = true
    MHH_sermentPan:Hide()
end)
MHH_MontrerSerment = function()
    -- Sélection vidée ; badges et liserés gérés par MaJVoiesSerment
    sermentChoix = nil
    MaJVoiesSerment()
    MHH_sermentPan:Show()
end
MHH_sermentPan:Hide()
end -- fin du bloc serment (libère ses locales)

-- INDICE PULSANT « Ton gibier t'attend ici » RETIRÉ : le tuto de
-- bienvenue guide déjà le chasseur à la première ouverture — la
-- flèche d'objectif devenait un doublon.

-- Son à l'ouverture/fermeture du carnet (SFX du jeu, style journal)
carnet:SetScript("OnShow", function()
    if DB and DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 845) end
    -- Tuto de bienvenue : panneau « Bonne chasse » à la première ouverture
    -- (case « Ne plus afficher » ; /hunt tuto pour le faire revenir),
    -- puis le serment du chasseur (voies souple/stricte) s'il n'a
    -- jamais été prononcé
    if DB and not DB.tutoPanVu and MHH_tutoPan then
        MontrerTuto()
    elseif DB and not DB.sermentVu and MHH_sermentPan then
        MHH_MontrerSerment()
    end
    AfficherOnglet("accueil")
end)
carnet:SetScript("OnHide", function()
    if DB and DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_CLOSE or 844) end
    -- Les encarts volants suivent : la fermeture du carnet doit tout
    -- emporter (sinon l'enclos/histogramme restaient à l'écran).
    if ArreterMenagerieGlobal then ArreterMenagerieGlobal() end
    if MHH_armesPan then MHH_armesPan:Hide() end
end)
-- 7. BOUTON MINIMAP (menu du carnet)
--    Texture tolérante : carnet.tga si dispo, sinon icône WoW
-- ============================================
local bouton = CreateFrame("Button", "LaChasseBouton", Minimap)
bouton:SetSize(31, 31)
bouton:SetFrameStrata("MEDIUM")
-- Position : à droite de la minimap par défaut, déplaçable au drag (mémorisée)
-- NB : au chargement du fichier, DB n'est pas encore peuplé — on lit la base brute
bouton:SetPoint("CENTER", Minimap, "CENTER",
    (LaChasseDB and LaChasseDB.boutonX) or 78,
    (LaChasseDB and LaChasseDB.boutonY) or -16)
bouton:SetMovable(true)
bouton:RegisterForClicks("AnyUp")
bouton:RegisterForDrag("LeftButton")
bouton:SetScript("OnDragStart", function(self) self:StartMoving() end)
bouton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter()
    local mx, my = Minimap:GetCenter()
    DB.boutonX = cx - mx
    DB.boutonY = cy - my
end)
local boutonIcone = bouton:CreateTexture(nil, "BACKGROUND")
if TextureCustomActive("icone") then
    boutonIcone:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\carnet.tga")
else
    boutonIcone:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
end
-- L'icône remplit le bouton ; léger décalage vertical pour compenser
-- le dessin du livre dans carnet.tga, et rognage des bords de la texture
-- (élimine les artefacts de coin, ex. point jaune en haut à gauche)
boutonIcone:SetSize(30, 30)
-- Décalage +2 uniquement pour l'icône du livre WoW (dessin excentré dans la
-- texture) ; avec la texture custom (pattoune, parfaitement centrée), on reste
-- centré — sinon le cercle de bordure paraît désaxé par rapport à l'icône
boutonIcone:SetPoint("CENTER", 0, TextureCustomActive("icone") and 0 or 2)
boutonIcone:SetTexCoord(0.07, 0.93, 0.07, 0.93)

-- Application des textures selon la config (appelé sur ADDON_LOADED,
-- quand la base est garantie prête — fiable sur tous les clients)
local boutonBordure -- déclaré ici : utilisé par AppliquerTextures ci-dessous
AppliquerTextures = function()
    -- Position mémorisée de l'icône minimap : réappliquée une fois la base
    -- prête (garde-fou : certains flux révoquer/contrat tombaient dessus).
    if DB.boutonX or DB.boutonY then
        bouton:ClearAllPoints()
        bouton:SetPoint("CENTER", Minimap, "CENTER",
            DB.boutonX or 78, DB.boutonY or -16)
    end
    if not DB then return end
    if DB.config.fond == "custom" then
        carnetFond:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\fond.tga")
    else
        carnetFond:SetColorTexture(0.18, 0.13, 0.07, 0.95)
    end
    if DB.config.icone == "custom" then
        boutonIcone:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\carnet.tga")
        boutonIcone:SetPoint("CENTER", 0, 0)
        boutonBordure:Hide() -- pas de cercle doré sur l'icône custom
    else
        boutonIcone:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
        boutonIcone:SetPoint("CENTER", 0, 2)
        boutonBordure:Show()
    end
end
boutonBordure = bouton:CreateTexture(nil, "OVERLAY")
boutonBordure:SetSize(33, 33)
boutonBordure:SetPoint("TOPLEFT", bouton, "TOPLEFT", -1, 1)
boutonBordure:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
-- Surbrillance : texture créée manuellement et étirée sur tout le bouton
-- (SetHighlightTexture(chemin) laisse la texture à sa taille native, 64x64
-- pour UI-Quickslot2 → surbrillance décalée sur un bouton 31x31)
local boutonSurbrillance = bouton:CreateTexture(nil)
boutonSurbrillance:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
boutonSurbrillance:SetBlendMode("ADD")
boutonSurbrillance:SetTexCoord(0.1, 0.9, 0.1, 0.9)
boutonSurbrillance:SetAllPoints(bouton)
bouton:SetHighlightTexture(boutonSurbrillance)
bouton:SetScript("OnClick", function(self, btn)
    if btn == "RightButton" then
        OuvrirCarnet("succes")
    else
        if carnet:IsShown() then
            carnet:Hide()
        else
            -- Le carnet s'ouvre sur l'Accueil (vue d'ensemble du chasseur)
            OuvrirCarnet("accueil")
        end
    end
end)
bouton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cffffd100MH Hunt|r")
    GameTooltip:AddLine(L("Clic gauche : Carnet de chasse"))
    GameTooltip:AddLine(L("Clic droit : Succès"))
    GameTooltip:AddLine(nbChasses() .. (nbChasses() == 1 and L(" chasse réussie.") or L(" chasses réussies.")))
    GameTooltip:Show()
end)
bouton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Indicateur « EN CHASSE ! » : petit bandeau sous le bouton minimap,
-- visible même carnet fermé, suit le bouton quand il est déplacé.
-- Frame top-level (UIParent) en strate HIGH : rien ne peut la recouvrir,
-- y compris la minimap ou le cluster autour.
local indicateurChasse = CreateFrame("Frame", nil, UIParent)
indicateurChasse:SetSize(160, 20)
indicateurChasse:SetPoint("TOP", bouton, "BOTTOM", 0, 2)
indicateurChasse:SetFrameStrata("HIGH")
pcall(function()
    indicateurChasse:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    indicateurChasse:SetBackdropColor(0.05, 0.03, 0.01, 0.30)
    indicateurChasse:SetBackdropBorderColor(0.85, 0.35, 0.15, 0.45)
end)
-- Fond sombre : ColorTexture translucide, puis dégradé si dispo
local indicateurDegrad = indicateurChasse:CreateTexture(nil, "BACKGROUND")
indicateurDegrad:SetAllPoints()
indicateurDegrad:SetColorTexture(0.03, 0.02, 0.01, 0.50)
pcall(function()
    indicateurDegrad:SetGradientAlpha("VERTICAL",
        0.02, 0.02, 0.01, 0.65,  -- haut : sombre (lisibilité du libellé)
        0.06, 0.04, 0.02, 0.20)  -- bas : presque transparent
end)
local indicateurChasseTxt = indicateurChasse:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
indicateurChasseTxt:SetPoint("CENTER")
indicateurChasseTxt:SetText(L("|cffff7a1aEN CHASSE !|r"))
indicateurChasseTxt:SetShadowColor(0, 0, 0, 1)
indicateurChasseTxt:SetShadowOffset(1, -1)
indicateurChasse:Hide()
-- Fond WoW (bordure + dégradé) : remis en mode texte, retiré en mode custom
-- pour que la transparence de bandeau.tga respire sur le décor du jeu.
local function IndicateurFondWoW(actif)
    if actif then
        pcall(function()
            indicateurChasse:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
            indicateurChasse:SetBackdropColor(0.05, 0.03, 0.01, 0.30)
            indicateurChasse:SetBackdropBorderColor(0.85, 0.35, 0.15, 0.45)
        end)
        indicateurDegrad:Show()
    else
        pcall(function() indicateurChasse:SetBackdrop(nil) end)
        indicateurDegrad:Hide()
    end
end
-- Chrono de chasse : bandeau discret en haut de l'écran pendant la traque,
-- avec le record personnel du monstre chassé (demain : texture « En chasse ! »)
MHH_chronoChasse = CreateFrame("Frame", nil, UIParent)
-- 282x124 : chrono.tga rognée de 12 % de chaque côté (les ornements
-- latéraux mangeaient la moitié de l'encart) — ratio du cœur conservé
MHH_chronoChasse:SetSize(282, 124)
MHH_chronoChasse:SetPoint("TOP", UIParent, "TOP", 0, -32)
MHH_chronoChasse:SetFrameStrata("HIGH")
pcall(function()
    MHH_chronoChasse:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    MHH_chronoChasse:SetBackdropColor(0.05, 0.03, 0.01, 0.85)
    MHH_chronoChasse:SetBackdropBorderColor(0.85, 0.35, 0.15, 0.9)
end)
-- Deux FontStrings séparées : seul le titre du monstre est gras avec
-- contour ; la ligne temps/record reste discrète. Les deux sont calées
-- dans la zone PARCHemin de chrono.tga (cœur de l'image), loin des bords.
MHH_chronoChasseTitre = MHH_chronoChasse:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
MHH_chronoChasseTitre:SetPoint("TOP", 0, -34)
MHH_chronoChasseTitre:SetWidth(258)
MHH_chronoChasseTitre:SetShadowColor(0, 0, 0, 1)
MHH_chronoChasseTitre:SetShadowOffset(1, -1)
pcall(function() MHH_chronoChasseTitre:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE") end)
MHH_chronoChasseTxt = MHH_chronoChasse:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MHH_chronoChasseTxt:SetPoint("TOP", 0, -66)
MHH_chronoChasseTxt:SetWidth(258)
MHH_chronoChasseTxt:SetShadowColor(0, 0, 0, 1)
MHH_chronoChasseTxt:SetShadowOffset(1, -1)
pcall(function() MHH_chronoChasseTxt:SetFont("Fonts\\FRIZQT__.TTF", 15) end)
MHH_chronoChasse:Hide()

-- Chrono MINIATURE près du bouton minimap (/hunt chrono minimap) :
-- seulement temps + record, sur une chrono.tga réduite (ou fond sobre
-- en mode texte). Pour qui veut le chrono discret sans le grand encart.
-- Chrono MINIATURE au-dessus du bouton minimap (/hunt chrono minimap) :
-- seulement temps + record, sur une chrono.tga réduite (ou fond sobre
-- en mode texte). Placé AU-DESSUS du bouton : hors de la zone de clic et
-- ne recouvre ni le rappel de contrat ni l'indicateur.
MHH_chronoMini = CreateFrame("Frame", nil, UIParent)
MHH_chronoMini:SetSize(150, 50) -- chrono.tga réduit au ratio 3:1
MHH_chronoMini:SetPoint("BOTTOM", bouton, "TOP", 0, 10)
MHH_chronoMini:SetFrameStrata("HIGH")
pcall(function()
    MHH_chronoMini:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    MHH_chronoMini:SetBackdropColor(0.05, 0.03, 0.01, 0.85)
    MHH_chronoMini:SetBackdropBorderColor(0.85, 0.35, 0.15, 0.9)
end)
MHH_chronoMiniFond = MHH_chronoMini:CreateTexture(nil, "ARTWORK")
MHH_chronoMiniFond:SetAllPoints()
MHH_chronoMiniFond:Hide()
MHH_chronoMiniTxt = MHH_chronoMini:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MHH_chronoMiniTxt:SetPoint("CENTER", 0, 0)
MHH_chronoMiniTxt:SetShadowColor(0, 0, 0, 1)
MHH_chronoMiniTxt:SetShadowOffset(1, -1)
MHH_chronoMini:Hide()
MHH_tickerChrono = nil
local function FormatDuree(d)
    return math.floor(d / 60) .. ":" .. string.format("%02d", d % 60)
end
local function RafraichirChrono()
    if not chasseActive then return end
    -- Filet de sécurité : si le journal de combat n'a rien validé mais que
    -- la bête chassée est morte sous le viseur, la prise est validée quand
    -- même (certaines bêtes « meurent muettes » sur certains clients)
    if UnitExists("target") and (UnitName("target") or "") == chasseActive then
        local okMort, mort = pcall(function() return UnitIsDead("target") end)
        if okMort and mort then
            DebugChasse("chrono", chasseActive .. L(" mort sous le viseur"))
            local nomPrise = chasseActive
            C_Timer.After(0, function()
                if chasseActive == nomPrise then FinChasseVictoire(nomPrise) end
            end)
            return
        end
    end
    local d = chasseDebutTemps and (time() - chasseDebutTemps) or 0
    local info = DB.chasses[chasseActive]
    MHH_chronoChasseTitre:SetText("|cffffd100" .. chasseActive .. "|r")
    MHH_chronoChasseTxt:SetText("|cffff7a1a" .. FormatDuree(d) .. "|r"
        .. (info and info.recordMin and ("  |cff8a6d3b(record : " .. FormatDuree(info.recordMin) .. ")|r") or ""))
    -- Miniature minimap : même info, compacte
    MHH_chronoMiniTxt:SetText("|cffff7a1a" .. FormatDuree(d) .. "|r"
        .. (info and info.recordMin and ("  |cff8a6d3b(" .. FormatDuree(info.recordMin) .. ")|r") or ""))
    -- Mini chrono : le carnet ouvert sur l'Accueil suit la chasse en direct
    if carnet and carnet:IsShown() and RaffraichirAccueil then RaffraichirAccueil() end
end
-- Fond texture du bandeau « EN CHASSE » (bandeau.tga : texte gravé DANS la
-- texture) — déclaré avant MettreAJourIndicateur pour la portée des upvalues
MHH_indicateurChasseFond = indicateurChasse:CreateTexture(nil, "ARTWORK")
MHH_indicateurChasseFond:SetAllPoints()
MHH_indicateurChasseFond:Hide()
-- Largeur du bandeau adaptée au texte (un nom de contrat peut être long)
local function AjusterLargeurIndicateur()
    if not (DB and DB.contrat) then return end
    -- Colle au texte : ni trop large, ni écrasé pour un long nom de mob
    indicateurChasse:SetWidth(math.min(290, math.max(88, 38 + #DB.contrat * 6.5)))
end
-- Rappel du contrat sous le bouton minimap — visible AUSSI pendant la
-- chasse (il est discret et ne gêne pas, contrairement à un bandeau)
local function RafraichirRappelContrat()
    IndicateurFondWoW(true)
    MHH_indicateurChasseFond:Hide()
    indicateurChasse:ClearAllPoints()
    indicateurChasse:SetPoint("TOP", bouton, "BOTTOM", 0, 2)
    indicateurChasse:SetHeight(20)
    if DB and DB.contrat then
        -- Contrat sur 2 lignes : libellé centré, cible en dessous.
        -- Bordure DORÉE (l'orange est réservé à « EN CHASSE ») : on lit
        -- d'un coup d'œil qu'une mission est acceptée, et la prime au
        -- passage. MHH_NomAffiche : graphie FR si le nom EN sert de clé.
        pcall(function()
            indicateurChasse:SetBackdropBorderColor(0.82, 0.64, 0.28, 0.95)
        end)
        indicateurChasseTxt:SetText("|cffffd100" .. L("Mission acceptée :") .. "|r\n|cffffff00"
            .. (MHH_NomAffiche and MHH_NomAffiche(DB.contrat) or DB.contrat) .. "|r")
        indicateurChasse:SetHeight(30)
        AjusterLargeurIndicateur()
        indicateurChasse:Show()
    else
        indicateurChasse:Hide()
    end
end
MettreAJourIndicateur = function()
    if chasseActive then
        -- En chasse : rien de superflu. Pas de bandeau permanent, pas de
        -- grand encart : seul le mini chrono tourne en coin, sous la
        -- minimap. Le bandeau « EN CHASSE » est éphémère (4 s à la
        -- sélection du gibier, géré par DebutChasse/BandeauChasseEphemer).
        indicateurChasse:Hide()
        IndicateurFondWoW(true)
        MHH_indicateurChasseFond:Hide()
        MHH_chronoChasse:Hide()
        if (DB.config.chronoMode or "minimap") ~= "off" then
            if DB.config.texUI == "custom" then MHH_chronoMiniFond:Show() end
            MHH_chronoMini:Show()
        else
            MHH_chronoMini:Hide()
            MHH_chronoMiniFond:Hide()
        end
        RafraichirChrono()
        if MHH_tickerChrono then MHH_tickerChrono:Cancel() end
        MHH_tickerChrono = C_Timer.NewTicker(1, RafraichirChrono)
        -- Pendant la chasse, le petit rappel de contrat reste en place
        RafraichirRappelContrat()
    else
        -- Pas de chasse active : rappel du contrat sous la minimap
        RafraichirRappelContrat()
        MHH_chronoChasse:Hide()
        MHH_chronoMini:Hide()
        MHH_chronoMiniFond:Hide()
        if MHH_tickerChrono then MHH_tickerChrono:Cancel() MHH_tickerChrono = nil end
    end
end

-- Bandeau « EN CHASSE » éphémère : affiché ~4 s à la sélection du gibier
-- (appelé par DebutChasse), puis il s'efface de lui-même. Seul le mini
-- chrono reste en coin pendant la chasse — pas de détail superflu.
local timerBandeauEphemer
function BandeauChasseEphemer() -- globale : DebutChasse est définie avant
    if not chasseActive then return end
    indicateurChasse:ClearAllPoints()
    indicateurChasse:SetPoint("TOP", UIParent, "TOP", 0, -60)
    if DB.config.texUI == "custom" then
        IndicateurFondWoW(false)
        MHH_indicateurChasseFond:Show()
        indicateurChasseTxt:SetText("")
        -- Taille au ratio de la texture (1152x443), hauteur réduite
        indicateurChasse:SetWidth(660)
        indicateurChasse:SetHeight(210)
    else
        IndicateurFondWoW(true)
        MHH_indicateurChasseFond:Hide()
        indicateurChasseTxt:SetText(L("|cffff7a1aEN CHASSE !|r"))
        indicateurChasse:SetWidth(400)
        indicateurChasse:SetHeight(50)
    end
    indicateurChasse:Show()
    indicateurChasse:SetAlpha(1)
    if timerBandeauEphemer then timerBandeauEphemer:Cancel() end
    timerBandeauEphemer = C_Timer.After(4, function()
        -- Disparition douce en fondu (0,8 s), pas de coupure sèche
        if FonduDoux then
            FonduDoux(indicateurChasse, 1, 0, 0.8, function()
                indicateurChasse:Hide()
                indicateurChasse:SetAlpha(1)
                MettreAJourIndicateur()
            end)
        else
            indicateurChasse:Hide()
            MettreAJourIndicateur()
        end
    end)
end

-- Textures UI custom (fichiers dans Interface/AddOns/MHHunt/Textures/) :
--   bandeau.tga = bandeau « EN CHASSE » sous la minimap (texte gravé dedans)
--   zone.tga    = fond de l'annonce de zone (Région de chasse — N gibiers)
--   chrono.tga  = fond du chrono de chasse en haut d'écran
-- Activées par /hunt texui custom (test : /hunt test zone|banniere|chrono)
MHH_chronoChasseFond = MHH_chronoChasse:CreateTexture(nil, "ARTWORK")
MHH_chronoChasseFond:SetAllPoints()
-- Rogne les ornements gauche/droite de chrono.tga : on ne garde que
-- le cœur parchemin (12 % retiré de chaque côté)
MHH_chronoChasseFond:SetTexCoord(0.12, 0.88, 0, 1)
MHH_chronoChasseFond:Hide()
AppliquerTexUI = function()
    if not DB then return end
    local custom = (DB.config.texUI == "custom")
    if custom then
        MHH_indicateurChasseFond:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\bandeau.tga")
        if not MHH_chronoChasseFond:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\chrono.tga") then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r chrono.tga ne charge pas — dimensions en puissance de 2 requises (ex. 512x64), TGA non compressé."))
        end
        MHH_chronoMiniFond:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\chrono.tga")
        MHH_chronoChasseFond:Show()
        if annonceZoneFrame and annonceZoneFrame.zoneFond then
            if not annonceZoneFrame.zoneFond:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\zone.tga") then
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r zone.tga ne charge pas — dimensions en puissance de 2 requises (ex. 256x64), TGA non compressé."))
            end
            annonceZoneFrame.zoneFond:Show()
        end
    else
        MHH_indicateurChasseFond:Hide()
        MHH_chronoChasseFond:Hide()
        MHH_chronoMiniFond:Hide()
        if annonceZoneFrame and annonceZoneFrame.zoneFond then
            annonceZoneFrame.zoneFond:Hide()
        end
    end
    MettreAJourIndicateur()
end

-- ============================================
-- 8. COMMANDES
-- ============================================
-- Fondu doux (anti « pop ») : interpole l'alpha d'un cadre en 10 pas,
-- enchaîne sur `apres` une fois terminé. Globale : appelée aussi par
-- BandeauChasseEphemer, définie plus haut dans le fichier.
function FonduDoux(f, a1, a2, duree, apres)
    f:Show()
    f:SetAlpha(a1)
    for i = 0, 10 do
        C_Timer.After(duree * i / 10, function()
            f:SetAlpha(a1 + (a2 - a1) * i / 10)
            if i == 10 and apres then apres() end
        end)
    end
end

-- Banque de pistes validées en jeu : voir PISTES_COMBAT_EPIQUE /
-- PISTES_COMBAT_NORMAL / PISTES_CHASE plus haut. /hunt test son <id>
-- reste disponible pour un essai libre.

SLASH_LACHASSE1 = "/hunt"
SLASH_LACHASSE2 = "/chasse"
SlashCmdList["LACHASSE"] = function(msg)
    local cmd = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if cmd == "" or cmd == "carnet" then
        OuvrirCarnet()
    elseif cmd == "aide" or cmd == "help" then
        -- Aide complète : toutes les commandes du carnet de chasse
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffffc44cAide du chasseur :|r"))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt|r : ouvrir le carnet. |cffffd100/hunt gibier|contrats|succes|profil|cuisine|options|r : page directe."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt add / remove|r : ajouter/retirer la cible au carnet (mode auto)."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt banner on/off|r, |cffffd100/hunt sound on/off|r : bannières, sons."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt kill loose/strict|r : participation ou coup de grâce pour valider une prise."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt icon custom/wow|r, |cffffd100/hunt parchment custom/wow|r : icône minimap, fond du carnet."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r : textures bandeau/zone/chrono. |cffffd100/hunt toast custom/wow|r : toast parchemin / plaque sombre."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt chrono full/minimap/off|r : chrono de chasse. |cffffd100/hunt musique off/wow/custom|r : musiques."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt tuto|r : revoir le panneau de bienvenue."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt carte <joueur>|r : envoyer votre carte de chasseur (rang, points, enclos) à un autre chasseur de l'addon."))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffc9a24a•|r |cffffd100/hunt langue fr|en|r : langue de l'interface (publication).")
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt export|r : liste « nom | id | zone » des découvertes (réconciliation Forever). |cffc9a24a•|r |cffffd100/hunt reset succes|missions|menagerie|carnet|r : remises à zéro ciblées. |cffffd100/hunt reset|r : tout effacer (irréversible)."))
    elseif cmd == "tuto" then
        -- Ré-affiche le panneau « Bonne chasse » (sans marquer tutoPanVu) ;
        -- le carnet s'ouvre d'abord : le panneau en est l'invite
        OuvrirCarnet()
        MontrerTuto()
    elseif cmd == "achievements" or cmd == "succes" then
        OuvrirCarnet("succes")
    elseif cmd == "profil" then
        OuvrirCarnet("profil")
    elseif cmd == "add" then
        if UnitExists("target") then
            -- v0.30 : nom secret (poison client) → clé de table interdite
            local nom = NomOrdinaire(UnitName("target"))
            if not nom then
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Nom de la cible illisible sur ce client (secret) — visez-la autrement ou resaisissez-la."))
            else
            local idR = nil
            local guid = UnitGUID("target")
            if guid then idR = tonumber(guid:match("-(%d+)$")) end
            DB.decouverts[nom] = DB.decouverts[nom] or { kills = 0, vu = true, zone = GetZoneText(), decouvert = time(), id = idR, nouveau = true }
            DB.decouverts[nom].vu = true
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. nom .. L(" ajouté au carnet."))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Ciblez d'abord une créature."))
        end
    elseif cmd == "remove" then
        if UnitExists("target") then
            local nom = NomOrdinaire(UnitName("target"))
            if not nom then
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Nom de la cible illisible sur ce client (secret)."))
            else
            DB.decouverts[nom] = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. nom .. L(" retiré du carnet."))
            end
        end
    elseif cmd == "banner on" then DB.config.banniere = true DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Bannière activée."))
    elseif cmd == "banner off" then DB.config.banniere = false DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Bannière désactivée."))
    elseif cmd == "sound on" then DB.config.son = true DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Sons activés."))
    elseif cmd == "sound off" then DB.config.son = false DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Sons désactivés."))
    elseif cmd == "emote on" then DB.config.emotePerdu = true DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Émote de perte (à genou) activée."))
    elseif cmd == "emote off" then DB.config.emotePerdu = false DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Émote de perte (à genou) désactivée."))
    elseif cmd == "kill loose" then DB.config.killSouple = true DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Kill souple (la participation compte).")
    elseif cmd == "kill strict" then DB.config.killSouple = false DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Kill strict (le coup de grâce doit être le vôtre)."))
    elseif cmd == "icon custom" then DB.config.icone = "custom" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Icône custom — nécessite /reload."))
    elseif cmd == "icon wow" then DB.config.icone = "wow" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Icône WoW — nécessite /reload."))
    elseif cmd == "parchment custom" then DB.config.fond = "custom" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Parchemin custom — nécessite /reload."))
    elseif cmd == "parchment wow" then DB.config.fond = "wow" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Fond WoW — nécessite /reload."))
    elseif cmd == "texui custom" then
        DB.config.texUI = "custom"
        if AppliquerTexUI then AppliquerTexUI() end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Textures UI custom : bandeau.tga / zone.tga / chrono.tga (dossier Textures).")
    elseif cmd == "toast custom" then
        DB.config.toast = "custom"
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Toasts parchemin : toast1.tga (validations) + toast2.tga (annonces) + tampons de guilde (dossier Textures).")
    elseif cmd == "toast wow" then
        DB.config.toast = "wow"
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Toasts standard (plaque sombre).")
    elseif cmd == "texui wow" then
        DB.config.texUI = "wow"
        if AppliquerTexUI then AppliquerTexUI() end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Textures UI standard (WoW).")
    elseif cmd == "musique off" or cmd == "musique wow" or cmd == "musique custom" then
        DB.config.musique = cmd:sub(9)
        MHH_ArreterMusique()
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Musiques : |cffffff00" .. DB.config.musique
            .. "|r." .. (DB.config.musique == "custom" and L(" (MHAmbiance/Sounds : promotion.mp3, combat.mp3, traque.mp3 — fichiers ajoutés après lancement du jeu = redémarrage client requis.)") or ""))
    elseif cmd == "chrono full" or cmd == "chrono minimap" or cmd == "chrono off" then
        DB.config.chronoMode = cmd:sub(8)
        MHH_chronoMini:Hide()
        MHH_chronoMiniFond:Hide()
        if chasseActive then MettreAJourIndicateur() end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Chrono : |cffffff00" .. DB.config.chronoMode
            .. "|r — " .. (DB.config.chronoMode == "full" and L("grand encart pendant la chasse")
            or (DB.config.chronoMode == "minimap" and "miniature sous le bouton minimap" or L("désactivé"))) .. ".")
    elseif cmd:match("^ajuster .+ [+-]%d+$") then
        -- Recalibrage manuel du compteur d'une bête :
        --   /hunt ajuster Capitaine Croc-Plat -3   (retirer des prises fantômes)
        --   /hunt ajuster Naraxis +2               (rattraper des prises manquées)
        local nomSaisi, deltaStr = cmd:match("^ajuster (.+) ([+-]%d+)$")
        local delta = tonumber(deltaStr)
        -- Recherche tolérante : nom exact, sinon insensible à la casse
        local nomExact
        if DB.chasses[nomSaisi] then
            nomExact = nomSaisi
        else
            for k in pairs(DB.chasses) do
                if k:lower() == nomSaisi:lower() then nomExact = k end
            end
        end
        if not nomExact then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Bête inconnue du carnet : « ") .. nomSaisi .. " ». Orthographe exacte de la fiche requise.")
        else
            local info = DB.chasses[nomExact]
            info.kills = math.max(0, (info.kills or 0) + delta)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Compteur de |cffffff00" .. nomExact .. L("|r ajusté (") .. deltaStr .. L(") : |cffffd100") .. info.kills .. L("|r prise(s)."))
        end
        if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "reset kills" then
        -- Remise à zéro de TOUS les compteurs de prises (fiches conservées).
        -- Pour repartir propre après des prises fantômes de test.
        for _, info in pairs(DB.chasses) do info.kills = 0 end
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Tous les compteurs de prises remis à zéro (fiches, trophées et points conservés)."))
        if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "reset succes" then
        -- Remise à zéro des succès : tout redevient verrouillé (test,
        -- replay du débloquage, ou purge de déblocages de test).
        DB.succes = {}
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Tous les succès remis à zéro — ils se débloqueront de nouveau à la prochaine action qui les valide."))
        if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "reset missions" then
        -- Remise à zéro des missions : la mission active est abandonnée
        -- et toutes les missions accomplies redeviennent à faire.
        DB.missions = {}
        DB.missionActive = nil
        DB.missionCacheeActive = nil -- rumeur active abandonnée…
        DB.missionCacheeJour = nil   -- …et le tirage du jour refait au log
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Missions remises à zéro — mission active abandonnée, toutes les missions redeviennent disponibles."))
        if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "reset menagerie" then
        -- Enclos vidé : les spécimens repartent dans la nature (fiches,
        -- trophées et points conservés).
        DB.menagerie = {}
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Enclos vidé — les spécimens sont partis dans la nature (fiches et trophées conservés)."))
        if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "reset carnet" then
        -- Fiches et découvertes effacées : le carnet repart vierge.
        -- Attention : les prises et points associés aux fiches sont perdus.
        DB.decouverts = {}
        DB.chasses = {}
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Carnet vidé — fiches et comptes de chasse effacés (succès, trophées et points de guilde conservés)."))
        if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "debug" then
        -- Bascule du journal de diagnostic (canal DBG dans le chat) :
        -- trace chaque canal de détection de mort, la source du gabarit,
        -- etc. Utile quand une prise « ne compte pas ».
        DB.config.debug = not DB.config.debug
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Traçage des détections de mort : |cffffff00") .. (DB.config.debug and "ON" or "OFF") .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Debug : chasseActive=") .. tostring(chasseActive)
            .. ", chasseSuspendue=" .. tostring(chasseSuspendue and chasseSuspendue.nom or nil)
            .. ", rayonEngagement=" .. tostring(chasseRayon)
            .. ", UnitBoundingRadius=" .. (UnitBoundingRadius and "dispo" or "absent"))
    elseif cmd:sub(1, 6) == "carte " or cmd == "carte" then
        -- v0.56 : ENVOI de la carte de chasseur. Le protocole existed côté
        -- réception depuis longtemps, mais personne n'envoyait jamais rien.
        local cible = cmd:sub(7):gsub("^%s+", ""):gsub("%s+$", "")
        if cible == "" then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r /hunt carte <joueur> : indiquez le nom du chasseur."))
            return
        end
        local total = 0
        if DB.chasses then
            for _, c in pairs(DB.chasses) do total = total + (c.kills or 0) end
        end
        local nbCaptures = 0
        if DB.menagerie then
            for _ in pairs(DB.menagerie) do nbCaptures = nbCaptures + 1 end
        end
        local idxRang = RangGuilde(DB.points or 0)
        local msgCarte = "CARTE:" .. idxRang .. "|" .. (DB.points or 0)
            .. "|" .. total .. "|" .. nbCaptures .. "|" .. (DB.dernierePriseNom or "-")
        local envoye = false
        pcall(function()
            if C_Chat and C_Chat.SendAddonMessage then
                C_Chat.SendAddonMessage("MHHUNT", msgCarte, "WHISPER", cible)
                envoye = true
            elseif SendAddonMessage then
                SendAddonMessage("MHHUNT", msgCarte, "WHISPER", cible)
                envoye = true
            end
        end)
        if envoye then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Carte de chasseur envoyée à |cffffff00") .. cible
                .. L("|r — elle s'affichera chez lui s'il a l'addon."))
        else
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Canal d'addon indisponible sur ce client."))
        end
    elseif cmd == "export" then
        -- Export de réconciliation : liste « nom FR | id | zone » des bêtes
        -- découvertes (id NPC extrait du GUID). À copier-coller au dev pour
        -- confirmer les noms FR du serveur et remplir le palier 31-60.
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffffc44cExport de réconciliation — copie-colle ces lignes :|r"))
        local n = 0
        -- Noms vus en jeu ABSENTS du catalogue : c'est la détection de
        -- doublons (le nom réel du serveur ne matche aucune fiche du
        -- data — à fusionner en ajustant nom/alias dans MHHuntData).
        local inconnus = {}
        for nom, e in pairs(DB.decouverts) do
            n = n + 1
            if not MHH_CATALOGUE[nom] then inconnus[#inconnus + 1] = nom .. " | zone=" .. tostring(e.zone or "?") end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("MHEXPORT | %s | id=%s | zone=%s | kills=%s",
                nom, tostring(e.id or "?"), tostring(e.zone or "?"), tostring(e.kills or 0)))
        end
        for nom, info in pairs(DB.chasses) do
            if not DB.decouverts[nom] then
                n = n + 1
                if not MHH_CATALOGUE[nom] then inconnus[#inconnus + 1] = nom end
                DEFAULT_CHAT_FRAME:AddMessage(string.format("MHEXPORT | %s | id=%s | kills=%s",
                    nom, tostring(info.id or "?"), tostring(info.kills or 0)))
            end
        end
        if #inconnus > 0 then
            table.sort(inconnus)
            DEFAULT_CHAT_FRAME:AddMessage(string.format(L("|cffffd100[MH Hunt]|r |cffff6a6a%d nom(s) hors catalogue|r (doublons potentiels — noms réels du serveur à fusionner dans le data) :"), #inconnus))
            for _, ligne in ipairs(inconnus) do
                DEFAULT_CHAT_FRAME:AddMessage("MHHORSCAT | " .. ligne)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L("|cffffd100[MH Hunt]|r %d entrées exportées."), n))
    elseif cmd == "langue fr" then
        DB.config.langue = "fr"
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. L("langue_changee"))
        if carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "langue en" then
        DB.config.langue = "en"
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. L("langue_changee"))
        if carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd == "test tooltip" or cmd:match("^test tooltip ") then
        -- Previsualisation du tooltip de liste : nom seul, ANCHOR_CURSOR.
        -- /hunt test tooltip <nom> force un mob precis (recherche large).
        local nomSaisi = cmd:match("^test tooltip (.+)$")
        local nom = nomSaisi
        if nom and MHH_CATALOGUE[nom] == nil then nom = nil end
        if nomSaisi and not nom then
            for k in pairs(MHH_CATALOGUE) do
                if k:lower():find(nomSaisi:lower(), 1, true) then nom = nom or k end
            end
        end
        if not nom then
            for k in pairs(MHH_CATALOGUE) do nom = nom or k end
        end
        if GameTooltip and nom then
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            local ech = UIParent:GetScale()
            local mx, my = GetCursorPosition()
            GameTooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                mx / ech + 4, my / ech - 12)
            GameTooltip:SetText("|cffffd100" .. (MHH_NomAffiche and MHH_NomAffiche(nom) or nom) .. "|r")
            GameTooltip:Show()
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Tooltip affiche au curseur : |cffffff00"
                .. nom .. "|r (se referme au prochain mouvement).")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Aucun mob a afficher.")
        end
    elseif cmd == "test mystere" then
        -- Diagnostic vignette mystere : verifie que inconnu.tga est chargeable
        -- (ok=true/false + chemin relu par GetTexture). Si ok=false : fichier
        -- absent, JPG renomme en .tga, TGA non 32 bits non compresse, ou
        -- dimensions non puissance de 2 (ex. 128).
        for _, dossier in ipairs({ "Specimens", "Vignettes" }) do
            local tx = UIParent:CreateTexture(nil, "ARTWORK")
            tx:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\" .. dossier .. "\\inconnu.tga")
            local ok = tx:GetTexture() ~= nil
            local chemin = tx:GetTexture() or "?"
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Test " .. dossier
                .. "\\inconnu.tga : |cffffff00" .. tostring(ok) .. "|r — " .. tostring(chemin))
            tx:Hide()
            tx = nil
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r ok=false partout : fichier absent, JPG renomme en .tga, "
            .. "TGA non 32 bits non compresse, ou taille non puissance de 2 (ex. 128).")
    -- v0.151 : « test sprites » retiré — plus de sprites TGA ménagerie
    -- (pensionnaires = modèles 3D du jeu, cf. Menagerie.lua).
    elseif cmd == "test icones" then
        -- Diagnostic icônes rondes du médaillon : charge chaque TGA, dit
        -- ok/absent en chat, ET affiche un aperçu des 3 à l'écran (8 s).
        -- ok=false : fichier absent, JPG renommé en .tga, TGA non 32 bits
        -- non compressé, ou dimensions non puissance de 2 (ex. 128).
        local nomsIcones = { "griffe", "patte", "sceau" }
        -- Aperçu visuel : 3 cases de 128 px côte à côte, centre écran
        local apercu = CreateFrame("Frame", nil, UIParent)
        apercu:SetSize(3 * 148, 170)
        apercu:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        apercu:SetFrameStrata("HIGH")
        -- Pas de SetBackdrop (nil sur ce client pour un frame neuf) :
        -- plaque en textures, même recette que les toasts (liseré + fond)
        local bordApercu = apercu:CreateTexture(nil, "BACKGROUND")
        bordApercu:SetAllPoints()
        bordApercu:SetColorTexture(0.60, 0.44, 0.20, 0.95)
        local fondApercu = apercu:CreateTexture(nil, "BORDER")
        fondApercu:SetPoint("TOPLEFT", 3, -3)
        fondApercu:SetPoint("BOTTOMRIGHT", -3, 3)
        fondApercu:SetColorTexture(0.05, 0.03, 0.01, 0.92)
        for i, n in ipairs(nomsIcones) do
            local chemin = "Interface\\AddOns\\MHHunt\\Textures\\Circles\\" .. n .. ".tga"
            -- Diagnostic chat (une texture jetable relit GetTexture)
            local tx = UIParent:CreateTexture(nil, "ARTWORK")
            tx:SetTexture(chemin)
            local ok = tx:GetTexture() ~= nil
            tx:Hide()
            tx = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Circles\\" .. n
                .. ".tga : |cffffff00" .. tostring(ok) .. "|r — "
                .. (ok and "|cff88ff88chargée|r" or "|cffff5555ABSENTE (fichier absent, JPG renommé en .tga, TGA non 32 bits non compressé, ou taille non puissance de 2)|r"))
            -- Case d'aperçu : le TGA tel quel (aucun repli : on voit le VRAI rendu)
            local t = apercu:CreateTexture(nil, "ARTWORK")
            t:SetSize(128, 128)
            t:SetPoint("TOPLEFT", (i - 1) * 148 + 10, -10)
            t:SetTexture(chemin)
            local lbl = apercu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("TOPLEFT", (i - 1) * 148 + 10, -140)
            lbl:SetWidth(128)
            lbl:SetJustifyH("CENTER")
            lbl:SetText("|cffffd100" .. n .. "|r\n" .. (ok and "|cff88ff88OK|r" or "|cffff5555absente|r"))
        end
        C_Timer.After(8, function() apercu:Hide() end)
    elseif cmd == "test griffe" then
        -- Réplique du toast « Mesure du gabarit — COURONNE D'OR » (icône griffe)
        ToastSucces("Interface\\Icons\\INV_Misc_MonsterClaw_04",
            L("Mesure du gabarit"),
            L("Gabarit mesuré : |cffffff00") .. "62" .. L(" unités|r")
                .. L(" |cffa58b54(~") .. "145" .. L(" cm d'envergure)|r")
                .. L(" — |cffffcc44COURONNE D'OR !|r"))
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast couronne d'or (griffe)."))
    elseif cmd == "test patte" then
        -- Réplique du toast « Spécimen capturé » (icône patte, desc 2 lignes)
        ToastSucces("Interface\\Icons\\Ability_Hunter_BeastTaming",
            L("Spécimen capturé"), "Humar (Les Paluns)" .. L(" rejoint l'enclos (Ménagerie)."))
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast spécimen capturé (patte)."))
    elseif cmd == "test mission" then
        -- Réplique du toast « Mission accomplie » (icône carrée : repli)
        ToastSucces("Interface\\Icons\\Ability_Hunter_Pet_Wolf",
            L("Mission accomplie"), "Nettoyer la tanière — Riveau (Bois de la Pénombre)")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast mission (icône carrée de repli)."))
    elseif cmd == "test rumeur" then
        -- Réplique du toast « Rumeur élucidée » (icône carrée : repli)
        ToastSucces("Interface\\Icons\\INV_Misc_Dice_01",
            L("Rumeur élucidée"), "Le dé pipé de Menara")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast rumeur élucidée (icône carrée de repli)."))
    elseif cmd == "test succes" then
        -- Réplique du toast « Succès débloqué » (icône carrée : repli)
        ToastSucces("Interface\\Icons\\Spell_Fire_FireBolt",
            L("Série de 5"), L("5 chasses consécutives sans mourir"), nil, "succes")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast succès (icône carrée de repli)."))
    elseif cmd == "test promotion" then
        -- Réplique du toast « Promotion de guilde » — affiché comme un
        -- succès (parchemin custom, desc = phrase)
        ToastSucces("Interface\\Common\\ReputationStar",
            L("Promotion de guilde"), L("Nouveau rang : ") .. "Artisan du gibier", nil, "succes")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast promotion (comme un succès — parchemin)."))
    elseif cmd == "test intrus" then
        -- Réplique du toast « Intrus dans l'enclos » — message simple
        -- (plaque sombre, sans médaillon ni tampon)
        ToastSucces("Interface\\Icons\\Ability_Hunter_BeastTaming",
            L("Intrus dans l'enclos"), "Gorged'acier", "wow")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast intrus dans l'enclos (message simple, sans médaillon)."))
    elseif cmd == "debug enclos" then
        -- DIAGNOSTIQUE « carrés flottants » (v0.65m) : inventorie tout ce
        -- qui s'affiche sur l'enclos au moment de la commande. Taper
        -- /hunt debug enclos quand un carré parasite est visible.
        local n = 0
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r === Inventaire enclos ===")
        -- fond + bâtiments
        if MHH_enclosFondImg then
            DEFAULT_CHAT_FRAME:AddMessage("fond: shown=" .. tostring(MHH_enclosFondImg:IsShown()))
        end
        for i, t in ipairs(MHH_batimentsRanch or {}) do
            if t:IsShown() then
                DEFAULT_CHAT_FRAME:AddMessage("batiment " .. (t.mhhFichier or i)
                    .. ": shown, tga charge=" .. tostring(t.mhhCharge))
            end
        end
        -- particules météo (doivent être toutes cachées depuis la v0.65h)
        local np = 0
        for _, p in ipairs(MHH_particulesMenagerie or {}) do
            if p.t:IsShown() then np = np + 1 end
        end
        if np > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5050PARTICULES visibles: " .. np .. " (normalement 0)|r")
        end
        -- sprites pensionnaires + leurs ombres
        for nom, s in pairs(MHH_spritesMenagerie or {}) do
            local uf = s.f and s.f.utiliseTga
            local sf = s.f and s.f:IsShown()
            local so = s.ombre and s.ombre:IsShown()
            local omx, omy = -999, -999
            pcall(function()
                local _, _, _, xoff, yoff = s.ombre:GetPoint(1)
                omx, omy = xoff or -999, yoff or -999
            end)
            n = n + 1
            DEFAULT_CHAT_FRAME:AddMessage("sprite " .. nom
                .. ": tga=" .. tostring(uf) .. " shown=" .. tostring(sf)
                .. " | ombre shown=" .. tostring(so)
                .. " @" .. math.floor(tonumber(omx) or -999) .. "," .. math.floor(tonumber(omy) or -999)
                .. " taille=" .. (s.ombre and (math.floor(s.ombre:GetWidth() or 0) .. "x" .. math.floor(s.ombre:GetHeight() or 0)) or "?"))
        end
        DEFAULT_CHAT_FRAME:AddMessage("sprites: " .. n .. " — si un carré est visible sans ligne correspondante, il vient d'ailleurs.")
    elseif cmd:match("^test batimg") then
        -- v0.118o : PRÉVISUALISATION des bâtiments supérieurs sans
        -- monter de rang. Fichiers : tente, tour, house, manoir.
        -- v0.142 : sans argument, AIDE au lieu d'effacer l'override —
        -- « suit le rang » en réponse à /hunt test batimg tout court
        -- se lisait comme « ça ne marche pas » (retour utilisateur).
        -- Accepte aussi le NUMÉRO (1-4 = entrée de MHH_BATIMENTS_RANCH).
        if not (MHH_DB and MHH_MajBatimentsRanch) then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r ouvre d'abord le carnet (M\195\169nagerie)")
        else
            local f = cmd:match("^test batimg (%S+)")
            if not f then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r /hunt test batimg <tente|tour|house|manoir|1-4>  ou  /hunt test batimg off")
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r for\195\169age actif : "
                    .. tostring(MHH_DB.config and MHH_DB.config.batImg))
            elseif f == "off" then
                MHH_DB.config = MHH_DB.config or {}
                MHH_DB.config.batImg = nil
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r b\195\162timent : suit le rang")
                MHH_MajBatimentsRanch()
            else
                local n = tonumber(f)
                if n and MHH_BATIMENTS_RANCH and MHH_BATIMENTS_RANCH[n] then
                    f = MHH_BATIMENTS_RANCH[n].fichier
                end
                local okBat
                if MHH_BATIMENTS_RANCH then
                    for _, bat in ipairs(MHH_BATIMENTS_RANCH) do
                        if bat.fichier == f then okBat = true end
                    end
                end
                if not okBat then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r b\195\162timent inconnu : " .. f .. " (tente, tour, house, manoir)")
                else
                    MHH_DB.config = MHH_DB.config or {}
                    MHH_DB.config.batImg = f
                    MHH_MajBatimentsRanch()
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r b\195\162timent forc\195\169 : " .. f .. "  (/hunt test batimg off pour revenir)")
                end
            end
        end
    elseif cmd == "test bat" or cmd:match("^test bat ") then
        -- v0.115 : réglage à l'œil du bâtiment du ranch (la commande
        -- était promise dans les commentaires depuis la v0.103 mais
        -- n'avait JAMAIS été écrite — retour utilisateur).
        --   /hunt test bat <taille> [x] [y]   (y depuis le HAUT)
        --   /hunt test bat reset            (défauts : centre du plot)
        if not (MHH_DB and MHH_MajBatimentsRanch) then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r ouvre d'abord le carnet (M\195\169nagerie)")
        elseif cmd:match("^test bat reset") then
            MHH_DB.config = MHH_DB.config or {}
            MHH_DB.config.bat2 = nil
            MHH_MajBatimentsRanch()
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r b\195\162timent : d\195\169fauts (centre du plot)")
        else
            local a, b, c = cmd:match("^test bat (%-?%d+)%s*(%-?%d*)%s*(%-?%d*)$")
            if not a then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r /hunt test bat <taille> [x] [y]  |  /hunt test bat reset")
            else
                MHH_DB.config = MHH_DB.config or {}
                MHH_DB.config.bat2 = {
                    taille = tonumber(a),
                    x = (b ~= "" and tonumber(b)) or nil,
                    y = (c ~= "" and tonumber(c)) or nil,
                }
                MHH_MajBatimentsRanch()
                local r = MHH_DB.config.bat2
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r b\195\162timent : taille " .. a
                    .. ", x " .. tostring(r.x) .. ", y " .. tostring(r.y) .. " (depuis le haut)")
            end
        end
    elseif cmd == "test zone" then
        -- Aperçu : bandeau d'entrée de région (zone.tga en mode custom)
        MHH_AnnonceZone(true)
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : annonce de zone affichée."))
    elseif cmd == "test banniere" then
        -- Aperçu : bannière centrale (bandeau.tga en mode custom)
        AfficherBanniere(L("|cffffd100BONNE CHASSE !|r"), 1, 0.84, 0)
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : bannière centrale affichée."))
    elseif cmd == "test en chasse" then
        -- Aperçu : bandeau EN CHASSE + mini chrono en coin (4 s)
        AfficherBanniere(L("|cffff7a1aEN CHASSE !|r"), 0.95, 0.55, 0.2)
        if MHH_chronoMini then
            MHH_chronoMini:Show()
            if MHH_chronoMiniTxt then MHH_chronoMiniTxt:SetText("|cffff7a1a00:04|r") end
            C_Timer.After(4, function() if MHH_chronoMini then MHH_chronoMini:Hide() end end)
        end
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : bandeau En chasse éphémère (4 s), puis mini chrono en coin."))
    elseif cmd == "test chrono" then
        -- Aperçu : grand chrono de chasse, compte à rebours 10 s puis masqué
        if MHH_chronoChasse and MHH_chronoChasseTitre and MHH_chronoChasseTxt then
            MHH_chronoChasseTitre:SetText("|cffffd100Test chrono|r")
            MHH_chronoChasse:Show()
            for i = 0, 10 do
                C_Timer.After(i, function()
                    if MHH_chronoChasse and MHH_chronoChasse:IsShown() then
                        MHH_chronoChasseTxt:SetText("|cffff7a1a00:" .. string.format("%02d", 10 - i) .. "|r")
                        if i == 10 then MHH_chronoChasse:Hide() end
                    end
                end)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : chrono lancé (10 s), fondu à l'entrée et à la sortie."))
    elseif cmd == "test prime" then
        -- Aperçu : toast validation (toast1.tga + médaillon + tampon)
        ToastSucces("Interface\\Icons\\INV_Misc_Coin_01",
            L("Contrat rempli"), "Rotheap (Les Paluns)")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast validation affiché (toast1.tga)."))
    elseif cmd == "test wow" then
        -- Aperçu : l'AUTRE toast (plaque sombre à liseré doré), sans
        -- toucher à la config — surcharge ponctuelle du mode
        MHH_ToastForceMode = "wow"
        ToastSucces("Interface\\Icons\\INV_Misc_Coin_01",
            L("Contrat rempli"), "Rotheap (Les Paluns)")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast sombre affiché (mode « wow », sans changer la config)."))
    elseif cmd == "test tampon alliance" or cmd == "test tampon horde" then
        -- Aperçu : le même toast avec le tampon de faction forcé
        local f = (cmd == "test tampon horde") and "Horde" or "Alliance"
        MHH_ToastTestFaction = f
        ToastSucces("Interface\\Icons\\INV_Misc_Coin_01",
            L("Contrat rempli"), "Rotheap (Les Paluns)")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : toast avec tampon ") .. f .. ".")
    elseif cmd == "test cible" then
        -- Aperçu : toast cible du jour (compact) — tirage forcé si besoin
        if not DB.cibleJour then ContratQuotidien() end
        if DB.cibleJour then
            ToastCibleDuJour(DB.cibleJour, DB.cibleJourZone)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Test : aucune cible du jour (catalogue vide ?).")
            return
        end
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : cible du jour relancée (toast + plaque Accueil)."))
    elseif cmd == "test menagerie" then
        -- Aperçu : provisionne viandes/miels et 8 spécimens d'enclos
        DB.viande = (DB.viande or 0) + 20
        DB.miel = (DB.miel or 0) + 10
        DB.menagerie = DB.menagerie or {}
        local n = 0
        if MHH_SPECIMENS then
            for nomSpec in pairs(MHH_SPECIMENS) do
                if n >= 8 then break end
                if not DB.menagerie[nomSpec] then
                    DB.menagerie[nomSpec] = { capture = time(), nourri = time() }
                    n = n + 1
                end
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : +20 viandes, +10 miels, 8 spécimens en enclos (dont un affamé et un gâté)."))
        if RaffraichirMenagerie then RaffraichirMenagerie() end
        -- v0.119 : la fiche Gibier suit (mention « Spécimen en enclos »)
        if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    elseif cmd:match("^test son .+$") then
        -- /hunt test son <id SoundKit> : essai audio direct sur le canal
        -- SFX (PlaySoundFile). Aucun son = identifiant inconnu du client.
        local ref = cmd:match("^test son (.+)$")
        local res = JouerFichierBlinde(tonumber(ref) or ref)
        if res ~= nil and res ~= false then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Son joué : |cffffff00" .. ref .. "|r.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Aucun son pour « " .. ref
                .. " » : identifiant inconnu sur ce client (ou piste muette).")
        end
    elseif cmd:match("^test chemin .+$") then
        -- /hunt test chemin <fichier.mp3> : essai d'un fichier du dossier
        -- MHAmbiance\\Sounds (nom relatif). Fichier ajouté après le
        -- lancement du jeu = redémarrage client requis.
        local f = cmd:match("^test chemin (.+)$")
        local res = JouerFichierBlinde("Interface\\AddOns\\MHAmbiance\\Sounds\\" .. f)
        if res ~= nil and res ~= false then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Fichier joué : |cffffff00MHAmbiance\\Sounds\\" .. f .. "|r.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Introuvable ou muet : |cffffff00MHAmbiance\\Sounds\\" .. f
                .. "|r — vérifiez le nom/extension, ou redémarrez le client si le fichier a été ajouté après lancement.")
        end
    elseif cmd == "armes" then
        -- DIAGNOSTIC armes de chasse (enfin implémenté — l'aide
        -- l'annonçait). État du panneau + contenu de DB.armes.
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Diagnostic armes :")
        if not MHH_armesPan then
            DEFAULT_CHAT_FRAME:AddMessage("  panneau : INEXISTANT — le chunk mhhunt.lua a été interrompu avant sa création (voir erreur de chargement).")
        else
            DEFAULT_CHAT_FRAME:AddMessage("  panneau : shown=" .. tostring(MHH_armesPan:IsShown())
                .. " visible=" .. tostring(MHH_armesPan:IsVisible())
                .. " strate=" .. tostring(MHH_armesPan:GetFrameStrata())
                .. " niveau=" .. tostring(MHH_armesPan:GetFrameLevel()))
        end
        local nArmes = 0
        if DB and DB.armes then
            for k, v in pairs(DB.armes) do
                nArmes = nArmes + 1
                DEFAULT_CHAT_FRAME:AddMessage("  " .. k .. " : " .. v)
            end
        end
        if nArmes == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  (aucune arme enregistrée en base — les prises n'ont pas été identifiées)")
        end
    elseif cmd == "reset" then
        for k in pairs(LaChasseDB) do LaChasseDB[k] = nil end
        InitDB()
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Base réinitialisée."))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r /hunt (carnet), /hunt aide, /hunt tuto, /hunt achievements, /hunt add|remove, /hunt banner on|off, /hunt sound on|off, /hunt kill loose|strict, /hunt icon custom|wow, /hunt parchment custom|wow, /hunt texui custom|wow, /hunt toast custom|wow, /hunt musique off|wow|custom, /hunt test zone|banniere|chrono|en chasse|prime|wow|cible|tampon alliance|horde|icones|griffe|patte|mission|rumeur|succes|promotion|intrus|menagerie, /hunt chrono full|minimap|off, /hunt carte <joueur>, /hunt ajuster <nom> <±n>, /hunt reset kills, /hunt reset succes|missions|menagerie|carnet, /hunt export, /hunt langue fr|en, /hunt reset")
    end
end
-- ================= PONT VERS Menagerie.lua (v0.67) =================
MHH_L = L
MHH_Carnet = carnet
MHH_MeteoActuelle = MeteoActuelle
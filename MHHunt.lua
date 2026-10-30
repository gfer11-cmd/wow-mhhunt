MHH_ADDON_NAME = "MHHunt"

-- ============================================
-- 1. BASE DE DONNÉES
-- ============================================
local defaults = {
    chasses = {},          -- [nom] = { kills = n, vu = true/false }
    missions = {},         -- [id mission] = date d'accomplissement
    decouverts = {},       -- rares Forever inconnus détectés automatiquement
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
        killSouple = true, -- true: participation compte, false: kill strict
        icone = "custom",  -- "wow" ou "custom" (Textures/carnet.tga)
        fond = "custom",   -- "wow" (couleur bois) ou "custom" (Textures/fond.tga parchemin)
        texUI = "custom",  -- "wow" ou "custom" : bandeau.tga / zone.tga / chrono.tga
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
        ["|cffffd100[MH Hunt]|r Tous les succès remis à zéro — ils se débloqueront de nouveau à la prochaine action qui les valide."] = "|cffffd100[MH Hunt]|r All achievements reset — they will unlock again the next time their condition is met.",
        ["|cffffd100[MH Hunt]|r Missions remises à zéro — mission active abandonnée, toutes les missions redeviennent disponibles."] = "|cffffd100[MH Hunt]|r Quests reset — active quest abandoned, all quests available again.",
        ["|cffffd100[MH Hunt]|r Enclos vidé — les spécimens sont partis dans la nature (fiches et trophées conservés)."] = "|cffffd100[MH Hunt]|r Pen emptied — the specimens are back in the wild (cards and trophies kept).",
        ["|cffffd100[MH Hunt]|r Carnet vidé — fiches et comptes de chasse effacés (succès, trophées et points de guilde conservés)."] = "|cffffd100[MH Hunt]|r Journal emptied — cards and kill counts erased (achievements, trophies and guild points kept).",
        [" chasse"] = " hunt",
        [" chasses"] = " hunts",
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
        ["Capture-le : piège de chasse puis acheve-le,"] = "Capture it: hunting trap, then finish it off,",
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
        ["Découvrir un rare inconnu (mode auto)"] = "Discover an unknown rare (auto mode)",
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
        ["Rang de chasseur : |cffffd100"] = "Hunter rank: |cffffd100",
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
        ["Sans mourir : "] = "Without dying: ",
        ["Sans une égratignure"] = "Without a Scratch",
        ["Serpent des marais, patient comme la vase. On le voit trop tard, jamais deux fois."] = "Swamp serpent, patient as mud. You see it too late, never twice.",
        ["Ses bonds laissent des traces profondes dans la poussière des Tarides."] = "Its leaps leave deep tracks in the Barrens dust.",
        ["Ses griffes tombent plus vite que l'œil ne cligne. Les prairies l'entendent avant de le voir."] = "Its claws fall faster than the eye blinks. The plains hear it before they see it.",
        ["Sons de l'addon"] = "Addon Sounds",
        ["Sorcier de guerre"] = "Warlock",
        ["Spécimen capturé"] = "Specimen captured",
        ["Spécimen en enclos — "] = "Specimen in the pen — ",
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
        ["  |cffc9a24a•|r |cffffd100/hunt test zone|banniere|chrono|en chasse|prime|menagerie|r : prévisualisations. |cffffd100/hunt test chemin <mp3>|r, |cffffd100/hunt test son <id>|r : essais audio."] = "  |cffc9a24a•|r |cffffd100/hunt test zone|banniere|chrono|en chasse|prime|menagerie|r: previews. |cffffd100/hunt test chemin <mp3>|r, |cffffd100/hunt test son <id>|r: audio tests.",
        ["  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r : textures bandeau/zone/chrono."] = "  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r: banner/zone/timer textures.",
        ["  |cffc9a24a•|r |cffffd100/hunt titre <famille>|r : naturaliste, chasseur, explorateur, traqueur."] = "  |cffc9a24a•|r |cffffd100/hunt titre <family>|r: naturalist, hunter, explorer, tracker.",
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
        [" est exténué — il droole sur ses pattes…"] = " is exhausted — drooling on its paws…",
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
        [" » (nom de zone inconnu du client ?)."] = "\" (zone name unknown to this client?).",
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
        ["|cffa58b54Le carnet du chasseur : quatre repères de vieux chasseur|r"] = "|cffa58b54The hunter's journal: four marks of an old hunter|r",
        ["|cffa58b54RÉGION DE CHASSE|r"] = "|cffa58b54HUNTING REGION|r",
        ["|cffc9a24aIngrédients :|r "] = " |cffc9a24aIngredients:|r ",
        ["|cffc9a24aLa guilde des chasseurs salue|r"] = "|cffc9a24aThe hunters' guild salutes|r",
        ["|cffc9a24aRepas préparé :|r"] = "|cffc9a24aMeal prepared:|r",
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
        ["|cffffd100[MH Hunt]|r /hunt titre naturaliste | chasseur | explorateur | traqueur"] = "|cffffd100[MH Hunt]|r /hunt titre naturaliste | chasseur | explorateur | traqueur",
        ["|cffffd100[MH Hunt]|r Ambiance sonore du jeu réactivée (un vieux mute de l'addon traînait dans la config du client)."] = "|cffffd100[MH Hunt]|r Game ambience re-enabled (an old addon mute was lingering in the client config).",
        ["|cffffd100[MH Hunt]|r Bannière activée."] = "|cffffd100[MH Hunt]|r Banner enabled.",
        ["|cffffd100[MH Hunt]|r Bannière désactivée."] = "|cffffd100[MH Hunt]|r Banner disabled.",
        ["|cffffd100[MH Hunt]|r Base réinitialisée."] = "|cffffd100[MH Hunt]|r Database reset.",
        ["|cffffd100[MH Hunt]|r Bête inconnue du carnet : « "] = " |cffffd100[MH Hunt]|r Beast unknown to the journal: \" ",
        ["|cffffd100[MH Hunt]|r Carte de chasseur envoyée à |cffffff00"] = "|cffffd100[MH Hunt]|r Hunter card sent to |cffffff00",
        ["|cffffd100[MH Hunt]|r Carte de chasseur — |cffffff00"] = "|cffffd100[MH Hunt]|r Hunter card — |cffffff00",
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
        ["|cffffd100[MH Hunt]|r Test : bandeau En chasse éphémère (4 s), puis mini chrono en coin."] = "|cffffd100[MH Hunt]|r Test: ephemeral hunt banner (4 s), then mini timer in the corner.",
        ["|cffffd100[MH Hunt]|r Test : bannière centrale affichée."] = "|cffffd100[MH Hunt]|r Test: center banner shown.",
        ["|cffffd100[MH Hunt]|r Test : chrono lancé (10 s), fondu à l'entrée et à la sortie."] = "|cffffd100[MH Hunt]|r Test: timer running (10 s), fade in and out.",
        ["|cffffd100[MH Hunt]|r Test : cible du jour relancée (toast + plaque Accueil)."] = "|cffffd100[MH Hunt]|r Test: target of the day refreshed (toast + Home plate).",
        ["|cffffd100[MH Hunt]|r Test : enclos vidé (l'apprivoisement reste testable, les fiches sont conservées)."] = "|cffffd100[MH Hunt]|r Test: pen emptied (taming still testable, cards kept).",
        ["|cffffd100[MH Hunt]|r Titre affiché : « "] = " |cffffd100[MH Hunt]|r Displayed title: \" ",
        ["|cffffd100[MH Hunt]|r Tous les compteurs de prises remis à zéro (fiches, trophées et points conservés)."] = "|cffffd100[MH Hunt]|r All kill counters reset to zero (cards, trophies and points kept).",
        ["|cffffd100[MH Hunt]|r Traçage des détections de mort : |cffffff00"] = "|cffffd100[MH Hunt]|r Death detection tracing: |cffffff00",
        ["|cffffd100[MH Hunt]|r Trophée prélevé : "] = " |cffffd100[MH Hunt]|r Trophy taken: ",
        ["|cffffd100[MH Hunt]|r Usage : /hunt lisere <1-5> (0 = rang réel)."] = "|cffffd100[MH Hunt]|r Usage: /hunt lisere <1-5> (0 = real rank).",
        ["|cffffd100[MH Hunt]|r chargé. /hunt pour ouvrir le carnet. "] = " |cffffd100[MH Hunt]|r loaded. /hunt to open the journal. ",
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
    ["Ambassadeur Sanglerage"] = "Les Tarides",
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
    ["Géoprêtre Gukk'rok"] = "Mulgore",
    ["Swinegart Peau-de-lance"] = "Mulgore",
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
    ["Terrowulf Chef-de-meute"] = "Orneval",
    ["Ursol'lok"] = "Orneval",
    ["Slitherblade maudit"] = "Désolace",
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
    ["Ironeye l'Invincible"] = "Mille Pointes",
    ["Ravageur silithide"] = "Mille Pointes",
    ["Dard-vil"] = "Mille Pointes",
    ["Brimgore"] = "Marécage d'Âprefange",
    -- Mor'Ladim : Duskwood (mal classé aux Carmines avant)
    ["Mor'Ladim"] = "Bois de la Pénombre",
    ["Burgle Eye"] = "Marécage d'Âprefange",
    ["Veuve de la Brume-noire"] = "Marécage d'Âprefange",
    ["Dart"] = "Marécage d'Âprefange",
    ["Drogoth le Rôdeur"] = "Marécage d'Âprefange",
    ["Hayoc"] = "Marécage d'Âprefange",
    ["Seigneur Pêche-à-la-ligne"] = "Marécage d'Âprefange",
    ["Ver-de-limace"] = "Marécage d'Âprefange",
    ["Écaille-déchirée"] = "Marécage d'Âprefange",
    ["La Pourriture"] = "Marécage d'Âprefange",
    ["Grukk"] = "Tanaris",
    ["Croquesable"] = "Tanaris",
    ["Cyclok le Fou"] = "Tanaris",
    ["Oiseau de feu supérieur"] = "Tanaris",
    ["Haarka le Vorace"] = "Tanaris",
    ["Jin'Zallah le Porte-sable"] = "Tanaris",
    ["Kregg Keelhaul"] = "Tanaris",
    ["Patte-ampoule meurtrière"] = "Tanaris",
    ["Omgorn l'Égaré"] = "Tanaris",
    ["Soriid le Dévoreur"] = "Tanaris",
    ["Chef de guerre Krazzilak"] = "Tanaris",
    ["Antilus le Planieur"] = "Féralas",
    ["Arash-ethis"] = "Féralas",
    ["Bloodroar le Traqueur"] = "Féralas",
    ["Tête-de-diamant"] = "Féralas",
    ["Gnarl Frère-des-feuilles"] = "Féralas",
    ["Dame Szallah"] = "Féralas",
    ["Vieux Ventre-grison"] = "Féralas",
    ["Qirot"] = "Féralas",
    ["Grondeur"] = "Féralas",
    ["Sablonneux"] = "Gangrebois",
    ["Alshirr Souffle-de-fléau"] = "Gangrebois",
    ["Hurlement de mort"] = "Gangrebois",
    ["Dessecus"] = "Gangrebois",
    ["Immolatus"] = "Gangrebois",
    ["Mongress"] = "Gangrebois",
    ["Olm le Sage"] = "Gangrebois",
    ["Patte-enragée"] = "Gangrebois",
    ["L'Ongar"] = "Gangrebois",
    ["Mère de couvée Zavas"] = "Cratère d'Un'Goro",
    ["Gruff"] = "Cratère d'Un'Goro",
    ["Roi Mosh"] = "Cratère d'Un'Goro",
    ["Matriarche Croc-rasoir"] = "Cratère d'Un'Goro",
    ["Uhk'loc"] = "Cratère d'Un'Goro",
    ["Gretheer"] = "Silithus",
    ["Grubthor"] = "Silithus",
    ["Huricanian"] = "Silithus",
    ["Krellack"] = "Silithus",
    ["Lapress"] = "Silithus",
    ["Rex Ashil"] = "Silithus",
    ["Setis"] = "Silithus",
    ["Seigneur du Crépuscule Everun"] = "Silithus",
    ["Zora"] = "Silithus",
    ["Antilos"] = "Azshara",
    ["Gardien Rageroar"] = "Azshara",
    ["Général Fangferror"] = "Azshara",
    ["Dame Sesspira"] = "Azshara",
    ["Magistère Heaume-faucon"] = "Azshara",
    ["Maître Feardred"] = "Azshara",
    ["Monnos l'Ancien"] = "Azshara",
    ["Écaillebarbe"] = "Azshara",
    ["L'Evalcharr"] = "Azshara",
    ["Fantôme de Varo'then"] = "Azshara",
    ["Azurous"] = "Hiverpré",
    ["Général Colbatann"] = "Hiverpré",
    ["Grizzle Patte-des-neiges"] = "Hiverpré",
    ["Kashoch le Ravageur"] = "Hiverpré",
    ["Mezzir le Hurleur"] = "Hiverpré",
    ["Rak'shiri"] = "Hiverpré",
    ["Sian-Rotam"] = "Hiverpré",
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
    ["Commandant Felstrom"] = "Bois de la Pénombre",
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
    ["Benj l'Aigri"] = "Montagnes d'Alterac",
    ["Gravis Noeud-coulant"] = "Montagnes d'Alterac",
    ["Jimmy le Saignant"] = "Montagnes d'Alterac",
    ["Lo'Grosh"] = "Montagnes d'Alterac",
    ["Narillasanz"] = "Montagnes d'Alterac",
    ["Skhowl"] = "Montagnes d'Alterac",
    ["Furie-de-pierre"] = "Montagnes d'Alterac",
    ["Darbel Montrose"] = "Hautes-terres d'Arathi",
    ["Ventre-immonde"] = "Hautes-terres d'Arathi",
    ["Géomancien Silex-dague"] = "Hautes-terres d'Arathi",
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
    ["Grosse patte"] = "Marais des chagrins",
    ["Fingat"] = "Marais des chagrins",
    ["Gilmorian"] = "Marais des chagrins",
    ["Capitaine-seigneur Wyrmak"] = "Marais des chagrins",
    ["Chef des Perdus"] = "Marais des chagrins",
    ["Cuisinier des Perdus"] = "Marais des chagrins",
    ["Molt Thorn"] = "Marais des chagrins",
    ["7:XT"] = "Terres ingrates",
    ["Anathemus"] = "Terres ingrates",
    ["Croc-Cassé"] = "Terres ingrates",
    ["Rumbler"] = "Terres ingrates",
    ["Commandant de l'Ombreforge"] = "Terres ingrates",
    ["Golem de siège"] = "Terres ingrates",
    ["Golem de guerre"] = "Terres ingrates",
    ["Zaricotl"] = "Terres ingrates",
    ["Golem de guerre défectueux"] = "Gorge des Vents brûlants",
    ["Généralissime Mastrogonde"] = "Gorge des Vents brûlants",
    ["Rekk'tilac"] = "Gorge des Vents brûlants",
    ["Scald"] = "Gorge des Vents brûlants",
    ["Shleipnarr"] = "Gorge des Vents brûlants",
    ["Maître des esclaves Coeur-noir"] = "Gorge des Vents brûlants",
    ["Smoldar"] = "Gorge des Vents brûlants",
    ["Fourbasse"] = "Steppes ardentes",
    ["Gueule-de-mort"] = "Steppes ardentes",
    ["Gorgon'och"] = "Steppes ardentes",
    ["Gruklash"] = "Steppes ardentes",
    ["Hahk'Zor"] = "Steppes ardentes",
    ["Hematos"] = "Steppes ardentes",
    ["Ravageur défectueux"] = "Steppes ardentes",
    ["Étincelle-terreur"] = "Steppes ardentes",
    ["Thauris Balgarr"] = "Steppes ardentes",
    ["Volchan"] = "Steppes ardentes",
    ["Akubar le Voyant"] = "Terres foudroyées",
    ["Clack le Ravageur"] = "Terres foudroyées",
    ["Oeil-de-mort"] = "Terres foudroyées",
    ["Dreadscorn"] = "Terres foudroyées",
    ["Grunter"] = "Terres foudroyées",
    ["Magronos l'Inflexible"] = "Terres foudroyées",
    ["Mojo le Tordu"] = "Terres foudroyées",
    ["Ravage"] = "Terres foudroyées",
    ["Spiteflayer"] = "Terres foudroyées",
    ["Murmure-effroi"] = "Maleterres de l'Ouest",
    ["Crinière-immonde"] = "Maleterres de l'Ouest",
    ["Seigneur Maldazzar"] = "Maleterres de l'Ouest",
    ["Bourreau écarlate"] = "Maleterres de l'Ouest",
    ["Haut clerc écarlate"] = "Maleterres de l'Ouest",
    ["Interrogateur écarlate"] = "Maleterres de l'Ouest",
    ["Juge écarlate"] = "Maleterres de l'Ouest",
    ["Forgeron écarlate"] = "Maleterres de l'Ouest",
    ["La Carcasse"] = "Maleterres de l'Ouest",
    ["Duggan Marteau-hardi"] = "Maleterres de l'Est",
    ["Gish l'Immobile"] = "Maleterres de l'Est",
    ["Hed'mush le Pourrissant"] = "Maleterres de l'Est",
    ["Grand général Abbendis"] = "Maleterres de l'Est",
    ["Seigneur Faux-sombre"] = "Maleterres de l'Est",
    ["Contremaître nérubien"] = "Maleterres de l'Est",
    ["Seigneur traqueur Lance-faucon"] = "Maleterres de l'Est",
    ["Seigneur de guerre Thresh'jin"] = "Maleterres de l'Est",
    ["Zul'Brin Rameau-tordu"] = "Maleterres de l'Est",
    ["Grimungous"] = "Les Hinterlands",
    ["Dos-de-fer"] = "Les Hinterlands",
    ["Jalinde Drake-d'été"] = "Les Hinterlands",
    ["Mith'rethis l'Enchanteur"] = "Les Hinterlands",
    ["Vieux Sauteur-de-falaises"] = "Les Hinterlands",
    ["Razortalon"] = "Les Hinterlands",
    ["Retherokk le Berserker"] = "Les Hinterlands",
    ["Le Reak"] = "Les Hinterlands",
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
    { id = "decouverte", cat = "Exploration",     tex = "Spell_Arcane_StarFire",        nom = L("Première découverte"),   desc = L("Découvrir un rare inconnu (mode auto)") },
    { id = "explorateur",cat = "Exploration",     tex = "Spell_Nature_Thorns",          nom = L("Traqueur des profondeurs"), desc = L("Découvrir 5 rares inconnus") },
    -- Légendes locales
    { id = "brachland",  cat = L("Légendes locales"), tex = "Ability_Hunter_BeastTaming",  nom = L("Toute une panoplie"),    desc = L("Tuer Humar, Vif-Crinière et Takk — les trois fiertés des plaines") },
    { id = "rotheap",    cat = L("Légendes locales"), tex = "Spell_Frost_FrostBolt",      nom = L("Ami des profondeurs"),   desc = L("Tuer Rotheap dans les Paluns") },
    -- Les éléments (météo Forever via C_Weather)
    { id = "pluie",      cat = L("Les éléments"),      tex = "Spell_Frost_Frostbolt",        nom = L("Danse de la pluie"),     desc = L("Réussir une chasse sous la pluie") },
    { id = "feu",        cat = L("Les éléments"),      tex = "Spell_Fire_FireBolt",          nom = L("Chasseur de l'apocalypse"), desc = L("Réussir une chasse pendant une pluie de feu") },
    { id = "neige",      cat = L("Les éléments"),      tex = "Spell_Frost_FrostArmor",       nom = L("Traqueur des neiges"),   desc = L("Réussir une chasse sous la neige") },
    -- La ménagerie
    { id = "amidevoue",  cat = L("La ménagerie"), tex = "Ability_Hunter_BeastTaming", nom = L("Ami dévoué"), desc = L("Amener un pensionnaire à 100 d'affinité") },
    { id = "encloscomplet", cat = L("La ménagerie"), tex = "INV_Misc_Cage_01", nom = L("Enclos complet"), desc = L("Avoir tous les spécimens de la savane en enclos") },
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
    local n = 0
    for _ in pairs(DB.decouverts) do n = n + 1 end
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
    local t = CreateFrame("Frame", nil, UIParent)
    t:SetSize(380, 64)
    -- Position : sous le bandeau « CHASSE RÉUSSIE » (bas à -210). En mode
    -- texture custom, le bandeau « EN CHASSE » (660x210 ancré à -60)
    -- descend jusqu'à -270 : on descend le toast sous lui.
    local yToast = (DB.config.texUI == "custom") and -300 or -230
    t:SetPoint("TOP", UIParent, "TOP", 0, yToast)
    t:SetFrameStrata("HIGH")
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
    icone:SetPoint("LEFT", 14, 6)
    icone:SetTexture(texPath or "Interface\\Icons\\INV_Misc_QuestionMark")
    local tex = t:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tex:SetPoint("LEFT", 62, 8)
    tex:SetText("|cffffd100" .. nom .. "|r")
    local tdx = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tdx:SetPoint("LEFT", 64, -12)
    tdx:SetText(desc)
    C_Timer.After(5, function()
        for i = 1, 10 do
            C_Timer.After(i * 0.1, function() t:SetAlpha(1 - i / 10) end)
        end
        C_Timer.After(1.2, function()
            t:Hide()
            -- Suite de la file : au toast suivant s'il en reste
            ToastSuccesSuivant()
        end)
    end)
    if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 888) end
end
local function ToastSucces(texPath, nom, desc)
    fileToasts[#fileToasts + 1] = { texPath, nom, desc }
    if not toastEnCours then ToastSuccesSuivant() end
end

-- Toast « Cible du jour » : bandeau cliquable à la connexion, façon
-- panneau d'annonce de prime MH. Clic = ouvrir le carnet sur l'Accueil.
local function ToastCibleDuJour(nom, zone)
    local t = CreateFrame("Frame", nil, UIParent)
    -- Notification compacte coin haut-droit : pas de grand encart centré,
    -- l'info reste discrète (l'icône donne l'accent, le texte habille).
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
            ToastSucces("Interface\\Icons\\" .. (s.tex or "INV_Misc_QuestionMark"), s.nom, s.desc)
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
    ["Mor'Ladim"] = L("Cette chose rode dans le cimetière des Bois de la Pénombre. Les gardes n'osent plus y descendre."),
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
MHH_NOM_AFFICHAGE = {}
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

-- Identification automatique par NPC id : le GUID contient l'ID, qui ne
-- dépend pas de la langue du client ni des traductions approximatives du
-- serveur. Dès qu'une bête du data file est ciblée ou survolée, son nom
-- EXACT en jeu est appris et inscrit au carnet — aucun /run manuel.
local function ApprendreParId(unite)
    local guid = UnitGUID(unite)
    if not guid then return end
    local idR = tonumber(guid:match("-(%d+)$"))
    if not idR or not MHH_RARES_PAR_ID[idR] then return end
    local nom = UnitName(unite) or ""
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
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Identifié par l'ID ") .. idR .. " : |cffffff00"
        .. nom .. "|r (" .. (e.nomEn or e.nom or "?") .. L(") — inscrit au carnet."))
    DebloquerSucces("decouverte")
end

-- ============================================
-- 3ter. MÉNAGERIE : spécimens capturables (pixel art)
-- ============================================
-- La capture façon MH : tuer la bête pendant qu'elle est prise dans un
-- piège. Seuls ces spécimens rejoignent l'enclos (onglet Ménagerie).
-- Dessin = grille 16x16, un caractère par pixel ('.' = transparent),
-- palette par monstre. Rendu : textures SetColorTexture, aucune image.
MHH_SPECIMENS = {
    ["Humar le Seigneur hautain"] = {
        famille = L("Félin"),
        palette = { ["@"] = {0.05,0.04,0.06}, ["#"] = {0.14,0.12,0.14},
                    ["o"] = {1.0,0.85,0.3}, ["+"] = {0.9,0.75,0.65} },
        lignes = {
            "................",
            "....@@@.........",
            "...@@@@@........",
            "..@@###@@.......",
            "..@#####@.......",
            "..@##o##@.......",
            "...##+##........",
            "...@@@@@........",
            "..@@#####@@.....",
            ".+@@#######@....",
            "+..#########....",
            "...#########....",
            "...#..#...#.....",
            "...#..#...#.....",
            "...#..#...#.....",
            "................",
        },
    },
    ["Takk le Bondisseur"] = {
        famille = "Raptor",
        palette = { ["@"] = {0.55,0.35,0.12}, ["#"] = {0.25,0.20,0.18},
                    ["o"] = {1.0,0.9,0.2}, ["+"] = {0.5,0.42,0.3} },
        lignes = {
            "..............@.",
            ".....@.......@@.",
            "....@@......@#..",
            "....@#.....@#...",
            "....##o....@#...",
            "....###...@#....",
            "....+##..@##....",
            ".....##@###.....",
            "....########....",
            "....#+######....",
            ".....########...",
            "......##..##....",
            "......#....#....",
            "......#....#....",
            "......#....#....",
            "................",
        },
    },
    ["Mazzranache"] = {
        famille = "Haut-traqueur",
        palette = { ["@"] = {0.95,0.55,0.72}, ["#"] = {0.93,0.45,0.66},
                    ["o"] = {1,1,1}, ["+"] = {1,0.8,0.25} },
        lignes = {
            "..@+............",
            "..@o............",
            "..@#............",
            "..@#............",
            "...@#...........",
            "...@#...........",
            "...@###@........",
            "....#####.......",
            "..#########.....",
            "..##########....",
            "..##########....",
            "...#########....",
            "...#..#..#......",
            "...#..#..#......",
            "...#..#..#......",
            "................",
        },
    },
    ["Sarkoth"] = {
        famille = "Scorpide",
        palette = { ["@"] = {0.35,0.22,0.10}, ["#"] = {0.5,0.35,0.15},
                    ["o"] = {0.5,1.0,0.5}, ["+"] = {0.6,0.8,0.3} },
        lignes = {
            "................",
            "................",
            "............@@..",
            "...........@+...",
            "...........@....",
            "..........@.....",
            "..........@.....",
            "..........@.....",
            "@@@.....o@#@....",
            "@.@#########....",
            "@.@#########....",
            "..@#########....",
            "..##.##.##......",
            "..#..#..#..#....",
            "................",
            "................",
        },
    },
    ["Flagglemurk le Cruel"] = {
        famille = "Murloc",
        palette = { ["@"] = {0.18,0.42,0.24}, ["#"] = {0.30,0.62,0.35},
                    ["o"] = {1,1,1}, ["+"] = {0.9,0.8,0.7} },
        lignes = {
            "......@.........",
            ".....@..........",
            "....#####.......",
            "...##o##o##.....",
            "...###+###......",
            "...########.....",
            "...########.....",
            "..+########+....",
            "....######......",
            "....######......",
            "....######......",
            "....######......",
            "....##..##......",
            "....##..##......",
            "....@#..#@......",
            "................",
        },
    },
    ["Naraxis"] = {
        famille = L("Araignée"),
        palette = { ["@"] = {0.30,0.07,0.32}, ["#"] = {0.48,0.12,0.5},
                    ["o"] = {1,0.3,0.3} },
        lignes = {
            "................",
            "........@.......",
            ".@@....##....@@.",
            "..@...####...@..",
            "..@..##o##..@...",
            "...@.######.@...",
            "...@.######.@...",
            "..@..######..@..",
            ".@...######...@.",
            ".@...######...@.",
            "..@...####...@..",
            "...@@......@@...",
            "................",
            "................",
            "................",
            "................",
        },
    },
    ["Snarlflare"] = {
        famille = "Dragonnet",
        palette = { ["@"] = {0.45,0.15,0.12}, ["#"] = {0.16,0.13,0.14},
                    ["o"] = {1,0.5,0.1}, ["+"] = {0.85,0.4,0.15} },
        lignes = {
            "................",
            "......@....@....",
            "......@@..@@....",
            ".....@@@.@@@....",
            "...#o##@@@......",
            "...####.@@......",
            "...+####@.......",
            "....########....",
            "....#########...",
            "....+#########..",
            ".....##########.",
            "......##...##...",
            "......##...##...",
            "......##...##...",
            "................",
            "................",
        },
    },
    ["Mor'Ladim"] = {
        famille = "Mort-vivant",
        palette = { ["@"] = {0.75,0.72,0.6}, ["#"] = {0.92,0.9,0.8},
                    ["o"] = {0.35,0.7,1.0}, ["+"] = {0.6,0.6,0.68} },
        lignes = {
            "................",
            "....@@@.........",
            "...@o#o@........",
            "...@###@........",
            "....@@@.........",
            "...@###@.@......",
            "..@#####@#......",
            "..@##+##@#......",
            "..@##+##@#......",
            "..@#####@#......",
            "...#####@#......",
            "....#.#..#......",
            "....#.#..#......",
            "....#.#..#......",
            "...@#.#@.#@.....",
            "................",
        },
    },
    ["Capitaine Croc-Plat"] = {
        famille = "Sanglier",
        palette = { ["@"] = {0.10,0.07,0.05}, ["#"] = {0.45,0.30,0.18},
                    ["o"] = {1,0.95,0.85} },
        lignes = {
            "................",
            "...@@...........",
            "..@##@..........",
            "..@###@.....@...",
            ".@o####@....@#..",
            ".@######@...@##.",
            "@########@..@##.",
            "@#########@.@##.",
            "@##########@##@.",
            "@###@@########@.",
            ".@###@..@#####@.",
            ".@#####@#####@..",
            "..@##@.@###@o@..",
            "...@@..@##@.@...",
            "........@@..@...",
            "................",
        },
    },
    ["Grand crocolisque du loch"] = {
        famille = "Crocolisque",
        palette = { ["@"] = {0.05,0.12,0.08}, ["#"] = {0.25,0.45,0.25},
                    ["o"] = {1,1,1}, ["+"] = {0.55,0.70,0.45} },
        lignes = {
            "................",
            ".............@..",
            "....@@......@#..",
            "...@##@....@##..",
            "..@o##@...@##...",
            ".@######@@##@...",
            "@#############..",
            "@##+#########@..",
            ".@##+########@..",
            ".@###@######@...",
            "..@o@@..@##@o...",
            "..@@..@#@..@....",
            "....@#.@#..@#...",
            "....@#.@#...@#..",
            ".....@..@...@#..",
            "................",
        },
    },
}
-- Ordre stable d'affichage dans l'enclos
MHH_SPECIMENS_ORDRE = {
    "Humar le Seigneur hautain", "Takk le Bondisseur",
    "Mazzranache", "Sarkoth", "Flagglemurk le Cruel", "Naraxis",
    "Snarlflare", "Mor'Ladim",
    "Capitaine Croc-Plat", "Grand crocolisque du loch",
}

-- ENCLOS PAR BIOME : chaque pensionnaire vit dans le biome de son habitat.
-- Un enclos se DÉBLOQUE au fil du rang de guilde — le régisseur agrandit
-- le ranch. Le fond de l'enclos change avec le biome sélectionné.
MHH_ENCLOS = {
    { cle = "savane",   nom = L("Enclos de la savane"),   rang = 1,
      specimens = { "Humar le Seigneur hautain", "Takk le Bondisseur",
                    "Mazzranache", "Sarkoth" } },
    { cle = "marais",   nom = L("Enclos des marais"),     rang = 2,
      specimens = { "Flagglemurk le Cruel", "Naraxis",
                    "Grand crocolisque du loch" } },
    { cle = "montagne", nom = L("Enclos des montagnes"), rang = 3,
      specimens = { "Capitaine Croc-Plat", "Snarlflare", "Mor'Ladim" } },
    { cle = "volcan",   nom = L("Enclos du volcan"),     rang = 4,
      specimens = {} }, -- les pensionnaires y sont déplacés à la main
}
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
local ZoneAvecAmiDevoue -- affinité ménagerie : bonus de zone (section ménagerie)
local Affinite -- jauge d'affinité d'un pensionnaire (section ménagerie)
local dernierJingleTemps -- horodatage du dernier carillon (protège le cut SFX différé)
-- Chasse suspendue (cible perdue hors combat, bête enfuie) : on garde tout
-- pour REPRENDRE la chasse là où elle en était si on re-cible la bête
-- rapidement — le chrono n'est PAS remis à zéro.
local chasseSuspendue = nil -- { nom, debutTemps, debutVie, niveau, rare, piegee }
local chasseDebutVie = nil -- vie du chasseur au début de la chasse
local chasseVieTouchee = false -- vie passée sous son niveau de départ (suivi UNIT_HEALTH)
local chasseNiveau = nil   -- niveau du monstre chassé
local chasseRare = false   -- le monstre chassé est-il rare ?
local chasseDebutTemps = nil -- début du chronomètre
local chassePiegee = false   -- le monstre est-il pris dans un piège ?
local dernierTrigger = {} -- anti-spam bannière (30 s par monstre)
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
        DEFAULT_CHAT_FRAME:AddMessage("|cff6aaaff[MH Hunt DBG]|r " .. canal .. " — " .. tostring(texte))
    end
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
        if not UnitAffectingCombat("player") then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffa0ff50Chasse reprise :|r " .. nom .. L(" — le chrono continue."))
        end
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
    chasseActive = nom
    chasseDebutVie = UnitHealth("player")
    chasseVieTouchee = false -- nouveau départ : remise à zéro du suivi
    chasseNiveau = niveau
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
    -- s'efface en fondu — reste seulement le mini chrono en coin
    if BandeauChasseEphemer then BandeauChasseEphemer() end
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
        cible = "Veuve de la Brume-noire", zone = "Marécage d'Âprefange",
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
    ["Dagues"] = "Dagues", ["Epées"] = "Epées",
    ["Epées à deux mains"] = "Epées 2M", ["Masses"] = "Masses",
    ["Masses à deux mains"] = "Masses 2M", ["Haches"] = "Haches",
    ["Haches à deux mains"] = "Haches 2M", ["Armes de pugilat"] = "Pugilat",
    ["Armes d'hast"] = "Hast", ["Arcs"] = "Arcs",
    ["Arbalètes"] = "Arb.", ["Bâtons"] = "Bâtons",
    ["Baguettes"] = "Bagu.", ["Armes à feu"] = "Fusils",
}
-- Normalisation : le client FR écrit parfois « Epées » ou « Épées » (accent),
-- et le tooltip peut coller la classe de l'arme en majuscules.
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

local function FinChasseVictoire(nom)
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
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffa0ff50Contrat rempli : " .. nom .. L(" !|r (+") .. (DB.contratPrime or 20) .. L(" points)"))
    else
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffa0ff50Chasse réussie : ") .. nom .. " !|r (" .. info.kills .. L(" chasses") .. nomMeteoAnnonce .. ")")
    end
    -- La musique de chasse s'arrête à la prise : sans cet arrêt explicite,
    -- la piste de combat continuait jusqu'au relais suivant quand le kill
    -- était validé PENDANT le combat (UNIT_DIED / viseur) — REGEN_ENABLED
    -- ne la stoppait que si le joueur était déjà sorti du combat.
    MHH_ArreterMusique()
    if DB.config.son and JouerJingleVictoire then JouerJingleVictoire() end
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
    -- Taille du gabarit façon MH : hitbox du client (UnitBoundingRadius,
    -- renvoyée en mètres) + variation aléatoire cohérente (85 %–130 %).
    -- Couronne d'argent dès 105 %, d'or à 115 % ; record mémorisé.
    -- Tout sous pcall : les « secret numbers » de Midnight peuvent
    -- interdire l'arithmétique sur cette valeur — l'échec est muet.
    pcall(function()
        local b = UnitBoundingRadius and UnitBoundingRadius("target")
        if type(b) == "number" and b > 0 then
            local facteur = 0.85 + math.random() * 0.45
            local taille = math.floor(b * facteur * 100 + 0.5) / 100
            info.taille = taille
            if not info.tailleRecord or taille > info.tailleRecord then
                info.tailleRecord = taille
            end
            local couronne
            if facteur >= 1.15 then couronne = "or"
            elseif facteur >= 1.05 then couronne = "argent" end
            if couronne then
                if couronne == "or" or info.couronne ~= "or" then
                    info.couronne = couronne
                end
            end
            local libelle = L("Gabarit mesuré : |cffffff00") .. taille .. L(" unités|r")
            if couronne == "or" then
                ToastSucces("Interface\\Icons\\INV_Misc_MonsterClaw_04",
                    L("Mesure du gabarit"), libelle .. L(" — |cffffcc44COURONNE D'OR !|r"))
            elseif couronne == "argent" then
                ToastSucces("Interface\\Icons\\INV_Misc_MonsterClaw_04",
                    L("Mesure du gabarit"), libelle .. L(" — |cffc0c0c0couronne d'argent|r"))
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. libelle)
            end
        end
    end)
    -- Arme du coup : l'arme tenue en main principale au moment de la prise
    -- alimente l'histogramme de la carte de guilde (armes les plus
    -- utilisées). Triple source : lien d'objet, identifiant, puis nom —
    -- sur ce client le cache d'objet peut manquer pour l'une mais pas
    -- l'autre. Échec = trace /hunt debug (plus jamais muet).
    do
        local sousClasseArme = nil
        pcall(function()
            -- Lien d'abord, id en repli — sousClasseDe corrige l'indice
            -- (8e valeur ; via pcall la capture n = valeur n-1).
            sousClasseArme = NormaliserTypeArme(sousClasseDe(GetInventoryItemLink and GetInventoryItemLink("player", 16)))
                or NormaliserTypeArme(sousClasseDe(GetInventoryItemID and GetInventoryItemID("player", 16)))
            -- Source 2 : le TOOLTIP de l'objet en main droite. Sur ce
            -- client le cache d'objet renvoyé par GetItemInfo est souvent
            -- VIDE (nil sur lien ET id), alors que le tooltip, lui, rend
            -- toujours les lignes réelles. La 2e ligne du tooltip est la
            -- sous-classe (« Haches », « Épées »… en client FR) — c'est
            -- la valeur exacte que l'histogramme veut compter.
            if not sousClasseArme and GameTooltip then
                -- Scan de TOUTES les lignes du tooltip : la ligne du type
                -- d'arme (« Haches », « Dagues »…) n'est pas toujours la 2e
                -- (le « Niveau d'objet » s'y glisse selon les clients) et
                -- « Niveau d'objet » n'est PAS un type. On cherche la
                -- première ligne qui matche un type canonique.
                GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                GameTooltip:ClearLines()
                GameTooltip:SetInventoryItem("player", 16)
                for lig = 1, math.min(GameTooltip:NumLines(), 8) do
                    local fs = _G["GameTooltipTextLeft" .. lig]
                    local txt = fs and fs.GetText and fs:GetText()
                    if txt and txt ~= "" and not string.find(string.lower(txt), "niveau d", 1, true) then
                        local norm = NormaliserTypeArme(txt)
                        -- garder seulement si reconnu canonique
                        for _, canon in ipairs(MHH_TYPES_ARMES) do
                            if norm == canon then sousClasseArme = canon break end
                        end
                        if sousClasseArme then break end
                    end
                end
                GameTooltip:Hide()
            end
        end)
        DB.armes = DB.armes or {}
        if sousClasseArme then
            DB.armes[sousClasseArme] = (DB.armes[sousClasseArme] or 0) + 1
        else
            DebugChasse("armes", L("arme non identifiée à la prise (essais GetItemInfo vides)"))
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
    -- Trophée façon MH (carving) : une pièce prélevée sur la dépouille
    local PIECES = {
        { nom = "croc",      article = "un"  },
        { nom = "plume",     article = "une" },
        { nom = "écaille",   article = "une" },
        { nom = "carapace",  article = "une" },
        { nom = "patte",     article = "une" },
    }
    local piece = PIECES[((info.kills or 1) - 1) % #PIECES + 1]
    DB.trophees = DB.trophees or {}
    DB.trophees[piece.nom] = (DB.trophees[piece.nom] or 0) + 1
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Trophée prélevé : ") .. piece.article .. " " .. piece.nom .. ".")
    -- Cuisine : récolte sur la dépouille (viande 40%, miel 10% sur rare)
    if math.random(100) <= 40 then
        DB.viande = (DB.viande or 0) + 1
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Récolte : |cffff7a1a1 viande de gibier|r."))
    end
    if chasseRare and math.random(100) <= 10 then
        DB.miel = (DB.miel or 0) + 1
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Récolte : |cffff7a1a1 miel sauvage|r !"))
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
    -- Capture façon MH : la bête prise au piège rejoint la ménagerie
    -- (seuls les spécimens pixel art de l'enclos sont capturables)
    if chassePiegee and MHH_SPECIMENS[nom] then
        DB.menagerie = DB.menagerie or {}
        local m = DB.menagerie[nom]
        if not m then
            DB.menagerie[nom] = { capture = time(), nourri = time() }
            -- Grande annonce dorée : la capture est un moment MH, pas un
            -- simple message discret. Bandeau + toast deux lignes.
            AfficherBanniere(L("SPÉCIMEN CAPTURÉ !"), 0.95, 0.78, 0.25)
            ToastSucces("Interface\\Icons\\Ability_Hunter_BeastTaming",
                L("Spécimen capturé"), nom .. L(" rejoint l'enclos (Ménagerie)."))
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff7a1aSpécimen captéré !|r ")
                .. nom .. L(" est transféré dans l'enclos (onglet Ménagerie)."))
        else
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
        ToastSucces("Interface\\Common\\ReputationStar", L("Promotion de guilde"), L("Nouveau rang : ") .. nomRang)
        -- Sommet atteint : la Blackrock orchestrée remplace la fanfare —
        -- elle ne jouera qu'ici, à ce moment précis. Une seule fois.
        if MHH_RANGS and nouvelIdx == #MHH_RANGS then
            MHH_JouerMusique("promotion", MHH_PISTE_RANG_MAX.d, tostring(MHH_PISTE_RANG_MAX.id))
        else
            MHH_JouerMusique("promotion", 45)
        end
    end
end

local function FinChasseEchec()
    -- Échec aussi si la chasse venait d'être suspendue (mort du chasseur :
    -- la cible se perd AVANT que PLAYER_DEAD n'arrive — sinon la suspension
    -- survivait à la mort et se « reprenait » au cimetière)
    if not chasseActive and not chasseSuspendue then return end
    local nom = chasseActive or (chasseSuspendue and chasseSuspendue.nom) or "?"
    DebugChasse("echec", nom)
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff5050Chasse échouée : ") .. nom .. "|r")
    AfficherBanniere(L("CHASSE ÉCHOUÉE"), 1, 0.3, 0.3)
    -- Le chasseur s'écroule, façon MH quand le monstre s'échappe :
    -- emote de perte de connaissance si le client la connaît, sinon rien
    if not pcall(DoEmote, "faint") then pcall(DoEmote, "flop") end
    if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_FAILED or 845) end
    MHH_ArreterMusique() -- stoppe la musique et rend le décor sonore au jeu
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
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffa58b54La trace de " .. nom .. L(" se perd…|r Chasse suspendue — re-ciblez-la pour reprendre."))
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
local cercleCarte, cercleTicker, MHH_timerCercle
local function CacherCercleCarte()
    if MHH_timerCercle then MHH_timerCercle:Cancel() MHH_timerCercle = nil end
    if cercleTicker then cercleTicker:Cancel() cercleTicker = nil end
    if cercleCarte then cercleCarte:Hide() end
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
        if not cercleCarte then
            cercleCarte = CreateFrame("Frame", nil, canvas)
            cercleCarte:SetSize(96, 96)
            -- AU-DESSUS de l'art de la carte : sans strate haute, le disque
            -- reste DERRIÈRE la texture de la carte — invisible. C'est le
            -- probable coupable du ping jamais vu (le son jouait, le
            -- cercle se cachait derrière la peinture).
            pcall(function() cercleCarte:SetFrameStrata("HIGH") end)
            pcall(function() cercleCarte:SetFrameLevel(20) end)
            -- Zone ronde lisible sur tous les clients : un disque
            -- translucide + un anneau de points dessinés en textures
            -- (le MiniMap-TrackingBorder seul peut ne pas s'afficher)
            local fond = cercleCarte:CreateTexture(nil, "BACKGROUND")
            fond:SetAllPoints()
            fond:SetColorTexture(1, 0.82, 0.25, 0.13)
            for i = 0, 23 do
                local a = i * math.pi / 12
                local pt = cercleCarte:CreateTexture(nil, "OVERLAY")
                pt:SetSize(6, 6)
                pt:SetPoint("CENTER", math.cos(a) * 42, math.sin(a) * 42)
                pt:SetColorTexture(1, 0.75, 0.15, 0.95)
            end
            local t = cercleCarte:CreateTexture(nil, "OVERLAY")
            t:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            t:SetAllPoints()
            cercleCarte.texture = t
            -- le cercle disparaît avec la carte
            WorldMapFrame:HookScript("OnHide", CacherCercleCarte)
        end
        -- position en fraction de la carte (0-1) → pixels du canevas
        cercleCarte:ClearAllPoints()
        cercleCarte:SetPoint("CENTER", canvas, "TOPLEFT",
            x * canvas:GetWidth(), y * canvas:GetHeight())
        cercleCarte:SetAlpha(1)
        cercleCarte:SetScale(1)
        cercleCarte:Show()
        -- Animation « ping sonar » : l'anneau se DILATE depuis le point
        -- tout en s'estompant, puis repart — le mouvement qu'on attend
        -- d'un ping, maintenant qu'on l'entend aussi (cycle d'une seconde).
        if cercleTicker then cercleTicker:Cancel() end
        local phase = 0
        cercleTicker = C_Timer.NewTicker(0.04, function()
            if not cercleCarte or not cercleCarte:IsShown() then return end
            phase = phase + 0.025
            if phase >= 1 then phase = 0 end
            cercleCarte:SetScale(1 + phase * 0.5) -- se dilate : 1 -> 1,5
            cercleCarte:SetAlpha(1 - phase * 0.7)  -- s'estompe : 1 -> 0,3
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
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Carte introuvable pour « " .. zone .. L(" » (nom de zone inconnu du client ?)."))
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
                    C_Map.SetUserWaypoint({ uiMapID = idCarte, position = { x = point.x, y = point.y } })
                    if C_SuperTrack and C_SuperTrack.AddSuperTrackedUserWaypoint then
                        pcall(C_SuperTrack.AddSuperTrackedUserWaypoint)
                    end
                end
                -- Cercle placé une frame plus tard : juste après SetMapID le
                -- canvas n'a pas toujours encore ses nouvelles dimensions —
                -- le marqueur atterrissait alors au mauvais endroit
                if MHH_timerCercle then MHH_timerCercle:Cancel() end
                local px, py = point.x, point.y
                MHH_timerCercle = C_Timer.After(0.05, function()
                    PlacerCercleCarte(px, py)
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
    { id = 4423094, d = 119 }, -- Celestial battle
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
-- Tempo avant la musique de combat : le jingle « En chasse » doit finir
-- seul (pas de cacophonie). Un seul timer pendante à la fois.
local timerMusiqueCombat = nil

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
    if musiqueTimer then pcall(function() musiqueTimer:Cancel() end) musiqueTimer = nil end
    -- Le décor sonore du jeu revient (musique + ambiance restaurées)
    RestaurerSonAmbiant()
    -- Coupure franche SI le client renvoie un handle sur PlaySoundFile
    -- (pas de fondu possible sur le canal SFX de ce client — on essaie
    -- FadeOut si présent, sinon Stop ; souvent aucune des deux n'existe
    -- et la piste finit naturellement, ce qui reste le plus propre).
    if musiqueHandle then
        pcall(function()
            if musiqueHandle.FadeOut then musiqueHandle:FadeOut(1000)
            elseif musiqueHandle.Stop then musiqueHandle:Stop() end
        end)
        musiqueHandle = nil
    end
    -- Filet anti-piste fantôme : sans handle, un son de FICHIER continue
    -- jusqu'au bout — impossible à stopper proprement. Mais un son de
    -- fichier ne REPREND jamais après un mute : couper le canal SFX
    -- 0,15 s le tue net, et l'ambiance du jeu revient dès la réouverture.
    -- Différé de 2,5 s (laisser finir un éventuel fondu), et SKIP si une
    -- nouvelle piste a démarré entre-temps (on la tuerait aussi) ou si
    -- le carillon de victoire sonne encore.
    if etatAuStop and C_Timer and C_Timer.After then
        C_Timer.After(2.5, function()
            if musiqueEtat ~= nil then return end -- nouvelle piste en cours
            if dernierJingleTemps and time() - dernierJingleTemps < 5 then return end
            pcall(function()
                local avant = tonumber(GetCVar("Sound_EnableSFX"))
                if avant == 0 then return end -- le joueur coupe déjà son SFX
                SetCVar("Sound_EnableSFX", 0)
                C_Timer.After(0.15, function()
                    pcall(function() SetCVar("Sound_EnableSFX", 1) end)
                end)
            end)
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
    local res = JouerFichierBlinde(619)
    if res == nil then
        JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_COMPLETE or 828)
    end
end

local function JouerPisteWoW(piste)
    dernierePiste = piste.id
    musiqueHandle = nil
    local res = JouerFichierBlinde(piste.id)
    if type(res) == "table" and (res.Stop or res.FadeOut) then musiqueHandle = res end
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
    local m = MHH_MUSIQUES[evenement]
    if not m then return end
    musiqueEtat = evenement
    -- Une piste à nous se joue : le décor sonore du jeu se tait
    CouperSonAmbiant()
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
    -- Déjà tiré aujourd'hui : rien à faire, SAUF si la cible manque
    -- (sauvegarde d'une version antérieure sans cibleJour) → on la retire.
    if DB.contratJour == aujourdhui and DB.cibleJour
        and DB.offresJour and DB.offresJour.date == aujourdhui then return end
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
    local nom = source[math.random(#source)]
    -- La cible du jour est TOUJOURS mémorisée (plaque Accueil), même si
    -- le joueur a déjà un contrat en cours (le sien prime).
    DB.cibleJour = nom
    DB.cibleJourZone = MHH_CATALOGUE[nom] or zone
    -- Offres du jour (fenêtre Contrats) : la cible du jour (prime +20)
    -- et 4 gibiers piochés dans tout le carnet (prime +5 chacun : de quoi
    -- agrémenter le choix, sans concurrencer l'offre spéciale).
    local offres = { nom }
    local pris = { [nom] = true }
    local gardes = 0
    while #offres < 5 and #tous > 1 and gardes < 200 do
        gardes = gardes + 1
        local cand = tous[math.random(#tous)]
        if not pris[cand] then
            pris[cand] = true
            offres[#offres + 1] = cand
        end
    end
    DB.offresJour = { date = aujourdhui, noms = offres }
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
-- Exténué (clin d'œil MH « drooling ») : annoncé une fois quand la cible
-- de la chasse active passe sous 25% de vie, remis à zéro si elle remonte
local eteintAnnonce = false
-- Traitement de la sélection de cible : détecte le gibier et lance la
-- chasse. Factorisée car appelée depuis PLAYER_TARGET_CHANGED ET depuis
-- PLAYER_ALIVE (fantôme qui redevient vivant en gardant la cible).
local function TraiterCible()
    if not DB then return end
    -- Portrait live dans le carnet s'il est ouvert
    if RaffraichirCarnet and carnet and carnet:IsShown() then RaffraichirCarnet() end
    if UnitExists("target") and not UnitIsFriend("player", "target") and not UnitIsPlayer("target") then
        local nom = UnitName("target") or ""
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
            end
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
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r chargé. /hunt pour ouvrir le carnet. ") .. nbChasses() .. L(" chasses au compteur."))
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
                        if UnitExists("target") and (UnitName("target") or "") == nomChasse
                            and UnitIsDead("target") then encoreMorte = true end
                        if UnitExists("mouseover") and (UnitName("mouseover") or "") == nomChasse
                            and UnitIsDead("mouseover") then encoreMorte = true end
                    end)
                    if encoreMorte then
                        DebugChasse("finCombat", nomChasse .. L(" — cadavre repéré au dernier filet : prise !"))
                        FinChasseVictoire(nomChasse)
                        return
                    end
                    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffa58b54Le monstre vous a échappé…|r La chasse de ") .. nomChasse .. L(" est suspendue."))
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
                FinChasseEchec()
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
        FinChasseEchec()
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
        local _, sousEvent, _, sourceGUID, sourceNom, _, _, _, destNom = CombatLogGetCurrentEventInfo()
        if sousEvent == "UNIT_DIED" and chasseActive then
            DebugChasse("journal", "UNIT_DIED : " .. tostring(destNom) .. L(" (chassé : ") .. chasseActive .. ")")
        end
        if sousEvent == "UNIT_DIED" and destNom == chasseActive then
            local parLeJoueur = (sourceGUID == UnitGUID("player"))
            local parLeGroupe = sourceNom and (UnitInParty(sourceNom) or UnitInRaid(sourceNom))
            DebugChasse("journal", "killSouple=" .. tostring(DB.config.killSouple)
                .. " parLeJoueur=" .. tostring(parLeJoueur)
                .. " parLeGroupe=" .. tostring(parLeGroupe))
            -- pcall : si Midnight bloque quelque chose en contexte tainté,
            -- la prise reste acquittée (anti-double en tête de fonction)
            local okF, errF
            if DB.config.killSouple then
                okF, errF = pcall(FinChasseVictoire, destNom)
            elseif parLeJoueur or parLeGroupe then
                okF, errF = pcall(FinChasseVictoire, destNom)
            end
            if not okF then DebugChasse("journal", L("ERREUR victoire : ") .. tostring(errF)) end
        elseif sousEvent == "AURA_APPLIED" and destNom == chasseActive then
            -- Piège gelé : le monstre chassé est capturé (spellId 3355 en Classic)
            local spellId = select(12, CombatLogGetCurrentEventInfo())
            if spellId == 3355 then
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
        if chasseActive and UnitExists("target") and UnitName("target") == chasseActive then
            -- Détection de la mise à mort TOLÉRANTE : certains clients
            -- n'offrent pas d'UNIT_DIED exploitable dans le journal de
            -- combat. Dès que la bête chassée meurt sous le viseur, la
            -- prise vaut — quel que soit le canal qui l'a signalée.
            local okMort, mort = pcall(function() return UnitIsDead("target") end)
            if okMort and mort then
                DebugChasse("viseur", chasseActive .. L(" mort sous le viseur"))
                local nomPrise = chasseActive
                C_Timer.After(0, function()
                    if chasseActive == nomPrise then FinChasseVictoire(nomPrise) end
                end)
                return
            end
            -- Clin d'œil MH : le monstre « droole » sous 25% de vie.
            -- NB : sur certains clients (Midnight), la vie des PNJ est un
            -- « secret number » : l'arithmétique (/ *) est interdite, mais
            -- les COMPARAISONS sont permises. On essaie dans l'ordre :
            -- pourcentage direct (UnitHealthPct), sinon ratio — tout en
            -- pcall : jamais de spam d'erreurs, la détection s'active
            -- selon ce que le client autorise.
            pcall(function()
                local faible = false
                if UnitHealthPct then
                    local p = UnitHealthPct("target")
                    if p > 1 then faible = (p < 25) else faible = (p < 0.25) end
                else
                    faible = UnitHealth("target") / math.max(1, UnitHealthMax("target")) < 0.25
                end
                if faible then
                    if not eteintAnnonce then
                        eteintAnnonce = true
                        AfficherBanniere(L("EXTÉNUÉ !"), 1, 0.55, 0.2)
                        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. chasseActive .. L(" est exténué — il droole sur ses pattes…"))
                    end
                else
                    eteintAnnonce = false
                end
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        EnregistrerCarteZone()
        ContratQuotidien()
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
                DB.herbe = (DB.herbe or 0) + 1
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Cueilli en chemin : |cffff7a1a1 herbe aromatique|r.")
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
            local rang, points, chasses, captures, trophee = strsplit("|", msg:sub(7))
            if type(expediteur) == "string" then expediteur = strsplit("-", expediteur) end
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Carte de chasseur — |cffffff00")
                .. (expediteur or "?") .. "|r, |cffc9a24a" .. (rang or "?") .. "|r : "
                .. (tonumber(points) or 0) .. " pts, " .. (tonumber(chasses) or 0) .. L(" chasses, ")
                .. (tonumber(captures) or 0) .. L(" spécimens en enclos.")
                .. ((trophee and trophee ~= "-" and trophee ~= "") and (L(" Dernière prise : |cffa0ff50") .. trophee .. "|r.") or ""))
            AfficherBanniere(L("CARTE DE CHASSEUR — ") .. (expediteur or "?"), 1, 0.84, 0)
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
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_ALIVE") -- fantôme qui redevient vivant avec la cible
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("UNIT_HEALTH")
-- UPDATE_MOUSEOVER est absent de certains clients Midnight : pcall + repli
-- sur CURSOR_UPDATE (même usage : survol des plaques pour l'auto-découverte)
pcall(function() f:RegisterEvent("UPDATE_MOUSEOVER") end)
pcall(function() f:RegisterEvent("CURSOR_UPDATE") end)
pcall(function() f:RegisterEvent("WEATHER_CHANGED") end) -- client Forever uniquement
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_LOGOUT") -- pour garantir la restitution du son du jeu
pcall(function() -- canal d'addon : carte de chasseur (/hunt carte <joueur>)
    if C_Chat and C_Chat.RegisterAddonMessagePrefix then
        C_Chat.RegisterAddonMessagePrefix("MHHUNT")
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("MHHUNT")
    end
end)
f:SetScript("OnEvent", OnEvenementPrincipal)

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
carnet:SetFrameStrata("MEDIUM")
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
local RaffraichirOptions, RaffraichirCuisine

-- Couleurs par rang (globale : utilisée par l'Accueil pour le liseré du
-- carnet ET par le Profil pour la bordure du portrait)
MHH_COULEURS_RANG = {
    { 0.55, 0.42, 0.20 }, -- Novice : brun
    { 0.72, 0.45, 0.25 }, -- Chasseur : bronze
    { 0.75, 0.75, 0.78 }, -- Vétéran : argent
    { 0.78, 0.62, 0.25 }, -- Chasseur accompli : or
    { 0.95, 0.80, 0.35 }, -- Légende de la chasse : or vif
}

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
local accueilRangTxt = pageAccueil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
accueilRangTxt:SetPoint("TOPLEFT", pageAccueil, "TOPLEFT", 84, -58)
accueilRangTxt:SetWidth(472)
accueilRangTxt:SetJustifyH("LEFT")
accueilRangTxt:SetShadowColor(0, 0, 0, 1)
accueilRangTxt:SetShadowOffset(1, -1)
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
    accueilRangTxt:SetText(L("Rang de chasseur : |cffffd100") .. rang .. "|r — " .. (DB.points or 0) .. L(" points de chasse"))
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
barreRecherche.instructions:SetPoint("LEFT", 3, -1)
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
    ["Bois de la Pénombre"]      = {0.35, 0.60, 0.30},
    ["Comté de l'Ouest"]     = {0.40, 0.55, 0.85},
    ["Durotar"]              = {0.80, 0.35, 0.20},
    ["Mulgore"]              = {0.35, 0.50, 0.70},
    ["Teldrassil"]           = {0.25, 0.65, 0.35},
    ["Les Tarides"]            = {0.85, 0.70, 0.25},
    ["Les Carmines"]         = {0.55, 0.20, 0.25},
    ["Bois de la Pénombre"]= {0.45, 0.45, 0.30},
    ["Mille Pointes"]        = {0.75, 0.65, 0.40},
    ["Orneval"]              = {0.30, 0.55, 0.25},
    ["Steppes ardentes"]     = {0.85, 0.40, 0.15},
    ["Marais des chagrins"]  = {0.30, 0.50, 0.45},
    ["Les Paluns"]           = {0.35, 0.55, 0.75},
    ["Loch Modan"]           = {0.60, 0.55, 0.30},
    ["Gangrebois"]           = {0.85, 0.25, 0.30},
    ["Tanaris"]               = {0.85, 0.75, 0.45},
    ["Maleterres ouest"]     = {0.55, 0.55, 0.60},
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
}
local COULEUR_DEFAUT = {0.78, 0.62, 0.25} -- doré

local function CouleurZone(zone)
    return ZONE_COULEURS[zone] or COULEUR_DEFAUT
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
detailZone:SetPoint("TOPLEFT", 140, -56)
-- Retour à la ligne pour les longs noms de zone (ne déborde plus de l'encart)
detailZone:SetWidth(138)
detailZone:SetJustifyH("LEFT")
detailZone:SetShadowColor(0, 0, 0, 1)
detailZone:SetShadowOffset(1, -1)
-- Pastille de couleur de l'habitat (façon bouton de biome MH)
local detailHabitatIcone = detailFond:CreateTexture(nil, "ARTWORK")
detailHabitatIcone:SetSize(12, 12)
detailHabitatIcone:SetPoint("TOPLEFT", 124, -57)
detailHabitatIcone:SetColorTexture(0.5, 0.5, 0.5, 0.95)
local detailMenace = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
detailMenace:SetPoint("TOPLEFT", 124, -84)
-- Rangée de menace : 5 pips carrés + 5 étoiles en texture (les glyphes texte
-- type étoile ne sont pas rendus par les polices WoW ; les textures si).
-- Doublure : si la texture étoile manque sur un client, les pips restent visibles.
local pipsMenace, etoilesMenace = {}, {}
for i = 1, 5 do
    -- Ancrées sur le texte « Menace : » : alignement vertical exact,
    -- quel que soit le rendu de la police. Étoiles agrandies (16px).
    local pip = detailFond:CreateTexture(nil, "ARTWORK")
    pip:SetSize(12, 12)
    pip:SetPoint("LEFT", detailMenace, "RIGHT", 6 + (i - 1) * 16, -1)
    pipsMenace[i] = pip
    local et = detailFond:CreateTexture(nil, "OVERLAY")
    et:SetSize(16, 16)
    et:SetPoint("CENTER", pip, "CENTER")
    et:SetTexture("Interface\\Common\\FavoritesIcon")
    et:SetVertexColor(0.78, 0.62, 0.25, 0.95)
    etoilesMenace[i] = et
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
detailFaiblesseLabel:SetPoint("TOPLEFT", 124, -142)
local faiblesseIcons = {}
local faiblesseNoms = {}
for i = 1, 3 do
    local t = detailFond:CreateTexture(nil, "ARTWORK")
    t:SetSize(12, 12)
    t:SetPoint("TOPLEFT", 124 + (i - 1) * 74, -157)
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
detailGabaritLabel:SetPoint("TOPLEFT", 124, -102)
local detailGabaritBg = detailFond:CreateTexture(nil, "BACKGROUND")
detailGabaritBg:SetSize(120, 8)
detailGabaritBg:SetPoint("TOPLEFT", 124, -114)
detailGabaritBg:SetColorTexture(0.25, 0.20, 0.12, 0.9)
local detailGabaritFill = detailFond:CreateTexture(nil, "ARTWORK")
detailGabaritFill:SetSize(0, 8)
detailGabaritFill:SetPoint("TOPLEFT", 124, -114)
detailGabaritFill:SetColorTexture(0.78, 0.62, 0.25, 0.95)
-- Légende de la jauge de gabarit : échelle des niveaux 1 -> 60
local detailGabaritMin = detailFond:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
detailGabaritMin:SetPoint("TOPLEFT", 120, -124)
detailGabaritMin:SetText("1")
local detailGabaritMax = detailFond:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
detailGabaritMax:SetPoint("TOPLEFT", 238, -124)
detailGabaritMax:SetText("60")
-- Délimitation légère entre le bloc d'identité et les statistiques
local detailTraitStats = detailFond:CreateTexture(nil, "OVERLAY")
detailTraitStats:SetHeight(1)
detailTraitStats:SetWidth(256)
detailTraitStats:SetPoint("TOPLEFT", 16, -182)
detailTraitStats:SetColorTexture(0.62, 0.48, 0.22, 0.45)
-- Note du naturaliste (2 lignes max, texte intégral — plus de troncature
-- brutale : on répartit les stats en 2 colonnes pour gagner la place)
local detailNote = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailNote:SetPoint("TOPLEFT", 16, -190)
detailNote:SetJustifyH("LEFT")
detailNote:SetWidth(256)
detailNote:SetSpacing(3)
-- Stats de chasse : 2 colonnes gauche/droite (au lieu d'une pile haute
-- qui débordait sur les boutons quand la note était longue)
local detailStatsG = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailStatsG:SetPoint("TOPLEFT", 16, -222)
detailStatsG:SetJustifyH("LEFT")
detailStatsG:SetWidth(128)
detailStatsG:SetSpacing(4)
local detailStatsD = detailFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailStatsD:SetPoint("TOPLEFT", 150, -222)
detailStatsD:SetJustifyH("LEFT")
detailStatsD:SetWidth(126)
detailStatsD:SetSpacing(4)
-- Bouton de contrat : texte mis à jour par RaffraichirDetail (définie juste après)
local MettreAJourBoutonContrat = function() end

local function EtoilesMenace(nom, info)
    -- Menace simple : 1 à 5. Jamais chassée ? L'estimation du data file
    -- (NIVEAUX) sert en attendant la première prise. Une rare ÉLITE
    -- gagne une étoile : le dragon doré du client se lit dans le carnet.
    local niv = (info and info.nivMax) or MHH_NIVEAUX[nom] or 0
    local nivJoueur = UnitLevel("player")
    local base = 1
    if niv > 0 then base = (niv >= nivJoueur + 5) and 5 or (niv >= nivJoueur) and 4 or (niv >= nivJoueur - 5) and 3 or 2 end
    if MHH_ELITES[nom] then base = math.min(5, base + 1) end
    return base
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
            pipsMenace[i]:Hide()
            etoilesMenace[i]:Hide()
        end
        detailPortrait:SetTexture(nil)
        return
    end
    local info = DB.chasses[mobSelectionne] or {}
    local zone = MHH_CATALOGUE[mobSelectionne] or (DB.decouverts[mobSelectionne] and DB.decouverts[mobSelectionne].zone) or "?"
    -- Statut sous le portrait : le niveau vit dans le gabarit (estimation
    -- ou observé) — ici, seulement le statut quand le data le connaît
    detailNiveau:SetText(MHH_ELITES[mobSelectionne] and "|cffff6a6aÉlite rare|r" or "")
    detailNom:SetText((DB.contrat == mobSelectionne and "|cffff69b4» |r" or "") .. "|cffffd100" .. mobSelectionne .. "|r")
    -- Noms très longs (« Maître des esclaves cœur-noir »…) : police
    -- rétrogradée puis tronquée — jamais de débordement sur la fiche
    pcall(function()
        detailNom:SetFontObject("GameFontNormalLarge")
        if detailNom:GetStringWidth() > 148 then
            detailNom:SetFontObject("GameFontNormal")
        end
        local nomz = mobSelectionne
        while detailNom:GetStringWidth() > 148 and #nomz > 6 do
            nomz = string.sub(nomz, 1, #nomz - 1)
            detailNom:SetText((DB.contrat == mobSelectionne and "|cffff69b4» |r" or "")
                .. "|cffffd100" .. nomz .. "…|r")
        end
    end)
    -- Habitat : coordonnées de spawn si le data file en fournit
    local coords = MHH_COORDS[mobSelectionne]
    if coords then
        detailZone:SetText(L("Habitat : ") .. zone
            .. " |cffc9a24a(≈ " .. coords[1] .. ", " .. coords[2] .. ")|r")
    else
        detailZone:SetText(L("Habitat : ") .. zone)
    end
    -- Couleur de l'habitat
    local cHabitat = ZONE_COULEURS[zone] or COULEUR_DEFAUT
    detailHabitatIcone:SetColorTexture(cHabitat[1], cHabitat[2], cHabitat[3], 0.95)
    -- Menace : étoiles seules, le score numérique est dans le décompte des pips
    detailMenace:SetText("|cffc9a24aMenace :|r")
    for i = 1, 5 do
        -- Façon MH : seules les étoiles GAGNÉES s'affichent — les non
        -- acquises sont masquées, comme sur les menus de Monster Hunter
        if i <= EtoilesMenace(mobSelectionne, info) then
            pipsMenace[i]:Show()
            pipsMenace[i]:SetColorTexture(0.35, 0.30, 0.22, 0.85)
            etoilesMenace[i]:Show()
            etoilesMenace[i]:SetVertexColor(0.95, 0.78, 0.25, 1.0)
        else
            pipsMenace[i]:Hide()
            etoilesMenace[i]:Hide()
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
    -- Gabarit : plage de niveaux rencontrés sur une barre (min/max, comme MH).
    -- Jamais pris ? Le data file donne l'ESTIMATION de la taille : marqueur
    -- discret sur la jauge, qui laisse la place à la plage réelle dès la
    -- première prise. Pas de doublon avec le niveau sous le portrait.
    local nivEstime = MHH_NIVEAUX[mobSelectionne]
    if info.nivMin and info.nivMax then
        -- Une seule prise : « niv 18 » plutôt que « niv 18–18 »
        if info.nivMin == info.nivMax then
            detailGabaritLabel:SetText(L("Gabarit : niv ") .. info.nivMin)
        else
            detailGabaritLabel:SetText(L("Gabarit : niv ") .. info.nivMin .. "–" .. info.nivMax)
        end
        local x1 = 124 + 120 * (info.nivMin / 60)
        local x2 = 124 + 120 * (info.nivMax / 60)
        detailGabaritFill:ClearAllPoints()
        detailGabaritFill:SetPoint("TOPLEFT", x1, -114)
        detailGabaritFill:SetSize(math.max(6, x2 - x1), 8)
        detailGabaritFill:SetColorTexture(0.78, 0.62, 0.25, 0.95) -- observé : or
    elseif nivEstime then
        detailGabaritLabel:SetText(L("Gabarit : ~niv ") .. nivEstime .. L(" (estimation)"))
        local xm = 124 + 120 * (nivEstime / 60) - 3
        detailGabaritFill:ClearAllPoints()
        detailGabaritFill:SetPoint("TOPLEFT", xm, -114)
        detailGabaritFill:SetSize(6, 8)
        detailGabaritFill:SetColorTexture(0.55, 0.48, 0.35, 0.75) -- estimé : discret
    else
        detailGabaritLabel:SetText(L("Gabarit : inconnu"))
        detailGabaritFill:ClearAllPoints()
        detailGabaritFill:SetPoint("TOPLEFT", 124, -114)
        detailGabaritFill:SetSize(0, 8)
    end
    -- Observations du naturaliste (2 lignes max, texte intégral), puis
    -- stats réparties en 2 colonnes : plus rien ne déborde sur les boutons.
    local note = MHH_NOTES[mobSelectionne]
    if not note and info.premiere then
        -- Bête hors bestiaire rédigé : note générée depuis le profil de
        -- chasse. Le ton évolue avec le nombre de prises — une bête tuée
        -- souvent n'est plus « mal connue ».
        local nb = info.kills or 0
        if nb >= 5 then
            note = L("Vieille connaissance du carnet — ") .. nb
                .. L(" prises, et toujours des restes à gratter.")
        elseif nb >= 2 then
            note = L("Ce spécimen commence à être bien connu : ") .. nb
                .. L(" prises au compteur.")
        else
            note = L("Spécimen encore mal connu du carnet. Première prise : ") .. info.premiere .. "."
        end
    end
    note = note or L("Observations en cours.")
    if #note > 110 then note = note:sub(1, 107) .. "..." end
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
    detailStatsG:SetText(
        L("Chasses : |cffffd100") .. (info.kills or 0) .. "|r\n"
        .. L("Première : ") .. (info.premiere or "?") .. "\n"
        .. L("Dernière : ") .. (info.derniere or "?"))
    local colD = L("Sans mourir : ") .. (info.sansMourir or 0) .. "/" .. (info.kills or 0)
    if info.recordMin then
        colD = colD .. "\nRecord : |cffffd100" .. math.floor(info.recordMin / 60)
            .. " min " .. (info.recordMin % 60) .. " s|r"
    end
    -- Gabarit mesuré : dernière taille + couronne (record trophée en fiche)
    if info.taille then
        colD = colD .. "\n" .. L("Gabarit : |cffffff00") .. info.taille .. L(" unités|r")
        if info.tailleRecord then
            colD = colD .. L("  |cffa58b54(★ |cffffd100") .. info.tailleRecord .. "|r)"
        end
        if info.couronne == "or" then
            colD = colD .. L("\n|cffffcc44★ Couronne d'or du gabarit !|r")
        elseif info.couronne == "argent" then
            colD = colD .. L("\n|cffc0c0c0★ Couronne d'argent du gabarit|r")
        end
    end
    detailStatsD:SetText(colD)
    -- Portrait : 3D si le mob est ciblé, sinon silhouette
    local nomCible = UnitName("target") or ""
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
        -- Silhouette grise seulement pour une bête JAMAIS prise ; une
        -- bête chassée (kills >= 1) a droit à son portrait en couleur.
        detailPortrait:SetDesaturated((info.kills or 0) == 0)
    end
    MettreAJourBoutonContrat()
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
boutonCarte:SetPoint("BOTTOMLEFT", 12, 10)
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
    ["Marais des chagrins"] = L("Royaumes de l'Est"),
    ["Terres ingrates"] = L("Royaumes de l'Est"),
    ["Gorge des Vents brûlants"] = L("Royaumes de l'Est"),
    ["Steppes ardentes"] = L("Royaumes de l'Est"),
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
    "Marais des chagrins", "Terres ingrates", "Gorge des Vents brûlants",
    "Steppes ardentes", "Terres foudroyées", "Maleterres de l'Ouest",
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

    local nomCible = UnitName("target") or ""
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
            entete.texte = entete:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            entete.texte:SetPoint("TOPLEFT", 20, -3)
            -- Estimation « rares non répertoriées » : petite police, calée
            -- à droite — plus de débordement hors de l'en-tête
            entete.estim = entete:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            entete.estim:SetPoint("TOPRIGHT", -20, -5)
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
        -- Noms de zone longs (« Contreforts de Hautebrande »…) : on repart
        -- de la grande police, on mesure, puis on rétrograde / tronque
        -- pour ne JAMAIS chevaucher le décompte X/Y calé à droite
        local nomTronque = false
        pcall(function()
            entete.texte:SetFontObject("GameFontNormalLarge")
            local nomz = z
            local maxW = 176 -- 240 - 20 (pastille) - 44 (ratio à droite)
            entete.texte:SetText("|cffffd100" .. nomz .. "|r")
            if entete.texte:GetStringWidth() > maxW then
                nomTronque = true
                entete.texte:SetFontObject("GameFontNormal")
                while entete.texte:GetStringWidth() > maxW and #nomz > 6 do
                    nomz = string.sub(nomz, 1, #nomz - 1)
                    entete.texte:SetText("|cffffd100" .. nomz .. "…|r")
                end
            end
        end)
        -- Ratio ultra-compact « fiches/total » : juste les chiffres —
        -- les noms de zone longs (Hautes-terres d'Arathi…) ne le touchent plus
        local total = #parZone[z] + (MHH_RARES_ESTIMES[z] or 0)
        -- Nom de zone trop long : le décompte X/Y ne rentre PAS à côté du
        -- titre — on le retire plutôt que de le juxtaposer (choix du joueur)
        if nomTronque then
            entete.estim:SetText("")
        else
            entete.estim:SetText(total > 0 and ("|cffa58b54" .. #parZone[z] .. "/" .. total .. "|r") or "")
        end
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
                bouton.cadre = bouton:CreateTexture(nil, "OVERLAY")
                bouton.cadre:SetSize(44, 44)
                bouton.cadre:SetPoint("TOP", 0, 0)
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
                boutonsMobs[ib] = bouton
            end
            bouton:ClearAllPoints()
            bouton:SetPoint("TOPLEFT", grilleContenu, "TOPLEFT", col * ESPACEMENT, -y)
            bouton:Show()
            bouton.nomMob = nom
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
            bouton.label:SetText((DB.contrat == nom) and ("|cffff69b4» |cffe9dcc0" .. nom .. "|r") or ("|cffe9dcc0" .. nom .. "|r"))
            if info.kills and info.kills > 0 then
                bouton.cadre:SetColorTexture(0.78, 0.62, 0.25, 0.95) -- doré : chassé
            else
                bouton.cadre:SetColorTexture(0.35, 0.30, 0.20, 0.9) -- gris : jamais chassé
            end
            if nom == nomCible then
                DefinirPortrait(bouton.icone, "target")
                bouton.icone:SetDesaturated(false)
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
                bouton.icone:SetDesaturated((info.kills or 0) == 0)
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
contratsFond:SetSize(552, 314)
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
for i = 1, 5 do
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
        if nomC then PrendreOffreContrat(nomC, (i == 1 and 20) or 5) end
    end)
    offresLignes[i] = { txt = l, btn = b }
end
ContratsLabel(20, -192, L("CONTRAT ACTIF"))
local contratsActifTxt = contratsFond:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
contratsActifTxt:SetPoint("TOPLEFT", contratsFond, "TOPLEFT", 40, -210)
contratsActifTxt:SetWidth(330)
contratsActifTxt:SetJustifyH("LEFT")
contratsActifTxt:SetShadowColor(0, 0, 0, 1)
contratsActifTxt:SetShadowOffset(1, -1)
-- Révoquer : abandonne le contrat en cours (la chasse, elle, continue)
local boutonRevoquer = CreateFrame("Button", nil, contratsFond, MHH_TEMPLATE_BACKDROP)
-- Ancré sous le bouton « Prendre / En cours » : centres alignés, empilement net
boutonRevoquer:SetPoint("TOPRIGHT", contratsFond, "TOPRIGHT", -16, -210)
boutonRevoquer:SetSize(96, 22)
boutonRevoquer:SetText(L("Révoquer"))
boutonRevoquer:SetNormalFontObject("GameFontHighlight")
pcall(function()
    boutonRevoquer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    boutonRevoquer:SetBackdropColor(0.30, 0.10, 0.08, 0.85)
    boutonRevoquer:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
-- Surbrillance au survol du bouton Révoquer (pleine taille, comme le titre)
local boutonRevoquerSurbrillance = boutonRevoquer:CreateTexture(nil, "HIGHLIGHT")
boutonRevoquerSurbrillance:SetAllPoints()
boutonRevoquerSurbrillance:SetColorTexture(1, 0.85, 0.4, 0.35)
boutonRevoquer:SetHighlightTexture(boutonRevoquerSurbrillance)
boutonRevoquer:SetScript("OnEnter", function(self)
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L("|cffffd100Révoquer le contrat|r"))
        GameTooltip:AddLine(L("Abandonne le contrat en cours. La prime du contrat (+5, +10 ou +20 points) est perdue, et la chasse en cours (s'il y en a une) continue normalement."), 0.9, 0.8, 0.4, true)
        GameTooltip:Show()
    end
end)
boutonRevoquer:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
boutonRevoquer:SetScript("OnClick", function()
    if not DB.contrat then return end
    local nom = DB.contrat
    DB.contrat = nil
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Contrat révoqué : |cffffff00") .. nom .. "|r.")
    if RaffraichirCarnet then RaffraichirCarnet() end
    if RaffraichirAccueil then RaffraichirAccueil() end
    RaffraichirContrats()
    MettreAJourIndicateur()
end)
ContratsLabel(20, -246, L("HISTORIQUE DES PRIMES"))
local contratsHistoTxt = contratsFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
contratsHistoTxt:SetPoint("TOPLEFT", contratsFond, "TOPLEFT", 40, -262)
contratsHistoTxt:SetWidth(500)
contratsHistoTxt:SetJustifyH("LEFT")
contratsHistoTxt:SetSpacing(2)
contratsHistoTxt:SetShadowColor(0, 0, 0, 1)
contratsHistoTxt:SetShadowOffset(1, -1)

RaffraichirContrats = function()
    if not DB then return end
    -- Offres du jour : 5 lignes — la cible du jour (+20, marquée en or)
    -- puis 4 offres (+10). Bouton « Prendre (+N) » / « En cours ».
    local aujourdhui = date("%y%m%d")
    local offres = (DB.offresJour and DB.offresJour.date == aujourdhui) and DB.offresJour.noms or nil
    for i = 1, 5 do
        local ligne = offresLignes[i]
        local nom = offres and offres[i] or nil
        if nom then
            local prime = (i == 1) and 20 or 5
            ligne.txt:SetText("|cffffff00" .. nom .. "|r (" .. (MHH_CATALOGUE[nom] or "?") .. ")"
                .. (i == 1 and (" |cffffcc66• " .. L("(cible du jour)")) or ""))
            if DB.contrat == nom then
                ligne.btn:SetText(L("En cours"))
                ligne.btn:Disable()
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
    -- Contrat actif
    if DB.contrat then
        local zc = MHH_CATALOGUE[DB.contrat] or (DB.decouverts[DB.contrat] and DB.decouverts[DB.contrat].zone) or "?"
        contratsActifTxt:SetText("|cffffd100" .. DB.contrat .. "|r — Habitat : " .. zc)
        boutonRevoquer:Enable()
    else
        contratsActifTxt:SetText(L("|cff8a6d3bAucun contrat en cours — prenez une offre du jour ci-dessus.|r"))
        boutonRevoquer:Disable()
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
end
end

-- ================= PAGE SUCCÈS =================
do
local succesScroll = CreateFrame("ScrollFrame", nil, pageSucces, "UIPanelScrollFrameTemplate")
-- Fond encadré derrière la liste (cohérent avec la fiche monstre)
local succesFond = CreateFrame("Frame", nil, pageSucces, MHH_TEMPLATE_BACKDROP)
succesFond:SetPoint("TOPLEFT", pageSucces, "TOPLEFT", 44, -50)
succesFond:SetSize(552, 306)
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
succesBarreFond:SetPoint("TOPLEFT", pageSucces, "TOPLEFT", 44, -28)
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
succesRecherche.instructions:SetPoint("LEFT", 5, 0)
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
    GameTooltip:AddLine(L("|cff8a6d3bCliquez : armes les plus utilisées (histogramme).|r"), 1, 1, 1, true)
    GameTooltip:Show()
end)
MHH_armesBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
MHH_armesPan = CreateFrame("Frame", nil, pageProfil, MHH_TEMPLATE_BACKDROP)
-- Le panneau SE SUPERPOSE au bloc statistiques (la page est dense) : l'ouvrir
-- masque les stats, le fermer les rend. Positionné pile sur la zone stats.
MHH_armesPan:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 58, -192)
MHH_armesPan:SetSize(280, 158)
MHH_armesPan:Hide()
MHH_armesPan:SetFrameStrata("HIGH")
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
-- HISTOGRAMME (layout IMMANQUABLE, tout est ancré depuis le BAS du panneau) :
-- pour chaque type d'arme DE LA CLASSE du chasseur : une colonne dont la
-- barre monte depuis une ligne d'axe explicite. Deux rangées empilées ;
-- dans chaque rangée, de BAS en haut : libellé, axe, barre, piste.
function MHH_RaffraichirArmesHistogramme()
    if not DB then return end
    -- comptes par type de la classe
    local types = MHH_TypesArmesJoueur()
    local comptes = {}
    for _, canon in ipairs(types) do comptes[canon] = 0 end
    if DB.armes then
        for arme, n in pairs(DB.armes) do
            local canon = NormaliserTypeArme(arme)
            if comptes[canon] then comptes[canon] = comptes[canon] + n end
        end
    end
    local total = 0
    for _, n in pairs(comptes) do total = total + n end
    MHH_armesVide:SetShown(total == 0)
    -- répartition en rangées
    local nbTypes = #types
    local nbCol = math.ceil(nbTypes / 2)
    if nbCol < 4 then nbCol = nbTypes end
    local nbRangs = math.ceil(nbTypes / nbCol)
    -- géométrie (panneau 280x158, TOUT depuis le BAS) :
    local margeBas = 8     -- liseré bas
    local hLbl = 12        -- libellé court
    local hMax = 40        -- barres
    local hCmp = 12        -- compte
    -- hauteur d'une rangée complète + intervalle
    local pitchRang = hLbl + 4 + hMax + 4 + hCmp
    -- la 1re rangée (rang=0) est EN BAS, la 2e au-dessus
    -- axe de la rangée r, mesuré DEPUIS LE BAS du panneau :
    --   bas rangée 0 : margeBas + hLbl + 4 (libellé sous l'axe)
    local axe0 = margeBas + hLbl + 4
    -- intervalle au-dessus d'une rangée pour le compte de la suivante
    local ecartRangs = hCmp + 6
    for i, canon in ipairs(types) do
        local barre = MHH_armesBarres[i]
        if not barre then
            barre = {}
            barre.fond = MHH_armesPan:CreateTexture(nil, "BACKGROUND")
            barre.fond:SetColorTexture(0.25, 0.20, 0.12, 0.9)
            barre.fill = MHH_armesPan:CreateTexture(nil, "ARTWORK")
            barre.fill:SetColorTexture(0.78, 0.62, 0.25, 0.95)
            barre.txt = MHH_armesPan:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            barre.txt:SetJustifyH("CENTER")
            barre.count = MHH_armesPan:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            barre.count:SetJustifyH("CENTER")
            MHH_armesBarres[i] = barre
        end
        local n = comptes[canon]
        local rang = math.floor((i - 1) / nbCol)
        local col = (i - 1) % nbCol
        -- position horizontale
        local margeCote = 10
        local colW = math.floor((280 - margeCote * 2) / nbCol)
        local x = margeCote + col * colW
        -- AXE de la rangée depuis le BAS : rangée 0 en bas, rangée 1 dessus
        local axeDepuisBas = axe0 + rang * (hMax + ecartRangs)
        -- LIBELLE : sous l'axe (entre axe et bas de rangée)
        barre.txt:ClearAllPoints()
        barre.txt:SetPoint("TOP", MHH_armesPan, "BOTTOM", x + colW / 2, axeDepuisBas - 2)
        barre.txt:SetWidth(colW)
        barre.txt:SetText("|cffd8c9a3" .. (MHH_TYPES_ARMES_COURT[canon] or canon) .. "|r")
        -- PISTE (repère) : monte de l'axe sur hMax
        barre.fond:SetSize(colW - 6, hMax)
        barre.fond:ClearAllPoints()
        barre.fond:SetPoint("BOTTOM", MHH_armesPan, "BOTTOMLEFT", x + (colW - 6) / 2, axeDepuisBas)
        -- BARRE : monte de l'axe sur h
        local h = (total > 0 and n > 0) and math.max(3, math.floor(hMax * n / math.max(total, 1))) or 0
        barre.fill:ClearAllPoints()
        barre.fill:SetSize(colW - 6, h)
        barre.fill:SetPoint("BOTTOM", MHH_armesPan, "BOTTOMLEFT", x + (colW - 6) / 2, axeDepuisBas)
        barre.fill:SetShown(n > 0)
        -- COMPTE : au sommet de la barre (h+2 au-dessus de l'axe ; pour h=0,
        -- il repose sur l'axe — jamais de chevauchement de rangée : l'écart
        -- ecartRangs compte hCmp+6 pour lui laisser la place)
        barre.count:ClearAllPoints()
        barre.count:SetPoint("BOTTOM", MHH_armesPan, "BOTTOMLEFT", x + (colW - 6) / 2, axeDepuisBas + h + 2)
        barre.count:SetText(n > 0 and ("|cffffd100" .. n .. "|r") or "|cff7777770|r")
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
vitrineLabel:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -80)
vitrineLabel:SetText(L("|cffffd100TROPHÉES DE CHASSE|r"))
local TROPHEES = { "premiere", "intact", "nocturne", "grandgibier", "piege" }
local vitrineTrophees = {}
local sucInfo = {}
for _, s in ipairs(MHH_SUCCES) do sucInfo[s.id] = s end
for i = 1, 5 do
    local b = CreateFrame("Button", nil, pageProfil)
    b.idVitrine = TROPHEES[i] -- réécrit à chaque rafraîchissement du profil
    b:SetSize(30, 30)
    b:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368 + (i - 1) * 36, -102)
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

-- Titres de chasseur : 4 familles au choix (/hunt titre), paliers progressifs
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
palmaresTitre:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -152)
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
    pip:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -176 - (i - 1) * 24)
    pip:SetColorTexture(couleursPalmares[i][1], couleursPalmares[i][2], couleursPalmares[i][3], 0.95)
    pip:Hide()
    palmaresPips[i] = pip
    local t = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 384, -174 - (i - 1) * 24)
    t:SetWidth(192)
    t:SetJustifyH("LEFT")
    pcall(function() t:SetWordWrap(false) end)
    t:SetShadowColor(0, 0, 0, 1)
    t:SetTextColor(1, 1, 1)
    t:SetShadowOffset(1, -1)
    palmaresTextes[i] = t
end
local palmaresDerniere = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
palmaresDerniere:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -252)
palmaresDerniere:SetShadowColor(0, 0, 0, 1)
palmaresDerniere:SetTextColor(1, 1, 1)
palmaresDerniere:SetShadowOffset(1, -1)
palmaresDerniere:SetWidth(208)
palmaresDerniere:SetJustifyH("LEFT")

-- Ornaments de chasse : médailons débloqués selon les statistiques
-- (calculés en direct, rien à stocker — façon carte de guilde MH)
local ornementLabel = pageProfil:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ornementLabel:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368, -294)
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
    b:SetPoint("TOPLEFT", pageProfil, "TOPLEFT", 368 + (i - 1) * 32, -316)
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
    -- Histogramme des armes : affiché d'office à l'ouverture de l'onglet
    -- (le bouton icône de classe, 22 px sans texture propre, passait pour
    -- inactif — il reste cliquable pour le replier/déplier).
    MHH_RaffraichirArmesHistogramme()
    MHH_armesPan:Show()
    -- Photo du chasseur (portrait live)
    DefinirPortrait(profilPortrait.tex, "player")
    local total = nbChasses()
    local points = DB.points or 0
    local idx, rang = RangGuilde(points)
    profilIdentite:SetText("|cffffd100" .. (UnitName("player") or "?") .. "|r")
    profilRangTexte:SetText("|cff8a6d3bRang : |cffffd100" .. rang .. "|r")
    local classeFr, token = UnitClass("player")
    -- Affichage : titre-flavor « chasseur » ; la classe WoW reste en tooltip
    profilClasseTxt:SetText("|cffa58b54"
        .. (CLASSES_FLAVOR[(token or ""):upper()] or classeFr or "?") .. "|r")
    profilClasseIcone:SetTexture("Interface\\Icons\\"
        .. (CLASSES_ARMES[(token or ""):upper()] or "INV_Misc_QuestionMark"))
    -- Cadre du portrait : se pare des couleurs du rang
    local cr = MHH_COULEURS_RANG[idx] or MHH_COULEURS_RANG[1]
    pcall(function() profilPortrait:SetBackdropBorderColor(cr[1], cr[2], cr[3], 0.95) end)
    -- Titre de chasseur : famille au choix via /hunt titre, palier selon les stats
    local famille = DB.titreFamille or "naturaliste"
    local titreComplet = TitreDeFamille(famille)
    profilSousTitre:SetText("|cff8a6d3bTitre : |cffffd100« " .. titreComplet .. " »|r")
    -- Le titre est souvent tronqué (150 px de large) : le tooltip le montre entier
    profilSousTitre.titreComplet = titreComplet
    profilSousTitre:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cffffd100« " .. (self.titreComplet or "?") .. " »|r")
        GameTooltip:AddLine(L("|cffa58b54Titre de chasseur — changez de famille via /hunt titre|r"), 0.8, 0.8, 0.8, true)
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
    viande = { nom = L("Viande de gibier"), icone = "INV_Misc_Food_18" },
    herbe  = { nom = L("Herbe aromatique"), icone = "INV_Misc_Herb_17" },
    miel   = { nom = L("Miel sauvage"),     icone = "INV_Misc_Food_01" },
}
CUISINE_RECETTES = {
    roti = {
        nom = L("Rôti du chasseur"), icone = "INV_Misc_Food_16", bonus = 10,
        cout = { viande = 2 },
        desc = L("+10 points sur la prochaine prise."),
    },
    civet = {
        nom = L("Civet épicé"), icone = "INV_Misc_Food_15", bonus = 25,
        cout = { viande = 2, herbe = 1 },
        desc = L("+25 points sur la prochaine prise."),
    },
    festin = {
        nom = L("Festin de légende"), icone = "INV_Misc_Food_37", bonus = 60,
        cout = { viande = 3, herbe = 2, miel = 1 },
        desc = L("+60 points sur la prochaine prise."),
    },
}
do
local cuisineFond = CreateFrame("Frame", nil, pageCuisine, MHH_TEMPLATE_BACKDROP)
cuisineFond:SetPoint("TOPLEFT", pageCuisine, "TOPLEFT", 44, -42)
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
cuisineTitre:SetPoint("TOP", cuisineFond, "TOP", 0, -12)
cuisineTitre:SetText("|cffffd100CUISINE DE CAMP|r")
-- Séparateurs façon carnet MH : trait doré + losange central, mêmes
-- tons que la grille des monstres (harmonie du carnet)
local function TraitCuisine(y)
    local t = pageCuisine:CreateTexture(nil, "OVERLAY")
    t:SetHeight(2)
    t:SetWidth(480)
    t:SetPoint("TOP", cuisineFond, "TOP", 0, y)
    t:SetColorTexture(0.62, 0.48, 0.22, 0.85)
    local d = pageCuisine:CreateTexture(nil, "OVERLAY")
    d:SetSize(6, 6)
    d:SetPoint("TOP", cuisineFond, "TOP", 0, y - 4)
    d:SetColorTexture(0.78, 0.62, 0.25, 1)
end
local cuisineSacLabel = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cuisineSacLabel:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 32, -48)
cuisineSacLabel:SetText(L("|cffc9a24aBourse à objets :|r"))
local cuisineSac = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cuisineSac:SetPoint("TOPLEFT", cuisineSacLabel, "TOPRIGHT", 12, 0)
local cuisineRepasLabel = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cuisineRepasLabel:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 32, -70)
cuisineRepasLabel:SetText(L("|cffc9a24aRepas préparé :|r"))
local cuisineRepas = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cuisineRepas:SetPoint("TOPLEFT", cuisineRepasLabel, "TOPRIGHT", 12, 0)
local cuisineBoutons, cuisineCouts = {}, {}
local ordreRecettes = { "roti", "civet", "festin" }
-- Séparations : sous l'en-tête (sac + repas), puis entre chaque recette
TraitCuisine(-86)
for i = 2, #ordreRecettes do
    TraitCuisine(-100 - (i - 1) * 56 + 8)
end
for i, rid in ipairs(ordreRecettes) do
    local r = CUISINE_RECETTES[rid]
    local y = -100 - (i - 1) * 56
    local ic = pageCuisine:CreateTexture(nil, "ARTWORK")
    ic:SetSize(28, 28)
    ic:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 32, y)
    ic:SetTexture("Interface\\Icons\\" .. r.icone)
    local n = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    n:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 70, y)
    n:SetText("|cffffd100" .. r.nom .. "|r")
    local c = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 70, y - 18)
    c:SetWidth(172)
    c:SetJustifyH("LEFT")
    cuisineCouts[i] = c
    local e = pageCuisine:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    e:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 254, y - 6)
    e:SetWidth(136)
    e:SetJustifyH("LEFT")
    e:SetText("|cffff7a1a" .. r.desc .. "|r")
    local b = CreateFrame("Button", nil, pageCuisine, MHH_TEMPLATE_BACKDROP)
    b:SetSize(110, 22)
    b:SetPoint("TOPLEFT", cuisineFond, "TOPLEFT", 402, y - 8)
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
    bt:SetText("|cffffd100Cuisiner|r")
    b:SetScript("OnClick", function()
        if not DB then return end
        local rec = CUISINE_RECETTES[rid]
        for ing, qte in pairs(rec.cout) do
            if (DB[ing] or 0) < qte then
                DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Il manque des ingrédients pour le ") .. rec.nom .. ".")
                return
            end
        end
        for ing, qte in pairs(rec.cout) do DB[ing] = (DB[ing] or 0) - qte end
        DB.repas = rid
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffff7a1a" .. rec.nom .. L("|r préparé : ") .. rec.desc)
        if DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 845) end
        RaffraichirCuisine()
    end)
    cuisineBoutons[i] = b
end

RaffraichirCuisine = function()
    if not DB then return end
    local parts = {}
    for ing, info in pairs(CUISINE_INGREDIENTS) do
        parts[#parts + 1] = "|cffffd100" .. (DB[ing] or 0) .. "|r " .. info.nom
    end
    cuisineSac:SetText(table.concat(parts, "   "))
    if DB.repas and CUISINE_RECETTES[DB.repas] then
        cuisineRepas:SetText("|cffff7a1a" .. CUISINE_RECETTES[DB.repas].nom .. L("|r — s'appliquera à la prochaine prise."))
    else
        cuisineRepas:SetText(L("|cff8a6d3bAucun — cuisinez pour bonifier la prochaine chasse.|r"))
    end
    for i, rid in ipairs(ordreRecettes) do
        local rec = CUISINE_RECETTES[rid]
        local coutsTxt, ok = {}, true
        for ing, qte in pairs(rec.cout) do
            coutsTxt[#coutsTxt + 1] = qte .. " " .. CUISINE_INGREDIENTS[ing].nom
            if (DB[ing] or 0) < qte then ok = false end
        end
        cuisineCouts[i]:SetText(L("|cffc9a24aIngrédients :|r ") .. table.concat(coutsTxt, ", "))
        if ok then cuisineBoutons[i]:Enable() else cuisineBoutons[i]:Disable() end
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
        RaffraichirOptions()
    end)
end
local optionsNote = pageOptions:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
optionsNote:SetPoint("BOTTOMLEFT", optionsFond, "BOTTOMLEFT", 40, 16)
optionsNote:SetWidth(480)
optionsNote:SetJustifyH("LEFT")
optionsNote:SetText(L("|cff8a6d3bLes commandes /hunt restent valables — le carnet n'est qu'un raccourci confortable.|r"))

RaffraichirOptions = function()
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
-- ================= PAGE MÉNAGERIE (enclos) =================
-- L'enclos : les spécimens capturés (piege + kill) s'y baladent en pixel
-- art. La viande et le miel récoltés en chasse servent à nourrir/gâter.
local pageMenagerie = CreateFrame("Frame", nil, carnet)
pageMenagerie:SetAllPoints()
pageMenagerie:Hide()

MHH_menagerieFond = CreateFrame("Frame", nil, pageMenagerie, MHH_TEMPLATE_BACKDROP)
MHH_menagerieFond:SetPoint("TOPLEFT", pageMenagerie, "TOPLEFT", 44, -50)
MHH_menagerieFond:SetSize(552, 320)
pcall(function()
    MHH_menagerieFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    MHH_menagerieFond:SetBackdropColor(0.42, 0.33, 0.18, 0.35)
    MHH_menagerieFond:SetBackdropBorderColor(0.55, 0.42, 0.2, 0.8)
end)
MHH_menagerieTitre = MHH_menagerieFond:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MHH_menagerieTitre:SetPoint("TOP", 0, -8)
MHH_menagerieTitre:SetText(L("|cffffd100MÉNAGERIE|r"))
-- (Pas de sous-titre ici : le mode d'emploi de la capture est dans le
-- tuto — ici, on laisse toute la place à l'enclos)

-- L'enclos proprement dit : décor peint (TGA) au-dessus d'un repli procedural
MHH_enclosMenagerie = CreateFrame("Frame", nil, MHH_menagerieFond)
MHH_enclosMenagerie:SetPoint("TOPLEFT", MHH_menagerieFond, "TOPLEFT", 10, -26)
MHH_enclosMenagerie:SetSize(532, 176)
-- FOND PEINT : la scène complète (ciel, collines, herbe texturée, clôture,
-- grange) est une SEULE image TGA par faction — cf Textures/enclos_*.tga.
MHH_enclosFondImg = MHH_enclosMenagerie:CreateTexture(nil, "BACKGROUND")
MHH_enclosFondImg:SetAllPoints(MHH_enclosMenagerie)
-- Décor selon la FACTION du chasseur : ranch horde (savane rouge/brune)
-- ou alliance (prairie verte/blue) — repli sur le décor neutre.
-- NB : sur client Vanilla, SetTexture ne renvoie RIEN (pas de booléen de
-- succès — c'est une API moderne). On ne peut PAS tester le chargement.
-- Stratégie robuste : l'image peinte est dessinée EN DESSUS des textures
-- procédurales (créée après elles dans la même couche = au-dessus). Si le
-- fichier TGA existe il la recouvre entièrement ; s'il manque, la texture
-- reste transparente et le repli procedural reste visible dessous.
MHH_enclosCiel = MHH_enclosMenagerie:CreateTexture(nil, "BACKGROUND")
MHH_enclosCiel:SetAllPoints()
MHH_enclosCiel:SetColorTexture(0.47, 0.66, 0.92, 0.98)
MHH_enclosBandesCiel = {}
do
    -- Dégradé de ciel procédural (REPLI visible sous le TGA s'il manque)
    local HAUT = 176
    local NB = 8
    for b = 1, NB do
        local t = (b - 0.5) / NB
        local bande = MHH_enclosMenagerie:CreateTexture(nil, "BACKGROUND")
        bande:SetPoint("TOPLEFT", MHH_enclosMenagerie, "TOPLEFT", 0, -math.floor(HAUT * (b - 1) / NB))
        bande:SetSize(532, math.ceil(HAUT / NB) + 1)
        bande:SetColorTexture(0.47 + 0.16 * t, 0.66 + 0.12 * t, 0.92 - 0.05 * t, 0.98)
        MHH_enclosBandesCiel[#MHH_enclosBandesCiel + 1] = bande
    end
end
MHH_enclosSol = MHH_enclosMenagerie:CreateTexture(nil, "BACKGROUND")
MHH_enclosSol:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 0, 0)
MHH_enclosSol:SetPoint("BOTTOMRIGHT", MHH_enclosMenagerie, "BOTTOMRIGHT", 0, 0)
MHH_enclosSol:SetHeight(92)
MHH_enclosSol:SetColorTexture(0.42, 0.60, 0.30, 1)
-- L'IMAGE PEINTE : dessinée après = AU-DESSUS du repli. Le TGA opaque
-- la recouvre entièrement quand il est présent.
-- Biome affiché = enclos sélectionné (savane/marais/montagne/volcan),
-- ESTOMPÉ par la teinte de faction (horde chaud / alliance froid) tant
-- qu'aucun fond de biome n'existe pour la clé. Ordre de préférence :
--   1. enclos_<biome>.tga (fond du biome sélectionné)
--   2. enclos_<faction>.tga (ranch de la faction)
--   3. enclos.tga (neutre)
local function MHH_ChargerFondEnclos()
    if not (MHH_enclosFondImg and DB) then return end
    local biome = DB.enclosActif or "savane"
    local essais = {
        "Interface\\AddOns\\MHHunt\\Textures\\enclos_" .. biome .. ".tga",
    }
    pcall(function()
        local faction = UnitFactionGroup and UnitFactionGroup("player")
        if faction == "Horde" or faction == "Alliance" then
            essais[#essais + 1] = "Interface\\AddOns\\MHHunt\\Textures\\enclos_"
                .. (faction == "Horde" and "horde" or "alliance") .. ".tga"
        end
    end)
    essais[#essais + 1] = "Interface\\AddOns\\MHHunt\\Textures\\enclos.tga"
    MHH_enclosFondImg:SetTexture(essais[1])
    -- (Vanilla : pas de retour de SetTexture — le premier chemin qui existe
    -- gagne ; les fonds de biome manquants retombent sur la faction/neutre
    -- via la teinte, le repli procedural reste dessous en pire cas.)
end
MHH_ChargerFondEnclos()

-- Message « enclos vide » : recréé ici (perdu lors du passage au fond peint)
MHH_enclosVide = MHH_enclosMenagerie:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_enclosVide:SetPoint("CENTER", MHH_enclosMenagerie, "CENTER", 0, 10)
MHH_enclosVide:SetText(L("|cffa58b54L'enclos est vide — le régisseur dort.|r"))

-- Mini-météo de l'enclos : reprend la météo réelle du client (C_Weather,
-- serveur Forever) — pluie/neige/tempête tombent dans l'enclos et le ciel
-- se teinte. Léger : 18 particules, animées par le ticker de la page.
MHH_particulesMenagerie = {}
MHH_meteoMenagerie = { cle = nil, verif = 0 }
MHH_COULEURS_CIEL_ENCLOS = {
    clear = { 0.55, 0.72, 0.92, 0.98 },
    cloudy = { 0.62, 0.64, 0.70, 0.98 },
    rain = { 0.42, 0.50, 0.62, 0.98 },
    snow = { 0.68, 0.74, 0.86, 0.98 },
    sandstorm = { 0.72, 0.62, 0.40, 0.98 },
    firestorm = { 0.55, 0.30, 0.20, 0.98 },
}
local function CouleurParticuleMeteo(cle)
    if cle == "rain" then return 0.55, 0.66, 0.95, 0.85 end
    if cle == "snow" then return 1, 1, 1, 0.9 end
    if cle == "sandstorm" then return 0.85, 0.72, 0.45, 0.8 end
    if cle == "firestorm" then return 1, 0.55, 0.2, 0.9 end
    return nil -- dégagé ou couvert : pas de particules
end
for i = 1, 18 do
    local p = MHH_enclosMenagerie:CreateTexture(nil, "OVERLAY")
    p:SetSize(2, 7)
    p:SetPoint("TOPLEFT", MHH_enclosMenagerie, "TOPLEFT", 0, 0)
    p:Hide()
    MHH_particulesMenagerie[i] = { t = p, x = math.random() * 532, y = math.random() * 176,
                               v = 0, dir = 1 }
end
local function ConfigurerMeteoEnclos(cle)
    local ciel = MHH_COULEURS_CIEL_ENCLOS[cle] or MHH_COULEURS_CIEL_ENCLOS.clear
    -- Cycle jour/nuit : le ciel s'assombrit la nuit (20h - 6h, heure de
    -- jeu). GetGameTime renvoie (h, m) ou des minutes selon les clients —
    -- les deux sont couverts.
    local facteur = 1
    pcall(function()
        local a, b = GetGameTime()
        local heure = b and a or math.floor((a or 0) / 60)
        if heure >= 20 or heure < 6 then facteur = 0.45 end
    end)
    MHH_enclosCiel:SetColorTexture(ciel[1] * facteur, ciel[2] * facteur,
        ciel[3] * facteur, ciel[4])
    -- FOND PEINT : l'image unique reçoit la teinte météo + cycle jour/nuit
    -- (SetVertexColor multiplie : nuit = assombri, pluie = refroidi, le
    -- pixel art reste lisible). Les replis procéduraux sont teintés pareil.
    if MHH_enclosFondImg then
        MHH_enclosFondImg:SetVertexColor(
            0.55 + 0.45 * ciel[1] * facteur,
            0.55 + 0.45 * ciel[2] * facteur,
            0.55 + 0.45 * ciel[3] * facteur)
    end
    for bi, bande in ipairs(MHH_enclosBandesCiel or {}) do
        local t = (bi - 0.5) / #MHH_enclosBandesCiel
        bande:SetColorTexture((ciel[1] + 0.16 * t) * facteur,
            (ciel[2] + 0.12 * t) * facteur,
            (ciel[3] - 0.05 * t) * facteur, ciel[4])
    end
    -- Le décor céleste suit la lumière : nuances sombres la nuit, blanches
    -- le jour — sinon le soleil brillait en plein noir.
    for _, nuage in ipairs(MHH_enclosNuages) do
        for _, t in ipairs(nuage) do
            t:SetVertexColor(facteur, facteur, facteur)
        end
    end
end
local function ConfigurerParticulesEnclos(cle)
    local r, g, b, a = CouleurParticuleMeteo(cle)
    for _, p in ipairs(MHH_particulesMenagerie) do
        if r then
            p.t:SetColorTexture(r, g, b, a)
            p.t:Show()
            if cle == "snow" then
                p.v, p.dir = 0.4 + math.random() * 0.5, 1
            elseif cle == "rain" then
                p.v, p.dir = 3 + math.random() * 2, 1
            elseif cle == "sandstorm" then
                p.v, p.dir = 0.8 + math.random(), 1
            else -- firestorm : braises qui remontent
                p.v, p.dir = 0.8 + math.random(), -1
            end
            p.y = math.random() * 176
        else
            p.v = 0
            p.t:Hide()
        end
    end
end

-- État de faim : calculé depuis le dernier nourrissage (pas de ticker
-- en arrière-plan, tout est dérivé de l'horodatage)
local function EtatSpecimen(m)
    local d = time() - (m.nourri or m.capture or time())
    if d < 86400 then return "repu", "|cffa0ff50Repu|r"
    elseif d < 259200 then return "faim", "|cffffd100Petite faim|r"
    else return "affame", L("|cffd87a6aAffamé|r") end
end

-- AFFINITÉ (0-100) : nourrir +4, gâter au miel +10 ; dégrise de 2/jour sans
-- soin. À 100, le pensionnaire est « dévoué » : +10% points de chasse dans
-- sa zone d'habitat, et une piste quotidienne sur un rare de sa zone.
Affinite = function(m)
    if not m then return 0 end
    local base = m.affinite or 0
    -- décroissance : 2 points par jour écoulé depuis le dernier soin
    local dernier = m.dernierSoin or m.capture or time()
    local jours = math.floor((time() - dernier) / 86400)
    return math.max(0, math.min(100, base - jours * 2))
end
local function AffiniteLibelle(v)
    if v >= 100 then return "|cffff8800Dévoué|r"
    elseif v >= 60 then return "|cffffd100Attaché|r"
    elseif v >= 25 then return "|cffa58b54Apprivoisé|r"
    else return "|cff8a6d3bMéfiant|r" end
end
local function SoinSpecimen(m, gain)
    if not m then return end
    m.affinite = Affinite(m) + gain          -- repart du valeur déclinée
    if m.affinite > 100 then m.affinite = 100 end
    m.dernierSoin = time()
    -- Succès « Ami dévoué » : le premier pensionnaire à 100 d'affinité
    if m.affinite >= 100 and DB and DB.succes and not DB.succes["amidevoue"] then
        DebloquerSucces("amidevoue")
    end
end
-- Le pensionnaire dévoué d'une zone donne-t-il un bonus de chasse ici ?
-- (déclarée en tête de fichier : FinChasseVictoire l'appelle avant)
ZoneAvecAmiDevoue = function(zone)
    if not (DB and DB.menagerie) then return false end
    for nom, m in pairs(DB.menagerie) do
        local z = MHH_CATALOGUE[nom]
        if z == zone and Affinite(m) >= 100 then return true, nom end
    end
    return false
end
local function IlYA(t)
    local d = time() - t
    if d < 3600 then return math.floor(d / 60) .. " min"
    elseif d < 86400 then return math.floor(d / 3600) .. " h"
    else return math.floor(d / 86400) .. " j" end
end

-- Rendu pixel art : une grille de textures 16x16, 5 px par cellule.
-- SPIRITES TGA : si un fichier existe dans
-- Interface\AddOns\MHHunt\Textures\Specimens\<slug>.tga, il REMPLACE la
-- grille (SetTexture renvoie nil si le fichier est absent → repli grille).
-- Génération : magick sprite.png -resize 80x80 -depth 32 <slug>.tga
MHH_TAILLE_PIX = 5
MHH_SLUGS_SPRITES = {
    ["Humar le Seigneur hautain"] = "humar",
    ["Takk le Bondisseur"] = "takk",
    ["Mazzranache"] = "mazzranache",
    ["Sarkoth"] = "sarkoth",
    ["Flagglemurk le Cruel"] = "flagglemurk",
    ["Naraxis"] = "naraxis",
    ["Snarlflare"] = "snarlflare",
    ["Mor'Ladim"] = "morladim",
}
local function CreerSpriteMenagerie(nom, defOpt)
    local def = defOpt or MHH_SPECIMENS[nom]
    local f = CreateFrame("Frame", nil, MHH_enclosMenagerie)
    f:SetSize(16 * MHH_TAILLE_PIX, 16 * MHH_TAILLE_PIX)
    -- TGA custom d'abord (Textures\Specimens\<slug>.tga)
    local slug = (defOpt and defOpt.slug) or MHH_SLUGS_SPRITES[nom]
    if slug then
        pcall(function()
            local t = f:CreateTexture(nil, "OVERLAY")
            t:SetAllPoints(f)
            if t:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\Specimens\\" .. slug .. ".tga") then
                f.utiliseTga = true
                -- Sprites 48x48 vue 3/4 DE DESSUS (style farm sim top-down) :
                -- rendu x2 -> 240 px à l'écran, présence nette dans l'enclos
                f:SetSize(16 * MHH_TAILLE_PIX * 2.4, 16 * MHH_TAILLE_PIX * 2.4)
                f.tgaA = t
                pcall(function() t:SetTexelSnappingBias(0) end) -- pixel art net
                -- FRAME 2 d'animation : <slug>_2.tga si le fichier existe
                -- (posture de marche/posée). Bascule automatique dans le
                -- rafraîchissement de l'enclos, cadence de la marche.
                local t2 = f:CreateTexture(nil, "OVERLAY")
                t2:SetAllPoints(f)
                if t2:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\Specimens\\" .. slug .. "_2.tga") then
                    f.tgaB = t2
                    t2:Hide()
                    pcall(function() t2:SetTexelSnappingBias(0) end)
                else
                    t2:Hide()
                end
            else
                t:Hide()
            end
        end)
    end
    if not f.utiliseTga then
    -- Animation 2 frames façon sprite rétro : phase A = grille telle
    -- quelle (debout), phase B = corps écrasé d'1 px vers le bas (pose,
    -- pattes plantées — les 2 dernières lignes ne bougent pas). La
    -- bascule se fait dans RaffraichirMenagerie, à la cadence de marche.
    local pa = CreateFrame("Frame", nil, f)
    pa:SetAllPoints(f)
    local pb = CreateFrame("Frame", nil, f)
    pb:SetAllPoints(f)
    pb:Hide()
    f.pa, f.pb = pa, pb
    local function DessinerGrille(cible, ecrase)
        for r = 1, 16 do
            local ligne = def.lignes[r] or ""
            for c = 1, 16 do
                local ch = ligne:sub(c, c)
                if ch ~= "." and ch ~= "" then
                    local coul = def.palette[ch]
                    if coul then
                        local t = cible:CreateTexture(nil, "OVERLAY")
                        t:SetSize(MHH_TAILLE_PIX, MHH_TAILLE_PIX)
                        -- pose écrasée : corps (lignes 1-14) enfoncé d'1 px,
                        -- pattes (lignes 15-16) au sol, bien plantées
                        local rr = (ecrase and r <= 14) and (r + 1) or r
                        t:SetPoint("TOPLEFT", (c - 1) * MHH_TAILLE_PIX, -(rr - 1) * MHH_TAILLE_PIX)
                        t:SetColorTexture(coul[1], coul[2], coul[3], 1)
                    end
                end
            end
        end
    end
    DessinerGrille(pa, false)
    DessinerGrille(pb, true)
    end -- fin repli grille pixel
    return f
end

-- Le régisseur de l'enclos : petit chat en tablier de camp qui veille
-- sur les pensionnaires — clin d'œil aux compagnons félins des camps
-- de chasse. Purement décoratif : il se balance doucement.
MHH_REGISSEUR = {
    slug = "regisseur",
    palette = {
        ["@"] = {0.55, 0.45, 0.38}, ["#"] = {0.33, 0.26, 0.22},
        ["o"] = {0.75, 1.0, 0.5},   ["+"] = {0.95, 0.93, 0.88},
        ["*"] = {1.0, 0.62, 0.75},
    },
    lignes = {
        ".@@..........@@.",
        ".@@@........@@@.",
        "..@@@@@@@@@@@@..",
        "..@@@@@@@@@@@@..",
        "..@@o@@@@@@o@@..",
        "..@@o@@@@@@o@@..",
        "..@@@@@**@@@@@..",
        "..@@@@@@@@@@@@..",
        "...@@@@@@@@@@...",
        "....@@++++@@....",
        "#..@@++++++@@...",
        "#..@@++++@@.....",
        "#..@@@@@@@@.....",
        "....@#....#@....",
        "....@#....#@....",
        "................",
    },
}
MHH_regisseurFrame = nil
pcall(function()
    MHH_regisseurFrame = CreerSpriteMenagerie(nil, MHH_REGISSEUR)
    MHH_regisseurFrame:SetPoint("BOTTOMRIGHT", MHH_enclosMenagerie, "BOTTOMRIGHT", -14, 10)
end)
-- Quand l'enclos est vide, le régisseur se la coule douce : boule
-- roulée, yeux fermés, petit « zz » qui flotte
MHH_REGISSEUR_DORT = {
    slug = "regisseur_dort",
    palette = MHH_REGISSEUR.palette,
    lignes = {
        "..........zz....",
        ".........z.z....",
        "................",
        "..@@@@..........",
        ".@@@@@@.........",
        ".@@#@@@.........",
        ".@@@@@@@@@@@....",
        "@@@@@@@@@@@@....",
        "@@@@@@@@@@@@@...",
        "@@@@@@@@@@@@@#..",
        "@@@@@@@@@@@@@@..",
        ".@@@@@@@@@@@#...",
        "..@@@@@@@@@.....",
        "................",
        "................",
        "................",
    },
}
MHH_regisseurDortFrame = nil
pcall(function()
    MHH_regisseurDortFrame = CreerSpriteMenagerie(nil, MHH_REGISSEUR_DORT)
    MHH_regisseurDortFrame:SetPoint("BOTTOMRIGHT", MHH_enclosMenagerie, "BOTTOMRIGHT", -14, 10)
    MHH_regisseurDortFrame:Hide()
end)

MHH_spritesMenagerie = {}
MHH_selectionMenagerie = nil
MHH_tickerMenagerie = nil

local function ArreterMenagerie()
    if MHH_tickerMenagerie then MHH_tickerMenagerie:Cancel() MHH_tickerMenagerie = nil end
end
-- Global : carnet:SetScript("OnHide") l'appelle pour couper le ticker
-- quand la fenêtre se ferme directement depuis l'onglet Ménagerie.
ArreterMenagerieGlobal = ArreterMenagerie
local function BoucleMenagerie()
    if not DB then return end
    -- Mini-météo : la météo réelle est revérifiée toutes les 1,5 s
    -- (léger), la chute des particules à chaque tic
    local maintenant = GetTime()
    if maintenant - MHH_meteoMenagerie.verif > 1.5 then
        MHH_meteoMenagerie.verif = maintenant
        local _, cle = MeteoActuelle()
        -- le ciel se rafraîchit à chaque revue (cycle jour/nuit), les
        -- particules seulement quand le temps change réellement
        ConfigurerMeteoEnclos(cle)
        if cle ~= MHH_meteoMenagerie.cle then
            MHH_meteoMenagerie.cle = cle
            ConfigurerParticulesEnclos(cle)
        end
    end
    for _, p in ipairs(MHH_particulesMenagerie) do
        if p.v > 0 then
            p.y = p.y + p.dir * p.v
            -- pluie de sable : légère dérive horizontale
            if MHH_meteoMenagerie.cle == "sandstorm" then
                p.x = p.x + 1.5
                if p.x > 532 then p.x = 0 end
            end
            -- hors enclos : on réapparaît de l'autre côté
            if p.dir > 0 and p.y > 176 then p.y = -8 p.x = math.random() * 532 end
            if p.dir < 0 and p.y < -8 then p.y = 176 p.x = math.random() * 532 end
            p.t:ClearAllPoints()
            p.t:SetPoint("TOPLEFT", MHH_enclosMenagerie, "TOPLEFT", p.x, p.y)
        end
    end
    -- INTRUS ACTIF : les pensionnaires paniquent (vitesse x4, direction
    -- fuante) jusqu'à ce que l'intrus s'en aille.
    local peur = MHH_intrus.nom and GetTime() < MHH_intrus.jusqua
    if MHH_intrus.nom and not peur then
        -- l'intrus s'enfuit : message de fin une seule fois
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffffcc66")
            .. MHH_intrus.nom .. L("|r repart d'où il vient. Le troupeau se calme."))
        MHH_intrus.nom = nil
    end
    for nom, s in pairs(MHH_spritesMenagerie) do
        local m = DB.menagerie and DB.menagerie[nom]
        if m then
            local etat = EtatSpecimen(m)
            local gate = m.gate and (time() - m.gate) < 3600
            if peur then
                s.vNormale = s.vNormale or s.v   -- mémorise l'allure normale
                s.v = 1.2                        -- panique : vitesse multipliée
                s.dir = (s.x < 266) and -1 or 1   -- fuir vers le bord proche
            elseif s.vNormale then
                s.v = s.vNormale                 -- l'intrus parti : reprise
                s.vNormale = nil
            end
            s.f:ClearAllPoints()
            -- Ombre portée : créée au premier passage, elle suit le sprite
            -- (ellipse sombre au sol, le bob la fait légèrement respirer).
            -- Sans elle, les bêtes semblaient flotter au-dessus de l'herbe.
            if not s.ombre then
                local om = MHH_enclosMenagerie:CreateTexture(nil, "BACKGROUND")
                om:SetSize(16 * MHH_TAILLE_PIX - 14, 7)
                om:SetColorTexture(0.05, 0.08, 0.04, 0.45)
                s.ombre = om
            end
            s.ombre:ClearAllPoints()
            if etat == "affame" then
                -- il boude : coin de l'enclos, tout pâle, immobile
                s.f:SetAlpha(0.35)
                s.f:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 8, 12)
                s.ombre:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 8 + s.f:GetWidth() / 2 - 33, 10)
                s.ombre:Show()
                if s.f.pa then s.f.pa:Show() s.f.pb:Hide() end
                if s.f.tgaA then s.f.tgaA:Show() end
                if s.f.tgaB then s.f.tgaB:Hide() end
            else
                s.f:SetAlpha(1)
                s.x = s.x + s.dir * s.v
                local maxi = MHH_enclosMenagerie:GetWidth() - 16 * MHH_TAILLE_PIX - 8
                if s.x < 4 then s.x = 4 s.dir = 1 end
                if s.x > maxi then s.x = maxi s.dir = -1 end
                -- petite marche sautillée ; s'il est gâté : il saute de joie
                local amp, freq = 3, 3
                if gate then amp, freq = 9, 7 end
                local bob = math.abs(math.sin(GetTime() * freq + s.phase)) * amp
                s.f:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", s.x, 12 + bob)
                -- l'ombre s'aplatit quand la bête saute : ancre le mouvement
                local omScale = 1 - bob * 0.045
                s.ombre:SetSize((16 * MHH_TAILLE_PIX - 14) * omScale, 7 * omScale)
                s.ombre:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", s.x + 7, 10)
                -- Animation 2 frames : la posture alterne à la cadence de
                -- la marche (debout / posée). Un pensionnaire gâté trottine.
                local phase = math.floor(GetTime() * (gate and 8 or 4) + s.phase) % 2
                if s.f.pa then
                    s.f.pa:SetShown(phase == 0)
                    s.f.pb:SetShown(phase == 1)
                end
                if s.f.tgaA and s.f.tgaB then
                    s.f.tgaA:SetShown(phase == 0)
                    s.f.tgaB:SetShown(phase == 1)
                end
            end
        end
    end
    -- Le régisseur se balance doucement, indifférent aux caprices ;
    -- endormi, il respire à peine
    if MHH_regisseurFrame and MHH_regisseurFrame:IsShown() then
        local b = math.sin(GetTime() * 1.2) * 1.5
        MHH_regisseurFrame:ClearAllPoints()
        MHH_regisseurFrame:SetPoint("BOTTOMRIGHT", MHH_enclosMenagerie, "BOTTOMRIGHT", -14, 10 + b)
    end
    if MHH_regisseurDortFrame and MHH_regisseurDortFrame:IsShown() then
        local b = math.sin(GetTime() * 0.8)
        MHH_regisseurDortFrame:ClearAllPoints()
        MHH_regisseurDortFrame:SetPoint("BOTTOMRIGHT", MHH_enclosMenagerie, "BOTTOMRIGHT", -14, 10 + b)
    end
end
local function DemarrerMenagerie()
    ArreterMenagerie()
    if C_Timer and C_Timer.NewTicker then
        MHH_tickerMenagerie = C_Timer.NewTicker(0.05, BoucleMenagerie)
    end
end
pageMenagerie:HookScript("OnHide", ArreterMenagerie)

-- SÉLECTEUR D'ENCLOS : un onglet par biome, débloqué au rang de guilde.
-- Le fond de l'enclos suit le biome choisi ; les slots ne montrent que
-- les pensionnaires/espèces de CE biome.
-- RaffraichirMenagerie est une fonction GLOBALE définie plus bas ; les
-- sélecteurs l'appellent à retardement (OnClick), donc pas de souci d'ordre.
MHH_boutonsEnclos = {}
for idxEnc, enc in ipairs(MHH_ENCLOS) do
    local b = CreateFrame("Button", nil, MHH_menagerieFond, MHH_TEMPLATE_BACKDROP)
    -- sélecteur sur la RANGÉE DU TITRE (à droite du titre MÉNAGERIE)
    b:SetPoint("TOPLEFT", MHH_menagerieFond, "TOPLEFT",
        250 + (idxEnc - 1) * 74, -8)
    b:SetSize(70, 16)
    b:SetNormalFontObject("GameFontHighlightSmall")
    b:SetText(enc.nom)
    b:GetFontString():SetPoint("CENTER", 0, 0)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    pcall(function()
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 6,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
    end)
    MHH_boutonsEnclos[enc.cle] = b
    -- Tooltip : rang requis si verrouillé, contenu sinon
    b:SetScript("OnEnter", function(self)
        if not GameTooltip or not DB then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cffffd100" .. enc.nom .. "|r")
        local idxRang = RangGuilde(DB.points or 0)
        if idxRang < enc.rang then
            GameTooltip:AddLine(L("|cffd87a6aVerrouillé|r — s'ouvre au rang |cffffff00")
                .. MHH_RANGS[enc.rang].nom .. L("|r"), 1, 1, 1, true)
            GameTooltip:AddLine(L("|cffa58b54Continuez à chasser pour gravir les rangs.|r"), 0.8, 0.8, 0.8, true)
        else
            local nb = 0
            for _, nom in ipairs(enc.specimens) do
                if DB.menagerie and DB.menagerie[nom] then nb = nb + 1 end
            end
            GameTooltip:AddLine(L("Pensionnaires : |cffffd100") .. nb .. " / " .. #enc.specimens, 1, 1, 1, true)
            if enc.cle == "volcan" then
                GameTooltip:AddLine(L("|cffa58b54Enclos d'apparat — déplacez-y vos pensionnaires favoris.|r"), 0.8, 0.8, 0.8, true)
            end
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnClick", function()
        if not DB then return end
        local idxRang = RangGuilde(DB.points or 0)
        if idxRang < enc.rang then
            -- verrouillé : le tooltip l'explique déjà — un discret tilt suffit
            if b:GetFontString() then
                local ancien = b:GetFontString():GetText()
                b:GetFontString():SetText("|cffff5050" .. enc.nom .. "|r")
                C_Timer.After(0.4, function()
                    if b:GetFontString() then b:GetFontString():SetText(ancien) end
                    RaffraichirMenagerie()
                end)
            end
            return
        end
        DB.enclosActif = enc.cle
        if MHH_ChargerFondEnclos then MHH_ChargerFondEnclos() end
        RaffraichirMenagerie()
    end)
end

-- Slots de sélection (4 x 2) : un par spécimen possible, « ??? » si
-- pas encore capturé
MHH_boutonsSpecimen = {}
local function BoutonSpecimen(i)
    local b = CreateFrame("Button", nil, MHH_menagerieFond, MHH_TEMPLATE_BACKDROP)
    b:SetPoint("TOPLEFT", MHH_menagerieFond, "TOPLEFT",
        10 + ((i - 1) % 4) * 134, -206 - math.floor((i - 1) / 4) * 32)
    b:SetSize(130, 26)
    pcall(function()
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        b:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
        b:SetBackdropBorderColor(0.45, 0.36, 0.20, 0.9)
    end)
    b.txt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.txt:SetPoint("CENTER")
    -- Surbrillance sur TOUT le bouton (le vieux Quickslot2 était illisible)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", function()
        -- le nom réel vient du biome affiché (MHH_boutonsSpecimen[i].nomSpecimen)
        MHH_selectionMenagerie = b.nomSpecimen or MHH_SPECIMENS_ORDRE[i]
        RaffraichirMenagerie()
    end)
    -- Tooltip : explique ce que montre le bouton (le « ???/famille »
    -- n'était pas clair sans explication)
    b:SetScript("OnEnter", function()
        if not GameTooltip then return end
        local nom = b.nomSpecimen or MHH_SPECIMENS_ORDRE[i]
        local m = DB.menagerie and DB.menagerie[nom]
        GameTooltip:SetOwner(b, "ANCHOR_TOPLEFT")
        if m then
            local _, libelle = EtatSpecimen(m)
            GameTooltip:AddLine(nom, 1, 0.82, 0)
            GameTooltip:AddLine(L("Spécimen en enclos — ") .. libelle, 0.8, 0.8, 0.8)
            GameTooltip:AddLine(L("Famille : ") .. MHH_SPECIMENS[nom].famille, 0.8, 0.8, 0.8)
            GameTooltip:AddLine(L("Clic : le sélectionner (nourrir / gâter / relâcher)."), 0.55, 0.75, 0.95)
        else
            GameTooltip:AddLine(L("Spécimen non capturé"), 0.6, 0.6, 0.6)
            GameTooltip:AddLine(L("Famille : ") .. MHH_SPECIMENS[nom].famille, 0.8, 0.8, 0.8)
            GameTooltip:AddLine(L("Capture-le : piège de chasse puis acheve-le,"), 0.8, 0.8, 0.8)
            GameTooltip:AddLine("ou apprivoise-le avec 5 viandes une fois abattu.", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(L("Clic : voir ses conditions."), 0.55, 0.75, 0.95)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return b
end

-- Ligne d'info + nourrissage
MHH_menagerieInfo = MHH_menagerieFond:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_menagerieInfo:SetPoint("TOPLEFT", MHH_menagerieFond, "TOPLEFT", 14, -266)
MHH_menagerieInfo:SetWidth(532)
MHH_menagerieInfo:SetWordWrap(true)
MHH_boutonNourrir = CreateFrame("Button", nil, MHH_menagerieFond, MHH_TEMPLATE_BACKDROP)
MHH_boutonNourrir:SetPoint("BOTTOM", MHH_menagerieFond, "BOTTOM", 68, 10)
MHH_boutonNourrir:SetSize(112, 22)
pcall(function()
    MHH_boutonNourrir:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    MHH_boutonNourrir:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    MHH_boutonNourrir:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
MHH_boutonNourrirTxt = MHH_boutonNourrir:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_boutonNourrirTxt:SetPoint("CENTER")
MHH_boutonNourrirTxt:SetShadowColor(0, 0, 0, 1)
MHH_boutonNourrirTxt:SetShadowOffset(1, -1)
MHH_boutonNourrir:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
MHH_boutonNourrir:SetScript("OnClick", function()
    if not MHH_selectionMenagerie or not DB.menagerie then return end
    local m = DB.menagerie[MHH_selectionMenagerie]
    if not m then
        -- Apprivoisement (repli sans piège) : le gibier doit déjà avoir
        -- été abattu, et il faut 5 viandes pour le dresser
        local kills = DB.chasses[MHH_selectionMenagerie] and DB.chasses[MHH_selectionMenagerie].kills or 0
        if kills < 1 then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Ce gibier n'a jamais été abattu — chasse-le d'abord."))
            return
        end
        if (DB.viande or 0) < 5 then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Il faut 5 viandes pour apprivoiser ce spécimen."))
            return
        end
        DB.viande = DB.viande - 5
        DB.menagerie[MHH_selectionMenagerie] = { capture = time(), nourri = time() }
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffffff00" .. MHH_selectionMenagerie
            .. L("|r est apprivoisé et rejoint l'enclos !"))
        RaffraichirMenagerie()
        return
    end
    if (DB.viande or 0) < 1 then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Pas de viande — chasse pour en récolter (40% par prise)."))
        return
    end
    DB.viande = DB.viande - 1
    m.nourri = time()
    SoinSpecimen(m, 4)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffffff00" .. MHH_selectionMenagerie
        .. L("|r se régale d'une viande de gibier."))
    RaffraichirMenagerie()
end)
MHH_boutonGater = CreateFrame("Button", nil, MHH_menagerieFond, MHH_TEMPLATE_BACKDROP)
MHH_boutonGater:SetPoint("BOTTOM", MHH_menagerieFond, "BOTTOM", 196, 10)
MHH_boutonGater:SetSize(112, 22)
pcall(function()
    MHH_boutonGater:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    MHH_boutonGater:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    MHH_boutonGater:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
MHH_boutonGaterTxt = MHH_boutonGater:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_boutonGaterTxt:SetPoint("CENTER")
MHH_boutonGaterTxt:SetShadowColor(0, 0, 0, 1)
MHH_boutonGaterTxt:SetShadowOffset(1, -1)
MHH_boutonGater:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
MHH_boutonGater:SetScript("OnClick", function()
    if not MHH_selectionMenagerie or not DB.menagerie then return end
    local m = DB.menagerie[MHH_selectionMenagerie]
    if not m then return end
    if (DB.miel or 0) < 1 then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Pas de miel — il se déniche sur les rares (10%)."))
        return
    end
    DB.miel = DB.miel - 1
    m.gate = time()
    SoinSpecimen(m, 10)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffffff00" .. MHH_selectionMenagerie
        .. "|r savoure son miel — regarde-le sauter de joie !")
    RaffraichirMenagerie()
end)
-- Relâcher : le spécimen repart dans la nature (la fiche de chasse reste)
MHH_boutonRelacher = CreateFrame("Button", nil, MHH_menagerieFond, MHH_TEMPLATE_BACKDROP)
MHH_boutonRelacher:SetPoint("BOTTOM", MHH_menagerieFond, "BOTTOM", -62, 10)
MHH_boutonRelacher:SetSize(112, 22)
pcall(function()
    MHH_boutonRelacher:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    MHH_boutonRelacher:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    MHH_boutonRelacher:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
MHH_boutonRelacherTxt = MHH_boutonRelacher:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_boutonRelacherTxt:SetPoint("CENTER")
MHH_boutonRelacherTxt:SetShadowColor(0, 0, 0, 1)
MHH_boutonRelacherTxt:SetShadowOffset(1, -1)
MHH_boutonRelacher:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
MHH_boutonRelacher:SetScript("OnClick", function()
    if not MHH_selectionMenagerie or not DB.menagerie then return end
    if not DB.menagerie[MHH_selectionMenagerie] then
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Ce spécimen n'est pas en enclos."))
        return
    end
    local nom = MHH_selectionMenagerie
    -- Relâcher un pensionnaire : contrepoint des primes de chasse, très MH
    DebloquerSucces("coeur_tendre")
    DB.menagerie[nom] = nil
    MHH_selectionMenagerie = nil
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r |cffffff00" .. nom
        .. L("|r repart dans la nature... bonne chance à lui, petit guy."))
    RaffraichirMenagerie()
end)
-- Tous nourrir : un clic, tous les pensionnaires affamés ou en petite faim
-- reçoivent une viande (jusqu'à épuisement de la réserve)
MHH_boutonTous = CreateFrame("Button", nil, MHH_menagerieFond, MHH_TEMPLATE_BACKDROP)
MHH_boutonTous:SetPoint("BOTTOM", MHH_menagerieFond, "BOTTOM", -190, 10)
MHH_boutonTous:SetSize(112, 22)
pcall(function()
    MHH_boutonTous:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    MHH_boutonTous:SetBackdropColor(0.30, 0.22, 0.10, 0.75)
    MHH_boutonTous:SetBackdropBorderColor(0.62, 0.48, 0.22, 0.9)
end)
MHH_boutonTousTxt = MHH_boutonTous:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MHH_boutonTousTxt:SetPoint("CENTER")
MHH_boutonTousTxt:SetShadowColor(0, 0, 0, 1)
MHH_boutonTousTxt:SetShadowOffset(1, -1)
MHH_boutonTous:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
MHH_boutonTous:SetScript("OnClick", function()
    if not DB.menagerie then return end
    local nourris = 0
    for _, nom in ipairs(MHH_SPECIMENS_ORDRE) do
        local m = DB.menagerie[nom]
        if m and EtatSpecimen(m) ~= "repu" then
            if (DB.viande or 0) < 1 then break end
            DB.viande = DB.viande - 1
            m.nourri = time()
            SoinSpecimen(m, 2)
            nourris = nourris + 1
        end
    end
    if nourris > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. nourris
            .. L(" pensionnaire(s) nourri(s) d'une viande chacun."))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Tout le monde est repu (ou plus de viande).")
    end
    RaffraichirMenagerie()
end)

-- INTRUS : parfois (20% à l'ouverture de l'onglet, 1 fois/heure max), un
-- gibier sauvage surgit dans l'enclos et affole les pensionnaires pendant
-- 12 s (ils se dispersent) ; s'il est encore là, il s'enfuit. Le message
-- indique sa zone — le chasseur sait où traquer la bestiole effrontée.
MHH_intrus = { nom = nil, jusqua = 0 }
local function PeutDeclencherIntrus()
    if not DB then return false end
    if not DB.menagerie then return false end
    local nb = 0
    for _ in pairs(DB.menagerie) do nb = nb + 1 end
    if nb == 0 then return false end        -- enclos vide : rien à effrayer
    if time() < (DB.intrusCooldown or 0) then return false end
    return math.random(100) <= 20
end
local function DeclencherIntrus()
    -- L'INTRUS : un gibier du CARNET DE CHASSE (rares Forever du data file —
    -- jamais un boss de raid ni un PNJ hors carnet). Préférence : une bête de
    -- la zone d'un pensionnaire de l'enclos affiché (cohérence), sinon
    -- n'importe quel rare catalogué.
    local biome = DB.enclosActif or "savane"
    local zonesResidents = {}
    for _, enc in ipairs(MHH_ENCLOS) do
        if enc.cle == biome then
            for _, nom in ipairs(enc.specimens) do
                local z = MHH_CATALOGUE[nom]
                if z then zonesResidents[z] = true end
            end
        end
    end
    local candidats, candidatsZone = {}, {}
    for nomC in pairs(MHH_CATALOGUE) do
        if MHH_EstNomAffichable(nomC) then
            candidats[#candidats + 1] = nomC
            if zonesResidents[MHH_CATALOGUE[nomC]] then
                candidatsZone[#candidatsZone + 1] = nomC
            end
        end
    end
    if #candidats == 0 then return end
    local liste = (#candidatsZone > 0) and candidatsZone or candidats
    local intrusNom = liste[math.random(#liste)]
    MHH_intrus.nom = intrusNom
    MHH_intrus.jusqua = GetTime() + 12
    DB.intrusCooldown = time() + 3600
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff5050Un intrus !|r ")
        .. intrusNom .. L(" saute la clôture de l'enclos et effraye le troupeau !"))
    ToastSucces("Interface\\Icons\\Ability_Hunter_BeastTaming",
        L("Intrus dans l'enclos"), intrusNom)
end

function RaffraichirMenagerie()
    if not DB then return end
    DB.menagerie = DB.menagerie or {}
    -- INTRUS : tirage à l'ouverture de l'enclos (garde-fou anti-spam)
    if not MHH_intrus.nom and PeutDeclencherIntrus() then DeclencherIntrus() end
    -- Succès « Enclos complet » : tous les spécimens de la savane capturés
    if DB.succes and not DB.succes["encloscomplet"] then
        local complet = true
        for _, nomC in ipairs(MHH_ENCLOS[1].specimens) do
            if not DB.menagerie[nomC] then complet = false break end
        end
        if complet then DebloquerSucces("encloscomplet") end
    end
    -- Enclos actif : le biome de rattachement du spécimen sélectionné, sinon
    -- le premier enclos débloqué (les vieux perros ont « savane » par défaut).
    local biome = DB.enclosActif or "savane"
    -- Onglets du sélecteur : actif = doré, verrouillé = grisé, dispo = neutre
    local idxRang = RangGuilde(DB.points or 0)
    for _, enc in ipairs(MHH_ENCLOS) do
        local b = MHH_boutonsEnclos[enc.cle]
        if b then
            if enc.cle == biome then
                b:GetFontString():SetText("|cffffd100" .. enc.nom .. "|r")
                pcall(function() b:SetBackdropBorderColor(0.9, 0.75, 0.35, 1) end)
            elseif idxRang < enc.rang then
                b:GetFontString():SetText("|cff555555" .. enc.nom .. "|r")
                pcall(function() b:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8) end)
            else
                b:GetFontString():SetText(enc.nom)
                pcall(function() b:SetBackdropBorderColor(0.45, 0.36, 0.2, 0.9) end)
            end
        end
    end
    -- Pensionnaires du biome affiché (ranch des savanes au premier plan)
    local specimensBiome = {}
    for _, enc in ipairs(MHH_ENCLOS) do
        if enc.cle == biome then
            for _, nom in ipairs(enc.specimens) do
                specimensBiome[#specimensBiome + 1] = nom
            end
        end
    end
    -- Sprites : créer si besoin, montrer/cacher selon capture ET biome
    for _, nom in ipairs(MHH_SPECIMENS_ORDRE) do
        local dansBiome = (MHH_ENCLOS_DU_SPECIMEN[nom] == biome)
        if DB.menagerie[nom] and dansBiome then
            if not MHH_spritesMenagerie[nom] then
                MHH_spritesMenagerie[nom] = {
                    f = CreerSpriteMenagerie(nom),
                    x = 20 + math.random(0, 300),
                    dir = (math.random(2) == 1) and 1 or -1,
                    v = 0.15 + math.random() * 0.3,
                    phase = math.random() * 6,
                }
            end
            MHH_spritesMenagerie[nom].f:Show()
        elseif MHH_spritesMenagerie[nom] then
            MHH_spritesMenagerie[nom].f:Hide()
            if MHH_spritesMenagerie[nom].ombre then
                MHH_spritesMenagerie[nom].ombre:Hide()
            end
        end
    end
    -- Ce biome compte-t-il des pensionnaires ?
    local nbCaptures = 0
    for _, nom in ipairs(specimensBiome) do
        if DB.menagerie[nom] then nbCaptures = nbCaptures + 1 end
    end
    MHH_enclosVide:SetShown(nbCaptures == 0)
    -- Le régisseur : debout dès qu'il a du monde, roulé en boule sinon
    if MHH_regisseurFrame then MHH_regisseurFrame:SetShown(nbCaptures > 0) end
    if MHH_regisseurDortFrame then MHH_regisseurDortFrame:SetShown(nbCaptures == 0) end
    -- Slots : espèces du biome affiché uniquement (les surnuméraires masqués)
    for i = #specimensBiome + 1, #MHH_boutonsSpecimen do
        if MHH_boutonsSpecimen[i] and MHH_boutonsSpecimen[i].Hide then
            MHH_boutonsSpecimen[i]:Hide()
        end
    end
    for i, nom in ipairs(specimensBiome) do
        if not MHH_boutonsSpecimen[i] then MHH_boutonsSpecimen[i] = BoutonSpecimen(i) end
        MHH_boutonsSpecimen[i]:Show()
        local capt = DB.menagerie[nom]
        MHH_boutonsSpecimen[i].nomSpecimen = nom
        if capt then
            local _, libelle = EtatSpecimen(capt)
            MHH_boutonsSpecimen[i].txt:SetText("|cffffd100" .. nom .. "|r — " .. libelle
                .. " |cffc9a24a(" .. AffiniteLibelle(Affinite(capt)) .. ")|r")
        else
            MHH_boutonsSpecimen[i].txt:SetText("|cff8a6d3b???|r |cffc9a24a(" .. MHH_SPECIMENS[nom].famille .. ")|r")
        end
    end
    -- Nourrissage rapide : combien de bouches à nourrir ?
    local nbFaim = 0
    for _, nom in ipairs(MHH_SPECIMENS_ORDRE) do
        local capt = DB.menagerie[nom]
        if capt and EtatSpecimen(capt) ~= "repu" then nbFaim = nbFaim + 1 end
    end
    if nbFaim > 0 then
        MHH_boutonTousTxt:SetText("|cffffd100Tous nourrir|r (" .. nbFaim .. ")")
    else
        MHH_boutonTousTxt:SetText("|cff8a6d3bTous repus|r")
    end
    -- Sélection : conservée même non-capturée (pour l'apprivoisement),
    -- premier capturé par défaut
    if MHH_selectionMenagerie and not MHH_SPECIMENS[MHH_selectionMenagerie] then
        MHH_selectionMenagerie = nil
    end
    if not MHH_selectionMenagerie then
        for _, nom in ipairs(MHH_SPECIMENS_ORDRE) do
            if DB.menagerie[nom] then MHH_selectionMenagerie = nom break end
        end
    end
    if MHH_selectionMenagerie then
        local m = DB.menagerie[MHH_selectionMenagerie]
        local kills = DB.chasses[MHH_selectionMenagerie] and DB.chasses[MHH_selectionMenagerie].kills or 0
        if m then
            local _, libelle = EtatSpecimen(m)
            local gate = m.gate and (time() - m.gate) < 3600
            MHH_menagerieInfo:SetText("|cffffff00" .. MHH_selectionMenagerie .. "|r |cffc9a24a("
                .. MHH_SPECIMENS[MHH_selectionMenagerie].famille .. L(")|r — ") .. libelle
                .. L(", nourri il y a ") .. IlYA(m.nourri or m.capture or time())
                .. (gate and L(" |cffff7a1a— gâté au miel !|r") or ""))
            MHH_boutonNourrirTxt:SetText("|cffffd100Nourrir|r (1 viande : " .. (DB.viande or 0) .. ")")
            MHH_boutonGaterTxt:SetText("|cffffd100Gâter|r (1 miel : " .. (DB.miel or 0) .. ")")
            MHH_boutonRelacherTxt:SetText("|cffd87a6aRelâcher|r")
        elseif kills > 0 then
            MHH_menagerieInfo:SetText("|cffffff00" .. MHH_selectionMenagerie .. "|r |cffc9a24a("
                .. MHH_SPECIMENS[MHH_selectionMenagerie].famille .. L(")|r — |cff8a6d3bpas en enclos :|r ")
                .. "apprivoise-le avec 5 viandes (" .. (DB.viande or 0) .. L(" en réserve)."))
            MHH_boutonNourrirTxt:SetText("|cffffd100Apprivoiser|r (5 viandes)")
            MHH_boutonGaterTxt:SetText("|cffffd100Gâter|r")
            MHH_boutonRelacherTxt:SetText("|cff8a6d3bRelâcher|r")
        else
            MHH_menagerieInfo:SetText("|cffffff00" .. MHH_selectionMenagerie .. "|r |cffc9a24a("
                .. MHH_SPECIMENS[MHH_selectionMenagerie].famille .. L(")|r — |cff8a6d3bnon abattu :|r ")
                .. "chasse-le, puis apprivoise-le avec 5 viandes.")
            MHH_boutonNourrirTxt:SetText("|cff8a6d3bApprivoiser|r (5 viandes)")
            MHH_boutonGaterTxt:SetText("|cffffd100Gâter|r")
            MHH_boutonRelacherTxt:SetText("|cff8a6d3bRelâcher|r")
        end
    else
        MHH_menagerieInfo:SetText(L("|cff8a6d3bSélectionne un spécimen capturé pour le nourrir.|r"))
        MHH_boutonNourrirTxt:SetText("|cffffd100Nourrir|r")
        MHH_boutonGaterTxt:SetText("|cffffd100Gâter|r")
    end
    DemarrerMenagerie()
end

function AfficherOnglet(id)
    -- L'indice pulsant « Ton gibier t'attend ici » disparaît dès qu'on
    -- visite la page Gibier (première visite mémorisée dans la config)
    if CacherIndiceGibier then CacherIndiceGibier(id) end
    pageAccueil:SetShown(id == "accueil")
    pageMonstres:SetShown(id == "monstres")
    pageSucces:SetShown(id == "succes")
    pageProfil:SetShown(id == "profil")
    pageContrats:SetShown(id == "contrats")
    pageCuisine:SetShown(id == "cuisine")
    pageMissions:SetShown(id == "missions")
    pageMenagerie:SetShown(id == "menagerie")
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
    elseif id == "cuisine" then RaffraichirCuisine()
    elseif id == "missions" then MHH_RaffraichirMissions()
    elseif id == "menagerie" then RaffraichirMenagerie()
    elseif id == "options" then RaffraichirOptions() end
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
    -- Intro guidée : une fois le tuto lu, on pointe l'onglet Gibier
    if DB and not DB.config.gibierVu then AfficherIndiceGibier() end
end)
MHH_tutoPan:SetScript("OnHide", function()
    if DB and MHH_tutoCoche:GetChecked() then DB.tutoPanVu = true end
end)
MHH_tutoPan:Hide()

-- Indice pulsant « → Ton gibier t'attend ici » : flèche d'objectif collée
-- à l'onglet Gibier après le tuto, façon guide MH. S'efface au premier
-- clic sur l'onglet (mémorisé dans DB.config.gibierVu).
-- NB : rattaché au carnet (pas UIParent) : il se cache avec lui.
local indiceGibier = CreateFrame("Frame", nil, carnet)
indiceGibier:SetSize(210, 26)
indiceGibier:SetFrameLevel(15)
pcall(function()
    indiceGibier:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    indiceGibier:SetBackdropColor(0.05, 0.03, 0.01, 0.85)
    indiceGibier:SetBackdropBorderColor(0.98, 0.72, 0.30, 0.9)
end)
local indiceGibierTxt = indiceGibier:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
indiceGibierTxt:SetPoint("CENTER")
indiceGibierTxt:SetText(L("|cffffd100» Ton gibier t'attend ici|r"))
indiceGibierTxt:SetShadowColor(0, 0, 0, 1)
indiceGibierTxt:SetShadowOffset(1, -1)
indiceGibier:Hide()
local tickerIndice = nil
function AfficherIndiceGibier()
    if DB and DB.config.gibierVu then return end
    if not indiceGibier or not onglets["monstres"] then return end
    -- Suivre l'onglet : il bouge quand il est actif/désactivé
    indiceGibier:ClearAllPoints()
    indiceGibier:SetPoint("RIGHT", onglets["monstres"], "LEFT", 8, 0)
    indiceGibier:Show()
    if tickerIndice then tickerIndice:Cancel() end
    tickerIndice = C_Timer.NewTicker(0.4, function()
        -- Pulsation douce : respiration entre 0.45 et 1
        local a = 0.72 + 0.28 * math.sin((GetTime() or 0) * math.pi)
        indiceGibier:SetAlpha(a)
    end)
end
function CacherIndiceGibier(id)
    -- Seul le clic sur l'onglet Gibier valide l'intro guidée
    if id and id ~= "monstres" then return end
    if id == "monstres" and DB then DB.config.gibierVu = true end
    if tickerIndice then tickerIndice:Cancel() tickerIndice = nil end
    if indiceGibier then
        indiceGibier:SetAlpha(1)
        indiceGibier:Hide()
    end
end

-- Son à l'ouverture/fermeture du carnet (SFX du jeu, style journal)
carnet:SetScript("OnShow", function()
    if DB and DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 845) end
    -- Tuto de bienvenue : panneau « Bonne chasse » à la première ouverture
    -- (case « Ne plus afficher » ; /hunt tuto pour le faire revenir)
    if DB and not DB.tutoPanVu and MHH_tutoPan then
        MontrerTuto()
    elseif DB and not DB.config.gibierVu and AfficherIndiceGibier then
        AfficherIndiceGibier()
    end
    AfficherOnglet("accueil")
end)
carnet:SetScript("OnHide", function()
    if DB and DB.config.son then JouerSon(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_CLOSE or 844) end
    -- L'indice « gibier t'attend ici » ne doit pas survivre au carnet :
    -- on l'efface sans marquer la visite (id nil = simple masquage)
    if CacherIndiceGibier then CacherIndiceGibier(nil) end
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
    GameTooltip:AddLine(nbChasses() .. L(" chasses réussies."))
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
MHH_chronoChasse:SetSize(360, 124) -- ratio proche de chrono.tga (1037x348 ≈ 3:1)
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
MHH_chronoChasseTitre:SetWidth(336)
MHH_chronoChasseTitre:SetShadowColor(0, 0, 0, 1)
MHH_chronoChasseTitre:SetShadowOffset(1, -1)
pcall(function() MHH_chronoChasseTitre:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE") end)
MHH_chronoChasseTxt = MHH_chronoChasse:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MHH_chronoChasseTxt:SetPoint("TOP", 0, -66)
MHH_chronoChasseTxt:SetWidth(336)
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
    indicateurChasse:SetWidth(math.min(300, math.max(110, 46 + #DB.contrat * 6.5)))
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
        -- Contrat sur 2 lignes : libellé centré, cible en dessous
        indicateurChasseTxt:SetText("|cffff69b4CONTRAT :|r\n|cffffff00" .. DB.contrat .. "|r")
        indicateurChasse:SetHeight(36)
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
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt texui custom/wow|r : textures bandeau/zone/chrono."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt chrono full/minimap/off|r : chrono de chasse. |cffffd100/hunt musique off/wow/custom|r : musiques."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt titre <famille>|r : naturaliste, chasseur, explorateur, traqueur."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt test zone|banniere|chrono|en chasse|prime|menagerie|r : prévisualisations. |cffffd100/hunt test chemin <mp3>|r, |cffffd100/hunt test son <id>|r : essais audio."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt tuto|r : revoir le panneau de bienvenue. |cffffd100/hunt lisere <1-5|0>|r : couleur du liseré de rang."))
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt carte <joueur>|r : envoyer votre carte de chasseur (rang, points, enclos) à un autre chasseur de l'addon."))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffc9a24a•|r |cffffd100/hunt langue fr|en|r : langue de l'interface (publication).")
        DEFAULT_CHAT_FRAME:AddMessage(L("  |cffc9a24a•|r |cffffd100/hunt debug|r : diagnostic. |cffffd100/hunt armes|r : diagnostic des armes de chasse. |cffffd100/hunt export|r : liste « nom | id | zone » des découvertes (réconciliation Forever). |cffffd100/hunt reset succes|missions|menagerie|carnet|r : remises à zéro ciblées. |cffffd100/hunt reset|r : tout effacer (irréversible)."))
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
            local nom = UnitName("target") or ""
            local idR = nil
            local guid = UnitGUID("target")
            if guid then idR = tonumber(guid:match("-(%d+)$")) end
            DB.decouverts[nom] = DB.decouverts[nom] or { kills = 0, vu = true, zone = GetZoneText(), decouvert = time(), id = idR, nouveau = true }
            DB.decouverts[nom].vu = true
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. nom .. L(" ajouté au carnet."))
        else
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Ciblez d'abord une créature."))
        end
    elseif cmd == "remove" then
        if UnitExists("target") then
            local nom = UnitName("target") or ""
            DB.decouverts[nom] = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. nom .. L(" retiré du carnet."))
        end
    elseif cmd == "banner on" then DB.config.banniere = true DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Bannière activée."))
    elseif cmd == "banner off" then DB.config.banniere = false DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Bannière désactivée."))
    elseif cmd == "sound on" then DB.config.son = true DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Sons activés."))
    elseif cmd == "sound off" then DB.config.son = false DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Sons désactivés."))
    elseif cmd == "armes" then
        -- Diagnostic de l'histogramme des armes : ce que le client renvoie
        -- VRAIMENT pour l'arme en main droite, et ce que la DB contient.
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Diagnostic des armes de chasse :")
        local idArmeD = GetInventoryItemID and GetInventoryItemID("player", 16)
        local lienArmeD = GetInventoryItemLink and GetInventoryItemLink("player", 16)
        DEFAULT_CHAT_FRAME:AddMessage("  Arme main droite : id=" .. tostring(idArmeD) .. " lien=" .. tostring(lienArmeD))
        if lienArmeD then
            local _, nomD, _, _, _, _, _, typeD, sousD = pcall(GetItemInfo, lienArmeD)
            DEFAULT_CHAT_FRAME:AddMessage("  GetItemInfo(lien) : nom=" .. tostring(nomD) .. " classe=" .. tostring(typeD) .. " sous-classe=" .. tostring(sousD))
        end
        if idArmeD then
            local _, nomD2, _, _, _, _, _, typeD2, sousD2 = pcall(GetItemInfo, idArmeD)
            DEFAULT_CHAT_FRAME:AddMessage("  GetItemInfo(id) : nom=" .. tostring(nomD2) .. " classe=" .. tostring(typeD2) .. " sous-classe=" .. tostring(sousD2))
        end
        if DB.armes then
            for a, nArme in pairs(DB.armes) do
                DEFAULT_CHAT_FRAME:AddMessage("  DB.armes : " .. tostring(a) .. " = " .. tostring(nArme))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("  DB.armes : vide")
        end
        DEFAULT_CHAT_FRAME:AddMessage("  → Histogramme : bouton d'icône de classe, page Profil.")
    elseif cmd == "kill loose" then DB.config.killSouple = true DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Kill souple (la participation compte).")
    elseif cmd == "kill strict" then DB.config.killSouple = false DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Kill strict (le coup de grâce doit être le vôtre)."))
    elseif cmd == "icon custom" then DB.config.icone = "custom" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Icône custom — nécessite /reload."))
    elseif cmd == "icon wow" then DB.config.icone = "wow" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Icône WoW — nécessite /reload."))
    elseif cmd == "parchment custom" then DB.config.fond = "custom" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Parchemin custom — nécessite /reload."))
    elseif cmd == "parchment wow" then DB.config.fond = "wow" DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Fond WoW — nécessite /reload."))
    elseif cmd == "titre" or cmd:match("^titre ") then
        local famille = cmd:match("^titre (%S+)$")
        if famille and TITRES[famille] then
            DB.titreFamille = famille
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Titre affiché : « ") .. TitreDeFamille(famille) .. " » (" .. famille .. ")")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Titre actuel : « " .. TitreDeFamille(DB.titreFamille or "naturaliste") .. " » — famille : " .. (DB.titreFamille or "naturaliste"))
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r /hunt titre naturaliste | chasseur | explorateur | traqueur"))
        end
        RaffraichirProfil()
    elseif cmd == "texui custom" then
        DB.config.texUI = "custom"
        if AppliquerTexUI then AppliquerTexUI() end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Textures UI custom : bandeau.tga / zone.tga / chrono.tga (dossier Textures).")
    elseif cmd == "texui wow" then
        DB.config.texUI = "wow"
        if AppliquerTexUI then AppliquerTexUI() end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Textures UI standard (WoW).")
    elseif cmd == "test zone" then
        MHH_AnnonceZone(true)
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : annonce de zone affichée."))
    elseif cmd == "test banniere" then
        AfficherBanniere(L("CHASSE RÉUSSIE — MISSION ACCOMPLIE"), 0.4, 1, 0.4)
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : bannière centrale affichée."))
    elseif cmd == "test chrono" then
        -- Chrono animé : compte réellement 10 s pour voir le rendu final.
        -- NB : `local tick` d'abord, tick:Cancel() dans la closure sinon
        -- tick est global (nil) — bug corrigé.
        local debut = time()
        MHH_chronoChasseTitre:SetText("|cffffd100Humar le Seigneur hautain|r")
        MHH_chronoChasseTxt:SetText("|cffff7a1a0:00|r  |cff8a6d3b(record : 0:58)|r")
        local tick
        FonduDoux(MHH_chronoChasse, 0, 1, 0.6, function()
            tick = C_Timer.NewTicker(1, function()
                local d = time() - debut
                MHH_chronoChasseTxt:SetText("|cffff7a1a"
                    .. FormatDuree(d) .. "|r  |cff8a6d3b(record : 0:58)|r")
                if d >= 10 then
                    tick:Cancel()
                    if not chasseActive then
                        FonduDoux(MHH_chronoChasse, 1, 0, 0.6, function()
                            MHH_chronoChasse:Hide()
                            MHH_chronoChasse:SetAlpha(1)
                        end)
                    end
                end
            end)
        end)
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : chrono lancé (10 s), fondu à l'entrée et à la sortie."))
    elseif cmd == "test en chasse" then
        -- Prévi du comportement réel : bandeau « EN CHASSE » éphémère
        -- (4 s) puis seulement le mini chrono en coin, rien d'autre.
        if not chasseActive then
            chasseActive = "Aperçu (test)"
            chasseDebutTemps = time()
            MettreAJourIndicateur()
            BandeauChasseEphemer()
            C_Timer.After(6, function()
                if chasseActive == "Aperçu (test)" then
                    chasseActive = nil
                    MettreAJourIndicateur()
                end
            end)
        else
            BandeauChasseEphemer()
        end
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : bandeau En chasse éphémère (4 s), puis mini chrono en coin."))
    elseif cmd == "test prime" then
        DB.contratJour = nil
        ContratQuotidien()
        if RaffraichirAccueil then RaffraichirAccueil() end
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : cible du jour relancée (toast + plaque Accueil)."))
    elseif cmd:match("^carte %S+$") then
        -- Carte de chasseur : données publiques uniquement (rang, points,
        -- chasses, enclos, dernière prise) — JAMAIS le carnet de découverte
        local destinataire = cmd:match("^carte (%S+)$")
        local captures = 0
        if DB.menagerie then for _ in pairs(DB.menagerie) do captures = captures + 1 end end
        local carte = "CARTE:" .. (select(2, RangGuilde(DB.points or 0)) or "?")
            .. "|" .. (DB.points or 0)
            .. "|" .. nbChasses()
            .. "|" .. captures
            .. "|" .. (DB.dernierePriseNom or "-")
        local ok = pcall(function()
            if C_Chat and C_Chat.SendAddonMessage then
                C_Chat.SendAddonMessage("MHHUNT", carte, "WHISPER", destinataire)
            else
                SendAddonMessage("MHHUNT", carte, "WHISPER", destinataire)
            end
        end)
        if ok then
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Carte de chasseur envoyée à |cffffff00")
                .. destinataire .. "|r (visible s'il a l'addon).")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Envoi impossible — joueur introuvable ?")
        end
    elseif cmd == "test menagerie" then
        -- Remplissage de test : ingrédients + les 8 spécimens en enclos
        -- (dont un affamé qui boude et un gâté qui saute), pour tester
        -- la page Ménagerie sans chasse préalable
        DB.viande = (DB.viande or 0) + 20
        DB.miel = (DB.miel or 0) + 10
        DB.menagerie = DB.menagerie or {}
        for _, nom in ipairs(MHH_SPECIMENS_ORDRE) do
            -- Fiche au carnet SANS kill : les tests ne doivent jamais
            -- gonfler le compteur de prises ni colorer la bête en
            -- « déjà chassée ». kills reste à 0.
            DB.chasses[nom] = DB.chasses[nom] or { kills = 0, vu = true }
            DB.chasses[nom].vu = true
            DB.menagerie[nom] = { capture = time(), nourri = time() }
        end
        -- états variés : l'un boude (affamé depuis 4 jours), un autre gâté
        DB.menagerie["Mor'Ladim"].nourri = time() - 4 * 86400
        DB.menagerie["Naraxis"].gate = time()
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : +20 viandes, +10 miels, 8 spécimens en enclos (dont un affamé et un gâté)."))
        OuvrirCarnet("menagerie")
    elseif cmd == "test menagerie off" then
        DB.menagerie = nil
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Test : enclos vidé (l'apprivoisement reste testable, les fiches sont conservées)."))
        if RaffraichirMenagerie then RaffraichirMenagerie() end
    elseif cmd == "musique off" or cmd == "musique wow" or cmd == "musique custom" then
        DB.config.musique = cmd:sub(9)
        MHH_ArreterMusique()
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Musiques : |cffffff00" .. DB.config.musique
            .. "|r." .. (DB.config.musique == "custom" and L(" (MHAmbiance/Sounds : promotion.mp3, combat.mp3, traque.mp3 — fichiers ajoutés après lancement du jeu = redémarrage client requis.)") or ""))
    elseif cmd:match("^test chemin .+") then
        local piste = cmd:match("^test chemin (.+)$")
        PlaySoundFile(piste)
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Test : |cffffff00" .. piste .. "|r — si aucun son, le fichier n'existe pas dans vos MPQ.")
    elseif cmd:match("^test son %d+$") then
        -- Son par identifiant (ex. 552503 = Illidan « Vous n'êtes pas prêt »)
        local id = tonumber(cmd:match("^test son (%d+)$"))
        PlaySoundFile(id)
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Test : son |cffffff00" .. id .. L("|r joué — aucun son = identifiant inconnu sur ce client."))
    elseif cmd == "chrono full" or cmd == "chrono minimap" or cmd == "chrono off" then
        DB.config.chronoMode = cmd:sub(8)
        MHH_chronoMini:Hide()
        MHH_chronoMiniFond:Hide()
        if chasseActive then MettreAJourIndicateur() end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Chrono : |cffffff00" .. DB.config.chronoMode
            .. "|r — " .. (DB.config.chronoMode == "full" and L("grand encart pendant la chasse")
            or (DB.config.chronoMode == "minimap" and "miniature sous le bouton minimap" or L("désactivé"))) .. ".")
    elseif cmd:match("^lisere %d+$") then
        -- Test du liseré de rang : /hunt lisere <1-5> ; 0 = rang réel
        -- NB : la prochaine ouverture du carnet recolore selon le vrai rang.
        local n = tonumber(cmd:match("^lisere (%d+)$"))
        local idx
        if n == 0 then
            idx = RangGuilde(DB.points or 0)
        elseif MHH_RANGS[n] and MHH_COULEURS_RANG[n] then
            idx = n
        else
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Usage : /hunt lisere <1-5> (0 = rang réel)."))
            idx = nil
        end
        if idx then
            local cr = MHH_COULEURS_RANG[idx] or MHH_COULEURS_RANG[1]
            if carnetLisere then
                for i = 1, 4 do carnetLisere[i]:SetColorTexture(cr[1], cr[2], cr[3], 0.95) end
            end
            DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Liseré : |cffffff00") .. MHH_RANGS[idx].nom
                .. "|r (" .. idx .. L("/5) — /hunt lisere 0 pour revenir au rang réel."))
        end
    elseif cmd == "debug" then
        -- Diagnostic : bascule le traçage des canaux de détection + état
        DB.config.debug = not DB.config.debug
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Debug : chasseActive=") .. (chasseActive or "nil") .. L(", contrat=") .. (DB.contrat or "nil") .. L(", points=") .. (DB.points or 0))
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Traçage des détections de mort : |cffffff00") .. (DB.config.debug and L("ACTIVÉ") or L("désactivé")) .. "|r (journal, fin de combat, viseur, chrono).")
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Musique : mode=|cffffff00") .. tostring(DB.config.musique) .. "|r, état=" .. tostring(musiqueEtat)
            .. L(", son ambiant coupé=") .. tostring(sonAmbiantCoupe)
            .. L(", C_Sound.PlaySoundFile=") .. tostring(C_Sound ~= nil and C_Sound.PlaySoundFile ~= nil))
        indicateurChasse:Show()
        C_Timer.After(5, function() MettreAJourIndicateur() end)
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
    elseif cmd == "reset" then
        for k in pairs(LaChasseDB) do LaChasseDB[k] = nil end
        InitDB()
        DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r Base réinitialisée."))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r /hunt (carnet), /hunt aide, /hunt tuto, /hunt achievements, /hunt add|remove, /hunt banner on|off, /hunt sound on|off, /hunt kill loose|strict, /hunt icon custom|wow, /hunt parchment custom|wow, /hunt texui custom|wow, /hunt titre <famille>, /hunt test zone|banniere|chrono|en chasse|prime, /hunt test chemin <chemin mp3>, /hunt test son <id>, /hunt musique off|wow|custom, /hunt chrono full|minimap|off, /hunt carte <joueur>, /hunt lisere <1-5|0>, /hunt ajuster <nom> <±n>, /hunt reset kills, /hunt reset succes|missions|menagerie|carnet, /hunt export, /hunt langue fr|en, /hunt debug, /hunt armes, /hunt reset")
    end
end
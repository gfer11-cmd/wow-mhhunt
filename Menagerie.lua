-- ================================================================
-- MHHunt — Menagerie.lua (extrait de mhhunt.lua v0.67, échelle v0.68)
-- Page Ménagerie : enclos, pensionnaires, régisseur, bâtiments,
-- météo, boucle d'animation. Autonome vis-à-vis du fichier
-- principal : ne consomme que les ponts ci-dessous.
-- ORDRE DE CHARGEMENT (.toc) :
--     MHHuntData.lua
--     mhhunt.lua        (core + carnet + événements)
--     Menagerie.lua     (cette page)
-- ================================================================

-- ===== PONT vers mhhunt.lua (symboles exposés en fin de fichier principal) =====
local L              = MHH_L               -- traduction
local carnet         = MHH_Carnet          -- frame principale du carnet
local MeteoActuelle  = MHH_MeteoActuelle   -- météo réelle du client
-- DB n'est PAS un local ici : la table n'existe qu'après ADDON_LOADED.
-- On utilise MHH_DB (mis à jour par le fichier principal à cet instant).

-- ================= PAGE MÉNAGERIE (enclos) =================
-- L'enclos : les spécimens capturés (piege + kill) s'y baladent en pixel
-- art. La viande et le miel récoltés en chasse servent à nourrir/gâter.
local pageMenagerie = CreateFrame("Frame", nil, carnet)
MHH_pageMenagerie = pageMenagerie -- expose : AfficherOnglet (mhhunt.lua) l affiche/cache
pageMenagerie:SetAllPoints()
pageMenagerie:Hide()

-- v0.112 : CADREUR 4 TEXTURES — SetBackdrop ne s'affiche pas sur
-- tous les clients (retour utilisateur : liseré invisible, HUD sans
-- bord). Quatre textures plates, ça ne peut PAS ne pas s'afficher.
-- ep = épaisseur du trait en px.
MHH_Cadrer = function(parent, r, g, b, a, ep)
    local function trait(cote, w, h)
        local t = parent:CreateTexture(nil, "ARTWORK")
        t:SetSize(w, h)
        t:SetPoint(cote, parent, cote, 0, 0)
        t:SetColorTexture(r, g, b, a)
        return t
    end
    local L = parent:GetWidth() or 10
    local H = parent:GetHeight() or 10
    trait("TOPLEFT", L, ep)
    trait("BOTTOMLEFT", L, ep)
    trait("LEFT", ep, H)
    trait("RIGHT", ep, H)
end

-- v0.112 : OMBRE PROCÉDURALE — 3 bandes plates empilées, de plus en
-- plus étroites et denses : un faux dégradé doux SANS aucun fichier
-- TGA (ombre.tga ne se chargeait pas de façon fiable sur le client :
-- SetTexture paresseux + retour nil => repli jamais déclenché, ombre
-- invisible — retour utilisateur « ils font collés »).
-- Retourne une FRAME : SetSize/SetPoint/Show/Hide marchent comme sur
-- l'ancienne texture, le code d'errance n'a pas changé.
MHH_OmbrePlate = function(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:EnableMouse(false)
    -- v0.156 : RECETTE GOBLIN v0.155, VALIDÉE EN JEU — tout en couche
    -- ARTWORK (seule couche confirmée visible sur ce client, retour :
    -- « on en a une ! »). Disparaissent : le TGA (jamais rendu) et le
    -- rectangle noir PLEIN alpha 1 (c'était LUI qu'on voyait sur les
    -- pensionnaires, dur et carré). 4 plans empilés par ancres : le
    -- dégradé suit n'importe quel SetSize fait après création.
    local function bande(ix, iy, al)
        local b = f:CreateTexture(nil, "ARTWORK")
        b:SetPoint("TOPLEFT", f, "TOPLEFT", ix, iy)
        b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -ix, -iy)
        b:SetColorTexture(0, 0, 0, al)
        return b
    end
    bande(0, 0, 0.06)   -- halo large
    bande(1, 0, 0.12)
    bande(3, 0, 0.18)
    bande(5, 1, 0.26)   -- coeur (cumul ~0,49 : doux)
    return f
end

-- v0.118o : SECOURS TEMPLATE — si Menagerie.lua est parsé AVANT
-- mhhunt.lua, MHH_TEMPLATE_BACKDROP valait nil ici et SetBackdrop ne
-- rendait RIEN (fiche sans bordure WoW, retour utilisateur).
if not MHH_TEMPLATE_BACKDROP and BackdropTemplateMixin then
    MHH_TEMPLATE_BACKDROP = "BackdropTemplate"
end
MHH_menagerieFond = CreateFrame("Frame", nil, pageMenagerie, MHH_TEMPLATE_BACKDROP)
MHH_menagerieFond:SetPoint("TOPLEFT", pageMenagerie, "TOPLEFT", 44, -42)
MHH_menagerieFond:SetSize(552, 314) -- v0.125 : standard des autres onglets (552x314)
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
-- v0.112 : le titre nu rendait peu (retour utilisateur) —
-- plaque encadrée façon onglet, avec l'icône patte du tab.
MHH_menagerieTitrePlaque = CreateFrame("Frame", nil, MHH_menagerieFond)
MHH_menagerieTitrePlaque:SetSize(190, 30)
-- v0.118t : COLLE au bord haut du fond (retour : flottait trop haut)
-- v0.118u : icône patte retirée (retour utilisateur) ; plaque
-- décalée d un poil à gauche du fond.
MHH_menagerieTitrePlaque:SetPoint("TOP", MHH_menagerieFond, "TOP", -140, -5) -- v0.130 : ENTIÈREMENT dans l'encart gris (le bas chevauche légèrement le haut de la scène, assumé)
local mtpFond = MHH_menagerieTitrePlaque:CreateTexture(nil, "BACKGROUND")
mtpFond:SetAllPoints()
mtpFond:SetColorTexture(0.42, 0.35, 0.20, 0.95)
MHH_Cadrer(MHH_menagerieTitrePlaque, 0.85, 0.68, 0.25, 0.35, 1) -- v0.113 discret
MHH_menagerieTitre = MHH_menagerieTitrePlaque:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- RETOUR DE TEST : « GameFontNormalLarge » n'existe PAS en Vanilla 1.12 —
-- le titre ne se rendait plus. On garde GameFontNormal et on grossit la
-- police via SetFont (fichier TTF du client), avec repli silencieux.
pcall(function()
    MHH_menagerieTitre:SetFont("Fonts\\FRIZQT__.TTF", 16)
end)
MHH_menagerieTitre:SetPoint("CENTER", MHH_menagerieTitrePlaque, "CENTER", 11, 0)
MHH_menagerieTitre:SetText(L("|cffffd100MÉNAGERIE|r"))
MHH_menagerieTitre:SetShadowColor(0, 0, 0, 1)
MHH_menagerieTitre:SetShadowOffset(2, -2)
-- v0.119k : TITRE RETIRÉ (retour utilisateur : « ça fait ridicule
-- finalement »). La plaque reste CRÉÉE (MHH_plaqueViande s'ancre
-- dessus) mais CACHÉE : un Hide() masque fond, liseré et texte d'un
-- coup, et l'ancre de la plaque viandes continue de fonctionner.
MHH_menagerieTitrePlaque:Hide()
-- (Pas de sous-titre ici : le mode d'emploi de la capture est dans le
-- tuto — ici, on laisse toute la place à l'enclos)

-- L'enclos proprement dit : décor peint (TGA) au-dessus d'un repli procedural
-- v0.118s : MINI-INTERFACE BOUFFE (retour : dans le HUD a
-- chevauchait, collee sur l'encart transparent c'etait peu clair).
-- Cartouche autonome sur la ligne du titre : fond sombre, lisere
-- dore, icone gigot + compteur xN.
MHH_plaqueViande = CreateFrame("Frame", nil, MHH_menagerieFond)
MHH_plaqueViande:SetSize(112, 30)
MHH_plaqueViande:SetPoint("TOPLEFT", MHH_menagerieTitrePlaque, "TOPRIGHT", 12, 0)
local pvFond = MHH_plaqueViande:CreateTexture(nil, "BACKGROUND")
pvFond:SetAllPoints()
pvFond:SetColorTexture(0.08, 0.06, 0.04, 0.85)
MHH_Cadrer(MHH_plaqueViande, 0.85, 0.68, 0.25, 0.6, 1)
MHH_iconeViande = MHH_plaqueViande:CreateTexture(nil, "ARTWORK")
MHH_iconeViande:SetSize(18, 18)
MHH_iconeViande:SetPoint("LEFT", 8, 0)
MHH_iconeViande:SetTexture("Interface\\Icons\\INV_Misc_Food_17")
MHH_ctViande = MHH_plaqueViande:CreateFontString(nil, "OVERLAY")
MHH_ctViande:SetFont("Fonts\\FRIZQT__.TTF", 12)
MHH_ctViande:SetTextColor(0.98, 0.85, 0.45, 1)
MHH_ctViande:SetShadowColor(0, 0, 0, 1)
MHH_ctViande:SetShadowOffset(1, -1)
MHH_ctViande:SetPoint("LEFT", MHH_iconeViande, "RIGHT", 6, 0)

-- v0.126 : COMPTEUR DE PENSIONNAIRES en haut, au niveau de la plaque
-- viandes (retour : « Pensionnaires : N » quittait le bas du HUD) —
-- même cartouche : fond sombre, liseré doré, icône + N/limite.
MHH_plaquePension = CreateFrame("Frame", nil, MHH_menagerieFond)
MHH_plaquePension:SetSize(156, 30)
MHH_plaquePension:SetPoint("TOPLEFT", MHH_plaqueViande, "TOPRIGHT", 10, 0)
local ppFond = MHH_plaquePension:CreateTexture(nil, "BACKGROUND")
ppFond:SetAllPoints()
ppFond:SetColorTexture(0.08, 0.06, 0.04, 0.85)
MHH_Cadrer(MHH_plaquePension, 0.85, 0.68, 0.25, 0.6, 1)
local ppIcone = MHH_plaquePension:CreateTexture(nil, "ARTWORK")
ppIcone:SetSize(18, 18)
ppIcone:SetPoint("LEFT", 8, 0)
ppIcone:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming")
MHH_ctPension = MHH_plaquePension:CreateFontString(nil, "OVERLAY")
MHH_ctPension:SetFont("Fonts\\FRIZQT__.TTF", 11)
MHH_ctPension:SetTextColor(0.98, 0.85, 0.45, 1)
MHH_ctPension:SetShadowColor(0, 0, 0, 1)
MHH_ctPension:SetShadowOffset(1, -1)
MHH_ctPension:SetPoint("LEFT", ppIcone, "RIGHT", 6, 0)
MHH_ctPension:SetText("Pensionnaires : 0/26")
-- Limite totale d'enclos (somme des capacités des biomes)
MHH_LimiteEnclos = function()
    local t = 0
    if MHH_CAPACITE_ENCLOS then
        for _, c in pairs(MHH_CAPACITE_ENCLOS) do t = t + (c or 0) end
    end
    return (t > 0) and t or 26
end

MHH_enclosMenagerie = CreateFrame("Frame", nil, MHH_menagerieFond)
MHH_enclosMenagerie:SetPoint("TOPLEFT", MHH_menagerieFond, "TOPLEFT", 10, -33) -- v0.137 : 2px de léger recouvrement : le contact avec les cartouches est franc, sans jour
-- 532x266 : le ratio exact du fond enclos.tga (512x256 = 2:1) — à 532x176
-- (ancien) l'image était étirée de 50% en largeur. Scène plus haute, zéro distorsion.
MHH_enclosMenagerie:SetSize(532, 266)
-- FOND PEINT : la scène complète (ciel, collines, herbe texturée, clôture,
-- grange) est une SEULE image TGA par faction — cf Textures/enclos_*.tga.
MHH_enclosFondImg = MHH_enclosMenagerie:CreateTexture(nil, "BACKGROUND")
-- v0.129 : VOILE DE PÉNOMBRE tant que le régisseur n'est pas arrivé
-- (avant le 1er dialogue) — l'enclos « dort » dans le clair-obscur
-- (retour utilisateur : « plus classe »). Calque BORDER : au-dessus
-- du fond peint, sous l'ARTWORK. RaffraichirMenagerie le gère.
MHH_voileEnclos = MHH_enclosMenagerie:CreateTexture(nil, "BORDER")
MHH_voileEnclos:SetAllPoints(MHH_enclosMenagerie)
MHH_voileEnclos:SetColorTexture(0.01, 0.008, 0.005, 0.42)
MHH_voileEnclos:SetShown(false)
MHH_enclosFondImg:SetAllPoints(MHH_enclosMenagerie)
-- v0.110 : LISERÉ DORÉ, CORRIGÉ — le v0.104 l'avait posé sur
-- MHH_enclosMenagerie lui-même, or le backdrop d'une frame se dessine
-- SOUS ses enfants : l'image (enfant BACKGROUND) le recouvrait
-- intégralement, d'où le look « autocollant » toujours là (retour
-- utilisateur). Solution : une frame OVERLAY au-dessus de l'image,
-- qui ne porte QUE le bord — le centre reste transparent, les bêtes
-- passent dessous, rien n'est cliquable (EnableMouse false).
do
    -- v0.112 : le SetBackdrop ne s'affichait pas (retour utilisateur)
    -- -> 4 textures dorées via MHH_Cadrer. Global pour /mhho.
    MHH_cadreEnclos = CreateFrame("Frame", nil, MHH_enclosMenagerie)
    local cadreEnclos = MHH_cadreEnclos
    cadreEnclos:SetAllPoints(MHH_enclosMenagerie)
    cadreEnclos:SetFrameLevel(60)
    cadreEnclos:EnableMouse(false)
    -- v0.118s : CONTOUR ARTIFICIEL assume (retour : " toujours trop
    -- subtil, fait comme un contour artificiel ") - bord SOMBRE plein
    -- 3 px (cadre de panneau) + filet dore 1 px a l'interieur.
    MHH_Cadrer(cadreEnclos, 0.05, 0.04, 0.03, 0.95, 3)
    local cadreIn = CreateFrame("Frame", nil, MHH_enclosMenagerie)
    cadreIn:SetPoint("TOPLEFT", 3, -3)
    cadreIn:SetPoint("BOTTOMRIGHT", -3, 3)
    cadreIn:SetFrameLevel(60)
    cadreIn:EnableMouse(false)
    MHH_Cadrer(cadreIn, 0.85, 0.68, 0.25, 0.95, 1)
    -- v0.118n : plus APPUYÉ (retour : « délimite pas assez ») — alpha
    -- 0.7 -> 0.9, mais 2 px au lieu de 3 : net et lisible, pas baveux.
    -- v0.110 : HUD DU RANCH — plaque légère bas-droite de l'enclos
    -- (sur le chemin) : compteurs + bouton. Le dialogue n'étant plus
    -- rejoué qu'une fois (v0.102), le bouton rend Gazlowe accessible.
    MHH_hudRanch = CreateFrame("Frame", nil, MHH_enclosMenagerie,
        MHH_TEMPLATE_BACKDROP)
    -- v0.118 : HUD UTILE (retour utilisateur : « ça fait cheap
    -- sans icône ni bouton ») — compteurs + rang du ranch + bouton
    -- NOURRIR TOUT (l'équivalent de la fiche, pour tout le monde).
    -- v0.148 : 172 -> 150 : les boutons cote a cote, plus de marge (retour)
    MHH_hudRanch:SetSize(150, 58) -- v0.146 : moins haut (retour : « toujours trop grand en hauteur »)
    MHH_hudRanch:SetPoint("BOTTOMRIGHT", MHH_enclosMenagerie,
        "BOTTOMRIGHT", -8, 6)
    MHH_hudRanch:SetFrameLevel(61)
    MHH_hudRanch:EnableMouse(true)
    -- v0.118t : COMPAT — les anciens champs iconeViande/ctViande du HUD
    -- ont déménagé dans le cartouche du haut ; on les rebranche ici pour
    -- que toute ref externe (mhhunt.lua) ne crashe pas sur un nil.
    MHH_hudRanch.iconeViande = MHH_iconeViande
    MHH_hudRanch.ctViande = MHH_ctViande
    local hudFond = MHH_hudRanch:CreateTexture(nil, "BACKGROUND")
    hudFond:SetAllPoints()
    hudFond:SetColorTexture(0.06, 0.05, 0.04, 0.62) -- v0.118k : transparent
    MHH_Cadrer(MHH_hudRanch, 0.85, 0.68, 0.25, 0.35, 1) -- v0.113 discret
    MHH_hudRanch.l1 = MHH_hudRanch:CreateFontString(nil, "OVERLAY")
    MHH_hudRanch.l1:SetFont("Fonts\\FRIZQT__.TTF", 10)
    MHH_hudRanch.l1:SetTextColor(1, 0.82, 0.4, 1)
    MHH_hudRanch.l1:SetPoint("TOPLEFT", 10, -6)  -- v0.119c : à gauche, la place à droite est au bouton
    MHH_hudRanch.l2 = MHH_hudRanch:CreateFontString(nil, "OVERLAY")
    MHH_hudRanch.l2:SetFont("Fonts\\FRIZQT__.TTF", 10)
    MHH_hudRanch.l2:SetTextColor(0.8, 0.74, 0.55, 1)
    -- v0.155 : lignes CENTRÉES (retour : marge à droite dans l encart)
    MHH_hudRanch.l2:SetPoint("TOP", MHH_hudRanch, "TOP", 0, -6)
    MHH_hudRanch.l3 = MHH_hudRanch:CreateFontString(nil, "OVERLAY")
    MHH_hudRanch.l3:SetFont("Fonts\\FRIZQT__.TTF", 10)
    MHH_hudRanch.l3:SetTextColor(0.8, 0.74, 0.55, 1)
    MHH_hudRanch.l3:SetPoint("TOP", MHH_hudRanch, "TOP", 0, -19)
    local hudNourrir = CreateFrame("Button", nil, MHH_hudRanch)
    -- v0.119g : Nourrir tout a GAUCHE, Liste arrive a sa droite
    -- (retour : le bouton Liste devait finir SOUS Nourrir tout)
    hudNourrir:SetSize(84, 14) -- v0.146 : plus compact
    -- v0.155 : boutons CENTRÉS : 84+4+40 = 128 px dans 150 -> 11 px
    -- de marge de chaque côté (Liste suit Nourrir tout, ancre relative).
    hudNourrir:SetPoint("BOTTOMLEFT", 11, 4)
    hudNourrir:SetText("Nourrir tout")
    hudNourrir:SetNormalFontObject("GameFontHighlightSmall")
    local hnFond = hudNourrir:CreateTexture(nil, "BACKGROUND")
    hnFond:SetAllPoints()
    hnFond:SetColorTexture(0.42, 0.35, 0.20, 0.55)
    MHH_Cadrer(hudNourrir, 0.85, 0.68, 0.25, 0.35, 1)
    -- v0.119f : global — MHH_MajHudRanch (hors du do) gère l'état grisé
    MHH_hudNourrir = hudNourrir
    hudNourrir.actif = true
    hudNourrir:SetScript("OnClick", function()
        -- v0.118 : nourrit tous les NON-repus d'un coup — même effet
        -- que le bouton NOURRIR de la fiche (seuil repu : 24 h).
        if not (MHH_DB and MHH_DB.menagerie) then return end
        -- v0.119f : clic muet interdit — message si grisé
        if not hudNourrir.actif then
            if (MHH_DB.viande or 0) < 1 then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r "
                    .. "Plus de viande — chasse pour en récolter (40% par prise).")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r "
                    .. "Tout le monde est repu — rien à nourrir.")
            end
            return
        end
        local n = 0
        for _, m in pairs(MHH_DB.menagerie) do
            local d = time() - (m.nourri or m.capture or time())
            if d >= 86400 then
                -- v0.118o : chaque repas CONSOMME une viande — la
                -- ressource de la chasse/cuisine sert enfin à quelque
                -- chose. Plus de stock = nourrissage interrompu.
                if (MHH_DB.viande or 0) < 1 then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r "
                        .. "Plus de viande — nourrissage interrompu ("
                        .. n .. " nourri(s)).")
                    break
                end
                MHH_DB.viande = MHH_DB.viande - 1
                m.nourri = time()
                m.repas = (m.repas or 0) + 1   -- v0.144 : stat « repas donnés »
                m.affinite = math.min(100, (m.affinite or 0) + 4)
                n = n + 1
            end
        end
        if MHH_MajHudRanch then MHH_MajHudRanch() end
        DEFAULT_CHAT_FRAME:AddMessage("MHH: " .. n
            .. " nourri(s) — affinit\195\169 +4 chacun, viandes restantes : "
            .. (MHH_DB.viande or 0))
    end)
    -- v0.119f : SURVOL — le bouton r\195\169agit (retour : \171 on voit pas
    -- que c'est cliquable \187). Gris\195\169 : fond p\195\226le + police Disable.
    hudNourrir:SetScript("OnEnter", function(self)
        hnFond:SetColorTexture(0.55, 0.46, 0.26, self.actif and 0.85 or 0.45)
        self:SetNormalFontObject(self.actif
            and "GameFontYellowSmall" or "GameFontDisableSmall")
    end)
    hudNourrir:SetScript("OnLeave", function(self)
        hnFond:SetColorTexture(0.42, 0.35, 0.20, self.actif and 0.55 or 0.30)
        self:SetNormalFontObject(self.actif
            and "GameFontHighlightSmall" or "GameFontDisableSmall")
    end)
end
-- ============================================================
-- v0.117 : FICHE PENSIONNAIRE — le décor était purement contemplatif
-- et le nourrissage n'existait PLUS (les anciens boutons avaient été
-- retirés ; nourri n'était mis à jour qu'à la capture : les bêtes ne
-- pouvaient que s'affamer). CLIC sur une bête en scène = sa fiche :
-- nom, état de faim, affinité, bouton NOURRIR (repousse la faim,
-- +4 affinité, et déclenche l'heure de « gâteau » : le bob amplifié
-- déjà codé autour de m.gate).
-- ============================================================
-- v0.118k : FENÊTRE TYPIQUE DE WOW (retour utilisateur : « comme une
-- info d'objet ») — template backdrop tooltip, fond translucide
-- (alpha 0,72), liseré doré discret.
MHH_fichePensionnaire = CreateFrame("Frame", nil, MHH_enclosMenagerie,
    MHH_TEMPLATE_BACKDROP)
-- v0.149 : resserrée (retour : trop de hauteur/largeur) : 230x96 -> 200x84
MHH_fichePensionnaire:SetSize(200, 84)
MHH_fichePensionnaire:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie,
    "BOTTOMLEFT", 8, 6)
MHH_fichePensionnaire:SetFrameLevel(62)
MHH_fichePensionnaire:EnableMouse(true)
MHH_fichePensionnaire:Hide()
do
    local fp = MHH_fichePensionnaire
    pcall(function()
        fp:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        fp:SetBackdropColor(0.02, 0.02, 0.03, 0.72)
        fp:SetBackdropBorderColor(0.65, 0.50, 0.20, 0.60)
    end)
    fp.icone = fp:CreateTexture(nil, "ARTWORK")
    fp.icone:SetSize(18, 18)
    fp.icone:SetPoint("TOPLEFT", 10, -8)
    fp.icone:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming")
    fp.titre = fp:CreateFontString(nil, "OVERLAY")
    fp.titre:SetFont("Fonts\\FRIZQT__.TTF", 12)
    fp.titre:SetTextColor(1, 0.82, 0.4, 1)
    fp.titre:SetPoint("TOPLEFT", 34, -7)
    fp.etat = fp:CreateFontString(nil, "OVERLAY")
    fp.etat:SetFont("Fonts\\FRIZQT__.TTF", 10)
    fp.etat:SetTextColor(0.8, 0.74, 0.55, 1)
    fp.etat:SetPoint("TOPLEFT", 34, -26)
    fp.affinite = fp:CreateFontString(nil, "OVERLAY")
    fp.affinite:SetFont("Fonts\\FRIZQT__.TTF", 10)
    fp.affinite:SetTextColor(0.8, 0.74, 0.55, 1)
    fp.affinite:SetPoint("TOPLEFT", 34, -42) -- v0.144 : décalée à droite, alignée sur État
    local btnNourrir = CreateFrame("Button", nil, fp)
    btnNourrir:SetSize(60, 14) -- v0.146 : encore trop gros (retour) ; remonté
    -- v0.151 : centrés sous le texte (retour : « décale à droite, plus
    -- centré par rapport au texte au-dessus ») : 60+6+60 = 126 px de
    -- boutons dans une fiche de 200 -> 37 px de chaque côté.
    btnNourrir:SetPoint("BOTTOMLEFT", 37, 10)
    btnNourrir:SetText("Nourrir")
    btnNourrir:SetNormalFontObject("GameFontHighlightSmall")
    local bnf = btnNourrir:CreateTexture(nil, "BACKGROUND")
    bnf:SetAllPoints()
    bnf:SetColorTexture(0.42, 0.35, 0.20, 0.95)
    MHH_Cadrer(btnNourrir, 0.85, 0.68, 0.25, 0.7, 2)
    btnNourrir:SetScript("OnClick", function()
        local nom = MHH_fichePensionnaireNom
        if not (nom and MHH_DB and MHH_DB.menagerie
            and MHH_DB.menagerie[nom]) then return end
        if (MHH_DB.viande or 0) < 1 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r "
                .. "Pas de viande — chasse pour en r\195\169colter (40 % par prise).")
            return
        end
        local m = MHH_DB.menagerie[nom]
        MHH_DB.viande = MHH_DB.viande - 1   -- v0.118o : 1 viande par repas
        m.nourri = time()
        m.gate = time()                    -- 1 h de bob « gâté »
        m.repas = (m.repas or 0) + 1        -- v0.144 : stat « repas donnés »
        m.affinite = math.min(100, (m.affinite or 0) + 4)
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r "
            .. nom .. " d\195\169vore une viande (reste : " .. MHH_DB.viande .. ").")
        MHH_MajFichePensionnaire(nom)     -- rafraîchit l'état affiché
        if MHH_MajHudRanch then MHH_MajHudRanch() end
    end)
    -- v0.119h : RELÂCHER (retour utilisateur). Double-clic de
    -- confirmation : 1er clic arme (« Confirmer ? »), 2e clic dans
    -- les 3 s relâche. Le bouton repart désarmé à chaque fiche.
    local btnRelacher = CreateFrame("Button", nil, fp)
    btnRelacher:SetSize(60, 14) -- v0.146 : encore trop gros (retour) ; remonté
    -- v0.149 : GROUPLÉS (retour : trop d'écart) — Relâcher collé à Nourrir
    btnRelacher:SetPoint("BOTTOMLEFT", btnNourrir, "BOTTOMRIGHT", 6, 0)
    btnRelacher:SetText("Relâcher")
    btnRelacher:SetNormalFontObject("GameFontHighlightSmall")
    local brlFond = btnRelacher:CreateTexture(nil, "BACKGROUND")
    brlFond:SetAllPoints()
    brlFond:SetColorTexture(0.30, 0.18, 0.12, 0.75)
    MHH_Cadrer(btnRelacher, 0.85, 0.68, 0.25, 0.7, 2)
    MHH_btnRelacherFiche = btnRelacher
    btnRelacher:SetScript("OnClick", function()
        local nomR = MHH_fichePensionnaireNom
        if not (nomR and MHH_DB and MHH_DB.menagerie
            and MHH_DB.menagerie[nomR]) then return end
        if not (btnRelacher.armer and time() - btnRelacher.armer < 3) then
            btnRelacher.armer = time()
            btnRelacher:SetText("Confirmer ?")
            return
        end
        -- relâché : il rejoint la nature
        MHH_DB.menagerie[nomR] = nil
        local sp = MHH_spritesMenagerie and MHH_spritesMenagerie[nomR]
        if sp then
            if sp.f then sp.f:Hide() end
            MHH_spritesMenagerie[nomR] = nil
        end
        btnRelacher.armer = nil
        fp:Hide()
        if MHH_MajHudRanch then MHH_MajHudRanch() end
        if MHH_roster and MHH_roster:IsVisible() and MHH_MajRoster then
            MHH_MajRoster()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r " .. nomR
            .. " est rel\195\162ch\195\169 dans la nature. Bon vent, vieille b\195\170te.")
        -- v0.119h : le succès Cœur tendre existait depuis toujours —
        -- il attendait ce bouton pour être atteignable.
        if DebloquerSucces then DebloquerSucces("coeur_tendre") end
    end)
    local btnFermer = CreateFrame("Button", nil, fp)
    btnFermer:SetSize(18, 18)
    btnFermer:SetPoint("TOPRIGHT", -6, -6)
    -- v0.153 : le X natif du Button penche à gauche en 1.12 (retour :
    -- « pas tout à fait centré, décale à droite »). On vide le texte
    -- natif et on pose NOTRE FontString, centré +1 px.
    btnFermer:SetText("")
    local xf = btnFermer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    xf:SetPoint("CENTER", btnFermer, "CENTER", 1, 0)
    xf:SetText("X")
    local bff = btnFermer:CreateTexture(nil, "BACKGROUND")
    bff:SetAllPoints()
    bff:SetColorTexture(0.42, 0.35, 0.20, 0.95)
    MHH_Cadrer(btnFermer, 0.85, 0.68, 0.25, 0.7, 2)
    btnFermer:SetScript("OnClick", function() fp:Hide() end)
end

-- v0.118j BUGFIX : MHH_MajFichePensionnaire appelle EtatSpecimen,
-- defini LOCAL plus bas (ligne ~547) — pas de hoisting en Lua :
-- le nom valait nil a l'execution -> erreur au clic sur un mob.
-- Declaration anticipee, l'assignation reste en place plus bas.
local EtatSpecimen

MHH_MajFichePensionnaire = function(nom)
    local fp = MHH_fichePensionnaire
    if not (fp and nom and MHH_DB and MHH_DB.menagerie
        and MHH_DB.menagerie[nom]) then return end
    local m = MHH_DB.menagerie[nom]
    MHH_fichePensionnaireNom = nom
    fp.titre:SetText(MHH_TronquerTexte(nom, 22)) -- v0.144 : « ... » si trop long
    local _, libelle = EtatSpecimen(m)
    if m.gate and (time() - m.gate) < 3600 then
        libelle = libelle .. " |cffa0ff50(g\195\162t\195\169 !)|r"
    end
    fp.etat:SetText("État : " .. libelle)
    -- v0.144 : viandes retirées de la fiche (déjà affichées en haut,
    -- retour utilisateur) — la stat devient les REPAS DONNÉS.
    fp.affinite:SetText("Affinité : "
        .. string.format("%.0f", Affinite(m)) .. "%   |   Repas : "
        .. (m.repas or 0))
    -- v0.119h : Relâcher repart désarmé
    if MHH_btnRelacherFiche then
        MHH_btnRelacherFiche.armer = nil
        MHH_btnRelacherFiche:SetText("Relâcher")
    end
    fp:Show()
end

MHH_OuvrirFichePensionnaire = function(nom)
    MHH_MajFichePensionnaire(nom)
end

-- Décor selon la FACTION du chasseur : ranch horde (savane rouge/brune)
-- ou alliance (prairie verte/blue) — repli sur le décor neutre.
-- NB : sur client Vanilla, SetTexture ne renvoie RIEN (pas de booléen de
-- succès — c'est une API moderne). On ne peut PAS tester le chargement.
-- Stratégie robuste : l'image peinte est dessinée EN DESSUS des textures
-- procédurales (créée après elles dans la même couche = au-dessus). Si le
-- fichier TGA existe il la recouvre entièrement ; s'il manque, la texture
-- reste transparente et le repli procedural reste visible dessous.
-- NOUVEAU PRINCIPE : plus de repli procédural (ciel, bandes, sol, nuages
-- supprimés) — la scène peinte enclos.tga est le décor, point. Moins de
-- code, moins de textures, plus rien qui puisse planter sur du mort.
-- L'IMAGE PEINTE : dessinée après = AU-DESSUS du repli. Le TGA opaque
-- la recouvre entièrement quand il est présent.
-- Biome affiché = enclos sélectionné (savane/marais/montagne/volcan),
-- ESTOMPÉ par la teinte de faction (horde chaud / alliance froid) tant
-- qu'aucun fond de biome n'existe pour la clé. Ordre de préférence :
--   1. enclos_<biome>.tga (fond du biome sélectionné)
--   2. enclos_<faction>.tga (ranch de la faction)
--   3. enclos.tga (neutre)
local function MHH_ChargerFondEnclos()
    -- BUGFIX : plus de garde « if not MHH_DB » — ce loader est appelé au PARSE
    -- du fichier, AVANT l'événement ADDON_LOADED où MHH_DB est construit. Avec
    -- la garde, il retournait sans rien charger (le fond n'apparaissait
    -- qu'après /hunt test fond, qui le rappelle une fois MHH_DB vivant).
    if not MHH_enclosFondImg then return end
    -- (purge de l'ancien débrayage si la base existe déjà)
    if MHH_DB and MHH_DB.config and MHH_DB.config.fondEnclos then MHH_DB.config.fondEnclos = nil end
    MHH_enclosFondImg:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\menagerie\\enclos.tga")
end
MHH_ChargerFondEnclos()

-- ================= BÂTIMENTS DU RANCH =================
-- Le campement évolue avec le RANG DE GUILDE : tente → cabane → tour →
-- manoir. Un seul bâtiment visible à la fois — chaque rang REMPLACE le
-- précédent (pas d'accumulation qui déborde). Échelle étalonnée sur
-- l'arbre de la base : tente 90, cabane 110, tour 130, manoir 150 px.
-- Fichiers : Textures/menagerie/<fichier>.tga (256x256 transparents).
-- v0.65k : ORDRE SWAPPÉ — la tour rendait « cheap » après la maison ;
-- progression remise dans la logique du campement : tente → POSTE DE
-- GUET (on sécurise) → maison (on s'installe) → manoir (on prospère).
-- v0.65o : affichage RECTANGULAIRE — taille = hauteur de référence,
-- larg = ratio de largeur (tente et maison élargies, tour resserrée :
-- leurs silhouettes n'ont jamais été carrées, le cadre carré les tassait)
MHH_BATIMENTS_RANCH = {
    -- v0.116 : tente a 40 VALIDÉE en jeu (/hunt test bat 40,
    -- retour utilisateur) ; progression proportionnelle.
    -- v0.118p : chaque bâtiment a SA taille et SA position (retour
    -- utilisateur : « tour rabougrie et trop à gauche, manoir trop
    -- petit, maison plus grosse que la tente »). centre = centre x
    -- en px, y depuis le HAUT. La tente reste le calage validé.
    { rang = 1, fichier = "tente",  taille = 40,  larg = 1.35, centre = 96,  y = 52 },
    -- v0.147 : tour R\195\169DUITE (retour : trop \195\169largie) : 95\226\128\14680, larg 1.0\226\128\1460.8 ; base gard\195\169e au sol (y recal\195\169 12).
    { rang = 2, fichier = "tour",   taille = 80,  larg = 0.8,  centre = 96, y = 12 },
    { rang = 3, fichier = "house",  taille = 55,  larg = 1.25, centre = 104, y = 40 }, -- v0.119i : calé en jeu (/hunt test bat 55 70 40)
    -- v0.147 : manoir R\195\169DUIT (retour : trop gros, trop haut, sort du cadre) : 115\226\128\14685, larg 1.15\226\128\1461.0 ; base gard\195\169e au sol (y recal\195\169 7).
    -- v0.149 : manoir encore réduit (retour : encore trop gros) : 85→70, base au sol (y 22).
    { rang = 5, fichier = "manoir", taille = 70,  larg = 1.0,  centre = 96, y = 22 },
}
MHH_batimentsRanch = {}
-- OMBRE DU BÂTIMENT (v0.66d) : une seule texture, recadrée à chaque
-- changement de rang — même style que les ombres des pensionnaires.
-- Couche BACKGROUND : elle passe SOUS la couche ARTWORK du bâtiment.
-- v0.112 : reste une TEXTURE plate (BACKGROUND) — une frame ombre
-- passerait au-dessus du TGA du bâtiment (texture ARTWORK de l'enclos),
-- or elle doit rester SOUS sa base. Le procédural en bandes ne
-- s'applique pas ici : on garde la plate, alpha doux.
-- v0.153 : OMBRE PROCÉDURALE GARANTIE (retour : « je vois pas les ombres
-- des bâtiments » après v0.149/v0.151) — l'ellipse TGA ne rend pas sur ce
-- client. 5 BANDES EMPILÉES suivant un profil d'ellipse (alpha doux au
-- bord, dense au centre). Zéro fichier requis, toujours visible. Les
-- bandes sont recalées à chaque changement de bâtiment.
MHH_ombreBatiment = CreateFrame("Frame", nil, MHH_enclosMenagerie)
MHH_ombreBatiment:EnableMouse(false)
MHH_ombreBatiment.bandes = {}
-- v0.155 : couche ARTWORK (retour : « toujours pas d ombre ») —
-- sur ce client, dans cet enclos, BACKGROUND ne rend pas ; les TGA
-- des batiments (ARTWORK) sont visibles, eux.
for bI = 1, 5 do
    local bt = MHH_ombreBatiment:CreateTexture(nil, "ARTWORK")
    bt:SetColorTexture(0, 0, 0, ({ 0.14, 0.22, 0.30, 0.22, 0.14 })[bI])
    MHH_ombreBatiment.bandes[bI] = bt
end
MHH_ombreBatiment:Hide()
-- v0.156 : CONTOUR LÉGER du bâtiment actif (retour : « et les
-- bâtiments aussi pour faire leur contour (léger) ») — 4 traits
-- de 1 px, noir doux alpha 0,4, calés sur le rect du TGA. Les
-- traits sont posés par ANCRES : la frame suit le bâtiment via
-- SetAllPoints, aucune taille à recalculer.
MHH_contourBatiment = CreateFrame("Frame", nil, MHH_enclosMenagerie)
MHH_contourBatiment:EnableMouse(false)
MHH_contourBatiment:SetFrameLevel(2)
do
    local function ctrait(quatre)
        local t = MHH_contourBatiment:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0.05, 0.03, 0.02, 0.40)
        if quatre == "haut" then
            t:SetHeight(1)
            t:SetPoint("TOPLEFT", MHH_contourBatiment, "TOPLEFT", 0, 0)
            t:SetPoint("TOPRIGHT", MHH_contourBatiment, "TOPRIGHT", 0, 0)
        elseif quatre == "bas" then
            t:SetHeight(1)
            t:SetPoint("BOTTOMLEFT", MHH_contourBatiment, "BOTTOMLEFT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", MHH_contourBatiment, "BOTTOMRIGHT", 0, 0)
        elseif quatre == "gauche" then
            t:SetWidth(1)
            t:SetPoint("TOPLEFT", MHH_contourBatiment, "TOPLEFT", 0, 0)
            t:SetPoint("BOTTOMLEFT", MHH_contourBatiment, "BOTTOMLEFT", 0, 0)
        else
            t:SetWidth(1)
            t:SetPoint("TOPRIGHT", MHH_contourBatiment, "TOPRIGHT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", MHH_contourBatiment, "BOTTOMRIGHT", 0, 0)
        end
    end
    ctrait("haut"); ctrait("bas"); ctrait("gauche"); ctrait("droite")
end
MHH_contourBatiment:Hide()
for i, bat in ipairs(MHH_BATIMENTS_RANCH) do
    local t = MHH_enclosMenagerie:CreateTexture(nil, "ARTWORK")
    t.mhhFichier = bat.fichier
    -- (v0.65m : SetTexture renvoie false si le TGA manque — sans ce
    -- drapeau, une texture vide Show() affiche un carré gris)
    local ok = pcall(function()
        return t:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\menagerie\\"
            .. bat.fichier .. ".tga")
    end)
    t.mhhCharge = (ok == true)
    -- v0.118h : INTÉGRATION AU DÉCOR (retour utilisateur : la tente
    -- fait « dessinée/collée » alors que c'est un rendu 3D) : deux
    -- corrections optiques —
    -- 1) TEINTE : le TGA du bâtiment est plus éclatant que la scène
    --    peinte (éclairage différent). On le rabote vers l'ambiance
    --    du fond : léger voile froid-assombri.
    pcall(function() t:SetVertexColor(0.88, 0.88, 0.94) end)
    -- 2) FONDU DE BASE : le bord BAS du TGA tranche avec le sol.
    --    Dégradé vertical : opaque en haut, ~70 % à la base — la ligne
    --    de coupe se dissout dans l'ombre ronde posée dessous.
    --    (pcall : sur un client sans le mixin, c'est silencieux)
    pcall(function()
        t:SetGradientAlpha("VERTICAL",
            1, 1, 1, 1.0,    -- haut : opaque
            1, 1, 1, 0.70)   -- bas : semi-transparent
    end)
    t:SetSize(bat.taille * (bat.larg or 1), bat.taille)
    -- Position à retoucher à l'œil en jeu (végétation bas-gauche) : mêmes
    -- coordonnées pour tous, chaque rang remplace le précédent sur place.
    -- v0.103 : bâtiment en HAUT-GAUCHE = au fond de la scène
    -- (perspective ranch : les enclos devant, le QG derrière).
    t:SetPoint("TOPLEFT", MHH_enclosMenagerie, "TOPLEFT", 14, -10)
    t:Hide()
    MHH_batimentsRanch[i] = t
end
function MHH_MajBatimentsRanch()
    if not MHH_DB then return end
    local rang = MHH_DB.rangActuel or 1
    local visible = nil
    for i, bat in ipairs(MHH_BATIMENTS_RANCH) do
        if bat.rang <= rang then visible = i end
    end
    -- v0.118o : prévisualisation — /hunt test batimg <fichier> force
    -- un bâtiment précis (tester tour/maison/manoir sans monter de rang)
    local cfgBat = MHH_DB.config and MHH_DB.config.batImg
    if cfgBat then
        for i, bat in ipairs(MHH_BATIMENTS_RANCH) do
            if bat.fichier == cfgBat then visible = i end
        end
    end
    for i, t in ipairs(MHH_batimentsRanch) do
        -- (v0.65m : ne JAMAIS Show() une texture dont le TGA manque —
        -- un SetTexture raté laisse une texture vide, que le client
        -- rend en carré gris/bruit)
        if i == visible and t.mhhCharge then
            local bat = MHH_BATIMENTS_RANCH[i]
            -- v0.117 : centre recalé à 120 (150 la envoyait trop à
            -- droite, retour utilisateur) et y=85 : le bâtiment POSE
            -- SUR LE SOL du plot (bas de la zone, ~moitié de hauteur)
            -- — depuis la v0.103 il était ancré à 10 px du HAUT :
            -- il flottait dans le ciel au-dessus de la scène.
            -- Réglage à l'œil en jeu : /hunt test bat <taille> [x] [y]
            -- (v0.114 : la clé de débrayage passe à config.bat2,
            -- l'ancienne config.bat de l'échelle 90-150 est ignorée)
            -- v0.118e : micro-ajustement retour utilisateur
            -- (« un peu droite/bas, très léger »).
            local taille = bat.taille
            -- v0.118p : centre et hauteur propres à CHAQUE bâtiment
            local x = (bat.centre or 96) - taille * (bat.larg or 1) / 2
            local y = bat.y or 52
            if MHH_DB.config and MHH_DB.config.bat2 then
                taille = MHH_DB.config.bat2.taille or taille
                x = MHH_DB.config.bat2.x or x
                y = MHH_DB.config.bat2.y or y
            end
            t:SetSize(taille * (bat.larg or 1), taille)
            t:ClearAllPoints()
            -- v0.103 : y se compte DEPUIS LE HAUT (bâtiment au fond)
            t:SetPoint("TOPLEFT", MHH_enclosMenagerie, "TOPLEFT", x, -y)
            t:Show()
            -- ombre (v0.66d) recadrée sous la base du bâtiment — v0.118g :
            -- RONDE (ellipse douce), un peu plus large que lui, pour
            -- l'asseoir au sol au lieu de le laisser « collé »
            -- v0.153 : ellipse procédurale en 5 bandes, 85 % de la
            -- largeur du bâtiment, 12 px de haut, centrée sous la base.
            local largOmbre = taille * (bat.larg or 1) * 0.85
            local hautOmbre = 12
            MHH_ombreBatiment:SetSize(largOmbre, hautOmbre)
            MHH_ombreBatiment:ClearAllPoints()
            MHH_ombreBatiment:SetPoint("BOTTOMLEFT", t,
                "BOTTOMLEFT", (taille * (bat.larg or 1) - largOmbre) / 2, -3)
            local profO = { 0.45, 0.70, 1.0, 0.70, 0.45 }
            for bI, bt in ipairs(MHH_ombreBatiment.bandes) do
                bt:ClearAllPoints()
                bt:SetSize(largOmbre * profO[bI], hautOmbre / 5)
                bt:SetPoint("TOPLEFT", MHH_ombreBatiment, "TOPLEFT",
                    largOmbre * (1 - profO[bI]) / 2, -(bI - 1) * hautOmbre / 5)
            end
            MHH_ombreBatiment:Show()
            -- v0.156 : le contour épouse le rect du bâtiment affiché
            MHH_contourBatiment:ClearAllPoints()
            MHH_contourBatiment:SetAllPoints(t)
            MHH_contourBatiment:Show()
        else
            t:Hide()
            MHH_ombreBatiment:Hide()
            MHH_contourBatiment:Hide()
        end
    end
end

-- Message « enclos vide » : recréé ici (perdu lors du passage au fond peint)
-- Plaque « enclos vide » : cartouche sombre à liseré doré pour rester
-- lisible sur le fond pixel art chargé (retour de test : le texte seul
-- était pâle et noyé dans le décor)
-- FIX : sans le template MHH_TEMPLATE_BACKDROP, SetBackdrop ne rend RIEN
-- sur ce client (BackdropTemplateMixin requis) — d'où l'encart invisible.
MHH_enclosVideFond = CreateFrame("Frame", nil, MHH_enclosMenagerie, MHH_TEMPLATE_BACKDROP)
MHH_enclosVideFond:SetSize(360, 48)
MHH_enclosVideFond:SetPoint("CENTER", MHH_enclosMenagerie, "CENTER", 0, 6)
MHH_enclosVideFond:Hide()
pcall(function()
    MHH_enclosVideFond:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    -- v0.124 : fond PLUS PRONONCÉ (retour utilisateur : le cartouche
    -- parchemin clair semi-transparent se noyait dans le fond peint) —
    -- cartouche sombre quasi opaque, liseré doré à pleine opacité
    MHH_enclosVideFond:SetBackdropColor(0.05, 0.045, 0.035, 0.92)
    MHH_enclosVideFond:SetBackdropBorderColor(0.85, 0.66, 0.25, 1.0)
end)
MHH_enclosVide = MHH_enclosVideFond:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MHH_enclosVide:SetPoint("CENTER", 0, 0)
-- LE RANCH A QUATRE ENCLOS : « les enclos » au pluriel (retour
-- utilisateur — une seule phrase, les variantes étaient trop longues)
MHH_enclosVide:SetText(L("|cffffd100Les enclos sont vides — le régisseur dort.|r"))
MHH_enclosVide:SetShadowColor(0, 0, 0, 0.9)
MHH_enclosVide:SetShadowOffset(1, -1)

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
    MHH_particulesMenagerie[i] = { t = p, x = math.random() * 532, y = math.random() * 266,
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
    -- FOND PEINT : l'image unique reçoit la teinte météo + cycle jour/nuit
    -- (SetVertexColor multiplie : nuit = assombri, pluie = refroidi, le
    -- pixel art reste lisible).
    -- v0.65h : MÉTÉO + CYCLE JOUR/NUIT COUPÉS DE LA V1 — le voile sombre
    -- (jusqu'à -55 % la nuit, teinte météo le jour) délavait le pixel
    -- art Stardew du fond-test4. Le fond s'affiche désormais à pleine
    -- luminosité en toutes circonstances.
    if MHH_enclosFondImg then
        MHH_enclosFondImg:SetVertexColor(1, 1, 1)
    end
end
local function ConfigurerParticulesEnclos(cle)
    -- v0.65h : particules météo coupées de la v1 (pluie/neige sur du
    -- pixel art peint : peu crédible, coût non justifié). Tout est
    -- caché, quoi qu'il arrive ; le ticker les ignore (v = 0).
    for _, p in ipairs(MHH_particulesMenagerie) do
        p.v = 0
        p.t:Hide()
    end
end

-- État de faim : calculé depuis le dernier nourrissage (pas de ticker
-- en arrière-plan, tout est dérivé de l'horodatage)
EtatSpecimen = function(m)
    local d = time() - (m.nourri or m.capture or time())
    if d < 86400 then return "repu", "|cffa0ff50Repu|r"
    elseif d < 259200 then return "faim", "|cffffd100Petite faim|r"
    else return "affame", L("|cffd87a6aAffamé|r") end
end

-- v0.110 : actualise le HUD DU RANCH (compteurs bas-droite de
-- l'enclos) — appelé au rafraîchissement des pensionnaires.
MHH_MajHudRanch = function()
    if not (MHH_hudRanch and MHH_DB and MHH_DB.menagerie) then return end
    -- v0.119f : on S\195\169PARE petite faim et vraie famine (retour :
    -- \171 Affam\195\169s : 8 mais petite faim je crois \187 — oui, l'ancienne
    -- ligne comptait les deux pareil)
    local n, faimN, affN = 0, 0, 0
    for _, m in pairs(MHH_DB.menagerie) do
        n = n + 1
        local etat = EtatSpecimen(m)
        if etat == "faim" then faimN = faimN + 1
        elseif etat == "affame" then affN = affN + 1 end
    end
    -- v0.118 : ligne RANCH (bâtiment + rang)
    local rang = (MHH_DB and MHH_DB.rangActuel) or 1
    local nomsBat = { tente = "Tente", tour = "Poste de guet",
        house = "Maison", manoir = "Manoir" }
    local fichierBat = "tente"
    for _, bat in ipairs(MHH_BATIMENTS_RANCH or {}) do
        if bat.rang <= rang then fichierBat = bat.fichier end
    end
    if MHH_hudRanch.l3 then
        MHH_hudRanch.l3:SetText((nomsBat[fichierBat] or fichierBat)
            .. " — rang " .. rang)
    end
    -- v0.126 : le compteur vit en HAUT (MHH_plaquePension) — le bas
    -- du HUD respire ; la ligne l1 reste vide pour ne rien décaler.
    MHH_hudRanch.l1:SetText("")
    if MHH_ctPension then
        MHH_ctPension:SetText("Pensionnaires : " .. n .. "/"
            .. (MHH_LimiteEnclos and MHH_LimiteEnclos() or 26))
    end
    -- v0.118p : compteur de viandes MAJ à chaque rafraîchissement
    if MHH_ctViande then
        -- v0.119c : « Viandes : N » (retour : « x2.0 » illisible —
        -- le x collé au nombre se lisait comme une décimale)
        MHH_ctViande:SetText("Viandes : "
            .. string.format("%.0f", (MHH_DB.viande or 0)))
    end
    if affN > 0 then
        MHH_hudRanch.l2:SetText("|cffd87a6aAffam\195\169s : " .. affN .. "|r"
            .. (faimN > 0 and (" |cffffd100Faim : " .. faimN .. "|r") or ""))
    elseif faimN > 0 then
        MHH_hudRanch.l2:SetText("|cffffd100Petite faim : " .. faimN .. "|r")
    else
        MHH_hudRanch.l2:SetText("|cffa0ff50Tout le monde est repu|r")
    end
    -- v0.119f : NOURRIR TOUT gris\195\169 si plus de viande ou rien \195\160 nourrir
    if MHH_hudNourrir then
        MHH_hudNourrir.actif = (faimN + affN) > 0 and (MHH_DB.viande or 0) >= 1
        MHH_hudNourrir:SetNormalFontObject(MHH_hudNourrir.actif
            and "GameFontHighlightSmall" or "GameFontDisableSmall")
    end
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
    if m.affinite >= 100 and MHH_DB and MHH_DB.succes and not MHH_DB.succes["amidevoue"] then
        DebloquerSucces("amidevoue")
    end
end
-- Le pensionnaire dévoué d'une zone donne-t-il un bonus de chasse ici ?
-- (déclarée en tête de fichier : FinChasseVictoire l'appelle avant)
ZoneAvecAmiDevoue = function(zone)
    if not (MHH_DB and MHH_DB.menagerie) then return false end
    for nom, m in pairs(MHH_DB.menagerie) do
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
-- SPRITES TGA : si un fichier existe dans
-- Interface\AddOns\MHHunt\Textures\menagerie\<slug>.tga, il REMPLACE la
-- (v0.64 : dossier dédié MENAGERIE — Specimens/ est réservé aux vignettes)
-- grille (SetTexture renvoie nil si le fichier est absent → repli grille).
-- Génération : magick sprite.png -resize 80x80 -depth 32 <slug>.tga
MHH_TAILLE_PIX = 5
-- v0.65 : GÉOMÉTRIE DES ENCLOS PEINTS (fractions du cadre 532x266). Le
-- fond n'est PAS 4 bandes verticales : savane/marais/neige sont des
-- carrés dans les 2/3 hauts, la lave occupe le tiers bas droit, et le
-- bas gauche est l'espace bâtiment (aucune bête n'y vit). x1..x2 =
-- bornes horizontales de marche, y = hauteur des pattes depuis le bas.
-- v0.65b : carrés RESSERRÉS et errance verticale — y..y2 = bande de
-- hauteur des pattes dans laquelle la bête monte et descend (elle ne
-- reste plus sur une ligne fixe). Sprites 48 px (64 restait massif).
-- v0.65c : calé sur fond-test4 (Stardew, 4 carrés hauts + chantier
-- bas-gauche). Savane 0-25 %, marais 25-50 %, neige 50-75 % (haut),
-- lave 75-100 % (bas-droit). y..y2 = bande verticale d'errance des
-- pattes, en fractions de la hauteur.
-- v0.65d : bandes verticales REMONTÉES (il restait de la marge au-dessus
-- du lion) et errance verticale plus visible (80 % de l'allure).
-- Sprites 40 px (48 encore un peu massif face aux carrés du fond-test4).
-- v0.65e : BUGFIX fractions y — elles se comptent DEPUIS LE BAS du
-- cadre, or les carrés savane/marais/neige du fond-test4 occupent la
-- moitié HAUTE (y 0,5→1,0 depuis le bas) et la lave la moitié basse
-- droite (y 0→0,5). Les anciennes bornes plaçaient les bêtes SOUS les
-- carrés. Bandes corrigées + sprites 32 px (40 encore trop massif).
MHH_TAILLE_SPRITE_TGA = 24
-- v0.68 : ÉCHELLE GÉNÉRALE des pensionnaires/régisseur. 1 = comportement
-- v0.66. 2 = sprites 48 px, régisseur 44x64, ombres et bob doublés.
-- Tout le reste (enclos, bâtiments) reste en taille de scène.
MHH_ECHELLE = 1.5 -- v0.68b : 2 surdimensionnait le cheval face aux arbres/clôtures (retour utilisateur)
-- v0.104 : recalé sur le fond 3D WoW (fond-3DWoW-test7) — 4 colonnes
-- pleine hauteur, clôtures 25/75, chemin de terre en moitié basse.
-- Les bêtes marchent juste AU-DESSUS du chemin, sur le terrain.
-- Ajustable en jeu par zone : /mhhe <zone> <dx> <dy> (persistant).
MHH_ENCLOS_GEOM = {
    -- v0.118i : savane et marais remontent PLUS HAUT (y2 0.46 -> 0.53) :
    -- retour utilisateur « la savane et le murloc remontent pas assez ».
    -- Montagne et volcan restent à 0.46 (validés en jeu).
    savane   = { x1 = 0.01, x2 = 0.24, y = 0.32, y2 = 0.52 }, -- v0.119c : 0.60 chevauchait la barrière du haut
    -- v0.138 : les 3 enclos de DROITE remontent plus haut (retour :
    -- « les mobs remontent pas assez ») — plafond 0.58 au lieu de
    -- 0.52/0.55, en restant sous la barrière du haut.
    -- v0.141 : encore plus haut (retour : « ils vont pas encore
    -- assez haut ») : y2 0.58 -> 0.66. Si une bête passe sous la
    -- barrière du haut, redescendre à 0.62.
    marais   = { x1 = 0.26, x2 = 0.49, y = 0.32, y2 = 0.66 },
    montagne = { x1 = 0.51, x2 = 0.74, y = 0.32, y2 = 0.66 },
    volcan   = { x1 = 0.76, x2 = 0.99, y = 0.32, y2 = 0.66 },
}
MHH_SLUGS_SPRITES = {
    ["Humar le Seigneur hautain"] = "humar",
    ["Takk le Bondisseur"] = "takk",
    ["Mazzranache"] = "mazzranache",
    ["Sarkoth"] = "sarkoth",
    ["Flagglemurk le Cruel"] = "flagglemurk",
    ["Naraxis"] = "naraxis",
    ["Snarlflare"] = "snarlflare",
    ["Mor'Ladim"] = "morladim",
    -- v0.64 : les deux pensionnaires manquaient à la table des slugs —
    -- sans entrée, leur TGA n'était jamais chargé (sprite invisible)
    ["Grand crocolisque du loch"] = "crocolisque",
    ["Capitaine Croc-Plat"] = "croclplat",
}
-- v0.152 : MHH_SPRITES_TGA_DISPO SUPPRIMÉ — fini les sprites TGA « faits
-- main » de la ménagerie : les pensionnaires sont rendus par les MODÈLES
-- 3D du jeu (SetCreature, cf. MHH_DISPLAYS ci-dessous).
-- ============================================================
-- v0.70 : MODÈLES 3D NATURELS DU JEU (PlayerModel, comme la cabine
-- d'essayage) — la bête est rendue par le client : art officiel WoW,
-- idle animé natif, zéro sprite à générer/détourer.
-- MHH_DISPLAYS[slug] = displayID (nombre) ou table {id, echelle, face}.
-- displayIDs à recopier depuis ForeverDB / fiches wowhead du rare.
-- Tant qu'une entrée est absente -> repli TGA/grille comme avant.
-- MHH_MODELES_3D = false : coupe tout, retour au comportement v0.69.
-- ============================================================
MHH_MODELES_3D = true
MHH_MODELE_FACE = 0.6           -- orientation de base (radians, ~3/4)
-- v0.119c : ANIM PAR DÉFAUT PAR SQUELETTE — le n° de marche change
-- selon le squelette (le murloc pédèle à l\'envers en anim 4) : la
-- valeur gagnante trouvée en jeu via /mhha se pose ici, /mhha garde
-- la priorité (config DB > défaut ci-dessous > 4).
MHH_ANIM_SPEC_DEFAUT = {
    -- ["Flagglemurk le Cruel"] = 5,  -- régler via /mhha puis reporter
}
-- v0.72 : displayIDs recollés depuis CMaNGOS Classic-DB 1.12.1
-- (github.com/cmangos/classic-db — LA base du serveur Forever) :
-- creature_template, champ displayid1 de chaque NPC. Ce sont les
-- modèles exacts vus en jeu. echelle/face = réglages fins optionnels.
-- v0.73 BUGFIX « yeti aléatoire » : en 1.12, SetCreature(CreatureId)
-- attend une ENTRÉE NPC, pas un displayID (Widget API vanilla) — d'où
-- les modèles absurdes/noirs du test précédent. Chaque entrée porte
-- donc les DEUX : npc = entrée creature_template (SetCreature, l'API
-- 1.12 native — marche dès que le client a croisé/cache la créature,
-- ce qui est ton cas, tu les chasses) et disp = displayid (repli
-- SetDisplayID si SetCreature manque sur un client exotique).
MHH_DISPLAYS = {
    humar       = { npc = 5828, echelle = 1.1,  disp = 4424 },  -- Humar le Seigneur hautain
    takk        = { npc = 5842, echelle = 1.1,  disp = 1337 },  -- Takk le Bondisseur
    mazzranache = { npc = 3068, echelle = 1.2,  disp = 1961 },  -- Mazzranache
    sarkoth     = { npc = 3281, echelle = 0.8,  disp = 2864 },  -- Sarkoth
    flagglemurk = { npc = 7015, echelle = 0.9,  disp = 1305 },  -- Flagglemurk le Cruel
    naraxis     = { npc = 574, echelle = 1.0,   disp = 963  },  -- Naraxis
    snarlflare  = { npc = 14272, echelle = 1.3, disp = 497  },  -- Snarlflare
    morladim    = { npc = 3301,  disp = 3231 },  -- Mor'Ladim / Morgan Ladimore
    crocolisque = { npc = 2476, echelle = 1.1,  disp = 831  },  -- Grand crocolisque du loch
    croclplat   = { npc = 5824, echelle = 1.0,  disp = 1346 },  -- Capitaine Croc-Plat (5824 !)
}
-- v0.122 : modèles 3D des candidats étendus (Specimens.lua) — le NPC id
-- du data file suffit : SetCreature rend le modèle dès que la bête a
-- été croisée en jeu (la capture implique le gibier TUÉ, donc en cache)
if type(MHH_SPECIMENS_EXTRA) == "table" then
    for _, ex in ipairs(MHH_SPECIMENS_EXTRA) do
        if ex.npc and not MHH_SLUGS_SPRITES[ex.cle] then
            local slugExt = "ext" .. ex.npc
            MHH_SLUGS_SPRITES[ex.cle] = slugExt
            MHH_DISPLAYS[slugExt] = { npc = ex.npc }
        end
    end
end
local function CreerSpriteMenagerie(nom, defOpt)
    -- v0.121 : résolution par clé canonique (graphies serveur incluses)
    local cleSpecSprite = (not defOpt and MHH_SpecimenDe) and MHH_SpecimenDe(nom)
    local def = defOpt or (cleSpecSprite and MHH_SPECIMENS[cleSpecSprite]) or MHH_SPECIMENS[nom]
    -- v0.70 : MODÈLE 3D NATIF en priorité — si le displayID est connu,
    -- la frame devient un PlayerModel (art + idle du client, aucune
    -- image à fournir). pcall partout : SetCreature peut manquer sur un
    -- client exotique -> repli silencieux sur TGA/grille.
    if MHH_MODELES_3D then
        local slugM = (defOpt and defOpt.slug) or MHH_SLUGS_SPRITES[nom]
        local d = slugM and MHH_DISPLAYS[slugM]
        if d then
            -- v0.73 : d est une table {npc, disp} — SetCreature prend
            -- l'entrée NPC (API 1.12), SetDisplayID le displayid en repli
            local id   = (type(d) == "table") and (d.npc or d.id) or d
            local disp = (type(d) == "table") and d.disp
            local ech  = (type(d) == "table" and d.echelle) or 1
            local face = (type(d) == "table" and d.face) or MHH_MODELE_FACE
            local m = CreateFrame("PlayerModel", nil, MHH_enclosMenagerie)
            m:SetSize(MHH_TAILLE_SPRITE_TGA * MHH_ECHELLE,
                      MHH_TAILLE_SPRITE_TGA * MHH_ECHELLE)
            m.utiliseModele = true
            m.mhhFace = face
            -- v0.123 : TAILLE RÉELLE par pensionnaire (réalisme de
            -- l'enclos : un kodo domine une araignée). Sur ce client,
            -- SetModelScale recadre quasi tout (test terrain v0.80) :
            -- le levier PROUVÉ est SetScale sur la frame (v0.93) — il
            -- grossit ou rétrécit la frame ET son rendu 3D d'un coup.
            -- ech vient de Specimens.lua (ech / echelle), 1 = normal.
            m:SetScale(ech)
            -- v0.75 : SetCreature D'ABORD — la SEULE méthode prouvée en
            -- jeu sur ce client (elle rend les bêtes déjà croisées).
            -- SetDisplayID n'existe probablement pas en 1.12 (Widget API
            -- vanilla ne liste que SetCreature/SetRotation/SetUnit) et
            -- est gardée en simple repli si l'appel SetCreature plante.
            -- LIMITE 1.12 : SetCreature ne rend que ce que le cache
            -- client (Cache/WDB) connaît — pas d'API pour forcer un
            -- modèle arbitrary sans l'avoir croisé en jeu.
            local ok = pcall(function()
                m:SetCreature(id)
                m:SetCamera(0)
                m:SetModelScale(ech)
                m:SetPosition(0, 0, 0)
                m:SetSequence(1)       -- idle natif du jeu
                m:SetFacing(face)      -- oriente le modèle (le miroir
                                       -- de marche tournera SetFacing)
            end)
            -- repli : SetDisplayID (client exotique qui l'aurait)
            if not ok and disp then
                ok = pcall(function()
                    m:SetDisplayID(disp)
                    m:SetCamera(0)
                    m:SetModelScale(ech)
                    m:SetSequence(1)
                    m:SetFacing(face)
                end)
            end
            if ok then return m end
            m:Hide()
            m.utiliseModele = nil
        end
    end
    -- v0.152 : BRANCHE TGA + GRILLE PIXEL SUPPRIMÉE (retour : « on
    -- utilise les textures des mobs en jeu »). On n'arrive ici QUE si le
    -- modèle 3D n'a pas chargé (npc absent de MHH_DISPLAYS ou échec
    -- SetCreature) : silhouette neutre de dernier recours, en attendant
    -- que la bête croisée entre dans le cache client.
    local f = CreateFrame("Frame", nil, MHH_enclosMenagerie)
    f:SetSize(16 * MHH_TAILLE_PIX * MHH_ECHELLE, 16 * MHH_TAILLE_PIX * MHH_ECHELLE)
    local tSil = f:CreateTexture(nil, "OVERLAY")
    tSil:SetAllPoints(f)
    tSil:SetColorTexture(0.10, 0.09, 0.07, 1)
    local corps = f:CreateTexture(nil, "OVERLAY")
    corps:SetSize(f:GetWidth() * 0.62, f:GetHeight() * 0.45)
    corps:SetPoint("CENTER", f, "CENTER", 0, f:GetHeight() * 0.12)
    corps:SetColorTexture(0.28, 0.24, 0.18, 1)
    return f
end

-- ============================================================
-- RÉGISSEUR (v0.66) : le tortollan revient en TGA dédié —
-- Textures\menagerie\tortollan.tga + tortollan_2..6.tga.
-- Frame unique, 6 textures préchargées (zéro chargement à chaud),
-- une seule affichée à la fois. Cycle lent : une pose ~2,5 s.
-- Animation par OnUpdate propre à la frame : ne tourne QUE quand
-- le régisseur est visible — rien à câbler dans BoucleMenagerie.
-- ============================================================
MHH_regisseur = CreateFrame("Frame", nil, MHH_enclosMenagerie)
-- v0.66c : 22x32 — la pose paraissait ~1,5x trop large pour sa
-- hauteur (retour utilisateur) : largeur réduite pour compenser.
-- La texture s'étire dans la frame (SetAllPoints), c'est voulu.
MHH_regisseur:SetSize(22 * MHH_ECHELLE, 32 * MHH_ECHELLE)
-- Pieds posés sur le premier plan (sol devant les enclos, y < ~70)
MHH_regisseur:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 120, 8)
-- OMBRE du régisseur (v0.66d) : même style que les pensionnaires
-- (couche BACKGROUND, sous le sprite) — sans elle, il flotte.
-- v0.112 : ombre PROCÉDURALE (MHH_OmbrePlate) — le TGA ombre.tga
-- ne se chargeait pas de façon fiable sur le client.
local ombreReg = MHH_OmbrePlate(MHH_enclosMenagerie)
-- SOUS le régisseur (cf v0.112 : les frames enfants passent avant)
-- v0.118m : niveaux EXPLICITES — avant : niveau-1 = 0 quand le
-- régisseur est à 1, SetFrameLevel(0) échouait SILENCIEusement
-- (pcall) et l'ombre se perdait (retour : « le régisseur n'en
-- a plus »).
MHH_regisseur:SetFrameLevel(4)
ombreReg:SetFrameLevel(3)
ombreReg:SetSize(60, 14)
ombreReg:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 108, 2)
-- v0.124 : ombre exposée (le refresh pilote sa visibilité avec celle
-- du régisseur) et TOUT CACHÉ par défaut — le régisseur n'entre en
-- scène qu'à la PREMIÈRE prise (retour utilisateur : « n'affiche pas
-- le gobelin tant qu'on a pas la 1ere prise »)
MHH_regisseur.ombre = ombreReg
MHH_regisseur:Hide()
ombreReg:Hide()

-- BULLE D'ÉMOTION (v0.66e) : au-dessus du régisseur pendant un geste,
-- façon Animal Crossing — fond blanc, liseré doré, icône standard WoW.
-- Elle n'apparaît PAS pour l'idle ni la pause assise (repos silencieux).
-- Icônes par pose — à adapter à l'ordre de TES fichiers :
--   2 = salut, 3 = pouce, 4 = sacoche, 5 = salut bras levé, 6 = assis
-- v0.66g : bulles RPG simples (fond blanc, contour noir), générées
-- avec l'icône INTÉGRÉE — une texture par geste, pas d'overlay.
-- Fichiers OBLIGATOIRES dans Textures/menagerie/ (piège v0.65n) :
--   bulle_salut.tga (note de musique)   → poses 2, 5
--   bulle_pouce.tga (pouce levé)        → pose 3
--   bulle_sacoche.tga (sac de voyage)   → pose 4
--   bulle_zzz.tga (Zzz, repos assis)   → pose 6
MHH_bulleRegisseur = CreateFrame("Frame", nil, MHH_enclosMenagerie)
MHH_bulleRegisseur:SetSize(30 * MHH_ECHELLE, 26 * MHH_ECHELLE)
-- au-dessus de la tête (le régisseur est à x=120, 22x32) : 116, 44
MHH_bulleRegisseur:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT",
    120 - 4 * MHH_ECHELLE, 8 + 36 * MHH_ECHELLE)
MHH_bulleRegisseur:Hide()
local fondBulle = MHH_bulleRegisseur:CreateTexture(nil, "ARTWORK")
fondBulle:SetAllPoints(MHH_bulleRegisseur)
pcall(function() fondBulle:SetTexelSnappingBias(0) end)
MHH_bulleRegisseur.fond = fondBulle
-- table posée SUR la frame du régisseur, utilisée par MHH_PoseRegisseur :
-- pose → fichier de bulle (nil = pas de bulle, ex. idle)
MHH_regisseur.bulles = {
    [2] = "bulle_salut",
    [3] = "bulle_pouce",
    [4] = "bulle_sacoche",
    [5] = "bulle_salut",
    [6] = "bulle_zzz",
}
MHH_regisseur.textures = {}
MHH_regisseur.pose = 1
for i = 1, 6 do
    local slug = (i == 1) and "tortollan" or ("tortollan_" .. i)
    local t = MHH_regisseur:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints(MHH_regisseur)
    t:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\menagerie\\" .. slug .. ".tga")
    t:SetShown(i == 1)
    pcall(function() t:SetTexelSnappingBias(0) end) -- pixel art net
    MHH_regisseur.textures[i] = t
end

-- ============================================================
-- v0.71 : RÉGISSEUR « PORTRAIT WC3 » (optionnel) — encart doré
-- façon portrait de cinématique Warcraft III : un PlayerModel en
-- gros plan (idle natif du client, il gesticule tout seul) dans un
-- cadre, posé dans la zone du bâtiment, en bas à gauche.
-- ACTIVATION : renseigner une table ci-dessous, ex. tortue du jeu :
--     MHH_REGISSEUR_PORTRAIT = { id = 1570, echelle = 1.2 }
-- (id = displayID du modèle, echelle = réglage du cadrage,
--  x/y = position du cadre dans la scène, taille = côté en px.)
-- nil (défaut) : rien ne change, le tortollan TGA à 6 poses reste.
-- NB : pas de modèle Tortollan en Vanilla — le plus proche est une
-- tortue du jeu ; toute créature de ForeverDB fait l'affaire.
-- ============================================================
-- v0.73 : tortue « Tamed Turtle » du client vanilla — npc = ENTRÉE
-- créature 5448 (SetCreature, l'API 1.12), disp = 1244 en repli.
-- Petit, mignon, lit bien « jeune tortollan ». Ajuste echelle/face.
-- v0.76 : régie confiée à GAZLOWE en personne (NPC 3391, Ratchet) —
-- le baron marchand qui gère déjà la ville portuaire. Le furbolg et
-- le murloc ont été écartés (retour utilisateur : Gazlowe « ça ira »).
-- Portrait tête/épaules : echelle = cadrage du modèle, hauteur peut
-- décaler la caméra si la coupe n'est pas bonne.
-- v0.77 : le régisseur 3D vit DANS LA SCÈNE (comme les pensionnaires,
-- à l'ancienne place du tortollan TGA), et le carré en bas-gauche
-- devient un ENCART D'ACCUEIL : zoom sur la tête + ligne d'intro
-- (et plus tard : événements). zoom = cadrage portrait tête/épaules.
MHH_REGISSEUR_PORTRAIT = {
    npc = 3391, disp = 7052,
    echelle = 1.0,            -- taille du goblin en scène
    facePortrait = 0.15,      -- v0.83 : le portrait regarde la caméra
    distRepos = 0.95,         -- v0.101 : gros plan desserré (0.75 = gueule trop zoomée)
    distParle = 1.7,          -- v0.90 : sens INVERSÉ confirmé (plus grand = plus
                              -- serré ; 2.25 zoomait à fond, capture = blob vert)
    latPortrait = 0.12,       -- v0.89 : décalage latéral (positif = droite)
    ratioPortrait = 1.0,      -- v0.95 : taille frame modèle pendant la
                              -- parole (validé : ratio 1 = parfait)
    ratioRepos = 1.0,         -- v0.99 : ratio au zoom final (validé : 1)
    scaleRepos = 0.95,         -- v0.100 : échelle au zoom final (0.85 = trop rentré)
    vertPortrait = 0.20,      -- v0.91 : hauteur validée en jeu à 0.18 via /mhhv,
                              -- +0.02 pour éliminer le débord bas
    zoom = 2.6,               -- cadrage tête/épaules dans l'encart
    face = 0.5, hauteur = 0,
    intro = "Bah alors, cher client ? Gazlowe, r\195\169gisseur de CE ranch. Nourris... mais touche pas \195\160 la marchandise : chaque b\195\170te, c\39est du fric sur pattes. Clic sur une b\195\170te si tu comptes t\39en occuper s\195\169rieusement.",
}
if MHH_REGISSEUR_PORTRAIT then
    local pr = MHH_REGISSEUR_PORTRAIT
    -- v0.78 : DIALOGUE D'OUVERTURE façon WC3/WoW — remplace l'encart
    -- permanent v0.77. À l'ouverture de la page : le fond de la scène
    -- S'ASSOMBRI (focus), une barre de dialogue pleine largeur en bas,
    -- la gueule de Gazlowe zoomée à gauche, et le texte s'écrit lettre
    -- à lettre (il « parle »). Clic n'importe où : tout disparaît et
    -- la scène revient. Rejoué à chaque ouverture de la Ménagerie.
    local dlg = CreateFrame("Frame", nil, MHH_enclosMenagerie)
    dlg:SetAllPoints(MHH_enclosMenagerie)
    dlg:SetFrameLevel(30)            -- au-dessus des modèles 3D
    dlg:EnableMouse(true)            -- le clic ferme, partout
    dlg:Hide()
    local dim = dlg:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints(dlg)
    dim:SetColorTexture(0, 0, 0, 0.45)
    local barre = CreateFrame("Frame", nil, dlg, MHH_TEMPLATE_BACKDROP)
    barre:SetPoint("BOTTOMLEFT", dlg, "BOTTOMLEFT", 8, 8)
    barre:SetPoint("BOTTOMRIGHT", dlg, "BOTTOMRIGHT", -8, 8)
    barre:SetHeight(54 * MHH_ECHELLE)   -- v0.140 : réduite (76 datait de la v0.92, quand le texte débordait — réglé depuis), le portrait suit
    barre:EnableMouse(true)
    pcall(function()
        barre:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 32, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        barre:SetBackdropColor(0.04, 0.03, 0.02, 0.94)
        barre:SetBackdropBorderColor(0.85, 0.68, 0.25, 1)
    end)
    -- cadre doré du portrait : DANS la barre, à gauche (façon WC3)
    -- v0.92 : 54 -> 66 : le modèle débordait de tous les côtés
    -- (retour utilisateur). Si le moteur ne clippe pas le rendu 3D,
    -- SetMask (moteur moderne) le découpe aux bords du cadre.
    local taille = pr.taille or (48 * MHH_ECHELLE) -- v0.140 : portrait 66->48 (la barre est moins haute)
    local cadre = CreateFrame("Frame", nil, barre, MHH_TEMPLATE_BACKDROP)
    cadre:SetSize(taille, taille)
    cadre:SetPoint("LEFT", barre, "LEFT", 10, 0)
    pcall(function()
        cadre:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        cadre:SetBackdropColor(0.06, 0.04, 0.02, 0.9)
        cadre:SetBackdropBorderColor(0.85, 0.68, 0.25, 1)
    end)
    -- v0.77 : le régisseur vit EN SCÈNE, à la place du tortollan TGA
    -- (mêmes coordonnées, ombre conservée) — il se fond dans le décor
    -- comme les pensionnaires, et l'encart bas-gauche devient un zoom
    -- d'accueil sur sa tête + une ligne d'intro (réutilisable ensuite
    -- pour des événements).
    local mScene = CreateFrame("PlayerModel", nil, MHH_enclosMenagerie)
    mScene:SetSize(24 * MHH_ECHELLE, 36 * MHH_ECHELLE)
    -- v0.157 : (120, 8) -> (200, 14) : Gazlowe se rapproche des
    -- enclos et patrouille vers la droite (le chemin va tout à droite).
    mScene:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 200, 14)
    mScene.utiliseModele = true          -- la boucle le tournera (miroir)
    mScene.mhhFace = pr.face or 0.5
    -- v0.75 : SetCreature d'abord (cf. pensionnaires), SetDisplayID repli.
    local npcR = pr.npc or pr.id
    local okScene = pcall(function()
        mScene:SetCreature(npcR)
        mScene:SetCamera(0)
        mScene:SetModelScale(pr.echelle or 1)
        mScene:SetPosition(0, 0, 0)
        mScene:SetSequence(1)          -- idle : il vit, sans 6 fichiers TGA
        mScene:SetFacing(pr.face or 0.5)
    end)
    if not okScene and pr.disp then
        okScene = pcall(function()
            mScene:SetDisplayID(pr.disp)
            mScene:SetCamera(0)
            mScene:SetModelScale(pr.echelle or 1)
            mScene:SetSequence(1)
            mScene:SetFacing(pr.face or 0.5)
        end)
    end
    -- v0.118d : OMBRE DU RÉGISSEUR EN SCÈNE — le mScene n'avait pas
    -- d'ombre (seul l'ancien sprite en avait une) : il flottait
    -- (retour utilisateur : « plus d'ombre ? le régisseur à minima »).
    local omScene = MHH_OmbrePlate(MHH_enclosMenagerie)
    -- v0.118m : niveaux explicites (même bug que ombreReg)
    mScene:SetFrameLevel(4)
    omScene:SetFrameLevel(3)
    -- v0.128 : goblin + ombre CACHÉS à la création — ils n'entrent
    -- en scène qu'après le PREMIER DIALOGUE (retour utilisateur :
    -- « je veux pas voir l'interface avant le 1er dialogue »).
    -- RaffraichirMenagerie les montre quand regisseurIntro est posé.
    mScene:SetShown(false)
    omScene:SetShown(false)
    -- v0.118p : désembrouillable — le modèle AI voit l'ombre,
    -- l'utilisateur NON : on empile 3 couches (2x TGA rond + 1 bande
    -- plate dense) : l'une des trois finira par se voir. Si ça
    -- n'apparaît toujours pas, c'est de l'OCCLUSION, pas une
    -- question d'alpha — on changera complètement d'approche.
    omScene:SetSize(60, 14)
    omScene:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 108, 2)
    local om2 = omScene:CreateTexture(nil, "ARTWORK")
    om2:SetAllPoints(omScene)
    om2:SetTexture("Interface\\AddOns\\MHHunt\\Textures\\menagerie\\ombre_ronde.tga")
    -- v0.119j : le régisseur se tient sur le CHEMIN (sol sombre) : les
    -- bandes 0.14-0.35 passaient inaperçues là où les ombres des
    -- bêtes marquent sur l'herbe claire (retour : « toujours sans
    -- ombre »). On assombrit net + un cœur dense central, et on
    -- EXPOSE pour régler en jeu :
    --   /run MHH_ombreRegCore:SetAlpha(0.9)   (cœur, défaut 0.75)
    --   /run MHH_ombreRegHalo:SetAlpha(0.6)   (halo, défaut 0.55)
    local om3 = omScene:CreateTexture(nil, "BACKGROUND")
    om3:SetAllPoints(omScene)
    om3:SetColorTexture(0, 0, 0, 0.55)
    MHH_ombreRegHalo = om3
    local om4 = omScene:CreateTexture(nil, "BACKGROUND")
    om4:SetSize(34, 14)
    om4:SetPoint("CENTER", omScene, "CENTER", 0, 0)
    om4:SetColorTexture(0.01, 0.01, 0.01, 0.75)
    MHH_ombreRegCore = om4
    -- global : diagnostic live si besoin
    MHH_ombreRegisseurScene = omScene
    -- ENCART D'ACCUEIL : zoom tête/épaules dans le cadre doré + intro
    MHH_cadrePortrait = cadre        -- v0.94 : pour /mhhi (taille live)
    local m = CreateFrame("PlayerModel", nil, cadre)
    -- v0.94 : le rendu 3D occupe un espace LEGÈREMENT plus grand que la
    -- frame (moteur, confirmé : débord 5-10 px par-dessus le voile, et
    -- SetScale ne change rien). On fait donc la frame du modèle PLUS
    -- PETITE que le cadre doré : son espace de rendu gonflé retombe
    -- alors DANS le cadre. /mhhi <ratio> règle le ratio en jeu.
    dlg.ratioParle = pr.ratioPortrait or 1.0
    dlg.ratioRepos = pr.ratioRepos or 1.0
    dlg.scaleParle = pr.scalePortrait or 0.92
    dlg.scaleRepos = pr.scaleRepos or 0.85
    dlg.taillePortrait = taille
    local tailleM = taille * (pr.ratioPortrait or 1.0)
    m:ClearAllPoints()
    m:SetSize(tailleM, tailleM)
    m:SetPoint("CENTER", cadre, "CENTER", 0, 0)
    -- v0.92 : masque de découpe — si le moteur ne clippe pas le
    -- rendu 3D aux bords du cadre, ce masque le coupe proprement
    -- (no-op silencieux sur un client 1.12 pur).
    pcall(function() m:SetMask("Interface\\Buttons\\WHITE8X8") end)
    -- v0.93 : le moteur ne CLIPPE pas le rendu 3D aux bords du cadre
    -- (confirmé : modèle visible par-dessus le voile). SetScale rétrécit
    -- la frame ET son rendu 3D proportionnellement -> le débord rétrécit.
    -- Réglable en jeu : /mhhs <échelle>  (1 = taille normale).
    m:SetScale(pr.scalePortrait or 0.92)
    -- v0.80 : RETOUR À DES DÉFAUTS SÛRS — test terrain : sur ce
    -- client SetModelScale ne grossit quasi pas la créature (le
    -- PlayerModel recadre automatiquement) et le 2e argument de
    -- SetPosition est LATÉRAL (gauche/droite), pas vertical — d'où
    -- le goblin décalé/perdu. Sans caméra custom dispo, le cadrage
    -- tête (caméra custom) est IMPOSSIBLE en 1.12 : cadrage entier.
    -- v0.82 : DÉCOUVERTE — le client Forever est un moteur MODERNE
    -- (traces d'erreur Blizzard_ChatFrameBase/Shared, build 1.60).
    -- SetPortraitZoom EXISTE donc : cadrage NATIF tête/épaules façon
    -- portrait de quête — le look WC3 voulu. Repli silencieux si
    -- absent (client 1.12 pur) : goblin cadré entier.
    -- v0.83 : PLEINE FACE + IL PARLE — le cadrage tête était de
    -- profil (face 0.5 rad) ; le portrait regarde désormais la
    -- caméra (facePortrait ~0.15). Et sur ce moteur moderne,
    -- SetAnimation(60) = l'anim TALK du modèle : sa bouche bouge
    -- pendant que le texte s'écrit — le vrai effet « il parle ».
    local okZoom = pcall(function()
        m:SetCreature(npcR)
        m:SetCamera(0)
        m:SetModelScale(pr.zoom or 1)
        m:SetSequence(1)
        m:SetFacing(pr.facePortrait or 0.15)   -- pleine face caméra
        m:SetPortraitZoom(1)        -- LE cadrage tête natif
        -- v0.89 : décalage statique corrige le débord à gauche (2e arg
        -- de SetPosition = latéral, négatif = gauche, positif = droite)
        pcall(function()
            m:SetPosition(0, pr.latPortrait or 0.12,
                pr.vertPortrait or 0.20) end)
        if MHH_REGISSEUR_PARLE == nil or MHH_REGISSEUR_PARLE then
            m:SetAnimation(60)      -- anim Talk : bouche animée
        end
        -- v0.85 : SetCameraZoomLevel = no-op sur ce moteur (confirmé
        -- en jeu). On tente SetCamDistanceScale (API zoom fiche perso)
        -- pour donner de l'air au geste de parole. pcall : si absent,
        -- l'encart élargi (taille par défaut passée à 54) fait le job.
        pcall(function()
            m:SetCamDistanceScale(pr.distParle or 2.0)
        end)
    end)
    if not okZoom and pr.disp then
        pcall(function()
            m:SetDisplayID(pr.disp)
            m:SetCamera(0)
            m:SetModelScale(pr.zoom or 1)
            m:SetSequence(1)
            m:SetFacing(pr.facePortrait or 0.15)
            m:SetPortraitZoom(1)
            pcall(function()
                m:SetPosition(0, pr.latPortrait or 0.12,
                    pr.vertPortrait or 0.20) end)
            if MHH_REGISSEUR_PARLE == nil or MHH_REGISSEUR_PARLE then
                m:SetAnimation(60)
            end
            pcall(function()
                m:SetCamDistanceScale(pr.distParle or 2.0)
            end)
        end)
    end
    MHH_gueuleGazlowe = m
    -- texte machine à écrire (v0.78) : s'écrit lettre à lettre,
    -- comme si Gazlowe parlait. UTF-8 : on avance par octets, un
    -- accent coupé une frame reste invisible à cette vitesse.
    local txt = barre:CreateFontString(nil, "OVERLAY")
    txt:SetFont("Fonts\\FRIZQT__.TTF", 9 * MHH_ECHELLE + 0.5, "OUTLINE")
    txt:SetTextColor(1, 0.95, 0.8, 1)
    txt:SetJustifyH("LEFT")
    -- v0.98 : le bloc texte etait centre trop bas dans la barre
    -- (retour utilisateur). Justification MIDDLE + boite remontee :
    -- le texte se cale au milieu-haut de la barre, au-dessus du hint.
    txt:SetJustifyV("MIDDLE")
    txt:SetPoint("TOPLEFT", cadre, "TOPRIGHT", 12, -2)
    txt:SetPoint("BOTTOMRIGHT", barre, "BOTTOMRIGHT", -14, 16) -- v0.135 : +une ligne, la fin n'était plus coupée
    local hint = barre:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 7 * MHH_ECHELLE + 0.5, "OUTLINE")
    hint:SetTextColor(0.8, 0.74, 0.55, 0.9)
    hint:SetPoint("BOTTOMRIGHT", barre, "BOTTOMRIGHT", -10, 7)
    hint:SetText("- clique pour continuer -")
    dlg.texte = txt
    dlg.nu = 0
    dlg.acc = 0
    dlg.distRepos = pr.distRepos or 0.75
    dlg.distParle = pr.distParle or 2.0
    dlg.dist = dlg.distParle          -- il parle dès l'ouverture
    dlg.intro = pr.intro or ""   -- v0.113 : dynamique (dialogues par événement)
    -- v0.86 : ZOOM CINÉMATIQUE (retour utilisateur) — pendant la
    -- frappe il PARLE : dézoom fluide vers distParle pour que le
    -- grand geste de parole tienne dans l'encart. Quand le texte
    -- est terminé il SE TAIT (retour idle) et la caméra RE-ZOOME
    -- en douceur vers distRepos (sa gueule en gros plan). Lissage
    -- exponentiel à ~3/s : jamais de saut sec, ni à l'aller ni au
    -- retour. SetAnimation(0)/60 dans des pcall : robuste.
    barre:SetScript("OnUpdate", function(self, elapsed)
        local d = self:GetParent()
        local introFull = d.intro or "" -- v0.113 : lu à chaque tick
        if d.nu < string.len(introFull) then
            d.acc = d.acc + elapsed
            while d.acc >= 0.028 and d.nu < string.len(introFull) do
                d.acc = d.acc - 0.028
                d.nu = d.nu + 1
            end
            txt:SetText(string.sub(introFull, 1, d.nu))
        else
            -- fin du texte : il se tait (une seule fois)
            if not d.fini then
                d.fini = true
                if MHH_REGISSEUR_PARLE ~= false then
                    pcall(function() m:SetAnimation(0) end)
                end
                -- v0.93 : zoom final DOUX — on attend 0.35 s après la
                -- fin du texte, puis 4 crans espacés de 0.12 s (retour
                -- utilisateur : "un peu plus smooth, attendre un peu").
                -- 5 appels max : pas de martèlement, transition lisible.
                d.zoomAtt = 0.35
                d.zoomEtape = 0
                d.zoomFini = false
            end
            if d.fini and not d.zoomFini then
                d.zoomAtt = (d.zoomAtt or 0) - elapsed
                if d.zoomAtt <= 0 then
                    -- v0.97 : CRAN UNIQUE (retour utilisateur : "plutôt
                    -- brutal que le scintillement louche"). Chaque appel
                    -- a SetCamDistanceScale relance le rendu -> 4 crans =
                    -- 4 scintillements. On fait donc TOUT en un seul
                    -- appel : distance de repos + bascule du ratio 1 ->
                    -- 0.86 (resize 2D, lui ne scintille pas).
                    d.zoomFini = true
                    -- v0.99 : état zoom final validé en jeu :
                    -- ratio (mhhi) = 1 + échelle (mhhs) = 0.85
                    local tp = d.taillePortrait or 99
                    local r = d.ratioRepos or 1.0
                    m:ClearAllPoints()
                    m:SetSize(tp * r, tp * r)
                    m:SetPoint("CENTER", MHH_cadrePortrait, "CENTER", 0, 0)
                    pcall(function() m:SetScale(d.scaleRepos or 0.85) end)
                    pcall(function()
                        m:SetCamDistanceScale(d.distRepos or 0.75) end)
                end
            end
        end
        -- v0.88 : CAMERA FIXE. Meme throttle, SetCamDistanceScale
        -- relance le rendu a CHAQUE appel sur ce moteur (scintillement
        -- persistant, confirme en jeu v0.87). Le zoom dynamique est
        -- donc abandonne : distance fixe a distParle, appliquee UNE
        -- fois a l'ouverture, jamais pendant l'anim. Plus de flash,
        -- plus de cadrage qui glisse (les decalages bas/gauche/haut
        -- vus pendant la transition venaient du recadrage en cours).
    end)
    -- clic n'importe où : la scène revient
    local function FermerDialogue()
        dlg:Hide()
        -- v0.128 : le dialogue d'ouverture vient d'être vu (le OnUpdate
        -- a posé regisseurIntro) — le goblin et le HUD apparaissent.
        if MHH_regisseurScene then MHH_regisseurScene:Show() end
        if MHH_regisseurSceneOmbre then MHH_regisseurSceneOmbre:Show() end
        if MHH_hudRanch then MHH_hudRanch:Show() end
        -- v0.129 : la pénombre se lève avec l'arrivée du régisseur
        if MHH_voileEnclos then MHH_voileEnclos:Hide() end
    end
    dlg:SetScript("OnMouseUp", FermerDialogue)
    barre:SetScript("OnMouseUp", FermerDialogue)
    MHH_dialogueRegisseur = dlg
    if okScene then
        -- le tortollan TGA disparaît ; l'OMBRE est conservée (le goblin
        -- se tient au même endroit). La frame MHH_regisseur reste
        -- VISIBLE mais vide : les textures sont vidées, mais son
        -- OnUpdate continue de tourner (frames cachées = pas de ticks)
        -- pour déclencher les BULLES d'émotion au-dessus du goblin.
        for _, tx in ipairs(MHH_regisseur.textures) do tx:Hide() end
        MHH_regisseur.textures = {}
        MHH_regisseur:SetAlpha(0.01)
        MHH_regisseur.scene = mScene
        -- v0.128 : globales pour la visibilité post-dialogue
        MHH_regisseurScene = mScene
        -- v0.145 : L'OMBRE ENFIN RÉELLE (retour : « surtout il n'a pas
        -- d'ombre ») — les couches empilées du v0.118p n'ont JAMAIS
        -- rendu sur ce client (occlusion moteur). On prend la RECETTE
        -- PENSIONNAIRE, elle fonctionne en jeu : MHH_OmbrePlate,
        -- frame level juste SOUS le modèle (mScene = 4 -> ombre = 3).
        omScene:Hide()
        -- v0.150 : OMBRE DU GOBLIN — 3e tentative, 2 changements :
        -- 1) plus MHH_OmbrePlate : en 1.12 SetTexture ne renvoie RIEN,
        --    donc sa recette retombait TOUJOURS dans le repli « bandes
        --    noires » — jamais l'ellipse du TGA ;
        -- 2) niveau 5, AU-DESSUS du modèle (niveau 4) : le viewport 3D
        --    du modèle efface ce qui est rendu dessous (occlusion
        --    moteur 1.12, retour « toujours sans ombre »). Dessus, elle
        --    est rendue ; l'ellipse douce (alpha max 0,32) ne fait
        --    qu'effleurer ses pieds.
        -- v0.153 : ellipse PROCÉDURALE (retour : « toujours pas
        -- d'ombre ») — le TGA ne rend pas sur ce client ; 5 bandes
        -- empilées, toujours visibles, niveau 5 au-dessus du modèle.
        -- v0.155 : 4e tentative, 2 VRAIS bugs corrigés :
        -- 1) COUCHE : les bandes étaient en « BACKGROUND » — or sur ce
        --    client, dans cet enclos, seules les textures « ARTWORK »
        --    sont confirmées visibles (TGA des bâtiments, ombre plate
        --    des pensionnaires). Une bande BACKGROUND n'a jamais été
        --    vue en jeu : on passe tout en ARTWORK (goblin ET bâtiments).
        -- 2) CENTRAGE : le modèle fait 24*MHH_ECHELLE=36 px de large
        --    (pieds centrés à g.x+18) mais l'ombre était ancrée à
        --    g.x-12 (centre g.x+5) : elle tombait 13 px À CÔTÉ des
        --    pieds. Recentrée, et alphas triplés pour percer le chemin
        --    sombre. Réglable en jeu :
        --      /run MHH_regisseurSceneOmbre:SetAlpha(0.6)
        local omGaz = CreateFrame("Frame", nil, MHH_enclosMenagerie)
        omGaz:EnableMouse(false)
        -- v0.157 : 30x10 -> 20x7 (retour : « trop grosse ») et
        -- REMONTÉE sous les pieds : le modèle monte à y=14, l'ombre
        -- vit à y=11 (elle chevauche les pieds au lieu de traîner
        -- plus bas). Pieds centrés à 200+18 : ombre à 208.
        omGaz:SetSize(20, 7)
        -- v0.158 : y 11 -> 13 (pieds à 14 : l'ombre démarre 1 px sous)
        omGaz:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT", 208, 13)
        local profG = { 0.45, 0.70, 1.0, 0.70, 0.45 }
        for bI = 1, 5 do
            local bt = omGaz:CreateTexture(nil, "ARTWORK")
            bt:SetColorTexture(0, 0, 0, ({ 0.22, 0.34, 0.48, 0.34, 0.22 })[bI])
            bt:SetSize(20 * profG[bI], 1.4)
            bt:SetPoint("TOPLEFT", omGaz, "TOPLEFT",
                20 * (1 - profG[bI]) / 2, -(bI - 1) * 1.4)
        end
        omGaz:SetFrameLevel(5)
        MHH_regisseurSceneOmbre = omGaz
        -- v0.139 : LA RONDE DU RÉGISSEUR (retour utilisateur : « il peut
        -- peut-être s'animer un peu ? marcher/surveiller de droite à
        -- gauche »). v0.157 : bornes 60-250 -> 130-320 (retour : « le
        -- chemin va tout à droite ») et y=14 : il se rapproche des
        -- enclos. ~12 px/s à 10 Hz.
        MHH_gazloweRonde = {
            x = 200, min = 130, max = 320, y = 14,
            dir = 1, v = 1.2,
            face = 1, faceBase = pr.face or 0.5,
            pause = nil, marcheOn = nil,
            -- anim de MARCHE : 4 = marche avant (validée en jeu sur les
            -- pensionnaires, v0.107). Réglage dédié au goblin :
            -- /run MHH_DB.config.gazloweAnim = <n>  (défaut 4)
        }
    else
        -- modèle scène impossible : retour au TGA tortollan complet
        mScene:Hide()
    end
end

-- Animation (v0.66b) : OnUpdate throttlé à ~10 Hz. Le régisseur ne
-- DEFILE PAS ses poses : il reste IDLE (pose 1) la majorité du temps
-- (6-14 s), puis fait UNE pose de temps en temps (2,5 s) avant de
-- revenir à l'idle. Un PNJ vivant, pas un diaporama.
-- À 32 px, seules les poses à silhouette marquée se lisent :
-- les saluts, le pouce, l'assise. Si tes fichiers ne suivent pas
-- cet ordre, réordonne MHH_regisseur.gestes.
MHH_regisseur.idle = 1                    -- pose de repos
MHH_regisseur.gestes = { 2, 3, 4, 5, 6 }  -- poses occasionnelles
-- La pause ASSIS (6) est un vrai repos, pas un geste vif : elle dure
-- 8-14 s ; les autres gestes, 2,5 s (durée tirée à CHAQUE occurrence).
MHH_regisseur.geste = nil                 -- geste en cours (nil = idle)
MHH_regisseur.finIdle = GetTime() + 6 + math.random() * 8
MHH_regisseur.dernier = 0
local function MHH_PoseRegisseur(self, p)
    if self.pose == p then return end
    self.pose = p
    for i, tx in ipairs(self.textures) do
        tx:SetShown(i == p)
    end
    -- bulle d'émotion : texture PAR geste, cachée à l'idle
    if MHH_bulleRegisseur then
        local bulle = self.bulles and self.bulles[p]
        if bulle then
            MHH_bulleRegisseur.fond:SetTexture(
                "Interface\\AddOns\\MHHunt\\Textures\\menagerie\\" .. bulle .. ".tga")
            -- v0.124 : bulle seulement si le régisseur est en scène
            MHH_bulleRegisseur:SetShown(self:IsShown())
        else
            MHH_bulleRegisseur:Hide()
        end
    end
end
MHH_regisseur:SetScript("OnUpdate", function(self, elapsed)
    self.dernier = self.dernier + elapsed
    if self.dernier < 0.1 then return end -- ~10 Hz suffit largement
    self.dernier = 0
    local t = GetTime()
    -- v0.139 : LA RONDE — Gazlowe patrouille devant son bâtiment,
    -- pauses spontanées comme les pensionnaires, retournement natif
    -- par SetFacing (sens v0.111 : dir -1 = +pi). Suspendue pendant
    -- un dialogue (il est en gros plan, pas en scène).
    if MHH_regisseurScene and MHH_gazloweRonde
        and not (MHH_dialogueRegisseur and MHH_dialogueRegisseur:IsShown()) then
        local g = MHH_gazloweRonde
        if g.pause and g.pause > 0 then
            g.pause = g.pause - 1
            -- v0.143 : IL MARCHE, il ne glisse plus (retour : « Gazlow
            -- slide de gauche à droite ») — marche = SetAnimation(4)
            -- comme les pensionnaires (v0.107), pause = SetAnimation(0).
            if g.marcheOn then
                g.marcheOn = nil
                pcall(function()
                    MHH_regisseurScene:SetAnimation(0)
                    -- NB v0.109 : SetAnimation ÉCRASE l'orientation —
                    -- on repose le miroir APRÈS chaque changement.
                    MHH_regisseurScene:SetFacing(g.faceBase
                        + ((g.dir == -1) and math.pi or 0))
                end)
            end
        else
            g.pause = nil
            if math.random() < 0.012 then g.pause = 10 + math.random(50) end
            if not g.marcheOn then
                g.marcheOn = true
                local aM = (MHH_DB and MHH_DB.config
                    and MHH_DB.config.gazloweAnim) or 4
                pcall(function()
                    MHH_regisseurScene:SetAnimation(aM)
                    MHH_regisseurScene:SetFacing(g.faceBase
                        + ((g.dir == -1) and math.pi or 0))
                end)
            end
            g.x = g.x + g.dir * g.v
            if g.x < g.min then g.x = g.min g.dir = 1 end
            if g.x > g.max then g.x = g.max g.dir = -1 end
            MHH_regisseurScene:ClearAllPoints()
            MHH_regisseurScene:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie,
                "BOTTOMLEFT", g.x, g.y or 14)
            if g.dir ~= g.face then
                g.face = g.dir
                -- demi-tour : l'anim est reposée aussi (v0.111 :
                -- SetAnimation écrase l'orientation du modèle)
                local aM = (MHH_DB and MHH_DB.config
                    and MHH_DB.config.gazloweAnim) or 4
                pcall(function()
                    if g.marcheOn then MHH_regisseurScene:SetAnimation(aM) end
                end)
            end
            -- v0.145 : IL SE TOURNE (retour : « se tourne pas, reste de
            -- profil ») — l'anim de marche du squelette humanoïde
            -- réaffirme son orientation en continu : un SetFacing posé
            -- une seule fois aux demi-tours ne tient pas. On le repose
            -- à CHAQUE tick de marche (10 Hz, pcall : coût nul).
            pcall(function()
                MHH_regisseurScene:SetFacing(g.faceBase
                    + ((g.dir == -1) and math.pi or 0))
            end)
            if MHH_regisseurSceneOmbre then
                MHH_regisseurSceneOmbre:ClearAllPoints()
                -- v0.158 : ombre 20 px, ancre g.x+8 (centre g.x+18)
                -- et y = pieds - 1 (retour : « encore un poil trop
                -- basse ») : le haut de l'ellipse touche les semelles.
                MHH_regisseurSceneOmbre:SetPoint("BOTTOMLEFT",
                    MHH_enclosMenagerie, "BOTTOMLEFT", g.x + 8, (g.y or 14) - 1)
            end
        end
    end
    -- v0.78 : ce OnUpdate ne tourne QUE quand la Ménagerie est
    -- affichée — un écart > 1 s veut dire page (ré)ouverte.
    -- v0.102 : le dialogue d'accueil ne se joue qu'UNE FOIS, a la
    -- premiere ouverture de la Menagerie APRES la premiere capture.
    -- v0.113 : Gazlowe parle aux ETAPES IMPORTANTES — il commente
    -- aussi CHAQUE MONTÉE DE RANG (le bâtiment vient d'évoluer) :
    -- texte adapté au nouveau bâtiment, rejoué a la prochaine
    -- ouverture de la Menagerie. /mhhd rejoue le dernier a volonte.
    if MHH_dialogueRegisseur and t - (self.dernierTick or 0) > 1.0 then
        local nbCaptures = 0
        if MHH_DB and MHH_DB.menagerie then
            for _ in pairs(MHH_DB.menagerie) do nbCaptures = nbCaptures + 1 end
        end
        -- Quel dialogue jouer ?
        local texteDialogue = nil
        local rang = (MHH_DB and MHH_DB.rangActuel) or 1
        local rangVu = MHH_DB and MHH_DB.rangRegisseurVu or nil
        if rangVu and rang > rangVu then
            -- MONTÉE DE RANG : le campement a évolué depuis sa visite
            local fichierBat = "tente"
            for _, bat in ipairs(MHH_BATIMENTS_RANCH or {}) do
                if bat.rang <= rang then fichierBat = bat.fichier end
            end
            local phrases = {
                tente  = "une belle tente de chasse",
                tour   = "un poste de guet digne de ce nom",
                house  = "une vraie maison, avec une porte et tout",
                manoir = "un MANOIR, oui monsieur !",
            }
            MHH_DB.rangRegisseurVu = rang
            texteDialogue = "Et hop, le ranch monte d'un cran ! "
                .. (phrases[fichierBat] or "un nouveau b\195\162timent")
                .. " Tes b\195\170tes sont entre de bonnes pattes, patron — les miennes."
        elseif nbCaptures > 0 and not (MHH_DB and MHH_DB.regisseurIntro) then
            MHH_DB.regisseurIntro = true    -- jamais deux fois (sauf /mhhd)
            MHH_DB.rangRegisseurVu = rang
            texteDialogue = MHH_REGISSEUR_PORTRAIT
                and MHH_REGISSEUR_PORTRAIT.intro or nil
        end
        if not texteDialogue then
            self.dernierTick = t
            return   -- rien a jouer : deja vu ou pension vide
        end
        local d = MHH_dialogueRegisseur
        d.intro = texteDialogue -- v0.113 : le texte de CETTE étape
        d.nu = 0
        d.acc = 0
        d.fini = nil
        d.zoomFini = nil          -- v0.98 : le zoom final doit pouvoir
        d.zoomAtt = nil           -- se rejouer a la prochaine fin
        d.dist = d.distParle      -- il repart en mode « il parle »
        d.texte:SetText("")
        -- v0.98 : BUG - apres un 1er dialogue complete, la frame du
        -- modele RESTAIT au ratio du zoom final (0.86) et la camera
        -- a la distance de repos : au 2e dialogue, le portrait etait
        -- donc mal cadre des l'ouverture. On remet TOUT a l'etat
        -- « parole » (ratio 1, distance distParle).
        if MHH_gueuleGazlowe and MHH_cadrePortrait then
            local tp = d.taillePortrait or 99
            local r = d.ratioParle or 1.0
            MHH_gueuleGazlowe:ClearAllPoints()
            MHH_gueuleGazlowe:SetSize(tp * r, tp * r)
            MHH_gueuleGazlowe:SetPoint("CENTER",
                MHH_cadrePortrait, "CENTER", 0, 0)
            pcall(function()
                MHH_gueuleGazlowe:SetScale(d.scaleParle or 0.92) end)
            pcall(function()
                MHH_gueuleGazlowe:SetCamDistanceScale(d.distParle or 1.7)
            end)
        end
        if MHH_REGISSEUR_PARLE ~= false then
            pcall(function()
                MHH_gueuleGazlowe:SetAnimation(60)
            end)
        end
        d:Show()
    end
    self.dernierTick = t
    if self.geste then
        -- une pose dure 2,5 s, puis retour au repos
        if t > self.gesteJusqua then
            self.geste = nil
            self.finIdle = t + 6 + math.random() * 8
            MHH_PoseRegisseur(self, self.idle)
        end
    elseif t > self.finIdle then
        -- un geste de temps en temps — jamais le même deux fois
        -- de suite (re-tirage tant que c'est le précédent)
        local g = self.gestes[math.random(#self.gestes)]
        if #self.gestes > 1 then
            while g == self.dernierGeste do
                g = self.gestes[math.random(#self.gestes)]
            end
        end
        self.dernierGeste = g
        self.geste = g
        -- durées par pose : assis (6) = repos 8-14 s ; saluts (2, 5) =
        -- geste vif 1,2 s (retour utilisateur : trop long) ; autres 2,5 s
        local duree = 2.5
        if g == 6 then duree = 8 + math.random() * 6
        elseif g == 2 or g == 5 then duree = 1.2 end
        self.gesteJusqua = t + duree
        MHH_PoseRegisseur(self, g)
    end
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
    if not MHH_DB then return end
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
            if p.dir > 0 and p.y > 266 then p.y = -8 p.x = math.random() * 532 end
            if p.dir < 0 and p.y < -8 then p.y = 266 p.x = math.random() * 532 end
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
        local m = MHH_DB.menagerie and MHH_DB.menagerie[nom]
        if m then
            local etat = EtatSpecimen(m)
            local gate = m.gate and (time() - m.gate) < 3600
            -- v0.65l BUGFIX « carrés flottants » : une bête sans TGA est
            -- cachée, mais le ticker continuait de créer/déplacer SON
            -- OMBRE — des rectangles semi-transparents erraient seuls
            -- dans les enclos, sans propriétaire. On la saute entièrement.
            if s.f and not s.f.utiliseModele then
                if s.ombre then s.ombre:Hide() end
            else
            if peur then
                s.vNormale = s.vNormale or s.v   -- mémorise l'allure normale
                s.v = 1.2                        -- panique : vitesse multipliée
                -- fuir vers le bord de SON enclos (v0.64 : bornes par biome)
                local milieu = ((s.penMin or 4) + (s.penMax or 266)) / 2
                s.dir = (s.x < milieu) and -1 or 1
            elseif s.vNormale then
                s.v = s.vNormale                 -- l'intrus parti : reprise
                s.vNormale = nil
            end
            s.f:ClearAllPoints()
            -- Ombre portée : créée au premier passage, elle suit le sprite
            -- (ellipse sombre au sol, le bob la fait légèrement respirer).
            -- Sans elle, les bêtes semblaient flotter au-dessus de l'herbe.
            if not s.ombre then
                -- v0.112 : ombre PROCÉDURALE (MHH_OmbrePlate) — le TGA
                -- ombre.tga ne se chargeait pas de façon fiable sur le
                -- client (SetTexture paresseux, repli jamais déclenché)
                -- et l'ombre restait invisible (« ils font collés »).
                -- Frame 3 bandes dégradées : SetSize/SetPoint/Show
                -- fonctionnent comme sur l'ancienne texture.
                local om = MHH_OmbrePlate(MHH_enclosMenagerie)
                -- SOUS le modèle : en frame, l'ombre se dessinerait
                -- AU-DESSUS de la bête (les frames enfants passent
                -- avant) — on la place explicitement un cran dessous.
                pcall(function()
                    om:SetFrameLevel((s.f and s.f:GetFrameLevel() or 2) - 1)
                end)
                -- v0.115b : moins large et moins haute (retour
                -- utilisateur : trop grosse, trop allongée)
                -- v0.158 : 26x6 -> 18x5 (retour : « encore un peu trop
                -- grosse ») : mieux vaut une petite ombre discrète.
                om:SetSize(18, 5)
                s.ombre = om
            end
            s.ombre:ClearAllPoints()
            if etat == "affame" then
                -- il boude : coin de SON enclos, tout pâle, immobile
                s.f:SetAlpha(0.35)
                -- v0.118i : échelle remise à 1 (l'échelle de profondeur
                -- du ticker décalerait ses offsets d'ancrage)
                s.f:SetScale(1)
                s.f:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT",
                    s.penMin or 8, (s.penY or 12))
                s.ombre:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT",
                    (s.penMin or 8) + s.f:GetWidth() / 2 - 24, (s.penY or 12) + 5)
                s.ombre:Show()
            else
                s.f:SetAlpha(1)
                -- PAUSE PÂTURE (v0.65f) : pause SPONTANÉE toutes les ~8 s
                -- en moyenne (1-4 s d'arrêt), pas seulement aux demi-tours.
                -- Coût nul : un compteur par bête, zéro allocation.
                if s.pause and s.pause > 0 then
                    s.pause = s.pause - 1
                else
                    s.pause = nil
                    if math.random() < 0.006 then
                        s.pause = 20 + math.random(60)
                    end
                end
                -- HORLOGE PROPRE (v0.65j BUGFIX) : GetTime() continue
                -- pendant les pauses, donc l'errance verticale et le bob
                -- « avançaient » sans la bête — à la reprise, elle SAUTAIT
                -- d'un coup vers la position atteinte par la sinusoïde.
                -- On accumule le temps de pause dans un décalage : les
                -- oscillations reprennent exactement où elles se sont
                -- arrêtées. Coût : deux soustractions par tick.
                local maintenant2 = GetTime()
                local dt = maintenant2 - (s.lastT or maintenant2)
                s.lastT = maintenant2
                if s.pause then s.tOff = (s.tOff or 0) + dt end
                local tEff = maintenant2 - (s.tOff or 0)
                -- BOB FONDU (v0.65g) : le sautillement de marche s'estompe
                -- PROGRESSIVEMENT pendant les pauses. Avant : arrêt net de
                -- 2-3 px d'un coup — sur un sprite 24 px, ça lisait
                -- « saccade » à chaque pause et chaque redémarrage.
                local ampCible = (not s.pause) and ((gate and 4 or 1) * MHH_ECHELLE) or 0
                s.bobN = (s.bobN or 0) + (ampCible - (s.bobN or 0)) * 0.12
                local bob = math.abs(math.sin(tEff * (gate and 7 or 3)
                    + s.phase)) * s.bobN
                if not s.pause then
                    -- MARCHE EN X + bornes + miroir, DANS le test de pause
                    -- (v0.65h BUGFIX : avant, l'avancée se faisait AVANT le
                    -- test — pendant les pauses, la bête glissait sur
                    -- l'herbe, pattes figées, sans marcher « à pied »)
                    s.x = s.x + s.dir * s.v
                    local mini = s.penMin or 4
                    local maxi = s.penMax
                        or (MHH_enclosMenagerie:GetWidth() - 16 * MHH_TAILLE_PIX * MHH_ECHELLE - 8)
                    if s.x < mini then s.x = mini s.dir = 1 end
                    if s.x > maxi then s.x = maxi s.dir = -1 end
                    -- v0.65 : MIROIR selon la direction — l'art regarde à
                    -- GAUCHE par défaut, on le retourne pour marcher à
                    -- droite (UV des textures existantes : zéro allocation)
                    if s.dir ~= s.face then
                        s.face = s.dir
                        -- v0.70 : le modèle 3D se retourne NATIVEMENT
                        -- (SetFacing en radians).
                        if s.f.utiliseModele and s.f.mhhFace then
                            -- v0.111 : sens INVERSE (avant, ils
                            -- marchaient a reculons)
                            s.f:SetFacing(s.f.mhhFace
                                + ((s.dir == -1) and math.pi or 0))
                        end
                    end
                    -- ERRANCE VERTICALE (v0.65f) : SINUSOÏDE lente, de
                    -- fréquence propre à chaque bête (tirée à la création)
                    -- — croisée avec la marche en x, la trajectoire ne se
                    -- répète JAMAIS exactement. Plus de circuit mécanique.
                    local yMin, yMax = s.penY or 12, s.penYmax or (s.penY or 12)
                    s.y = yMin + (yMax - yMin)
                        * (0.5 + 0.5 * math.sin(tEff
                            * (s.freqY or 0.08) + s.phase * 2))
                    -- v0.118c : PROFONDEUR — plus la bête est HAUTE dans
                    -- son enclos (au fond de la scène), plus elle est
                    -- PETITE ; elle rezoome en redescendant. 1,0 en bas
                    -- de bande, ~0,70 tout au fond (retour utilisateur :
                    -- « plus petits le temps qu'ils aillent au fond,
                    -- rezoomés quand ils descendent »).
                    s.prof = (s.y - yMin) / math.max(1, yMax - yMin)
                end
                -- v0.118c : PROFONDEUR sur les modèles 3D aussi — la
                -- bête rapetisse au fond et regrossit en redescendant.
                if s.f.utiliseModele then
                    s.f:SetScale(1 - 0.30 * (s.prof or 0))
                end
                -- v0.105 : ANIM DE MARCHE (modèles 3D) — sans elle, les
                -- bêtes GLISSENT (déplacement SetPoint sans cycle de
                -- pattes, retour utilisateur). Marche pendant le
                -- mouvement, retour idle (0) pendant les pauses pâture.
                -- Le n° d'anim se règle en jeu : /mhhw <n> (testé à
                -- l'\339\147il), stocké en DB. SetFacing n'est PAS
                -- touché : le miroir continue de marcher.
                if s.f.utiliseModele then
                    -- v0.107 : anim 4 = MARCHE AVANT, validée en jeu
                    -- (13 = marche arrière / moonwalk, rejetée). Défaut 4 ;
                    -- /mhhw off pose false pour couper réellement.
                    -- v0.118o : anim PAR SPÉCIMEN (/mhha) avant le
                    -- réglage global (/mhhw) — les n° d'anim changent
                    -- selon le SQUELETTE (le murloc pédèle à l'envers
                    -- avec l'anim 4, retour utilisateur).
                    local cfgA = MHH_DB and MHH_DB.config
                    local aM = cfgA and cfgA.animSpec
                        and cfgA.animSpec[s.nom]
                    if aM == nil then aM = cfgA and cfgA.marcheAnim end
                    if aM == nil then aM = (MHH_ANIM_SPEC_DEFAUT or {})[s.nom] end
                    if aM == nil then aM = 4 end
                    -- v0.109 : SetAnimation ECRASE l'orientation
                    -- du modele (retour utilisateur : « ils ne se
                    -- tournent pas ») — on repose le miroir APRES
                    -- chaque changement d'anim.
                    if aM then
                        if s.pause and s.marcheOn then
                            s.marcheOn = nil
                            pcall(function()
                                s.f:SetAnimation(0)
                                if s.f.mhhFace then
                                    s.f:SetFacing(s.f.mhhFace
                                        + ((s.dir == -1)
                                            and math.pi or 0))
                                end
                            end)
                        elseif not s.pause and not s.marcheOn then
                            s.marcheOn = true
                            pcall(function()
                                s.f:SetAnimation(aM)
                                if s.f.mhhFace then
                                    s.f:SetFacing(s.f.mhhFace
                                        + ((s.dir == -1)
                                            and math.pi or 0))
                                end
                            end)
                        end
                    end
                end
                -- position commune marche/pause : le bob fondu garantit une
                -- transition douce entre les deux états
                -- v0.118i BUGFIX : SetScale MULTIPLIE AUSSI les offsets
                -- d'ancrage de la frame — au fond (échelle ~0,70) la
                -- bête glissait à 70 % de sa position vers la gauche et
                -- SORTAIT de son enclos (dragon/neige/raptor, retour
                -- utilisateur). On compense : offsets ÷ échelle.
                local echProf = 1 - 0.30 * (s.prof or 0)
                -- v0.118u BUGFIX MOONWALK (retour : « le murloc recule
                -- puis se retourne pour avancer ») : le CYCLE d'anim
                -- en boucle écrase l'orientation du modèle en cours de
                -- route — SetFacing n'était reposé qu'aux demi-tours
                -- (dir ~= face), d'où la bête qui moonwalk jusqu'au
                -- bord avant de se retourner. On repose le miroir À
                -- CHAQUE TICK : coût nul, le moonwalk est mort.
                if s.f.utiliseModele and s.f.mhhFace then
                    pcall(function()
                        s.f:SetFacing(s.f.mhhFace
                            + ((s.dir == -1) and math.pi or 0))
                    end)
                end
                s.f:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT",
                    s.x / echProf, (s.y + bob) / echProf)
                -- l'ombre s'aplatit quand la bête saute : ancre le mouvement
                -- v0.118c : elle RAPETISSE AUSSI au fond (suit la bête)
                local omScale = (1 - 0.30 * (s.prof or 0))
                    * (1 - bob * 0.045)
                -- v0.115b : ombre ÉTROITE et BASSE, centrée sous
                -- la bête (retour utilisateur : trop grosse/allongée)
                -- v0.158 : ENCORE PLUS PETITE (retour : « encore un
                -- peu trop grosse ») : 18x5, une ombre discrète.
                s.ombre:SetSize(18 * omScale, 5 * omScale)
                s.ombre:SetPoint("BOTTOMLEFT", MHH_enclosMenagerie, "BOTTOMLEFT",
                    s.x + 9, s.y + 3)
                -- v0.118l : CŒUR DÉVOUÉ — fondu DOUX vers 0,85 pendant
                -- le survol, retour à 0 en quittant (une bête non
                -- dévouée ne montre rien, cible = 0 en permanence).
                if s.ico then
                    local cible = (s.icoSurvol and s.icoActif) and 0.85 or 0
                    local a = (s.icoAlpha or 0) + (cible - (s.icoAlpha or 0)) * 0.15
                    s.icoAlpha = a
                    if a < 0.01 and cible == 0 then
                        if s.ico:IsShown() then s.ico:Hide() end
                    else
                        s.ico:Show()
                        s.ico:SetAlpha(a)
                    end
                end
                -- v0.152 : cycles de poses retirés — les modèles 3D
                -- ont leur idle natif du jeu.
            end
            end
        end
    end
end
local function DemarrerMenagerie()
    ArreterMenagerie()
    if C_Timer and C_Timer.NewTicker then
        MHH_tickerMenagerie = C_Timer.NewTicker(0.05, BoucleMenagerie)
    end
end
pageMenagerie:HookScript("OnHide", ArreterMenagerie)

-- SÉLECTEUR DE BIOMES RETIRÉ (savane/marais/montagnes/volcan) :
-- reveniendra avec de vrais fonds par biome. Un seul enclos pour
-- l'instant — fond unique enclos.tga.

-- SLOTS DE SPÉCIMENS RETIRÉS (raptor, etc.) : l'enclos ne montre
-- plus que la scène — la sélection/nourrissage reviendra plus tard,
-- une fois l'enclos visuel au point.

-- BOUTONS DE GESTION RETIRÉS (info, Nourrir, Gâter, Relâcher, Tous
-- nourrir) : tant que la scène de l'enclos n'est pas au point, la
-- Ménagerie ne montre QUE le décor. La logique de nourrissage (fonctions
-- plus bas) reste en place — les boutons reviendront après.

-- INTRUS : parfois (20% à l'ouverture de l'onglet, 1 fois/heure max), un
-- gibier sauvage surgit dans l'enclos et affole les pensionnaires pendant
-- 12 s (ils se dispersent) ; s'il est encore là, il s'enfuit. Le message
-- indique sa zone — le chasseur sait où traquer la bestiole effrontée.
MHH_intrus = { nom = nil, jusqua = 0 }
local function PeutDeclencherIntrus()
    if not MHH_DB then return false end
    if not MHH_DB.menagerie then return false end
    local nb = 0
    for _ in pairs(MHH_DB.menagerie) do nb = nb + 1 end
    if nb == 0 then return false end        -- enclos vide : rien à effrayer
    if time() < (MHH_DB.intrusCooldown or 0) then return false end
    return math.random(100) <= 20
end
local function DeclencherIntrus()
    -- L'INTRUS : un gibier du CARNET DE CHASSE (rares Forever du data file —
    -- jamais un boss de raid ni un PNJ hors carnet). Préférence : une bête de
    -- la zone d'un pensionnaire de l'enclos affiché (cohérence), sinon
    -- n'importe quel rare catalogué.
    local biome = MHH_DB.enclosActif or "savane"
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
    MHH_DB.intrusCooldown = time() + 3600
    DEFAULT_CHAT_FRAME:AddMessage(L("|cffffd100[MH Hunt]|r |cffff5050Un intrus !|r ")
        .. intrusNom .. L(" saute la clôture de l'enclos et effraye le troupeau !"))
    -- Message simple : plaque sombre sans medaillon ni tampon (retour
    -- utilisateur — l'intrus est une annonce, pas une validation)
    ToastSucces("Interface\\Icons\\Ability_Hunter_BeastTaming",
        L("Intrus dans l'enclos"), intrusNom, "wow")
end

function RaffraichirMenagerie()
    if not MHH_DB then return end
    -- Fond : rechargé à l'ouverture (double sûreté : si le SetTexture du
    -- parse n'a pas pris sur ce client, celui-ci le rattrape)
    if MHH_ChargerFondEnclos then MHH_ChargerFondEnclos() end
    -- Bâtiment du ranch selon le rang de guilde (remplace le précédent)
    if MHH_MajBatimentsRanch then MHH_MajBatimentsRanch() end
    MHH_DB.menagerie = MHH_DB.menagerie or {}
    -- INTRUS : déclenchement SUSPENDU — les sprites n'étant plus visibles
    -- tant que les TGA des spécimens ne sont pas posés, l'intrus invisible
    -- et ses messages prêtaient à confusion. Le code reste, prêt à revenir.
    -- if not MHH_intrus.nom and PeutDeclencherIntrus() then DeclencherIntrus() end
    -- Succès « Enclos complet » : tous les spécimens de la savane
    -- capturés (v0.119l : la savane est passe à 3 pensionnaires max,
    -- son catalogue aussi — Sarkoth vit désormais en montagne, sinon
    -- le succes était mathématiquement impossible)
    if MHH_DB.succes and not MHH_DB.succes["encloscomplet"] then
        local complet = true
        -- v0.120 : le seuil reste le TRIO HISTORIQUE de la savane même
        -- si le catalogue de candidats s'est élargi (Dishu, Snort,
        -- Azzere) — sinon le succès devenait mathématiquement très long
        local trioSavane = { "Humar le Seigneur hautain",
                             "Takk le Bondisseur", "Mazzranache" }
        for _, nomC in ipairs(trioSavane) do
            if not MHH_DB.menagerie[nomC] then complet = false break end
        end
        if complet then DebloquerSucces("encloscomplet") end
    end
    -- Enclos actif : le biome de rattachement du spécimen sélectionné, sinon
    -- le premier enclos débloqué (les vieux perros ont « savane » par défaut).
    -- (v0.64 : plus de biome « actif » — le fond montre les 4 enclos
    -- d'un coup et chaque pensionnaire vit dans le sien, cf. plus bas)
    -- v0.152 : pensionnaires rendus par les MODÈLES 3D du jeu — une
    -- bête sans modèle chargé (cache client vide) reste cachée, son
    -- modèle apparaît dès qu'elle a été croisée en jeu.
    -- v0.64 : le fond montre les 4 enclos d'un coup — chaque pensionnaire
    -- vit dans SON enclos (savane à gauche → lave à droite), borné au
    -- quart de largeur de son biome.
    for _, nom in ipairs(MHH_SPECIMENS_ORDRE) do
        if MHH_DB.menagerie[nom] then
            if not MHH_spritesMenagerie[nom] then
                -- Enclos du spécimen : SON carré peint sur le fond (v0.65 :
                -- plus de quarts verticaux — savane = carré haut-gauche,
                -- lave = tiers bas-droit, bas-gauche = espace bâtiment)
                local cle = MHH_ENCLOS_DU_SPECIMEN[nom]
                local geom = (cle and MHH_ENCLOS_GEOM[cle])
                    or { x1 = 0.02, x2 = 0.28, y = 0.05 }
                -- v0.104 : décalage de calage par zone, persistant dans
                -- la DB (réglé en jeu via /mhhe <zone> <dx> <dy>)
                local dec = (MHH_DB and MHH_DB.config
                    and MHH_DB.config.enclos
                    and MHH_DB.config.enclos[cle or ""]) or nil
                local dx, dy = (dec and dec.dx) or 0, (dec and dec.dy) or 0
                local larg = MHH_enclosMenagerie:GetWidth()
                local haut = MHH_enclosMenagerie:GetHeight()
                -- v0.118v : MARGES ANTI-BARRIÈRE (retour : « les mobs
                -- chevauchent les barrières — Humar à gauche, le murloc
                -- en bas »). Le sprite est ancré par son COIN BAS-GAUCHE
                -- et le modèle rendu déborde de sa frame : on inset
                -- la moitié du sprite de CHAQUE côté, et on décolle le
                -- bas de la barrière avant. Calage fin possible en jeu
                -- via /mhhe <zone> <dx> <dy>.
                local margeS = MHH_TAILLE_SPRITE_TGA * MHH_ECHELLE / 2
                local penMin = geom.x1 * larg + margeS + 4 + dx
                local penMax = math.max(penMin + 2,
                    geom.x2 * larg - MHH_TAILLE_SPRITE_TGA * MHH_ECHELLE
                    - margeS - 4 + dx)
                -- v0.119h : rangée éventuelle (1 = fond, 2 = devant) ;
                -- remplie par le bloc tranches ci-dessous, appliquée à
                -- la bande verticale plus bas (une seule place possible)
                local rangEnc = nil
                -- v0.119c : TRANCHE PAR SPÉCIMEN (retour : « possible
                -- qu\'ils se chevauchent moins ? ») — chacun son quartier
                -- (1/n de la bande selon l\'ordre FIXE de MHH_ENCLOS :
                -- stable d\'une session à l\'autre), 15 % de recouvrement
                -- pour que les voisins se croisent encore un peu. Si la
                -- bande est trop étroite pour n tranches de 28 px, tout
                -- le monde garde la bande entière (mieux vaut un
                -- chevauchement qu\'une bête clouée sur place).
                local listeEnclos = (cle and MHH_ENCLOS_INDEX and
                    MHH_ENCLOS[MHH_ENCLOS_INDEX[cle]])
                    and MHH_ENCLOS[MHH_ENCLOS_INDEX[cle]].specimens or nil
                if listeEnclos then
                    local nB, iB = #listeEnclos, 1
                    for idxB, nomB in ipairs(listeEnclos) do
                        if nomB == nom then iB = idxB end
                    end
                    -- v0.119h : DEUX RANGÉES quand l'enclos se remplit
                    -- (retour : « dans la savane y en a pas mal »). La
                    -- 1re moitié passe au FOND (haut de bande), la 2e
                    -- DEVANT (bas) ; l'ordre de création fait le reste :
                    -- créées après, les bêtes de devant se dessinent
                    -- DESSUS — l'empilement se lit comme de la profondeur.
                    -- Ici : rang + tranches horizontales SEULEMENT (penY
                    -- n'existe pas encore — le découpage vertical suit la
                    -- définition de la bande, juste en dessous).
                    if nB >= 4 then
                        local coupe = math.floor(nB / 2)
                        local posR, nR
                        if iB <= coupe then
                            rangEnc = 1
                            posR, nR = iB, coupe
                        else
                            rangEnc = 2
                            posR, nR = iB - coupe, nB - coupe
                        end
                        -- tranche horizontale DANS la rangée
                        if nR > 1 and (penMax - penMin) / nR >= 20 then
                            local base0 = penMin
                            local tranche = (penMax - penMin) / nR
                            local rec = tranche * 0.10
                            penMin = base0 + (posR - 1) * tranche
                                - (posR > 1 and rec or 0)
                            penMax = math.min(penMax,
                                base0 + posR * tranche
                                + (posR < nR and rec or 0))
                        end
                    elseif nB > 1 and (penMax - penMin) / nB >= 28 then
                        local tranche = (penMax - penMin) / nB
                        local rec = tranche * 0.15
                        local pMinB = penMin + (iB - 1) * tranche
                            - (iB > 1 and rec or 0)
                        local pMaxB = penMin + iB * tranche
                            + (iB < nB and rec or 0)
                        penMin = pMinB
                        penMax = math.min(penMax, pMaxB)
                    end
                end
                -- bande verticale d'errance : la bête monte et descend
                -- dans SON carré, pas seulement gauche-droite (v0.65b)
                -- v0.118v : +10 px pour dégager la barrière AVANT
                -- (retour : le murloc la chevauchait en bas).
                local penY = geom.y * haut + 10 + dy
                local penYmax = (geom.y2 or geom.y) * haut + dy
                if penYmax < penY then penYmax = penY end
                -- v0.119h : bande verticale DE LA RANGÉE (si 2 rangées,
                -- léger chevauchement des rangées : c'est la profondeur)
                if rangEnc then
                    local miY = penY + (penYmax - penY) / 2
                    if rangEnc == 1 then
                        penYmax = miY + 6
                    else
                        penY = miY - 6
                        if penYmax < penY then penYmax = penY end
                    end
                end
                MHH_spritesMenagerie[nom] = {
                    f = CreerSpriteMenagerie(nom),
                    nom = nom,
                    x = penMin + math.random(0, math.max(1, penMax - penMin)),
                    penMin = penMin, penMax = penMax,
                    penY = penY, penYmax = penYmax,
                    y = penY + math.random() * math.max(0, penYmax - penY),
                    dy = (math.random(2) == 1) and 1 or -1,
                    dir = (math.random(2) == 1) and 1 or -1,
                    v = 0.15 + math.random() * 0.3,
                    phase = math.random() * 6,
                    -- v0.109 : 0,04-0,12 = 75-150 s de periode,
                    -- imperceptible (retour utilisateur). x3 : 25-50 s.
                    freqY = 0.12 + math.random() * 0.24,
                }
            end
            -- v0.117 : CLIC sur la bête = sa fiche (nourrissage
            -- enfin possible depuis la scène)
            -- v0.118 : les PlayerModel ne supportent pas
            -- SetScript("OnClick") sur ce client -> bouton
            -- invisible enfant cree une seule fois.
            local sp = MHH_spritesMenagerie[nom]
            if sp.f and not sp.btn then
                local btn = CreateFrame("Button", nil, sp.f)
                btn:SetAllPoints(sp.f)
                btn:RegisterForClicks("LeftButtonUp")
                btn:SetScript("OnClick",
                    function() MHH_OuvrirFichePensionnaire(nom) end)
                -- v0.118l : le cœur DÉVOUÉ n'apparaît qu'AU SURVOL de
                -- la bête (fondu doux, géré par le ticker). OnEnter/
                -- OnLeave passe par le BOUTON — le PlayerModel ne
                -- supporte pas les handlers (même piège que OnClick).
                btn:SetScript("OnEnter", function() sp.icoSurvol = true end)
                btn:SetScript("OnLeave", function() sp.icoSurvol = false end)
                sp.btn = btn
            end
            if sp.f then sp.f:EnableMouse(true) end
            -- v0.118k : INDICATEUR EN SCÈNE (retour utilisateur : pas de
            -- jauge dans la fiche, un truc discret sur la scène) — petit
            -- cœur au-dessus des bêtes DÉVOUÉES uniquement (affinité 100 :
            -- +10 % points de chasse). Suit l'échelle de profondeur
            -- (enfant du modèle, rapetisse au fond).
            if sp.f and not sp.ico then
                local ico = sp.f:CreateTexture(nil, "OVERLAY")
                ico:SetSize(12, 12)
                ico:SetPoint("BOTTOM", sp.f, "TOP", 0, 2)
                ico:SetTexture("Interface\\Icons\\INV_ValentinesCandy")
                ico:SetAlpha(0.85)
                sp.ico = ico
            end
            if sp.ico then
                local m = MHH_DB.menagerie[nom]
                -- v0.118l : AFFICHÉ SEULEMENT AU SURVOL — le ticker
                -- gère le fondu ; ici on ne marque que « dévoué ? ».
                sp.icoActif = (m and Affinite and (Affinite(m) >= 100))
                    and true or false
                sp.ico:SetShown(sp.icoActif)
                sp.ico:SetAlpha(0)
            end
            if MHH_spritesMenagerie[nom].f.utiliseModele then
                MHH_spritesMenagerie[nom].f:Show()
            else
                MHH_spritesMenagerie[nom].f:Hide()
                if MHH_spritesMenagerie[nom].ombre then
                    MHH_spritesMenagerie[nom].ombre:Hide()
                end
            end
        elseif MHH_spritesMenagerie[nom] then
            MHH_spritesMenagerie[nom].f:Hide()
            if MHH_spritesMenagerie[nom].ombre then
                MHH_spritesMenagerie[nom].ombre:Hide()
            end
        end
    end
    -- L'enclos (le ranch entier) compte-t-il des pensionnaires ?
    local nbCaptures = 0
    for _ in pairs(MHH_DB.menagerie) do nbCaptures = nbCaptures + 1 end
    MHH_enclosVideFond:SetShown(nbCaptures == 0)
    -- v0.124 : le régisseur n'entre en scène qu'à la première prise
    -- (cohérent avec la plaque : « le régisseur dort » = il n'est pas
    -- là). Ombre et bulle suivent. NB : caché, son OnUpdate est coupé
    -- par le client — zéro coût quand la ménagerie est vide.
    local regisseurVisible = nbCaptures > 0
    if MHH_regisseur then
        MHH_regisseur:SetShown(regisseurVisible)
        if MHH_regisseur.ombre then MHH_regisseur.ombre:SetShown(regisseurVisible) end
        if not regisseurVisible and MHH_bulleRegisseur then
            MHH_bulleRegisseur:Hide()
        end
    end
    -- v0.128 : l'INTERFACE DU RANCH (goblin en scène, son ombre, HUD
    -- des compteurs/boutons) n'apparaît qu'APRÈS le premier dialogue
    -- avec le régisseur (regisseurIntro, posé par le dialogue
    -- d'ouverture — qui exige une 1re prise pour se déclencher).
    local introVu = (MHH_DB and MHH_DB.regisseurIntro) == true
    if MHH_voileEnclos then MHH_voileEnclos:SetShown(not introVu) end
    if MHH_regisseurScene then MHH_regisseurScene:SetShown(introVu) end
    if MHH_regisseurSceneOmbre then MHH_regisseurSceneOmbre:SetShown(introVu) end
    if MHH_hudRanch then MHH_hudRanch:SetShown(introVu) end
    if not introVu and MHH_bulleRegisseur then
        MHH_bulleRegisseur:Hide()
    end
    if MHH_MajHudRanch then MHH_MajHudRanch() end -- v0.110 : compteurs
    -- (slots, boutons nourrissage : retirés — cf. plus haut)
    DemarrerMenagerie()
end

-- ============================================================
-- v0.81 : RÉGLAGE LIVE DU PORTRAIT DE GAZLOWE (sans ReloadUI).
-- Test terrain : SetModelScale ne grossit quasi pas la créature
-- (recadrage auto du PlayerModel) ; SetPosition(a, b, c) : le
-- 2e argument (b) est LATÉRAL (négatif = gauche). La caméra
-- custom (SetCustomCamera) n'EXISTE PAS en 1.12 (confirmé en
-- jeu) : le goblin reste cadré en entier — c'est le look final.
--
--   /mhhg <zoom> <latéral>   ex: /mhhg 1.6 -0.5
-- ============================================================
-- v0.85 : RÉGLAGES LIVE DU PORTRAIT
--   /mhhz <niveau>  -> SetCamDistanceScale (0.4 = tête dégagée,
--                      1.0 = serré). Si l'API manque, le chat le dit.
--   /mhht           -> COUPE/REMET l'anim de parole (60) : la tête
--                      arrête de se pencher hors du cadre.
SLASH_MHHZ1 = "/mhhz"
SlashCmdList["MHHZ"] = function(msg)
    if not MHH_gueuleGazlowe then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ouvre d'abord la M\195\169nagerie")
        return
    end
    local n = tonumber(msg and msg:match("%S+"))
    if n and MHH_dialogueRegisseur then
        MHH_dialogueRegisseur.distParle = n
        MHH_dialogueRegisseur.dist = n   -- prend effet immédiatement
        DEFAULT_CHAT_FRAME:AddMessage("MHH: distance PAROLE = "
            .. string.format("%.2f", n)
            .. " (repos inchang\195\169)")
    end
end
SLASH_MHHHI1 = "/mhhi"
SlashCmdList["MHHHI"] = function(msg)
    if not MHH_gueuleGazlowe or not MHH_cadrePortrait then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ouvre d'abord la M\195\169nagerie")
        return
    end
    local n = tonumber(msg and msg:match("%S+")) or 1.0   -- v0.96 : /mhhi sans argument = retour au ratio 1
    if n > 0.3 and n <= 1 then
        local t = MHH_cadrePortrait:GetWidth()
        local m = MHH_gueuleGazlowe
        m:ClearAllPoints()
        m:SetSize(t * n, t * n)
        m:SetPoint("CENTER", MHH_cadrePortrait, "CENTER", 0, 0)
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ratio portrait = "
            .. string.format("%.2f", n) .. " (1 = cadre entier)")
    else
        DEFAULT_CHAT_FRAME:AddMessage("MHH: /mhhi <ratio 0.5-1> ex: /mhhi 0.86")
    end
end
SLASH_MHHO1 = "/mhho"
SlashCmdList["MHHO"] = function()
    -- v0.112 : diagnostic du décor de la Ménagerie — imprime l'état
    -- des éléments qui n'apparaissaient pas (liseré, HUD, ombres).
    local function info(label, v)
        DEFAULT_CHAT_FRAME:AddMessage("MHH: " .. label .. " = "
            .. tostring(v))
    end
    info("page ouverte", pageMenagerie and pageMenagerie:IsShown())
    info("cadre enclos", MHH_cadreEnclos
        and tostring(MHH_cadreEnclos:IsVisible()) or "nil")
    info("HUD ranch", MHH_hudRanch
        and tostring(MHH_hudRanch:IsVisible()) or "nil")
    if MHH_hudRanch and MHH_hudRanch.l1 then
        info("HUD texte", MHH_hudRanch.l1:GetText())
    end
    info("titre plaque", MHH_menagerieTitrePlaque
        and tostring(MHH_menagerieTitrePlaque:IsVisible()) or "nil")
    info("ombre batiment", MHH_ombreBatiment
        and tostring(MHH_ombreBatiment:IsVisible()) or "nil")
    local n = 0
    for _, s in pairs(MHH_spritesMenagerie or {}) do
        n = n + 1
        -- v0.154 : distinguer MODÈLE 3D (ombre normale) et SILHOUETTE
        -- (modèle pas en cache client → PAS d'ombre par design, retour :
        -- « ombres sur quelques mobs seulement »).
        if s.f then
            info((s.f.utiliseModele and "3D " or "SILHOUETTE ")
                .. (s.f.mhhNom or "?"),
                s.ombre and tostring(s.ombre:IsVisible()) or "sans ombre")
        end
    end
    info("pensionnaires", n)
end
SLASH_MHHW1 = "/mhhw"
SlashCmdList["MHHW"] = function(msg)
    -- v0.105 : règle le N° D'ANIM DE MARCHE des pensionnaires 3D.
    -- L'anim exacte varie selon le modèle : essaie /mhhw 1 .. 15 en
    -- regardant la scène, et garde celle où les pattes pédalent.
    --   /mhhw off -> pas d'anim (retour au glissement lisse)
    if not MHH_DB then return end
    MHH_DB.config = MHH_DB.config or {}
    if msg and msg:match("^%s*off") then
        MHH_DB.config.marcheAnim = false
        for _, s in pairs(MHH_spritesMenagerie or {}) do
            s.marcheOn = nil
            if s.f and s.f.utiliseModele then
                pcall(function() s.f:SetAnimation(0) end)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("MHH: anim de marche OFF (glissement lisse)")
        return
    end
    local n = tonumber(msg and msg:match("%S+"))
    if n then
        MHH_DB.config.marcheAnim = n
        for _, s in pairs(MHH_spritesMenagerie or {}) do
            s.marcheOn = nil
            if s.f and s.f.utiliseModele then
                pcall(function() s.f:SetAnimation(0) end)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("MHH: anim de marche = " .. n
            .. " (visible des que les b\195\170tes bougent)")
    else
        DEFAULT_CHAT_FRAME:AddMessage("MHH: /mhhw <n\176>  |  /mhhw off")
    end
end
SLASH_MHHA1 = "/mhha"
SlashCmdList["MHHA"] = function(msg)
    -- v0.118o : anim de marche PAR SPÉCIMEN — le n° d'anim varie
    -- selon le squelette du modèle (murloc != raptor).
    --   /mhha flaggle 3      -> anim 3 pour le spécimen matchant
    --   /mhha flaggle off    -> coupe l'anim pour CE spécimen
    --   /mhha flaggle reset  -> retombe sur le réglage global (/mhhw)
    if not MHH_DB then return end
    local a, b = msg and msg:match("^%s*(%S+)%s+(%S+)")
    if not (a and b) then
        DEFAULT_CHAT_FRAME:AddMessage(
            "MHH: /mhha <partie du nom> <n\176|off|reset>")
        return
    end
    local nomTrouve = nil
    for n2 in pairs(MHH_DB.menagerie or {}) do
        if n2:lower():find(a:lower(), 1, true) then
            nomTrouve = n2 break
        end
    end
    if not nomTrouve then
        DEFAULT_CHAT_FRAME:AddMessage(
            "MHH: aucun pensionnaire ne matche \"" .. a .. "\"")
        return
    end
    MHH_DB.config = MHH_DB.config or {}
    MHH_DB.config.animSpec = MHH_DB.config.animSpec or {}
    if b == "off" then
        MHH_DB.config.animSpec[nomTrouve] = false
    elseif b == "reset" then
        MHH_DB.config.animSpec[nomTrouve] = nil
    else
        local n2 = tonumber(b)
        if not n2 then
            DEFAULT_CHAT_FRAME:AddMessage("MHH: n\176 invalide")
            return
        end
        MHH_DB.config.animSpec[nomTrouve] = n2
    end
    for _, s in pairs(MHH_spritesMenagerie or {}) do
        s.marcheOn = nil
        if s.f and s.f.utiliseModele then
            pcall(function() s.f:SetAnimation(0) end)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("MHH: " .. nomTrouve
        .. " -> anim " .. tostring(MHH_DB.config.animSpec[nomTrouve]))
end
SLASH_MHHE1 = "/mhhe"
SlashCmdList["MHHE"] = function(msg)
    -- v0.104 : CALAGE LIVE DES ENCLOS. Le nouveau fond 3D n'a pas les
    -- memes bornes que l'ancien Stardew : /mhhe decale UNE zone entiere
    -- (toutes ses betes), en pixels, et le garde en DB (persistant).
    --   /mhhe savane 20 15     -> savane : 20 px a droite, 15 px plus haut
    --   /mhhe reset            -> remet les offsets a zero
    -- dx en px (negatif = gauche), dy en px (positif = vers le HAUT).
    if not MHH_DB then return end
    MHH_DB.config = MHH_DB.config or {}
    MHH_DB.config.enclos = MHH_DB.config.enclos or {}
    local function RebaserSprite(nom, sp, dx, dy)
        sp.penMin = sp.penMin + dx
        sp.penMax = sp.penMax + dx
        sp.penY = sp.penY + dy
        sp.penYmax = sp.penYmax + dy
        if sp.penYmax < sp.penY then sp.penYmax = sp.penY end
        sp.x = math.min(math.max(sp.x, sp.penMin), sp.penMax)
        sp.y = math.min(math.max(sp.y, sp.penY), sp.penYmax)
    end
    if msg and msg:match("^%s*reset") then
        MHH_DB.config.enclos = {}
        for nom, sp in pairs(MHH_spritesMenagerie or {}) do
            local cle = MHH_ENCLOS_DU_SPECIMEN[nom]
            local geom = cle and MHH_ENCLOS_GEOM[cle]
            if geom then
                local larg = MHH_enclosMenagerie:GetWidth()
                local haut = MHH_enclosMenagerie:GetHeight()
                sp.penMin = geom.x1 * larg + 4
                sp.penMax = math.max(sp.penMin + 2,
                    geom.x2 * larg - MHH_TAILLE_SPRITE_TGA * MHH_ECHELLE - 4)
                sp.penY = geom.y * haut
                sp.penYmax = (geom.y2 or geom.y) * haut
                if sp.penYmax < sp.penY then sp.penYmax = sp.penY end
                sp.x = math.min(math.max(sp.x, sp.penMin), sp.penMax)
                sp.y = math.min(math.max(sp.y, sp.penY), sp.penYmax)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("MHH: calage des enclos remis a zero")
        return
    end
    local zone, a, b =
        string.match(msg or "", "([%a]+)%s+(-?[%d%.]+)%s+(-?[%d%.]+)")
    if not (zone and a and b) or not MHH_ENCLOS_GEOM[zone] then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: /mhhe <savane|marais|montagne|volcan> <dx> <dy>  |  /mhhe reset")
        return
    end
    local dx, dy = tonumber(a), tonumber(b)
    local c = MHH_DB.config.enclos[zone] or {}
    c.dx = (c.dx or 0) + dx
    c.dy = (c.dy or 0) + dy
    MHH_DB.config.enclos[zone] = c
    for nom, sp in pairs(MHH_spritesMenagerie or {}) do
        if MHH_ENCLOS_DU_SPECIMEN[nom] == zone then
            RebaserSprite(nom, sp, dx, dy)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("MHH: enclos " .. zone .. " dx="
        .. string.format("%.0f", c.dx) .. " dy=" .. string.format("%.0f", c.dy))
end
SLASH_MHHD1 = "/mhhd"
SlashCmdList["MHHD"] = function()
    -- v0.102 : rejoue le dialogue de Gazlowe (test). Le declencheur
    -- automatique ne se joue qu'une fois apres la premiere capture.
    local d = MHH_dialogueRegisseur
    if not d or not MHH_gueuleGazlowe then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ouvre d'abord la M\195\169nagerie")
        return
    end
    d.nu = 0
    d.acc = 0
    d.fini = nil
    d.zoomFini = nil
    d.zoomAtt = nil
    d.dist = d.distParle
    d.texte:SetText("")
    local tp = d.taillePortrait or 99
    local r = d.ratioParle or 1.0
    MHH_gueuleGazlowe:ClearAllPoints()
    MHH_gueuleGazlowe:SetSize(tp * r, tp * r)
    MHH_gueuleGazlowe:SetPoint("CENTER", MHH_cadrePortrait, "CENTER", 0, 0)
    pcall(function()
        MHH_gueuleGazlowe:SetScale(d.scaleParle or 0.92) end)
    pcall(function()
        MHH_gueuleGazlowe:SetCamDistanceScale(d.distParle or 1.7) end)
    pcall(function()
        MHH_gueuleGazlowe:SetAnimation(60) end)
    d:Show()
    DEFAULT_CHAT_FRAME:AddMessage("MHH: dialogue re jou\195\169")
end
SLASH_MHHHS1 = "/mhhs"
SlashCmdList["MHHHS"] = function(msg)
    if not MHH_gueuleGazlowe then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ouvre d'abord la M\195\169nagerie")
        return
    end
    local n = tonumber(msg and msg:match("%S+"))
    if n then
        pcall(function() MHH_gueuleGazlowe:SetScale(n) end)
        DEFAULT_CHAT_FRAME:AddMessage("MHH: échelle portrait = "
            .. string.format("%.2f", n) .. " (1 = normal)")
    else
        DEFAULT_CHAT_FRAME:AddMessage("MHH: /mhhs <échelle> ex: /mhhs 0.85")
    end
end
SLASH_MHHV1 = "/mhhv"
SlashCmdList["MHHV"] = function(msg)
    if not MHH_gueuleGazlowe then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ouvre d'abord la M\195\169nagerie")
        return
    end
    -- v0.90 : test AXE VERTICAL (3e arg de SetPosition) + latéral.
    -- usage: /mhhv <vert> <lat>  -- vert positif = ? (a tester)
    local a, b = string.match(msg or "", "(%S+)%s+(%S+)")
    local a2 = tonumber(msg and msg:match("%S+"))
    local z, lat
    if a and b then z, lat = tonumber(a), tonumber(b) end
    if z then
        pcall(function() MHH_gueuleGazlowe:SetPosition(0, lat or 0.12, z) end)
        DEFAULT_CHAT_FRAME:AddMessage("MHH: vert=" .. string.format("%.2f", z)
            .. " lat=" .. string.format("%.2f", lat or 0.12)
            .. " (si rien bouge: 3e arg pas vertical)")
    elseif a2 then
        pcall(function() MHH_gueuleGazlowe:SetPosition(0, 0.12, a2) end)
        DEFAULT_CHAT_FRAME:AddMessage("MHH: vert=" .. string.format("%.2f", a2)
            .. " lat=0.12")
    else
        DEFAULT_CHAT_FRAME:AddMessage("MHH: /mhhv <vert> [lat]")
    end
end
SLASH_MHHT1 = "/mhht"
SlashCmdList["MHHT"] = function()
    if not MHH_gueuleGazlowe then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ouvre d'abord la M\195\169nagerie")
        return
    end
    MHH_REGISSEUR_PARLE = not (MHH_REGISSEUR_PARLE == nil or MHH_REGISSEUR_PARLE)
    if MHH_REGISSEUR_PARLE then
        MHH_gueuleGazlowe:SetAnimation(60)
        DEFAULT_CHAT_FRAME:AddMessage("MHH: il PARLE")
    else
        MHH_gueuleGazlowe:SetAnimation(0)
        DEFAULT_CHAT_FRAME:AddMessage("MHH: il se tait")
    end
end
SLASH_MHHG1 = "/mhhg"
SlashCmdList["MHHG"] = function(msg)
    if not MHH_gueuleGazlowe then
        DEFAULT_CHAT_FRAME:AddMessage("MHH: ouvre d'abord la M\195\169nagerie")
        return
    end
    local a, b = string.match(msg or "", "(%S+)%s+(%S+)")
    local z, lat = tonumber(a), tonumber(b)
    if z then MHH_gueuleGazlowe:SetModelScale(z) end
    if lat then MHH_gueuleGazlowe:SetPosition(0, lat, 0) end
    DEFAULT_CHAT_FRAME:AddMessage("MHH: gueule zoom="
        .. (z and string.format("%.2f", z) or "?")
        .. " lat\195\169ral=" .. (lat and string.format("%.2f", lat) or "?"))
end
-- ================================================================
-- v0.119d : ROSTER DE L'ENCLOS — VERSION BLINDÉE (anti-fatality)
-- OÙ LE COLLER : en TOUT DERNIER de Menagerie.lua, APRÈS la création
-- de MHH_enclosMenagerie et du HUD ranch (MHH_hudRanch).
-- POURQUOI CE GARDE : une erreur Lua pendant l'exécution d'un fichier
-- ABANDONNE le reste du chunk — c'est comme ça que MHH_pageMenagerie
-- s'est retrouvé nil (fatality à l'ouverture du carnet). Mal placé, ce
-- bloc affiche désormais un message dans le chat au lieu de tuer
-- Ménagerie.lua. Bien placé, il ne s'affiche jamais.
-- ================================================================
if not (MHH_enclosMenagerie and MHH_hudRanch) then
    pcall(function()
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[MH Hunt]|r Roster ménagerie : bloc mal placé — colle-le en FIN de Menagerie.lua, après la création de l'enclos et du HUD ranch.")
    end)
elseif MHH_btnRoster then
    -- déjà installé (double collage) : rien à faire
else

-- Couleurs d'état (mêmes teintes que les libellés d'EtatSpecimen)
local MHH_ROSTER_ETAT = {
    repu   = { 0.63, 1.00, 0.31 },
    faim   = { 1.00, 0.82, 0.00 },
    affame = { 0.85, 0.48, 0.42 },
}

-- v0.127 : tronque proprement en UTF-8 (jamais au milieu d'un accent)
MHH_TronquerTexte = function(txt, nb)
    if string.len(txt or "") <= nb then return txt end
    local cut = string.sub(txt, 1, nb)
    while string.len(cut) > 0 and string.byte(cut, -1) > 127 do
        cut = string.sub(cut, 1, -2)
    end
    return cut .. "..."
end

-- ===== 1. BOUTON « Liste » — DANS le HUD ranch (en haut à droite de l'encart) =====
MHH_btnRoster = CreateFrame("Button", nil, MHH_hudRanch)
MHH_btnRoster:SetSize(40, 14) -- v0.146 : plus compact
-- v0.119g : en bas du HUD, a cote de Nourrir tout (retour utilisateur)
-- v0.148 : colle a Nourrir tout (retour : trop d ecart, marge sur la largeur)
MHH_btnRoster:SetPoint("BOTTOMLEFT", MHH_hudNourrir, "BOTTOMRIGHT", 4, 0)
-- v0.125 : 61 -> 63. Au MEME niveau que son parent MHH_hudRanch (61),
-- le hit-test peut laisser le parent manger le clic (retour : bouton
-- toujours pas cliquable). 63 le place au-dessus du parent ET de la
-- fiche pensionnaire (62). RegisterForClicks = securite 1.12.
MHH_btnRoster:SetFrameLevel(63)
pcall(function() MHH_btnRoster:RegisterForClicks("LeftButtonUp", "RightButtonUp") end)
local brFond = MHH_btnRoster:CreateTexture(nil, "BACKGROUND")
brFond:SetAllPoints()
brFond:SetColorTexture(0.42, 0.35, 0.20, 0.85)
MHH_Cadrer(MHH_btnRoster, 0.85, 0.68, 0.25, 0.6, 1)
MHH_btnRoster.texte = MHH_btnRoster:CreateFontString(nil, "OVERLAY")
MHH_btnRoster.texte:SetFont("Fonts\\FRIZQT__.TTF", 9)
MHH_btnRoster.texte:SetTextColor(0.98, 0.85, 0.45, 1)
MHH_btnRoster.texte:SetPoint("CENTER", 0, 0)
MHH_btnRoster.texte:SetText("Liste")
MHH_btnRoster:SetScript("OnClick", function()
    -- v0.119f : pcall — un clic muet ne diagnostique rien ; l'erreur
    -- est affich\195\169e au chat (retour : \171 le bouton Liste marche pas \187)
    local ok, err = pcall(function()
        if MHH_roster:IsVisible() then
            MHH_roster:Hide()
        else
            MHH_MajRoster()
            MHH_roster:Show()
        end
    end)
    if not ok then
        pcall(function()
            DEFAULT_CHAT_FRAME:AddMessage("|cffff2000[MH Hunt]|r Liste : "
                .. tostring(err))
        end)
    end
end)
MHH_btnRoster:SetScript("OnEnter", function(self)
    brFond:SetColorTexture(0.55, 0.46, 0.26, 0.95)
    self.texte:SetTextColor(1, 1, 0.6, 1)
end)
MHH_btnRoster:SetScript("OnLeave", function(self)
    brFond:SetColorTexture(0.42, 0.35, 0.20, 0.85)
    self.texte:SetTextColor(0.98, 0.85, 0.45, 1)
end)

-- ===== 2. LE PANNEAU (fond sombre + liseré, langue du HUD) =====
MHH_roster = CreateFrame("Frame", nil, MHH_enclosMenagerie)
-- v0.119g : le bouton est en bas ; le panneau s\'ouvre AU-DESSUS du HUD
MHH_roster:SetPoint("BOTTOMRIGHT", MHH_btnRoster, "TOPRIGHT", 0, 6)
MHH_roster:SetSize(132, 24)
MHH_roster:SetFrameLevel(64) -- au-dessus de la fiche pensionnaire (62)
MHH_roster:EnableMouse(true)
MHH_roster:Hide()
local rosFond = MHH_roster:CreateTexture(nil, "BACKGROUND")
rosFond:SetAllPoints()
rosFond:SetColorTexture(0.06, 0.05, 0.04, 0.80)
MHH_Cadrer(MHH_roster, 0.85, 0.68, 0.25, 0.5, 1)
MHH_roster.entete = MHH_roster:CreateFontString(nil, "OVERLAY")
MHH_roster.entete:SetFont("Fonts\\FRIZQT__.TTF", 9)
MHH_roster.entete:SetTextColor(0.98, 0.85, 0.45, 1)
MHH_roster.entete:SetPoint("TOPLEFT", 6, -4)
MHH_roster.lignes = {}
MHH_roster.nbLignes = 0

-- Une ligne : pastille 6x6 + nom + affinité. Clic = fiche pensionnaire.
local function CreerLigneRoster(i)
    local ln = CreateFrame("Button", nil, MHH_roster)
    ln:SetSize(160, 18) -- v0.136 : marge droite des noms resserrée
    ln:SetPoint("TOPLEFT", 4, -(20 + (i - 1) * 18))
    ln.pastille = ln:CreateTexture(nil, "ARTWORK")
    ln.pastille:SetSize(7, 7)
    ln.pastille:SetPoint("LEFT", 6, 0)
    ln.pastille:SetColorTexture(1, 1, 1, 1)
    ln.nom = ln:CreateFontString(nil, "OVERLAY")
    ln.nom:SetFont("Fonts\\FRIZQT__.TTF", 10)
    ln.nom:SetTextColor(0.92, 0.86, 0.69, 1)
    ln.nom:SetPoint("LEFT", 16, 0)
    ln.nom:SetShadowColor(0, 0, 0, 1)
    ln.nom:SetShadowOffset(1, -1)
    ln.affinite = ln:CreateFontString(nil, "OVERLAY")
    ln.affinite:SetFont("Fonts\\FRIZQT__.TTF", 9)
    ln.affinite:SetTextColor(0.60, 0.55, 0.44, 1)
    ln.affinite:SetPoint("RIGHT", -6, 0)
    ln:SetScript("OnClick", function(self)
        if self.mhhNom and MHH_MajFichePensionnaire then
            MHH_MajFichePensionnaire(self.mhhNom)
        end
    end)
    ln:SetScript("OnEnter", function(self)
        if not (self.mhhNom and MHH_DB and MHH_DB.menagerie
            and MHH_DB.menagerie[self.mhhNom]) then return end
        local m = MHH_DB.menagerie[self.mhhNom]
        local _, lib = EtatSpecimen(m)
        pcall(function()
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(self.mhhNom, 1, 0.82, 0.25, 1)
            GameTooltip:AddLine(lib, 0.8, 0.74, 0.55, 1)
            GameTooltip:AddLine("Nourri il y a "
                .. IlYA(m.nourri or m.capture or time()),
                0.55, 0.50, 0.40, 1)
            GameTooltip:AddLine("Affinité : "
                .. string.format("%.0f", Affinite(m)) .. "%", 0.8, 0.74, 0.55, 1)
            GameTooltip:Show()
        end)
    end)
    ln:SetScript("OnLeave", function() pcall(function() GameTooltip:Hide() end) end)
    return ln
end

-- ===== 3. REMPLISSAGE — ordre stable de Specimens.lua, puis les hors-catalogue
MHH_MajRoster = function()
    if not (MHH_roster and MHH_DB and MHH_DB.menagerie) then return end
    for _, ln in ipairs(MHH_roster.lignes) do ln:Hide() end
    local n = 0
    local vus = {}
    local function Ajouter(nom)
        if vus[nom] or n >= 11 then return end -- v0.119g : reste dans l\'enclos
        local m = MHH_DB.menagerie[nom]
        if not m then return end
        vus[nom] = true
        n = n + 1
        local ln = MHH_roster.lignes[n] or CreerLigneRoster(n)
        MHH_roster.lignes[n] = ln
        ln.mhhNom = nom
        local etat = EtatSpecimen(m)
        local c = MHH_ROSTER_ETAT[etat] or MHH_ROSTER_ETAT.repu
        ln.pastille:SetColorTexture(c[1], c[2], c[3], 1)
        ln.nom:SetText(MHH_TronquerTexte(nom, 19)) -- v0.127 : « ... » si trop long (tooltip = complet)
        ln.affinite:SetText(string.format("%.0f%%", Affinite(m)))
        ln:Show()
    end
    for _, nom in ipairs(MHH_SPECIMENS_ORDRE or {}) do Ajouter(nom) end
    for nom in pairs(MHH_DB.menagerie) do Ajouter(nom) end
    MHH_roster.nbLignes = n
    MHH_roster:SetSize(168, 22 + n * 18 + 6) -- v0.136 : 190 laissait un vide à droite des noms
    MHH_roster.entete:SetText("PENSIONNAIRES (" .. n .. ")")
end

-- Branchement auto sur le HUD ranch
local _MajHudRanchAvant = MHH_MajHudRanch
MHH_MajHudRanch = function(...)
    if _MajHudRanchAvant then _MajHudRanchAvant() end
    if MHH_roster and MHH_roster:IsVisible() then MHH_MajRoster() end
end

end -- fin du garde (bloc blindé)


MHH_MarquerEtat = function(f, etat)
    if not f then return end
    if etat == "affame" and not f.mhhMarque then
        local t = f:CreateTexture(nil, "BACKGROUND")
        t:SetSize(f:GetWidth() * 1.2, 8)
        t:SetPoint("BOTTOM", f, "BOTTOM", 0, -1)
        t:SetColorTexture(0.85, 0.30, 0.25, 0.45)
        f.mhhMarque = t
    end
    if f.mhhMarque then
        if etat == "affame" then f.mhhMarque:Show() else f.mhhMarque:Hide() end
    end
end
-- Dans RaffraichirMenagerie, là où chaque pensionnaire est repositionné :
--     local etat = EtatSpecimen(m)
--     MHH_MarquerEtat(f, etat)

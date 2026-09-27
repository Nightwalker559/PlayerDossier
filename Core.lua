-- ============================================================
--  PlayerDossier – Core.lua
--  Namespace, SavedVariables, CRUD, Slash-Commands
-- ============================================================

PlayerDossier = PlayerDossier or {}
local PD = PlayerDossier

-- Locale-Tabelle: Fallback auf den Key selbst
PD.L = setmetatable({}, { __index = function(_, k) return k end })

-- ----------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------

local myRealm  -- gecacht nach ADDON_LOADED, danach unveränderlich

-- Gibt den aktuellen Realm-Namen zurück (gecacht nach erstem Aufruf)
local function GetMyRealm()
    if not myRealm then myRealm = GetRealmName() end
    return myRealm
end
PD.GetMyRealm = GetMyRealm  -- für andere Module

-- ----------------------------------------------------------------
-- Secret Values (WoW 12.0+ "Midnight"): UnitName() etc. can return
-- secret string values in certain restricted contexts (e.g. active
-- PvP matches, some restricted maps). Tainted addon code cannot
-- compare/concat these directly - doing so throws a hard Lua error.
-- This helper checks with issecretvalue() (global API, safe to call
-- on any value) and returns ok=false if the name/realm can't be
-- read right now, so callers can bail out gracefully instead of
-- crashing. See: https://warcraft.wiki.gg/wiki/Secret_Values
-- ----------------------------------------------------------------
function PD:SafeUnitName(unit)
    local name, realm = UnitName(unit)
    if type(issecretvalue) == "function" and (issecretvalue(name) or issecretvalue(realm)) then
        return nil, nil, false
    end
    return name, realm, true
end

-- Shared "time ago" formatter used by Players/Ignore/History panels
-- (was duplicated 3x before 1.8.0 - now a single source of truth)
function PD:TimeAgo(ts)
    if not ts then return "?" end
    local diff = time() - ts
    if diff < 3600 then
        return "<1h"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. "h"
    else
        return math.floor(diff / 86400) .. "d"
    end
end

-- Kanonischer Key: "Name-Realm"
function PD:GetKey(name, realm)
    if type(realm) ~= "string" or realm == "" then
        realm = GetMyRealm()
    end
    return name .. "-" .. realm
end

-- ----------------------------------------------------------------
-- Gemeinsame Spalten-Positionen für Spieler-/Ignorier-/Verlauf-Tab.
-- Alle drei Panels liegen im selben Hauptfenster (gleiche Breite),
-- daher sorgen identische x-Werte für exakt gleiches Aussehen.
-- MODE ist exklusiv für den Verlauf-Tab (Modus-Spalte). LAST ist
-- "Notiz" bei Spieler/Ignorierliste, aber "Gruppiert" im Verlauf.
-- ----------------------------------------------------------------
PD.COL = {
    NAME  = 58,   -- Platz für das 48px Stimmungs-Icon im Spieler-Tab
    REALM = 220,
    ROLE  = 330,  -- nicht in Ignorierliste verwendet
    MODE  = 370,  -- nur Verlauf (zeigt ausschließlich "M+"/"M+20" – ScanGroup() filtert auf ^M%+)
    SEIT  = 440,
    LAST  = 485,  -- Notiz (Spieler/Ignorierliste) bzw. Gruppiert (Verlauf)
}

-- ----------------------------------------------------------------
-- Gemeinsamer Tabellenkopf für Spieler-/Ignorier-/Verlauf-Tab.
-- Sorgt dafür, dass alle drei Tabs optisch identisch aussehen und
-- jede Spaltenüberschrift bis zur nächsten Spalte (bzw. bei der
-- letzten Spalte bis zum rechten Rand) breit ist, statt ohne
-- Breitenbegrenzung ggf. abgeschnitten zu wirken.
--
-- heads: { { text=<string>, x=<pixel-offset von links> }, ... }
--        sortiert nach x aufsteigend.
-- rightPad: Abstand zum rechten Panelrand (Standard 26, passt zur
--           Scrollbar-Breite der drei ScrollFrames).
-- ----------------------------------------------------------------
function PD:BuildColumnHeaders(panel, heads, rightPad)
    rightPad = rightPad or 26
    for i, h in ipairs(heads) do
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", h.x + 2, -4)
        local nextX  = heads[i + 1] and heads[i + 1].x
        local width  = nextX and (nextX - h.x - 4)
            or (panel:GetWidth() - h.x - rightPad - 2)
        if width and width > 0 then fs:SetWidth(width) end
        fs:SetJustifyH("LEFT")
        fs:SetText(h.text)
        fs:SetTextColor(0.9, 0.82, 0.5)
    end

    -- Trennlinie unter den Überschriften (einheitlich für alle drei Tabs)
    local sep = panel:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  panel, "TOPLEFT",   4,  -18)
    sep:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -rightPad, -18)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.8)
end

-- ----------------------------------------------------------------
-- Frame-Pooling für Zeilen in Players-/Ignorier-/Verlauf-Panel.
-- Jedes Panel hatte vorher seine eigene identische Pool-Implementierung
-- (rowPool/GetRow/HideAllRows) - jetzt eine gemeinsame Fabrikfunktion.
-- ----------------------------------------------------------------
function PD:NewRowPool()
    local pool = {}
    local function GetRow(parent)
        for _, r in ipairs(pool) do
            if not r:IsShown() then r:SetParent(parent) r:Show() return r end
        end
        local r = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        table.insert(pool, r)
        return r
    end
    local function HideAll()
        for _, r in ipairs(pool) do r:Hide() end
    end
    return GetRow, HideAll
end

-- ----------------------------------------------------------------
-- DB-Initialisierung
-- ----------------------------------------------------------------

function PD:Init()
    if not PlayerDossierDB then
        PlayerDossierDB = { players = {}, version = 1 }
    end
    if not PlayerDossierDB.players then
        PlayerDossierDB.players = {}
    end
end

-- ----------------------------------------------------------------
-- CRUD
-- ----------------------------------------------------------------

function PD:GetEntry(name, realm)
    local db = PlayerDossierDB
    if not db or not db.players then return nil end
    return db.players[PD:GetKey(name, realm)]
end

-- mood: "positive" | "negative" | "neutral"
function PD:SetEntry(name, realm, note, mood, class, guid)
    PD:Init()
    realm = (realm and realm ~= "") and realm or GetMyRealm()
    local key = PD:GetKey(name, realm)
    local old = PlayerDossierDB.players[key]
    PlayerDossierDB.players[key] = {
        name      = name,
        realm     = realm,
        note      = note  or "",
        mood      = mood  or "neutral",
        class     = class or (old and old.class) or "UNKNOWN",
        guid      = guid  or (old and old.guid)  or "",
        timestamp = (old and old.timestamp) or time(),
    }
end

function PD:RemoveEntry(name, realm)
    local db = PlayerDossierDB
    if not db or not db.players then return end
    db.players[PD:GetKey(name, realm)] = nil
end

function PD:GetAllEntries()
    local db = PlayerDossierDB
    if not db or not db.players then return {} end
    return db.players
end

function PD:Count()
    local n = 0
    for _ in pairs(PD:GetAllEntries()) do n = n + 1 end
    return n
end

-- ----------------------------------------------------------------
-- Slash-Commands
-- ----------------------------------------------------------------

SLASH_PLAYERDOSSIER1 = "/pd"
SLASH_PLAYERDOSSIER2 = "/playerdossier"
SLASH_PLAYERDOSSIER3 = "/dossier"

SlashCmdList["PLAYERDOSSIER"] = function(msg)
    local L = PD.L
    msg = msg and strtrim(msg:lower()) or ""
    if msg == "" or msg == "list" then
        PD:ToggleMainWindow()
    elseif msg == "clear" then
        StaticPopup_Show("PD_CONFIRM_CLEAR")
    elseif msg == "help" then
        print(L["SLASH_HELP_HEADER"])
        print(L["SLASH_HELP_PD"])
        print(L["SLASH_HELP_IGNORE"])
        print(L["SLASH_HELP_MINIMAP"])
        print(L["SLASH_HELP_CLEAR"])
        print(L["SLASH_HELP_HELP"])
        print(L["SLASH_HELP_ADD"])
    else
        print(L["SLASH_UNKNOWN"])
    end
end

-- ----------------------------------------------------------------
-- Static Popups (hier definiert, L ist zu dem Zeitpunkt schon geladen)
-- ----------------------------------------------------------------

StaticPopupDialogs["PD_CONFIRM_CLEAR"] = {
    text         = function() return PlayerDossier.L["CONFIRM_CLEAR"] end,
    button1      = function() return PlayerDossier.L["BTN_DELETE_ALL"] end,
    button2      = function() return PlayerDossier.L["BTN_CANCEL"] end,
    OnAccept     = function()
        if PlayerDossierDB then PlayerDossierDB.players = {} end
        print(PlayerDossier.L["CLEARED_MSG"])
        if PlayerDossier.mainFrame and PlayerDossier.mainFrame:IsShown() then
            PlayerDossier:RefreshMainWindow()
        end
    end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

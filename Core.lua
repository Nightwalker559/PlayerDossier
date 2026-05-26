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

-- Kanonischer Key: "Name-Realm"
function PD:GetKey(name, realm)
    if type(realm) ~= "string" or realm == "" then
        realm = GetMyRealm()
    end
    return name .. "-" .. realm
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
        timestamp  = (old and old.timestamp) or time(),
        encounters = (old and old.encounters or 0) + (old and 0 or 1),
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

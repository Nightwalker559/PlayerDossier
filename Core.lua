-- ============================================================
--  PlayerDossier – Core.lua
--  Namespace, shared helpers, SavedVariables, CRUD, slash commands
-- ============================================================

PlayerDossier = PlayerDossier or {}
local PD = PlayerDossier

-- Locale table: missing strings fall back to the key itself
PD.L = setmetatable({}, { __index = function(_, k) return k end })
local L = PD.L

local MEDIA = "Interface/AddOns/PlayerDossier/Media/"

-- ----------------------------------------------------------------
-- Realm / name helpers
-- ----------------------------------------------------------------

-- All realm names are stored in their normalized form without spaces
-- ("TarrenMill"), which is what UnitName(), chat senders and the native
-- ignore list use. GetRealmName() returns "Tarren Mill" instead.
local myRealm  -- cached once WoW reports it

local function GetMyRealm()
    if myRealm then return myRealm end
    local normalized = GetNormalizedRealmName and GetNormalizedRealmName()
    if normalized and normalized ~= "" then
        myRealm = normalized
        return myRealm
    end
    -- Not available yet (very early login): derive it, but don't cache
    return (((GetRealmName() or ""):gsub("%s", "")))
end
PD.GetMyRealm = GetMyRealm

-- Normalizes a realm name; empty/missing means "same realm as the player"
function PD.NormRealm(realm)
    if type(realm) == "string" and realm ~= "" then
        return (realm:gsub("%s", ""))
    end
    return GetMyRealm()
end

-- "Name-Realm" → name, realm (realm is nil when absent). Realm names may
-- contain hyphens, so only the last segment counts as the realm.
function PD.SplitName(full)
    local name, realm = full:match("^(.+)-([^%-]+)$")
    return name or full, realm
end

-- Canonical key: "Name-Realm"
function PD:GetKey(name, realm)
    return name .. "-" .. PD.NormRealm(realm)
end

-- "Name" for the player's own realm, "Name-Realm" otherwise - the form WoW
-- expects for /w and the native ignore list
function PD.TargetName(name, realm)
    realm = PD.NormRealm(realm)
    return (realm == GetMyRealm()) and name or (name .. "-" .. realm)
end

-- ----------------------------------------------------------------
-- Secret Values (WoW 12.0+ "Midnight"): UnitName(), chat senders etc.
-- can return secret values in restricted contexts (active PvP matches,
-- instances, ...). Tainted code must not compare/concatenate them -
-- doing so throws a hard Lua error. issecretvalue() is safe to call
-- on any value. See https://warcraft.wiki.gg/wiki/Secret_Values
-- ----------------------------------------------------------------
PD.IsSecret = issecretvalue or function() return false end

-- Returns name, realm, ok. ok=false when the name can't be read right now.
function PD:SafeUnitName(unit)
    local name, realm = UnitName(unit)
    if PD.IsSecret(name) or PD.IsSecret(realm) then
        return nil, nil, false
    end
    return name, realm, true
end

-- Calls fn(unit, name, realm) for every other player in the group whose
-- name is readable. realm is normalized (never empty).
function PD:ForEachGroupMember(fn)
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = prefix .. i
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name, realm, ok = PD:SafeUnitName(unit)
            if ok and name then
                fn(unit, name, PD.NormRealm(realm))
            end
        end
    end
end

-- Only an active Mythic+ run counts; normal dungeons/heroics/raids don't.
function PD:IsMythicPlusActive()
    local isActive = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
    if not isActive then return false end
    local ok, active = pcall(isActive)
    return ok and active or false
end

-- ----------------------------------------------------------------
-- Misc helpers
-- ----------------------------------------------------------------

function PD.TableCount(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- "<1h" / "5h" / "12d"
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

-- ----------------------------------------------------------------
-- Moods
-- ----------------------------------------------------------------

PD.MOOD = {
    positive = { r = 0, g = 0.80, b = 0,    hex = "00cc00", labelKey = "MOOD_GOOD",    file = "mood_good",    order = 1 },
    neutral  = { r = 1, g = 0.85, b = 0,    hex = "ffdd00", labelKey = "MOOD_NEUTRAL", file = "mood_neutral", order = 2 },
    negative = { r = 1, g = 0.18, b = 0.18, hex = "ff2e2e", labelKey = "MOOD_BAD",     file = "mood_bad",     order = 3 },
}
for _, m in pairs(PD.MOOD) do
    m.tex = MEDIA .. m.file .. ".png"
end

-- Unknown / missing moods count as neutral
function PD:GetMood(id)
    return PD.MOOD[id] or PD.MOOD.neutral
end

-- Inline texture string for chat/tooltips
function PD:MoodIcon(id, size)
    size = size or 16
    return string.format("|T%s:%d:%d|t", PD:GetMood(id).tex, size, size)
end

-- ----------------------------------------------------------------
-- Init / UI-build callbacks. Modules register here instead of
-- wrapping PD.Init / PD.BuildUI.
-- ----------------------------------------------------------------

local initCallbacks, buildCallbacks = {}, {}

function PD:OnInit(fn)    initCallbacks[#initCallbacks + 1] = fn end
function PD:OnBuildUI(fn) buildCallbacks[#buildCallbacks + 1] = fn end

function PD:RunBuildCallbacks()
    for _, fn in ipairs(buildCallbacks) do fn() end
end

-- ----------------------------------------------------------------
-- Slash commands. Modules add subcommands to PD.commands.
-- ----------------------------------------------------------------

PD.commands = {}

SLASH_PLAYERDOSSIER1 = "/pd"
SLASH_PLAYERDOSSIER2 = "/playerdossier"
SLASH_PLAYERDOSSIER3 = "/dossier"

SlashCmdList["PLAYERDOSSIER"] = function(msg)
    local cmd = strtrim((msg or ""):lower())
    if cmd == "" then cmd = "list" end
    local handler = PD.commands[cmd]
    if handler then
        handler()
    else
        print(L["SLASH_UNKNOWN"])
    end
end

PD.commands.list  = function() PD:ToggleMainWindow() end
PD.commands.clear = function() StaticPopup_Show("PD_CONFIRM_CLEAR_PLAYERS") end
PD.commands.help  = function()
    print(L["SLASH_HELP_HEADER"])
    print(L["SLASH_HELP_PD"])
    print(L["SLASH_HELP_IGNORE"])
    print(L["SLASH_HELP_MINIMAP"])
    print(L["SLASH_HELP_CLEAR"])
    print(L["SLASH_HELP_HELP"])
    print(L["SLASH_HELP_ADD"])
end

-- ----------------------------------------------------------------
-- SavedVariables
-- ----------------------------------------------------------------

-- Creates the top-level tables; safe to call repeatedly
function PD:EnsureDB()
    PlayerDossierDB = PlayerDossierDB or { version = 1 }
    local db = PlayerDossierDB
    db.players    = db.players    or {}
    db.ignoreList = db.ignoreList or {}
    db.history    = db.history    or {}
    db.opt        = db.opt        or {}
end

-- Realm format 2: realm names without spaces. Re-keys the entries of the
-- players, ignore list and history tables that were stored with the
-- spaced name from GetRealmName() ("Name-Tarren Mill" → "Name-TarrenMill").
-- If both variants exist, the one already stored under the new key wins.
local REALM_FORMAT = 2

local function MigrateRealmKeys(tbl)
    local moves = {}
    for key, e in pairs(tbl) do
        if e.name then
            local realm  = PD.NormRealm(e.realm)
            local newKey = e.name .. "-" .. realm
            if newKey ~= key then moves[#moves + 1] = { key, newKey, e, realm } end
        end
    end
    for _, m in ipairs(moves) do
        local key, newKey, e, realm = m[1], m[2], m[3], m[4]
        tbl[key] = nil
        if not tbl[newKey] then
            e.realm = realm
            tbl[newKey] = e
        end
    end
end

local function MigrateDB()
    local db = PlayerDossierDB
    if (db.realmFormat or 1) >= REALM_FORMAT then return end
    MigrateRealmKeys(db.players)
    MigrateRealmKeys(db.ignoreList)
    MigrateRealmKeys(db.history)
    db.realmFormat = REALM_FORMAT
end

-- Called once from ADDON_LOADED
function PD:Init()
    PD:EnsureDB()
    MigrateDB()
    for _, fn in ipairs(initCallbacks) do fn() end
end

-- ----------------------------------------------------------------
-- CRUD (dossier entries)
-- ----------------------------------------------------------------

function PD:GetEntry(name, realm)
    local db = PlayerDossierDB
    if not db or not db.players then return nil end
    return db.players[PD:GetKey(name, realm)]
end

-- mood: "positive" | "negative" | "neutral"
function PD:SetEntry(name, realm, note, mood, class, guid)
    PD:EnsureDB()
    realm = PD.NormRealm(realm)
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
    return PD.TableCount(PD:GetAllEntries())
end

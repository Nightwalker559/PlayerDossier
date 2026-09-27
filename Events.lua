-- ============================================================
--  PlayerDossier – Events.lua
--  Event handling: ADDON_LOADED, group roster, reunion notices,
--  leave/kick detection with clickable remember-link
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- Read from the .toc instead of a hardcoded copy so the two can't drift apart
local ADDON_VERSION = C_AddOns.GetAddOnMetadata("PlayerDossier", "Version") or "?"

-- ----------------------------------------------------------------
-- Mood colours for chat notices
-- ----------------------------------------------------------------

-- Inline-Textur-Icons für den Chat (|T...:h:w|t Format)
local MOOD_ICON = {
    positive = "|TInterface/AddOns/PlayerDossier/Media/mood_good.png:16:16|t",
    negative = "|TInterface/AddOns/PlayerDossier/Media/mood_bad.png:16:16|t",
    neutral  = "|TInterface/AddOns/PlayerDossier/Media/mood_neutral.png:16:16|t",
}

local MOOD_COLOR = {
    positive = { hex="00d000" },
    negative = { hex="ff3030" },
    neutral  = { hex="ffdd00" },
}

-- ----------------------------------------------------------------
-- Reunion notification
-- ----------------------------------------------------------------

function PD:ShowReunionNotice(entry)
    if not PD:OPT_Get("chatMessages") then return end
    local mood  = entry.mood or "neutral"
    local icon  = MOOD_ICON[mood]  or MOOD_ICON.neutral
    local col   = MOOD_COLOR[mood] or MOOD_COLOR.neutral

    local nameStr = entry.name or "Unknown"
    if entry.realm and entry.realm ~= PD.GetMyRealm() then
        nameStr = nameStr .. "|cff888888-" .. entry.realm .. "|r"
    end

    local line = string.format("|cff9B82F3[PlayerDossier]|r %s |cff%s%s|r",
        icon, col.hex, nameStr)
    if entry.note and entry.note ~= "" then
        line = line .. " |cffaaaaaa– " .. entry.note .. "|r"
    end
    print(line)
end

-- ----------------------------------------------------------------
-- Clickable "remember" hyperlink
-- Format: |Hpd:remember:Name:Realm|h[remember them]|h
-- ----------------------------------------------------------------

-- Hilfsfunktion: Name in Klassenfarbe + optionaler Realm-Suffix
local function ColoredName(name, realm, class)
    local myRealm = PD.GetMyRealm()
    local cc = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
    local nameStr
    if cc then
        nameStr = string.format("|cff%02x%02x%02x%s|r", cc.r*255, cc.g*255, cc.b*255, name)
    else
        nameStr = "|cffdddddd" .. name .. "|r"
    end
    if realm and realm ~= myRealm then
        nameStr = nameStr .. "|cff888888-" .. realm .. "|r"
    end
    return nameStr
end

-- Hyperlink auch Klasse mitgeben: pd:remember:Name:Realm:Class
local function MakeRememberLink(name, realm, class, linkText)
    realm    = (realm and realm ~= "") and realm or PD.GetMyRealm()
    class    = class or "UNKNOWN"
    linkText = linkText or L["LINK_REMEMBER"]
    return string.format("|Hpd:remember:%s:%s:%s|h|cff9B82F3[%s]|r|h",
        name, realm, class, linkText)
end

-- Hook: Klasse aus dem Link extrahieren
local function PD_OnHyperlinkClick(_, link, _, button)
    local name, realm, class = link:match("^pd:remember:(.+):(.+):(.+)$")
    -- Fallback für alte Links ohne Klasse
    if not name then
        name, realm = link:match("^pd:remember:(.+):(.+)$")
    end
    if not name then return end
    if button == "LeftButton" then
        PD:OpenNoteDialog(name, realm, class ~= "UNKNOWN" and class or nil, nil, "positive")
    end
end

local function HookChatFrame(cf)
    if cf and not cf._pdHooked then
        cf._pdHooked = true
        cf:HookScript("OnHyperlinkClick", PD_OnHyperlinkClick)
    end
end

-- Alle bestehenden Chat-Frames hooken
for i = 1, (NUM_CHAT_WINDOWS or 10) do
    HookChatFrame(_G["ChatFrame"..i])
end

-- Neu erstellte Chat-Fenster (Floated/Docked) ebenfalls hooken
hooksecurefunc("FCF_OpenNewWindow", function()
    C_Timer.After(0, function()
        for i = 1, (NUM_CHAT_WINDOWS or 10) do
            HookChatFrame(_G["ChatFrame"..i])
        end
    end)
end)

-- ----------------------------------------------------------------
-- Group roster tracking for leave/kick detection
-- ----------------------------------------------------------------

-- Snapshot of current group members: key → { name, realm, class, guid }
local prevGroup      = {}
local selfInGroup    = false   -- war der Spieler selbst in einer Gruppe?
local wasMythicPlus  = false   -- war die zuletzt gesehene Gruppe eine aktive M+ Gruppe?

-- Only an active Mythic+ run counts; normal dungeons/heroics/raids don't.
local function IsMythicPlusActive()
    local ok, active = pcall(function()
        return C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
    end)
    return ok and active or false
end

local function SnapshotGroup()
    local snap    = {}
    local isRaid  = IsInRaid()
    local num     = GetNumGroupMembers()
    for i = 1, num do
        local unit = isRaid and ("raid"..i) or ("party"..i)
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name, realm, ok = PD:SafeUnitName(unit)
            if ok and name then
                realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
                local _, class = UnitClass(unit)
                local guid     = UnitGUID(unit)
                local key      = PD:GetKey(name, realm)
                snap[key] = { name=name, realm=realm, class=class, guid=guid }
            end
        end
    end
    return snap
end

-- Zeigt die "has left the group" Nachricht mit klickbarem Link
local function ShowLeavePrompt(info)
    if not PD:OPT_Get("chatMessages") then return end
    local name  = info.name
    local realm = info.realm
    local class = info.class

    -- Klasse ins Dossier schreiben wenn noch unbekannt
    local entry = PD:GetEntry(name, realm)
    if entry and (not entry.class or entry.class == "UNKNOWN") and class then
        entry.class = class
    end

    local action = MakeRememberLink(name, realm, class,
        entry and L["LINK_EDIT"] or L["LINK_REMEMBER"])

    local line = string.format(
        "|cff9B82F3[PlayerDossier]|r %s %s. %s",
        ColoredName(name, realm, class), L["LINK_LEFT_GROUP"], action
    )
    print(line)
end

-- Wird aufgerufen wenn der Spieler selbst aus der Gruppe fliegt (Kick)
-- Zeigt für alle vorherigen Gruppenmitglieder einen Prompt
local function ShowKickedPrompts(snapshot)
    if not PD:OPT_Get("chatMessages") then return end
    if not next(snapshot) then return end
    C_Timer.After(0.3, function()
        print(string.format("|cff9B82F3[PlayerDossier]|r %s", L["KICKED_MSG"]))
        for _, info in pairs(snapshot) do
            local entry = PD:GetEntry(info.name, info.realm)
            -- Klasse ins Dossier schreiben wenn noch unbekannt
            if entry and (not entry.class or entry.class == "UNKNOWN") and info.class then
                entry.class = info.class
            end
            local action = MakeRememberLink(info.name, info.realm, info.class,
                entry and L["LINK_EDIT"] or L["LINK_REMEMBER"])
            print("  " .. ColoredName(info.name, info.realm, info.class) .. " " .. action)
        end
    end)
end

-- ----------------------------------------------------------------
-- Players we already notified this session (reunion notices)
-- ----------------------------------------------------------------

local wasInRaid             = false
local notifiedThisSession   = {}
local rosterUpdatePending   = false   -- Debounce fuer GROUP_ROSTER_UPDATE

-- prevSnap: Snapshot VOR dem Update (nil = Login/Reload, alle pruefen)
function PD:CheckGroupMembers(prevSnap)
    local isRaid   = IsInRaid()
    local maxSlots = GetNumGroupMembers()
    for i = 1, maxSlots do
        local unit = isRaid and ("raid"..i) or ("party"..i)
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm, ok = PD:SafeUnitName(unit)
            if ok and name then
                realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
                local key = PD:GetKey(name, realm)
                -- Bereits gemeldet oder schon im vorigen Snapshot (= nicht neu)
                if not notifiedThisSession[key]
                and not (prevSnap and prevSnap[key]) then
                    local entry = PD:GetEntry(name, realm)
                    if entry then
                        notifiedThisSession[key] = true
                        PD:ShowReunionNotice(entry)
                    end
                end
            end
        end
    end
end

-- ----------------------------------------------------------------
-- Event frame
-- ----------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "PDEventFrame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_LEFT")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "PlayerDossier" then
            PD:Init()
            PD:BuildUI()
            local cnt = PD:Count()
            print(string.format(L["PD_LOADED"], ADDON_VERSION, cnt,
                cnt == 1 and L["entry"] or L["entries"]))
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Debounce: GROUP_ROSTER_UPDATE feuert oft 3-5x rapid hintereinander.
        -- Nur den ersten Timer starten; weitere Events bis zum Ablauf ignorieren.
        if not rosterUpdatePending then
            rosterUpdatePending = true
            C_Timer.After(0.6, function()
                rosterUpdatePending = false

                local nowGroup     = SnapshotGroup()
                local nowInGrp     = IsInGroup()
                local nowInRaid    = IsInRaid()
                local nowMythicPlus = IsMythicPlusActive()

                -- Leave-Detection nur in 5er-Gruppe, NICHT im Raid, NUR waehrend M+
                if selfInGroup and nowInGrp and not nowInRaid and nowMythicPlus then
                    for key, info in pairs(prevGroup) do
                        if not nowGroup[key] then
                            ShowLeavePrompt(info)
                        end
                    end
                end

                -- Reunion: nur neu hinzugekommene Mitglieder melden
                PD:CheckGroupMembers(prevGroup)

                prevGroup     = nowGroup
                selfInGroup   = nowInGrp
                wasInRaid     = nowInRaid
                wasMythicPlus = nowMythicPlus
            end)
        end

    elseif event == "GROUP_LEFT" then
        -- Nur in 5er-Gruppe Prompts zeigen, NICHT nach Raid-Verlassen, NUR wenn es M+ war
        if selfInGroup and not wasInRaid and wasMythicPlus and next(prevGroup) then
            ShowKickedPrompts(prevGroup)
        end
        rosterUpdatePending = false
        prevGroup           = {}
        selfInGroup         = false
        wasInRaid           = false
        wasMythicPlus       = false
        wipe(notifiedThisSession)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- arg1 = isLogin (true nur beim ersten Login/Reload, nicht bei Zonenwechsel)
        if arg1 then
            wipe(notifiedThisSession)
        end
        -- Snapshot aktualisieren; initiale Reunion-Notices fuer bestehende Gruppe
        C_Timer.After(1, function()
            -- nil als prevSnap: alle aktuellen Mitglieder pruefen (Login/Reload)
            PD:CheckGroupMembers(nil)
            prevGroup   = SnapshotGroup()
            selfInGroup = IsInGroup()
        end)
    end
end)

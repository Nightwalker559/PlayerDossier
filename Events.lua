-- ============================================================
--  PlayerDossier – Events.lua
--  Event handling: ADDON_LOADED, group roster, reunion notices,
--  leave/kick detection with clickable remember-link
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

local ADDON_VERSION = "1.0.1"

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
local prevGroup   = {}
local selfInGroup = false   -- war der Spieler selbst in einer Gruppe?

local function SnapshotGroup()
    local snap    = {}
    local isRaid  = IsInRaid()
    local num     = GetNumGroupMembers()
    for i = 1, num do
        local unit = isRaid and ("raid"..i) or ("party"..i)
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name, realm = UnitName(unit)
            if name then
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

local wasKicked           = false
local notifiedThisSession = {}

function PD:CheckGroupMembers()
    local isRaid   = IsInRaid()
    local maxSlots = isRaid and GetNumGroupMembers() or GetNumSubgroupMembers()
    for i = 1, maxSlots do
        local unit = isRaid and ("raid"..i) or ("party"..i)
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = UnitName(unit)
            if name then
                realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
                local key = PD:GetKey(name, realm)
                if not notifiedThisSession[key] then
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

local wasKicked           = false
local notifiedThisSession = {}

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
        C_Timer.After(0.5, function()
            local nowGroup  = SnapshotGroup()
            local nowInGrp  = IsInGroup()

            -- Nur in 5er-Gruppe prüfen, NICHT im Raid
            if selfInGroup and nowInGrp and not IsInRaid() then
                for key, info in pairs(prevGroup) do
                    if not nowGroup[key] then
                        ShowLeavePrompt(info)
                    end
                end
            end

            -- Reunion-Benachrichtigung
            PD:CheckGroupMembers()

            prevGroup   = nowGroup
            selfInGroup = nowInGrp
        end)

    elseif event == "GROUP_LEFT" then
        -- Zeigt Prompts ob Kick oder freiwillig – nützlich in beiden Fällen
        if selfInGroup and next(prevGroup) then
            ShowKickedPrompts(prevGroup)
        end
        wasKicked   = false
        prevGroup   = {}
        selfInGroup = false
        wipe(notifiedThisSession)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- arg1 = isLogin, arg2 = isReload
        -- Nur beim echten Login/Reload den Session-Cache leeren,
        -- NICHT bei jedem Portal/Zone-Wechsel
        if arg1 then  -- arg1 = isLogin (true nur beim ersten Einloggen/Reload)
            wipe(notifiedThisSession)
        end
        -- Snapshot immer aktualisieren
        C_Timer.After(1, function()
            prevGroup   = SnapshotGroup()
            selfInGroup = IsInGroup()
        end)
    end
end)

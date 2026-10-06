-- ============================================================
--  PlayerDossier – Events.lua
--  Event handling: ADDON_LOADED, group roster, reunion notices,
--  leave/kick detection with clickable remember-link
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- ----------------------------------------------------------------
-- Reunion notice
-- ----------------------------------------------------------------

-- Grey "-Realm" suffix for players from other realms
local function RealmSuffix(realm)
    if realm and realm ~= PD.GetMyRealm() then
        return "|cff888888-" .. realm .. "|r"
    end
    return ""
end

function PD:ShowReunionNotice(entry)
    if not PD:OPT_Get("chatMessages") then return end
    local mood = PD:GetMood(entry.mood)

    local nameStr = (entry.name or "?") .. RealmSuffix(entry.realm)

    local line = string.format("|cff9B82F3[PlayerDossier]|r %s |cff%s%s|r",
        PD:MoodIcon(entry.mood), mood.hex, nameStr)
    if entry.note and entry.note ~= "" then
        line = line .. " |cffaaaaaa– " .. entry.note .. "|r"
    end
    print(line)
end

-- ----------------------------------------------------------------
-- Clickable "remember" hyperlink
-- Format: |Hpd:remember:Name:Realm:Class|h[remember them]|h
-- ----------------------------------------------------------------

-- Name in class color plus realm suffix for foreign realms
local function ColoredName(name, realm, class)
    local cc = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
    local nameStr
    if cc then
        nameStr = string.format("|cff%02x%02x%02x%s|r", cc.r * 255, cc.g * 255, cc.b * 255, name)
    else
        nameStr = "|cffdddddd" .. name .. "|r"
    end
    return nameStr .. RealmSuffix(realm)
end

local function MakeRememberLink(name, realm, class, linkText)
    return string.format("|Hpd:remember:%s:%s:%s|h|cff9B82F3[%s]|r|h",
        name, PD.NormRealm(realm), class or "UNKNOWN", linkText or L["LINK_REMEMBER"])
end

local function OnHyperlinkClick(_, link, _, button)
    if button ~= "LeftButton" then return end
    local name, realm, class = link:match("^pd:remember:(.+):(.+):(.+)$")
    if not name then return end
    PD:OpenNoteDialog(name, realm, class ~= "UNKNOWN" and class or nil, nil, "positive")
end

local function HookChatFrames()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        if cf and not cf._pdHooked then
            cf._pdHooked = true
            cf:HookScript("OnHyperlinkClick", OnHyperlinkClick)
        end
    end
end

HookChatFrames()

-- Newly created chat windows (floated/docked) need the hook too
hooksecurefunc("FCF_OpenNewWindow", function()
    C_Timer.After(0, HookChatFrames)
end)

-- ----------------------------------------------------------------
-- Group roster tracking for leave/kick detection
-- ----------------------------------------------------------------

-- Snapshot of current group members: key → { name, realm, class, guid }
local prevGroup     = {}
local selfInGroup   = false   -- was the player in a group at the last roster update?
local wasInRaid     = false
local wasMythicPlus = false   -- was the last seen group an active M+ group?

local function SnapshotGroup()
    local snap = {}
    PD:ForEachGroupMember(function(unit, name, realm)
        local _, class = UnitClass(unit)
        snap[PD:GetKey(name, realm)] = { name = name, realm = realm, class = class, guid = UnitGUID(unit) }
    end)
    return snap
end

-- Builds the clickable "Add to Dossier"/"Edit Note" link for a player and
-- stores the class on an existing dossier entry if it was still unknown.
local function RememberAction(info)
    local entry = PD:GetEntry(info.name, info.realm)
    if entry and (not entry.class or entry.class == "UNKNOWN") and info.class then
        entry.class = info.class
    end
    return MakeRememberLink(info.name, info.realm, info.class,
        entry and L["LINK_EDIT"] or L["LINK_REMEMBER"])
end

-- "<name> has left the group. [Add to Dossier]"
local function ShowLeavePrompt(info)
    if not PD:OPT_Get("chatMessages") then return end
    print(string.format("|cff9B82F3[PlayerDossier]|r %s %s. %s",
        ColoredName(info.name, info.realm, info.class), L["LINK_LEFT_GROUP"], RememberAction(info)))
end

-- The player was removed from the group: prompt for every previous member
local function ShowKickedPrompts(snapshot)
    if not PD:OPT_Get("chatMessages") then return end
    if not next(snapshot) then return end
    C_Timer.After(0.3, function()
        print(string.format("|cff9B82F3[PlayerDossier]|r %s", L["KICKED_MSG"]))
        for _, info in pairs(snapshot) do
            print("  " .. ColoredName(info.name, info.realm, info.class) .. " " .. RememberAction(info))
        end
    end)
end

-- ----------------------------------------------------------------
-- Reunion check
-- ----------------------------------------------------------------

local notifiedThisSession = {}
local rosterUpdatePending = false   -- debounce for GROUP_ROSTER_UPDATE

-- prevSnap: snapshot from BEFORE the update (nil = login/reload, check everyone)
function PD:CheckGroupMembers(prevSnap)
    PD:ForEachGroupMember(function(_, name, realm)
        local key = PD:GetKey(name, realm)
        if notifiedThisSession[key] or (prevSnap and prevSnap[key]) then return end
        local entry = PD:GetEntry(name, realm)
        if entry then
            notifiedThisSession[key] = true
            PD:ShowReunionNotice(entry)
        end
    end)
end

-- ----------------------------------------------------------------
-- Event frame
-- ----------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "PDEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_LEFT")

local function OnRosterUpdate()
    rosterUpdatePending = false

    local nowGroup      = SnapshotGroup()
    local nowInGroup    = IsInGroup()
    local nowInRaid     = IsInRaid()
    local nowMythicPlus = PD:IsMythicPlusActive()

    -- Leave detection: only in 5-man groups, never in raids, only during M+
    if selfInGroup and nowInGroup and not nowInRaid and nowMythicPlus then
        for key, info in pairs(prevGroup) do
            if not nowGroup[key] then
                ShowLeavePrompt(info)
            end
        end
    end

    -- Reunion: only announce newly arrived members
    PD:CheckGroupMembers(prevGroup)

    prevGroup     = nowGroup
    selfInGroup   = nowInGroup
    wasInRaid     = nowInRaid
    wasMythicPlus = nowMythicPlus
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "PlayerDossier" then
            PD:Init()
            PD:BuildUI()
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        -- GROUP_ROSTER_UPDATE often fires 3-5x in quick succession:
        -- start one timer and ignore further events until it fires.
        if not rosterUpdatePending then
            rosterUpdatePending = true
            C_Timer.After(0.6, OnRosterUpdate)
        end

    elseif event == "GROUP_LEFT" then
        -- Kick prompts only for a 5-man M+ group, not after leaving a raid
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
        -- arg1 = isLogin (true only on first login/reload, not on zone changes)
        if arg1 then
            wipe(notifiedThisSession)
        end
        C_Timer.After(1, function()
            -- nil as prevSnap: check all current members (login/reload)
            PD:CheckGroupMembers(nil)
            prevGroup   = SnapshotGroup()
            selfInGroup = IsInGroup()
        end)
    end
end)

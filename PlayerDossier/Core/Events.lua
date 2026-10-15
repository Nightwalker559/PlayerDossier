-- ============================================================
--  PlayerDossier – Events.lua
--  Event handling: ADDON_LOADED and group roster changes
--  (reunion notices for players in the dossier)
-- ============================================================

local PD = PlayerDossier

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
-- Reunion check
-- ----------------------------------------------------------------

local prevMembers         = {}   -- keys of the members at the last roster update
local notifiedThisSession = {}   -- keys we already announced
local rosterUpdatePending = false   -- debounce for GROUP_ROSTER_UPDATE

-- Announces dossier players that are new in the group and returns the set
-- of current member keys. prevSnap: members from BEFORE the update (nil =
-- login/reload, check everyone).
function PD:CheckGroupMembers(prevSnap)
    local now = {}
    PD:ForEachGroupMember(function(_, name, realm)
        local key = PD:GetKey(name, realm)
        now[key] = true
        if notifiedThisSession[key] or (prevSnap and prevSnap[key]) then return end
        local entry = PD:GetEntry(name, realm)
        if entry then
            notifiedThisSession[key] = true
            PD:ShowReunionNotice(entry)
        end
    end)
    return now
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
    prevMembers = PD:CheckGroupMembers(prevMembers)
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
        rosterUpdatePending = false
        prevMembers = {}
        wipe(notifiedThisSession)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- arg1 = isLogin (true only on first login/reload, not on zone changes)
        if arg1 then
            wipe(notifiedThisSession)
        end
        C_Timer.After(1, function()
            -- nil = check all current members (login/reload)
            prevMembers = PD:CheckGroupMembers(nil)
        end)
    end
end)

-- ============================================================
--  PlayerDossier – LFG.lua
--  Premade Group Finder integration:
--    • tooltip: mood icons next to known players + notes, warning
--      when an ignored player is in the group
--    • inline warning in the search result list
--    • optionally hide groups containing ignored players
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

local ENTRY_HEIGHT = 52   -- height of a search result row

-- ================================================================
-- 1.  MEMBER CHECK (cached per search result)
-- ================================================================

-- resultID → { hasIgnored, hasDossier, ignored = {name→realm}, dossier = {name→realm} }
local resultCache = {}

-- Lower-case name → entry for the ignore list and the dossier, built lazily.
-- Needed because member names often come without a realm.
local nameIndex

local function IndexByName(tbl)
    local idx = {}
    for _, e in pairs(tbl) do
        if e.name then idx[e.name:lower()] = e end
    end
    return idx
end

local function GetNameIndex()
    if not nameIndex then
        nameIndex = { ignore = IndexByName(PD:IL_GetAll()), dossier = IndexByName(PD:GetAllEntries()) }
    end
    return nameIndex
end

local function CheckResult(resultID)
    if resultCache[resultID] then return resultCache[resultID] end

    local entry = { hasIgnored = false, hasDossier = false, ignored = {}, dossier = {} }
    resultCache[resultID] = entry

    local ok, info = pcall(C_LFGList.GetSearchResultInfo, resultID)
    if not ok or not info then return entry end

    local function CheckMember(mName)
        if not mName or PD.IsSecret(mName) then return end
        local name, realm = PD.SplitName(mName)
        local hasRealm    = realm ~= nil
        realm = PD.NormRealm(realm)

        -- Without a realm the player may be on another realm → look up by name only
        local ignRealm, dosRealm
        if PD:IL_IsIgnored(name, realm) then
            ignRealm = realm
        elseif not hasRealm then
            local e = GetNameIndex().ignore[name:lower()]
            ignRealm = e and e.realm
        end
        if PD:GetEntry(name, realm) then
            dosRealm = realm
        elseif not hasRealm then
            local e = GetNameIndex().dossier[name:lower()]
            dosRealm = e and e.realm
        end

        if ignRealm and not entry.ignored[name] then
            entry.hasIgnored    = true
            entry.ignored[name] = ignRealm
        end
        if dosRealm and not entry.dossier[name] then
            entry.hasDossier    = true
            entry.dossier[name] = dosRealm
        end
    end

    CheckMember(info.leaderName)

    local okNum, numMembers = pcall(C_LFGList.GetNumSearchResultMembers, resultID)
    if okNum and numMembers then
        for i = 1, numMembers do
            local okM, mName = pcall(C_LFGList.GetSearchResultMemberInfo, resultID, i)
            if okM then CheckMember(mName) end
        end
    end

    return entry
end

-- New search → drop all cached results
local lfgFrame = CreateFrame("Frame", "PDLFGEvents")
lfgFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
lfgFrame:RegisterEvent("LFG_LIST_SEARCH_FAILED")

-- ================================================================
-- 2.  TOOLTIP
-- ================================================================

-- Removes color/texture codes so line text can be compared with a name
local function StripCodes(s)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    return s
end

-- Puts the mood icon right before the player's name in the Leader and
-- Members lines of the existing Blizzard/Raider.IO tooltip.
local function AnnotateMemberLines(entry)
    local marks = {}   -- name:lower() → icon
    for name, realm in pairs(entry.dossier) do
        local dEntry = PD:GetEntry(name, realm)
        marks[name:lower()] = PD:MoodIcon(dEntry and dEntry.mood)
    end
    for name, realm in pairs(entry.ignored) do
        if not marks[name:lower()] then
            local dEntry = PD:GetEntry(name, realm)
            marks[name:lower()] = PD:MoodIcon(dEntry and dEntry.mood or "negative")
        end
    end

    for i = 2, GameTooltip:NumLines() do
        for _, side in ipairs({ "Right", "Left" }) do
            local fs   = _G["GameTooltipText" .. side .. i]
            local text = fs and fs:GetText()
            if text and not PD.IsSecret(text) and not text:find("PlayerDossier/Media", 1, true) then
                local plain = StripCodes(text)
                plain = plain:gsub("^.-:%s*", "")        -- drop a "Leader: " label
                plain = plain:gsub("%s*%b()%s*$", "")    -- drop a trailing "(Horde)"
                plain = strtrim(plain)
                plain = plain:match("^([^%s%-]+)%-[^%s%-]+$") or plain   -- Name-Realm → Name
                local icon = marks[plain:lower()]
                local pos  = icon and text:find(plain, 1, true)
                if pos then
                    fs:SetText(text:sub(1, pos - 1) .. icon .. " " .. text:sub(pos))
                    break
                end
            end
        end
    end
end

-- Sorted list of the names in a name→realm table
local function SortedNames(tbl, skip)
    local names = {}
    for name in pairs(tbl) do
        if not (skip and skip[name]) then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

local function AddPlayerLine(name, realm, color)
    local dEntry = PD:GetEntry(name, realm)
    local line   = "  " .. PD:MoodIcon(dEntry and dEntry.mood) .. " |cff" .. color .. name .. "|r"
    if dEntry and dEntry.note and dEntry.note ~= "" then
        line = line .. " |cffaaaaaa– " .. dEntry.note .. "|r"
    end
    GameTooltip:AddLine(line, 1, 1, 1, true)
end

local function CheckAndWarnTooltip(frame)
    if not frame or not frame.resultID then return end
    local entry = CheckResult(frame.resultID)
    if not entry.hasIgnored and not entry.hasDossier then return end

    AnnotateMemberLines(entry)

    GameTooltip:AddLine(" ")

    if entry.hasIgnored then
        GameTooltip:AddLine("|cffff2e2e! " .. L["LFG_IGNORED_WARNING"] .. "|r")
        for _, name in ipairs(SortedNames(entry.ignored)) do
            AddPlayerLine(name, entry.ignored[name], "ff8888")
        end
    end

    -- Dossier players that aren't ignored
    local others = SortedNames(entry.dossier, entry.ignored)
    if #others > 0 then
        if entry.hasIgnored then GameTooltip:AddLine(" ") end
        GameTooltip:AddLine("|cff9B82F3PlayerDossier:|r")
        for _, name in ipairs(others) do
            AddPlayerLine(name, entry.dossier[name], "ffff88")
        end
    end

    GameTooltip:Show()
end

-- ================================================================
-- 3.  INLINE WARNING
--
-- Colors the group name red and prefixes a warning when the leader or a
-- member is ignored - no hover needed. Blizzard re-sets frame.Name on
-- every LFGListSearchEntry_Update and our secure hook runs afterwards,
-- so the prefix never doubles up and non-ignored rows need no reset.
-- ================================================================

local INLINE_WARN_PREFIX = "|cffff2e2e!|r "

local function ApplyInlineWarning(frame)
    if not frame or not frame.resultID or not frame.Name then return end
    if not PD:OPT_Get("lfgInlineWarning") then return end

    if CheckResult(frame.resultID).hasIgnored then
        frame.Name:SetText(INLINE_WARN_PREFIX .. (frame.Name:GetText() or ""))
        frame.Name:SetTextColor(1, 0.35, 0.35)
    end
end

-- ================================================================
-- 4.  HIDE GROUPS WITH IGNORED PLAYERS
--
-- frame:Hide() doesn't work here: the ScrollBox recycles frames and
-- calls Show() again, which makes hidden rows flicker back. Instead
-- we collapse the row (alpha 0, no mouse, height 0) after Blizzard
-- filled it in LFGListSearchEntry_SetResult.
-- ================================================================

local function SetEntryHidden(frame, hidden)
    frame:SetAlpha(hidden and 0 or 1)
    frame:EnableMouse(not hidden)
    if frame.SetHeight then frame:SetHeight(hidden and 0 or ENTRY_HEIGHT) end
end

local function OnSetResult(frame, resultID)
    if not PD:OPT_Get("lfgHideIgnored") then
        -- Option off: make sure a recycled frame is visible again
        frame:SetAlpha(1)
        frame:EnableMouse(true)
        return
    end
    if not resultID then return end
    SetEntryHidden(frame, CheckResult(resultID).hasIgnored)
end

-- Catches rows that were rendered before our hook saw them
local function FilterLFGResults()
    if not PD:OPT_Get("lfgHideIgnored") then return end
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    if not panel or not panel.ScrollBox then return end
    panel.ScrollBox:ForEachFrame(function(frame)
        if frame and frame.resultID then
            SetEntryHidden(frame, CheckResult(frame.resultID).hasIgnored)
        end
    end)
end

lfgFrame:SetScript("OnEvent", function(_, event)
    wipe(resultCache)
    nameIndex = nil
    if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" and PD:OPT_Get("lfgHideIgnored") then
        C_Timer.After(0.2, FilterLFGResults)
    end
end)

-- ================================================================
-- 5.  HOOKS
-- ================================================================

local hooked = {}

local function HookOnce(fnName, hook)
    if hooked[fnName] or not _G[fnName] then return end
    hooked[fnName] = true
    hooksecurefunc(fnName, hook)
end

-- Hooks everything that exists yet; called again when the frame is shown
-- in case Blizzard's LFG code loaded later.
local function InstallHooks()
    HookOnce("LFGListSearchEntry_OnEnter", function(frame)
        C_Timer.After(0.05, function()
            if GameTooltip:IsShown() then CheckAndWarnTooltip(frame) end
        end)
    end)
    HookOnce("LFGListSearchEntry_Update",    ApplyInlineWarning)
    HookOnce("LFGListSearchEntry_SetResult", OnSetResult)
end

-- Called from the BuildUI callback below
function PD:InitLFG()
    InstallHooks()

    if not hooked["LFGListSearchEntry_OnEnter"] then
        -- Fallback: recognize LFG rows via the tooltip's owner
        GameTooltip:HookScript("OnShow", function(tt)
            local owner = tt:GetOwner()
            if owner and owner.resultID then
                C_Timer.After(0.01, function()
                    if tt:IsShown() then CheckAndWarnTooltip(owner) end
                end)
            end
        end)
    end

    if LFGListFrame_Show then
        hooksecurefunc("LFGListFrame_Show", InstallHooks)
    end
end

PD:OnBuildUI(function() PD:InitLFG() end)

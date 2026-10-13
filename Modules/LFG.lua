-- ============================================================
--  PlayerDossier – LFG.lua
--  Premade Group Finder integration:
--    • tooltip: warning plus ignore reason / dossier note of known
--      players in the group
--    • "!IGNORED" / "!WARNING" (bad-mood dossier player) in the search result list
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- ================================================================
-- 1.  MEMBER CHECK (cached per search result)
-- ================================================================

-- resultID → { hasIgnored, hasDossier, hasBad (non-ignored member with a bad mood), ignored = {name→realm}, dossier = {name→realm} }
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

    local entry = { hasIgnored = false, hasDossier = false, hasBad = false, ignored = {}, dossier = {} }
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
            -- Ignored players already get the stronger ignore warning
            local dEntry = PD:GetEntry(name, dosRealm)
            if not ignRealm and dEntry and dEntry.mood == "negative" then
                entry.hasBad = true
            end
        end
    end

    CheckMember(info.leaderName)

    -- GetNumSearchResultMembers / GetSearchResultMemberInfo no longer exist;
    -- the live API is info.numMembers + GetSearchResultPlayerInfo (name is nilable)
    local numMembers = info.numMembers
    if PD.IsSecret(numMembers) then numMembers = 0 end   -- a secret number can't drive a loop
    for i = 1, numMembers or 0 do
        local okM, member = pcall(C_LFGList.GetSearchResultPlayerInfo, resultID, i)
        if okM and member then CheckMember(member.name) end
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

-- Sorted list of the names in a name→realm table
local function SortedNames(tbl, skip)
    local names = {}
    for name in pairs(tbl) do
        if not (skip and skip[name]) then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

-- "  Name – note"
local function AddPlayerLine(name, note, color)
    local line = "  |cff" .. color .. name .. "|r"
    if note and note ~= "" then
        line = line .. " |cffaaaaaa– " .. note .. "|r"
    end
    GameTooltip:AddLine(line, 1, 1, 1, true)
end

local function CheckAndWarnTooltip(frame)
    if not frame or not frame.resultID then return end
    local entry = CheckResult(frame.resultID)
    if not entry.hasIgnored and not entry.hasDossier then return end

    GameTooltip:AddLine(" ")

    -- Ignored players: show the ignore list reason
    if entry.hasIgnored then
        GameTooltip:AddLine("|cffff2e2e! " .. L["LFG_IGNORED_WARNING"] .. "|r")
        for _, name in ipairs(SortedNames(entry.ignored)) do
            local ignored = PD:IL_GetAll()[PD:GetKey(name, entry.ignored[name])]
            AddPlayerLine(name, ignored and ignored.reason, "ff8888")
        end
    end

    -- Dossier players that aren't ignored: show the dossier note
    local others = SortedNames(entry.dossier, entry.ignored)
    if #others > 0 then
        if entry.hasIgnored then GameTooltip:AddLine(" ") end
        if entry.hasBad then
            GameTooltip:AddLine("|cffff8800! " .. L["LFG_BAD_WARNING"] .. "|r")
        else
            GameTooltip:AddLine("|cff9B82F3PlayerDossier:|r")
        end
        for _, name in ipairs(others) do
            local dEntry = PD:GetEntry(name, entry.dossier[name])
            local bad    = dEntry and dEntry.mood == "negative"
            AddPlayerLine(name, dEntry and dEntry.note, bad and "ffaa44" or "ffff88")
        end
    end

    GameTooltip:Show()
end

-- ================================================================
-- 3.  INLINE WARNING
--
-- Colors the group name red and prefixes "!IGNORED" when the leader or a
-- member is ignored - no hover needed. Blizzard re-sets frame.Name on
-- every LFGListSearchEntry_Update and our secure hook runs afterwards,
-- so the prefix never doubles up and non-ignored rows need no reset.
-- ================================================================

local function ApplyInlineWarning(frame)
    if not frame or not frame.resultID or not frame.Name then return end
    if not PD:OPT_Get("lfgInlineWarning") then return end

    local entry = CheckResult(frame.resultID)
    if not entry.hasIgnored and not entry.hasBad then return end

    -- Blizzard fills Name from the (possibly secret) search result name;
    -- a secret string can't be concatenated, so leave such rows alone.
    local text = frame.Name:GetText()
    if PD.IsSecret(text) then return end

    if entry.hasIgnored then
        frame.Name:SetText("|cffff2e2e!" .. L["LFG_INLINE_IGNORED"] .. "|r " .. (text or ""))
        frame.Name:SetTextColor(1, 0.35, 0.35)
    else
        frame.Name:SetText("|cffff8800!" .. L["LFG_INLINE_BAD"] .. "|r " .. (text or ""))
        frame.Name:SetTextColor(1, 0.6, 0.2)
    end

    -- LFGListSearchEntry_Update capped Name at 176px (165 for applications,
    -- minus 22 with the voice chat icon) before our prefix made it longer.
    local maxW = (frame.isApplication and 165 or 176) - (frame.VoiceChat and frame.VoiceChat:IsShown() and 22 or 0)
    if frame.Name:GetWidth() > maxW then frame.Name:SetWidth(maxW) end
end

lfgFrame:SetScript("OnEvent", function()
    wipe(resultCache)
    nameIndex = nil
end)

-- ================================================================
-- 4.  HOOKS
-- ================================================================

-- Blizzard builds the tooltip in LFGListSearchEntry_OnEnter; our lines go on
-- one frame later. Several triggers in the same frame add them only once.
local tipPending = {}

local function ScheduleTooltip(frame)
    if tipPending[frame] then return end
    tipPending[frame] = true
    RunNextFrame(function()
        tipPending[frame] = nil
        if GameTooltip:IsShown() and GameTooltip:GetOwner() == frame then
            CheckAndWarnTooltip(frame)
        end
    end)
end

local hookedRows = setmetatable({}, { __mode = "k" })

-- Post-hook of LFGListSearchEntry_Update (runs for every row whenever Blizzard
-- fills it). The XML binds LFGListSearchEntry_OnEnter by value, so hooking the
-- global would miss real mouse-overs; each row gets a HookScript instead.
local function OnRowUpdate(frame)
    if not hookedRows[frame] then
        hookedRows[frame] = true
        frame:HookScript("OnEnter", ScheduleTooltip)
    end
    ApplyInlineWarning(frame)

    -- While hovered, Update calls OnEnter by its global name and rebuilds the
    -- tooltip without our lines
    if GameTooltip:GetOwner() == frame then ScheduleTooltip(frame) end
end

-- Called from the BuildUI callback below. Blizzard_GroupFinder is not
-- load-on-demand, so the function exists by now. hooksecurefunc/HookScript
-- are post-hooks: they run after Blizzard's code and can't taint it.
local lfgHooked = false

function PD:InitLFG()
    if lfgHooked or not LFGListSearchEntry_Update then return end
    lfgHooked = true
    hooksecurefunc("LFGListSearchEntry_Update", OnRowUpdate)
end

PD:OnBuildUI(function() PD:InitLFG() end)

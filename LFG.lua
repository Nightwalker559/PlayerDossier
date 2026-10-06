-- ============================================================
--  PlayerDossier – LFG.lua
--  Premade Group Finder integration:
--    • tooltip: warning plus ignore reason / dossier note of known
--      players in the group
--    • "!IGNORED" warning in the search result list
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

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
        GameTooltip:AddLine("|cff9B82F3PlayerDossier:|r")
        for _, name in ipairs(others) do
            local dEntry = PD:GetEntry(name, entry.dossier[name])
            AddPlayerLine(name, dEntry and dEntry.note, "ffff88")
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

    if CheckResult(frame.resultID).hasIgnored then
        frame.Name:SetText("|cffff2e2e!" .. L["LFG_INLINE_IGNORED"] .. "|r " .. (frame.Name:GetText() or ""))
        frame.Name:SetTextColor(1, 0.35, 0.35)
    end
end

lfgFrame:SetScript("OnEvent", function()
    wipe(resultCache)
    nameIndex = nil
end)

-- ================================================================
-- 4.  HOOKS
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
    HookOnce("LFGListSearchEntry_Update", ApplyInlineWarning)
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

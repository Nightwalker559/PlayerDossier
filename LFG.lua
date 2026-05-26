-- ============================================================
--  PlayerDossier – LFG.lua
--  Warnt im LFG-Tooltip wenn ein ignorierter Spieler in der
--  Gruppe ist. Optional: Gruppen mit ignorierten Spielern
--  aus den Suchergebnissen ausblenden.
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- Cache: resultID → { ignored={name→realm}, dossier={name→realm} }
local lfgIgnoreCache = {}

-- ----------------------------------------------------------------
-- Hilfsfunktion: Alle Mitglieder eines LFG-Eintrags prüfen
-- ----------------------------------------------------------------
local function CheckResult(resultID)
    if lfgIgnoreCache[resultID] then return lfgIgnoreCache[resultID] end

    local entry = {
        hasIgnored  = false,
        hasDossier  = false,
        ignored     = {},   -- name → realm
        dossier     = {},   -- name → realm
    }

    local ok, info = pcall(C_LFGList.GetSearchResultInfo, resultID)
    if not ok or not info then
        lfgIgnoreCache[resultID] = entry
        return entry
    end

    local function CheckMember(mName)
        if not mName then return end
        local name, realm = mName:match("^(.+)-(.+)$")
        name  = name  or mName
        realm = realm or PD.GetMyRealm()

        if PD:IL_IsIgnored(name, realm) and not entry.ignored[name] then
            entry.hasIgnored      = true
            entry.ignored[name]   = realm
        end

        if PD:GetEntry(name, realm) and not entry.dossier[name] then
            entry.hasDossier      = true
            entry.dossier[name]   = realm
        end
    end

    -- Leader prüfen
    CheckMember(info.leaderName)

    -- Alle Mitglieder prüfen
    local okNum, numMembers = pcall(C_LFGList.GetNumSearchResultMembers, resultID)
    if okNum and numMembers then
        for i = 1, numMembers do
            local okM, mName = pcall(function()
                return C_LFGList.GetSearchResultMemberInfo(resultID, i)
            end)
            if okM and mName then CheckMember(mName) end
        end
    end

    lfgIgnoreCache[resultID] = entry
    return entry
end

-- ----------------------------------------------------------------
-- Cache leeren bei neuer Suche
-- ----------------------------------------------------------------
local lfgFrame = CreateFrame("Frame", "PDLFGEvents")
lfgFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
lfgFrame:RegisterEvent("LFG_LIST_SEARCH_FAILED")
lfgFrame:SetScript("OnEvent", function(_, event)
    if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED"
    or event == "LFG_LIST_SEARCH_FAILED" then
        wipe(lfgIgnoreCache)
    end
end)

-- ----------------------------------------------------------------
-- Tooltip-Hook: Warnung in LFG-Gruppentooltip einblenden
-- ----------------------------------------------------------------
local function HookLFGTooltip()
    -- LFGListSearchEntry_OnEnter ist die Funktion die den Tooltip befüllt
    -- Wir hooken sie um unsere Warnung anzuhängen
    local function CheckAndWarnTooltip(frame)
        if not frame or not frame.resultID then return end
        local entry = CheckResult(frame.resultID)
        if not entry.hasIgnored and not entry.hasDossier then return end

        local function AddPlayerLine(name, realm)
            local dEntry  = PD:GetEntry(name, realm)
            local mood    = dEntry and dEntry.mood or "neutral"
            local moodTex = string.format(
                "|TInterface/AddOns/PlayerDossier/Media/mood_%s.png:16:16|t", mood)
            local line    = "  " .. moodTex .. " |cffffff88" .. name .. "|r"
            if dEntry and dEntry.note and dEntry.note ~= "" then
                line = line .. " |cffaaaaaa– " .. dEntry.note .. "|r"
            end
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end

        GameTooltip:AddLine(" ")

        -- Ignorierte Spieler
        if entry.hasIgnored then
            GameTooltip:AddLine("|cffff2e2e⚠ " .. L["LFG_IGNORED_WARNING"] .. "|r")
            for name, realm in pairs(entry.ignored) do
                local dEntry  = PD:GetEntry(name, realm)
                local mood    = dEntry and dEntry.mood or "neutral"
                local moodTex = string.format(
                    "|TInterface/AddOns/PlayerDossier/Media/mood_%s.png:16:16|t", mood)
                local line    = "  " .. moodTex .. " |cffff8888" .. name .. "|r"
                if dEntry and dEntry.note and dEntry.note ~= "" then
                    line = line .. " |cffaaaaaa– " .. dEntry.note .. "|r"
                end
                GameTooltip:AddLine(line, 1, 1, 1, true)
            end
        end

        -- Spieler aus dem Dossier (die nicht ignoriert sind)
        local hasDossierOnly = false
        for name, realm in pairs(entry.dossier) do
            if not entry.ignored[name] then
                hasDossierOnly = true
                break
            end
        end
        if hasDossierOnly then
            if entry.hasIgnored then GameTooltip:AddLine(" ") end
            GameTooltip:AddLine("|cff9B82F3PlayerDossier:|r")
            for name, realm in pairs(entry.dossier) do
                if not entry.ignored[name] then
                    AddPlayerLine(name, realm)
                end
            end
        end

        GameTooltip:Show()
    end

    -- Hook über hooksecurefunc auf den Tooltip-Build
    if LFGListSearchEntry_OnEnter then
        hooksecurefunc("LFGListSearchEntry_OnEnter", function(frame)
            C_Timer.After(0.05, function()
                if GameTooltip:IsShown() then
                    CheckAndWarnTooltip(frame)
                end
            end)
        end)
    else
        -- Fallback: GameTooltip OnShow Hook für LFG-Frames
        GameTooltip:HookScript("OnShow", function(tt)
            local owner = tt:GetOwner()
            if owner and owner.resultID then
                C_Timer.After(0.01, function()
                    if tt:IsShown() then
                        CheckAndWarnTooltip(owner)
                    end
                end)
            end
        end)
    end
end

-- ----------------------------------------------------------------
-- LFG-Einträge mit ignorierten Spielern aus den Ergebnissen
-- ausblenden (wenn Option aktiviert)
-- ----------------------------------------------------------------
local function FilterLFGResults()
    if not PD:OPT_Get("lfgHideIgnored") then return end
    if not LFGListFrame or not LFGListFrame.SearchPanel then return end

    local panel = LFGListFrame.SearchPanel
    if not panel.ScrollBox then return end

    -- Scroll-Einträge iterieren und verstecken wenn ignoriert
    panel.ScrollBox:ForEachFrame(function(frame)
        if frame and frame.resultID then
            local entry = CheckResult(frame.resultID)
            if entry.hasIgnored then
                frame:Hide()
            end
        end
    end)
end

-- Hook auf LFG-Suchergebnisse für Filter
local function OnSearchResults()
    if PD:OPT_Get("lfgHideIgnored") then
        C_Timer.After(0.1, FilterLFGResults)
    end
end

hooksecurefunc(C_LFGList, "GetSearchResults", function()
    -- Wird aufgerufen wenn die UI die Ergebnisse verarbeitet
end)

lfgFrame:HookScript("OnEvent", function(_, event)
    if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        OnSearchResults()
    end
end)

-- ----------------------------------------------------------------
-- Init (wird von Events.lua's BuildUI-Hook aufgerufen)
-- ----------------------------------------------------------------
function PD:InitLFG()
    HookLFGTooltip()
end

-- Hook in BuildUI
local origBuildUI = PD.BuildUI
PD.BuildUI = function(self)
    if origBuildUI then origBuildUI(self) end
    PD:InitLFG()
end

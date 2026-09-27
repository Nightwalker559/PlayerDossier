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
        local name, realm = mName:match("^(.+)-([^%-]+)$")
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
            local moodFile = (mood == "positive") and "mood_good" or (mood == "negative") and "mood_bad" or "mood_neutral"
            local moodTex = string.format(
                "|TInterface/AddOns/PlayerDossier/Media/%s.png:16:16|t", moodFile)
            local line    = "  " .. moodTex .. " |cffffff88" .. name .. "|r"
            if dEntry and dEntry.note and dEntry.note ~= "" then
                line = line .. " |cffaaaaaa– " .. dEntry.note .. "|r"
            end
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end

        GameTooltip:AddLine(" ")

        -- Ignorierte Spieler
        if entry.hasIgnored then
            GameTooltip:AddLine("|cffff2e2e! " .. L["LFG_IGNORED_WARNING"] .. "|r")
            for name, realm in pairs(entry.ignored) do
                local dEntry  = PD:GetEntry(name, realm)
                local mood    = dEntry and dEntry.mood or "neutral"
                local moodFile = (mood == "positive") and "mood_good" or (mood == "negative") and "mood_bad" or "mood_neutral"
                local moodTex = string.format(
                    "|TInterface/AddOns/PlayerDossier/Media/%s.png:16:16|t", moodFile)
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
-- Inline-Warnung: Gruppenname direkt in der Ergebnis-Zeile rot
-- einfärben + Warnsymbol voranstellen, wenn Leader/Mitglied
-- ignoriert ist. Kein Hover noetig (im Gegensatz zum Tooltip oben).
--
-- Blizzard setzt frame.Name bei JEDEM LFGListSearchEntry_Update-
-- Aufruf frisch (SetText), unser hooksecurefunc laeuft danach ->
-- kein Doppel-Praefix bei wiederholten Aufrufen, kein manuelles
-- Zuruecksetzen fuer nicht-ignorierte Zeilen noetig.
-- ----------------------------------------------------------------
local INLINE_WARN_PREFIX = "|cffff2e2e!|r "

local function ApplyInlineWarning(frame)
    if not frame or not frame.resultID or not frame.Name then return end
    if not PD:OPT_Get("lfgInlineWarning") then return end

    local entry = CheckResult(frame.resultID)
    if entry.hasIgnored then
        local name = frame.Name:GetText() or ""
        frame.Name:SetText(INLINE_WARN_PREFIX .. name)
        frame.Name:SetTextColor(1, 0.35, 0.35)
    end
end

local lfgInlineHooked = false
local function HookLFGInlineWarning()
    if lfgInlineHooked then return end
    if not LFGListSearchEntry_Update then return end
    lfgInlineHooked = true
    hooksecurefunc("LFGListSearchEntry_Update", ApplyInlineWarning)
end

-- ----------------------------------------------------------------
-- LFG-Einträge mit ignorierten Spielern ausblenden
--
-- PROBLEM mit frame:Hide() in ForEachFrame:
--   WoW's ScrollBox recycelt Frames beim Scrollen/Update und ruft
--   intern Show() auf → unser Hide() wird sofort ueberschrieben (Flackern).
--
-- LOESUNG: Hook auf LFGListSearchEntry_SetResult – diese Funktion
--   wird aufgerufen NACHDEM ein Frame mit Ergebnis-Daten befuellt wurde.
--   Hier greifen wir sicher ein ohne den ScrollBox-Lifecycle zu stoeren.
-- ----------------------------------------------------------------

local lfgFilterHooked = false

local function HookLFGEntrySetResult()
    if lfgFilterHooked then return end
    if not LFGListSearchEntry_SetResult then return end
    lfgFilterHooked = true

    hooksecurefunc("LFGListSearchEntry_SetResult", function(frame, resultID)
        if not PD:OPT_Get("lfgHideIgnored") then
            -- Option deaktiviert: sicherstellen dass alles sichtbar ist
            frame:SetAlpha(1)
            frame:EnableMouse(true)
            return
        end
        if not resultID then return end

        local entry = CheckResult(resultID)
        if entry.hasIgnored then
            -- SetAlpha+Height statt Hide(): ScrollBox-Lifecycle bleibt intakt
            frame:SetAlpha(0)
            frame:EnableMouse(false)
            if frame.SetHeight then frame:SetHeight(0) end
        else
            -- Recycelter Frame koennte zuvor gefiltert gewesen sein → zuruecksetzen
            frame:SetAlpha(1)
            frame:EnableMouse(true)
            if frame.SetHeight then frame:SetHeight(52) end
        end
    end)
end

-- Fallback-Durchlauf nach Suchergebnissen fuer bereits gerenderte Frames
local function FilterLFGResults()
    if not PD:OPT_Get("lfgHideIgnored") then return end
    if not LFGListFrame or not LFGListFrame.SearchPanel then return end
    local panel = LFGListFrame.SearchPanel
    if not panel.ScrollBox then return end
    panel.ScrollBox:ForEachFrame(function(frame)
        if not frame or not frame.resultID then return end
        local entry = CheckResult(frame.resultID)
        if entry.hasIgnored then
            frame:SetAlpha(0)
            frame:EnableMouse(false)
            if frame.SetHeight then frame:SetHeight(0) end
        else
            frame:SetAlpha(1)
            frame:EnableMouse(true)
        end
    end)
end

-- ScrollBox-Hook: SetResult-Hook registrieren sobald ScrollBox existiert
local function HookLFGScrollBox()
    if not LFGListFrame or not LFGListFrame.SearchPanel then return end
    local sb = LFGListFrame.SearchPanel.ScrollBox
    if sb and not sb._pdHooked then
        sb._pdHooked = true
        HookLFGEntrySetResult()
        HookLFGInlineWarning()
    end
end

-- Nach Suchergebnissen: Fallback-Durchlauf fuer bereits gerenderte Frames
local function OnSearchResults()
    if not PD:OPT_Get("lfgHideIgnored") then return end
    C_Timer.After(0.2, FilterLFGResults)
end

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
    -- SetResult-Hook so frueh wie moeglich registrieren
    HookLFGEntrySetResult()
    HookLFGInlineWarning()
    -- LFGListFrame existiert erst wenn es geoeffnet wird
    if LFGListFrame then
        HookLFGScrollBox()
    else
        hooksecurefunc("LFGListFrame_Show", function()
            HookLFGScrollBox()
        end)
    end
end

-- Hook in BuildUI
local origBuildUI = PD.BuildUI
PD.BuildUI = function(self)
    if origBuildUI then origBuildUI(self) end
    PD:InitLFG()
end

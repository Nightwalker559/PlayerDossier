-- ============================================================
--  PlayerDossier – ElvUI_Skin.lua
--  Registriert PlayerDossier bei ElvUI's Skin-System.
--  Läuft nur wenn ElvUI geladen ist.
-- ============================================================

-- Sicherer Check: IsAddOnLoaded kann nil sein, unpack(ElvUI) crasht ohne ElvUI
if not ElvUI then return end

local ok, E = pcall(function() return unpack(ElvUI) end)
if not ok or not E then return end

local S = E:GetModule("Skins")
if not S or not S.AddCallbackForAddon then return end
local PD = PlayerDossier

-- ----------------------------------------------------------------
-- Helper: entfernt Blizzard-Backdrop und setzt ElvUI-Template
-- ----------------------------------------------------------------
local function SkinFrame(frame, template)
    if not frame then return end
    frame:StripTextures()
    frame:SetTemplate(template or "Transparent")
end

-- ----------------------------------------------------------------
-- Tabs linksbündig mit ~1px sichtbarem Abstand.
--
-- ElvUI's S:HandleTab zieht das sichtbare Backdrop mit einem festen
-- Inset nach innen (3px auf Retail, 10px auf älteren Clients) statt
-- es an die Frame-Kanten zu setzen. Ein reiner Anker-Abstand von 1px
-- zwischen den Tab-Frames erzeugt dadurch eine 2×Inset breite Lücke
-- zwischen den sichtbaren Backdrops. Der Anker-Offset muss diesen
-- Inset daher kompensieren (negativ), damit am Ende ~1px sichtbar
-- übrig bleibt. Gleiches Prinzip wie in ElvUI-Addon-Skins üblich
-- (z. B. LuckyoneUI's Auctionator-Skin).
-- ----------------------------------------------------------------
local TAB_START_X = 4

local function TabGapOffset()
    -- Bestätigt korrekt für dieses ElvUI-Skin (E.Modern lieferte bei
    -- manchen ElvUI-Versionen falsch/nil -> Fallback auf -19 war der Bug)
    return -5
end

local function ReflowTabs(mainFrame)
    if not mainFrame then return end
    local gap = TabGapOffset()
    local prevTab
    for i = 1, 4 do
        local tab = _G["PDMainTab" .. i]
        if tab then
            tab:ClearAllPoints()
            if prevTab then
                tab:SetPoint("LEFT", prevTab, "RIGHT", gap, 0)
            else
                tab:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", TAB_START_X, -28)
            end
            prevTab = tab
        end
    end
end

-- ----------------------------------------------------------------
-- Haupt-Skin-Funktion
-- Wird von ElvUI aufgerufen sobald PlayerDossier fertig geladen ist
-- ----------------------------------------------------------------
local function LoadSkin()
    -- Frames sind erst nach ADDON_LOADED bereit.
    -- PD:BuildUI() wird von Events.lua aufgerufen.
    -- Wir hooken uns in den Show-Event des Hauptfensters.

    -- ── Hauptfenster ───────────────────────────────────────────
    local f = _G["PDMainFrame"]
    if f then
        f:HookScript("OnShow", function(self)
            if self.ElvUISkinned then return end
            self.ElvUISkinned = true

            -- Hauptfenster
            SkinFrame(self)
            S:HandleCloseButton(self.CloseButton)

            -- TitleBg (falls vorhanden)
            if self.TitleBg then self.TitleBg:StripTextures() end

            -- InsetBg
            if self.InsetBg then self.InsetBg:StripTextures() end

            -- Tabs – UI.lua setzt bereits die korrekte Breite
            -- Im ElvUI-Skin werden die Tabs zusätzlich linksbündig mit
            -- 1px Abstand neu positioniert (Blizzard-Look bleibt unverändert)
            for i = 1, 4 do
                local tab = _G["PDMainTab"..i]
                if tab then S:HandleTab(tab) end
            end
            C_Timer.After(0, function() ReflowTabs(self) end)

            -- ScrollFrame im Players-Panel
            local sf = _G["PDScrollFrame"]
            if sf and sf.ScrollBar then
                S:HandleScrollBar(sf.ScrollBar)
            end

            -- "Alle entfernen"-Button Players
            local clearP = _G["PDClearPlayersBtn"]
            if clearP then S:HandleButton(clearP) end

            -- ScrollFrame im Ignorier-Listen-Panel
            local ilsf = _G["PDILScrollFrame"]
            if ilsf and ilsf.ScrollBar then
                S:HandleScrollBar(ilsf.ScrollBar)
            end

            -- "Alle entfernen"-Button Ignore
            local clearI = _G["PDClearIgnoreBtn"]
            if clearI then S:HandleButton(clearI) end

            -- ScrollFrame im Optionen-Panel
            local optsf = _G["PDOptScrollFrame"]
            if optsf and optsf.ScrollBar then
                S:HandleScrollBar(optsf.ScrollBar)
            end

            -- ScrollFrame im Verlauf-Panel
            local hsf = _G["PDHistScrollFrame"]
            if hsf and hsf.ScrollBar then
                S:HandleScrollBar(hsf.ScrollBar)
            end

            -- "Alle entfernen"-Button Verlauf
            local clearH = _G["PDClearHistoryBtn"]
            if clearH then S:HandleButton(clearH) end
        end)
    end

    -- ── Note-Dialog ────────────────────────────────────────────
    local nd = _G["PDNoteDialog"]
    if nd then
        nd:HookScript("OnShow", function(self)
            if self.ElvUISkinned then return end
            self.ElvUISkinned = true

            SkinFrame(self)
            S:HandleCloseButton(self.CloseButton)

            -- EditBox
            local eb = _G["PDNoteEditBox"]
            if eb then S:HandleEditBox(eb) end

            -- Mood-Buttons + Save/Cancel
            for _, child in ipairs({self:GetChildren()}) do
                if child.GetObjectType and child:GetObjectType() == "Button" then
                    if child ~= self.CloseButton then
                        S:HandleButton(child)
                    end
                end
            end
        end)
    end

    -- ── Copy-Popup (lazy erstellt – Hook auf ShowCopyPopup) ────
    hooksecurefunc(PD, "ShowCopyPopup", function()
        local cp = _G["PDCopyPopup"]
        if not cp or cp.ElvUISkinned then return end
        cp.ElvUISkinned = true
        pcall(function()
            SkinFrame(cp)
            if cp.CloseButton then S:HandleCloseButton(cp.CloseButton) end
            if cp.editBox     then S:HandleEditBox(cp.editBox)         end
        end)
    end)

    -- ── Minimap-Button (LibDBIcon) ─────────────────────────────
    local function SkinMinimapBtn()
        local mmBtn = _G["LibDBIcon10_PlayerDossier"]
        if not mmBtn or mmBtn._pdSkinned then return end
        mmBtn._pdSkinned = true

        pcall(function()
            if mmBtn.SetBackdrop then mmBtn:SetBackdrop(nil) end
            if mmBtn.border     then mmBtn.border:Hide()     end
            if mmBtn.background then mmBtn.background:Hide() end
            if mmBtn.icon then
                mmBtn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
            end
            for _, region in ipairs({mmBtn:GetRegions()}) do
                if region:GetObjectType() == "Texture" and region ~= mmBtn.icon then
                    region:SetTexture(nil)
                end
            end
        end)
    end

    -- Sofort versuchen, falls Button bereits existiert
    SkinMinimapBtn()
    -- Fallback: nach kurzem Delay wenn LibDBIcon noch nicht registriert hat
    C_Timer.After(1, SkinMinimapBtn)

    -- ── Hook für dynamisch erstellte Popup-Dialoge ─────────────
    local function SkinStaticPopup(dialog, which)
        if not which or not which:find("^PD_") then return end
        if dialog.ElvUISkinned then return end
        dialog.ElvUISkinned = true

        SkinFrame(dialog)
        if dialog.CloseButton  then S:HandleCloseButton(dialog.CloseButton) end
        if dialog.EditBox       then S:HandleEditBox(dialog.EditBox) end
        if dialog.Button1       then S:HandleButton(dialog.Button1) end
        if dialog.Button2       then S:HandleButton(dialog.Button2) end
        if dialog.ExtraButton   then S:HandleButton(dialog.ExtraButton) end
    end

    hooksecurefunc("StaticPopup_Show", function(which, ...)
        for i = 1, 4 do
            local d = _G["StaticPopup"..i]
            if d and d:IsShown() and d.which == which then
                SkinStaticPopup(d, which)
            end
        end
    end)
end

-- ----------------------------------------------------------------
-- Hook SelectTab um Panels nach dem Lazy-Build zu skinnen
-- ----------------------------------------------------------------
local origSelectTab = PD.SelectTab
PD.SelectTab = function(self, n)
    origSelectTab(self, n)
    -- Tabs erneut linksbündig ausrichten (falls PanelTemplates_SetTab
    -- o.ä. die Anker zwischenzeitlich zurückgesetzt hat)
    ReflowTabs(PD.mainFrame)
    -- Nach Tab-Wechsel frisch gebaute Panels skinnen
    C_Timer.After(0, function()
        if n == 2 then  -- Ignorier-Liste
            local ilsf = _G["PDILScrollFrame"]
            if ilsf and ilsf.ScrollBar and not ilsf._ElvUISkinned then
                ilsf._ElvUISkinned = true
                S:HandleScrollBar(ilsf.ScrollBar)
            end
            local clearI = _G["PDClearIgnoreBtn"]
            if clearI and not clearI._ElvUISkinned then
                clearI._ElvUISkinned = true
                S:HandleButton(clearI)
            end
        elseif n == 1 then  -- Spieler
            local sf = _G["PDScrollFrame"]
            if sf and sf.ScrollBar and not sf._ElvUISkinned then
                sf._ElvUISkinned = true
                S:HandleScrollBar(sf.ScrollBar)
            end
            local clearP = _G["PDClearPlayersBtn"]
            if clearP and not clearP._ElvUISkinned then
                clearP._ElvUISkinned = true
                S:HandleButton(clearP)
            end
        elseif n == 3 then  -- Verlauf
            local hsf = _G["PDHistScrollFrame"]
            if hsf and hsf.ScrollBar and not hsf._ElvUISkinned then
                hsf._ElvUISkinned = true
                S:HandleScrollBar(hsf.ScrollBar)
            end
            local clearH = _G["PDClearHistoryBtn"]
            if clearH and not clearH._ElvUISkinned then
                clearH._ElvUISkinned = true
                S:HandleButton(clearH)
            end
        elseif n == 4 then  -- Optionen
            local optsf = _G["PDOptScrollFrame"]
            if optsf and optsf.ScrollBar and not optsf._ElvUISkinned then
                optsf._ElvUISkinned = true
                S:HandleScrollBar(optsf.ScrollBar)
            end
            local importBtn = _G["PDImportIgnoreBtn"]
            if importBtn and not importBtn._ElvUISkinned then
                importBtn._ElvUISkinned = true
                S:HandleButton(importBtn)
            end
            -- Alle Optionen-Checkboxen ins ElvUI-Quadrat-Design bringen
            local cbs = PD.panel4 and PD.panel4._optCbs
            if cbs then
                for _, cb in pairs(cbs) do
                    if cb and not cb._ElvUISkinned then
                        cb._ElvUISkinned = true
                        S:HandleCheckBox(cb)
                    end
                end
            end
        end
    end)
end

-- ----------------------------------------------------------------
-- Bei ElvUI registrieren
-- ----------------------------------------------------------------
S:AddCallbackForAddon("PlayerDossier", "PlayerDossier", LoadSkin)
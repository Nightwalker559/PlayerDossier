-- ============================================================
--  PlayerDossier – ElvUI_Skin.lua
--  Registers PlayerDossier with ElvUI's skin system.
--  Only does anything when ElvUI is loaded.
-- ============================================================

-- unpack(ElvUI) would error without ElvUI
if not ElvUI then return end

local ok, E = pcall(function() return unpack(ElvUI) end)
if not ok or not E then return end

local S = E:GetModule("Skins")
if not S or not S.AddCallbackForAddon then return end

local PD = PlayerDossier

-- Runs fn(obj) once per object
local function SkinOnce(obj, fn)
    if not obj or obj._ElvUISkinned then return end
    obj._ElvUISkinned = true
    fn(obj)
end

-- Removes the Blizzard backdrop and applies ElvUI's template
local function SkinFrame(frame, template)
    frame:StripTextures()
    frame:SetTemplate(template or "Transparent")
end

local function SkinScrollFrame(sf)
    if sf and sf.ScrollBar then
        SkinOnce(sf, function() S:HandleScrollBar(sf.ScrollBar) end)
    end
end

local function SkinButton(btn)
    SkinOnce(btn, function() S:HandleButton(btn) end)
end

-- ----------------------------------------------------------------
-- Tabs: left-aligned with ~1px of visible gap.
--
-- ElvUI's S:HandleTab pulls the visible backdrop inwards by a fixed
-- inset (3px on retail) instead of anchoring it to the frame edges.
-- A plain 1px anchor gap between tab frames therefore yields a gap of
-- 2×inset between the visible backdrops. The anchor offset has to
-- compensate (negative) to leave ~1px visible, the same approach
-- ElvUI addon skins commonly use. -5 is confirmed correct for this
-- skin (E.Modern returned wrong/nil on some ElvUI versions, which
-- made a -19 fallback the original bug).
-- ----------------------------------------------------------------
local TAB_START_X = 4
local TAB_GAP     = -5
local NUM_TABS    = 4

local function ReflowTabs(mainFrame)
    if not mainFrame then return end
    local prevTab
    for i = 1, NUM_TABS do
        local tab = _G["PDMainTab" .. i]
        if tab then
            tab:ClearAllPoints()
            if prevTab then
                tab:SetPoint("LEFT", prevTab, "RIGHT", TAB_GAP, 0)
            else
                tab:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", TAB_START_X, -28)
            end
            prevTab = tab
        end
    end
end

-- ----------------------------------------------------------------
-- Tab content: panels are built lazily, so each one is skinned
-- the first time its tab is selected.
-- ----------------------------------------------------------------
local TAB_WIDGETS = {
    [1] = { scroll = "PDScrollFrame",     button = "PDClearPlayersBtn" },
    [2] = { scroll = "PDILScrollFrame",   button = "PDClearIgnoreBtn" },
    [3] = { scroll = "PDHistScrollFrame", button = "PDClearHistoryBtn" },
    [4] = { scroll = "PDOptScrollFrame",  button = "PDImportIgnoreBtn", checkboxes = true },
}

local function SkinTabContent(n)
    local w = TAB_WIDGETS[n]
    if not w then return end
    SkinScrollFrame(_G[w.scroll])
    SkinButton(_G[w.button])

    if w.checkboxes and PD.panel4 and PD.panel4._optCbs then
        for _, cb in pairs(PD.panel4._optCbs) do
            SkinOnce(cb, function() S:HandleCheckBox(cb) end)
        end
    end
end

-- ----------------------------------------------------------------
-- Main skin function. ElvUI calls it once PlayerDossier is loaded
-- (the frames exist by then: PD:BuildUI runs from ADDON_LOADED).
-- ----------------------------------------------------------------
local function LoadSkin()
    -- ── Sort arrows: ElvUI's own arrow in the accent color ──────
    local arrowTex = E.Media and E.Media.Textures and E.Media.Textures.ArrowUp
    if arrowTex then
        PD.StyleSortArrow = function(arrow, asc)
            arrow:SetTexture(arrowTex)
            arrow:SetTexCoord(0, 1, 0, 1)
            arrow:SetSize(12, 12)
            arrow:SetRotation(asc and 0 or math.pi)
            local c = E.media and E.media.rgbvaluecolor
            if c then arrow:SetVertexColor(c[1], c[2], c[3]) else arrow:SetVertexColor(1, 1, 1) end
        end
        PD:RestyleSortArrows()
    end

    -- ── Main window ─────────────────────────────────────────────
    local f = _G["PDMainFrame"]
    if f then
        f:HookScript("OnShow", function(self)
            SkinOnce(self, function()
                SkinFrame(self)
                S:HandleCloseButton(self.CloseButton)
                if self.TitleBg then self.TitleBg:StripTextures() end
                if self.InsetBg then self.InsetBg:StripTextures() end

                -- UI.lua already sets the correct tab width; here the tabs
                -- are additionally re-laid-out left-aligned
                for i = 1, NUM_TABS do
                    local tab = _G["PDMainTab" .. i]
                    if tab then S:HandleTab(tab) end
                end
                C_Timer.After(0, function() ReflowTabs(self) end)
            end)
        end)
    end

    -- ── Note dialog ─────────────────────────────────────────────
    local nd = _G["PDNoteDialog"]
    if nd then
        nd:HookScript("OnShow", function(self)
            SkinOnce(self, function()
                SkinFrame(self)
                S:HandleCloseButton(self.CloseButton)

                local eb = _G["PDNoteEditBox"]
                if eb then S:HandleEditBox(eb) end

                -- Mood buttons + Save/Cancel
                for _, child in ipairs({ self:GetChildren() }) do
                    if child ~= self.CloseButton and child.GetObjectType
                       and child:GetObjectType() == "Button" then
                        S:HandleButton(child)
                    end
                end
            end)
        end)
    end

    -- ── Copy popup (created lazily → hook ShowCopyPopup) ────────
    hooksecurefunc(PD, "ShowCopyPopup", function()
        SkinOnce(_G["PDCopyPopup"], function(cp)
            pcall(function()
                SkinFrame(cp)
                if cp.CloseButton then S:HandleCloseButton(cp.CloseButton) end
                if cp.editBox     then S:HandleEditBox(cp.editBox) end
            end)
        end)
    end)

    -- ── Minimap button (LibDBIcon) ──────────────────────────────
    local function SkinMinimapBtn()
        SkinOnce(_G["LibDBIcon10_PlayerDossier"], function(btn)
            pcall(function()
                if btn.SetBackdrop then btn:SetBackdrop(nil) end
                if btn.border     then btn.border:Hide()     end
                if btn.background then btn.background:Hide() end
                if btn.icon then btn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95) end
                for _, region in ipairs({ btn:GetRegions() }) do
                    if region:GetObjectType() == "Texture" and region ~= btn.icon then
                        region:SetTexture(nil)
                    end
                end
            end)
        end)
    end
    SkinMinimapBtn()                -- if the button already exists
    C_Timer.After(1, SkinMinimapBtn) -- otherwise LibDBIcon may not have registered yet

    -- ── Our StaticPopups (PD_*) ─────────────────────────────────
    hooksecurefunc("StaticPopup_Show", function(which)
        if not which or not which:find("^PD_") then return end
        for i = 1, 4 do
            local d = _G["StaticPopup" .. i]
            if d and d:IsShown() and d.which == which then
                SkinOnce(d, function()
                    SkinFrame(d)
                    if d.CloseButton then S:HandleCloseButton(d.CloseButton) end
                    if d.EditBox     then S:HandleEditBox(d.EditBox) end
                    if d.Button1     then S:HandleButton(d.Button1) end
                    if d.Button2     then S:HandleButton(d.Button2) end
                    if d.ExtraButton then S:HandleButton(d.ExtraButton) end
                end)
            end
        end
    end)
end

-- ----------------------------------------------------------------
-- Hook SelectTab: re-align the tabs and skin freshly built panels
-- ----------------------------------------------------------------
local origSelectTab = PD.SelectTab
PD.SelectTab = function(self, n)
    origSelectTab(self, n)
    -- PanelTemplates_SetTab & co. may have reset the anchors
    ReflowTabs(PD.mainFrame)
    C_Timer.After(0, function() SkinTabContent(n) end)
end

S:AddCallbackForAddon("PlayerDossier", "PlayerDossier", LoadSkin)

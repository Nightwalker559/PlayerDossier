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

local function SkinTrimScrollBar(bar)
    if bar then SkinOnce(bar, function() S:HandleTrimScrollBar(bar) end) end
end

local function SkinButton(btn)
    if btn then SkinOnce(btn, function() S:HandleButton(btn) end) end
end

-- Portrait-style frame (main window and dialogs: ElvUI strips the Blizzard
-- art, skins the inset and the close button and applies its template)
local function SkinPanelFrame(frame)
    S:HandlePortraitFrame(frame)
end

-- ----------------------------------------------------------------
-- Tabs (TabSystem below the main window).
--
-- ElvUI's S:HandleTab pulls the visible backdrop inwards by a fixed
-- inset instead of anchoring it to the frame edges, so the layout
-- spacing has to be negative to leave ~1px visible between tabs and the
-- strip has to move left a bit. Same values as ElvUI's own TabSystem
-- skins (Player Spells, Friends).
-- ----------------------------------------------------------------
local TAB_SPACING = -5
local TAB_START_X = -3

local function SkinTabSystem(tabSystem, mainFrame)
    for _, tab in next, { tabSystem:GetChildren() } do
        S:HandleTab(tab)
    end
    tabSystem.spacing = TAB_SPACING
    tabSystem:MarkDirty()
    tabSystem:ClearAllPoints()
    tabSystem:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", TAB_START_X, 0)
end

-- ----------------------------------------------------------------
-- Tab content: panels are built lazily, so each one is skinned
-- the first time its tab is selected.
-- ----------------------------------------------------------------
local function SkinTabContent(n)
    local panel = PD["panel" .. n]
    if not panel then return end
    SkinTrimScrollBar(panel.scrollBar)
    SkinButton(panel.clearBtn)     -- list tabs
    SkinButton(panel.importBtn)    -- options tab

    if panel._optCbs then
        for _, cb in pairs(panel._optCbs) do
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
                SkinPanelFrame(self)
                SkinTabSystem(self.TabSystem, self)
            end)
        end)
    end

    -- ── Note dialog ─────────────────────────────────────────────
    local nd = _G["PDNoteDialog"]
    if nd then
        nd:HookScript("OnShow", function(self)
            SkinOnce(self, function()
                SkinPanelFrame(self)

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
                SkinPanelFrame(cp)
                if cp.editBox then S:HandleEditBox(cp.editBox) end
            end)
        end)
    end)

    -- ── Minimap button ───────────────────────────────────────────
    -- Minimap.lua calls this when it creates the button (the skin may load
    -- before or after that); also covers a button that already exists.
    function PD.SkinMinimapButton(btn)
        SkinOnce(btn, function()
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
    PD.SkinMinimapButton(_G["LibDBIcon10_PlayerDossier"])

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
-- Hook SelectTab: skin freshly built panels
-- ----------------------------------------------------------------
local origSelectTab = PD.SelectTab
PD.SelectTab = function(self, n)
    origSelectTab(self, n)
    RunNextFrame(function() SkinTabContent(n) end)
end

S:AddCallbackForAddon("PlayerDossier", "PlayerDossier", LoadSkin)

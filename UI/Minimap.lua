-- ============================================================
--  PlayerDossier – Minimap.lua
--  Minimap button without a library: left click toggles the window,
--  right click opens a small menu, dragging moves it around the minimap.
--
--  The button is named like a LibDBIcon button ("LibDBIcon10_<name>", with
--  .icon / .border / .background) so button collectors and minimap skins
--  (ElvUI, MinimapButtonButton, ...) pick it up like any other addon button.
--
--  SavedVariables (inside PlayerDossierDB):
--    PlayerDossierDB.minimap = { minimapPos = 225, hide = false }
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

local BUTTON_NAME = "LibDBIcon10_PlayerDossier"

local button

-- ----------------------------------------------------------------
-- Position
-- ----------------------------------------------------------------

-- Places the button on the minimap edge at `angle` degrees (0 = right,
-- counterclockwise); square minimaps (ElvUI) get it on the square edge.
local function Place(angle)
    -- A collector moved the button into its own bar: leave the layout to it.
    if button:GetParent() ~= Minimap then return end
    local rad = math.rad(angle)
    local dx, dy = math.cos(rad), math.sin(rad)
    local half = Minimap:GetWidth() / 2 + 5
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape ~= "ROUND" then
        local m = math.max(math.abs(dx), math.abs(dy))
        dx, dy = dx / m, dy / m
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", dx * half, dy * half)
end

local function UpdateAngleFromCursor()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
    PlayerDossierDB.minimap.minimapPos = angle
    Place(angle)
end

-- ----------------------------------------------------------------
-- Button
-- ----------------------------------------------------------------

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["TT_TITLE"], 0.608, 0.510, 0.961)
    GameTooltip:AddLine(L["TT_LEFTCLICK"] .. "\n" .. L["TT_RIGHTCLICK"], 1, 1, 1, true)
    local count = PD:Count()
    GameTooltip:AddLine(string.format(L["TT_N_ENTRIES"], count,
        count == 1 and L["entry"] or L["entries"]), 1, 1, 1)
    GameTooltip:Show()
end

local function CreateButton()
    local b = CreateFrame("Button", BUTTON_NAME, Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture("Interface\\AddOns\\PlayerDossier\\Media\\icon.tga")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b.icon, b.border, b.background = icon, border, bg

    b:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            PD:ShowMinimapContextMenu()
        else
            PD:ToggleMainWindow()
        end
    end)
    b:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", UpdateAngleFromCursor)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", ShowTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    if PD.SkinMinimapButton then PD.SkinMinimapButton(b) end   -- ElvUI skin (loaded last)
    return b
end

-- ----------------------------------------------------------------
-- Show / hide
-- ----------------------------------------------------------------

function PD:IsMinimapHidden()
    local mm = PlayerDossierDB and PlayerDossierDB.minimap
    return mm and mm.hide or false
end

-- Button bars (LuckyoneUI) re-collect on ElvUI's minimap update; a button
-- without LibDBIcon has to ask for it, or the gap of a hidden button stays
-- until the next reload.
local function NotifyButtonBars()
    local E = ElvUI and ElvUI[1]
    local minimap = E and E.GetModule and E:GetModule("Minimap", true)
    if minimap and minimap.UpdateSettings then pcall(minimap.UpdateSettings, minimap) end
end

local function Apply()
    if PD:IsMinimapHidden() then
        if button then button:Hide() end
        return
    end
    if not button then button = CreateButton() end
    Place(PlayerDossierDB.minimap.minimapPos)
    button:Show()
end

function PD:MinimapShow()
    PlayerDossierDB.minimap.hide = false
    Apply()
    NotifyButtonBars()
end

function PD:MinimapHide()
    PlayerDossierDB.minimap.hide = true
    Apply()
    NotifyButtonBars()
end

local function ToggleMinimapButton()
    if PD:IsMinimapHidden() then
        PD:MinimapShow()
    else
        PD:MinimapHide()
        print(L["MM_HIDE_MSG"])
    end
end

-- ----------------------------------------------------------------
-- Creation (runs after the main window was built)
-- ----------------------------------------------------------------

PD:OnBuildUI(function()
    local mm = PlayerDossierDB.minimap or {}
    PlayerDossierDB.minimap = mm
    mm.minimapPos = mm.minimapPos or 225   -- degrees, 225° = upper left
    Apply()
end)

-- ----------------------------------------------------------------
-- Right-click context menu
-- ----------------------------------------------------------------

function PD:ShowMinimapContextMenu()
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle("|cff9B82F3PlayerDossier|r")
        root:CreateButton(L["MM_OPEN_DOSSIER"], function() PD:ToggleMainWindow() end)
        root:CreateButton(L["MM_OPEN_IGNORE"],  function() PD:OpenOnTab(2) end)
        root:CreateDivider()
        root:CreateButton(PD:IsMinimapHidden() and L["MM_SHOW_BTN"] or L["MM_HIDE_BTN"],
            ToggleMinimapButton)
    end)
end

-- ----------------------------------------------------------------
-- Slash command: /pd minimap
-- ----------------------------------------------------------------

PD.commands.minimap = ToggleMinimapButton

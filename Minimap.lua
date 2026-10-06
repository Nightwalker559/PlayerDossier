-- ============================================================
--  PlayerDossier – Minimap.lua
--  Minimap button via LibDataBroker-1.1 + LibDBIcon-1.0.
--
--  Why LibDBIcon instead of a hand-made button?
--  → Interoperability: MinimapButtonButton, MinimapButtonHub,
--    Bazooka, ChocolateBar, ElvUI etc. all collect LibDBIcon
--    buttons, so ours shows up where users expect addon buttons.
--
--  SavedVariables (inside PlayerDossierDB):
--    PlayerDossierDB.minimap = { minimapPos = 225, hide = false }
-- ============================================================

local PD     = PlayerDossier
local L      = PD.L
local LDB    = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

local BUTTON_NAME = L["TT_TITLE"]

-- ----------------------------------------------------------------
-- LDB data object ("launcher" is the standard type for addon buttons)
-- ----------------------------------------------------------------

local ldbObject = LDB:NewDataObject(BUTTON_NAME, {
    type  = "launcher",
    label = BUTTON_NAME,
    icon  = "Interface/AddOns/PlayerDossier/Media/icon.tga",

    OnClick = function(self, button)
        if button == "LeftButton" then
            PD:ToggleMainWindow()
        elseif button == "RightButton" then
            PD:ShowMinimapContextMenu()
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:AddLine(L["TT_TITLE"], 0.608, 0.510, 0.961)
        tooltip:AddLine(L["TT_LEFTCLICK"] .. "\n" .. L["TT_RIGHTCLICK"], 1, 1, 1, true)
        local count = PD:Count()
        tooltip:AddLine(string.format(L["TT_N_ENTRIES"], count,
            count == 1 and L["entry"] or L["entries"]), 1, 1, 1)
    end,
})

-- ----------------------------------------------------------------
-- Show / hide
-- ----------------------------------------------------------------

function PD:IsMinimapHidden()
    local mm = PlayerDossierDB and PlayerDossierDB.minimap
    return mm and mm.hide or false
end

function PD:MinimapShow()
    if PlayerDossierDB.minimap then PlayerDossierDB.minimap.hide = false end
    DBIcon:Show(BUTTON_NAME)
end

function PD:MinimapHide()
    if PlayerDossierDB.minimap then PlayerDossierDB.minimap.hide = true end
    DBIcon:Hide(BUTTON_NAME)
end

local function ToggleMinimapButton()
    if PD:IsMinimapHidden() then
        PD:MinimapShow()
        print(L["MM_SHOW_MSG"])
    else
        PD:MinimapHide()
        print(L["MM_HIDE_MSG"])
    end
end

-- ----------------------------------------------------------------
-- Registration (runs after the main window was built)
-- ----------------------------------------------------------------

PD:OnBuildUI(function()
    if DBIcon:IsRegistered(BUTTON_NAME) then return end

    -- LibDBIcon reads/writes minimapPos and hide directly in this table
    PlayerDossierDB.minimap = PlayerDossierDB.minimap or {
        minimapPos = 225,   -- degrees, 225° = upper left (LibDBIcon convention)
        hide       = false,
    }
    DBIcon:Register(BUTTON_NAME, ldbObject, PlayerDossierDB.minimap)
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

PD.commands.minimap = function()
    if DBIcon:IsRegistered(BUTTON_NAME) then ToggleMinimapButton() end
end

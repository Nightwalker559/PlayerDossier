-- ============================================================
--  PlayerDossier – Minimap.lua
--  Minimap button via LibDataBroker-1.1 + LibDBIcon-1.0.
--
--  Why LibDBIcon instead of pure Lua?
--  → Interoperability: MinimapButtonButton (14M DL), MinimapButtonHub,
--    Bazooka, ChocolateBar, ElvUI all collect LibDBIcon buttons.
--    Our button shows up everywhere users expect addon buttons.
--
--  SavedVariables used (inside PlayerDossierDB):
--    PlayerDossierDB.minimap = { minimapPos = 225, hide = false }
-- ============================================================

local PD     = PlayerDossier
local L = PD.L
local LDB    = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

-- ----------------------------------------------------------------
-- LDB data object  (the "launcher" type is the standard for addon buttons)
-- ----------------------------------------------------------------

local ldbObject = LDB:NewDataObject(L["TT_TITLE"], {
    type  = "launcher",
    label = L["TT_TITLE"],
    icon  = "Interface/AddOns/PlayerDossier/Media/icon.tga",

    -- ── Left / right click ─────────────────────────────────
    OnClick = function(self, button)
        if button == "LeftButton" then
            PD:ToggleMainWindow()
        elseif button == "RightButton" then
            PD:ShowMinimapContextMenu(self)
        end
    end,

    -- ── Tooltip ────────────────────────────────────────────
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(L["TT_TITLE"], 0.608, 0.510, 0.961)
        tooltip:AddLine(L["TT_LEFTCLICK"] .. "\n" .. L["TT_RIGHTCLICK"], 1, 1, 1, true)
        local count = PD:Count()
        tooltip:AddLine(string.format(L["TT_N_ENTRIES"], count,
            count == 1 and L["entry"] or L["entries"]), 1, 1, 1)
    end,
})

-- ----------------------------------------------------------------
-- Register + initialise  (called from PD:BuildUI in Events.lua)
-- ----------------------------------------------------------------

function PD:BuildMinimapButton()
    if DBIcon:IsRegistered(L["TT_TITLE"]) then return end

    -- Ensure the minimap sub-table exists in our SavedVariables.
    -- LibDBIcon reads/writes minimapPos and hide directly into this table.
    PlayerDossierDB.minimap = PlayerDossierDB.minimap or {
        minimapPos = 225,   -- degrees, 225° = upper-left (LibDBIcon convention)
        hide       = false,
    }

    DBIcon:Register(L["TT_TITLE"], ldbObject, PlayerDossierDB.minimap)

    -- Öffentliche Hilfsfunktionen damit Options.lua DBIcon nicht kennen muss
    function PD:MinimapShow()
        if PlayerDossierDB.minimap then PlayerDossierDB.minimap.hide = false end
        DBIcon:Show(L["TT_TITLE"])
    end
    function PD:MinimapHide()
        if PlayerDossierDB.minimap then PlayerDossierDB.minimap.hide = true end
        DBIcon:Hide(L["TT_TITLE"])
    end
end

-- ----------------------------------------------------------------
-- Context menu  (right-click)
-- ----------------------------------------------------------------

function PD:ShowMinimapContextMenu(owner)
    MenuUtil.CreateContextMenu(UIParent, function(_, rootDescription)
        rootDescription:CreateTitle("|cff9B82F3PlayerDossier|r")

        rootDescription:CreateButton(L["MM_OPEN_DOSSIER"], function()
            PD:ToggleMainWindow()
        end)

        rootDescription:CreateButton(L["MM_OPEN_IGNORE"], function()
            PD:OpenOnTab(2)
        end)

        rootDescription:CreateDivider()

        -- Minimap button hide/show
        local btnHidden = PlayerDossierDB and PlayerDossierDB.minimap and PlayerDossierDB.minimap.hide
        rootDescription:CreateButton(
            btnHidden and L["MM_SHOW_BTN"] or L["MM_HIDE_BTN"],
            function()
                if PlayerDossierDB.minimap.hide then
                    PD:MinimapShow()
                    print(L["MM_SHOW_MSG"])
                else
                    PD:MinimapHide()
                    print(L["MM_HIDE_MSG"])
                end
            end
        )
    end)
end

-- ----------------------------------------------------------------
-- Extend PD:BuildUI  (UI.lua defines the original; we wrap it here)
-- ----------------------------------------------------------------

local origBuildUI = PD.BuildUI
PD.BuildUI = function(self)
    if origBuildUI then origBuildUI(self) end
    PD:BuildMinimapButton()
end

-- ----------------------------------------------------------------
-- Extend slash commands  (/pd minimap)
-- ----------------------------------------------------------------

local origSlash = SlashCmdList["PLAYERDOSSIER"]
SlashCmdList["PLAYERDOSSIER"] = function(msg)
    local lower = msg and strtrim(msg:lower()) or ""
    if lower == "minimap" then
        if not DBIcon:IsRegistered(L["TT_TITLE"]) then return end
        local isHidden = PlayerDossierDB and PlayerDossierDB.minimap and PlayerDossierDB.minimap.hide
        if isHidden then
            PD:MinimapShow()
            print(L["MM_SHOW_MSG"])
        else
            PD:MinimapHide()
            print(L["MM_HIDE_MSG"])
        end
    else
        origSlash(msg)
    end
end

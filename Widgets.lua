-- ============================================================
--  PlayerDossier – Widgets.lua
--  Shared UI building blocks used by the Players, Ignore List and
--  History panels: column layout, row pooling, list panels, popups.
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- ----------------------------------------------------------------
-- Column positions shared by the Players, Ignore List and History
-- tabs. All panels live in the same main window (same width), so
-- identical x values give an identical look.
-- MODE is only used by the History tab. LAST is "Note" in the
-- Players/Ignore List tabs but "Grouped" in History.
-- ----------------------------------------------------------------
PD.COL = {
    NAME  = 58,   -- leaves room for the 48px mood icon in the Players tab
    REALM = 220,
    ROLE  = 330,  -- not used by the Ignore List
    MODE  = 370,  -- History only (only ever "M+<level>" - ScanGroup() filters on ^M%+)
    SINCE = 440,
    LAST  = 485,
}

-- Alternating row background colors { even, odd }
PD.ROW_TINT = {
    default = { { 0.08, 0.08, 0.10, 0.55 }, { 0.13, 0.13, 0.17, 0.55 } },
    ignore  = { { 0.10, 0.04, 0.04, 0.60 }, { 0.14, 0.06, 0.06, 0.60 } },
}

-- ----------------------------------------------------------------
-- Draggable top-level frame
-- ----------------------------------------------------------------
function PD:MakeDraggable(f)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
end

-- ----------------------------------------------------------------
-- Shared table header for the Players/Ignore List/History tabs.
-- Each header stretches to the next column (the last one to the
-- panel's right edge) so long labels aren't cut off.
--
-- heads: { { text=<string>, x=<pixel offset from left> }, ... }
--        sorted by x ascending.
-- rightPad: distance to the panel's right edge (default 26 = scrollbar)
-- ----------------------------------------------------------------
function PD:BuildColumnHeaders(panel, heads, rightPad)
    rightPad = rightPad or 26
    for i, h in ipairs(heads) do
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", h.x + 2, -4)
        local nextX = heads[i + 1] and heads[i + 1].x
        local width = nextX and (nextX - h.x - 4)
            or (panel:GetWidth() - h.x - rightPad - 2)
        if width and width > 0 then fs:SetWidth(width) end
        fs:SetJustifyH("LEFT")
        fs:SetText(h.text)
        fs:SetTextColor(0.9, 0.82, 0.5)
    end

    local sep = panel:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  panel, "TOPLEFT",   4,  -18)
    sep:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -rightPad, -18)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.8)
end

-- ----------------------------------------------------------------
-- Frame pool for list rows. Returns GetRow(parent), HideAll().
-- ----------------------------------------------------------------
function PD:NewRowPool()
    local pool = {}
    local function GetRow(parent)
        for _, r in ipairs(pool) do
            if not r:IsShown() then r:SetParent(parent) r:Show() return r end
        end
        local r = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        table.insert(pool, r)
        return r
    end
    local function HideAll()
        for _, r in ipairs(pool) do r:Hide() end
    end
    return GetRow, HideAll
end

-- ----------------------------------------------------------------
-- List panel skeleton: column headers, scroll frame and a
-- "Remove All" button. Returns the scroll content frame.
--
-- spec = { heads, scroll, content, clearBtn, clearPopup }
--   scroll/content/clearBtn: global frame names (ElvUI skin looks
--   them up by name); clearPopup: StaticPopup shown by the button.
-- ----------------------------------------------------------------
function PD:BuildListPanel(panel, spec)
    PD:BuildColumnHeaders(panel, spec.heads)

    local sf = CreateFrame("ScrollFrame", spec.scroll, panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     panel, "TOPLEFT",     4,  -22)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 32)
    local content = CreateFrame("Frame", spec.content, sf)
    content:SetWidth(sf:GetWidth())
    content:SetHeight(1)
    sf:SetScrollChild(content)

    local clearBtn = CreateFrame("Button", spec.clearBtn, panel, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 22)
    clearBtn:SetText(L["BTN_CLEAR_ALL"])
    clearBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 6)
    clearBtn:SetScript("OnClick", function() StaticPopup_Show(spec.clearPopup) end)

    return content
end

-- ----------------------------------------------------------------
-- Row helpers
-- ----------------------------------------------------------------

-- Sizes/positions a pooled row inside the scroll content and applies
-- the striped background. tint: one of PD.ROW_TINT.
function PD:SetupRow(row, content, index, rowH, pad, tint)
    row:SetSize(content:GetWidth() - 4, rowH)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -pad - (index - 1) * (rowH + pad))
    row:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    row:SetBackdropColor(unpack(tint[index % 2 == 0 and 1 or 2]))

    row:EnableMouse(true)
    if not row.hlTex then
        row.hlTex = row:CreateTexture(nil, "HIGHLIGHT")
        row.hlTex:SetAllPoints()
        row.hlTex:SetColorTexture(1, 1, 1, 0.05)
        row.hlTex:SetBlendMode("ADD")
    end
end

-- Sets the scroll content height after `count` rows
function PD:FinishList(content, count, rowH, pad)
    content:SetHeight(2 * pad + count * (rowH + pad))
end

-- Returns row[key], creating the FontString on first use.
-- x: left offset; nextX: x of the next column (nil = last column,
-- stretches to the row's right edge); r,g,b: optional fixed color.
function PD:RowLabel(row, key, x, nextX, template, r, g, b)
    local fs = row[key]
    if not fs then
        fs = row:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
        fs:SetPoint("LEFT", row, "LEFT", x, 0)
        if nextX then
            fs:SetWidth(nextX - x - 4)
        else
            fs:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        end
        fs:SetJustifyH("LEFT")
        if r then fs:SetTextColor(r, g, b) end
        row[key] = fs
    end
    return fs
end

-- Class color (if enabled in the options) or white
function PD:ApplyNameColor(fs, class)
    local cc = PD:OPT_Get("classColors") and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if cc then fs:SetTextColor(cc.r, cc.g, cc.b)
    else       fs:SetTextColor(1, 1, 1) end
end

-- Right-click context menu for a row. build(root) fills the menu.
function PD:SetRowMenu(row, build)
    row:SetScript("OnMouseUp", function(_, btn)
        if btn ~= "RightButton" then return end
        MenuUtil.CreateContextMenu(UIParent, function(_, root) build(root) end)
    end)
end

-- ----------------------------------------------------------------
-- Empty-state label and subtitle
-- ----------------------------------------------------------------

function PD:ShowEmptyLabel(panel, content, text, top, height)
    if not panel.emptyLabel then
        panel.emptyLabel = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        panel.emptyLabel:SetPoint("TOP", content, "TOP", 0, -top)
        panel.emptyLabel:SetText(text)
        panel.emptyLabel:SetJustifyH("CENTER")
    end
    panel.emptyLabel:Show()
    content:SetHeight(height)
end

function PD:HideEmptyLabel(panel)
    if panel.emptyLabel then panel.emptyLabel:Hide() end
end

-- "No entries" / "1 entry" / "%d entries" style text from three locale keys
function PD.CountText(count, noneKey, oneKey, manyKey)
    if count == 0 then return L[noneKey] end
    if count == 1 then return L[oneKey] end
    return string.format(L[manyKey], count)
end

function PD:SetSubtitle(text)
    if PD.mainFrame then PD.mainFrame.subtitle:SetText(text) end
end

-- ----------------------------------------------------------------
-- Copy popup (Ctrl+C), created lazily
-- ----------------------------------------------------------------
local copyPopup

function PD:ShowCopyPopup(text)
    if not copyPopup then
        local f = CreateFrame("Frame", "PDCopyPopup", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(320, 70)
        f:SetFrameStrata("TOOLTIP")
        PD:MakeDraggable(f)
        f:Hide()
        f.TitleText:SetText(L["COPY_POPUP_TITLE"])
        f:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() end
        end)
        f:SetPropagateKeyboardInput(true)

        local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        eb:SetSize(280, 20)
        eb:SetPoint("CENTER", f.InsetBg, "CENTER", 0, 0)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed",  function() f:Hide() end)
        eb:SetScript("OnKeyDown", function(_, key)
            if key == "C" and IsControlKeyDown() then
                C_Timer.After(0, function() f:Hide() end)
            end
        end)
        f.editBox = eb
        copyPopup = f
    end
    local f = copyPopup
    f:SetPoint("CENTER")
    f.editBox:SetText(text)
    f.editBox:HighlightText()
    f.editBox:SetFocus()
    f:Show()
end

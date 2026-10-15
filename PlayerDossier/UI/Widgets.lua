-- ============================================================
--  PlayerDossier – Widgets.lua
--  Shared UI building blocks used by the Dossier, Ignore List and
--  History panels: column layout, row pooling, list panels, popups.
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- ----------------------------------------------------------------
-- Column positions shared by the Dossier, Ignore List and History
-- tabs. All panels live in the same main window (same width), so
-- identical x values give an identical look.
-- MODE is only used by the History tab. LAST is "Note" in the
-- Dossier/Ignore List tabs but "Grouped" in History.
-- Every header cell must fit its label plus the 14px sort arrow
-- (localized labels like "Rolle"/"Modus"/"Gruppiert"), so the narrow
-- columns are at least ~60px wide.
-- ----------------------------------------------------------------
PD.COL = {
    MOOD  = 4,    -- mood icon (Dossier and Ignore List tabs, no header)
    NAME  = 58,   -- leaves room for the 48px mood icon
    REALM = 170,
    ROLE  = 275,
    MODE  = 335,  -- History only (only ever "M+<level>" - ScanGroup() filters on ^M%+)
    SINCE = 400,
    LAST  = 465,
}

-- Header cells start where the row labels start: scroll box inset (4)
-- + row inset (2) = 6px from the panel's left edge
local HEADER_X = 6

-- Space reserved at the right edge of a list panel for the minimal scroll bar
local LIST_BAR_W = 18

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
-- Small dialog shell (note dialog, copy popup): DefaultPanelTemplate
-- (title bar + nine-slice border) with a close button and an inset
-- for the content. Title via f:SetTitle(), content parent: f.Inset.
-- ----------------------------------------------------------------
function PD:CreateDialogFrame(name, width, height, strata)
    local f = CreateFrame("Frame", name, UIParent, "DefaultPanelTemplate")
    f:SetSize(width, height)
    f:SetFrameStrata(strata or "DIALOG")
    f:SetToplevel(true)
    PD:MakeDraggable(f)
    f:Hide()

    f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButtonDefaultAnchors")

    f.Inset = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
    f.Inset:SetFrameLevel(f:GetFrameLevel())
    f.Inset:SetPoint("TOPLEFT",     f, "TOPLEFT",      4, -24)
    f.Inset:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6,   4)
    return f
end

-- ----------------------------------------------------------------
-- Shared table header for the Dossier/Ignore List/History tabs.
-- Each header stretches to the next column (the last one to the
-- panel's right edge) so long labels aren't cut off.
--
-- heads: { { text=<string>, x=<pixel offset from left>,
--            key=<sort key>, descFirst=<true: first click sorts descending> }, ... }
--        sorted by x ascending. Heads with a key are clickable.
-- sort:  { id=<saved sort state name>, default={key=,asc=}, onChange=fn }
-- rightPad: distance to the panel's right edge (default LIST_BAR_W = scroll bar)
-- ----------------------------------------------------------------

-- Default for every list tab: "Since", newest first
PD.SORT_DEFAULT = { key = "since", asc = false }

-- Lower-case string for sort keys (nil → "")
function PD.Lower(s) return (s or ""):lower() end

-- Sort key for the Role column of the Dossier and Ignore List tabs (role
-- comes from the group history)
function PD.RoleSortKey(e)
    local h = PD:GH_GetEntry(e.name, e.realm)
    return PD.Lower(h and h.role)
end

-- Saved sort state of a list tab (falls back to the tab's default)
function PD:GetSortState(id, default)
    local db = PlayerDossierDB
    db.sort = db.sort or {}
    local s = db.sort[id]
    if not s or s.key == nil then
        s = { key = default.key, asc = default.asc }
        db.sort[id] = s
    end
    return s
end

-- Sorts `list` in place. getters[key](entry) returns a number or a
-- lowercase string; ties fall back to name, then realm.
function PD:SortList(list, id, default, getters)
    local s   = PD:GetSortState(id, default)
    local get = getters[s.key] or getters[default.key]
    local asc = s.asc
    local keys = {}   -- sort key per entry, computed once
    for _, e in ipairs(list) do keys[e] = get(e) end
    table.sort(list, function(a, b)
        local va, vb = keys[a], keys[b]
        if va ~= vb then
            if asc then return va < vb end
            return va > vb
        end
        local na, nb = (a.name or ""):lower(), (b.name or ""):lower()
        if na ~= nb then return na < nb end
        return (a.realm or "") < (b.realm or "")
    end)
end

-- All sort arrows, so the ElvUI skin can restyle the ones already built
local sortArrows = {}

-- Look of a sort arrow; ElvUI_Skin.lua replaces this with ElvUI's arrow.
function PD.StyleSortArrow(arrow, asc)
    arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    arrow:SetSize(9, 8)
    arrow:SetRotation(0)
    arrow:SetVertexColor(1, 1, 1)
    -- UI-SortArrow points up; flip vertically for descending
    arrow:SetTexCoord(0, 0.5625, asc and 0 or 1, asc and 1 or 0)
end

function PD:RestyleSortArrows()
    for _, arrow in ipairs(sortArrows) do PD.StyleSortArrow(arrow, arrow.asc) end
end

function PD:BuildColumnHeaders(panel, heads, rightPad, sort)
    rightPad = rightPad or LIST_BAR_W
    local buttons = {}

    local function UpdateArrows()
        local s = sort and PD:GetSortState(sort.id, sort.default)
        for key, btn in pairs(buttons) do
            local active = s and s.key == key
            btn.arrow:SetShown(active)
            if active then
                btn.arrow.asc = s.asc
                PD.StyleSortArrow(btn.arrow, s.asc)
            end
        end
    end

    for i, h in ipairs(heads) do
        local nextX = heads[i + 1] and heads[i + 1].x
        local width = nextX and (nextX - h.x - 4)
            or (panel:GetWidth() - h.x - rightPad - HEADER_X)

        local btn = CreateFrame("Button", nil, panel)
        btn:SetPoint("TOPLEFT", panel, "TOPLEFT", h.x + HEADER_X, -2)
        btn:SetHeight(16)
        btn:SetWidth(width and width > 0 and width or 60)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", btn, "LEFT", 0, 0)
        fs:SetJustifyH("LEFT")
        fs:SetText(h.text)
        fs:SetTextColor(0.9, 0.82, 0.5)
        -- Leave room for the sort arrow
        if width and width > 0 and fs:GetStringWidth() > width - 14 then
            fs:SetWidth(width - 14)
        end

        if h.key and sort then
            local arrow = btn:CreateTexture(nil, "OVERLAY")
            arrow:SetPoint("LEFT", fs, "RIGHT", 3, 0)
            arrow:Hide()
            btn.arrow = arrow
            sortArrows[#sortArrows + 1] = arrow
            buttons[h.key] = btn

            btn:SetScript("OnEnter", function() fs:SetTextColor(1, 1, 1) end)
            btn:SetScript("OnLeave", function() fs:SetTextColor(0.9, 0.82, 0.5) end)
            btn:SetScript("OnClick", function()
                local s = PD:GetSortState(sort.id, sort.default)
                if s.key == h.key then
                    s.asc = not s.asc
                else
                    s.key = h.key
                    s.asc = not h.descFirst
                end
                UpdateArrows()
                sort.onChange()
            end)
        else
            btn:EnableMouse(false)
        end
    end
    UpdateArrows()

    local sep = panel:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  panel, "TOPLEFT",   4,  -18)
    sep:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -rightPad, -18)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.8)
end

-- ----------------------------------------------------------------
-- List panel skeleton: column headers, a ScrollBox (WowScrollBoxList)
-- with a minimal scroll bar, and a "Remove All" button in the button bar
-- of the main window. Rows are pooled by the ScrollBox and filled from
-- a DataProvider (see RenderList).
--
-- spec = { heads, sort, rowH, pad, tint, fill, clearPopup }
--   sort: see BuildColumnHeaders.
--   rowH/pad: row height and spacing; tint: one of PD.ROW_TINT.
--   fill(row, entry): fills a (recycled) row.
--   clearPopup: StaticPopup shown by the "Remove All" button.
-- Sets panel.scrollBox, panel.scrollBar, panel.clearBtn (the ElvUI
-- skin looks them up there).
-- ----------------------------------------------------------------
function PD:BuildListPanel(panel, spec)
    PD:BuildColumnHeaders(panel, spec.heads, nil, spec.sort)

    local box = CreateFrame("Frame", nil, panel, "WowScrollBoxList")
    box:SetPoint("TOPLEFT",     panel, "TOPLEFT",      4,  -22)
    box:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -LIST_BAR_W, 4)

    local bar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT",    box, "TOPRIGHT",    5, -3)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 5, 3)

    local pad, tint, fill = spec.pad, spec.tint, spec.fill
    local view = CreateScrollBoxListLinearView(pad, pad, 2, 2, pad)
    view:SetElementExtent(spec.rowH)
    view:SetElementInitializer("Button", function(row, data)
        if not row.stripe then
            row.stripe = row:CreateTexture(nil, "BACKGROUND")
            row.stripe:SetAllPoints()
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.05)
            hl:SetBlendMode("ADD")
        end
        row.stripe:SetColorTexture(unpack(tint[data.tint]))
        fill(row, data.entry)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)

    -- Button bar of the main window (panel is a child of it)
    local clearBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 22)
    clearBtn:SetText(L["BTN_CLEAR_ALL"])
    clearBtn:SetPoint("BOTTOMLEFT", panel:GetParent(), "BOTTOMLEFT", 8, 4)
    clearBtn:SetScript("OnClick", function() StaticPopup_Show(spec.clearPopup) end)

    panel.scrollBox, panel.scrollBar, panel.clearBtn = box, bar, clearBtn
end

-- Fills a list tab: sorts the entries, sets the subtitle, hands the rows
-- to the ScrollBox and shows the empty label if there are none.
-- o = { panel, list, sortId, getters,
--       subtitle = {noneKey, oneKey, manyKey}, empty = {text, top} }
function PD:RenderList(o)
    local panel = o.panel
    PD:SortList(o.list, o.sortId, PD.SORT_DEFAULT, o.getters)

    local count = #o.list
    PD:SetSubtitle(PD.CountText(count, unpack(o.subtitle)), panel)

    -- Alternating row tint: index into the tint table (1 = even, 2 = odd)
    local data = {}
    for i, e in ipairs(o.list) do
        data[i] = { entry = e, tint = i % 2 == 0 and 1 or 2 }
    end
    panel.scrollBox:SetDataProvider(CreateDataProvider(data), ScrollBoxConstants.RetainScrollPosition)

    if count == 0 then
        PD:ShowEmptyLabel(panel, o.empty[1], o.empty[2])
    else
        PD:HideEmptyLabel(panel)
    end
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

-- Class of a player known to the dossier or the group history (nil if unknown)
function PD:LookupClass(name, realm)
    local d = PD:GetEntry(name, realm)
    if d and d.class and d.class ~= "UNKNOWN" then return d.class end
    local h = PD:GH_GetEntry(name, realm)
    if h and h.class and h.class ~= "UNKNOWN" then return h.class end
end

-- Columns shared by the Dossier and Ignore List rows: mood icon,
-- class-colored name, realm, role (from the group history), since, note.
-- e: entry (name, realm); o: { mood, class, ts, note }
function PD:FillPlayerCols(row, e, o)
    local COL = PD.COL

    if not row.moodTex then
        row.moodTex = row:CreateTexture(nil, "ARTWORK")
        row.moodTex:SetSize(48, 48)
        row.moodTex:SetPoint("LEFT", row, "LEFT", COL.MOOD, 0)
    end
    row.moodTex:SetTexture(PD:GetMood(o.mood).tex)

    local nameLabel = PD:RowLabel(row, "nameLabel", COL.NAME, COL.REALM, "GameFontNormalLarge")
    PD:ApplyNameColor(nameLabel, o.class)
    nameLabel:SetText(e.name or "?")

    PD:RowLabel(row, "realmLabel", COL.REALM, COL.ROLE, nil, 0.78, 0.78, 0.78)
        :SetText(e.realm or PD.GetMyRealm())

    local hEntry = PD:GH_GetEntry(e.name, e.realm)
    PD:RowLabel(row, "roleLabel", COL.ROLE, COL.SINCE):SetText(PD:GH_RoleText(hEntry and hEntry.role))

    PD:RowLabel(row, "sinceLabel", COL.SINCE, COL.LAST, nil, 0.78, 0.78, 0.78)
        :SetText(PD:TimeAgo(o.ts))

    local noteLabel = PD:RowLabel(row, "noteLabel", COL.LAST, nil, nil, 0.60, 0.60, 0.60)
    noteLabel:SetWordWrap(false)
    noteLabel:SetText((o.note and o.note ~= "") and o.note or "|cff444444-|r")
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

function PD:ShowEmptyLabel(panel, text, top)
    if not panel.emptyLabel then
        panel.emptyLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        panel.emptyLabel:SetPoint("TOP", panel.scrollBox, "TOP", 0, -top)
        panel.emptyLabel:SetText(text)
        panel.emptyLabel:SetJustifyH("CENTER")
    end
    panel.emptyLabel:Show()
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

-- Sets the window subtitle; with `panel` only if that panel is the visible one
-- (a refresh can be triggered while another tab is open)
function PD:SetSubtitle(text, panel)
    if PD.mainFrame and (not panel or panel:IsShown()) then
        PD.mainFrame.subtitle:SetText(text)
    end
end

-- ----------------------------------------------------------------
-- Copy popup (Ctrl+C), created lazily
-- ----------------------------------------------------------------
local copyPopup

function PD:ShowCopyPopup(text)
    if not copyPopup then
        local f = PD:CreateDialogFrame("PDCopyPopup", 320, 90, "TOOLTIP")
        f:SetTitle(L["COPY_POPUP_TITLE"])
        f:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() end
        end)
        f:SetPropagateKeyboardInput(true)

        local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        eb:SetSize(280, 20)
        eb:SetPoint("CENTER", f.Inset, "CENTER", 0, 0)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed",  function() f:Hide() end)
        eb:SetScript("OnKeyDown", function(_, key)
            if key == "C" and IsControlKeyDown() then
                RunNextFrame(function() f:Hide() end)
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

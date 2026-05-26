-- ============================================================
--  PlayerDossier – UI.lua
--  Ein Fenster mit 3 Tabs (Players / Chat Filters / Ignore List)
--  Panel-Inhalte werden von ChatFilter.lua + IgnoreList.lua befüllt
-- ============================================================

local PD = PlayerDossier
local L = PD.L

-- ================================================================
-- GEMEINSAME KONSTANTEN
-- ================================================================

local MOOD = {
    positive = { r=0,   g=0.80, b=0,    hex="00cc00", label=L["MOOD_GOOD"],    tex="Interface/AddOns/PlayerDossier/Media/mood_good.png"    },
    negative = { r=1,   g=0.18, b=0.18, hex="ff2e2e", label=L["MOOD_BAD"],     tex="Interface/AddOns/PlayerDossier/Media/mood_bad.png"     },
    neutral  = { r=1,   g=0.85, b=0,    hex="ffdd00", label=L["MOOD_NEUTRAL"], tex="Interface/AddOns/PlayerDossier/Media/mood_neutral.png"  },
}

-- ================================================================
-- 1.  TOOLTIP  (kein Unit*-API → kein Taint)
-- ================================================================

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    if not data then return end

    -- data.guid ist ein "secret value" im tainted Context → pcall nötig
    local ok, guid = pcall(function() return data.guid end)
    if not ok or not guid then return end

    -- Nur Player-GUIDs verarbeiten
    local okMatch, guidType = pcall(string.match, guid, "^(%a+)-")
    if not okMatch or guidType ~= "Player" then return end

    -- GetPlayerInfoByGUID ebenfalls absichern
    local okInfo, _, _, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
    if not okInfo or not name then return end

    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local entry = PD:GetEntry(name, realm)
    if not entry then return end

    local m = MOOD[entry.mood] or MOOD.neutral
    tooltip:AddLine(string.format("|cff%s[PD] %s|r", m.hex, m.label))
    if entry.note and entry.note ~= "" then
        tooltip:AddLine("|cffbbbbbb\"" .. entry.note .. "\"|r", 1, 1, 1, true)
    end
end)

-- ================================================================
-- 2.  NOTE-DIALOG
-- ================================================================

local pending = {}

local MOOD_BTNS = {
    { id="positive", label=L["MOOD_GOOD"],    r=0,   g=0.80, b=0    },
    { id="neutral",  label=L["MOOD_NEUTRAL"], r=1,   g=0.85, b=0    },
    { id="negative",  label=L["MOOD_BAD"],     r=1,   g=0.18, b=0.18 },
}

local MOOD_SELECTED_ALPHA   = 1.0
local MOOD_UNSELECTED_ALPHA = 0.40

local function RefreshMoodBtns()
    local f = PD.noteDialog
    if not f then return end
    for _, btn in ipairs(f.moodBtns) do
        local selected = btn.moodId == pending.mood
        if selected then
            btn:LockHighlight()
            btn:SetAlpha(MOOD_SELECTED_ALPHA)
            btn:GetFontString():SetFont(btn:GetFontString():GetFont(), 13, "OUTLINE")
        else
            btn:UnlockHighlight()
            btn:SetAlpha(MOOD_UNSELECTED_ALPHA)
            btn:GetFontString():SetFont(btn:GetFontString():GetFont(), 11, "")
        end
    end
end

local function ResolveClass(name, realm, class, guid)
    -- Bereits bekannt
    if class and class ~= "UNKNOWN" and class ~= "" then return class end

    -- Aus GUID via GetPlayerInfoByGUID
    if guid and guid ~= "" then
        local ok, _, _, _, _, engClass = pcall(GetPlayerInfoByGUID, guid)
        if ok and engClass and engClass ~= "" then return engClass end
    end

    -- Aktuelle Gruppe scannen
    local myRealm = PD.GetMyRealm()
    realm = (realm and realm ~= "") and realm or myRealm
    local isRaid = IsInRaid()
    local num    = GetNumGroupMembers()
    for i = 1, num do
        local unit = isRaid and ("raid"..i) or ("party"..i)
        if UnitExists(unit) then
            local n, r = UnitName(unit)
            r = (r and r ~= "") and r or myRealm
            if n == name and r == realm then
                local _, engClass = UnitClass(unit)
                if engClass then return engClass end
            end
        end
    end

    return class or "UNKNOWN"
end

local function SaveNote()
    local f = PD.noteDialog
    local note = strtrim(f.editBox:GetText())
    local resolvedClass = ResolveClass(pending.name, pending.realm, pending.class, pending.guid)
    PD:SetEntry(pending.name, pending.realm, note, pending.mood, resolvedClass, pending.guid)
    if PD:OPT_Get("chatMessages") then
        print(string.format(L["NOTE_SAVED"], pending.name))
    end
    if PD.mainFrame and PD.mainFrame:IsShown() then PD:RefreshMainWindow() end
    f:Hide()
    wipe(pending)
end

function PD:BuildNoteDialog()
    if PD.noteDialog then return end
    local f = CreateFrame("Frame", "PDNoteDialog", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(340, 185)
    f:SetPoint("CENTER")
    f:SetMovable(true) f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG") f:SetFrameLevel(100) f:Hide()
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() wipe(pending) end
    end)
    f:SetPropagateKeyboardInput(true)

    f.editBox = CreateFrame("EditBox", "PDNoteEditBox", f, "InputBoxTemplate")
    f.editBox:SetSize(295, 20)
    f.editBox:SetPoint("TOP", f.InsetBg, "TOP", 0, -12)
    f.editBox:SetMaxLetters(60) f.editBox:SetAutoFocus(false)
    f.editBox:SetScript("OnEscapePressed", function() f:Hide() wipe(pending) end)
    f.editBox:SetScript("OnEnterPressed",  SaveNote)

    f.moodBtns = {}
    for i, def in ipairs(MOOD_BTNS) do
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(86, 22) btn:SetText(def.label)
        btn:GetFontString():SetTextColor(def.r, def.g, def.b)
        btn:SetPoint("TOPLEFT", f.editBox, "BOTTOMLEFT", (i-1)*90, -10)
        btn.moodId = def.id
        btn:SetScript("OnClick", function() pending.mood = def.id RefreshMoodBtns() end)
        f.moodBtns[i] = btn
    end

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(90, 22) saveBtn:SetText(L["BTN_SAVE"])
    saveBtn:SetPoint("BOTTOMLEFT", f.InsetBg, "BOTTOMLEFT", 8, 8)
    saveBtn:SetScript("OnClick", SaveNote)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22) cancelBtn:SetText(L["BTN_CANCEL"])
    cancelBtn:SetPoint("BOTTOMRIGHT", f.InsetBg, "BOTTOMRIGHT", -8, 8)
    cancelBtn:SetScript("OnClick", function() f:Hide() wipe(pending) end)

    PD.noteDialog = f
end

function PD:OpenNoteDialog(name, realm, class, guid, defaultMood)
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local entry = PD:GetEntry(name, realm)
    pending.name  = name
    pending.realm = realm
    pending.class = class or (entry and entry.class) or "UNKNOWN"
    pending.guid  = guid  or (entry and entry.guid)  or ""
    pending.mood  = defaultMood or (entry and entry.mood) or "positive"
    if not PD.noteDialog then PD:BuildNoteDialog() end
    local f = PD.noteDialog
    f.TitleText:SetText(string.format(L["NOTE_TITLE"], name))
    f.editBox:SetText(entry and entry.note or "")
    f.editBox:SetFocus() f.editBox:HighlightText()
    RefreshMoodBtns() f:Show()
end

-- ================================================================
-- 3.  RECHTSKLICK-MENÜ
-- ================================================================

local function MoodMenuLabel(entry)
    if not entry then return L["MENU_ADD"] end
    local m = MOOD[entry.mood] or MOOD.neutral
    return string.format(L["MENU_EDIT"], "|cff"..m.hex..m.label.."|r")
end

local function InjectUnitMenu(_, rootDescription, contextData)
    local unit = contextData and contextData.unit
    if not unit then return end
    if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
    local name, realm = UnitName(unit)
    if not name then return end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local _, engClass = UnitClass(unit)
    local guid        = UnitGUID(unit)
    local entry       = PD:GetEntry(name, realm)
    rootDescription:CreateDivider()
    rootDescription:CreateTitle("|cff9B82F3PlayerDossier|r")
    rootDescription:CreateButton(MoodMenuLabel(entry), function()
        PD:OpenNoteDialog(name, realm, engClass, guid, entry and entry.mood or "positive")
    end)
    if entry then
        rootDescription:CreateButton(L["MENU_REMOVE"], function()
            PD:RemoveEntry(name, realm)
            if PD.mainFrame and PD.mainFrame:IsShown() then PD:RefreshMainWindow() end
        end)
    end
end

local function InjectChatMenu(_, rootDescription, contextData)
    local name  = contextData and contextData.name
    local realm = contextData and contextData.server
    if not name or name == UnitName("player") then return end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local entry    = PD:GetEntry(name, realm)
    local isIgn    = PD.IL_IsIgnored and PD:IL_IsIgnored(name, realm)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle("|cff9B82F3PlayerDossier|r")

    -- Dossier
    rootDescription:CreateButton(MoodMenuLabel(entry), function()
        PD:OpenNoteDialog(name, realm, entry and entry.class, entry and entry.guid,
                          entry and entry.mood or "positive")
    end)
    if entry then
        rootDescription:CreateButton(L["MENU_REMOVE"], function()
            PD:RemoveEntry(name, realm)
        end)
    end

    -- Ignore
    if isIgn then
        rootDescription:CreateButton(string.format(L["MENU_UNIGNORE_PLAYER"], name), function()
            PD:IL_Remove(name, realm)
        end)
    else
        rootDescription:CreateButton(string.format(L["MENU_IGNORE_PLAYER"], name), function()
            PD:IL_PromptIgnore(name, realm)
        end)
    end
end

local UNIT_MENUS = {
    "MENU_UNIT_PLAYER","MENU_UNIT_PARTY","MENU_UNIT_RAID",
    "MENU_UNIT_RAID_PLAYER","MENU_UNIT_FRIEND","MENU_UNIT_FRIEND_OFFLINE",
    "MENU_UNIT_GUILD","MENU_UNIT_TARGET",
    "MENU_UNIT_RECENT_ALLY",
}
for _, tag in ipairs(UNIT_MENUS) do
    pcall(Menu.ModifyMenu, tag, InjectUnitMenu)
end
Menu.ModifyMenu("MENU_UNIT_CHAT_ROSTER", InjectChatMenu)
pcall(Menu.ModifyMenu, "MENU_UNIT_GUILD", InjectChatMenu)

-- ----------------------------------------------------------------
-- Social-Frame-Hook (Freundesliste + Kürzliche Verbündete)
-- Liest Name/Realm/Klasse aus allen bekannten contextData-Formaten.
-- ----------------------------------------------------------------
local function InjectSocialMenu(_, rootDescription, contextData)
    if not contextData then return end

    local name, realm, class

    -- Format A: Kürzliche Verbündete → characterData-Objekt
    if contextData.characterData then
        local cd = contextData.characterData
        name  = cd.name
        realm = cd.realm
        class = cd.classFilename or cd.className
    end

    -- Format B: name/server direkt im contextData
    if not name and contextData.name then
        name  = contextData.name
        realm = contextData.server or contextData.realm
    end

    -- Format C: unit-Token (z.B. friend1…friend10)
    if not name and contextData.unit then
        local u = contextData.unit
        local ok, isPlayer = pcall(UnitIsPlayer, u)
        if ok and isPlayer and not UnitIsUnit(u, "player") then
            local n, r = UnitName(u)
            if n then
                name  = n
                realm = r
                local _, engClass = UnitClass(u)
                class = engClass
            end
        end
    end

    if not name or name == UnitName("player") then return end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()

    -- Nicht duplizieren wenn InjectUnitMenu es bereits abgedeckt hat
    if contextData.unit and not contextData.characterData and not contextData.name then
        return
    end

    local entry = PD:GetEntry(name, realm)
    rootDescription:CreateDivider()
    rootDescription:CreateTitle("|cff9B82F3PlayerDossier|r")
    rootDescription:CreateButton(MoodMenuLabel(entry), function()
        local useClass = class or (entry and entry.class)
        PD:OpenNoteDialog(name, realm, useClass, entry and entry.guid,
                          entry and entry.mood or "positive")
    end)
    if entry then
        rootDescription:CreateButton(L["MENU_REMOVE"], function()
            PD:RemoveEntry(name, realm)
            if PD.mainFrame and PD.mainFrame:IsShown() then
                PD:RefreshMainWindow()
            end
        end)
    end
end

for _, tag in ipairs({
    "MENU_UNIT_FRIEND", "MENU_UNIT_FRIEND_OFFLINE", "MENU_UNIT_RECENT_ALLY",
}) do
    pcall(Menu.ModifyMenu, tag, InjectSocialMenu)
end

-- ================================================================
-- 4.  WHISPER HELPER
-- ================================================================

local function WhisperPlayer(name, realm)
    -- Realm-Vergleich case-insensitive und mit normalisierten Leerzeichen
    local myRealm = PD.GetMyRealm() or ""
    local entryRealm = realm or ""
    local crossRealm = entryRealm ~= ""
        and entryRealm:lower():gsub("%s", "") ~= myRealm:lower():gsub("%s", "")

    local target = crossRealm and (name .. "-" .. entryRealm) or name

    -- ChatFrame_OpenChat ist zuverlässiger als direktes EditBox-Manipulieren
    ChatFrame_OpenChat("/w " .. target .. " ", DEFAULT_CHAT_FRAME)
end

-- ================================================================
-- 5.  HAUPT-FENSTER MIT TABS
-- ================================================================

local function MakePanel(parent)
    local p = CreateFrame("Frame", nil, parent)
    p:SetPoint("TOPLEFT",     parent.InsetBg, "TOPLEFT",     0, -18)
    p:SetPoint("BOTTOMRIGHT", parent.InsetBg, "BOTTOMRIGHT",  0,   0)
    p:Hide()
    return p
end

function PD:BuildUI()
    if PD.mainFrame then return end

    local f = CreateFrame("Frame", "PDMainFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(620, 460)
    f:SetPoint("CENTER")
    f:SetMovable(true) f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG") f:Hide()

    -- Titelleiste komplett durchziehen (CloseButton liegt standardmäßig drüber)
    f.TitleText:SetText("PlayerDossier")
    f.TitleText:ClearAllPoints()
    f.TitleText:SetPoint("LEFT",  f.TitleBg, "LEFT",  5, 0)
    f.TitleText:SetPoint("RIGHT", f.TitleBg, "RIGHT", -5, 0)
    f.TitleText:SetJustifyH("CENTER")

    -- ESC schliesst das Fenster (WoW-Standard über UISpecialFrames)
    tinsert(UISpecialFrames, "PDMainFrame")

    -- Subtitle
    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.subtitle:SetPoint("TOP", f.InsetBg, "TOP", 0, -4)

    -- Drei Panels
    local p1 = MakePanel(f)
    local p2 = MakePanel(f)
    local p3 = MakePanel(f)
    f.panels = { p1, p2, p3 }

    -- Tab-Buttons (PanelTabButtonTemplate – klassisches WoW-Look)
    local tabLabels = { L["TAB_PLAYERS"], L["TAB_IGNORE"], L["TAB_OPTIONS"] }
    f.tabs = {}
    -- Tabs: erst alle erstellen, dann auf breitesten Text angleichen
    for i, label in ipairs(tabLabels) do
        local tab = CreateFrame("Button", "PDMainTab"..i, f, "PanelTabButtonTemplate")
        tab:SetText(label)
        tab:SetID(i)
        tab:SetScript("OnClick", function() PD:SelectTab(i) end)
        f.tabs[i] = tab
    end

    -- Textbreite korrekt messen via GetStringWidth (vor Rendering verfügbar)
    local maxW = 80
    for _, tab in ipairs(f.tabs) do
        local fs = tab:GetFontString()
        if fs then
            maxW = math.max(maxW, fs:GetStringWidth())
        end
    end
    -- 30px Padding links+rechts damit Text nicht abgeschnitten wird
    maxW = math.ceil(maxW) + 30

    for i, tab in ipairs(f.tabs) do
        tab:SetWidth(maxW)
        PanelTemplates_TabResize(tab, 0)
        if i == 1 then
            tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, -28)
        else
            tab:SetPoint("LEFT", f.tabs[i-1], "RIGHT", 2, 0)
        end
    end
    PanelTemplates_SetNumTabs(f, 3)

    PD.mainFrame  = f
    PD.panel1     = p1   -- Players
    PD.panel2     = p2   -- Ignore List
    PD.panel3     = p3   -- Chat Filters

    -- Panel-Inhalte bauen
    PD:BuildPlayersPanel(p1)
    PD:BuildNoteDialog()

    f:SetScript("OnShow", function() PD:SelectTab(PD._activeTab or 1) end)
end

-- ----------------------------------------------------------------
function PD:SelectTab(n)
    local f = PD.mainFrame
    if not f then return end
    PD._activeTab = n
    PanelTemplates_SetTab(f, n)
    -- Tab-Text bleibt zentriert (PanelTabButtonTemplate verschiebt ihn beim Aktivieren)
    for i, tab in ipairs(f.tabs) do
        local fs = tab:GetFontString()
        if fs then fs:SetPoint("CENTER", tab, "CENTER", 0, i == n and 0 or 1) end
    end
    for i, panel in ipairs(f.panels) do
        if i == n then panel:Show() else panel:Hide() end
    end
    -- Tab 1 = Players, Tab 2 = Ignore List, Tab 3 = Chat Filters
    if n == 1 then
        PD:RefreshMainWindow()
    elseif n == 2 then
        if PD.BuildIgnorePanel and not PD._il_built then
            PD:BuildIgnorePanel(PD.panel2)
            PD._il_built = true
        end
        if PD.RefreshIgnorePanel then PD:RefreshIgnorePanel() end
    elseif n == 3 then
        if PD.BuildOptionsPanel and not PD._opt_built then
            PD:BuildOptionsPanel(PD.panel3)
            PD._opt_built = true
        end
        if PD.RefreshOptionsPanel then PD:RefreshOptionsPanel() end
    end
    -- Subtitle
    if n == 1 then
        local c = PD:Count()
        f.subtitle:SetText(c == 0 and L["SUB_NO_ENTRIES"] or (c == 1 and L["SUB_1_ENTRY"] or string.format(L["SUB_N_ENTRIES"], c)))
    elseif n == 2 then
        local c = PD.IL_Count and PD:IL_Count() or 0
        f.subtitle:SetText(c == 0 and L["SUB_NO_IGNORED"] or
            (c == 1 and L["SUB_1_IGNORED"] or string.format(L["SUB_N_IGNORED"], c)))
    elseif n == 3 then
        f.subtitle:SetText(L["OPT_SEC_MESSAGES"])
    end
end

-- Compat: andere Module rufen diese Funktionen auf
function PD:ToggleMainWindow()       PD:OpenOnTab(1) end
function PD:ToggleChatFilterWindow() PD:OpenOnTab(3) end  -- Chat Filters = Tab 3
function PD:ToggleIgnoreWindow()     PD:OpenOnTab(2) end  -- Ignore List  = Tab 2

function PD:OpenOnTab(n)
    if not PD.mainFrame then return end
    if PD.mainFrame:IsShown() and PD._activeTab == n then
        PD.mainFrame:Hide()
    else
        PD.mainFrame:Show()
        PD:SelectTab(n)
    end
end

-- ================================================================
-- 6.  PANEL 1: PLAYERS
-- ================================================================

local rowPool = {}
local function GetRow(parent)
    for _, r in ipairs(rowPool) do
        if not r:IsShown() then r:SetParent(parent) r:Show() return r end
    end
    local r = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    table.insert(rowPool, r)
    return r
end
local function HideAllRows() for _, r in ipairs(rowPool) do r:Hide() end end

-- Spaltenoffsets Players-Panel
local PL_COL_MOOD  = 4    -- Emoji
local PL_COL_NAME  = 58   -- Spielername (mehr Platz für 48px Emoji)
local PL_COL_REALM = 220  -- Server
local PL_COL_SINCE = 370  -- Seit (Tage)
local PL_COL_NOTE  = 428  -- Notiz
local PL_ROW_H     = 52   -- Zeilenhöhe für 48px Emoji
local PL_ROW_PAD   = 2

local function PL_DaysSince(ts)
    if not ts then return "?" end
    local diff = time() - ts
    if diff < 3600 then
        return "<1h"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. "h"
    else
        return math.floor(diff / 86400) .. "d"
    end
end

function PD:BuildPlayersPanel(panel)
    -- Spaltenköpfe
    local heads = {
        { text=L["PL_COL_NAME"],  x=PL_COL_NAME  },
        { text=L["PL_COL_REALM"], x=PL_COL_REALM },
        { text=L["PL_COL_SINCE"], x=PL_COL_SINCE },
        { text=L["PL_COL_NOTE"],  x=PL_COL_NOTE  },
    }
    for _, h in ipairs(heads) do
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", h.x + 2, -4)
        fs:SetText(h.text)
        fs:SetTextColor(0.9, 0.82, 0.5)
    end

    -- Trennlinie
    local sep = panel:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  panel, "TOPLEFT",  4,  -18)
    sep:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -26, -18)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    -- Scrollframe
    local sf = CreateFrame("ScrollFrame", "PDScrollFrame", panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     panel, "TOPLEFT",     4,  -22)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 32)
    local content = CreateFrame("Frame", "PDScrollContent", sf)
    content:SetWidth(sf:GetWidth())
    content:SetHeight(1)
    sf:SetScrollChild(content)
    panel.scrollContent = content

    -- "Alle entfernen"-Button
    local clearBtn = CreateFrame("Button", "PDClearPlayersBtn", panel, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 22)
    clearBtn:SetText(L["BTN_CLEAR_ALL"])
    clearBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 6)
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("PD_CONFIRM_CLEAR_PLAYERS")
    end)
end

function PD:RefreshMainWindow()
    local myRealm = PD.GetMyRealm()
    local f  = PD.mainFrame
    local p1 = PD.panel1
    if not p1 then return end
    local content = p1.scrollContent
    HideAllRows()
    if p1.emptyLabel then p1.emptyLabel:Hide() end

    local MOOD_ORDER = { positive=1, neutral=2, negative=3 }
    local entries = PD:GetAllEntries()
    local list = {}
    for key, entry in pairs(entries) do list[#list+1] = {key=key, e=entry} end
    table.sort(list, function(a, b)
        local ma, mb = MOOD_ORDER[a.e.mood] or 2, MOOD_ORDER[b.e.mood] or 2
        if ma ~= mb then return ma < mb end
        return (a.e.timestamp or 0) > (b.e.timestamp or 0)
    end)

    local count = #list
    if f then
        f.subtitle:SetText(count==0 and L["SUB_NO_ENTRIES"] or
            (count==1 and L["SUB_1_ENTRY"] or string.format(L["SUB_N_ENTRIES"], count)))
    end

    if count == 0 then
        if not p1.emptyLabel then
            p1.emptyLabel = content:CreateFontString(nil,"OVERLAY","GameFontDisable")
            p1.emptyLabel:SetPoint("TOP", content, "TOP", 0, -60)
            p1.emptyLabel:SetText(L["EMPTY_PLAYERS"])
            p1.emptyLabel:SetJustifyH("CENTER")
        end
        p1.emptyLabel:Show()
        content:SetHeight(160)
        return
    end

    local rowW = content:GetWidth() - 4
    local yOff = -PL_ROW_PAD

    for i, item in ipairs(list) do
        local e   = item.e
        local row = GetRow(content)
        row:SetSize(rowW, PL_ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOff)
        row:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background"})
        if i%2==0 then row:SetBackdropColor(0.08,0.08,0.10,0.55)
        else            row:SetBackdropColor(0.13,0.13,0.17,0.55) end

        -- Mood-Emoji
        if not row.moodTex then
            row.moodTex = row:CreateTexture(nil,"ARTWORK")
            row.moodTex:SetSize(48, 48)
            row.moodTex:SetPoint("LEFT", row,"LEFT", PL_COL_MOOD, 0)
        end
        local m = MOOD[e.mood] or MOOD.neutral
        row.moodTex:SetTexture(m.tex)

        -- Name
        if not row.nameLabel then
            row.nameLabel = row:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
            row.nameLabel:SetPoint("LEFT", row,"LEFT", PL_COL_NAME, 0)
            row.nameLabel:SetWidth(PL_COL_REALM - PL_COL_NAME - 4)
            row.nameLabel:SetJustifyH("LEFT")
        end
        local cc = PD:OPT_Get("classColors") and RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
        if cc then row.nameLabel:SetTextColor(cc.r,cc.g,cc.b)
        else       row.nameLabel:SetTextColor(1,1,1) end
        row.nameLabel:SetText(e.name or "?")

        -- Realm
        if not row.realmLabel then
            row.realmLabel = row:CreateFontString(nil,"OVERLAY","GameFontNormal")
            row.realmLabel:SetPoint("LEFT", row,"LEFT", PL_COL_REALM, 0)
            row.realmLabel:SetWidth(PL_COL_SINCE - PL_COL_REALM - 4)
            row.realmLabel:SetJustifyH("LEFT")
            row.realmLabel:SetTextColor(0.78,0.78,0.78)
        end
        row.realmLabel:SetText(
            (e.realm and e.realm ~= myRealm) and e.realm or myRealm
        )

        -- Seit (Tage)
        if not row.sinceLabel then
            row.sinceLabel = row:CreateFontString(nil,"OVERLAY","GameFontNormal")
            row.sinceLabel:SetPoint("LEFT", row,"LEFT", PL_COL_SINCE, 0)
            row.sinceLabel:SetWidth(PL_COL_NOTE - PL_COL_SINCE - 4)
            row.sinceLabel:SetJustifyH("LEFT")
            row.sinceLabel:SetTextColor(0.78,0.78,0.78)
        end
        row.sinceLabel:SetText(PL_DaysSince(e.timestamp))

        -- Notiz
        if not row.noteLabel then
            row.noteLabel = row:CreateFontString(nil,"OVERLAY","GameFontNormal")
            row.noteLabel:SetPoint("LEFT",  row,"LEFT",  PL_COL_NOTE, 0)
            row.noteLabel:SetPoint("RIGHT", row,"RIGHT", -6, 0)
            row.noteLabel:SetJustifyH("LEFT")
            row.noteLabel:SetTextColor(0.60,0.60,0.60)
            row.noteLabel:SetWordWrap(false)
        end
        local noteText = (e.note and e.note ~= "") and e.note or "|cff444444-|r"
        row.noteLabel:SetText(noteText)

        -- Rechtsklick-Menü
        row:EnableMouse(true)
        local eName, eRealm, eClass, eGuid, eMood = e.name, e.realm, e.class, e.guid, e.mood
        row:SetScript("OnMouseUp", function(self, btn)
            if btn ~= "RightButton" then return end
            MenuUtil.CreateContextMenu(UIParent, function(_, root)
                root:CreateTitle("|cff9B82F3"..eName.."|r")

                root:CreateButton(L["BTN_EDIT"], function()
                    PD:OpenNoteDialog(eName, eRealm, eClass, eGuid, eMood)
                end)

                local isIgn = PD.IL_IsIgnored and PD:IL_IsIgnored(eName, eRealm)

                if not isIgn then
                    root:CreateButton(L["BTN_WHISPER"], function()
                        WhisperPlayer(eName, eRealm)
                    end)
                else
                    root:CreateButton("|cffaaaaaa"..L["BTN_WHISPER"].." ("..L["IL_IGNORED_HINT"]..")|r", function()
                        -- Kein Flüstern möglich – Spieler ist ignoriert
                    end)
                end

                root:CreateButton(isIgn and L["BTN_UNIGNORE"] or L["BTN_IGNORE"], function()
                    if PD:IL_IsIgnored(eName, eRealm) then
                        PD:IL_Remove(eName, eRealm)
                    else
                        PD:IL_PromptIgnore(eName, eRealm)
                    end
                    PD:RefreshMainWindow()
                end)

                root:CreateDivider()

                root:CreateButton("|cffff4444"..L["MENU_REMOVE"].."|r", function()
                    PD:RemoveEntry(eName, eRealm)
                    PD:RefreshMainWindow()
                end)
            end)
        end)

        -- Hover-Highlight damit klar ist dass man rechtsklicken kann
        if not row.hlTex then
            row.hlTex = row:CreateTexture(nil, "HIGHLIGHT")
            row.hlTex:SetAllPoints()
            row.hlTex:SetColorTexture(1, 1, 1, 0.05)
            row.hlTex:SetBlendMode("ADD")
        end

        yOff = yOff - PL_ROW_H - PL_ROW_PAD
    end
    content:SetHeight(math.abs(yOff) + PL_ROW_PAD)
end

-- ============================================================
--  PlayerDossier – UI.lua
--  Unit tooltip, note dialog, right-click menus, main window with
--  4 tabs (Players / Ignore List / History / Options) and the
--  Players panel. The other panels are built in IgnoreList.lua,
--  GroupHistory.lua and Options.lua.
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- ================================================================
-- 1.  UNIT TOOLTIP  (no Unit* API → no taint)
-- ================================================================

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    if not data then return end

    -- data.guid is a secret value in tainted contexts → pcall
    local ok, guid = pcall(function() return data.guid end)
    if not ok or not guid then return end

    -- Player GUIDs only
    local okMatch, guidType = pcall(string.match, guid, "^(%a+)-")
    if not okMatch or guidType ~= "Player" then return end

    local okInfo, _, _, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
    if not okInfo or not name then return end

    local entry = PD:GetEntry(name, realm)
    if not entry then return end

    local line = string.format("|cff9B82F3[PD]|r %s |cff%s%s|r",
        PD:MoodIcon(entry.mood, 14), PD:GetMood(entry.mood).hex, name)
    if entry.note and entry.note ~= "" then
        line = line .. " |cffaaaaaa- " .. entry.note .. "|r"
    end
    tooltip:AddLine(line, 1, 1, 1, true)
end)

-- ================================================================
-- 2.  NOTE DIALOG
-- ================================================================

local pending = {}   -- player currently being edited

local MOOD_BUTTONS = { "positive", "neutral", "negative" }
local MOOD_SELECTED_ALPHA   = 1.0
local MOOD_UNSELECTED_ALPHA = 0.40

local function RefreshMoodBtns()
    local f = PD.noteDialog
    if not f then return end
    for _, btn in ipairs(f.moodBtns) do
        local fs = btn:GetFontString()
        if btn.moodId == pending.mood then
            btn:LockHighlight()
            btn:SetAlpha(MOOD_SELECTED_ALPHA)
            fs:SetFont(fs:GetFont(), 13, "OUTLINE")
        else
            btn:UnlockHighlight()
            btn:SetAlpha(MOOD_UNSELECTED_ALPHA)
            fs:SetFont(fs:GetFont(), 11, "")
        end
    end
end

-- Finds the class token for a player: known class → GUID → current group
local function ResolveClass(name, realm, class, guid)
    if class and class ~= "UNKNOWN" and class ~= "" then return class end

    if guid and guid ~= "" then
        local ok, _, _, _, _, engClass = pcall(GetPlayerInfoByGUID, guid)
        if ok and engClass and engClass ~= "" then return engClass end
    end

    realm = PD.NormRealm(realm)
    local found
    PD:ForEachGroupMember(function(unit, n, r)
        if not found and n == name and r == realm then
            found = select(2, UnitClass(unit))
        end
    end)
    return found or class or "UNKNOWN"
end

local function CloseNoteDialog()
    PD.noteDialog:Hide()
    wipe(pending)
end

local function SaveNote()
    local note  = strtrim(PD.noteDialog.editBox:GetText())
    local class = ResolveClass(pending.name, pending.realm, pending.class, pending.guid)
    PD:SetEntry(pending.name, pending.realm, note, pending.mood, class, pending.guid)
    if PD.mainFrame and PD.mainFrame:IsShown() then PD:RefreshMainWindow() end
    CloseNoteDialog()
end

function PD:BuildNoteDialog()
    if PD.noteDialog then return end
    local f = CreateFrame("Frame", "PDNoteDialog", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(340, 185)
    f:SetPoint("CENTER")
    PD:MakeDraggable(f)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:Hide()
    f:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then CloseNoteDialog() end
    end)
    f:SetPropagateKeyboardInput(true)

    f.editBox = CreateFrame("EditBox", "PDNoteEditBox", f, "InputBoxTemplate")
    f.editBox:SetSize(295, 20)
    f.editBox:SetPoint("TOP", f.InsetBg, "TOP", 0, -12)
    f.editBox:SetMaxLetters(60)
    f.editBox:SetAutoFocus(false)
    f.editBox:SetScript("OnEscapePressed", CloseNoteDialog)
    f.editBox:SetScript("OnEnterPressed",  SaveNote)

    f.moodBtns = {}
    for i, moodId in ipairs(MOOD_BUTTONS) do
        local mood = PD.MOOD[moodId]
        local btn  = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(86, 22)
        btn:SetText(L[mood.labelKey])
        btn:GetFontString():SetTextColor(mood.r, mood.g, mood.b)
        btn:SetPoint("TOPLEFT", f.editBox, "BOTTOMLEFT", (i - 1) * 90, -10)
        btn.moodId = moodId
        btn:SetScript("OnClick", function() pending.mood = moodId RefreshMoodBtns() end)
        f.moodBtns[i] = btn
    end

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(90, 22)
    saveBtn:SetText(L["BTN_SAVE"])
    saveBtn:SetPoint("BOTTOMLEFT", f.InsetBg, "BOTTOMLEFT", 8, 8)
    saveBtn:SetScript("OnClick", SaveNote)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22)
    cancelBtn:SetText(L["BTN_CANCEL"])
    cancelBtn:SetPoint("BOTTOMRIGHT", f.InsetBg, "BOTTOMRIGHT", -8, 8)
    cancelBtn:SetScript("OnClick", CloseNoteDialog)

    PD.noteDialog = f
end

function PD:OpenNoteDialog(name, realm, class, guid, defaultMood)
    realm = PD.NormRealm(realm)
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
    f.editBox:SetFocus()
    f.editBox:HighlightText()
    RefreshMoodBtns()
    f:Show()
end

-- ================================================================
-- 3.  RIGHT-CLICK MENUS
-- ================================================================

local function MoodMenuLabel(entry)
    if not entry then return L["MENU_ADD"] end
    local mood = PD:GetMood(entry.mood)
    return string.format(L["MENU_EDIT"], "|cff" .. mood.hex .. L[mood.labelKey] .. "|r")
end

local function IsPlayerName(name)
    local me = UnitName("player")
    return not PD.IsSecret(me) and name == me
end

-- Adds the "PlayerDossier" section (add/edit note, remove) to a menu.
-- All callbacks go through securecallfunction so Blizzard's menu code
-- isn't tainted by ours.
local function AddDossierMenu(root, name, realm, class, guid)
    local entry = PD:GetEntry(name, realm)
    root:CreateDivider()
    root:CreateTitle("|cff9B82F3PlayerDossier|r")
    root:CreateButton(MoodMenuLabel(entry), function()
        securecallfunction(PD.OpenNoteDialog, PD, name, realm, class, guid,
            entry and entry.mood or "positive")
    end)
    if entry then
        root:CreateButton(L["MENU_REMOVE"], function()
            securecallfunction(PD.RemoveEntry, PD, name, realm)
            if PD.mainFrame and PD.mainFrame:IsShown() then
                securecallfunction(PD.RefreshMainWindow, PD)
            end
        end)
    end
end

-- Unit menus (unit frames, party/raid frames, target, ...)
local function InjectUnitMenu(_, root, contextData)
    local unit = contextData and contextData.unit
    if not unit then return end
    local ok1, isPlayer = pcall(UnitIsPlayer, unit)
    local ok2, isSelf   = pcall(UnitIsUnit, unit, "player")
    if not ok1 or not isPlayer or (ok2 and isSelf) then return end
    local name, realm, ok = PD:SafeUnitName(unit)
    if not ok or not name then return end   -- name unreadable right now (e.g. active PvP match)
    local _, engClass = UnitClass(unit)
    AddDossierMenu(root, name, PD.NormRealm(realm), engClass, UnitGUID(unit))
end

-- Chat roster / guild menus: contextData.name / .server
local function InjectChatMenu(_, root, contextData)
    local name  = contextData and contextData.name
    local realm = contextData and contextData.server
    if PD.IsSecret(name) or PD.IsSecret(realm) then return end   -- e.g. active PvP match
    if not name or IsPlayerName(name) then return end
    realm = PD.NormRealm(realm)

    AddDossierMenu(root, name, realm)

    if PD:IL_IsIgnored(name, realm) then
        root:CreateButton(string.format(L["MENU_UNIGNORE_PLAYER"], name), function()
            securecallfunction(PD.IL_Remove, PD, name, realm)
        end)
    else
        root:CreateButton(string.format(L["MENU_IGNORE_PLAYER"], name), function()
            securecallfunction(PD.IL_PromptIgnore, PD, name, realm)
        end)
    end
end

-- Friends list / recent allies. Reads name/realm/class from every known
-- contextData format.
local function InjectSocialMenu(_, root, contextData)
    if not contextData then return end

    local name, realm, class

    -- Format A: recent allies → characterData
    local cd = contextData.characterData
    if cd then
        name  = cd.name
        realm = cd.realm
        class = cd.classFilename or cd.className
    end

    -- Format B: name/server directly in contextData
    if not name and contextData.name then
        name  = contextData.name
        realm = contextData.server or contextData.realm
    end

    -- Format C: unit token only (friend1…friend10) → already covered by
    -- InjectUnitMenu, don't add the section twice.
    if not name then return end

    if PD.IsSecret(name) or PD.IsSecret(realm) then return end   -- e.g. active PvP match
    if IsPlayerName(name) then return end
    realm = PD.NormRealm(realm)

    local entry = PD:GetEntry(name, realm)
    AddDossierMenu(root, name, realm, class or (entry and entry.class), entry and entry.guid)
end

-- Registration order matters: for the friend menus the unit injector
-- runs first, then the social one.
local MENU_INJECTORS = {
    { InjectUnitMenu, {
        "MENU_UNIT_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID", "MENU_UNIT_RAID_PLAYER",
        "MENU_UNIT_FRIEND", "MENU_UNIT_FRIEND_OFFLINE", "MENU_UNIT_GUILD",
        "MENU_UNIT_TARGET", "MENU_UNIT_RECENT_ALLY",
    } },
    { InjectChatMenu,   { "MENU_UNIT_CHAT_ROSTER", "MENU_UNIT_GUILD" } },
    { InjectSocialMenu, { "MENU_UNIT_FRIEND", "MENU_UNIT_FRIEND_OFFLINE", "MENU_UNIT_RECENT_ALLY" } },
}
for _, group in ipairs(MENU_INJECTORS) do
    for _, tag in ipairs(group[2]) do
        pcall(Menu.ModifyMenu, tag, group[1])
    end
end

-- ================================================================
-- 4.  WHISPER
-- ================================================================

local function WhisperPlayer(name, realm)
    -- ChatFrame_OpenChat is more reliable than poking the edit box directly
    ChatFrame_OpenChat("/w " .. PD.TargetName(name, realm) .. " ", DEFAULT_CHAT_FRAME)
end

-- ================================================================
-- 5.  MAIN WINDOW WITH TABS
-- ================================================================

local activeTab   -- index of the selected tab

-- Tab definition: label key, panel builder (lazy, optional), refresh function
local TABS = {
    { label = "TAB_DOSSIER", refresh = "RefreshMainWindow" },
    { label = "TAB_IGNORE",  build = "BuildIgnorePanel",  refresh = "RefreshIgnorePanel" },
    { label = "TAB_HISTORY", build = "BuildHistoryPanel", refresh = "RefreshHistoryPanel" },
    { label = "TAB_OPTIONS", build = "BuildOptionsPanel", refresh = "RefreshOptionsPanel" },
}

local function MakePanel(parent)
    local p = CreateFrame("Frame", nil, parent)
    p:SetPoint("TOPLEFT",     parent.InsetBg, "TOPLEFT",     0, -18)
    p:SetPoint("BOTTOMRIGHT", parent.InsetBg, "BOTTOMRIGHT", 0,   0)
    p:Hide()
    return p
end

function PD:BuildUI()
    if PD.mainFrame then return end

    local f = CreateFrame("Frame", "PDMainFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(620, 460)
    f:SetPoint("CENTER")
    PD:MakeDraggable(f)
    f:SetFrameStrata("DIALOG")
    f:Hide()

    -- Stretch the title across the whole bar (the close button sits on top by default)
    f.TitleText:SetText("PlayerDossier")
    f.TitleText:ClearAllPoints()
    f.TitleText:SetPoint("LEFT",  f.TitleBg, "LEFT",  5, 0)
    f.TitleText:SetPoint("RIGHT", f.TitleBg, "RIGHT", -5, 0)
    f.TitleText:SetJustifyH("CENTER")

    -- ESC closes the window (WoW standard via UISpecialFrames)
    tinsert(UISpecialFrames, "PDMainFrame")

    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.subtitle:SetPoint("TOP", f.InsetBg, "TOP", 0, -4)

    -- One panel per tab (PD.panel1 … PD.panel4)
    f.panels = {}
    for i = 1, #TABS do
        f.panels[i] = MakePanel(f)
        PD["panel" .. i] = f.panels[i]
    end

    -- Tab buttons (PanelTabButtonTemplate, classic WoW look)
    f.tabs = {}
    for i, def in ipairs(TABS) do
        local tab = CreateFrame("Button", "PDMainTab" .. i, f, "PanelTabButtonTemplate")
        tab:SetText(L[def.label])
        tab:SetID(i)
        tab:SetScript("OnClick", function() PD:SelectTab(i) end)
        f.tabs[i] = tab
    end

    -- All tabs get the width of the widest label (+30px padding so no text is cut off)
    local maxW = 80
    for _, tab in ipairs(f.tabs) do
        local fs = tab:GetFontString()
        if fs then maxW = math.max(maxW, fs:GetStringWidth()) end
    end
    maxW = math.ceil(maxW) + 30

    for i, tab in ipairs(f.tabs) do
        tab:SetWidth(maxW)
        PanelTemplates_TabResize(tab, 0)
        if i == 1 then
            tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, -28)
        else
            tab:SetPoint("LEFT", f.tabs[i - 1], "RIGHT", 2, 0)
        end
    end
    PanelTemplates_SetNumTabs(f, #TABS)

    PD.mainFrame = f

    PD:BuildPlayersPanel(PD.panel1)
    PD:BuildNoteDialog()

    f:SetScript("OnShow", function() PD:SelectTab(activeTab or 1) end)

    PD:RunBuildCallbacks()
end

function PD:SelectTab(n)
    local f = PD.mainFrame
    if not f then return end
    activeTab = n
    PanelTemplates_SetTab(f, n)

    -- Keep the tab text centered (PanelTabButtonTemplate shifts it when selected)
    for i, tab in ipairs(f.tabs) do
        local fs = tab:GetFontString()
        if fs then fs:SetPoint("CENTER", tab, "CENTER", 0, i == n and 0 or 1) end
    end
    for i, panel in ipairs(f.panels) do
        panel:SetShown(i == n)
    end

    -- Build lazily on first visit, then refresh (refreshing also sets the subtitle)
    local def, panel = TABS[n], f.panels[n]
    if def.build and not panel._built then
        panel._built = true
        PD[def.build](PD, panel)
    end
    PD[def.refresh](PD)
    if n == 4 then PD:SetSubtitle(L["TAB_OPTIONS"]) end
end

function PD:OpenOnTab(n)
    if not PD.mainFrame then return end
    if PD.mainFrame:IsShown() and activeTab == n then
        PD.mainFrame:Hide()
    else
        PD.mainFrame:Show()
        PD:SelectTab(n)
    end
end

function PD:ToggleMainWindow() PD:OpenOnTab(1) end

-- ================================================================
-- 6.  PLAYERS PANEL
-- ================================================================

local GetRow, HideAllRows = PD:NewRowPool()

local COL_MOOD  = 4    -- mood icon (Dossier tab only)
local COL_NAME  = PD.COL.NAME
local COL_REALM = PD.COL.REALM
local COL_ROLE  = PD.COL.ROLE
local COL_SINCE = PD.COL.SINCE
local COL_NOTE  = PD.COL.LAST
local ROW_H     = 52   -- fits the 48px mood icon
local ROW_PAD   = 2

local SORT_DEFAULT = { key = "since", asc = false }   -- newest first

local function Lower(s) return (s or ""):lower() end

local SORT_GETTERS = {
    name  = function(e) return Lower(e.name) end,
    realm = function(e) return Lower(e.realm) end,
    role  = function(e)
        local h = PD:GH_GetEntry(e.name, e.realm)
        return Lower(h and h.role)
    end,
    since = function(e) return e.timestamp or 0 end,
    note  = function(e) return Lower(e.note) end,
}

function PD:BuildPlayersPanel(panel)
    panel.scrollContent = PD:BuildListPanel(panel, {
        heads = {
            { text = L["PL_COL_NAME"],  x = COL_NAME,  key = "name"  },
            { text = L["PL_COL_REALM"], x = COL_REALM, key = "realm" },
            { text = L["PL_COL_ROLE"],  x = COL_ROLE,  key = "role"  },
            { text = L["PL_COL_SINCE"], x = COL_SINCE, key = "since", descFirst = true },
            { text = L["PL_COL_NOTE"],  x = COL_NOTE,  key = "note"  },
        },
        sort = {
            id       = "players",
            default  = SORT_DEFAULT,
            onChange = function() PD:RefreshMainWindow() end,
        },
        scroll     = "PDScrollFrame",
        content    = "PDScrollContent",
        clearBtn   = "PDClearPlayersBtn",
        clearPopup = "PD_CONFIRM_CLEAR_PLAYERS",
    })
end

local function FillPlayerRow(row, e)
    if not row.moodTex then
        row.moodTex = row:CreateTexture(nil, "ARTWORK")
        row.moodTex:SetSize(48, 48)
        row.moodTex:SetPoint("LEFT", row, "LEFT", COL_MOOD, 0)
    end
    row.moodTex:SetTexture(PD:GetMood(e.mood).tex)

    local nameLabel = PD:RowLabel(row, "nameLabel", COL_NAME, COL_REALM, "GameFontNormalLarge")
    PD:ApplyNameColor(nameLabel, e.class)
    nameLabel:SetText(e.name or "?")

    PD:RowLabel(row, "realmLabel", COL_REALM, COL_ROLE, nil, 0.78, 0.78, 0.78)
        :SetText(e.realm or PD.GetMyRealm())

    -- Role (from the group history, if known)
    local hEntry = PD:GH_GetEntry(e.name, e.realm)
    PD:RowLabel(row, "roleLabel", COL_ROLE, COL_SINCE):SetText(PD:GH_RoleText(hEntry and hEntry.role))

    PD:RowLabel(row, "sinceLabel", COL_SINCE, COL_NOTE, nil, 0.78, 0.78, 0.78)
        :SetText(PD:TimeAgo(e.timestamp))

    local noteLabel = PD:RowLabel(row, "noteLabel", COL_NOTE, nil, nil, 0.60, 0.60, 0.60)
    noteLabel:SetWordWrap(false)
    noteLabel:SetText((e.note and e.note ~= "") and e.note or "|cff444444-|r")

    local eName, eRealm, eClass, eGuid, eMood = e.name, e.realm, e.class, e.guid, e.mood
    PD:SetRowMenu(row, function(root)
        root:CreateTitle("|cff9B82F3" .. eName .. "|r")

        root:CreateButton(L["BTN_EDIT"], function()
            PD:OpenNoteDialog(eName, eRealm, eClass, eGuid, eMood)
        end)

        local isIgn = PD:IL_IsIgnored(eName, eRealm)
        if isIgn then
            -- Whispering ignored players isn't possible (disabled entry)
            root:CreateButton("|cffaaaaaa" .. L["BTN_WHISPER"] .. " (" .. L["IL_IGNORED_HINT"] .. ")|r", function() end)
        else
            root:CreateButton(L["BTN_WHISPER"], function() WhisperPlayer(eName, eRealm) end)
        end

        root:CreateButton(isIgn and L["BTN_UNIGNORE"] or L["BTN_IGNORE"], function()
            if isIgn then
                PD:IL_Remove(eName, eRealm)
            else
                PD:IL_PromptIgnore(eName, eRealm)
            end
            PD:RefreshMainWindow()
        end)

        root:CreateDivider()
        root:CreateButton(L["BTN_COPY_NAME"], function()
            PD:ShowCopyPopup(eName .. "-" .. eRealm)
        end)
        root:CreateButton("|cffff4444" .. L["MENU_REMOVE"] .. "|r", function()
            PD:RemoveEntry(eName, eRealm)
            PD:RefreshMainWindow()
        end)
    end)
end

function PD:RefreshMainWindow()
    local p1 = PD.panel1
    if not p1 then return end
    local content = p1.scrollContent
    HideAllRows()
    PD:HideEmptyLabel(p1)

    local list = {}
    for _, entry in pairs(PD:GetAllEntries()) do list[#list + 1] = entry end
    PD:SortList(list, "players", SORT_DEFAULT, SORT_GETTERS)

    local count = #list
    PD:SetSubtitle(PD.CountText(count, "SUB_NO_ENTRIES", "SUB_1_ENTRY", "SUB_N_ENTRIES"), p1)

    if count == 0 then
        PD:ShowEmptyLabel(p1, content, L["EMPTY_PLAYERS"], 60, 160)
        return
    end

    for i, e in ipairs(list) do
        local row = GetRow(content)
        PD:SetupRow(row, content, i, ROW_H, ROW_PAD, PD.ROW_TINT.default)
        FillPlayerRow(row, e)
    end
    PD:FinishList(content, count, ROW_H, ROW_PAD)
end

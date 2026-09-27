-- ============================================================
--  PlayerDossier – Options.lua
--  Tab 3: Einstellungen
--  Ersetzt den Chat-Filter-Tab.
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- ================================================================
-- DB-DEFAULTS
-- ================================================================

function PD:OPT_Init()
    if not PlayerDossierDB then PD:Init() end
    local db = PlayerDossierDB
    if db.opt == nil then db.opt = {} end
    local o = db.opt
    if o.chatMessages   == nil then o.chatMessages   = true  end
    if o.blockIgnored   == nil then o.blockIgnored   = true  end
    if o.autoDecline    == nil then o.autoDecline    = true  end
    if o.minimapButton  == nil then o.minimapButton  = true  end
    if o.classColors    == nil then o.classColors    = true  end
    if o.lfgHideIgnored == nil then o.lfgHideIgnored = false end  -- LFG-Filter
    if o.lfgInlineWarning == nil then o.lfgInlineWarning = true end  -- Inline-Warnung in der Ergebnisliste
    if o.syncNativeIgnore == nil then o.syncNativeIgnore = true end  -- WoW-native Ignorierliste befuellen
    if o.trackGroupHistory == nil then o.trackGroupHistory = true end
end

function PD:OPT_Get(key)
    if not PlayerDossierDB or not PlayerDossierDB.opt then return true end
    local v = PlayerDossierDB.opt[key]
    return v ~= false   -- nil → true (default on)
end

function PD:OPT_Set(key, value)
    PD:OPT_Init()
    PlayerDossierDB.opt[key] = value
end

-- ================================================================
-- PANEL BUILD
-- ================================================================

function PD:BuildOptionsPanel(panel)
    if panel._optBuilt then return end
    panel._optBuilt = true

    -- ScrollFrame damit alles reinpasst
    local sf = CreateFrame("ScrollFrame", "PDOptScrollFrame", panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     panel, "TOPLEFT",     0,  0)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 0)

    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(sf:GetWidth())
    content:SetHeight(600)  -- wird am Ende angepasst
    sf:SetScrollChild(content)

    local INDENT = 8
    local yOff   = -8
    local p = content  -- alle Widgets auf content statt panel

    -- Helper: erstellt einen Abschnitt-Header mit Trennlinie
    local function MakeSection(text, yOffset)
        local sec = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sec:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT, yOffset)
        sec:SetText(text)
        sec:SetTextColor(0.9, 0.82, 0.5)
        local line = p:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  sec, "BOTTOMLEFT",  0, -2)
        line:SetPoint("TOPRIGHT", p,   "TOPRIGHT",   -INDENT, yOffset - 14)
        line:SetColorTexture(0.4, 0.4, 0.4, 0.6)
        return sec
    end

    local function MakeCB(key, lbl, sub, yOffset, onChange)
        local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT, yOffset)
        cb:SetChecked(PD:OPT_Get(key))
        cb:SetScript("OnClick", function(self)
            PD:OPT_Set(key, self:GetChecked())
            if onChange then onChange(self:GetChecked()) end
        end)
        local l = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        l:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        l:SetText(lbl)
        local rowHeight = 40
        if sub then
            local s = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            s:SetPoint("TOPLEFT",  cb, "BOTTOMLEFT", 28, -2)
            s:SetPoint("TOPRIGHT", p,  "TOPRIGHT",  -INDENT, -2)
            s:SetJustifyH("LEFT")
            s:SetWordWrap(true)
            s:SetText(sub)
            -- Zeilenumbruch statt Abschneiden: Zeilenhöhe dynamisch einrechnen
            rowHeight = 26 + s:GetStringHeight() + 14
        end
        return cb, rowHeight
    end

    -- ── 0. GRUPPENVERLAUF ─────────────────────────────────────
    MakeSection(L["OPT_SEC_HISTORY"], yOff) yOff = yOff - 22
    local cb7, rh7 = MakeCB("trackGroupHistory", L["OPT_TRACK_HISTORY"], L["OPT_TRACK_HISTORY_SUB"], yOff)
    yOff = yOff - rh7

    -- ── 1. GRUPPENSUCHE (LFG) ─────────────────────────────────
    MakeSection(L["OPT_SEC_LFG"], yOff) yOff = yOff - 22
    local cb6, rh6 = MakeCB("lfgHideIgnored", L["OPT_LFG_HIDE"], L["OPT_LFG_HIDE_SUB"], yOff)
    yOff = yOff - rh6
    local cb8, rh8 = MakeCB("lfgInlineWarning", L["OPT_LFG_INLINE"], L["OPT_LFG_INLINE_SUB"], yOff)
    yOff = yOff - rh8

    -- ── 2. IGNORIER-LISTE ─────────────────────────────────────
    MakeSection(L["OPT_SEC_IGNORE"], yOff) yOff = yOff - 22
    local cb2, rh2 = MakeCB("blockIgnored",  L["OPT_BLOCK_IGNORED"],  L["OPT_BLOCK_IGNORED_SUB"],  yOff)
    yOff = yOff - rh2
    local cb9, rh9 = MakeCB("syncNativeIgnore", L["OPT_SYNC_NATIVE"], L["OPT_SYNC_NATIVE_SUB"], yOff, function()
        PD:IL_Sync()
        if PD.panel2 and PD.panel2:IsShown() then PD:RefreshIgnorePanel() end
    end)
    yOff = yOff - rh9
    local cb3, rh3 = MakeCB("autoDecline",   L["OPT_AUTO_DECLINE"],   L["OPT_AUTO_DECLINE_SUB"],   yOff)
    -- Orange Hinweis zur Auto-Decline-Einschränkung
    local sub3b = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub3b:SetPoint("TOPLEFT", cb3, "BOTTOMLEFT", 28, -10 - (rh3 - 40))
    sub3b:SetPoint("TOPRIGHT", p, "TOPRIGHT", -INDENT, -10 - (rh3 - 40))
    sub3b:SetTextColor(1, 0.6, 0, 1)
    sub3b:SetWordWrap(true)
    sub3b:SetJustifyH("LEFT")
    sub3b:SetText(L["OPT_AUTO_DECLINE_NOTE"])
    yOff = yOff - rh3 - sub3b:GetStringHeight() - 16
    local cb5, rh5 = MakeCB("classColors",   L["OPT_CLASS_COLORS"],   L["OPT_CLASS_COLORS_SUB"],   yOff, function()
        if PD.mainFrame and PD.mainFrame:IsShown() then PD:RefreshMainWindow() end
    end)
    yOff = yOff - rh5

    -- ── 3. IGNORIER-LIMIT WORKAROUND ──────────────────────────
    MakeSection(L["OPT_SEC_LIMIT"], yOff) yOff = yOff - 22
    panel.limitLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.limitLabel:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT + 4, yOff)
    panel.limitLabel:SetJustifyH("LEFT")
    yOff = yOff - 22
    local infoText = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    infoText:SetPoint("TOPLEFT",  p, "TOPLEFT",  INDENT + 4, yOff)
    infoText:SetPoint("TOPRIGHT", p, "TOPRIGHT", -INDENT, yOff)
    infoText:SetJustifyH("LEFT")
    infoText:SetText(L["OPT_LIMIT_INFO"])
    yOff = yOff - 50

    -- ── 4. IMPORT ─────────────────────────────────────────────
    MakeSection(L["OPT_SEC_IMPORT"], yOff) yOff = yOff - 22
    local importLabel = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    importLabel:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT + 4, yOff)
    importLabel:SetWidth(540) importLabel:SetJustifyH("LEFT") importLabel:SetWordWrap(true)
    importLabel:SetText(L["OPT_IMPORT_INFO"])
    yOff = yOff - 30
    local importBtn = CreateFrame("Button", "PDImportIgnoreBtn", p, "UIPanelButtonTemplate")
    importBtn:SetSize(280, 24) importBtn:SetText(L["OPT_IMPORT_BTN"])
    importBtn:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT, yOff)
    importBtn:SetScript("OnClick", function()
        local num, added, skipped = C_FriendList.GetNumIgnores(), 0, 0
        for i = 1, num do
            local fullName = C_FriendList.GetIgnoreName(i)
            if fullName then
                -- Letztes Segment nach "-" als Realm (Realm kann Bindestriche enthalten)
                local name, realm = fullName:match("^(.+)-([^%-]+)$")
                name = name or fullName
                realm = realm or PD.GetMyRealm()
                local key = PD:GetKey(name, realm)
                if not PlayerDossierDB.ignoreList[key] then
                    PlayerDossierDB.ignoreList[key] = { name=name, realm=realm, reason="", timestamp=time(), native=true }
                    added = added + 1
                else skipped = skipped + 1 end
            end
        end
        if added > 0 then PD:IL_Sync() end
        print(string.format(L["OPT_IMPORT_DONE"], added, skipped))
        if PD.panel2 and PD.panel2:IsShown() then PD:RefreshIgnorePanel() end
    end)
    yOff = yOff - 40

    -- ── 5. MINIMAP ────────────────────────────────────────────
    MakeSection(L["OPT_SEC_MINIMAP"], yOff) yOff = yOff - 22
    local cb4 = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
    cb4:SetSize(24, 24)
    cb4:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT, yOff)
    cb4:SetChecked(not (PlayerDossierDB and PlayerDossierDB.minimap and PlayerDossierDB.minimap.hide))
    cb4:SetScript("OnClick", function(self)
        if self:GetChecked() then PD:MinimapShow() else PD:MinimapHide() end
    end)
    local lbl4 = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl4:SetPoint("LEFT", cb4, "RIGHT", 4, 0)
    lbl4:SetText(L["OPT_MINIMAP"])
    yOff = yOff - 40

    -- ── 6. NACHRICHTEN ────────────────────────────────────────
    MakeSection(L["OPT_SEC_MESSAGES"], yOff) yOff = yOff - 22
    local cb1, rh1 = MakeCB("chatMessages", L["OPT_CHAT_MESSAGES"], L["OPT_CHAT_MESSAGES_SUB"], yOff)
    yOff = yOff - rh1

    content:SetHeight(math.abs(yOff) + 20)
    panel._optCbs = { cb1=cb1, cb2=cb2, cb3=cb3, cb4=cb4, cb5=cb5, cb6=cb6, cb7=cb7, cb8=cb8, cb9=cb9 }
end

-- StaticPopups für die Bestätigungsdialoge
StaticPopupDialogs["PD_CONFIRM_CLEAR_PLAYERS"] = {
    text     = L["OPT_CONFIRM_CLEAR_PLAYERS"],
    button1  = L["BTN_DELETE_ALL"],
    button2  = L["BTN_CANCEL"],
    OnAccept = function()
        if PlayerDossierDB then PlayerDossierDB.players = {} end
        print(PlayerDossier.L["OPT_CLEARED_PLAYERS"])
        if PlayerDossier.mainFrame and PlayerDossier.mainFrame:IsShown() then
            PlayerDossier:RefreshMainWindow()
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["PD_CONFIRM_CLEAR_IGNORE"] = {
    text     = L["OPT_CONFIRM_CLEAR_IGNORE"],
    button1  = L["BTN_DELETE_ALL"],
    button2  = L["BTN_CANCEL"],
    OnAccept = function()
        if PlayerDossierDB then PlayerDossierDB.ignoreList = {} end
        -- WoW-native Liste ebenfalls leeren
        PD:IL_Sync()
        print(PlayerDossier.L["OPT_CLEARED_IGNORE"])
        if PlayerDossier.panel2 and PlayerDossier.panel2:IsShown() then
            PlayerDossier:RefreshIgnorePanel()
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["PD_CONFIRM_CLEAR_HISTORY"] = {
    text     = L["OPT_CONFIRM_CLEAR_HISTORY"],
    button1  = L["BTN_DELETE_ALL"],
    button2  = L["BTN_CANCEL"],
    OnAccept = function()
        if PlayerDossierDB then PlayerDossierDB.history = {} end
        print(PlayerDossier.L["OPT_CLEARED_HISTORY"])
        if PlayerDossier.panel3 and PlayerDossier.panel3:IsShown() then
            PlayerDossier:RefreshHistoryPanel()
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- ================================================================
-- REFRESH  (live-Daten aktualisieren wenn Tab geöffnet)
-- ================================================================

function PD:RefreshOptionsPanel()
    local panel = PD.panel4
    if not panel or not panel.limitLabel then return end

    local all     = PD.IL_GetAll and PD:IL_GetAll() or {}
    local total   = 0
    local native  = 0
    local overflow = 0
    for _, e in pairs(all) do
        total = total + 1
        if e.native then native = native + 1
        else             overflow = overflow + 1 end
    end

    panel.limitLabel:SetText(string.format(L["OPT_LIMIT_STATUS"], native, overflow))

    -- Checkboxen auf aktuellen DB-Stand setzen
    local cbs = panel._optCbs
    if not cbs then return end
    cbs.cb1:SetChecked(PD:OPT_Get("chatMessages"))
    cbs.cb2:SetChecked(PD:OPT_Get("blockIgnored"))
    cbs.cb3:SetChecked(PD:OPT_Get("autoDecline"))
    cbs.cb4:SetChecked(not (PlayerDossierDB and PlayerDossierDB.minimap and PlayerDossierDB.minimap.hide))
    if cbs.cb5 then cbs.cb5:SetChecked(PD:OPT_Get("classColors")) end
    if cbs.cb6 then cbs.cb6:SetChecked(PD:OPT_Get("lfgHideIgnored")) end
    if cbs.cb7 then cbs.cb7:SetChecked(PD:OPT_Get("trackGroupHistory")) end
    if cbs.cb8 then cbs.cb8:SetChecked(PD:OPT_Get("lfgInlineWarning")) end
    if cbs.cb9 then cbs.cb9:SetChecked(PD:OPT_Get("syncNativeIgnore")) end
end

-- ================================================================
-- INIT-HOOK
-- ================================================================

local origInit = PD.Init
PD.Init = function(self)
    origInit(self)
    PD:OPT_Init()
end

-- ================================================================
-- ILChatFilterFunc  (Overflow-Workaround – läuft immer)
-- Spieler auf der Ignore-Liste die NICHT nativ sind, werden hier geblockt
-- ================================================================

local IL_FILTER_EVENTS = {
    "CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_EMOTE",
    "CHAT_MSG_CHANNEL","CHAT_MSG_INSTANCE_CHAT","CHAT_MSG_RAID","CHAT_MSG_PARTY",
}

local function ILChatFilterFunc(_, event, msg, sender, ...)
    if not PD:OPT_Get("blockIgnored") then return end
    if not sender or sender == "" then return end
    -- Letztes Segment als Realm (Realm-Namen koennen Bindestriche enthalten)
    local name, realm = sender:match("^(.+)-([^%-]+)$")
    if not name then name = sender end
    if PD.IL_ShouldFilterSender and PD:IL_ShouldFilterSender(name, realm) then
        return true
    end
end

for _, ev in ipairs(IL_FILTER_EVENTS) do
    ChatFrame_AddMessageEventFilter(ev, ILChatFilterFunc)
end

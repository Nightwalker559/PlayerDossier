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
        if sub then
            local s = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            s:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 28, 2)
            s:SetText(sub)
        end
        return cb
    end

    -- ── 1. GRUPPENSUCHE (LFG) ─────────────────────────────────
    MakeSection(L["OPT_SEC_LFG"], yOff) yOff = yOff - 22
    local cb6 = MakeCB("lfgHideIgnored", L["OPT_LFG_HIDE"], L["OPT_LFG_HIDE_SUB"], yOff)
    yOff = yOff - 40

    -- ── 2. IGNORIER-LISTE ─────────────────────────────────────
    MakeSection(L["OPT_SEC_IGNORE"], yOff) yOff = yOff - 22
    local cb2 = MakeCB("blockIgnored",  L["OPT_BLOCK_IGNORED"],  L["OPT_BLOCK_IGNORED_SUB"],  yOff) yOff = yOff - 40
    local cb3 = MakeCB("autoDecline",   L["OPT_AUTO_DECLINE"],   L["OPT_AUTO_DECLINE_SUB"],   yOff)
    -- Orange Hinweis zur Auto-Decline-Einschränkung
    local sub3b = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub3b:SetPoint("TOPLEFT", cb3, "BOTTOMLEFT", 28, -10)
    sub3b:SetTextColor(1, 0.6, 0, 1)
    sub3b:SetText(L["OPT_AUTO_DECLINE_NOTE"])
    yOff = yOff - 50
    local cb5 = MakeCB("classColors",   L["OPT_CLASS_COLORS"],   L["OPT_CLASS_COLORS_SUB"],   yOff, function()
        if PD.mainFrame and PD.mainFrame:IsShown() then PD:RefreshMainWindow() end
    end)
    yOff = yOff - 40

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
                local name, realm = fullName:match("^(.+)-(.+)$")
                name = name or fullName; realm = realm or PD.GetMyRealm()
                local key = PD:GetKey(name, realm)
                if not PlayerDossierDB.ignoreList[key] then
                    PlayerDossierDB.ignoreList[key] = { name=name, realm=realm, reason="", timestamp=time(), native=true }
                    added = added + 1
                else skipped = skipped + 1 end
            end
        end
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
    local cb1 = MakeCB("chatMessages", L["OPT_CHAT_MESSAGES"], L["OPT_CHAT_MESSAGES_SUB"], yOff)
    yOff = yOff - 40

    content:SetHeight(math.abs(yOff) + 20)
    panel._optCbs = { cb1=cb1, cb2=cb2, cb3=cb3, cb4=cb4, cb5=cb5, cb6=cb6 }
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
        if C_FriendList then
            for i = C_FriendList.GetNumIgnores(), 1, -1 do
                local name = C_FriendList.GetIgnoreName(i)
                if name then C_FriendList.DelIgnore(name) end
            end
        end
        print(PlayerDossier.L["OPT_CLEARED_IGNORE"])
        if PlayerDossier.panel2 and PlayerDossier.panel2:IsShown() then
            PlayerDossier:RefreshIgnorePanel()
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- ================================================================
-- REFRESH  (live-Daten aktualisieren wenn Tab geöffnet)
-- ================================================================

function PD:RefreshOptionsPanel()
    local panel = PD.panel3
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

    panel.limitLabel:SetText(string.format(L["OPT_LIMIT_STATUS"],
        native, 50, overflow))

    -- Checkboxen auf aktuellen DB-Stand setzen
    local cbs = panel._optCbs
    if not cbs then return end
    cbs.cb1:SetChecked(PD:OPT_Get("chatMessages"))
    cbs.cb2:SetChecked(PD:OPT_Get("blockIgnored"))
    cbs.cb3:SetChecked(PD:OPT_Get("autoDecline"))
    cbs.cb4:SetChecked(not (PlayerDossierDB and PlayerDossierDB.minimap and PlayerDossierDB.minimap.hide))
    if cbs.cb5 then cbs.cb5:SetChecked(PD:OPT_Get("classColors")) end
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
    local name, realm = sender:match("^(.+)-(.+)$")
    if not name then name = sender end
    -- Nur blocken wenn in unserer Liste UND nicht nativ
    -- (native Slots werden von WoW selbst geblockt)
    if PD.IL_ShouldFilterSender and PD:IL_ShouldFilterSender(name, realm) then
        return true
    end
end

for _, ev in ipairs(IL_FILTER_EVENTS) do
    ChatFrame_AddMessageEventFilter(ev, ILChatFilterFunc)
end

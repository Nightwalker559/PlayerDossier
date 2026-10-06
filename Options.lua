-- ============================================================
--  PlayerDossier – Options.lua
--  Options tab: saved settings, panel layout, confirmation dialogs
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

-- ================================================================
-- SETTINGS
-- ================================================================

local DEFAULTS = {
    chatMessages      = true,
    blockIgnored      = true,
    autoDecline       = true,
    classColors       = true,
    lfgHideIgnored    = false,  -- hide LFG groups containing ignored players
    lfgInlineWarning  = true,   -- warn in the LFG result list
    syncNativeIgnore  = true,   -- also fill WoW's native ignore list
    trackGroupHistory = true,
}

PD:OnInit(function()
    local opt = PlayerDossierDB.opt
    for key, default in pairs(DEFAULTS) do
        if opt[key] == nil then opt[key] = default end
    end
end)

function PD:OPT_Get(key)
    if not PlayerDossierDB or not PlayerDossierDB.opt then return true end
    return PlayerDossierDB.opt[key] ~= false   -- nil → true (default on)
end

function PD:OPT_Set(key, value)
    PD:EnsureDB()
    PlayerDossierDB.opt[key] = value
end

-- ================================================================
-- PANEL
-- ================================================================

local INDENT = 8

function PD:BuildOptionsPanel(panel)
    -- Scroll frame so everything fits
    local sf = CreateFrame("ScrollFrame", "PDOptScrollFrame", panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     panel, "TOPLEFT",     0,  0)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 0)

    local p = CreateFrame("Frame", nil, sf)   -- scroll content; all widgets live here
    p:SetWidth(sf:GetWidth())
    p:SetHeight(600)  -- adjusted at the end
    sf:SetScrollChild(p)

    local yOff = -8
    panel._optCbs = {}   -- option key → checkbox (also used by the ElvUI skin)

    -- Section header with separator line
    local function MakeSection(text)
        local sec = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sec:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT, yOff)
        sec:SetText(text)
        sec:SetTextColor(0.9, 0.82, 0.5)
        local line = p:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  sec, "BOTTOMLEFT",  0, -2)
        line:SetPoint("TOPRIGHT", p,   "TOPRIGHT",   -INDENT, yOff - 14)
        line:SetColorTexture(0.4, 0.4, 0.4, 0.6)
        yOff = yOff - 22
    end

    -- Checkbox with label and optional wrapped description. Advances yOff.
    -- opts: onChange(checked), get() / set(checked) for non-standard storage.
    -- Returns the checkbox and the row height it used.
    local function MakeCB(key, label, sub, opts)
        opts = opts or {}
        local get = opts.get or function() return PD:OPT_Get(key) end
        local set = opts.set or function(v) PD:OPT_Set(key, v) end

        local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT, yOff)
        cb:SetChecked(get())
        cb._pdGet = get
        cb:SetScript("OnClick", function(self)
            set(self:GetChecked())
            if opts.onChange then opts.onChange(self:GetChecked()) end
        end)
        panel._optCbs[key] = cb

        local l = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        l:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        l:SetText(label)

        local rowHeight = 40
        if sub then
            local s = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            s:SetPoint("TOPLEFT",  cb, "BOTTOMLEFT", 28, -2)
            s:SetPoint("TOPRIGHT", p,  "TOPRIGHT",  -INDENT, -2)
            s:SetJustifyH("LEFT")
            s:SetWordWrap(true)
            s:SetText(sub)
            -- wrap instead of truncating: account for the text height
            rowHeight = 26 + s:GetStringHeight() + 14
        end
        yOff = yOff - rowHeight
        return cb, rowHeight
    end

    -- ── Group history ────────────────────────────────────────
    MakeSection(L["OPT_SEC_HISTORY"])
    MakeCB("trackGroupHistory", L["OPT_TRACK_HISTORY"], L["OPT_TRACK_HISTORY_SUB"])

    -- ── Group Finder (LFG) ───────────────────────────────────
    MakeSection(L["OPT_SEC_LFG"])
    MakeCB("lfgHideIgnored",   L["OPT_LFG_HIDE"],   L["OPT_LFG_HIDE_SUB"])
    MakeCB("lfgInlineWarning", L["OPT_LFG_INLINE"], L["OPT_LFG_INLINE_SUB"])

    -- ── Ignore list ──────────────────────────────────────────
    MakeSection(L["OPT_SEC_IGNORE"])
    MakeCB("blockIgnored", L["OPT_BLOCK_IGNORED"], L["OPT_BLOCK_IGNORED_SUB"])
    MakeCB("syncNativeIgnore", L["OPT_SYNC_NATIVE"], L["OPT_SYNC_NATIVE_SUB"], {
        onChange = function()
            PD:IL_Sync()
            if PD.panel2 and PD.panel2:IsShown() then PD:RefreshIgnorePanel() end
        end,
    })
    local cbDecline, rhDecline = MakeCB("autoDecline", L["OPT_AUTO_DECLINE"], L["OPT_AUTO_DECLINE_SUB"])
    -- Orange hint about the auto-decline limitation
    local declineNote = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    declineNote:SetPoint("TOPLEFT",  cbDecline, "BOTTOMLEFT", 28, -10 - (rhDecline - 40))
    declineNote:SetPoint("TOPRIGHT", p,         "TOPRIGHT",  -INDENT, -10 - (rhDecline - 40))
    declineNote:SetTextColor(1, 0.6, 0, 1)
    declineNote:SetWordWrap(true)
    declineNote:SetJustifyH("LEFT")
    declineNote:SetText(L["OPT_AUTO_DECLINE_NOTE"])
    yOff = yOff - declineNote:GetStringHeight() - 16
    MakeCB("classColors", L["OPT_CLASS_COLORS"], L["OPT_CLASS_COLORS_SUB"], {
        onChange = function()
            if PD.mainFrame and PD.mainFrame:IsShown() then PD:RefreshMainWindow() end
        end,
    })

    -- ── Ignore limit workaround ──────────────────────────────
    MakeSection(L["OPT_SEC_LIMIT"])
    panel.limitLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.limitLabel:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT + 4, yOff)
    panel.limitLabel:SetJustifyH("LEFT")
    yOff = yOff - 22
    local limitInfo = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    limitInfo:SetPoint("TOPLEFT",  p, "TOPLEFT",  INDENT + 4, yOff)
    limitInfo:SetPoint("TOPRIGHT", p, "TOPRIGHT", -INDENT, yOff)
    limitInfo:SetJustifyH("LEFT")
    limitInfo:SetText(L["OPT_LIMIT_INFO"])
    yOff = yOff - 50

    -- ── Import ───────────────────────────────────────────────
    MakeSection(L["OPT_SEC_IMPORT"])
    local importInfo = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    importInfo:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT + 4, yOff)
    importInfo:SetWidth(540)
    importInfo:SetJustifyH("LEFT")
    importInfo:SetWordWrap(true)
    importInfo:SetText(L["OPT_IMPORT_INFO"])
    yOff = yOff - 30
    local importBtn = CreateFrame("Button", "PDImportIgnoreBtn", p, "UIPanelButtonTemplate")
    importBtn:SetSize(280, 24)
    importBtn:SetText(L["OPT_IMPORT_BTN"])
    importBtn:SetPoint("TOPLEFT", p, "TOPLEFT", INDENT, yOff)
    importBtn:SetScript("OnClick", function()
        print(string.format(L["OPT_IMPORT_DONE"], PD:IL_ImportNative()))
    end)
    yOff = yOff - 40

    -- ── Minimap ──────────────────────────────────────────────
    MakeSection(L["OPT_SEC_MINIMAP"])
    MakeCB("minimap", L["OPT_MINIMAP"], nil, {
        get = function() return not PD:IsMinimapHidden() end,
        set = function(shown) if shown then PD:MinimapShow() else PD:MinimapHide() end end,
    })

    -- ── Chat messages ────────────────────────────────────────
    MakeSection(L["OPT_SEC_MESSAGES"])
    MakeCB("chatMessages", L["OPT_CHAT_MESSAGES"], L["OPT_CHAT_MESSAGES_SUB"])

    p:SetHeight(math.abs(yOff) + 20)
end

-- ================================================================
-- CONFIRMATION DIALOGS ("Remove All")
-- ================================================================

local function ConfirmDialog(textKey, onAccept)
    return {
        text     = L[textKey],
        button1  = L["BTN_DELETE_ALL"],
        button2  = L["BTN_CANCEL"],
        OnAccept = onAccept,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
end

StaticPopupDialogs["PD_CONFIRM_CLEAR_PLAYERS"] = ConfirmDialog("OPT_CONFIRM_CLEAR_PLAYERS", function()
    PlayerDossierDB.players = {}
    print(L["OPT_CLEARED_PLAYERS"])
    if PD.mainFrame and PD.mainFrame:IsShown() then PD:RefreshMainWindow() end
end)

StaticPopupDialogs["PD_CONFIRM_CLEAR_IGNORE"] = ConfirmDialog("OPT_CONFIRM_CLEAR_IGNORE", function()
    PlayerDossierDB.ignoreList = {}
    PD:IL_Sync()   -- also empties WoW's native list
    print(L["OPT_CLEARED_IGNORE"])
    if PD.panel2 and PD.panel2:IsShown() then PD:RefreshIgnorePanel() end
end)

StaticPopupDialogs["PD_CONFIRM_CLEAR_HISTORY"] = ConfirmDialog("OPT_CONFIRM_CLEAR_HISTORY", function()
    PlayerDossierDB.history = {}
    print(L["OPT_CLEARED_HISTORY"])
    if PD.panel3 and PD.panel3:IsShown() then PD:RefreshHistoryPanel() end
end)

-- ================================================================
-- REFRESH  (live data when the tab is opened)
-- ================================================================

function PD:RefreshOptionsPanel()
    local panel = PD.panel4
    if not panel or not panel.limitLabel then return end

    local native, overflow = 0, 0
    for _, e in pairs(PD:IL_GetAll()) do
        if e.native then native = native + 1 else overflow = overflow + 1 end
    end
    panel.limitLabel:SetText(string.format(L["OPT_LIMIT_STATUS"], native, overflow))

    for _, cb in pairs(panel._optCbs) do
        cb:SetChecked(cb._pdGet())
    end
end

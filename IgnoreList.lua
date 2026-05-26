-- ============================================================
--  PlayerDossier – IgnoreList.lua
--  Account-weite Ignore-Liste, kombiniert aus beiden Addons:
--  "I Remember You" + "Global Ignore List"
--
--  Strategie gegen das 50er-WoW-Limit:
--    • Die 50 zuletzt hinzugefügten landen im nativen WoW-System
--      (via C_FriendList.AddIgnore) → alle WoW-Features greifen
--    • Alle weiteren werden per ChatFrame_AddMessageEventFilter
--      aus dem Chat gefiltert
--
--  DB: PlayerDossierDB.ignoreList = {
--    ["Name-Realm"] = { name, realm, reason, timestamp, native }
--  }
-- ============================================================

local PD      = PlayerDossier
local L       = PD.L
local MAX_NATIVE = 50   -- Alle WoW-Slots nutzen

-- ================================================================
-- 1.  DB-SCHICHT
-- ================================================================

function PD:IL_Init()
    if not PlayerDossierDB then PD:Init() end
    if not PlayerDossierDB.ignoreList then
        PlayerDossierDB.ignoreList = {}
    end
end

function PD:IL_GetAll()
    return (PlayerDossierDB and PlayerDossierDB.ignoreList) or {}
end

function PD:IL_IsIgnored(name, realm)
    if not PlayerDossierDB or not PlayerDossierDB.ignoreList then return false end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    return PlayerDossierDB.ignoreList[PD:GetKey(name, realm)] ~= nil
end

function PD:IL_Count()
    local n = 0
    for _ in pairs(PD:IL_GetAll()) do n = n + 1 end
    return n
end

-- ----------------------------------------------------------------
function PD:IL_Add(name, realm, reason)
    PD:IL_Init()
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local key = PD:GetKey(name, realm)
    if PlayerDossierDB.ignoreList[key] then
        print(string.format(L["IL_ALREADY_MSG"], name))
        return
    end
    PlayerDossierDB.ignoreList[key] = {
        name      = name,
        realm     = realm,
        reason    = reason or "",
        timestamp = time(),
        native    = false,
    }
    PD:IL_Sync()
    if PD:OPT_Get("chatMessages") then
        print(string.format(L["IL_IGNORED_MSG"], name))
    end
    if PD.panel2 and PD.panel2:IsShown() then PD:RefreshIgnorePanel() end
end

-- ----------------------------------------------------------------
function PD:IL_Remove(name, realm)
    PD:IL_Init()
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local key = PD:GetKey(name, realm)
    local entry = PlayerDossierDB.ignoreList[key]
    if not entry then return end

    -- Aus WoW-System entfernen wenn dort eingetragen
    if entry.native then
        local target = (realm == PD.GetMyRealm()) and name or (name.."-"..realm)
        C_FriendList.DelIgnore(target)
    end

    PlayerDossierDB.ignoreList[key] = nil
    if PD:OPT_Get("chatMessages") then
        print(string.format(L["IL_UNIGNORED_MSG"], name))
    end
    if PD.panel2 and PD.panel2:IsShown() then PD:RefreshIgnorePanel() end
end

-- ================================================================
-- 2.  SYNC  (hält WoW-Slots aktuell)
-- ================================================================

function PD:IL_Sync()
    PD:IL_Init()

    -- Einträge nach Timestamp sortieren
    local list = {}
    for _, entry in pairs(PD:IL_GetAll()) do
        table.insert(list, entry)
    end
    table.sort(list, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)

    -- Native-Flags zurücksetzen
    for _, entry in pairs(PD:IL_GetAll()) do
        entry.native = false
    end

    -- WoW-Ignore-Liste einmalig als Lookup-Set → O(n) statt O(n²)
    local nativeSet  = {}
    local numIgnores = C_FriendList.GetNumIgnores()
    for i = 1, numIgnores do
        local iname = C_FriendList.GetIgnoreName(i)
        if iname then nativeSet[iname:lower()] = true end
    end

    local myRealm = PD.GetMyRealm()
    local canAdd  = math.max(0, MAX_NATIVE - numIgnores)

    -- Warnung wenn alle nativen Slots voll sind (nur einmal pro Session)
    if numIgnores >= MAX_NATIVE and not PD._ilSlotWarnShown then
        PD._ilSlotWarnShown = true
        if PD:OPT_Get("chatMessages") then
            print(L["IL_SLOTS_FULL"])
        end
    end

    for _, entry in ipairs(list) do
        local target = (entry.realm == myRealm)
            and entry.name
            or  (entry.name .. "-" .. entry.realm)
        local tLow = target:lower()

        if nativeSet[tLow] then
            entry.native = true
        elseif canAdd > 0 then
            C_FriendList.AddIgnore(target)
            nativeSet[tLow] = true
            entry.native    = true
            canAdd          = canAdd - 1
        end
    end
end

-- ================================================================
-- 3.  CHAT-FILTER  (Overflow-Schutz für > 50 Ignored)
-- ================================================================

-- Wird von ChatFilter.lua's ShouldFilter aufgerufen (dort eingebunden)
function PD:IL_ShouldFilterSender(name, realm)
    if not PlayerDossierDB or not PlayerDossierDB.ignoreList then return false end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local entry = PlayerDossierDB.ignoreList[PD:GetKey(name, realm)]
    -- Nur filtern wenn nicht nativ (nativ = WoW filtert selbst)
    return entry ~= nil and not entry.native
end

-- ================================================================
-- 4.  EVENTS  (Auto-Decline, Gruppen-Warnung)
-- ================================================================

local ilEventFrame = CreateFrame("Frame", "PDIgnoreListEvents")
ilEventFrame:RegisterEvent("DUEL_REQUESTED")
ilEventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
ilEventFrame:RegisterEvent("GUILD_INVITE_REQUEST")
ilEventFrame:RegisterEvent("TRADE_REQUEST")
ilEventFrame:RegisterEvent("IGNORELIST_UPDATE")
ilEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

ilEventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)

    if event == "DUEL_REQUESTED" then
        -- arg1 = challenger name
        if PD:OPT_Get("autoDecline") then
            local name = arg1
            if PD:IL_IsIgnored(name) then
                DeclineDuel()
                print(string.format(
                    "|cff9B82F3PlayerDossier:|r Auto-declined duel from ignored player |cffff2e2e%s|r.",
                    name
                ))
            end
        end

    elseif event == "PARTY_INVITE_REQUEST" then
        -- arg1 = "Name" or "Name-Realm", arg2 = isXRealm (bool) in 12.0
        if PD:OPT_Get("autoDecline") then
            local full = arg1 or ""
            local name, realm = full:match("^(.+)-(.+)$")
            name  = name  or full
            realm = (type(realm) == "string" and realm ~= "") and realm or PD.GetMyRealm()
            if PD:IL_IsIgnored(name, realm) then
                DeclineGroup()
            end
        end

    elseif event == "GUILD_INVITE_REQUEST" then
        -- arg1 = inviter name, arg2 = guild name
        if PD:OPT_Get("autoDecline") then
            local full = arg1 or ""
            local name, realm = full:match("^(.+)-(.+)$")
            name  = name  or full
            realm = (type(realm) == "string" and realm ~= "") and realm or PD.GetMyRealm()
            if PD:IL_IsIgnored(name, realm) then
                DeclineGuild()
            end
        end

    elseif event == "TRADE_REQUEST" then
        -- arg1 = player name
        if PD:OPT_Get("autoDecline") then
            local full = arg1 or ""
            local name, realm = full:match("^(.+)-(.+)$")
            name  = name  or full
            realm = (type(realm) == "string" and realm ~= "") and realm or PD.GetMyRealm()
            if PD:IL_IsIgnored(name, realm) then
                TradeFrame:Hide()
            end
        end

    elseif event == "IGNORELIST_UPDATE" then
        -- WoW's native Liste hat sich geändert → Flags neu synchronisieren
        PD:IL_Sync()
        if PD.panel2 and PD.panel2:IsShown() then
            PD:RefreshIgnorePanel()
        end

        -- Kurze Verzögerung damit Unit-Namen aufgelöst sind
        C_Timer.After(0.5, function()
            local isRaid = IsInRaid()
            local num    = GetNumGroupMembers()
            for i = 1, num do
                local unit = isRaid and ("raid"..i) or ("party"..i)
                if UnitExists(unit) and UnitIsPlayer(unit) then
                    local name, realm = UnitName(unit)
                    if name then
                        realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
                        if PD:IL_IsIgnored(name, realm) then
                            local entry = PD:IL_GetAll()[PD:GetKey(name, realm)]
                            local msg = string.format(
                                "|cff9B82F3PlayerDossier:|r |cffff2e2eWARNING:|r Ignored player |cffff2e2e%s|r is in your group!",
                                name
                            )
                            if entry and entry.reason and entry.reason ~= "" then
                                msg = msg .. " |cffaaaaaa(" .. entry.reason .. ")|r"
                            end
                            print(msg)
                        end
                    end
                end
            end
        end)
    end
end)

-- ================================================================
-- 5.  RECHTSKLICK-INTEGRATION  (in UI.lua's Menu.ModifyMenu hooks)
-- ================================================================

-- Wird nach UI.lua geladen → die Menu.ModifyMenu-Registrierungen
-- sind bereits aktiv; wir hängen uns hier separat rein.

local function InjectIgnoreMenu(_, rootDescription, contextData)
    local unit = contextData and contextData.unit
    if not unit then return end
    if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end

    local name, realm = UnitName(unit)
    if not name then return end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()

    local isIgnored = PD:IL_IsIgnored(name, realm)

    if isIgnored then
        rootDescription:CreateButton(string.format(L["MENU_UNIGNORE_PLAYER"], name), function()
            PD:IL_Remove(name, realm)
        end)
    else
        rootDescription:CreateButton(string.format(L["MENU_IGNORE_PLAYER"], name), function()
            PD:IL_PromptIgnore(name, realm)
        end)
    end
end

local function InjectIgnoreChatMenu(_, rootDescription, contextData)
    local name  = contextData and contextData.name
    local realm = contextData and contextData.server
    if not name or name == UnitName("player") then return end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()

    local isIgnored = PD:IL_IsIgnored(name, realm)

    if isIgnored then
        rootDescription:CreateButton(string.format(L["MENU_UNIGNORE_PLAYER"], name), function()
            PD:IL_Remove(name, realm)
        end)
    else
        rootDescription:CreateButton(string.format(L["MENU_IGNORE_PLAYER"], name), function()
            PD:IL_PromptIgnore(name, realm)
        end)
    end
end

local IL_UNIT_MENUS = {
    "MENU_UNIT_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID",
    "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_FRIEND", "MENU_UNIT_GUILD",
    "MENU_UNIT_TARGET",
}
for _, tag in ipairs(IL_UNIT_MENUS) do
    pcall(Menu.ModifyMenu, tag, InjectIgnoreMenu)
end
-- MENU_UNIT_CHAT_ROSTER wird von UI.lua's InjectChatMenu abgedeckt (inkl. Ignore)

-- Reason-Dialog
StaticPopupDialogs["PD_IGNORE_REASON"] = {
    text         = L["POPUP_IGNORE_TEXT"],
    button1      = L["BTN_IGNORE_PLAIN"],
    button2      = L["BTN_CANCEL"],
    hasEditBox   = true,
    maxLetters   = 100,
    editBoxWidth = 220,
    OnAccept = function(self)
        local reason = strtrim(self.EditBox:GetText())
        PD:IL_Add(PD._ilPendingName, PD._ilPendingRealm, reason)
        PD._ilPendingName, PD._ilPendingRealm = nil, nil
    end,
    OnCancel = function()
        PD._ilPendingName, PD._ilPendingRealm = nil, nil
    end,
    EditBoxOnEnterPressed = function(self)
        local dlg = self:GetParent()
        StaticPopupDialogs["PD_IGNORE_REASON"].OnAccept(dlg)
        dlg:Hide()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

function PD:IL_PromptIgnore(name, realm)
    PD._ilPendingName  = name
    PD._ilPendingRealm = realm
    StaticPopup_Show("PD_IGNORE_REASON", name)
end

-- ================================================================
-- 6.  IGNORE-FENSTER
-- ================================================================

local ilRowPool = {}
local function GetILRow(parent)
    for _, r in ipairs(ilRowPool) do
        if not r:IsShown() then r:SetParent(parent) r:Show() return r end
    end
    local r = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    table.insert(ilRowPool, r)
    return r
end
local function HideAllILRows()
    for _, r in ipairs(ilRowPool) do r:Hide() end
end

-- Spaltenoffsets
local IL_COL_NAME   = 4
local IL_COL_REALM  = 168
local IL_COL_LISTED = 298
local IL_COL_NOTE   = 358
local IL_ROW_H      = 52
local IL_ROW_PAD    = 2

local function DaysSince(ts)
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

function PD:BuildIgnorePanel(panel)
    if panel._ilBuilt then return end
    panel._ilBuilt = true

    -- Spaltenköpfe
    local heads = {
        { text=L["IL_COL_NAME"],   x=IL_COL_NAME   },
        { text=L["IL_COL_REALM"],  x=IL_COL_REALM  },
        { text=L["IL_COL_LISTED"], x=IL_COL_LISTED },
        { text=L["IL_COL_NOTE"],   x=IL_COL_NOTE   },
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
    local sf = CreateFrame("ScrollFrame", "PDILScrollFrame", panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     panel, "TOPLEFT",     4,  -22)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 32)
    local content = CreateFrame("Frame", "PDILScrollContent", sf)
    content:SetWidth(sf:GetWidth()) content:SetHeight(1)
    sf:SetScrollChild(content)
    panel.ilContent = content

    -- "Alle entfernen"-Button
    local clearBtn = CreateFrame("Button", "PDClearIgnoreBtn", panel, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 22)
    clearBtn:SetText(L["BTN_CLEAR_ALL"])
    clearBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 6)
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("PD_CONFIRM_CLEAR_IGNORE")
    end)
end


function PD:RefreshIgnorePanel()
    local myRealm = PD.GetMyRealm()
    local panel = PD.panel2
    if not panel or not panel.ilContent then return end

    local content = panel.ilContent
    HideAllILRows()

    local all  = PD:IL_GetAll()
    local list = {}
    for _, entry in pairs(all) do table.insert(list, entry) end
    table.sort(list, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)

    local count = #list
    if PD.mainFrame then
        PD.mainFrame.subtitle:SetText(
            count == 0 and L["SUB_NO_IGNORED"] or
            (count == 1 and L["SUB_1_IGNORED"] or string.format(L["SUB_N_IGNORED"], count))
        )
    end

    if count == 0 then
        if not panel.emptyLabel then
            panel.emptyLabel = content:CreateFontString(nil,"OVERLAY","GameFontDisable")
            panel.emptyLabel:SetPoint("TOP", content, "TOP", 0, -40)
            panel.emptyLabel:SetText(L["IL_EMPTY"])
            panel.emptyLabel:SetJustifyH("CENTER")
        end
        panel.emptyLabel:Show()
        content:SetHeight(100)
        return
    end
    if panel.emptyLabel then panel.emptyLabel:Hide() end

    local rowW = content:GetWidth() - 4
    local yOff = -IL_ROW_PAD

    for i, entry in ipairs(list) do
        local row = GetILRow(content)
        row:SetSize(rowW, IL_ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOff)
        row:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background"})
        if i % 2 == 0 then row:SetBackdropColor(0.10, 0.04, 0.04, 0.60)
        else                row:SetBackdropColor(0.14, 0.06, 0.06, 0.60) end

        -- Name (klassenfarben wenn im Dossier)
        if not row.nameLabel then
            row.nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameLabel:SetPoint("LEFT", row, "LEFT", IL_COL_NAME, 0)
            row.nameLabel:SetWidth(IL_COL_REALM - IL_COL_NAME - 4)
            row.nameLabel:SetJustifyH("LEFT")
        end
        local cc = nil  -- Ignorier-Liste: immer weiße Namen
        if cc then row.nameLabel:SetTextColor(cc.r, cc.g, cc.b)
        else       row.nameLabel:SetTextColor(1, 1, 1) end
        row.nameLabel:SetText(entry.name or "?")

        -- Realm
        if not row.realmLabel then
            row.realmLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.realmLabel:SetPoint("LEFT", row, "LEFT", IL_COL_REALM, 0)
            row.realmLabel:SetWidth(IL_COL_LISTED - IL_COL_REALM - 4)
            row.realmLabel:SetJustifyH("LEFT")
            row.realmLabel:SetTextColor(0.78, 0.78, 0.78)
        end
        row.realmLabel:SetText(entry.realm or myRealm)

        -- Tage auf Liste
        if not row.listedLabel then
            row.listedLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.listedLabel:SetPoint("LEFT", row, "LEFT", IL_COL_LISTED, 0)
            row.listedLabel:SetWidth(IL_COL_NOTE - IL_COL_LISTED - 4)
            row.listedLabel:SetJustifyH("LEFT")
            row.listedLabel:SetTextColor(0.78, 0.78, 0.78)
        end
        row.listedLabel:SetText(DaysSince(entry.timestamp))

        -- Notiz/Grund
        if not row.noteLabel then
            row.noteLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.noteLabel:SetPoint("LEFT",  row, "LEFT",  IL_COL_NOTE, 0)
            row.noteLabel:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            row.noteLabel:SetJustifyH("LEFT")
            row.noteLabel:SetTextColor(0.60, 0.60, 0.60)
        end
        row.noteLabel:SetText(
            (entry.reason and entry.reason ~= "") and entry.reason or "|cff444444-|r"
        )

        -- Rechtsklick-Menü
        row:EnableMouse(true)
        local eName, eRealm = entry.name, entry.realm
        row:SetScript("OnMouseUp", function(self, btn)
            if btn ~= "RightButton" then return end
            MenuUtil.CreateContextMenu(UIParent, function(_, root)
                root:CreateTitle("|cffff2e2e"..eName.."|r")
                root:CreateButton(L["BTN_UNIGNORE_PLAIN"], function()
                    PD:IL_Remove(eName, eRealm)
                end)
                -- Flüstern an ignorierte Spieler nicht erlaubt
                root:CreateButton("|cffaaaaaa"..L["BTN_WHISPER"].." ("..L["IL_IGNORED_HINT"]..")|r", function()
                end)
                root:CreateDivider()
                -- Auch ins Dossier aufnehmen falls noch nicht drin
                local dEntry = PD:GetEntry(eName, eRealm)
                if dEntry then
                    root:CreateButton(L["BTN_EDIT"], function()
                        PD:OpenNoteDialog(eName, eRealm, dEntry.class, dEntry.guid, dEntry.mood)
                    end)
                else
                    root:CreateButton(L["MENU_ADD"], function()
                        PD:OpenNoteDialog(eName, eRealm, nil, nil, "negative")
                    end)
                end
            end)
        end)

        -- Hover-Highlight
        if not row.hlTex then
            row.hlTex = row:CreateTexture(nil, "HIGHLIGHT")
            row.hlTex:SetAllPoints()
            row.hlTex:SetColorTexture(1, 1, 1, 0.05)
            row.hlTex:SetBlendMode("ADD")
        end

        yOff = yOff - IL_ROW_H - IL_ROW_PAD
    end
    content:SetHeight(math.abs(yOff) + IL_ROW_PAD)
end

-- Compat aliases
PD.RefreshIgnoreWindow = PD.RefreshIgnorePanel

-- ================================================================
-- 7.  INIT-HOOK + SLASH-COMMANDS
-- ================================================================

local origILInit = PD.Init
PD.Init = function(self)
    origILInit(self)
    PD:IL_Init()
    -- Sync nach kurzem Delay (WoW-IgnoreList ist bei ADDON_LOADED evtl. noch nicht geladen)
    C_Timer.After(2, function() PD:IL_Sync() end)
end

-- Overflow-Chat-Filter: blockiert Nachrichten von ignorierten Spielern
-- die nicht im WoW-native Slot sind (>50 Einträge)
local function ILChatFilterFunc(_, event, msg, sender, ...)
    if not PlayerDossierDB or not PlayerDossierDB.chatFilterEnabled then return end
    if not sender or sender == "" then return end
    local name, realm = sender:match("^(.+)-(.+)$")
    if not name then name = sender end
    if PD:IL_ShouldFilterSender(name, realm) then
        return true
    end
end
local IL_FILTER_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_RAID", "CHAT_MSG_PARTY",
}
for _, ev in ipairs(IL_FILTER_EVENTS) do
    ChatFrame_AddMessageEventFilter(ev, ILChatFilterFunc)
end

-- Slash-Commands erweitern
local origSlashIL = SlashCmdList["PLAYERDOSSIER"]
SlashCmdList["PLAYERDOSSIER"] = function(msg)
    local lower = msg and strtrim(msg:lower()) or ""
    if lower == "ignore" or lower == "il" or lower == "ignorelist" then
        PD:OpenOnTab(2)
    else
        origSlashIL(msg)
    end
end

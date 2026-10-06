-- ============================================================
--  PlayerDossier – IgnoreList.lua
--  Account-wide ignore list, combining the ideas of
--  "I Remember You" and "Global Ignore List".
--
--  Strategy against WoW's 50-slot limit (option "syncNativeIgnore",
--  on by default):
--    • The 50 most recently added players go into WoW's native
--      ignore list (via C_FriendList.AddIgnore) so all built-in
--      WoW features apply to them.
--    • Everything beyond that is blocked by a chat message filter.
--    • With the option off, EVERYTHING stays inside the addon -
--      C_FriendList is never touched, blocking happens only via
--      the chat filter.
--
--  DB: PlayerDossierDB.ignoreList = {
--    ["Name-Realm"] = { name, realm, reason, timestamp, native }
--  }
-- ============================================================

local PD         = PlayerDossier
local L          = PD.L
local MAX_NATIVE = 50   -- WoW's native ignore slots
local slotWarningShown = false   -- "all slots full" warning shown this session

-- ================================================================
-- 1.  DB LAYER
-- ================================================================

function PD:IL_GetAll()
    return (PlayerDossierDB and PlayerDossierDB.ignoreList) or {}
end

function PD:IL_IsIgnored(name, realm)
    if not PlayerDossierDB or not PlayerDossierDB.ignoreList then return false end
    return PlayerDossierDB.ignoreList[PD:GetKey(name, realm)] ~= nil
end

-- Name-only lookup (lower-case) for the chat filter, rebuilt lazily.
-- Invalidated on every change to the list.
local nameCache

local function InvalidateNameCache() nameCache = nil end

local function GetNameCache()
    if nameCache then return nameCache end
    nameCache = {}
    for _, e in pairs(PD:IL_GetAll()) do
        if e.name then nameCache[e.name:lower()] = true end
    end
    return nameCache
end

local function RefreshPanelIfShown()
    if PD.panel2 and PD.panel2:IsShown() then PD:RefreshIgnorePanel() end
end

function PD:IL_Add(name, realm, reason)
    realm = PD.NormRealm(realm)
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

    -- The new player got no native slot: warn once per session
    if PD:OPT_Get("syncNativeIgnore") and not PlayerDossierDB.ignoreList[key].native
       and not slotWarningShown then
        slotWarningShown = true
        if PD:OPT_Get("chatMessages") then print(L["IL_SLOTS_FULL"]) end
    end
    RefreshPanelIfShown()
end

-- Edits the reason of an already ignored player (timestamp/native untouched)
function PD:IL_SetReason(name, realm, reason)
    local entry = PlayerDossierDB.ignoreList[PD:GetKey(name, realm)]
    if not entry then return end
    entry.reason = reason or ""
    RefreshPanelIfShown()
end

function PD:IL_Remove(name, realm)
    realm = PD.NormRealm(realm)
    local key   = PD:GetKey(name, realm)
    local entry = PlayerDossierDB.ignoreList[key]
    if not entry then return end

    if entry.native then
        C_FriendList.DelIgnore(PD.TargetName(name, realm))
    end

    PlayerDossierDB.ignoreList[key] = nil
    InvalidateNameCache()
    if PD:OPT_Get("chatMessages") then
        print(string.format(L["IL_UNIGNORED_MSG"], name))
    end
    RefreshPanelIfShown()
end

-- Adds every player of WoW's native ignore list to the addon list.
-- Returns added, skipped.
function PD:IL_ImportNative()
    local added, skipped = 0, 0
    for i = 1, C_FriendList.GetNumIgnores() do
        local fullName = C_FriendList.GetIgnoreName(i)
        if fullName then
            local name, realm = PD.SplitName(fullName)
            realm = PD.NormRealm(realm)
            local key = PD:GetKey(name, realm)
            if PlayerDossierDB.ignoreList[key] then
                skipped = skipped + 1
            else
                PlayerDossierDB.ignoreList[key] = {
                    name = name, realm = realm, reason = "", timestamp = time(), native = true,
                }
                added = added + 1
            end
        end
    end
    if added > 0 then PD:IL_Sync() end
    RefreshPanelIfShown()
    return added, skipped
end

-- ================================================================
-- 2.  SYNC  (keeps WoW's native slots up to date)
-- ================================================================

function PD:IL_Sync()
    local addonList = PD:IL_GetAll()

    -- Native sync disabled: remove all previously synced native entries and
    -- hand NOTHING more to C_FriendList. Blocking then relies on the chat
    -- filter alone.
    if not PD:OPT_Get("syncNativeIgnore") then
        for _, entry in pairs(addonList) do
            if entry.native then
                C_FriendList.DelIgnore(PD.TargetName(entry.name, entry.realm))
                entry.native = false
            end
        end
        InvalidateNameCache()
        return
    end

    -- Addon list empty: remove all native ignores
    if not next(addonList) then
        for i = C_FriendList.GetNumIgnores(), 1, -1 do
            local iname = C_FriendList.GetIgnoreName(i)
            if iname then C_FriendList.DelIgnore(iname) end
        end
        InvalidateNameCache()
        return
    end

    -- Newest entries first; they get the native slots
    local list = {}
    for _, entry in pairs(addonList) do
        list[#list + 1] = entry
        entry.native = false
    end
    table.sort(list, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)

    -- Native list as a lookup set (O(n) instead of O(n²))
    local nativeSet  = {}
    local numIgnores = C_FriendList.GetNumIgnores()
    for i = 1, numIgnores do
        local iname = C_FriendList.GetIgnoreName(i)
        if iname then nativeSet[iname:lower()] = true end
    end

    local canAdd = math.max(0, MAX_NATIVE - numIgnores)

    for _, entry in ipairs(list) do
        local target = PD.TargetName(entry.name, entry.realm)
        local tLow   = target:lower()
        if nativeSet[tLow] then
            entry.native = true
        elseif canAdd > 0 then
            C_FriendList.AddIgnore(target)
            nativeSet[tLow] = true
            entry.native    = true
            canAdd          = canAdd - 1
        end
    end
    InvalidateNameCache()
end

-- ================================================================
-- 3.  CHAT FILTER  (overflow protection for > 50 ignored players)
-- ================================================================

-- realm = nil/"" means the sender came without a realm suffix
function PD:IL_ShouldFilterSender(name, realm)
    if not PlayerDossierDB or not PlayerDossierDB.ignoreList then return false end

    -- Exact match (name + realm; no realm = the player's own realm)
    if PlayerDossierDB.ignoreList[PD:GetKey(name, realm)] then return true end

    -- A sender WITH a realm that doesn't match exactly is someone else
    -- (same name, other realm). Only when the realm is unknown, fall back
    -- to the name (case-insensitive).
    if realm and realm ~= "" then return false end
    return GetNameCache()[name:lower()] or false
end

local FILTERED_CHAT_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_CHANNEL",
    "CHAT_MSG_WHISPER", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
}

local function ChatFilter(_, _, _, sender)
    -- In restricted contexts the sender is a secret value we can't inspect
    if not sender or PD.IsSecret(sender) or sender == "" then return end
    if not PD:OPT_Get("blockIgnored") then return end
    local name, realm = PD.SplitName(sender)
    if PD:IL_ShouldFilterSender(name, realm) then
        return true
    end
end

for _, ev in ipairs(FILTERED_CHAT_EVENTS) do
    ChatFrame_AddMessageEventFilter(ev, ChatFilter)
end

-- ================================================================
-- 4.  EVENTS  (auto-decline, group warning)
-- ================================================================

-- Auto-decline handlers; each gets the sender's name
local DECLINE = {
    DUEL_REQUESTED = function(name)
        DeclineDuel()
        if PD:OPT_Get("chatMessages") then
            print(string.format(L["IL_DUEL_DECLINED"], name))
        end
    end,
    PARTY_INVITE_REQUEST = function()
        DeclineGroup()
        StaticPopup_Hide("PARTY_INVITE")
    end,
    GUILD_INVITE_REQUEST = function()
        DeclineGuild()
    end,
    TRADE_REQUEST = function()
        -- The request is only a popup at this point, TradeFrame isn't shown yet
        if CancelTrade then CancelTrade() end
        StaticPopup_Hide("TRADE")
    end,
}

-- Prints a warning for every ignored player currently in the group
local function WarnIgnoredInGroup()
    PD:ForEachGroupMember(function(_, name, realm)
        local entry = PD:IL_GetAll()[PD:GetKey(name, realm)]
        if entry then
            local msg = string.format(L["IL_GROUP_WARNING"], name)
            if entry.reason and entry.reason ~= "" then
                msg = msg .. " |cffaaaaaa(" .. entry.reason .. ")|r"
            end
            print(msg)
        end
    end)
end

local groupWarnPending = false

local ilEventFrame = CreateFrame("Frame", "PDIgnoreListEvents")
for event in pairs(DECLINE) do ilEventFrame:RegisterEvent(event) end
ilEventFrame:RegisterEvent("IGNORELIST_UPDATE")

ilEventFrame:SetScript("OnEvent", function(_, event, sender)
    local decline = DECLINE[event]
    if decline then
        if not PD:OPT_Get("autoDecline") or not sender or PD.IsSecret(sender) then return end
        local name, realm = PD.SplitName(sender)
        if PD:IL_IsIgnored(name, realm) then decline(name) end

    elseif event == "IGNORELIST_UPDATE" then
        -- WoW's native list changed → re-sync the native flags
        PD:IL_Sync()
        RefreshPanelIfShown()

        -- One warning per burst of updates, after unit names have resolved
        if not groupWarnPending then
            groupWarnPending = true
            C_Timer.After(0.5, function()
                groupWarnPending = false
                WarnIgnoredInGroup()
            end)
        end
    end
end)

-- ================================================================
-- 5.  REASON DIALOGS
-- ================================================================

-- Pending player for the reason dialogs
local pending = {}

local function ReasonDialog(textKey, acceptKey, onAccept, onShow)
    local dialog
    dialog = {
        text         = L[textKey],
        button1      = L[acceptKey],
        button2      = L["BTN_CANCEL"],
        hasEditBox   = true,
        maxLetters   = 100,
        editBoxWidth = 220,
        OnShow       = onShow,
        OnAccept = function(self)
            onAccept(pending.name, pending.realm, strtrim(self.EditBox:GetText()))
            wipe(pending)
        end,
        OnCancel = function() wipe(pending) end,
        EditBoxOnEnterPressed = function(self)
            local dlg = self:GetParent()
            dialog.OnAccept(dlg)
            dlg:Hide()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    return dialog
end

StaticPopupDialogs["PD_IGNORE_REASON"] = ReasonDialog(
    "POPUP_IGNORE_TEXT", "BTN_IGNORE_PLAIN",
    function(name, realm, reason) PD:IL_Add(name, realm, reason) end)

StaticPopupDialogs["PD_IGNORE_EDIT_REASON"] = ReasonDialog(
    "POPUP_EDIT_REASON_TEXT", "BTN_SAVE",
    function(name, realm, reason) PD:IL_SetReason(name, realm, reason) end,
    function(self)
        self.EditBox:SetText(pending.reason or "")
        self.EditBox:HighlightText()
    end)

function PD:IL_PromptIgnore(name, realm)
    pending.name, pending.realm = name, realm
    StaticPopup_Show("PD_IGNORE_REASON", name)
end

function PD:IL_PromptEditReason(name, realm, currentReason)
    pending.name, pending.realm, pending.reason = name, realm, currentReason or ""
    StaticPopup_Show("PD_IGNORE_EDIT_REASON", name)
end

-- ================================================================
-- 6.  IGNORE LIST PANEL
-- ================================================================

local GetILRow, HideAllILRows = PD:NewRowPool()

local COL_NAME   = PD.COL.NAME
local COL_REALM  = PD.COL.REALM
local COL_LISTED = PD.COL.SINCE
local COL_NOTE   = PD.COL.LAST
local ROW_H      = 52
local ROW_PAD    = 2

function PD:BuildIgnorePanel(panel)
    panel.ilContent = PD:BuildListPanel(panel, {
        heads = {
            { text = L["IL_COL_NAME"],   x = COL_NAME   },
            { text = L["IL_COL_REALM"],  x = COL_REALM  },
            { text = L["IL_COL_LISTED"], x = COL_LISTED },
            { text = L["IL_COL_NOTE"],   x = COL_NOTE   },
        },
        scroll     = "PDILScrollFrame",
        content    = "PDILScrollContent",
        clearBtn   = "PDClearIgnoreBtn",
        clearPopup = "PD_CONFIRM_CLEAR_IGNORE",
    })
end

local function FillIgnoreRow(row, entry)
    -- Ignore list: always white names (class colors only in the Players tab)
    PD:RowLabel(row, "nameLabel", COL_NAME, COL_REALM, nil, 1, 1, 1):SetText(entry.name or "?")
    PD:RowLabel(row, "realmLabel", COL_REALM, COL_LISTED, nil, 0.78, 0.78, 0.78)
        :SetText(entry.realm or PD.GetMyRealm())
    PD:RowLabel(row, "listedLabel", COL_LISTED, COL_NOTE, nil, 0.78, 0.78, 0.78)
        :SetText(PD:TimeAgo(entry.timestamp))
    PD:RowLabel(row, "noteLabel", COL_NOTE, nil, nil, 0.60, 0.60, 0.60)
        :SetText((entry.reason and entry.reason ~= "") and entry.reason or "|cff444444-|r")

    local eName, eRealm, eReason = entry.name, entry.realm, entry.reason
    PD:SetRowMenu(row, function(root)
        root:CreateTitle("|cffff2e2e" .. eName .. "|r")
        root:CreateButton(L["BTN_UNIGNORE_PLAIN"], function()
            PD:IL_Remove(eName, eRealm)
        end)
        root:CreateButton(L["BTN_EDIT_REASON"], function()
            PD:IL_PromptEditReason(eName, eRealm, eReason)
        end)
        -- Whispering ignored players isn't possible (disabled entry)
        root:CreateButton("|cffaaaaaa" .. L["BTN_WHISPER"] .. " (" .. L["IL_IGNORED_HINT"] .. ")|r", function() end)
        root:CreateDivider()
        root:CreateButton(L["BTN_COPY_NAME"], function()
            PD:ShowCopyPopup(eName .. "-" .. eRealm)
        end)
        -- Mood/note live in the separate Player Dossier list
        local dEntry = PD:GetEntry(eName, eRealm)
        if dEntry then
            root:CreateButton(L["BTN_EDIT_DOSSIER"], function()
                PD:OpenNoteDialog(eName, eRealm, dEntry.class, dEntry.guid, dEntry.mood)
            end)
        else
            root:CreateButton(L["MENU_ADD_DOSSIER"], function()
                PD:OpenNoteDialog(eName, eRealm, nil, nil, "negative")
            end)
        end
    end)
end

function PD:RefreshIgnorePanel()
    local panel = PD.panel2
    if not panel or not panel.ilContent then return end
    local content = panel.ilContent
    HideAllILRows()

    local list = {}
    for _, entry in pairs(PD:IL_GetAll()) do list[#list + 1] = entry end
    table.sort(list, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)

    local count = #list
    PD:SetSubtitle(PD.CountText(count, "SUB_NO_IGNORED", "SUB_1_IGNORED", "SUB_N_IGNORED"))

    if count == 0 then
        PD:ShowEmptyLabel(panel, content, L["IL_EMPTY"], 40, 100)
        return
    end
    PD:HideEmptyLabel(panel)

    for i, entry in ipairs(list) do
        local row = GetILRow(content)
        PD:SetupRow(row, content, i, ROW_H, ROW_PAD, PD.ROW_TINT.ignore)
        FillIgnoreRow(row, entry)
    end
    PD:FinishList(content, count, ROW_H, ROW_PAD)
end

-- ================================================================
-- 7.  INIT + SLASH COMMANDS
-- ================================================================

PD:OnInit(function()
    -- Delayed: WoW's native ignore list may not be loaded yet at ADDON_LOADED
    C_Timer.After(2, function() PD:IL_Sync() end)
end)

PD.commands.ignore     = function() PD:OpenOnTab(2) end
PD.commands.il         = PD.commands.ignore
PD.commands.ignorelist = PD.commands.ignore

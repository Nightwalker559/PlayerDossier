-- ============================================================
--  PlayerDossier – Locales/Locale_enUS.lua
--  English base locale (default / fallback)
-- ============================================================

local L = PlayerDossier.L

-- ── General ──────────────────────────────────────────────────
L["entry"]               = "entry"
L["entries"]             = "entries"

-- ── Slash commands ────────────────────────────────────────────
L["SLASH_HELP_HEADER"]   = "|cff9B82F3PlayerDossier|r commands:"
L["SLASH_HELP_PD"]       = "  |cffffff00/pd|r              – open the dossier (Dossier tab)"
L["SLASH_HELP_IGNORE"]   = "  |cffffff00/pd ignore|r       – open Ignore List tab"
L["SLASH_HELP_MINIMAP"]  = "  |cffffff00/pd minimap|r      – toggle minimap button"
L["SLASH_HELP_CLEAR"]    = "  |cffffff00/pd clear|r        – delete ALL entries"
L["SLASH_HELP_HELP"]     = "  |cffffff00/pd help|r         – show this help"
L["SLASH_UNKNOWN"]       = "|cff9B82F3PlayerDossier:|r Unknown command. Type |cffffff00/pd help|r."

-- ── Tabs ─────────────────────────────────────────────────────
L["TAB_DOSSIER"]         = "Dossier"
L["TAB_IGNORE"]          = "Ignore List"

-- ── Subtitles ─────────────────────────────────────────────────
L["SUB_NO_ENTRIES"]      = "No entries yet"
L["SUB_1_ENTRY"]         = "1 entry"
L["SUB_N_ENTRIES"]       = "%d entries"
L["SUB_NO_IGNORED"]      = "No ignored players"
L["SUB_1_IGNORED"]       = "1 ignored player"
L["SUB_N_IGNORED"]       = "%d ignored players"

-- ── Players panel ─────────────────────────────────────────────
L["BTN_EDIT"]            = "Edit"
L["BTN_WHISPER"]         = "Whisper"
L["BTN_IGNORE"]          = "|cffff4444Ignore|r"
L["BTN_UNIGNORE"]        = "|cff00cc00Unignore|r"
L["BTN_DELETE_ALL"]      = "Delete All"
L["EMPTY_PLAYERS"]       = "Right-click any player in the world, group\nor chat to add them to your Dossier."

-- ── Note dialog ───────────────────────────────────────────────
L["NOTE_TITLE"]          = "Note – %s"
L["BTN_SAVE"]            = "Save"
L["BTN_CANCEL"]          = "Cancel"
L["MOOD_GOOD"]           = "Good"
L["MOOD_NEUTRAL"]        = "Neutral"
L["MOOD_BAD"]            = "Bad"

-- ── Right-click menu ──────────────────────────────────────────
L["MENU_ADD"]            = "Add to Dossier"
L["MENU_EDIT"]           = "[%s] Edit Note"
L["MENU_REMOVE"]         = "Remove from Dossier"
L["MENU_IGNORE_PLAYER"]  = "Ignore %s"
L["MENU_UNIGNORE_PLAYER"]= "|cffff2e2eUnignore %s|r"

-- ── Tooltip ───────────────────────────────────────────────────
L["TT_TITLE"]            = "PlayerDossier"
L["TT_LEFTCLICK"]        = "|cffffff00Left-click|r   Open / close"
L["TT_RIGHTCLICK"]       = "|cffffff00Right-click|r  Context menu"
L["TT_N_ENTRIES"]        = "|cffaaaaaa%d %s in dossier|r"

-- ── Minimap context menu ──────────────────────────────────────
L["MM_OPEN_DOSSIER"]     = "Open Player Dossier"
L["MM_OPEN_IGNORE"]      = "Open Ignore List"
L["MM_SHOW_BTN"]         = "Show Minimap Button"
L["MM_HIDE_BTN"]         = "Hide Minimap Button"
L["MM_HIDE_MSG"]         = "|cff9B82F3PlayerDossier:|r Minimap button hidden. Type |cffffff00/pd minimap|r to restore."

-- ── Ignore list panel ─────────────────────────────────────────
L["IL_EMPTY"]            = "No ignored players.\nRight-click any player and choose Ignore."
L["BTN_UNIGNORE_PLAIN"]  = "Unignore"
L["IL_IGNORED_MSG"]      = "|cff9B82F3PlayerDossier:|r Ignoring |cffff2e2e%s|r."
L["IL_UNIGNORED_MSG"]    = "|cff9B82F3PlayerDossier:|r Unignored %s."
L["IL_ALREADY_MSG"]      = "|cff9B82F3PlayerDossier:|r %s is already ignored."
L["POPUP_IGNORE_TEXT"]   = "Reason for ignoring |cffffffff%s|r (optional):"
L["BTN_IGNORE_PLAIN"]    = "Ignore"
L["POPUP_EDIT_REASON_TEXT"] = "Ignore reason for |cffffffff%s|r:"
L["BTN_EDIT_REASON"]     = "Edit reason"
L["BTN_EDIT_DOSSIER"]    = "Edit note in Player Dossier"
L["MENU_ADD_DOSSIER"]    = "Add to Player Dossier"

-- ── Options panel ─────────────────────────────────────────────
L["TAB_OPTIONS"]              = "Options"
L["OPT_SEC_MESSAGES"]         = "Chat Messages"
L["OPT_CHAT_MESSAGES"]        = "Show reunion & warning messages"
L["OPT_CHAT_MESSAGES_SUB"]    = "Notifies you when a tracked player joins your group."
L["OPT_SEC_IGNORE"]           = "Ignore List"
L["OPT_BLOCK_IGNORED"]        = "Block ignored players from chat"
L["OPT_BLOCK_IGNORED_SUB"]    = "Hides messages from ignored players who exceed WoW's 50-slot limit."
L["OPT_SYNC_NATIVE"]          = "Use WoW's native ignore list"
L["OPT_SYNC_NATIVE_SUB"]      = "When on, PlayerDossier-ignored players (up to 50) are also added to WoW's built-in ignore list so all of WoW's own features block them too. When off, ignoring stays inside PlayerDossier only - blocking still works via chat filtering."
L["OPT_AUTO_DECLINE"]         = "Auto-decline duels & invites"
L["OPT_AUTO_DECLINE_SUB"]     = "Automatically declines duels and group invites from ignored players."
L["OPT_SEC_LIMIT"]            = "Ignore Limit Workaround"
L["OPT_LIMIT_STATUS"]         = "|cffffff00%d / 50|r in WoW system    |cffaaaaaa%d via chat filter (overflow)|r"
L["OPT_LIMIT_INFO"]           = "WoW allows 50 ignore slots per character. PlayerDossier uses all 50 of them and filters the rest silently via the chat system — giving you unlimited ignores."
L["OPT_SEC_MINIMAP"]          = "Minimap"
L["OPT_MINIMAP"]              = "Show minimap button"

-- ── Ignore List columns ───────────────────────────────────────
L["IL_COL_NAME"]   = "Player Name"
L["IL_COL_REALM"]  = "Server"
L["IL_COL_LISTED"] = "Listed"
L["IL_COL_NOTE"]   = "Note"

-- ── Players panel columns ─────────────────────────────────────
L["PL_COL_NAME"]  = "Player Name"
L["PL_COL_REALM"] = "Server"
L["PL_COL_ROLE"]  = "Role"
L["PL_COL_SINCE"] = "Since"
L["PL_COL_NOTE"]  = "Note"
L["IL_IGNORED_HINT"]    = "Ignored"

L["BTN_COPY_NAME"]      = "Copy Name-Realm"
L["COPY_POPUP_TITLE"]   = "Copy – Ctrl+C"

-- ── Help ────────────────────────────────────────
L["SLASH_HELP_ADD"]     = "  Right-click any player or chat name to add them to the dossier."

-- ── Class colors option ───────────────────────────────────────
L["OPT_CLASS_COLORS"]     = "Show player names in class colors"
L["OPT_CLASS_COLORS_SUB"] = "Colors player names by their class. Disable for white names."

-- ── Cleanup ───────────────────────────────────────────
L["BTN_CLEAR_ALL"]            = "Remove All"

L["OPT_CONFIRM_CLEAR_PLAYERS"] = "Remove ALL players from the dossier? This cannot be undone."
L["OPT_CONFIRM_CLEAR_IGNORE"]  = "Remove ALL ignored players? This cannot be undone."

-- ── Import ────────────────────────────────────────────────────
L["OPT_SEC_IMPORT"]   = "Import"
L["OPT_IMPORT_INFO"]  = "Import all players from WoW's native ignore list into the PlayerDossier ignore list."
L["OPT_IMPORT_BTN"]   = "Import WoW Ignore List"
L["OPT_IMPORT_DONE"]  = "|cff9B82F3PlayerDossier:|r Import done. %d added, %d already existed."

-- ── Auto-decline note ─────────────────────────────────────────
L["OPT_AUTO_DECLINE_NOTE"] = "Note: May not work if another addon auto-accepts invites before PlayerDossier can decline them."

-- ── LFG ──────────────────────────────────────────────────────
L["OPT_SEC_LFG"]         = "Group Finder (LFG)"
L["OPT_LFG_INLINE"]      = "Show inline warning in group list"
L["OPT_LFG_INLINE_SUB"]  = "Colors the group name red and adds \"!IGNORED\" in front of it in the search result row when the leader or a member is on the PlayerDossier ignore list. Players with a bad mood in the dossier get an orange \"!WARNING\" instead."
L["LFG_IGNORED_WARNING"]  = "Ignored player in this group:"
L["LFG_INLINE_IGNORED"]   = "IGNORED"
L["LFG_BAD_WARNING"]      = "Badly rated player in this group:"
L["LFG_INLINE_BAD"]       = "WARNING"

-- ── Ignore slots full warning ─────────────────────────────────
L["IL_SLOTS_FULL"] = "|cff9B82F3PlayerDossier:|r |cffff8800All 50 WoW ignore slots are full. Additional players will be filtered via chat only.|r"
L["IL_DUEL_DECLINED"] = "|cff9B82F3PlayerDossier:|r Auto-declined duel from ignored player |cffff2e2e%s|r."
L["IL_GROUP_WARNING"] = "|cff9B82F3PlayerDossier:|r |cffff2e2eWARNING:|r Ignored player |cffff2e2e%s|r is in your group!"

-- ── Group History ─────────────────────────────────────────────
L["TAB_HISTORY"]         = "History"
L["SUB_NO_HISTORY"]      = "No group history yet"
L["SUB_1_HISTORY"]       = "1 player in history"
L["SUB_N_HISTORY"]       = "%d players in history"
L["HIST_COL_NAME"]       = "Player Name"
L["HIST_COL_REALM"]      = "Server"
L["HIST_COL_ROLE"]       = "Role"
L["HIST_COL_SEEN"]       = "Since"
L["HIST_COL_COUNT"]      = "Grouped"
L["HIST_COL_MODE"]       = "Mode"
L["HIST_CTX_DELVE"]        = "Delve"
L["HIST_CTX_TIMEWALKING"]  = "Timewalking"
L["HIST_CTX_RAID"]         = "Raid"
L["HIST_CTX_DUNGEON"]      = "Dungeon"
L["HIST_CTX_PVP"]          = "PvP"
L["HIST_CTX_SCENARIO"]     = "Scenario"
L["HIST_EMPTY"]          = "No group history yet.\nGroup members are logged automatically while you play."
L["HIST_ROLE_TANK"]      = "|cff3399ffT|r"
L["HIST_ROLE_HEALER"]    = "|cff33cc33H|r"
L["HIST_ROLE_DAMAGER"]   = "|cffff5555D|r"
L["HIST_ROLE_NONE"]      = "|cff888888-|r"
L["OPT_SEC_HISTORY"]        = "Group History"
L["OPT_TRACK_HISTORY"]      = "Track group history"
L["OPT_TRACK_HISTORY_SUB"]  = "Automatically logs everyone you group with, so you can add them to the dossier later."
L["OPT_CONFIRM_CLEAR_HISTORY"] = "Remove ALL group history? This cannot be undone."

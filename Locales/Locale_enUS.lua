-- ============================================================
--  PlayerDossier – Locales/Locale_enUS.lua
--  English base locale (default / fallback)
-- ============================================================

local L = PlayerDossier.L

-- ── General ──────────────────────────────────────────────────
L["PD_LOADED"]           = "|cff9B82F3PlayerDossier|r v%s loaded. %d %s. Type |cffffff00/pd|r."
L["entry"]               = "entry"
L["entries"]             = "entries"

-- ── Slash commands ────────────────────────────────────────────
L["SLASH_HELP_HEADER"]   = "|cff9B82F3PlayerDossier|r commands:"
L["SLASH_HELP_PD"]       = "  |cffffff00/pd|r              – open the dossier (Players tab)"
L["SLASH_HELP_IGNORE"]   = "  |cffffff00/pd ignore|r       – open Ignore List tab"
L["SLASH_HELP_MINIMAP"]  = "  |cffffff00/pd minimap|r      – toggle minimap button"
L["SLASH_HELP_CLEAR"]    = "  |cffffff00/pd clear|r        – delete ALL entries"
L["SLASH_HELP_HELP"]     = "  |cffffff00/pd help|r         – show this help"
L["SLASH_UNKNOWN"]       = "|cff9B82F3PlayerDossier:|r Unknown command. Type |cffffff00/pd help|r."

-- ── Tabs ─────────────────────────────────────────────────────
L["TAB_PLAYERS"]         = "Players"
L["TAB_IGNORE"]          = "Ignore List"
L["TAB_FILTER"]          = "Chat Filters"

-- ── Subtitles ─────────────────────────────────────────────────
L["SUB_NO_ENTRIES"]      = "No entries yet"
L["SUB_1_ENTRY"]         = "1 entry"
L["SUB_N_ENTRIES"]       = "%d entries"
L["SUB_NO_IGNORED"]      = "No ignored players"
L["SUB_1_IGNORED"]       = "1 ignored player"
L["SUB_N_IGNORED"]       = "%d ignored players"
L["SUB_FILTER_DESC"]     = "Keyword & pattern filters for chat messages"

-- ── Players panel ─────────────────────────────────────────────
L["BTN_ADD_PLAYER"]      = "Add Player"
L["BTN_EDIT"]            = "Edit"
L["BTN_WHISPER"]         = "Whisper"
L["BTN_IGNORE"]          = "|cffff4444Ignore|r"
L["BTN_UNIGNORE"]        = "|cff00cc00Unignore|r"
L["BTN_DELETE_ALL"]      = "Delete All"
L["NO_NOTE"]             = "(no note)"
L["EMPTY_PLAYERS"]       = "Right-click any player in the world, group\nor chat to add them to your Dossier."

-- ── Note dialog ───────────────────────────────────────────────
L["NOTE_TITLE"]          = "Note – %s"
L["BTN_SAVE"]            = "Save"
L["BTN_CANCEL"]          = "Cancel"
L["MOOD_GOOD"]           = "Good"
L["MOOD_NEUTRAL"]        = "Neutral"
L["MOOD_BAD"]            = "Bad"
L["NOTE_SAVED"]          = "|cff9B82F3PlayerDossier:|r Saved %s."

-- ── Add Player popup ──────────────────────────────────────────
L["POPUP_ADD_TEXT"]      = "Enter player name (Name or Name-Realm):"
L["BTN_NEXT"]            = "Next"

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
L["MM_OPEN_FILTERS"]     = "Open Chat Filters"
L["MM_OPEN_IGNORE"]      = "Open Ignore List"
L["MM_CHAT_FILTER"]      = "Chat Filtering"
L["MM_SHOW_BTN"]         = "Show Minimap Button"
L["MM_HIDE_BTN"]         = "Hide Minimap Button"
L["MM_SHOW_MSG"]         = "|cff9B82F3PlayerDossier:|r Minimap button shown."
L["MM_HIDE_MSG"]         = "|cff9B82F3PlayerDossier:|r Minimap button hidden. Type |cffffff00/pd minimap|r to restore."

-- ── Chat filter panel ─────────────────────────────────────────
L["CF_ON"]               = "|cff00d000Filtering ON|r"
L["CF_OFF"]              = "|cffff3030Filtering OFF|r"
L["CF_BLOCK_BAD"]        = "Block |cffff2e2eBad|r players from chat"
L["CF_COL_ON"]           = "ON"
L["CF_COL_PATTERN"]      = "PATTERN"
L["CF_COL_MODE"]         = "MODE"
L["CF_COL_DESC"]         = "DESCRIPTION"
L["CF_MODE_LABEL"]       = "Mode:"
L["CF_PLACEHOLDER_PAT"]  = "pattern or keyword…"
L["CF_PLACEHOLDER_DESC"] = "description…"
L["BTN_ADD"]             = "Add"
L["CF_EMPTY"]            = "No filters yet. Add one above."
L["CF_FILTER_ON_MSG"]    = "|cff9B82F3PlayerDossier:|r Chat filtering |cff00d000ON|r"
L["CF_FILTER_OFF_MSG"]   = "|cff9B82F3PlayerDossier:|r Chat filtering |cffff3030OFF|r"

-- ── Ignore list panel ─────────────────────────────────────────
L["IL_AUTO_DECLINE"]     = "Auto-decline duels & invites from ignored players"
L["IL_NO_REASON"]        = "(no reason)"
L["IL_EMPTY"]            = "No ignored players.\nRight-click any player and choose Ignore."
L["BTN_UNIGNORE_PLAIN"]  = "Unignore"
L["IL_IGNORED_MSG"]      = "|cff9B82F3PlayerDossier:|r Ignoring |cffff2e2e%s|r."
L["IL_UNIGNORED_MSG"]    = "|cff9B82F3PlayerDossier:|r Unignored %s."
L["IL_ALREADY_MSG"]      = "|cff9B82F3PlayerDossier:|r %s is already ignored."
L["IL_DECLINED_DUEL"]    = "|cff9B82F3PlayerDossier:|r Auto-declined duel from ignored player |cffff2e2e%s|r."
L["IL_DECLINED_INV"]     = "|cff9B82F3PlayerDossier:|r Auto-declined invite from ignored player |cffff2e2e%s|r."
L["IL_WARNING_GROUP"]    = "|cff9B82F3PlayerDossier:|r |cffff2e2eWARNING:|r Ignored player |cffff2e2e%s|r is in your group!"
L["POPUP_IGNORE_TEXT"]   = "Reason for ignoring |cffffffff%s|r (optional):"
L["POPUP_IL_ADD_TEXT"]   = "Ignore player (Name or Name-Realm):"
L["BTN_IGNORE_PLAIN"]    = "Ignore"

-- ── Reunion notice ────────────────────────────────────────────
L["REUNION_MSG"]         = "|cff9B82F3[PlayerDossier]|r %s%s%s"  -- mood-colored dot, name, note

-- ── Confirm clear ─────────────────────────────────────────────
L["CONFIRM_CLEAR"]       = "Delete ALL PlayerDossier entries? This cannot be undone."
L["CLEARED_MSG"]         = "|cff9B82F3PlayerDossier:|r All entries deleted."

-- ── Options panel ─────────────────────────────────────────────
L["TAB_OPTIONS"]              = "Options"
L["OPT_SEC_MESSAGES"]         = "Chat Messages"
L["OPT_CHAT_MESSAGES"]        = "Show reunion & warning messages"
L["OPT_CHAT_MESSAGES_SUB"]    = "Notifies you when a tracked player joins your group."
L["OPT_SEC_IGNORE"]           = "Ignore List"
L["OPT_BLOCK_IGNORED"]        = "Block ignored players from chat"
L["OPT_BLOCK_IGNORED_SUB"]    = "Hides messages from ignored players who exceed WoW's 50-slot limit."
L["OPT_AUTO_DECLINE"]         = "Auto-decline duels & invites"
L["OPT_AUTO_DECLINE_SUB"]     = "Automatically declines duels and group invites from ignored players."
L["OPT_SEC_LIMIT"]            = "Ignore Limit Workaround"
L["OPT_LIMIT_STATUS"]         = "|cffffff00%d / 50|r in WoW system    |cffaaaaaa%d via chat filter (overflow)|r"
L["OPT_LIMIT_INFO"]           = "WoW allows 50 ignore slots per character. PlayerDossier uses all 50 of them and filters the rest silently via the chat system — giving you unlimited ignores."
L["OPT_SEC_MINIMAP"]          = "Minimap"
L["OPT_MINIMAP"]              = "Show minimap button"

-- ── Recent Allies ─────────────────────────────────────────────
L["BTN_RECENT_ALLIES"]   = "Recent Allies"
L["RECENT_EMPTY"]        = "No recent allies found.\nPlay with others in dungeons or raids to populate this list."
L["RECENT_ADD"]          = "Add"
L["RECENT_LOADING"]        = "Loading recent allies from server..."

-- ── Ignore List columns ───────────────────────────────────────
L["IL_COL_NAME"]   = "Player Name"
L["IL_COL_REALM"]  = "Server"
L["IL_COL_LISTED"] = "Listed"
L["IL_COL_NOTE"]   = "Note"

-- ── Players panel columns ─────────────────────────────────────
L["PL_COL_MOOD"]  = "M"
L["PL_COL_NAME"]  = "Player Name"
L["PL_COL_REALM"] = "Server"
L["PL_COL_SINCE"] = "Since"
L["PL_COL_NOTE"]  = "Note"
L["IL_IGNORED_HINT"]    = "Ignored"

-- ── Group leave / kick ────────────────────────────────────────
L["LINK_REMEMBER"]  = "Add to Dossier"
L["LINK_EDIT"]      = "Edit Note"
L["LINK_LEFT_GROUP"]= "has left the group"
L["KICKED_MSG"]     = "You left the group. Remember anyone?"
L["SLASH_HELP_ADD"]     = "  Right-click any player or chat name to add them to the dossier."

-- ── Class colors option ───────────────────────────────────────
L["OPT_CLASS_COLORS"]     = "Show player names in class colors"
L["OPT_CLASS_COLORS_SUB"] = "Colors player names by their class. Disable for white names."

-- ── Cleanup section ───────────────────────────────────────────
L["OPT_SEC_CLEANUP"]           = "Cleanup"
L["BTN_CLEAR_ALL"]            = "Remove All"

L["OPT_CONFIRM_CLEAR_PLAYERS"] = "Remove ALL players from the dossier? This cannot be undone."
L["OPT_CONFIRM_CLEAR_IGNORE"]  = "Remove ALL ignored players? This cannot be undone."
L["OPT_CLEARED_PLAYERS"]       = "|cff9B82F3PlayerDossier:|r All players removed."
L["OPT_CLEARED_IGNORE"]        = "|cff9B82F3PlayerDossier:|r All ignored players removed."

-- ── Import ────────────────────────────────────────────────────
L["OPT_SEC_IMPORT"]   = "Import"
L["OPT_IMPORT_INFO"]  = "Import all players from WoW's native ignore list into the PlayerDossier ignore list."
L["OPT_IMPORT_BTN"]   = "Import WoW Ignore List"
L["OPT_IMPORT_DONE"]  = "|cff9B82F3PlayerDossier:|r Import done. %d added, %d already existed."

-- ── Auto-decline note ─────────────────────────────────────────
L["OPT_AUTO_DECLINE_NOTE"] = "Note: Does not work if another addon auto-accepts invites (e.g. guild invites)."

-- ── LFG ──────────────────────────────────────────────────────
L["OPT_SEC_LFG"]         = "Group Finder (LFG)"
L["OPT_LFG_HIDE"]        = "Hide groups containing ignored players"
L["OPT_LFG_HIDE_SUB"]    = "Hides LFG search results where the leader or a member is on the PlayerDossier ignore list (not just WoW's native list)."
L["LFG_IGNORED_WARNING"]  = "Ignored player in this group:"

-- ── Ignore slots full warning ─────────────────────────────────
L["IL_SLOTS_FULL"] = "|cff9B82F3PlayerDossier:|r |cffff8800⚠ All 50 WoW ignore slots are full. Additional players will be filtered via chat only.|r"

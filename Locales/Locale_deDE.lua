-- ============================================================
--  PlayerDossier – Locales/Locale_deDE.lua
--  German translation (deDE)
-- ============================================================

if GetLocale() ~= "deDE" then return end

local L = PlayerDossier.L

-- ── General ──────────────────────────────────────────────────
L["entry"]               = "Eintrag"
L["entries"]             = "Einträge"

-- ── Slash commands ────────────────────────────────────────────
L["SLASH_HELP_HEADER"]   = "|cff9B82F3PlayerDossier|r Befehle:"
L["SLASH_HELP_PD"]       = "  |cffffff00/pd|r              – Dossier öffnen (Spieler-Tab)"
L["SLASH_HELP_IGNORE"]   = "  |cffffff00/pd ignore|r       – Ignorier-Liste öffnen"
L["SLASH_HELP_MINIMAP"]  = "  |cffffff00/pd minimap|r      – Minimap-Button ein/aus"
L["SLASH_HELP_CLEAR"]    = "  |cffffff00/pd clear|r        – ALLE Einträge löschen"
L["SLASH_HELP_HELP"]     = "  |cffffff00/pd help|r         – Diese Hilfe anzeigen"
L["SLASH_UNKNOWN"]       = "|cff9B82F3PlayerDossier:|r Unbekannter Befehl. Tippe |cffffff00/pd help|r."

-- ── Tabs ─────────────────────────────────────────────────────
L["TAB_PLAYERS"]         = "Spieler"
L["TAB_IGNORE"]          = "Ignorierliste"

-- ── Subtitles ─────────────────────────────────────────────────
L["SUB_NO_ENTRIES"]      = "Keine Einträge"
L["SUB_1_ENTRY"]         = "1 Eintrag"
L["SUB_N_ENTRIES"]       = "%d Einträge"
L["SUB_NO_IGNORED"]      = "Keine ignorierten Spieler"
L["SUB_1_IGNORED"]       = "1 ignorierter Spieler"
L["SUB_N_IGNORED"]       = "%d ignorierte Spieler"

-- ── Players panel ─────────────────────────────────────────────
L["BTN_EDIT"]            = "Bearbeiten"
L["BTN_WHISPER"]         = "Flüstern"
L["BTN_IGNORE"]          = "|cffff4444Ignorieren|r"
L["BTN_UNIGNORE"]        = "|cff00cc00Entfernen|r"
L["BTN_DELETE_ALL"]      = "Alle löschen"
L["EMPTY_PLAYERS"]       = "Rechtsklick auf einen Spieler in der Welt,\nGruppe oder im Chat, um ihn hinzuzufügen."

-- ── Note dialog ───────────────────────────────────────────────
L["NOTE_TITLE"]          = "Vermerk – %s"
L["BTN_SAVE"]            = "Speichern"
L["BTN_CANCEL"]          = "Abbrechen"
L["MOOD_GOOD"]           = "Gut"
L["MOOD_NEUTRAL"]        = "Neutral"
L["MOOD_BAD"]            = "Schlecht"

-- ── Right-click menu ──────────────────────────────────────────
L["MENU_ADD"]            = "Zum Dossier hinzufügen"
L["MENU_EDIT"]           = "[%s] Vermerk bearbeiten"
L["MENU_REMOVE"]         = "Aus Dossier entfernen"
L["MENU_IGNORE_PLAYER"]  = "%s ignorieren"
L["MENU_UNIGNORE_PLAYER"]= "|cffff2e2e%s nicht mehr ignorieren|r"

-- ── Tooltip ───────────────────────────────────────────────────
L["TT_TITLE"]            = "PlayerDossier"
L["TT_LEFTCLICK"]        = "|cffffff00Linksklick|r   Öffnen / Schließen"
L["TT_RIGHTCLICK"]       = "|cffffff00Rechtsklick|r  Kontextmenü"
L["TT_N_ENTRIES"]        = "|cffaaaaaa%d %s im Dossier|r"

-- ── Minimap context menu ──────────────────────────────────────
L["MM_OPEN_DOSSIER"]     = "Spieler-Dossier öffnen"
L["MM_OPEN_IGNORE"]      = "Ignorier-Liste öffnen"
L["MM_SHOW_BTN"]         = "Minimap-Button anzeigen"
L["MM_HIDE_BTN"]         = "Minimap-Button verstecken"
L["MM_HIDE_MSG"]         = "|cff9B82F3PlayerDossier:|r Minimap-Button versteckt. Tippe |cffffff00/pd minimap|r zum Wiederherstellen."

-- ── Ignore list panel ─────────────────────────────────────────
L["IL_EMPTY"]            = "Keine ignorierten Spieler.\nRechtsklick auf einen Spieler und 'Ignorieren' wählen."
L["BTN_UNIGNORE_PLAIN"]  = "Entfernen"
L["IL_IGNORED_MSG"]      = "|cff9B82F3PlayerDossier:|r Ignoriert |cffff2e2e%s|r."
L["IL_UNIGNORED_MSG"]    = "|cff9B82F3PlayerDossier:|r %s wird nicht mehr ignoriert."
L["IL_ALREADY_MSG"]      = "|cff9B82F3PlayerDossier:|r %s wird bereits ignoriert."
L["POPUP_IGNORE_TEXT"]   = "Grund für das Ignorieren von |cffffffff%s|r (optional):"
L["BTN_IGNORE_PLAIN"]    = "Ignorieren"
L["POPUP_EDIT_REASON_TEXT"] = "Ignorier-Grund für |cffffffff%s|r:"
L["BTN_EDIT_REASON"]     = "Grund bearbeiten"
L["BTN_EDIT_DOSSIER"]    = "Notiz im Spieler-Dossier bearbeiten"
L["MENU_ADD_DOSSIER"]    = "Ins Spieler-Dossier aufnehmen"

-- ── Options panel ─────────────────────────────────────────────
L["TAB_OPTIONS"]              = "Optionen"
L["OPT_SEC_MESSAGES"]         = "Chat-Nachrichten"
L["OPT_CHAT_MESSAGES"]        = "Wieder-Treffen & Warnungen anzeigen"
L["OPT_CHAT_MESSAGES_SUB"]    = "Benachrichtigt dich wenn ein gespeicherter Spieler deiner Gruppe beitritt."
L["OPT_SEC_IGNORE"]           = "Ignorier-Liste"
L["OPT_BLOCK_IGNORED"]        = "Ignorierte Spieler im Chat blockieren"
L["OPT_BLOCK_IGNORED_SUB"]    = "Versteckt Nachrichten von Spielern die über WoWs 50er-Limit hinausgehen."
L["OPT_SYNC_NATIVE"]          = "WoWs native Ignorierliste verwenden"
L["OPT_SYNC_NATIVE_SUB"]      = "Wenn aktiv, werden bis zu 50 im PlayerDossier ignorierte Spieler zusätzlich in WoWs eingebaute Ignorierliste eingetragen, damit auch alle WoW-eigenen Funktionen greifen. Wenn deaktiviert, bleibt das Ignorieren rein im Addon - Blockierung läuft dann nur über den Chat-Filter."
L["OPT_AUTO_DECLINE"]         = "Duelle & Einladungen automatisch ablehnen"
L["OPT_AUTO_DECLINE_SUB"]     = "Lehnt Duelle und Gruppeneinladungen von ignorierten Spielern automatisch ab."
L["OPT_SEC_LIMIT"]            = "Ignorier-Limit Workaround"
L["OPT_LIMIT_STATUS"]         = "|cffffff00%d / 50|r im WoW-System    |cffaaaaaa%d per Chat-Filter (Überlauf)|r"
L["OPT_LIMIT_INFO"]           = "WoW erlaubt 50 Ignorier-Slots pro Charakter. PlayerDossier nutzt alle 50 davon und filtert den Rest still über das Chat-System – so sind unbegrenzt viele Spieler möglich."
L["OPT_SEC_MINIMAP"]          = "Minimap"
L["OPT_MINIMAP"]              = "Minimap-Button anzeigen"

-- ── Ignore List columns ────────────────────────────────────
L["IL_COL_NAME"]   = "Spielername"
L["IL_COL_REALM"]  = "Server"
L["IL_COL_LISTED"] = "Seit"
L["IL_COL_NOTE"]   = "Notiz"

-- ── Players panel columns ─────────────────────────────────────
L["PL_COL_NAME"]  = "Spielername"
L["PL_COL_REALM"] = "Server"
L["PL_COL_ROLE"]  = "Rolle"
L["PL_COL_SINCE"] = "Seit"
L["PL_COL_NOTE"]  = "Notiz"
L["IL_IGNORED_HINT"]    = "Ignoriert"

L["BTN_COPY_NAME"]      = "Name-Server kopieren"
L["COPY_POPUP_TITLE"]   = "Kopieren – Strg+C"

-- ── Group leave / kick ───────────────────────────────────
L["LINK_REMEMBER"]  = "Zum Dossier"
L["LINK_EDIT"]      = "Bearbeiten"
L["LINK_LEFT_GROUP"]= "hat die Gruppe verlassen"
L["KICKED_MSG"]     = "Du hast die Gruppe verlassen. Jemanden merken?"
L["SLASH_HELP_ADD"]     = "  Rechtsklick auf einen Spieler oder Chat-Namen um ihn hinzuzufügen."

-- ── Class colors option ──────────────────────────────────────
L["OPT_CLASS_COLORS"]     = "Spielernamen in Klassenfarbe anzeigen"
L["OPT_CLASS_COLORS_SUB"] = "Färbt Namen nach Klasse. Deaktivieren für weiße Namen."

-- ── Cleanup ─────────────────────────────────────────────────
L["BTN_CLEAR_ALL"]            = "Alle entfernen"

L["OPT_CONFIRM_CLEAR_PLAYERS"] = "ALLE Spieler aus dem Dossier entfernen? Dies kann nicht rückgängig gemacht werden."
L["OPT_CONFIRM_CLEAR_IGNORE"]  = "ALLE ignorierten Spieler entfernen? Dies kann nicht rückgängig gemacht werden."

-- ── Import ────────────────────────────────────────────────────
L["OPT_SEC_IMPORT"]   = "Import"
L["OPT_IMPORT_INFO"]  = "Alle Spieler aus WoWs nativer Ignorierliste in die PlayerDossier Ignorierliste importieren."
L["OPT_IMPORT_BTN"]   = "WoW-Ignorierliste importieren"
L["OPT_IMPORT_DONE"]  = "|cff9B82F3PlayerDossier:|r Import abgeschlossen. %d hinzugefügt, %d bereits vorhanden."

-- ── Auto-decline note ─────────────────────────────────────
L["OPT_AUTO_DECLINE_NOTE"] = "Hinweis: Funktioniert möglicherweise nicht, wenn ein anderes Addon Einladungen schneller annimmt als PlayerDossier sie ablehnen kann."

-- ── LFG ──────────────────────────────────────────────────────
L["OPT_SEC_LFG"]         = "Gruppensuche (LFG)"
L["OPT_LFG_HIDE"]        = "Gruppen mit ignorierten Spielern ausblenden"
L["OPT_LFG_HIDE_SUB"]    = "Blendet LFG-Suchergebnisse aus, wenn der Gruppenleiter oder ein Mitglied auf der PlayerDossier-Ignorierliste steht (nicht nur WoWs native Liste)."
L["OPT_LFG_INLINE"]      = "Warnung direkt in der Gruppenliste anzeigen"
L["OPT_LFG_INLINE_SUB"]  = "Färbt den Gruppennamen rot und zeigt ein Warnsymbol direkt in der Suchergebnis-Zeile, wenn der Gruppenleiter oder ein Mitglied auf der PlayerDossier-Ignorierliste steht."
L["LFG_IGNORED_WARNING"]  = "Ignorierter Spieler in dieser Gruppe:"

-- ── Ignore slots full warning ───────────────────────────────
L["IL_SLOTS_FULL"] = "|cff9B82F3PlayerDossier:|r |cffff8800Alle 50 WoW-Ignorier-Slots sind voll. Weitere Spieler werden nur noch per Chat gefiltert.|r"
L["IL_DUEL_DECLINED"] = "|cff9B82F3PlayerDossier:|r Duell von ignoriertem Spieler |cffff2e2e%s|r automatisch abgelehnt."
L["IL_GROUP_WARNING"] = "|cff9B82F3PlayerDossier:|r |cffff2e2eWARNUNG:|r Ignorierter Spieler |cffff2e2e%s|r ist in deiner Gruppe!"

-- ── Group History ────────────────────────────────────────────
L["TAB_HISTORY"]         = "Verlauf"
L["SUB_NO_HISTORY"]      = "Kein Gruppenverlauf"
L["SUB_1_HISTORY"]       = "1 Spieler im Verlauf"
L["SUB_N_HISTORY"]       = "%d Spieler im Verlauf"
L["HIST_COL_NAME"]       = "Spielername"
L["HIST_COL_REALM"]      = "Server"
L["HIST_COL_ROLE"]       = "Rolle"
L["HIST_COL_SEEN"]       = "Seit"
L["HIST_COL_COUNT"]      = "Gruppiert"
L["HIST_COL_MODE"]       = "Modus"
L["HIST_CTX_DELVE"]        = "Delve"
L["HIST_CTX_TIMEWALKING"]  = "Zeitwandern"
L["HIST_CTX_RAID"]         = "Schlachtzug"
L["HIST_CTX_DUNGEON"]      = "Instanz"
L["HIST_CTX_PVP"]          = "PvP"
L["HIST_CTX_SCENARIO"]     = "Szenario"
L["HIST_EMPTY"]          = "Noch kein Gruppenverlauf.\nGruppenmitglieder werden automatisch erfasst."
L["HIST_ROLE_TANK"]      = "|cff3399ffT|r"
L["HIST_ROLE_HEALER"]    = "|cff33cc33H|r"
L["HIST_ROLE_DAMAGER"]   = "|cffff5555D|r"
L["HIST_ROLE_NONE"]      = "|cff888888-|r"
L["OPT_SEC_HISTORY"]        = "Gruppenverlauf"
L["OPT_TRACK_HISTORY"]      = "Gruppenverlauf aufzeichnen"
L["OPT_TRACK_HISTORY_SUB"]  = "Erfasst automatisch alle Mitspieler, damit du sie später zum Dossier hinzufügen kannst."
L["OPT_CONFIRM_CLEAR_HISTORY"] = "Den GESAMTEN Gruppenverlauf löschen? Dies kann nicht rückgängig gemacht werden."

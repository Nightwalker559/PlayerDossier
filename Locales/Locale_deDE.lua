-- ============================================================
--  PlayerDossier – Locales/Locale_deDE.lua
--  Deutsche Übersetzung (deDE)
-- ============================================================

if GetLocale() ~= "deDE" then return end

local L = PlayerDossier.L

-- ── General ──────────────────────────────────────────────────
L["PD_LOADED"]           = "|cff9B82F3PlayerDossier|r v%s geladen. %d %s. Tippe |cffffff00/pd|r."
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
L["TAB_FILTER"]          = "Chat-Filter"

-- ── Subtitles ─────────────────────────────────────────────────
L["SUB_NO_ENTRIES"]      = "Keine Einträge"
L["SUB_1_ENTRY"]         = "1 Eintrag"
L["SUB_N_ENTRIES"]       = "%d Einträge"
L["SUB_NO_IGNORED"]      = "Keine ignorierten Spieler"
L["SUB_1_IGNORED"]       = "1 ignorierter Spieler"
L["SUB_N_IGNORED"]       = "%d ignorierte Spieler"
L["SUB_FILTER_DESC"]     = "Schlüsselwort- und Muster-Filter für Chat-Nachrichten"

-- ── Players panel ─────────────────────────────────────────────
L["BTN_ADD_PLAYER"]      = "Spieler hinzufügen"
L["BTN_EDIT"]            = "Bearbeiten"
L["BTN_WHISPER"]         = "Flüstern"
L["BTN_IGNORE"]          = "|cffff4444Ignorieren|r"
L["BTN_UNIGNORE"]        = "|cff00cc00Entfernen|r"
L["BTN_DELETE_ALL"]      = "Alle löschen"
L["NO_NOTE"]             = "(kein Vermerk)"
L["EMPTY_PLAYERS"]       = "Rechtsklick auf einen Spieler in der Welt,\nGruppe oder im Chat, um ihn hinzuzufügen."

-- ── Note dialog ───────────────────────────────────────────────
L["NOTE_TITLE"]          = "Vermerk – %s"
L["BTN_SAVE"]            = "Speichern"
L["BTN_CANCEL"]          = "Abbrechen"
L["MOOD_GOOD"]           = "Gut"
L["MOOD_NEUTRAL"]        = "Neutral"
L["MOOD_BAD"]            = "Schlecht"
L["NOTE_SAVED"]          = "|cff9B82F3PlayerDossier:|r %s gespeichert."

-- ── Add Player popup ──────────────────────────────────────────
L["POPUP_ADD_TEXT"]      = "Spielername eingeben (Name oder Name-Realm):"
L["BTN_NEXT"]            = "Weiter"

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
L["MM_OPEN_FILTERS"]     = "Chat-Filter öffnen"
L["MM_OPEN_IGNORE"]      = "Ignorier-Liste öffnen"
L["MM_CHAT_FILTER"]      = "Chat-Filterung"
L["MM_SHOW_BTN"]         = "Minimap-Button anzeigen"
L["MM_HIDE_BTN"]         = "Minimap-Button verstecken"
L["MM_SHOW_MSG"]         = "|cff9B82F3PlayerDossier:|r Minimap-Button wird angezeigt."
L["MM_HIDE_MSG"]         = "|cff9B82F3PlayerDossier:|r Minimap-Button versteckt. Tippe |cffffff00/pd minimap|r zum Wiederherstellen."

-- ── Chat filter panel ─────────────────────────────────────────
L["CF_ON"]               = "|cff00d000Filterung AKTIV|r"
L["CF_OFF"]              = "|cffff3030Filterung INAKTIV|r"
L["CF_BLOCK_BAD"]        = "|cffff2e2eSchlechte|r Spieler im Chat blockieren"
L["CF_COL_ON"]           = "AN"
L["CF_COL_PATTERN"]      = "MUSTER"
L["CF_COL_MODE"]         = "MODUS"
L["CF_COL_DESC"]         = "BESCHREIBUNG"
L["CF_MODE_LABEL"]       = "Modus:"
L["CF_PLACEHOLDER_PAT"]  = "Muster oder Schlüsselwort…"
L["CF_PLACEHOLDER_DESC"] = "Beschreibung…"
L["BTN_ADD"]             = "Hinzufügen"
L["CF_EMPTY"]            = "Noch keine Filter. Oben einen hinzufügen."
L["CF_FILTER_ON_MSG"]    = "|cff9B82F3PlayerDossier:|r Chat-Filterung |cff00d000AKTIV|r"
L["CF_FILTER_OFF_MSG"]   = "|cff9B82F3PlayerDossier:|r Chat-Filterung |cffff3030INAKTIV|r"

-- ── Ignore list panel ─────────────────────────────────────────
L["IL_AUTO_DECLINE"]     = "Duelle & Einladungen von ignorierten Spielern automatisch ablehnen"
L["IL_NO_REASON"]        = "(kein Grund)"
L["IL_EMPTY"]            = "Keine ignorierten Spieler.\nRechtsklick auf einen Spieler und 'Ignorieren' wählen."
L["BTN_UNIGNORE_PLAIN"]  = "Entfernen"
L["IL_IGNORED_MSG"]      = "|cff9B82F3PlayerDossier:|r Ignoriere |cffff2e2e%s|r."
L["IL_UNIGNORED_MSG"]    = "|cff9B82F3PlayerDossier:|r %s wird nicht mehr ignoriert."
L["IL_ALREADY_MSG"]      = "|cff9B82F3PlayerDossier:|r %s wird bereits ignoriert."
L["IL_DECLINED_DUEL"]    = "|cff9B82F3PlayerDossier:|r Duell von ignoriertem Spieler |cffff2e2e%s|r automatisch abgelehnt."
L["IL_DECLINED_INV"]     = "|cff9B82F3PlayerDossier:|r Einladung von ignoriertem Spieler |cffff2e2e%s|r automatisch abgelehnt."
L["IL_WARNING_GROUP"]    = "|cff9B82F3PlayerDossier:|r |cffff2e2eACHTUNG:|r Ignorierter Spieler |cffff2e2e%s|r ist in deiner Gruppe!"
L["POPUP_IGNORE_TEXT"]   = "Grund für das Ignorieren von |cffffffff%s|r (optional):"
L["POPUP_IL_ADD_TEXT"]   = "Spieler ignorieren (Name oder Name-Realm):"
L["BTN_IGNORE_PLAIN"]    = "Ignorieren"

-- ── Reunion notice ────────────────────────────────────────────
L["REUNION_MSG"]         = "|cff9B82F3[PlayerDossier]|r %s%s%s"

-- ── Confirm clear ─────────────────────────────────────────────
L["CONFIRM_CLEAR"]       = "ALLE PlayerDossier-Einträge löschen? Dies kann nicht rückgängig gemacht werden."
L["CLEARED_MSG"]         = "|cff9B82F3PlayerDossier:|r Alle Einträge gelöscht."

-- ── Options panel ─────────────────────────────────────────────
L["TAB_OPTIONS"]              = "Optionen"
L["OPT_SEC_MESSAGES"]         = "Chat-Nachrichten"
L["OPT_CHAT_MESSAGES"]        = "Wieder-Treffen & Warnungen anzeigen"
L["OPT_CHAT_MESSAGES_SUB"]    = "Benachrichtigt dich wenn ein gespeicherter Spieler deiner Gruppe beitritt."
L["OPT_SEC_IGNORE"]           = "Ignorier-Liste"
L["OPT_BLOCK_IGNORED"]        = "Ignorierte Spieler im Chat blockieren"
L["OPT_BLOCK_IGNORED_SUB"]    = "Versteckt Nachrichten von Spielern die über WoWs 50er-Limit hinausgehen."
L["OPT_AUTO_DECLINE"]         = "Duelle & Einladungen automatisch ablehnen"
L["OPT_AUTO_DECLINE_SUB"]     = "Lehnt Duelle und Gruppeneinladungen von ignorierten Spielern automatisch ab."
L["OPT_SEC_LIMIT"]            = "Ignorier-Limit Workaround"
L["OPT_LIMIT_STATUS"]         = "|cffffff00%d / 50|r im WoW-System    |cffaaaaaa%d per Chat-Filter (Überlauf)|r"
L["OPT_LIMIT_INFO"]           = "WoW erlaubt 50 Ignorier-Slots pro Charakter. PlayerDossier nutzt alle 50 davon und filtert den Rest still über das Chat-System – so sind unbegrenzt viele Spieler möglich."
L["OPT_SEC_MINIMAP"]          = "Minimap"
L["OPT_MINIMAP"]              = "Minimap-Button anzeigen"

-- ── Recent Allies ─────────────────────────────────────────────
L["BTN_RECENT_ALLIES"]   = "Kürzl. Verbündete"
L["RECENT_EMPTY"]        = "Keine kürzlichen Verbündeten gefunden.\nSpiele mit anderen in Dungeons oder Raids."
L["RECENT_ADD"]          = "Hinzufügen"
L["RECENT_LOADING"]        = "Lade kürzliche Verbündete vom Server..."

-- ── Ignorier-Liste Spalten ────────────────────────────────────
L["IL_COL_NAME"]   = "Spielername"
L["IL_COL_REALM"]  = "Server"
L["IL_COL_LISTED"] = "Seit"
L["IL_COL_NOTE"]   = "Notiz"

-- ── Spieler-Panel Spalten ─────────────────────────────────────
L["PL_COL_MOOD"]  = "S"
L["PL_COL_NAME"]  = "Spielername"
L["PL_COL_REALM"] = "Server"
L["PL_COL_SINCE"] = "Seit"
L["PL_COL_NOTE"]  = "Notiz"
L["IL_IGNORED_HINT"]    = "Ignoriert"

-- ── Gruppe verlassen / Kick ───────────────────────────────────
L["LINK_REMEMBER"]  = "Zum Dossier"
L["LINK_EDIT"]      = "Bearbeiten"
L["LINK_LEFT_GROUP"]= "hat die Gruppe verlassen"
L["KICKED_MSG"]     = "Du hast die Gruppe verlassen. Jemanden merken?"
L["SLASH_HELP_ADD"]     = "  Rechtsklick auf einen Spieler oder Chat-Namen um ihn hinzuzufügen."

-- ── Klassenfarben Option ──────────────────────────────────────
L["OPT_CLASS_COLORS"]     = "Spielernamen in Klassenfarbe anzeigen"
L["OPT_CLASS_COLORS_SUB"] = "Färbt Namen nach Klasse. Deaktivieren für weiße Namen."

-- ── Aufräumen ─────────────────────────────────────────────────
L["OPT_SEC_CLEANUP"]           = "Aufräumen"
L["BTN_CLEAR_ALL"]            = "Alle entfernen"

L["OPT_CONFIRM_CLEAR_PLAYERS"] = "ALLE Spieler aus dem Dossier entfernen? Dies kann nicht rückgängig gemacht werden."
L["OPT_CONFIRM_CLEAR_IGNORE"]  = "ALLE ignorierten Spieler entfernen? Dies kann nicht rückgängig gemacht werden."
L["OPT_CLEARED_PLAYERS"]       = "|cff9B82F3PlayerDossier:|r Alle Spieler entfernt."
L["OPT_CLEARED_IGNORE"]        = "|cff9B82F3PlayerDossier:|r Alle ignorierten Spieler entfernt."

-- ── Import ────────────────────────────────────────────────────
L["OPT_SEC_IMPORT"]   = "Import"
L["OPT_IMPORT_INFO"]  = "Alle Spieler aus WoWs nativer Ignorierliste in die PlayerDossier Ignorierliste importieren."
L["OPT_IMPORT_BTN"]   = "WoW-Ignorierliste importieren"
L["OPT_IMPORT_DONE"]  = "|cff9B82F3PlayerDossier:|r Import abgeschlossen. %d hinzugefügt, %d bereits vorhanden."

-- ── Auto-Ablehnen Hinweis ─────────────────────────────────────
L["OPT_AUTO_DECLINE_NOTE"] = "Hinweis: Funktioniert nicht wenn ein anderes Addon Einladungen automatisch annimmt (z.B. Gildeneinladungen)."

-- ── LFG ──────────────────────────────────────────────────────
L["OPT_SEC_LFG"]         = "Gruppensuche (LFG)"
L["OPT_LFG_HIDE"]        = "Gruppen mit ignorierten Spielern ausblenden"
L["OPT_LFG_HIDE_SUB"]    = "Blendet LFG-Suchergebnisse aus, wenn der Gruppenleiter oder ein Mitglied auf der PlayerDossier-Ignorierliste steht (nicht nur WoWs native Liste)."
L["LFG_IGNORED_WARNING"]  = "Ignorierter Spieler in dieser Gruppe:"

-- ── Ignorier-Slots voll Warnung ───────────────────────────────
L["IL_SLOTS_FULL"] = "|cff9B82F3PlayerDossier:|r |cffff8800⚠ Alle 50 WoW-Ignorier-Slots sind voll. Weitere Spieler werden nur noch per Chat gefiltert.|r"

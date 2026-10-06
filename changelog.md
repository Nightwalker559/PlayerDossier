# PlayerDossier – Changelog

## [1.1.0] - 2026-10-06

### New
- LFG tooltip: mood icon next to known players in the Leader and Members lines.

### Changed
- Chat filter also covers whispers, guild/officer chat and the leader/warning channels (party, raid, instance).
- Chat filter: a sender with a realm only matches the exact Name-Realm; same-named players on other realms are no longer blocked.
- Mood colors are the same in chat and UI.
- Quieter chat: no more login message and no confirmations for saved notes, "show minimap button" or "remove all". The "ignore slots full" warning now only appears when you ignore someone, not at login.

### Fixed
- Realms with a space in the name ("Tarren Mill") are now stored as WoW reports them ("TarrenMill"); existing entries are migrated automatically.
- LFG tooltip: players on other realms are now found when the member list has no realm.
- Auto-decline of trade requests now actually works.
- No Lua errors from secret sender names in the chat filter and auto-decline (WoW 12.x).
- "Ignored player is in your group" warning prints once instead of repeatedly, and is now localized.
- Saving a note no longer triggers an extra ignore-list sync.
- Whispering players on realms with a space in the name works.
- No bogus reunion notice for yourself in raids.
- Options tab subtitle read "Chat Messages" instead of "Options".

### Internal
- New `Widgets.lua` with shared UI helpers used by the Players, Ignore List and History tabs.
- Init, UI-build and slash commands use registries (`PD:OnInit`, `PD:OnBuildUI`, `PD.commands`) instead of wrapped functions.
- Shared helpers for realm names, group scans, Mythic+ check, moods and secret values.
- Chat filter and native ignore import moved into IgnoreList.lua.
- Dead code and unused locale keys removed, ElvUI skin simplified, all comments in English.

## [1.0.9] - 2026-09-20

### New
- LFG: inline warning directly in the Premade Group Finder search results — group name turns red with a warning icon when the leader or a member is on the ignore list (no hover needed). Toggle: "Show inline warning in group list" (on by default)
- New option "Use WoW's native ignore list" (on by default, matches previous behavior). When turned off, PlayerDossier-ignored players stay addon-only and are never pushed to WoW's built-in ignore list (via C_FriendList.AddIgnore) - useful to keep the 50 native slots free for other purposes. Blocking still works via chat filtering and PlayerDossier's own duel/invite auto-decline either way. Toggling it off immediately removes previously-synced native entries; toggling it back on re-syncs up to 50.

### Changed
- Group leave/kick prompts ("has left the group" / "Anyone worth remembering?") now only appear while an active Mythic+ run is in progress. Normal dungeons and heroics no longer trigger them.

### Fixed
- Crash on right-clicking a player ("attempt to compare ... a secret string value") caused by WoW 12.x's Secret Values privacy system, which can make UnitName() return unreadable values in restricted contexts (e.g. active PvP matches). All UnitName() call sites now go through a shared safe-check (Core.lua: PD:SafeUnitName) and skip gracefully instead of erroring. Affects the player/chat/social right-click menus, group snapshotting, group history, and the ignore list's group-join warning.
- Options panel: description text under each checkbox no longer gets cut off at the panel's right edge (missing right anchor/word wrap). Now wraps properly and rows space themselves dynamically based on how many lines the text needs. Affects both default UI and ElvUI skin.
- Options panel checkboxes now get ElvUI-skinned (square style) instead of staying plain Blizzard checkboxes when ElvUI is loaded.
- Ignore List right-click menu: "Edit" opened the Player Dossier's note dialog (wrong title "Note – Name", mood buttons) instead of editing the ignore entry's own reason. New dedicated "Edit reason" option edits the actual ignore-list reason text; the dossier link is now separately labeled "Edit note in Player Dossier" / "Add to Player Dossier".
- Player/Ignore List/Group History tab headers now share one helper (PD:BuildColumnHeaders) so all three look identical and each column stretches to full width instead of relying on unconstrained text.
- Column positions (Name/Server/Role/Since/last column) are now shared constants (PD.COL) across Players, Ignore List and Group History, so all three tabs line up identically instead of each tab using its own cramped layout.
- Ignore list chat filter cache wasn't cleared after "Remove All", so previously-ignored players could stay silently blocked in chat until reload.

### Removed (cleanup, no behavior change)
- Duplicate, out-of-date `Locale_deDE.lua`/`Locale_enUS.lua` at the addon root (not loaded by the .toc; real locales live in `Locales/`).
- Unused `encounters` field on player entries (written but never read).
- Unused compat aliases `PD:ToggleIgnoreWindow()` and `PD.RefreshIgnoreWindow`.
- Triplicated row-pooling code in UI.lua/IgnoreList.lua/GroupHistory.lua, consolidated into `PD:NewRowPool()` (Core.lua).

## [1.0.8] - 2026-09-18

### New
- Group History tab: auto-logs everyone you group with (class, role, mode, last seen, times grouped)
- Mode column: shows M+ level, Timewalking, Delve, Raid, Dungeon, PvP, or Scenario
- Right-click a History entry to add to Dossier/Ignore List retroactively
- Options: "Track group history" toggle (on by default)
- History capped at 300 entries, oldest trimmed automatically
- Players tab now shows a Role column, pulled from Group History if known

### Fixed
- History header overlap in German locale
- ElvUI tab gap (fixed offset -5)
- Removed unused argument in the ignore-limit status format call (Options.lua)

### Changed
- Toc updated
- Tab order: Players → Ignore List → History → Options
- Group History now only tracks Mythic+ groups. Raids, heroics ("hero runs"), timewalking, delves, scenarios and PvP are no longer logged.
- Version string is now read from the .toc at runtime instead of a hardcoded copy in Events.lua (prevented future version-mismatch bugs)
- Consolidated 3 identical `DaysSince`/`TimeAgo` helper functions (UI.lua, IgnoreList.lua, GroupHistory.lua) into one shared `PD:TimeAgo()` in Core.lua

## [1.0.7] - 2026-08-11

### Changed
- Added Interface 120100 (Patch 12.1 – Curse of Ula'tek) support. No API changes affected this addon.

## [1.0.6] - 2026-06-16

### Fixed
- **Duplicate ignore/unignore menu entries** – Right-clicking a player unit showed two separate Ignore/Unignore buttons (one from the Players section, one added a second time by a redundant hook). Now shows exactly one button per menu.
- **LFG "Hide groups" checkbox state** – The checkbox in Options > Group Finder was not refreshed when switching to the Options tab. It now always reflects the current saved setting.
- **Duel auto-decline message not localized** – The "Auto-declined duel" chat message was hardcoded in English for all locales. It now uses the localization system and also respects the "Chat Messages" toggle.
- **Unnecessary GROUP_ROSTER_UPDATE event** – The ignore list event frame registered GROUP_ROSTER_UPDATE but never handled it, causing a no-op callback on every roster change.

### Changed
- **Chat filter name lookup is now O(1)** – The fallback name-only lookup in the chat filter previously scanned the entire ignore list on every incoming chat message. It now uses a lazy-built cache that is invalidated only when the ignore list changes.
- **`GetNumSubgroupMembers` replaced** – Replaced the deprecated `GetNumSubgroupMembers()` with `GetNumGroupMembers()` in the group member check. Both return the same value for parties; the latter is the current recommended API.

---

## [1.0.5] - 2026-06-13

### Added
- **Copy Name-Realm** – Right-clicking a player in the Players list or the Ignore List now includes a "Copy Name-Realm" option. The full `Name-Realm` string is copied to the clipboard, ready to paste into raider.io, WarcraftLogs, or any other site. A confirmation message appears in chat (respects the chat messages setting).

---

## [1.0.4] - 2026-06-01

### Fixed
- **Chat message spam** – Reunion notices and leave prompts no longer appear multiple times when someone joins or leaves the group. WoW fires GROUP_ROSTER_UPDATE 3–5 times per roster change; all bursts are now collapsed into a single update.
- **Wrong reunion notices** – Joining a new group member no longer re-announces everyone already in the group. Only the newly arrived player triggers a reunion notice.
- **Ignored players not blocked in chat** – Players on the PlayerDossier ignore list (beyond WoW's 50-slot limit) were silently let through if their realm name contained a hyphen (e.g. Azjol-Nerub, Blade's Edge). Fixed in chat filter, auto-decline, and import.
- **LFG group hiding flickers** – Groups containing ignored players now stay hidden while scrolling or when the list refreshes. Previously the hide was immediately undone by WoW's internal frame recycling.
- **Duplicate chat filter** – A second, non-functional chat filter was registered on load (always disabled due to an unset flag). Removed.

---

## [1.0.3] - 2026-05-29

### Fixed
- IL_Sync now removes WoW native ignores when the addon ignore list is empty (e.g. after "Remove All")
- ElvUI: Minimap button no longer shows black square background
- ElvUI: Minimap button skin wrapped in pcall to prevent nil method errors on load

---

## [1.0.2] - 2026-05-27

### Fixed
- Menu taint: wrapped all menu callbacks in securecallfunction to prevent SetRaidTarget() and other protected functions from being tainted
- Tooltip: mood emoji, name and note now displayed on one line (previously split across multiple lines, emoji not visible)
- Party invite popup no longer shown when auto-declining ignored players (`StaticPopup_Hide` added)
- Chat filter now blocks ignored players even if on friends list or without realm suffix
- LFG group hiding now persistent — re-applies on ScrollBox update, not just on initial search
- Group leave/kick prompts no longer shown when leaving a raid (5-man only)
- German chat message: "Ignoriere Spieler" corrected to "Ignoriert Spieler"
- Removed ⚠ symbol from "ignore slots full" chat message (not supported in WoW chat)
- `notifiedThisSession` variable declared before `CheckGroupMembers()` (nil error on login)
- Auto-decline hint text updated: guild invites are now also declined; warning generalized to reflect any addon conflict

### Changed
- Players list sorted by mood (Good → Neutral → Bad) then alphabetically by name within each mood group
- Options tab sections sorted alphabetically (Group Finder → Ignore List → Ignore Limit → Import → Minimap → Messages)
- LFG hide-groups tooltip clarified: explicitly mentions PlayerDossier ignore list, not just WoW's native list

### Removed
- 35 dead locale keys (CF_*, BTN_ADD_PLAYER, RECENT_*, TAB_FILTER, MM_CHAT_FILTER, etc.)
- Dead `ToggleChatFilterWindow()` function from UI.lua

---

## [1.0.1] - 2026-05-25

### Fixed
- Options tab showed "50 / 45 in WoW system" instead of "50 / 50"
- Ignore list subtitle was hardcoded in English instead of using localization
- Tab text shifted downward when active (PanelTabButtonTemplate push effect)
- ElvUI skin: ignore list scrollbar and "Remove All" button not skinned on first open
- Mood button selection not visible in ElvUI skin (now uses alpha + font size)
- Chat menu (guild chat, etc.) missing ignore option
- Slots-full warning appeared twice in chat on login (now shown once per session)
- `PARTY_INVITE_REQUEST`: `arg2` is a boolean in WoW 12.0, not a realm string — caused crash in `GetKey()`
- `GUILD_INVITE_REQUEST` and `TRADE_REQUEST`: same arg parsing fix
- `GetKey()` now guards against non-string realm values

### Added
- `GUILD_INVITE_REQUEST` auto-decline for ignored players
- `TRADE_REQUEST` auto-decline for ignored players
- `IGNORELIST_UPDATE` event sync — native flags refresh when WoW's list changes externally
- LFG tooltip shows PlayerDossier notes and mood emoji for known players
- LFG tooltip warns when an ignored player is in a group
- Option to hide LFG groups containing ignored players
- Import button for WoW's native ignore list (Options tab)
- WoW ignore list now uses all 50 native slots (previously capped at 45)
- Warning in chat when all 50 native ignore slots are full (once per session)
- Class-colored names in chat leave/kick prompts
- Class saved automatically from group snapshot on leave/join
- Class passed through clickable chat hyperlinks
- "Remove All" button added to Players tab and Ignore List tab

### Changed
- "Remove All" buttons moved from Options tab into Players and Ignore List tabs
- Tab width auto-sized to widest label text (no more truncation)
- Note max length reduced from 150 to 60 characters
- Timestamps show hours (`<1h`, `3h`) instead of always `0d`
- Ignore list names always white (class colors only in Players list)

---

## [1.0.0] - 2026-05-23

### Initial Release
- Player dossier with notes and mood (Good / Neutral / Bad)
- Ignore list with overflow beyond WoW's 50-slot limit via chat filter
- Auto-decline duels and group invites from ignored players
- Clickable chat links when players leave group
- Reunion notices when meeting tracked players in group
- ElvUI skin support
- Minimap button (LibDBIcon)
- Slash commands: `/pd`, `/pd ignore`, `/pd minimap`, `/pd clear`, `/pd help`
- Localization: enUS, deDE

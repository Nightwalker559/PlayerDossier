# PlayerDossier – Changelog

## [1.0.1] - 2026-05-25

### Fixed
- Options tab showed "50 / 45 in WoW system" instead of "50 / 50"
- Ignore list subtitle was hardcoded in English instead of using localization
- Tab text shifted downward when active (PanelTabButtonTemplate push effect)
- ElvUI skin: ignore list scrollbar and "Remove All" button not skinned on first open
- Mood button selection not visible in ElvUI skin (now uses alpha + font size)
- Chat menu (guild chat, etc.) missing ignore option
- Slots-full warning appeared twice in chat on login (now shown once per session)
- `PARTY_INVITE_REQUEST`: `arg2` is a boolean in WoW 12.0, not a realm string — caused crash in `GetKey()` when concatenating boolean value
- `GUILD_INVITE_REQUEST` and `TRADE_REQUEST`: same arg parsing fix
- Options tab sections sorted alphabetically (Group Finder → Ignore List → Ignore Limit → Import → Minimap → Messages)
- LFG "Hide ignored groups" tooltip clarified to mention it's the PlayerDossier ignore list, not just WoW's native list

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
- Cleanup section removed from Options tab
- Tab width auto-sized to widest label text (no more truncation)
- Note max length reduced from 150 to 60 characters
- Timestamps show hours (`<1h`, `3h`) instead of always `0d`
- Ignore list names always white (class colors only in Players list)
- All changelog entries written in English

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

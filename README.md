# PlayerDossier

**Track the players you meet, remember what you thought of them, and block the ones you never want to see again — without the 50-slot ignore limit.**

PlayerDossier is a player manager for World of Warcraft (Retail, 12.x). It combines a personal notebook for players, an unlimited account-wide ignore list, an automatic group history and Group Finder (LFG) warnings in one window.

## Features

### Players (the "dossier")
- Add any player with a **note** (up to 60 characters) and a **mood**: Good, Neutral or Bad.
- Add players via right-click on a unit frame, a chat name, the group frames or the social menus.
- The list is sorted by mood (Good → Neutral → Bad), then by name, and shows class color, server, role, time since you added them and your note.
- **Copy Name-Realm** from the context menu, ready to paste into raider.io or WarcraftLogs.
- Get a **reunion notice** in chat when a tracked player joins your group.

### Ignore List — no 50-slot limit
- Account-wide ignore list with an optional reason per player.
- The 50 most recent entries are also added to WoW's native ignore list, so every built-in WoW feature respects them. Everything beyond that is blocked silently through a chat filter, which effectively gives you unlimited ignores.
- Optionally keep the list inside PlayerDossier only and leave WoW's native list untouched ("Use WoW's native ignore list").
- **Auto-decline** duels, party invites, guild invites and trade requests from ignored players.
- **Import** your existing WoW ignore list with one click.

### Group Finder (LFG)
- **Inline warning:** a group whose leader or member is on your ignore list is marked red with a warning icon directly in the search results, no hover needed.
- **Tooltip:** hover a group to see the mood icon right next to the names of known players in the Leader and Members lines, plus a PlayerDossier block with your notes. Works with players from other realms and alongside Raider.IO tooltips.
- **Hide groups** that contain ignored players (optional).

### Group History
- Automatically logs everyone you group with in **Mythic+** (class, role, M+ level, last seen, how often you grouped).
- Right-click an entry to add that player to your Dossier or Ignore List after the fact.
- Capped at 300 entries; the oldest are trimmed automatically. Can be turned off.

### Everything else
- Minimap button (LibDBIcon / LibDataBroker).
- Built-in **ElvUI skin** support.
- Localization: English and German.

## Installation

1. Download the latest release (or clone this repository).
2. Place the `PlayerDossier` folder in `World of Warcraft/_retail_/Interface/AddOns/`.
3. Start the game (or `/reload`).

## Usage

| Command | Action |
| --- | --- |
| `/pd` | Open the dossier (Players tab) |
| `/pd ignore` | Open the Ignore List tab |
| `/pd minimap` | Toggle the minimap button |
| `/pd clear` | Delete **all** dossier entries (asks for confirmation) |
| `/pd help` | Show the command list |

`/playerdossier` and `/dossier` work as aliases for `/pd`.

The window has four tabs: **Players**, **Ignore List**, **History** and **Options**.

## Options

| Section | Setting |
| --- | --- |
| Chat Messages | Reunion and warning messages in chat |
| Ignore List | Block ignored players in chat · Use WoW's native ignore list · Auto-decline duels and invites |
| Group Finder | Hide groups with ignored players · Inline warning in the group list |
| Group History | Track group history |
| Import | Import WoW's native ignore list |
| Minimap | Show minimap button |

## Notes

- Auto-decline may not work if another addon accepts invites before PlayerDossier can react.
- All data is stored account-wide in the `PlayerDossierDB` SavedVariable.
- Supports WoW 12.x (Midnight) including its Secret Values restrictions: names that can't be read in restricted situations (for example active PvP matches) are skipped instead of causing errors.

## Changelog

See [changelog.md](changelog.md).

## License

[MIT](LICENSE) © Nightwalker559

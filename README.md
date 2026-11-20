# PlayerDossier

Track the players you meet, remember what you thought of them, and block the ones you never want to see again, without the 50-slot ignore limit.

A player manager for World of Warcraft Retail (Midnight, 12.x): a personal notebook, an unlimited account-wide ignore list, an automatic group history and Group Finder warnings in one window. English and German. ElvUI skin supported.

**Author:** Nightwalker559 · **License:** MIT with AI restriction

---

## Features

- **Dossier:** add any player with a note (up to 60 characters) and a mood (Good, Neutral, Bad) via right-click on a unit frame, chat name, group frames or the social menus. The list shows mood, class color, server, role, time since you added them and your note; click a column header to sort. A **reunion notice** appears in chat when a tracked player joins your group, and **Copy Name-Realm** helps with raider.io or WarcraftLogs.
- **Ignore list without the limit:** account-wide, with an optional reason per player (the dossier note is prefilled). The 50 most recent entries also go into WoW's native ignore list, everything beyond is blocked silently through a chat filter. Optionally keep the list inside PlayerDossier only. Duels, party, guild and trade requests from ignored players are **declined automatically**, and one click **imports** your existing WoW ignore list.
- **Group Finder:** groups with an ignored leader or member are marked red "!IGNORED" in the search results, groups with a Bad-mood player orange "!WARNING". Tooltips show which members are ignored (with reason) or in your dossier (with your note), also for applicants and players from other realms, alongside Raider.IO tooltips.
- **Group history:** logs everyone you group with in Mythic+ (class, role, level, last seen, how often). Right-click an entry to add that player to your Dossier or Ignore List. Capped at 300 entries, can be turned off.
- **Window:** four tabs (Dossier, Ignore List, History, Options), a minimap button, mood icons as Faces, Subtle or Cats.

## Commands

| Command | Action |
| --- | --- |
| `/pd` | Open the dossier |
| `/pd ignore` | Open the Ignore List tab |
| `/pd minimap` | Toggle the minimap button |
| `/pd clear` | Delete **all** dossier entries (asks for confirmation) |
| `/pd help` | Show the commands |

`/playerdossier` and `/dossier` work as aliases for `/pd`.

## Notes

- Auto-decline may not work if another addon accepts invites first.
- All data is account-wide (`PlayerDossierDB`). Names that cannot be read in restricted situations (e.g. active PvP matches) are skipped instead of causing errors.

---

See the [changelog](https://github.com/Nightwalker559/PlayerDossier/blob/main/CHANGELOG.md) for the version history.

## Feedback

Found a bug or have an idea? [Open an issue on GitHub](https://github.com/Nightwalker559/PlayerDossier/issues).

## License

MIT with AI restriction (no use for AI or machine learning), see [LICENSE.md](https://github.com/Nightwalker559/PlayerDossier/blob/main/LICENSE.md).

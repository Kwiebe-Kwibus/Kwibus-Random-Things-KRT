# Kwibus Random Things (KRT)

[![Addon Version](https://img.shields.io/badge/Version-1.5.0-blue.svg)](https://www.esoui.com/downloads/info4450-KwibusRandomThingsKRT.html)
[![ESO API](https://img.shields.io/badge/API-101050%20101051-green.svg)](https://www.esoui.com/downloads/info4450-KwibusRandomThingsKRT.html)
[![ESOUI Download](https://img.shields.io/badge/ESOUI-KRT-orange.svg)](https://www.esoui.com/downloads/info4450-KwibusRandomThingsKRT.html)

**Kwibus Random Things (KRT)** is a modular, high-performance miscellaneous utility and raid assistance addon for *The Elder Scrolls Online* (ESO).

Instead of running a dozen disparate standalone addons for small interface tweaks, combat reminders, and group automation, KRT bundles them into a single, unified, lightweight addon. Every module can be independently enabled, disabled, and customized from the standard Addon Settings menu.

---

## Download & Links

* **ESOUI Download**: [Kwibus Random Things (KRT) on ESOUI](https://www.esoui.com/downloads/info4450-KwibusRandomThingsKRT.html)
* **GitHub Repository**: [Kwibus-Random-Things-KRT](https://github.com/Kwiebe-Kwibus/Kwibus-Random-Things-KRT)

---

## Included Modules

### 1. ISIIbus Equipped (`Modules/ISI.lua`)
An enhanced on-screen equipment and set tracker HUD (adapted with permission from *Isiimode* and heavily optimized).
* **Equipped Set Bonuses**: Displays currently equipped set piece counts (e.g., `5/5`, `2/2` Monster Sets, `1/1` Mythic items). Complete sets glow green; incomplete sets display red.
* **Bar Location Tags**: Indicates where sets are slotted:
  * `(b)` &mdash; Body armor
  * `(fb)` &mdash; Front Bar weapon
  * `(bb)` &mdash; Back Bar weapon
  * `(wp)` &mdash; Both weapon bars
* **Armor Weights**: Displays your equipped Light, Medium, and Heavy armor distribution color-coded in Champion Point hues.
* **Armor Traits**: Displays aggregate armor traits (Divines, Infused, Sturdy, Reinforced, etc.) with thematic color-coding.
* **Jewelry Traits (v1.5.0)**: Displays aggregate jewelry traits (Bloodthirsty, Infused, Swift, Harmony, Triune, etc.) with dedicated color coding and zero-allocation recycling pools.
* **Missing Gear & Ability Warnings**: Warns if armor or weapon slots are empty, or if an action bar ability cannot be used with your currently equipped weapon.
* **Customization**: Fully movable overlay with scale, column widths, background opacity, and visibility toggles in menus and combat.

### 2. Kromitor Moment (`Modules/KM.lua`)
A dedicated reminder and skill-blocker for tanks and supports running the *Archdruid Devyric* monster set.
* Displays an on-screen visual alert (`ARCHDRUID READY`) when 2 pieces of Archdruid Devyric are equipped and Major Vulnerability needs to be applied.
* **Optional Skill Blocker**: Integrates with *LibSkillBlocker* to prevent accidentally casting configured filler skills (e.g. Flare or Silver Leashes) while Archdruid is ready to trigger with a heavy attack.
* Test command: `/kmtest`

### 3. Kwibus Colorless Pool (`Modules/KCP.lua`)
Debuff tracker for the Scribing skill *Colorless Pool*.
* Reminds you on-screen (`BRITTLE MISSING!`) when you have Colorless Pool slotted and the target lacks Minor Brittle, ensuring near-100% debuff uptime.

### 4. Kwibus in Combat (`Modules/KIC.lua`)
* Displays an on-screen popup notification upon entering combat (`IN COMBAT` in red) and leaving combat (`OUT OF COMBAT` in green).
* Customizable screen positioning, sound effects, and fade animations.
* Test command: `/kic`

### 5. Kwibus Reset (`Modules/KWR.lua`)
* Detects trial instance resets after group wipes.
* Displays a Center Screen Announcement (CSA) and chat notification (`TRIAL RESET`) so the raid group knows exactly when the instance has reset and is safe to enter.

### 6. Kwibus Spaulder & Auto Lead Pass (`Modules/KWS.lua`)
Comprehensive group management tool for farming mythic leads (such as *Spaulder of Ruin*) or handling trial lockouts.
* Automates passing group leadership back and forth between the designated anchor and the player managing reinvites.
* Handles kicking designated players, waiting for them to leave the instance, passing lead, and re-inviting.
* Includes a UI panel with player profiles, dropdown selectors, and customizable delay timings.

### 7. Kwibus Auto Log / Encounter Auto Log (`Modules/EAL.lua`)
* Automatically manages ESO's `/encounterlog` logging state based on zone type and difficulty.
* Independently toggle auto-logging for:
  * Trials
  * Dungeons
  * Arenas
  * Houses
  * PvP (Cyrodiil, Imperial City, Battlegrounds)
* Option to restrict logging strictly to Veteran content to keep log file sizes clean.
* Displays a movable HUD indicator (`Logging` / `Not Logging`).

### 8. Kwibus Confirm (`Modules/KAC.lua`)
* Automatically populates the text confirmation field with `CONFIRM` (or localized equivalents, with full Cyrillic support) in destructive confirmation dialogs (such as deconstructing, deleting, or destroying items).

### 9. Group User ID (`Modules/GUID.lua`)
* When ESO's "Prefer User IDs" setting is enabled, ensures account display names (`@AccountName`) are consistently displayed across the group list, leaderboards, Emperor display, and social panels.
* Eliminates confusing switching between character names and account names in raid UI.

### 10. Kwibus Overload Watcher (`Modules/KOW.lua`)
* Displays a clear on-screen warning banner whenever the Sorcerer *Power Overload* or *Energy Overload* ultimate is toggled on.
* Helps Sorcerers avoid accidentally draining all their Ultimate between pulls or during mechanic phases.

### 11. Kwibus Skip Pregame Intro (`Modules/KSPI.lua`)
* Directly manages ESO's engine client variable (`SkipPregameVideos`) in `UserSettings.txt`.
* Skips the opening Bethesda and ZeniMax logo cinematics on game launch, booting straight into the login screen.
* Displays the live engine CVar status directly in the settings panel.

### 12. Kwibus Language Swap (`Modules/KLS.lua`)
* Prompts to switch game language to English when entering a Trial, and prompts to switch back to Russian after leaving.

---

## Dependencies

### Required
* [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html) (&ge; 41) &mdash; Required to render the in-game settings panel.

### Optional
* [LibSkillBlocker](https://www.esoui.com/downloads/info3479-LibSkillBlocker.html) (&ge; 110) &mdash; Required only if using the skill-blocking functionality in *Kromitor Moment*.

---

## Installation

### Via Minion (Recommended)
1. Open the [Minion Addon Manager](https://minion.mmoui.com/).
2. Search for **Kwibus Random Things (KRT)**.
3. Click **Install**.

### Manual Installation
1. Download the latest release from [ESOUI](https://www.esoui.com/downloads/info4450-KwibusRandomThingsKRT.html) or [GitHub Releases](https://github.com/Kwiebe-Kwibus/Kwibus-Random-Things-KRT/releases).
2. Extract the archive into your ESO AddOns directory:
   * **Windows**: `Documents\Elder Scrolls Online\live\AddOns\KwibusRandomThings`
   * **Mac**: `Documents/Elder Scrolls Online/live/AddOns/KwibusRandomThings`
3. Restart or reload the game (`/reloadui`).

---

## Slash Commands

| Command | Description |
| :--- | :--- |
| `/kic` | Test the *Kwibus in Combat* visual popup and sound effect. |
| `/kmtest` | Test the *Kromitor Moment* Archdruid alert banner. |

All settings can be configured in **Settings &rarr; Addons &rarr; Kwibus Random Things**.

---

## Author & Acknowledgements

* **Author**: |ce6202dKwiebe-Kwibus|r (wicked_prophet)
* **Special Thanks**:
  * *Isiimode* for permission to adapt and expand upon the item set tracker concept in *ISIIbus Equipped*.
  * The ESO addon development community for *LibAddonMenu* and *LibSkillBlocker*.

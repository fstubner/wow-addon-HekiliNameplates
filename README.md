# HekiliNameplates

A World of Warcraft addon that moves [Hekili](https://www.curseforge.com/wow/addons/hekili) recommendation frames to sit directly beneath your current target's nameplate — keeping the suggested spell rotation right where your eyes already are during combat.

![Interface: 12.0.1](https://img.shields.io/badge/Interface-12.0.1%20%28Midnight%29-C69B3A?style=flat-square)
![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)
![Requires: Hekili](https://img.shields.io/badge/Requires-Hekili-blueviolet?style=flat-square)

## What it does

When you target an enemy, HekiliNameplates automatically repositions the selected Hekili display frames to appear below that target's nameplate. When you drop target, all frames snap back to their saved default positions.

- Anchors below the **cast bar** when one is active, or below the **health bar** otherwise
- Horizontally **centres** the Hekili frame under the nameplate
- Supports all five Hekili display types: Primary, AOE, Defensives, Interrupts, Cooldowns
- Per-frame enable/disable toggles so you only move what you want
- Configurable X/Y offset with live preview
- Settings persist across sessions via saved variables

## Installation

**Requirement:** [Hekili](https://www.curseforge.com/wow/addons/hekili) must be installed and enabled.

1. Download or clone this repository.
2. Copy the `HekiliNameplates` folder into your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/HekiliNameplates
   ```
3. Launch WoW (or `/reload`) and enable both Hekili and HekiliNameplates in the AddOns menu.

## Configuration

Open the options panel with `/hn` or any of the commands below:

| Command | Description |
|---|---|
| `/hn` | Open the options panel |
| `/hn enable` | Enable nameplate anchoring |
| `/hn disable` | Disable nameplate anchoring |
| `/hn x <value>` | Set horizontal offset (e.g. `/hn x -10`) |
| `/hn y <value>` | Set vertical offset (e.g. `/hn y -8`) |
| `/hn about` | Show version info |
| `/hekilinameplates` | Alias for `/hn` |

## How it works

HekiliNameplates listens for `PLAYER_TARGET_CHANGED`, `NAME_PLATE_UNIT_ADDED/REMOVED`, and cast-related events. On each update it:

1. Looks up the active nameplate for `"target"` via `C_NamePlate.GetNamePlateForUnit`
2. Picks the best anchor — cast bar if visible, health bar otherwise
3. Calculates the horizontal offset needed to centre the Hekili frame under the nameplate width
4. Calls `SetPoint` on each enabled Hekili frame
5. Restores saved default positions when no target is selected

## Compatibility

- **Interface:** 12.0.1 (The War Within / Midnight)
- Requires Hekili (any recent version)
- No other dependencies

## License

MIT

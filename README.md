# Character-Tracker

Elder Scrolls character tracker for iOS

[Download on the App Store](https://apps.apple.com/us/app/character-tracker-for-skyrim/id1500330869)

## Overview

Character Tracker is an iOS app for keeping track of characters and other information for Skyrim or other games. This app is for players who might lose track of their many characters. You'll never again have to ask yourself questions like "Was I going to do the Thieve's Guild quest line on my assassin or my archer?" or "Was I going to bother with Enchanting on my fighter?"

### Features

* Track information about characters including:
  * Skills
  * Combat Styles
  * Questlines
  * Houses
  * Equipment
  * Followers
  * and more
* Track crafting ingredients for armors, weapons, etc.
* Organize game mods and custom content
* Scan QR codes to import data from a game mod

[Changelog](Changelog.md)

### Screenshots

<img src="Images/Screenshots/iPhone 11 Pro Max 1 - Characters.png" height=400 /> <img src="Images/Screenshots/iPhone 11 Pro Max 4 - Character Dark Collapsed.png" height=400 /> <img src="Images/Screenshots/iPhone 11 Pro Max 3 - Module.png" height=400 /> <img src="Images/Screenshots/iPhone 11 Pro Max 5 - Ingredients.png" height=400 />

### QR Codes

In Character Tracker you can scan QR codes to import new data, such as new equipment, followers, etc.

You can create QR codes in the app by tapping the "Export" button at the botton of mod and module screens.
You can also automatically generate QR codes for armor mods, including level and crafting requirements, using [xEdit Armor Export](https://github.com/Isvvc/xEdit-Armor-Export).

Below is an example QR code for the Skyrim mod [Nordic Wanderer Equipment](https://www.nexusmods.com/skyrim/mods/69103/) ([Skyrim Special Edition](https://www.nexusmods.com/skyrimspecialedition/mods/7943)).

These QR codes are very dense and may be difficult to scan. **Click the QR code for a full-size image**. Open on a large display for easier scanning.

[<img src="Images/Nordic Wanderer.png" height=400 />](https://raw.githubusercontent.com/Isvvc/Character-Tracker/master/Images/Nordic%20Wanderer.png)

This will add the Nordic Wanderer Equipment to your mods list, including images and the crafting recipe, which can be added to any character.

### Planned features

* Custom games
* Custom attribute and module types
* Link images to characters
* Allow mods to add:
  * Attributes
  * Races
* Import and export characters

## Build

Building Character Tracker requires Xcode 12+ on macOS 10.15 or later for
+ iOS Swift Package Manager support
+ SwiftUI 2

### Dependencies

Dependencies are either included in-code or obtained through Swift Package Manager.

* [Pluralize.swift](https://github.com/joshualat/Pluralize.swift) (included)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [EFQRCode](https://github.com/EFPrefix/EFQRCode)
* [SDWebImage](https://github.com/SDWebImage/SDWebImage)
* [ActionOver](https://github.com/AndreaMiotto/ActionOver)

There may be build warnings for SPM packages about an iOS 8 deployment target.
These are issues with the packages themselves and can safely be ignored.

## License

This project is open-source and licensed under the [The 2-Clause BSD License](LICENSE).

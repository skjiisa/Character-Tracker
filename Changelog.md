# Character Tracker Changelog

## v1.2.1

Bug fixes and minor improvements [#120](https://github.com/Isvvc/Character-Tracker/pull/120)

* Prevent crash when removing ingredients and modules from a mod
* Prevent loading invalid data from QR codes

## v1.2

Released 2020 October 12

### Major Features

You can now track game mods!
These are a way of better organizing new modules and ingredients.

Along with Mods comes QR code scanning.
From a module or mod in the app, you can now generate a QR code
which can be scanned by other users to load that data into their app.

You can also use [xEdit Armor Export](https://github.com/Isvvc/xEdit-Armor-Export)
on PC to automatically generate QR codes for armor mods.

## v1.1

Rejected from App Store.

### Major Features

* New preloaded data for Skyrim ([#91](https://github.com/Isvvc/Character-Tracker/pull/91))
  * Questlines
  * Houses
  * Objectives
  * Followers
  * Combat Styles
  * Fix existing typo
* Add search bars to Attributes, Modules, and Ingredients lists ([464e5c2](https://github.com/Isvvc/Character-Tracker/commit/464e5c2dde75cd900005065b5f6023a3d765611f), [6ab1906](https://github.com/Isvvc/Character-Tracker/commit/6ab1906d0a9033711fbb17cde428fcabf40c4198))
* Add filtering to Modules and Attributes lists ([#92](https://github.com/Isvvc/Character-Tracker/pull/92))
* Show which modules have been added to and completed by other characters ([#92](https://github.com/Isvvc/Character-Tracker/pull/92))

### Minor improvements

* Dismiss New Character modal after saving ([a1c7ab7](https://github.com/Isvvc/Character-Tracker/commit/a1c7ab7fcce36a04e492b0bd5b3dd92a81f729d9))
* Disable adding attributes and modules to new characters as it did not work ([a1c7ab7](https://github.com/Isvvc/Character-Tracker/commit/a1c7ab7fcce36a04e492b0bd5b3dd92a81f729d9))
* Hide "View Required Ingredients" if there are no required ingredients ([152ef21](https://github.com/Isvvc/Character-Tracker/commit/152ef219d109d3820261578ecb9594f793aeeb68))
* Show number of characters per game when selecting a game ([3346bb4](https://github.com/Isvvc/Character-Tracker/commit/3346bb427ff23085c1fac1da1705bd979a83d070))
* Make ingredient info dialogue more clear ([2d7efda](https://github.com/Isvvc/Character-Tracker/commit/2d7efdae07b629ae5741fc879f646085934d3e5a))
* Automatically scroll to things in lists after they're created ([af76ef7](https://github.com/Isvvc/Character-Tracker/commit/af76ef7b88cda0c8b37cc0067be8000e090a206e))
* Performance improvements ([#88](https://github.com/Isvvc/Character-Tracker/pull/88) among other commits)

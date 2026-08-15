# Changelog

All notable changes to Dumpster will be documented here.

## 2026-08-15 - 12.002

### Added

- Full Retail Character Bank support using Blizzard's modern Character Bank tab containers.
- Full Retail Warband Bank deposit and withdrawal support.
- Automatic detection of the currently selected Character or Warband Bank.
- Baganator Character Bank and Warband Bank compatibility.
- EllesmereUI compatibility through its exposed bank compatibility API.
- Modular bank detector system for easier support of replacement bank interfaces.
- Bank compatibility diagnostic commands:
  - `/dumpster banktype`
  - `/dumpster bankdebug`
  - `/dumpster bankframes`
- Expansion exclusion filters:
  - `/notcurrent`
  - `/notexp <expansion>`
  - `/exceptexp <expansion>`
- Midnight expansion aliases:
  - `/mn`
  - `/midnight`
- The Last Titan expansion aliases:
  - `/tlt`
  - `/thelasttitan`

### Changed

- Updated Retail Character Bank handling to use `CharacterBankTab_1` through `CharacterBankTab_6`.
- Updated Retail Warband Bank handling to use `AccountBankTab` containers.
- `/din` now explicitly targets the selected Character or Warband Bank type.
- `/dout` now scans the correct modern Character or Warband Bank containers.
- Improved replacement bank-interface handling through Blizzard state, generic addon compatibility APIs, and targeted fallbacks.
- Improved Guild Bank detection so replacement bank interfaces no longer need the Blizzard Guild Bank frame to be visible.
- Bank diagnostics no longer globally enumerate visible frames on Retail, avoiding secret-value/taint errors.
- Expanded expansion qualifier handling and aliases.

### Fixed

- Fixed `/din` depositing items into the Character Bank when the Warband Bank was selected.
- Fixed `/dout` failing to withdraw from modern Retail Character Bank tabs.
- Fixed Guild Bank transfers being queued but cancelled when Baganator replaced the Blizzard Guild Bank frame.
- Fixed duplicate expansion aliases causing `/tww` and `/warwithin` to resolve incorrectly.
- Fixed Retail tooltip filtering after compatibility refactoring.
- Fixed bank compatibility detection with EllesmereUI.
- Fixed several replacement-bank UI detection paths where Blizzard's `BankFrame:GetActiveBankType()` returned `nil`.

## 2026-08-14 - 12.001

- Refactored the monolithic addon into Core, Compatibility, Commands, Parser, Items, Transfers, GuildBank, and UI modules.
- Centralized shared debug/delayed state and inventory compatibility handling.
- Fixed saved-set listing/counting for keyed saved variables.
- Replaced hard-coded guild-bank/mail attachment slot counts with Blizzard constants when available.
- Registered `MAIL_SHOW` through AceEvent and localized several leaked UI/global variables.
- Preserved existing slash-command syntax and saved-set format.
- Modernized Retail tooltip scanning using Blizzard's structured tooltip APIs.
- Centralized container and bank API handling in the compatibility layer.
- Improved Retail account/Warband bank support.
- Cleaned up guild-bank queue and transfer state handling.
- Consolidated client support around a single codebase and TOC.

## 2026-03-02 - 12.0

- Updated TOC.

## 2025-07-05 - 11.3

- Added Bagnon references for the guild bank.

## 2025-07-05 - 11.2

- Fixed multiflag handling.
- Added new expansions.

## 2024-09-07

- Fixed interface errors.
- Added Warband bank extraction.

## 2023-12-08

- Updated the addon to work across multiple variants of World of Warcraft.
- Retail: Guild bank queue will cancel if the Guild Bank closes.

## 2022-12-15

- Updated reagent bag support.
- Updated guild bank event handling.

## 2019-03-07

- Bumped TOC.
- Refreshed Ace libraries.
- Added guild bank throttling workaround.
- Reagent Bank now works with `/dout`.
- Added error handling for pets/toys.
- Added expansion filters:
  - `/classic`
  - `/tbc`
  - `/wotlk`
  - `/cata`
  - `/mop`
  - `/wod`
  - `/legion`
  - `/bfa`

## 2018-07-23

- Bumped TOC.
- Refreshed Ace libraries.
- Updated code with suggestions from Neevar on Curse to help with cross-realm mail and Account Bound items.

## 2017-04-25 - 7.1

- Bumped TOC.
- Refreshed Ace libraries.

## 2010-10-16 - 4.1

- Fixed tooltip scanning.
- Found two more `"this"` errors with sets.
- Updated included Ace3.
- Changed `getglobal()` usage to `_G[]`.
- Fixed adding a new set.
- Fixed error when no sets are defined, such as during first run.

## 2010-10-13 - 4.0

- Bumped TOC.
- Fixed issue with `"this"` error.

## 2009-04-25 - 2.1

- Bumped TOC.

## 2009-04-13 - 2.0

- Added GUI interface for editing sets (`/dumpster`).
- Added ability to use set names in conjunction with other parameters.
- Added GUI help.

## 2009-03-05 - 1.9

- Added color based on status:
  - Green - dumped everything requested, which may be nothing in the case of `/only`.
  - Red - dumped nothing.
  - Blue - dumped some, but not all.
- Fixed a bug with dump counts when chaining commands.

## 2009-01-27 - 1.8

- Fixed some bugs with `/except`.
- Rewrote option parsing to be more flexible. This allows easier addition of options and prevents options from clobbering each other.
- Fixed a bug where `/din` to mail would add an unnecessary delay.
- Added sets. Any command line normally used with Dumpster can be made a set.

Commands:

    /dadd setname setdetails
    /ddel setname
    /dlist

Example:

    /dadd frostbag /to mistertailor 60 Frostweave Cloth; 12 Infinite Dust; 2 Eternium Thread
    /din frostbag

## 2009-01-24 - 1.7

- Fixed bug in `/dall` only checking the first two tabs.
- Fixed option parsing for `/except`.

## 2009-01-21 - 1.6

- Added `/except` parameter.

      /din /except apple

  Dumps everything except apples.

- Added `/remain` parameter.

  If you have 20 apples:

      /din 2 /remain apple

  Dumps 18 of them.

- Removed a fair amount of code duplication.
- Changed option parsing to allow numbers anywhere:

      /din 2 /full apple
      /din /full 2 apple

- Changed some magic numbers to actual constants, for example `BANK_CONTAINER` instead of `-1`.
- Automatically set mail to the Inbox or Send Mail frame depending on whether `/din` or `/dout` is being used.
- Added `/to` option for `/din` to mail.

      /din 2 apple /to HoboJoe

  Mails 2 apples to HoboJoe. `/to` is ignored elsewhere.

- Added command chaining:

      /din 2 apple; 3 block; 1 pear tree

- Fixed mail `/dout` skipping some messages.
- Improved performance by only retrieving tooltips when they are actually needed.

## 2009-01-13 - 1.5

- Changed to load on demand only for AddonLoader.
- Fixed `/dall`. `/dall` dumps from every tab of the guild bank.
- Updated embedded version of Ace.
- Moved to a `searchoptions` (`so`) dictionary for parameter passing instead of large argument lists.
- Added `/full` and `/partial` for only dumping full or partial stacks.
- Added `/dout` for merchants.

      /dout 4 Sacred Candle

  Buys 4 Sacred Candles.

  If an item is sold by the vendor in stacks, the number refers to stacks. For example:

      /dout 4 arrow

  With arrows sold in stacks of 200, this buys 800 arrows.

- Added `/dout` for mail to pull items from mail.
- Added `/only`.

      /dout 10 /only apple

  If you already have 3 apples, Dumpster only dumps 7 additional apples.

  `/only` does not work with `/dout` on merchants.

## 2008-12-03 - 1.4

- Changed some message text to hopefully make it clearer.
- Automatically selects merchant gossip if `/din` is used at an NPC such as an Innkeeper.
- Will load on demand if ACP or AddonLoader is installed.

## 2008-11-28 - 1.3

- Fixed bug in `numstacks` which would dump 5 stacks from every bag instead of 5 total.
- Ace-ified.
- Moved strings to `Dumpster-enUS.lua` for localization.
- Rewrote option parsing.
- Added merchant frame support.
- Added trade frame support.
- Added bind status filtering.
- Added tooltip search.

## 2008-11-13 - 1.2

- Added ability to specify item quality.

## 2008-11-12 - 1.1

- Added ability to specify number of stacks to dump.
- Limited dumping into mail to 12 stacks.

## 2008-11-07 - 1.0

- Initial release.

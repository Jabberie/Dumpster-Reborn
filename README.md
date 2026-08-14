# Dumpster

If you ever move a lot of things around, this addon is for you!

Dumpster is a World of Warcraft inventory utility for quickly moving groups of items between your bags and other storage or transfer systems.

It supports banks, guild banks, mail, trade, and vendors, with flexible filtering so you can move items by name, quality, binding type, expansion, stack size, tooltip text, and other criteria.

## About Dumpster

Dumpster was originally created by **Badhairday-Malygos**.

After the original addon stopped being maintained, it was later resurrected and maintained as **Dumpster Reborn** by **Jabberie-Draka**.

The **Reborn** name reflects that history: this project is a continuation and modernization of the original Dumpster rather than a completely unrelated addon.

The current version retains the established Dumpster command syntax and behaviour while modernizing the codebase for current World of Warcraft clients.

## Features

- Move matching items into your bank.
- Withdraw matching items from your bank.
- Deposit and withdraw items from guild banks.
- Support for Retail account/Warband bank storage.
- Send matching items through mail.
- Move items through the trade window.
- Buy and sell matching items at vendors where supported.
- Match items by partial or full item name.
- Match items using tooltip text.
- Filter by item quality.
- Filter by binding type.
- Filter by expansion.
- Filter by stack size.
- Save commonly used filters as named sets.
- Combine saved sets and qualifiers for more complex searches.
- Support for Retail, Mists of Pandaria Classic, and Classic Era.
- Uses Ace3 for console, events, timers, and localization.

## Basic Usage

Dumpster primarily uses two commands:

```text
/din <filter>
/dout <filter>
```

`/din` moves matching items **into** the system you currently have open.

`/dout` moves matching items **out of** that system and into your bags.

For example, while your bank is open:

```text
/din cloth
```

Deposits matching cloth items from your bags into the bank.

```text
/dout cloth
```

Withdraws matching cloth items from the bank into your bags.

The same general principle applies to supported guild bank, mail, trade, vendor, and account bank interactions.

## Item Matching

You can search using all or part of an item's name.

For example:

```text
/din ore
```

Matches items whose names contain `ore`.

```text
/dout potion
```

Withdraws matching potions.

Dumpster's parser also supports qualifiers and saved sets for more specific matching.

## Saved Sets

Create or update a saved set:

    /dadd setname setdetails

Delete a saved set:

    /ddel setname

List saved sets:

    /dlist

You can also use `/dumpster` to open Dumpster's configuration interface

## Qualifiers and Filtering

Dumpster can further restrict which items are selected.

Depending on the client and item information available, filters can include criteria such as:

- Item quality
- Binding status
- Expansion
- Tooltip text
- Stack size
- Item name
- Saved sets

These can be combined to create specific inventory rules for crafting materials, consumables, equipment, or other collections of items you regularly move.

## Tooltip Searches

Dumpster supports matching text found in item tooltips.

On Retail, current versions use Blizzard's structured `C_TooltipInfo` API where possible.

Classic clients retain a compatibility fallback using a hidden tooltip scanner.

This preserves older Dumpster-style tooltip filters while avoiding unnecessary tooltip-frame scanning on modern Retail clients.

## Banks

When a character bank is open, Dumpster can move matching items between your bags and available bank storage.

Retail bank handling uses Blizzard's current bank and container APIs rather than relying on older hard-coded bag-number ranges.

## Account / Warband Bank

Retail versions of Dumpster support account-wide bank storage.

Available account-bank tabs are discovered dynamically rather than assuming a fixed container ID.

## Guild Banks

Dumpster supports moving matching items into and out of guild-bank tabs.

Guild-bank transfers are throttled through an internal queue to avoid sending operations too quickly.

Where available, Dumpster uses Blizzard-provided guild-bank slot constants rather than assuming a fixed number of slots.

## Mail

Dumpster can use the mail interface to move matching items into mail attachments or collect matching items where supported.

Mail attachment limits are determined from Blizzard-provided values when available.

## Trade

When the trade window is open, Dumpster can place matching items into available trade slots.

This can be useful when repeatedly transferring the same categories of items between characters.

## Vendors

Dumpster retains its historical vendor support for buying or selling matching items where the current client allows it.

Vendor behaviour varies between World of Warcraft client versions, so compatibility handling is intentionally conservative.

## Supported Clients

The current codebase is designed to share one implementation across supported World of Warcraft variants.

Current targets include:

- World of Warcraft Retail
- Mists of Pandaria Classic
- World of Warcraft Classic Era

Client-specific behaviour is kept in `Compatibility.lua` wherever practical.

## Project Structure

The modernized version of Dumpster has been split into focused modules:

```text
Core.lua
Compatibility.lua
GuildBank.lua
Dumpster.lua
Commands.lua
Parser.lua
Items.lua
Transfers.lua
UI.lua
```

### Core.lua

Initial addon setup, client detection, event registration, and shared addon state.

### Compatibility.lua

World of Warcraft client differences, container APIs, bank handling, and external bag-addon compatibility.

### Commands.lua

Slash commands and command dispatch.

### Parser.lua

Dumpster filter parsing, qualifiers, and saved-set expansion.

### Items.lua

Item information, tooltip matching, qualities, binding filters, expansion filters, and related item checks.

### Transfers.lua

Bag, bank, mail, trade, merchant, and general item-transfer logic.

### GuildBank.lua

Guild-bank transfers, tab handling, throttling, and transfer queues.

### UI.lua

Dumpster settings and saved-set interface.

### Dumpster.lua

Shared runtime state and interaction/event handling that does not belong to one of the more specialised modules.

## Dependencies

Dumpster uses **Ace3**.

Ace3 may be embedded with the addon package or provided separately, depending on how the addon is installed.

## Installation

Install Dumpster through your preferred addon manager, or manually copy the `Dumpster` folder into the appropriate World of Warcraft `Interface/AddOns` directory.

For Retail:

```text
World of Warcraft/_retail_/Interface/AddOns/Dumpster/
```

Restart World of Warcraft or reload the UI after installation.

## Updating From Older Versions

Dumpster is designed to preserve the existing `dumpset` saved-variable format.

Users upgrading from older Dumpster or Dumpster Reborn releases should retain their saved sets.

Keeping a backup of the relevant SavedVariables file before a major update is still recommended.

## Development Philosophy

The current development work aims to modernize Dumpster without unnecessarily changing how long-time users interact with it.

The priorities are:

- Preserve established command behaviour.
- Preserve existing saved sets.
- Replace obsolete World of Warcraft APIs.
- Support current client variants through one codebase.
- Isolate client-specific behaviour.
- Remove accidental globals and historical compatibility patches.
- Replace fragile tooltip and container handling with current Blizzard APIs.
- Keep complex transfer operations reliable rather than rewriting them solely for stylistic reasons.

## History

Dumpster has existed in various forms for many years.

The original addon was written by **Badhairday-Malygos** and provided the core inventory-dumping concept and command system that still defines the addon today.

After the original project became inactive, **Jabberie-Draka** revived the addon as **Dumpster Reborn** and continued maintaining it for newer World of Warcraft releases.

The modern Dumpster project continues that lineage while progressively refactoring the older codebase for current Retail and Classic clients.

## Author and Maintenance

**Original Author:** Badhairday-Malygos  
**Current Maintainer / Project Manager:** Jabberie-Draka

CurseForge:

https://www.curseforge.com/wow/addons/dumpster-reborn

## Feedback and Issues

When reporting a bug, please include where possible:

- World of Warcraft client variant
- Dumpster version
- Command used
- What interface was open at the time
- Expected behaviour
- Actual behaviour
- Any Lua error produced

Because Dumpster interacts with several Blizzard inventory systems, identifying whether an issue occurred at a normal bank, account bank, guild bank, mailbox, trade window, or vendor is especially useful.

## License

Dumpster is released under the **MIT License**.

See [LICENSE](LICENSE) for the full license text.

# Project Zomboid Modding Reference

Sources: pzwiki.net (full PDFs preserved in [wiki_dump/](wiki_dump/)), MrBounty/PZ-Mod---Doc, FWolfe/ProfessionFramework, game source under `ProjectZomboid/media/lua/`.

## Topics

| File | What it covers |
|------|---------------|
| [mod_structure.md](mod_structure.md) | **Build 42 folder layout, mod.info format, the mandatory `42/` and `common/` folders** |
| [b42_mod_loading.md](b42_mod_loading.md) | **Why a B42 mod might not appear in the Mods menu — diagnostic procedure with code references** |
| [debug_mode.md](debug_mode.md) | Enabling `-debug`, in-game Lua console, debug menus, spawning NPCs/items for testing |
| [startup_parameters.md](startup_parameters.md) | Launch flags: `-debug`, `-modfolders`, `-cachedir`, `-debuglog`, JVM args |
| [occupations.md](occupations.md) | **All vanilla professions** — costs, skills, traits (B42 authoritative) |
| [vanilla_traits.md](vanilla_traits.md) | **All vanilla traits** — costs, XP boosts, exclusions (B42 authoritative) |
| [traits.md](traits.md) | How to create custom traits (B42 .txt script format + Lua notes) |
| [items.md](items.md) | Item script variables for all item types |
| [events.md](events.md) | Event system overview — hooking into game events (small starter set) |
| [**events_catalog.md**](events_catalog.md) | **Complete ~130-event catalog** extracted from game source — parameters, when each fires, confidence level, Sanity_traits priority table |
| [timed_actions.md](timed_actions.md) | Timed action skeleton reference |
| [**timed_actions_examples.md**](timed_actions_examples.md) | **Annotated vanilla timed action examples** — lifecycle diagram, patterns cheat sheet, 110+ player methods, 8 common pitfalls |
| [ui.md](ui.md) | ISPanel-based UI windows (overview) |
| [**ui_elements.md**](ui_elements.md) | **Full UI element API** — all 16 IS* classes with constructors, methods, event hooks, usage patterns |
| [moddata.md](moddata.md) | Global ModData + JSON/text save data |
| [**player_api.md**](player_api.md) | **IsoPlayer/IsoGameCharacter method reference** — 110+ methods in 14 categories, inferred from game source |
| [**loot_distributions.md**](loot_distributions.md) | **Procedural loot system** — distribution structure, tags, bulk-insert pattern, OnFillContainer hook |
| [**lua_optimization.md**](lua_optimization.md) | **Lua performance rules** — caching, locals, load balancing, table.newarray, print() warning |
| [**lua_api_overview.md**](lua_api_overview.md) | **Java/Lua bridge fundamentals** — `:` vs `.`, constructors, field reflection, hooking, load order, B41→B42 API gotchas |
| [wiki_dump/](wiki_dump/) | Full PZwiki page captures (PDFs + extracted text) — raw source for docs above |

## Examples (working Lua / script files)

| File | What it shows |
|------|--------------|
| [examples/mod.info](examples/mod.info) | Minimal mod.info template |
| [examples/profession_definition.txt](examples/profession_definition.txt) | **B42 profession script** — character_profession_definition |
| [examples/trait_definition.txt](examples/trait_definition.txt) | **B42 trait script** — character_trait_definition (all 4 patterns) |
| [examples/item_definition.txt](examples/item_definition.txt) | Item script (.txt) example |
| [examples/timed_action.lua](examples/timed_action.lua) | Custom timed action skeleton |
| [examples/ui_panel.lua](examples/ui_panel.lua) | ISPanel window with button/tickbox/text entry |
| [examples/moddata_usage.lua](examples/moddata_usage.lua) | ModData create/get/transmit pattern |
| [examples/trait_basic.lua](examples/trait_basic.lua) | Trait via legacy Lua TraitFactory (pre-B42 style) |
| [examples/professionframework_trait.lua](examples/professionframework_trait.lua) | Trait via ProfessionFramework (3rd-party) |
| [examples/professionframework_profession.lua](examples/professionframework_profession.lua) | Profession via ProfessionFramework (3rd-party) |

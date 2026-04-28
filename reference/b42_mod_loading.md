# B42 Mod Loading & Detection

Why a mod might not appear in the in-game Mods list, with code references and a verified debug procedure.

## How PZ enumerates mods

The flow, traced through `ProjectZomboid/media/lua/client/OptionScreens/ModSelector/`:

1. `ModSelector.Model:reloadMods()` calls Java's `getModDirectoryTable()` to list every mod folder, then `getModInfo(directory)` to parse each one's `mod.info`. ([ModSelectorModel.lua:56-86](../ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua#L56))
2. For each parsed mod, it sets `modData.isAvailable = modData.modInfo:isAvailable()` ([line 116](../ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua#L116)).
3. `ModListPanel:applyUnsupportedMods()` filters the displayed list. **Default state: "Show unsupported mods" tickbox is OFF**, so any mod where `isAvailable()` is false is silently filtered out. ([ModListPanel.lua:148-174](../ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModListPanel.lua#L148))

This means a mod can be 100% present on disk, parsed successfully, and still be invisible in the menu — because PZ decided it's "unsupported" for the current build.

## What makes `isAvailable()` return false

`isAvailable()` is implemented in Java and not directly readable from Lua, but reverse-engineering from observable behavior + workshop mod patterns:

| Condition | `isAvailable()` |
|-----------|-----------------|
| Mod has B42 folder structure (`42/`, `42.X/`, or `common/` directory present) AND `pzversion` major matches | **true** |
| Mod has only B41 layout (mod.info + media/ at root, no version folder, no common/) | **false** in B42 |
| `pzversion=42.0` (with `.0`) | **false** — treated as below `getBreakModGameVersion()` |
| `pzversion=42` (just major) and `versionMin` ≤ current game version | **true** |
| Missing `pzversion` field entirely | **false** in B42 (except the special-cased `ModTemplate` and `examplemod`) |

## Console.txt signals

What you can and cannot infer from `%UserProfile%/Zomboid/console.txt`:

| Log line | Meaning |
|----------|---------|
| `LOG : Mod f:0> refusing to list examplemod` | PZ scanned the folder, found the special-cased `examplemod`, and explicitly refused to list it. **Equivalent silent rejection happens for B41-only third-party mods, but without a log line.** |
| (no Mod log lines for your mod) | Could mean: (a) mod was scanned and silently rejected, OR (b) Mods menu wasn't opened in this session and the deep scan didn't run, OR (c) mod was scanned and silently accepted (rare — most accepted mods don't log). |
| `LOG : General f:0> STATE: exit zombie.gameStates.TermsOfServiceState` | User dismissed the Terms of Service screen. If this is the last meaningful log line before `GameThread exited.`, the user quit before doing anything else. |

`console.txt` is **rotated on every launch** — so the symptom "I opened the Mods menu, didn't see my mod, quit" leaves no console trace once you relaunch.

## Diagnostic procedure when a mod doesn't appear

Run these in order; stop at the first failure:

### Step 1: confirm files are physically there

```bash
ls "C:/Users/joaqu/Zomboid/mods/<ModName>/"
# Expect: 42/  common/  (and optionally mod.info, poster.png at root)

ls "C:/Users/joaqu/Zomboid/mods/<ModName>/42/"
# Expect: mod.info  media/

cat "C:/Users/joaqu/Zomboid/mods/<ModName>/42/mod.info"
# Expect: name, id, description, pzversion=42 (or 42.X), modversion
```

### Step 2: check for duplicates

```bash
# Search for the mod ID across all three possible mod locations
grep -r "id=YourModID" \
  "C:/Users/joaqu/Zomboid/mods/" \
  "C:/Users/joaqu/Zomboid/Workshop/" \
  "D:/SteamLibrary/steamapps/workshop/content/108600/"
```

Expect exactly one hit. Multiple hits = id collision = silent overwrite.

### Step 3: verify `pzversion` is sensible

```bash
grep "^pzversion=" "<mod>/42/mod.info"
# Want: pzversion=42  or  pzversion=42.X
# Reject: pzversion=42.0  (the .0 specifically breaks isAvailable)
# Reject: missing pzversion entirely (works only for whitelisted official mods)
```

### Step 4: launch PZ, open Mods menu, toggle "Show unsupported mods"

If the mod **appears** when "Show unsupported mods" is checked but **not** when unchecked → `isAvailable()` is returning false. Re-check Step 3 and the folder structure.

If the mod doesn't appear even with "Show unsupported mods" on → PZ isn't scanning the folder at all. Possible causes:
- Folder name has invisible characters (BOM, unicode, trailing space)
- Folder is hidden (Windows `attrib +H`)
- `-modfolders` startup arg excludes the location

### Step 5: launch with `-debug` and check the Lua console

`-debug` enables the in-game Lua console (F11). From there:
```lua
-- list all detected mods
for i, dir in ipairs(getModDirectoryTable()) do
    local info = getModInfo(dir)
    if info then
        print(i, dir, info:getId(), info:getName(), info:isAvailable())
    else
        print(i, dir, "<no mod.info parsed>")
    end
end
```

This is the authoritative test. If your mod's id and name appear with `isAvailable()=true`, it should be in the menu. If `isAvailable()=false`, fix the structure/pzversion. If the mod doesn't appear at all in the iteration, PZ never saw the folder.

## What `getBreakModGameVersion()` likely returns

Referenced at [ModListPanel.lua:155](../ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModListPanel.lua#L155) — this is the game's "minimum mod-compatible game version" cutoff. When you toggle "Show unsupported mods," the warning dialog says (paraphrased): "These mods are below `<this version>`, may not work."

For a 42.17.0 install, this cutoff is somewhere in the 42.X range — high enough that `pzversion=42.0` falls below it. Hence why we use `pzversion=42` (which the parser treats as "any 42.x") instead.

## "But examplemod has the B41 layout and it's not hidden!"

Examplemod and ModTemplate are **explicitly whitelisted** in Java code as official Indie Stone templates. They behave differently from third-party mods — examplemod gets the `refusing to list examplemod` log line specifically because it's recognized as the dev template and intentionally hidden from the user-facing list. Third-party mods using the same B41 layout don't get a log line, they just don't appear.

Don't model your mod's structure on examplemod or ModTemplate.

## Cross-references

- [mod_structure.md](mod_structure.md) — canonical B42 folder layout
- [debug_mode.md](debug_mode.md) — enabling `-debug` and using the Lua console
- [wiki_dump/Mod structure - PZwiki.txt](wiki_dump/Mod%20structure%20-%20PZwiki.txt) — wiki source

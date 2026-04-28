# Startup Parameters

Source: [`wiki_dump/Startup parameters - PZwiki.txt`](wiki_dump/Startup%20parameters%20-%20PZwiki.txt) (PZwiki, 42.12.3).

JVM args go first, separated from game args by `--`. From the Steam launch options field, `-debug` alone is fine (no `--` needed because there are no JVM args).

## Game arguments — most useful for modding

| Argument | What it does | Example |
|----------|--------------|---------|
| `-debug` | Enables debug mode (bug icon, Lua console, debug menus). **The single most useful flag for mod testing.** | `-debug` |
| `-debuglog={types}` | Enable named log filters. Comma-sep list of `DebugType` values. | `-debuglog=All` or `-debuglog=Network,-Sound` |
| `-modfolders {locations}` | Controls which mod folders are scanned and load order. **3 valid values: `workshop`, `steam`, `mods`.** Omit any to disable scanning that location. | `-modfolders workshop,steam,mods` |
| `-cachedir={path}` | Override the user data folder (default `%UserProfile%/Zomboid/`). Lets you test with a clean profile without nuking your real saves. | `-cachedir="D:\\PZ-Testing"` |
| `-console_dot_txt_size_kb={int}` | Max size of `console.txt` before rotation. Default is small; bump for long sessions. | `-console_dot_txt_size_kb=512000` |
| `-nosteam` | Skip Steam integration. Mod uploader won't work but offline launches are faster. | `-nosteam` |
| `-safemode` | Reduced resolution, no shaders, 1x texture scale. Use if PZ won't launch at all. | `-safemode` |
| `-imgui` | Debug mode + Imgui inspector enabled. | `-imgui` |
| `-debugtranslation` | Reload translation files mid-game by holding F12. Writes issues to `cachedir/translationProblems.txt`. | `-debugtranslation` |

## `-modfolders` deep dive

The three folder names map to:

| Name | Path |
|------|------|
| `mods` | `%UserProfile%/Zomboid/mods/` (manual installs) |
| `workshop` | `%UserProfile%/Zomboid/Workshop/<MyMod>/Contents/mods/` (development) |
| `steam` | `Steam/steamapps/workshop/content/108600/<workshopID>/mods/` (Workshop subscriptions) |

**Order matters** — earlier locations win on duplicate IDs. The default is to scan all three (in some order I haven't pinned down).

If our mod isn't being scanned, this is one place to check: `-modfolders mods` would force PZ to only look in `Zomboid/mods/`, ruling out duplicate-id collisions with workshop subscriptions.

## JVM arguments — useful for modding

JVM args **must** come before `--`:

| Argument | What it does | Example |
|----------|--------------|---------|
| `-Xms{size}m` | Min heap. Game won't start if system can't spare it. Format: `4096m` or `4g`. | `-Xms4096m` |
| `-Xmx{size}m` | Max heap. Above physical RAM = swaps to disk = slow. | `-Xmx8192m` |
| `-Dzomboid.steam=1` | Same as `-nosteam`. | |
| `-Ddebug` | Same as `-debug`. | |

Combined example for a development launch with extra memory and debug mode:

```
-Xmx8192m -Xms4096m -- -debug -debuglog=All
```

## Common combinations

**Mod testing baseline:**
```
-debug
```

**Verbose mod debugging:**
```
-debug -debuglog=All -console_dot_txt_size_kb=512000
```

**Isolated test profile (doesn't touch your real saves):**
```
-debug -cachedir="D:\\PZ-Test"
```

**Force-load only Zomboid/mods/ (rule out workshop conflicts):**
```
-debug -modfolders mods
```

## Server-side args

Not relevant to our singleplayer mod, but listed in the wiki under `Server`. See [the wiki dump](wiki_dump/Startup%20parameters%20-%20PZwiki.txt) if needed.

## Cross-references

- [debug_mode.md](debug_mode.md) — what `-debug` actually unlocks in-game
- [b42_mod_loading.md](b42_mod_loading.md) — using `-modfolders` and `-debug` to diagnose mod detection
- [wiki_dump/Startup parameters - PZwiki.txt](wiki_dump/Startup%20parameters%20-%20PZwiki.txt) — full wiki page

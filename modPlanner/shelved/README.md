# Shelved Mods

Mod efforts that were started but paused before completion. The folder
exists to keep the workspace tidy — `workBench/` stays for *active*
development, `shelved/` is for projects waiting on a future revisit.

A mod ends up here when:
- A milestone surfaces blockers that need a dedicated investigation session
- Scope evolved and the original direction no longer fits
- Better priorities surfaced and momentum is needed elsewhere
- The mod was an experiment that taught what we needed and doesn't need to ship

Each subfolder has a `SHELVED.md` documenting:
- Why it was shelved (the specific blocker or pivot reason)
- What works (parts that proved out, lessons captured)
- What doesn't (specific failures with file:line references)
- Resume conditions (what would have to be true to bring it back)
- Where related artifacts live (planning workspace, runtime backups, commits)

The full git history of each shelved project remains intact — `git log
modPlanner/shelved/<name>/` walks back through every phase commit.

---

## Currently shelved

- **[ProjectZLife/](ProjectZLife/SHELVED.md)** — Pre-apocalyptic life-sim RPG mod, intended as a clean-room replacement of BanditsWeekOne. 11 phases shipped (M1 + most of M2), 14 remaining. Halted on first in-game smoke test after 5 B42.17 substrate-API mismatches surfaced. The architecture and decisions log are sound; the rebuild needs a dedicated session of B42-internals probing first.

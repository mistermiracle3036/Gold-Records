# Changelog

All notable changes to Kanto Rocks are documented here, newest first,
following [Semantic Versioning](https://semver.org/).

<!-- Version headings MUST be bare: "## 0.1.1", no brackets and no date.
     .github/workflows/release.yml builds the GitHub release body with
     `awk -v v="## $VERSION" '$0 == v {...}'`, an EXACT line match. A
     Keep-a-Changelog style "## [0.1.1] - 2026-08-10" heading still passes
     the workflow's version-agreement check (that one strips brackets and
     takes the first word), so the release publishes happily with a
     COMPLETELY EMPTY body. Nothing fails; the notes are just gone. -->


## 0.2.0

**Kanto Rocks moves to Gold.** ROXIE is in JOHTO now, and this version
targets Gen 2 only.

### Changed
- **ROXIE has moved to VIOLET CITY**, and she is not impressed. She came
  looking for a music scene and found temple bells, monks and somebody's
  sleeping WOOPER. So she is starting a band out of spite.
- **The gate is now one badge, not four.** Violet City is Gold's second
  town and the Zephyr Badge is earned in it; a four-badge gate would have
  left ROXIE waiting in a town the player had long since walked out of.
  One badge puts her there the moment the gym goes quiet, which is the
  joke.
- **This version runs on Gold only** (`games: ["gen2"]`). The Red
  implementation is not carried forward. Nothing was published for Gen 1,
  so no existing player loses anything; if it should come back it is
  recoverable from git history rather than being rewritten.
- Minimum engine is now **0.1.78**, the release Gen 2 shipped in. This
  mod genuinely cannot run below it -- the entire Gen 2 mod surface
  arrives in that version -- which is the only reason the floor moved.

### Notes -- why this was a rewrite and not a location swap
Gen 2 is a *parallel* engine rather than an extension: a Gold boot never
loads the Gen 1 overworld, game or battle modules at all, so Gen 1
patterns do not degrade, they simply do nothing. Four pieces had to be
replaced outright.

- **Dialogue.** The `map_scripts` registry has no Gen 2 home -- Gold's
  script pool is the cart's own bytecode keyed by ROM pointer, and a Lua
  row list is not something its VM can run. ROXIE's lines are now driven
  from the `world.interacted` event: an A press that matches nothing
  reports the faced cell, the mod recognises hers, and the text is queued
  through the Gen 2 script API.
- **Badges.** Gold keeps them in `save.player.badges` and
  `save.player.kantoBadges`, and the Gen 1 badge module is not served by
  the compatibility adapter at all -- it would have read zero forever,
  leaving the gate permanently shut with no error anywhere.
- **NPC movement** is a number on Gen 2, not the Gen 1 `"STAY"` string.
- **On-screen reporting** now goes to the mod manager's `[ERRS]` screen.
  The Gen 1 text-box module is not served either, and on a Gold boot the
  engine's own adapter warnings are log-only -- invisible on a phone.

### Added
- `LICENSE` (MIT) and `THIRD_PARTY_NOTICES.md`, so redistribution rights
  and the trademark position are stated rather than assumed.

### Still to prove
- Nothing in this ecosystem has yet given a mod-spawned NPC a voice on
  Gold. The `world.interacted` fall-through is verified in engine source
  but **not on a real Gold boot** -- that is what this build is for.

## 0.1.2

Quest System is no longer required.

### Changed
- **Kanto Rocks no longer needs Quest System installed to run.** It was
  declared a hard dependency from the very first version, which means the
  mod refused to load without it -- and Quest System is distributed as a
  loose zip committed to someone else's repository, with no GitHub
  releases behind it, so the launcher cannot fetch or update it and you
  have to go and find the right file by hand. Kanto Rocks was making you
  do that for a mod it did not yet use a single line of.
- It is now an *optional* dependency, which is the honest description:
  install it and the questline will also keep a journal entry; skip it
  and everything else works exactly the same. The engine still guarantees
  Quest System loads first when it is present, so nothing about the
  integration gets harder.

### Notes
- No gameplay change. ROXIE, her placement and her dialogue are byte-for
  byte what 0.1.1 shipped.
- This also unblocks `modkit validate --strict`, which could never pass
  while the hard dependency stood: the validator mounts exactly one mod
  and cannot see a sibling on disk, so it reported a missing dependency
  every run regardless of what was installed.

## 0.1.1

ROXIE turns up.

### Added
- **ROXIE, in Vermilion City**, once you have four badges. She is a real
  new NPC of this mod's own -- not a vanilla character with her dialogue
  hijacked -- so she carries her own `TEXT_KR_ROXIE` line, cannot be
  broken by Yellow's per-map object renames, and cannot collide with any
  other mod's takeovers in that city. Under four badges she simply is not
  there yet.
- She has one thing to say for now. The quest itself registers in 0.1.3.
- Her sprite: the mod uses a stand-in until `assets/roxie.png` exists,
  then switches to it automatically with no code change. The art is
  16x96 -- six 16x16 frames, stand down/up/left then walk down/up/left --
  in the four GB greys 255/170/85/0, where 255 is transparent. It borrows
  SPRITE_DAISY's OBJ palette group (BLUE), so in the RED++ colour modes
  the 85 grey reads as blue hair and the 170 grey as skin.
- A placement report on the Vermilion banner, naming the cell she landed
  on and which sailor she anchored to -- or why she did not appear.

### Notes
- Her position is resolved at runtime rather than hard-coded: the mod
  finds a vanilla NPC to anchor on, then takes the first neighbouring
  cell the map itself reports as in-bounds, walkable and unoccupied.
  Vermilion's real coordinates only exist on the device, so hard-coding
  them from the repo would have been a guess.
- Nothing is written to the save. Runtime objects are not serialized.

### Fixed
- Nothing yet shipped to fix. The `map.entered` payload names the map id
  as `mapId`, not `map` (`map` is the map object) -- caught before the
  build, since the wrong one is a table-vs-string test that never matches
  and would have silently spawned nobody, anywhere, forever.

## 0.1.0

Scaffold slice. Registers no content on purpose.

### Added
- The mod itself: manifest, entry point, card, docs.
- A load banner naming the running version, drawn on the first map entry
  of the session (not on `game.ready` -- a text box pushed there is
  discarded before anything can draw it).
- A Quest System handshake probe. The banner's second page reports which
  of `register` / `start` / `advance` / `complete` / `track` / `markers`
  are really functions on that mod's exports table, so the questline in
  0.2.x can be written against a confirmed API instead of a remembered
  one.
- `mod.exports.owns`, declared up front and empty, reserving the mon
  fields `krHeadliner` and `krPiersGift` for the v0.5.x rewards.
- One option: **Show load banner** (default on).

### Notes
- Nothing vanilla is touched. No maps, NPCs, scripts, items or trainers
  are registered, patched or overridden by this version.

## Build order from here

Each line is one shipped version, one testable change.

- **0.1.3** -- the quest registers and starts in the journal, and ROXIE's
  dialogue branches on whether you have taken the job.
- **0.2.x** -- the recruitment beats, one per build: the drummer's
  battle, the bassist's missing instrument, the backup singer.
- **0.3.x** -- promotion: the FLYER item and the NPCs who take one.
- **0.4.x** -- the venue: custom tileset, custom map, the warp in, and
  the concert scene.
- **0.5.x** -- PIERS: trainer class, team, entrance, battle, rewards,
  and the quest completing.
- **0.6.x** -- cross-mod rewards, the Yellow constant pass, and tuning
  from playtests.

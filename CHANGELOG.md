# Changelog

All notable changes to Gold Records are documented here, newest first,
following [Semantic Versioning](https://semver.org/).

<!-- Version headings MUST be bare: "## 0.1.1", no brackets and no date.
     .github/workflows/release.yml builds the GitHub release body with
     `awk -v v="## $VERSION" '$0 == v {...}'`, an EXACT line match. A
     Keep-a-Changelog style "## [0.1.1] - 2026-08-10" heading still passes
     the workflow's version-agreement check (that one strips brackets and
     takes the first word), so the release publishes happily with a
     COMPLETELY EMPTY body. Nothing fails; the notes are just gone. -->


## 0.6.3

**Updating from 0.4.2?** Since the last release the band has gained a
four-stop venue hunt (0.5.0–0.6.0), interactive encounters at every venue
stop (0.6.1), commissioned character sprites, optional Trainer Journey
integration, and ROXIE now has her own overworld and battle portrait.

### Added
- ROXIE now has a commissioned overworld sprite and battle portrait by
  tharkka, replacing the vanilla COOLTRAINER_F stand-in. Her battle
  against the player shows the custom portrait instead of JANINE's.
- Optional **Trainer Journey** integration. When Trainer Journey is
  installed, eight quest beats award APPEAL, MOXIE and HEART stats and
  advance a new **ROCK STAR** profession (ROADIE → OPENER → HEADLINER →
  LEGEND). High stats add extra flavour dialogue at four moments: ROXIE's
  first meeting, the BASEMENT KING, the DANCE THEATER repeat visit, and
  PIERS' arrival. The DANCE THEATER showcase mildly leans Tradition; the
  NATIONAL PARK show mildly leans Innovation.
- `trainer_journey` added to `optional_dependencies`.

## 0.6.1

Every stop in the venue hunt now gives the manager something to do.

### Added
- After the DANCE THEATER refusal, choose a party Pokemon to demonstrate some
  grace. BELLOSSOM, the Eevee family, the POLIWHIRL family and HITMONTOP earn
  special praise and a small friendship boost.
- A SAILOR outside OLIVINE CAFE invites the whole band to busk. The first set
  each in-game day earns $300 and a party-wide friendship boost; later sets
  wait until tomorrow.
- The self-appointed BASEMENT KING offers an optional, safely losable battle
  in GOLDENROD UNDERGROUND. Beat his GRIMER Lv25, KOFFING Lv26 and MUK Lv28
  to earn the room's respect—even though WHITNEY still refuses the booking.
- The sleeping WOOPER from ROXIE's opening complaint finally appears on the
  road in ECRUTEAK. Waking it starts a one-shot wild encounter at level 18.
- PIERS now has a commissioned overworld sprite and battle portrait by
  Yogurcomics, replacing the vanilla ROCKER and KAREN stand-ins.
- Placement reports for the SAILOR, BASEMENT KING and sleeping WOOPER during
  private device testing.

### Fixed
- CASEY's NATIONAL PARK placement corrected from a wall tile to a walkable
  cell (regression from the 0.6.0 delivery).

### Notes
- Busking remains available after Act II and is limited by Gold's in-game
  clock rather than real-time elapsed minutes.
- The RADIO TOWER remains a dialogue-only refusal in this version.
- Existing saves at beat 90 or later skip every new Act II encounter except
  the persistent OLIVINE busking spot.

## 0.6.0

The band is ready. JOHTO's venues are not.

### Added
- A four-stop venue hunt between recruiting CASEY and the NATIONAL PARK
  show. The ECRUTEAK DANCE THEATER, GOLDENROD RADIO TOWER, OLIVINE CAFE and
  GOLDENROD UNDERGROUND each turn the band down in their own way.
- The RADIO TOWER offers a future radio spot, planting a lead for the next
  part of the quest even while refusing to host the show.
- Optional dialogue when Big Night in Olivine, Kanto Contests or Court of
  Noctowl is installed. These are presence-only crossovers: none is required,
  and disabling one cannot strand the quest.
- Runtime venue actors with walkable-cell fallback and `[ERRS]` placement
  reporting for private device testing.

### Changed
- Beat 90 still means the NATIONAL PARK show is assigned, but ROXIE now earns
  that answer after every venue refuses: nobody owns the park, so nobody can
  say no.
- Existing saves at beat 90 or later skip the venue hunt and keep their exact
  show and PIERS progression.

## 0.5.0

The band plays its first show, and PIERS has invited himself onto the bill.

### Added
- After CASEY joins, ROXIE books the assembled band into NATIONAL PARK and
  sends the player there as manager.
- The show opens once the player has four badges. Arriving early leaves the
  park unchanged and reports the closed gate in `[ERRS]`.
- ROXIE, WHITNEY and CASEY appear together for the opening performance.
  PIERS arrives only after the first song and is delighted that JOHTO finally
  has a show worth crashing.
- A safely losable and repeatable battle against PIERS: MURKROW Lv33,
  SNEASEL Lv33, WEEZING Lv34, CROBAT Lv34 and HOUNDOOM Lv35.
- New dialogue for the band before the show, during PIERS's interruption,
  after a loss and after PIERS is beaten.

### Notes
- The quest currently ends after PIERS acknowledges the band. Rewards and
  gift Pokemon are not part of this version.
- NATIONAL PARK placement is reported in `[ERRS]` while the new stage layout
  is tested on device.

## 0.4.2

**Formerly "Kanto Rocks".** The name was a leftover: this is a JOHTO story
and a Pokemon Gold mod, and it never loaded on a Kanto game at all. Renamed
before the first public release so nobody has to relearn it later.

**First public release — this is an ALPHA.** The band is half-assembled.

### Pokemon Gold only
This mod does **not** load on Red, Blue or Yellow. It is built against
Gold's engine, which is a separate implementation rather than an add-on,
so there is no Gen 1 version of it to fall back to. On a Red boot it is
simply skipped — that is expected, not a fault. Needs gen1recomp
**0.1.78 or newer**, the release Gold support arrived in.

### What you can play
ROXIE came to JOHTO looking for a music scene and found temple bells,
monks and somebody's sleeping WOOPER. So she is starting a band out of
spite, and you are going to manage it.

- **VIOLET CITY, once you have a badge.** ROXIE is waiting near the Gym
  with opinions about how quiet the place is, and a battle to see whether
  you are worth her time. Losing is safe — she will take you again.
- **GOLDENROD's UNDERGROUND.** Your first job as manager is finding a
  bassist who plays under the name FEEDBACK and will not audition for
  anyone carrying fewer than three badges. Beat her and you find out why
  she has been hiding behind a borrowed kimono.
- **ECRUTEAK's DANCE THEATER.** Three drummers, three very different
  ideas of a beat, and a JIGGLYPUFF with the worst possible timing. Work
  out who kept playing through it. Guessing wrong costs you nothing.

### What is not in yet
The questline stops after the drummer joins. Promoting the show, the
venue itself, and PIERS turning up to crash the encore are all still to
come. Nothing is broken when it ends — you simply reach the end of what
exists, and ROXIE has nothing new to say.

### Notes
- Your save is not modified. Every character this mod adds is a runtime
  actor, rebuilt from the mod's own quest progress each time you enter
  the map, so uninstalling leaves no trace in the world.
- No vanilla character, map, script or trainer is changed, so other mods
  touching Violet City, Goldenrod or Ecruteak will not collide with this
  one.
- **Quest System is optional.** Install it and the questline also keeps a
  journal entry; without it everything else is identical.
- Development aid: the mod writes actor placement into the mod manager's
  `[ERRS]` screen. That is deliberate and harmless. It goes away once the
  questline is finished.

## 0.4.1

Reconciliation build. No gameplay change from 0.4.0.

### Changed
- Brings the 0.2.1-0.4.0 work into the repository. Those five versions were
  written outside git and delivered as a zip, so this is the first commit
  that carries them; 0.4.0 itself has already left the repo as a private
  test build, which is why this lands as 0.4.1 rather than reusing it.
- Adds `docs/` to the release workflow's exclusion list, so screenshots
  added later cannot end up inside the player's download.

### Notes
- Recorded here because a manifest field is a poor place to leave a
  decision: this mod is now **Gold-only**. `games: ["gen2"]` with a
  `>=0.1.78` floor means it does not load on Red, Blue or Yellow at all.
  That is deliberate, and it means Gen 1 players never get this mod unless
  a backfill is chosen as new work later.

## 0.4.0

Private drummer-audition test build.

### Added
- After recruiting WHITNEY, ROXIE sends the player to an open drum audition
  in ECRUTEAK's DANCE THEATER.
- Runtime actors for ROXIE and three candidates: loud three-beat ROCKER GENE,
  five-four theorist BILLY, and Johto anime character CASEY.
- The player must speak to all three candidates before the audition begins.
- JIGGLYPUFF interrupts the audition with its recurring anime singing gag,
  sending the room to sleep and leaving a four-beat mystery behind.
- A dialogue-driven investigation which works without a choice-box API: gather
  all three rhythm clues, then select a candidate by speaking to them.
- Wrong selections are harmless and repeatable. CASEY's four-beat ELECTABUZZ
  chant identifies her as the drummer and recruits her into the band.
- Post-recruitment dialogue for CASEY and ROXIE, plus persistent audition,
  investigation, selection and completion states.

### Validation
- Every player-facing dialogue page has at most two lines, with no line longer
  than 18 visible characters.
- The full private sequence harness passes both existing battles, loss/retry,
  WHITNEY's reveal, the complete audition, a wrong choice and CASEY's reveal.

## 0.3.2

Private Feedback disguise test build.

### Changed
- FEEDBACK now uses the KIMONO GIRL overworld sprite instead of the green-
  haired male ROCKER sprite.
- WHITNEY explains after the reveal that the kimono and cheap wig let her Gym
  regulars walk straight past her without recognizing her.
- The costume disappears with the existing post-recruitment sprite change,
  leaving WHITNEY in her real overworld appearance.

## 0.3.1

Private Feedback placement-fix test build.

### Changed
- Moved FEEDBACK from `(9,18)` to `(6,33)`, beside the south GOLDENROD
  UNDERGROUND entrance used during normal progression.
- FEEDBACK faces left toward the entrance corridor.
- The three-badge requirement still gates only the audition battle; FEEDBACK
  appears as soon as ROXIE's manager conversation is completed.

## 0.3.0

Private bassist-recruitment test build.

### Added
- ROXIE now names the bassist FEEDBACK and directs the player to GOLDENROD's
  UNDERGROUND.
- FEEDBACK appears as a disguised ROCKER at `(9,18)` once the player has
  become ROXIE's manager.
- FEEDBACK refuses to audition until the player has three badges.
- A safely losable custom battle against CLEFAIRY Lv20, SNUBBULL Lv20 and
  MILTANK Lv22. The native battle introduction reveals FEEDBACK as LEADER
  WHITNEY before her post-battle confession.
- Victory dialogue recruits WHITNEY for one show and one encore. Her disguised
  NPC is replaced by WHITNEY's real overworld sprite after the reveal.
- ROXIE reacts to learning the bassist's identity and limits WHITNEY to one
  band-name suggestion.
- Persistent loss/retry, post-victory and recruited quest states.

## 0.2.3

Private placement-adjustment test build.

### Changed
- Moved ROXIE four cells right and seven cells up from the previous test
  position: `(18,19)` to `(22,12)`.
- ROXIE now initially faces right.

## 0.2.2

Private placement-fix test build.

### Changed
- ROXIE now has a fixed, visible position at `(18,19)`, directly south of
  Violet Gym's exterior door at `(18,17)`. The intervening square remains
  clear so she does not block the Gym entrance.
- ROXIE initially faces north toward the Gym.

## 0.2.1

Private quest-opening test build.

### Added
- ROXIE challenges the player after complaining that VIOLET CITY is too
  quiet and promising to shake it up.
- A native, safely losable trainer battle against EKANS and KOFFING.
- Win, loss and retry state. Only victory advances the quest; a loss keeps
  ROXIE available and restores HP/status for another attempt.
- After ROXIE loses, she appoints the player as her manager and sends them to
  GOLDENROD to find a bassist who only battles trainers with three badges.
- Persistent quest progress in `mod.save`.

### Testing
- Private ZIP test build only. No GitHub release or publishing plan.

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

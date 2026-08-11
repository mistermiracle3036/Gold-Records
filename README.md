# Kanto Rocks

ROXIE came to JOHTO looking for a music scene and found temple bells, monks
and somebody's sleeping WOOPER. So she is starting a band out of spite, and
you are her manager. Recruit the members, promote the gig, then find out
what happens when PIERS turns up to crash the encore.

A quest mod for [gen1recomp](https://github.com/bryanthaboi/gen1recomp),
mod API 2, **Pokemon Gold**.

**Status: v0.2.0, early.** ROXIE turns up in VIOLET CITY once you have a
badge, and has her say. The band, the gig and PIERS come after.

## Requirements

- gen1recomp **0.1.78 or newer** — the release Gen 2 support shipped in
- A Pokemon **Gold** boot. This version is Gen 2 only and is skipped on a
  Red/Blue/Yellow boot.

**Quest System is optional.** Install it and the questline also keeps an
entry in the journal; without it everything else behaves identically. It
is deliberately not a hard requirement: Quest System ships as a loose zip
committed to another repository with no GitHub releases behind it, so the
launcher cannot install or update it for you, and making you hunt that
file down by hand is not a fair price for a journal line.

## Design decisions worth knowing

### Why Gold-only, and why that was a rewrite

Gen 2 in this engine is a **parallel implementation**, not an extension. A
Gold boot never loads the Gen 1 game, overworld or battle modules at all,
so a Gen 1 pattern aimed at them does not degrade gracefully — it lands on
something nothing instantiates and does nothing, quietly. Moving towns was
the small part of this port. Four mechanisms had to be replaced:

| What | Gen 1 | Gold |
|---|---|---|
| Dialogue | `map_scripts` talk block | `world.interacted` + `queueScript` |
| Badges | `Badges.count(data, save)` | `save.player.badges` + `.kantoBadges` |
| NPC movement | `"STAY"` string | numeric (`STANDING_DOWN = 6`) |
| On-screen output | `TextBox` | `Runtime.reportError` → `[ERRS]` |

The dialogue one is the interesting one, because **Gold has no supported
way for a mod to author NPC speech**. Talking dispatches on an NPC's
`scriptKey` into the cart's decoded bytecode pool, and the `map_scripts`
registry has no Gen 2 home — a Lua row list merged into `gen2Scripts` is
not something Gold's script VM can run, so the registry is gated on a Gold
boot rather than silently merged.

The route through: `World:interactBody` tries trainer, boulder, itemball,
scriptKey, sign, hidden item, std-tile and field-move in turn, and when
nothing matches it emits `world.interacted` with `kind = "none"` and the
faced cell's coordinates. A mod-spawned NPC has no `scriptKey`, so an A
press aimed at ROXIE falls all the way through to there. The mod
recognises her cell and queues the text itself.

That is unproven on a real Gold boot — nothing in this ecosystem has given
a mod-spawned NPC a voice on Gold yet. It is the whole point of v0.2.0.

### Roxie is her own NPC, not a takeover

She has her own object rather than borrowing a townsperson's dialogue.
On Gold that is not really a choice — there is no vanilla line to take
over in a way the engine would run — but it was the right call on Gen 1
too: it means no per-version text-constant hunt, and no other mod editing
Violet City can silently clobber her, or be clobbered by her.

Her cell is resolved at runtime rather than hard-coded. Gold's manifest
carries map dimensions but no per-map object lists, so there is nothing to
copy even if hard-coding were wise; instead the mod anchors on a vanilla
NPC already on the map and takes the first neighbouring cell the map
itself reports as in-bounds, walkable and unoccupied.

### The HEADLINER ribbon is a field, not a call

kanto_ribbons has no award API. Its exports are `{ version, hasRibbon,
catalog }`, and every ribbon it grants comes from a resolver inside that
mod reading save state — the same way it reads snag_quest's `mon.snagged`.

So Kanto Rocks writes and owns `mon.krHeadliner`, and kanto_ribbons picks
it up in its own time. `mon.krPiersGift` is reserved the same way, tagging
the gift Pokemon's provenance.

## Options

| Option | Default | What it does |
|---|---|---|
| Report ROXIE status | on | Writes where ROXIE was placed — or why she was not — into the mod manager's `[ERRS]` screen. A development aid; it goes once the questline is stable. |

## Compatibility

Entirely additive: one NPC object of its own, and later its own items,
trainers and maps. No vanilla record is overridden and no vanilla dialogue
is displaced. ROXIE is a runtime object, which is never serialized, so she
never enters the map-data merge and nothing is written to your save on her
account.

Ownership is published at runtime in `mod.exports.owns`, including the two
mon fields reserved for rewards — `mon.krHeadliner` and `mon.krPiersGift`.
Read them freely; do not write them.

## Open questions (TODO/CONFIRM ledger)

Closed by reading engine source at v0.1.78:

- ~~Does the Gen 1 NPC pattern work on Gold~~ — no. `map_scripts` is
  gated on a Gold boot; see above.
- ~~Where Gold keeps badges~~ — `save.player.badges` (Johto) plus
  `save.player.kantoBadges` (Kanto), counted as set flags. Not reachable
  through `getFlag`; that is a different bitfield.
- ~~Which script verbs a mod can drive on Gold~~ — `text`, `warp`,
  `setflag`, `clearflag`, and `start_battle` **wild only**. The trainer
  arm is not served, which matters for the drummer's battle later.
- ~~Quest System export signatures~~ — device-confirmed:
  `register()`, `start()`, `advance()`, `complete()` and `track()` are all
  real functions on its exports table.

Still open:

- **The `world.interacted` fall-through, on a real Gold boot.** v0.2.0
  tests exactly this.
- **Where exactly ROXIE lands** in Violet City. Resolved at runtime and
  reported to `[ERRS]`.
- **Her sprite.** She wears `SPRITE_COOLTRAINER_F` as a stand-in. Gold's
  overworld sprite space is its own 162 ids, and Gen 1's `paletteSource`
  ROM crosswalk does not carry over, so bespoke art needs Gold's palette
  handling read properly first.
- **kanto_contests scarf reward.** Still a planned slice in that mod
  (`mon.kcScarf`); no scarf item exists in kanto_contests 0.9.0, so there
  is nothing to award yet.

## Credits

By **Mister Miracle**
([@mistermiracle3036](https://github.com/mistermiracle3036)).

- Built on the [gen1recomp](https://github.com/bryanthaboi/gen1recomp)
  engine and pret/pokecrystal + pokered research.
- **Quest System** by FAFF0x — optional journal integration.
- **Kanto Ribbons** — planned optional integration via a mon field.
- ROXIE (Pokemon Black 2 / White 2) and PIERS (Pokemon Sword) appear as
  fan tribute; no assets or text from those games are included.
- Pokemon and all related names are trademarks of Nintendo / Creatures
  Inc. / GAME FREAK inc. This mod contains no ROM data and requires your
  own game copy via gen1recomp.

Longer-form attribution lives in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

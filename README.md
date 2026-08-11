# Kanto Rocks

ROXIE is in Kanto trying to get a band together and play one big show,
and you are her manager. Recruit the members, promote the gig, then find
out what happens when PIERS turns up to crash the encore.

A quest mod for [gen1recomp](https://github.com/bryanthaboi/gen1recomp),
mod API 2, engine 0.1.75+.

**Status: v0.1.2, early.** ROXIE turns up in Vermilion City once you have
four badges, and has one thing to say. The quest itself registers in
0.1.3.

## Requirements

- gen1recomp 0.1.75 or newer

**Quest System is optional.** Install it and the questline also keeps an
entry in the journal; without it everything else behaves identically.
It is deliberately not a hard requirement: Quest System ships as a loose
zip committed to another repository with no GitHub releases behind it, so
the launcher cannot install or update it for you, and making you hunt
that file down by hand is not a fair price for a journal line.

## Design decisions worth knowing

### Roxie is not an NPC takeover

The original plan was the proven pattern from this ecosystem: take over
an existing Vermilion NPC's `TEXT_` constant and fall through to vanilla
dialogue with a `base_talk` command while the quest is gated off. Reading
the engine turned up something better, so the plan changed:

- `engine/src/world/WorldAPI.lua` exposes `mod.world:spawnNpc(mapId,
  objDef)` and `removeNpc(npcId)`. `objDef` takes the same shape as a
  `maps[].objects` entry. Runtime objects are not serialized, so the
  engine's own comment says a *permanent* NPC belongs in a maps patch and
  this is for scripted and dynamic actors a mod re-spawns on
  `map.entered`. A quest NPC who is supposed to show up only once you
  have four badges is exactly that.
- For the permanent case, `engine/src/mods/Merge.lua` documents the list
  extension wrappers: `mod.content.maps:patch("VERMILION_CITY",
  { objects = { __append = { def } } })` adds an object without
  replacing the vanilla list. A bare list would replace it wholesale --
  that is the trap this avoids.

So ROXIE gets her own object, her own sprite and her own `TEXT_KR_ROXIE`
constant that this mod owns. Consequences, all good:

- No `npc_inspector` harvest is needed for her, and no Yellow rename can
  silently break her, because the constant is ours on both versions.
- No collision with Pokemon Snag, which already owns
  `TEXT_VERMILIONCITY_SAILOR1` in this exact city as one of its fences.
- The closed-gate case stops needing a `base_talk` fallback at all:
  under four badges ROXIE simply is not there yet.

`spawnNpc` is engine-source-verified but not yet device-verified -- no
shipped mod in this ecosystem uses it -- so v0.1.1 tests exactly that one
thing. If it disappoints, the `maps:patch` + `__append` route is the
fallback and the dialogue code does not change.

### The HEADLINER ribbon is a field, not a call

kanto_ribbons has no award API. Its exports are `{ version, hasRibbon,
catalog }`, and every ribbon it grants comes from a resolver inside that
mod reading save state -- the same way it reads snag_quest's
`mon.snagged` and kanto_contests' `mon.contestWins`.

So Kanto Rocks writes and owns `mon.krHeadliner`, and kanto_ribbons picks
it up in its own time with a catalog entry, a resolver and an icon-sheet
cell. That change belongs in that repo, not this one. `mon.krPiersGift`
is reserved the same way, tagging the gift Pokemon's provenance for
whatever wants it later.

Mon tables take arbitrary fields and the save serializer is a generic
recursive dump, so both persist through save/load, boxing, evolution and
trading.

## Options

| Option | Default | What it does |
|---|---|---|
| Show load banner | on | Announces the running version once per session, and reports where ROXIE was placed in Vermilion. A development aid; it will go once the questline is stable. |

## Compatibility

The mod's footprint is entirely additive: its own NPC object, its own
`TEXT_KR_*` constants, its own sprite, and later its own items, trainers,
maps and tilesets. No vanilla record is overridden and no vanilla
dialogue is displaced, so two mods touching Vermilion City cannot
silently clobber each other here.

ROXIE is a runtime object, which is never serialized, so she never enters
the map-data merge and nothing is written to your save on her account.

Ownership is published at runtime in `mod.exports.owns`, including the
two mon fields this mod reserves for its rewards -- `mon.krHeadliner` and
`mon.krPiersGift`. Read them freely; do not write them.

## Open questions (TODO/CONFIRM ledger)

Closed by reading source in this working tree:

- ~~Trainer class prize-money field~~ -- `baseMoney`, an optional
  non-negative integer on the `trainers` registry (`Schemas.lua` R.trainers).
  Also available there: `battleTheme`, a music id that overrides the
  battle song per trainer.
- ~~Gen 1 stat-exp field names~~ -- `mon.statExp = { hp, attack, defense,
  speed, special }` (`src/pokemon/Pokemon.lua`, consumed by
  `Stats.calc`).
- ~~Can a new NPC entity go on a vanilla map~~ -- yes, two ways. See
  "Roxie is not a takeover" above.
- ~~kanto_ribbons ribbon-award contract~~ -- there is no award call;
  write a mon field. See above.
- ~~The badge gate~~ -- `Badges.count(data, save)` from
  `src/inventory/Badges.lua`, called with the game's data and save.

- ~~Quest System export signatures~~ -- device-confirmed in v0.1.0:
  `register()`, `start()`, `advance()`, `complete()` and `track()` are
  all real functions on its exports table. `markers` is additionally a
  field of the `register()` table, which is the form Pokemon-Snag ships
  and the form this mod will use.
- ~~Whether a runtime-spawned NPC's dialogue dispatches~~ -- yes. The
  interact path passes the object def's `text` straight to
  `showMapText`, which resolves it with
  `mapScripts.talkScript(mapId, textConst)` and does not care where the
  object came from.
- ~~Overworld sprite colour~~ -- there is no true-colour path.
  `SpriteRenderer` buckets every pixel into the four GB greys
  (255/170/85/0, 255 keyed to transparent) and never reads `trueColor`.
  Colour comes from one of four GBC OBJ palette groups -- ORANGE, BLUE,
  GREEN, BROWN -- selected with `paletteSource`, and only in the RED++
  colour modes.

Still open:

- **`spawnNpc` on a vanilla map, on device.** v0.1.1 tests it.
- **Where exactly ROXIE lands.** Her cell is resolved at runtime from a
  vanilla anchor NPC, because Vermilion's coordinates only exist on the
  device. v0.1.1 reports the cell it chose.
- **kanto_contests scarf reward.** The scarves are a *planned* slice in
  that mod's NOTES.md ("five worn items setting `mon.kcScarf`, +20 intro
  points"); no scarf item exists in kanto_contests 0.9.0 yet. Nothing to
  award until it ships, so this reward waits.
- **Every `TEXT_` constant for the promotion phase NPCs** (v0.3.x), per
  game version, until harvested with `npc_inspector`. Those really are
  takeovers -- handing a flyer to an existing townsperson is the point.

## Credits

By **Mister Miracle**
([@mistermiracle3036](https://github.com/mistermiracle3036)).

ROXIE and PIERS are Game Freak characters, used here as fan tribute.
Built on the gen1recomp engine and pret/pokered research.

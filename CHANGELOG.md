# Changelog

All notable changes to Kanto Rocks are documented here.
This project follows [Keep a Changelog](https://keepachangelog.com/) and
[Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-08-10

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

- **0.1.1** -- ROXIE appears in Vermilion City behind the 4-badge gate,
  as a real new NPC (see README, "Roxie is not a takeover"), and the
  quest registers into the journal.
- **0.2.x** -- the recruitment beats, one per build: the drummer's
  battle, the bassist's missing instrument, the backup singer.
- **0.3.x** -- promotion: the FLYER item and the NPCs who take one.
- **0.4.x** -- the venue: custom tileset, custom map, the warp in, and
  the concert scene.
- **0.5.x** -- PIERS: trainer class, team, entrance, battle, rewards,
  and the quest completing.
- **0.6.x** -- cross-mod rewards, the Yellow constant pass, and tuning
  from playtests.

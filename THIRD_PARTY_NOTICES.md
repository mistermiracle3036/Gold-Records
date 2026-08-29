# Third-party notices

- **Scope of the MIT licence.** The `LICENSE` file covers this mod's own
  code and its own original content. It makes no claim over ROM-derived
  material, over the games this mod runs on top of, or over any Nintendo,
  Creatures or GAME FREAK trademark.
- **gen1recomp** — this mod targets the
  [gen1recomp](https://github.com/bryanthaboi/gen1recomp) engine (mod
  API 2), and from v0.2.0 its Gen 2 / Pokemon Gold support. It reaches one
  engine internal under the `engine_internals` permission:
  `src.mods.Runtime`, purely to write status lines into the mod manager's
  `[ERRS]` screen, which is the only diagnostic channel that exists on a
  phone.
- **ROXIE** is the Virbank City gym leader of Pokemon Black 2 / White 2,
  **WHITNEY** is Goldenrod's gym leader, **CASEY** is a Johto anime character,
  **JIGGLYPUFF** draws on its recurring early-anime singing gag, and **PIERS**
  is the Spikemuth gym leader of Pokemon Sword. They appear here as fan
  tribute. No art, text, audio or data from those works is included;
  everything about them in this mod is original writing built on the
  characters.
- **Quest System** by FAFF0x — optional integration. When it is installed
  the questline also registers a journal entry through its public exports;
  no code is shared, and the mod is fully playable without it.
- **Trainer Journey** — optional integration. When it is installed, quest
  beats award APPEAL, MOXIE and HEART stats, advance the ROCK STAR
  profession, and mildly lean the ethos axis. High stats also add extra
  flavour dialogue at four moments. No code is shared and the mod is fully
  playable without it.
- **Kanto Ribbons** — planned optional integration. This mod will write
  `mon.grHeadliner = true` on the Pokemon that were at the show, for that
  mod to read the same way it already reads `mon.snagged`. A plain
  boolean, set once and never cleared — not the per-category count table
  `mon.contestWins` uses. No code is shared and neither mod requires the
  other.
- **Kanto Contests** — planned optional integration. That mod reserves
  contest scarves as rewards for quests across this portfolio, worn items
  setting `mon.kcScarf`. No scarf item exists in it yet (0.9.0 lists them
  as a future slice), so there is nothing for this mod to award until it
  ships; the reward is designed but parked. No code is shared and neither
  mod requires the other.
- **Roxie sprite art** — the overworld and battle portrait for ROXIE were
  commissioned from **tharkka** (via Fiverr) for this project's use. Both
  files are in `assets/`.
- **Piers sprite art** — the overworld and battle portrait for PIERS were
  commissioned from **Yogurcomics** for this project's use. Both files are
  in `assets/`.
- Pokemon and all related names are trademarks of Nintendo / Creatures
  Inc. / GAME FREAK inc. This mod contains no ROM data or copyrighted
  assets; it is a fan-made script mod and requires the user's own game
  copy via gen1recomp.

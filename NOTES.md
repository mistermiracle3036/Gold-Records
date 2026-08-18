# Gold Records — design notes

**Not shipped.** `NOTES.md` is in the release workflow's exclusion list, so
this stays out of the player's download. It is a spoiler document; keep it
that way.

Every beat below names the mechanism that would build it, in a clause. A
beat that cannot name one is not designed yet — that is the rule this file
exists to enforce, because prose can invent an API that Lua then cannot.

---

## Where the questline stands

Shipped through **0.5.0**: Roxie recruits the player (Violet), the bassist
turns out to be Whitney (Goldenrod Underground), the drummer is found via
the Jigglypuff audition (Ecruteak), and the band plays National Park where
Piers crashes it.

The gap this plan fills: **the band goes from "assembled" to "on stage" in
one line of dialogue.** There is no reason the show is in a park, and no
reason anyone comes. Acts II and III supply both.

---

## Act II — The Venue Hunt (0.6.x)

**The premise:** a band with no room to play. The player tries venues and
gets turned down, and the rejections are the content rather than an
obstacle to route around.

**The structural payoff, which is the point of the whole act:** every real
venue says no, so the band plays a park. It retroactively explains 0.5.0 —
National Park is not a venue, it is what you do when nobody will book you.
A guerrilla gig. That also makes Piers turning up funnier: he came to a
field.

### The venues

Each is approached at a **vanilla** location, so nothing here depends on
another mod being installed. Mechanism throughout: an owned runtime NPC at
the door plus `world.interacted` dialogue, exactly as every existing actor
works.

| Venue | Location | The "no" |
|---|---|---|
| **Dance Theater** | Ecruteak (vanilla, already used) | The Kimono Girls. "You auditioned here. That did not make it yours." |
| **Radio Tower** | Goldenrod (vanilla) | "We broadcast. We do not host." — but plants the radio spot that Act III uses. |
| **The Underground** | Goldenrod (vanilla, already used) | Roxie's obvious answer, and Whitney refuses: playing there outs her. A character beat, not a logistics one. |
| **Olivine** | vanilla Olivine Cafe | "We seat forty people and they come for the quiet." |
| **National Park** | vanilla | Nobody owns it. Nobody can say no. That is the answer. |

### Crossovers — additive, and they degrade to nothing

Detected with `mod.find(id)` on `game.ready`, never at load. If the mod is
absent the beat simply is not in the list; nothing is gated, nothing waits
on a release order, and no venue depends on another mod's map existing.
This follows the cross-mod protocol: no hard dependency, ever.

- **Big Night in Olivine** — `NONNO'S` is a restaurant having its opening
  night. A punk band asking to play a fine-dining launch is the joke;
  Primo and Secondo are appalled. The best of the three.
- **Kanto Contests** — the Contest Hall is a *stage*, which is Roxie's
  argument. The judge's answer is that a contest is a performance and a
  gig is a riot. She takes this one personally.
- **Court of Noctowl** — a society that quietly steers Johto could
  absolutely find a band a room. With strings. The one venue that says
  *yes* and should be refused.

**Do not edit those repos.** If a crossover ever needs something from
their side, it is a data contract and a brief, the way the Ribbons field
was.

### What Act II costs

Cheap. Owned NPCs, dialogue, `mod.save` beats and `mod.find` checks — every
mechanism is device-proven in this mod already. No new engine surface. This
is the safest possible next slice, and a good work order.

---

## Act III — Promotion (0.7.x)

**The premise:** a gig nobody knows about is a rehearsal. The player builds
an audience, and *the audience is a mechanic*, not a counter.

### Crowd score

An integer in `mod.save`. It is the only number Act III produces, and it is
what makes the finale differ between playthroughs.

### Where the choices come from

Gold gives a mod exactly three ways to ask the player anything. Act III
uses all three and invents nothing:

1. **Who you walk up to.** The drum audition already resolves a choice this
   way. Each town has a promoter; which ones you bother with is a choice.
2. **What you show them.** `mod.ui.push(game, "Gen2PartyMenu", { prompt,
   onChoose, onCancel })` — Snag's merchant mechanic. A promoter asks to
   see a Pokémon, and the poster, the radio spot or the word-of-mouth takes
   on that Pokémon's character. **PROVEN from the overworld, device,
   2026-08-18** — see "Blocked on proof" below for the evidence. This is
   the interesting one, and it is now real: an order can spec it directly
   rather than falling back to option 1 alone.
3. **A mod option.** Snag's `snag_ball_sources` shape: a `choice` row
   (`{display, stored}` pairs, read positionally) selecting which promotion
   routes are open at all — POSTERS / RADIO / WORD OF MOUTH / ALL. It gates
   supply the way Snag's gates ball sources, and Roxie's dialogue branches
   on it so she never points at a closed route.

There is **no yes/no box** available to a mod on Gold — it exists only
inside `src/ui/gen2/BattleState.lua`. Any beat written around one is
unbuildable, and that is the trap to avoid in this act.

### The payoff: the crowd changes the Piers fight

This is what the user asked for, and it is buildable today because
`trainer.party` already builds his team at battle time from our own table.

**The lever is team SIZE, not level.** Levels here are portfolio-owned
(`briefs/LEVEL_CURVE.md` put Piers at 33–35 as a capstone against Chuck's
anchor), so moving them is not this mod's call. Moving the *count* keeps
every mon inside the approved band and still changes the fight
substantially:

| Crowd | Piers brings | In character as |
|---|---|---|
| thin | all five | nobody is watching; he is just better than you |
| decent | four | he drops one to keep it short |
| yours | three | the noise rattles him, and he says so |

### Two axes, four endings — the part worth building

Keep **"did you win the battle"** and **"was the show any good"** separate.
They are different questions and a band story should care more about the
second.

|  | Small crowd | Big crowd |
|---|---|---|
| **Lose to Piers** | The gig nobody came to. Roxie is unbowed and it is the bleakest, funniest ending. | You lost the fight and won the night. Piers says so. |
| **Beat Piers** | You beat the headliner in front of nine people. | The show. Both. |

**The reward should hang on the SHOW, not the battle.** That gives promotion
a mechanical reason to exist rather than being a fetch phase before the real
content, and it makes the reward genuinely missable — which is what makes it
worth having. See "Rewards" below for what the reward now is.

---

## Blocked on proof — do not spec these until they boot

Both were mine to prove, not a work order's to assume. This is the rule that
kept `map_scripts` from costing a build round.

1. ~~`Screens.push` → `Gen2PartyMenu` from the overworld~~ — **PROVEN, device,
   2026-08-18.** A throwaway probe mod (`pmprobe`, not part of this repo)
   spawned one NPC in NATIONAL PARK and called
   `mod.ui.push(mod.game, "Gen2PartyMenu", { prompt="choose", onChoose, onCancel })`
   on `world.interacted`. On a real Gold boot: `PUSH OK`, then choosing a
   party member reported `CHOSE #1 SCIZOR` — a real slot index and a real
   species out of the player's actual party, from the overworld, with no
   battle running. The mechanic Act III's promoter beat needs is real.
   Confirming on the same run: the screen closing cleanly on CANCEL (not
   just CHOOSE), and that the overworld stays fully responsive afterwards —
   `PartyMenu:update`'s onChoose/onCancel arms do not pop the screen
   themselves outside a battle submenu, so the calling mod must
   `game.stack:pop()` or the menu would sit there looking frozen. `pmprobe`
   does that explicitly; a work order for Act III must too, and should be
   told so rather than left to notice it the hard way.
2. **A custom item on a Gold boot.** — **PROVEN, published mod.** Too Many
   Balls' `kanto_balls` (`games: ["gen1","gen2"]`) registers `BALL_CASE` via
   `mod.content.items:register` and STATUS.md already marks it
   "✅ craft balls on device" — a mod item that exists in a Gold bag and
   opens a screen when used. That is every link the flyer conceit needs;
   `items` staying off `Schemas.GEN2` was never actually a UI-level block,
   just a routing detail.

Both blockers are cleared. Act III can be specced against the real
mechanism instead of the fallback.
written.

---

## Build order

- **0.6.x — the venue hunt.** Cheapest, no new engine surface, explains the
  park. Good work order.
- **0.6.x+1 — the proving slice** for the party menu and a custom item.
- **0.7.x — promotion**, specced against whatever the proof allows.
- **0.8.x — the rewards.** A trophy, a gift Pokemon, and the tour. See
  below.

---

## Rewards (0.8.x) — revised 2026-08-18

Two rewards, doing different jobs: one **records** that you did it, one
**changes how you play afterwards**.

### 1. A trophy, not a ribbon — and this changes the shape

Developer's call: the Trophy Case becomes the default reward for finishing a
quest across the portfolio, replacing a ribbon-for-everything.

**`mon.grHeadliner` is retired.** It was never written and never published,
so dropping it costs nothing — the same free moment the `kr*` → `gr*` rename
caught, and the last one this field will get.

The shape genuinely changes, not just the name:

| | Ribbon | Trophy |
|---|---|---|
| Lives on | a Pokemon (`mon.ribbons[ID]`) | the save (`save.trophyUnlocks[key]`) |
| Means | *this Pokemon* was there | *you* did this |
| Missable per-mon | yes | no — it is a player record |

That is the right home for "the band played a show and it went well". It is
the player's achievement, not a Pokemon's.

**`mon.grPiersGift` stays exactly as it is** — per-mon provenance for the
gift Pokemon, unaffected by any of this, and still not a ribbon.

### ⚠ BLOCKING: the trophy contract is not settled yet

Checked rather than assumed. `trophy_case` **0.1.1 exists** — a front door
and an empty case — and its own handback says it ships "no save, storage,
map-patch, item, battle, award, catalog, IPC, or Pokemon field changes."
Its exports are `version` and `owns`. **There is no contract implemented.**

`briefs/ONBOARD_trophy_case_agent.md` lists the field name
(`save.trophyUnlocks`) and the key convention (lowercase
`mod_id:achievement_id`) as decisions **1 and 2 that the developer must
make**, marked "Blocking: it is the contract."

Gold Records is **published**. Anything written here lands in real players'
saves, and a key renamed afterwards orphans it. So: propose, get it
approved, then write — exactly how the Ribbons field was handled.

**Proposed, pending approval:**

    save.trophyUnlocks["gold_records:headliner"] = true

One trophy, awarded for the show going well — not for winning the fight.
Boolean, set once, never cleared, retroactive-friendly by construction.

### 2. The tour — the mechanical reward

The gap a trophy leaves is that it changes nothing about play. This fills it,
and it answers the brief's "move tutor / happiness / repeatable money" with
one mechanic instead of three, because for a band there is only one obvious
answer: **you have a band now, so go and play.**

Repeatable gigs, unlocked when the questline ends. Each show pays and lifts
the band's spirits.

**Both halves are Gold-native and verified in source:**

- **Money** — `save.player.money` (`src/world/gen2/World.lua:2485,2497`).
  The manager's cut. A repeatable, non-grindy income that is thematically
  inevitable rather than bolted on.
- **Happiness** — `Happiness.change(mon, event)` and
  `Happiness.changeParty(party, event)` (`src/core/gen2/Happiness.lua:164,190`),
  with named events in `Happiness.EVENT`. Playing a show makes your Pokemon
  happy, which is *what happiness is for*. Gen 1 has no happiness at all, so
  this is a reward that only exists because the mod moved to Gold — a good
  argument for the Gold-first direction rather than a consolation for it.

**Where the gigs happen is the payoff for Act II:** the venues that turned
the band down now want them. The Dance Theater, the Radio Tower, the cafe —
each becomes bookable once you are somebody. That closes the loop the venue
hunt opens, and it means Act II is not just a joke sequence, it is the
setlist.

**Guardrails, since this touches the save:**

- Money is *earned*, never taken, and clamps at the engine's cap.
- Happiness uses the engine's own event deltas rather than writing
  `mon.happiness` directly, so it obeys the cart's tiering.
- A gig must not be a money printer. Rate-limit it — one paid show per
  in-game day, or per Pokemon Center visit — and say which in the order.
- No EXP, no levels, no battles in the tour loop. A gig is a gig; if that
  ever changes it goes through `briefs/LEVEL_CURVE.md`.

### Not chosen, and why

A **move tutor** was on the table. Rejected as the primary: it is one-shot
rather than repeatable, writing `mon.moves` is more invasive than either
half of the tour, and "Roxie teaches your Pokemon a song" is a better
flourish *inside* the tour than a reward competing with it.

### The rewards are outsourced too (developer, 2026-08-18)

Earlier drafts of this file kept them back on the grounds that they write
into the player's live party and carry a cross-mod contract. The developer's
call is to outsource the code, and that is workable — but *what* gets
outsourced has to be the implementation, not the specification. The risk in
this slice is entirely in the spec, and the spec is already settled:

- **The contract is fixed and agreed with the Ribbons agent.** Both fields
  are plain booleans, set once, never cleared. `mon.grHeadliner` on each
  band member that played the show; `mon.grPiersGift` on the Pokemon Piers
  hands over. `grPiersGift` is provenance, **not** a ribbon. That is not a
  decision the order re-opens — it goes in as a given, with the README's
  contract table quoted.
- **The one invariant that must be spelled out**, because it is the thing
  this project guards hardest: a gift Pokemon must **never** displace
  anything. Full party goes to a box; every box full means the gift is
  refused with a line, not dropped. No overwrite, no silent loss, no
  reordering of the player's party.

Acceptance for that order should be sharp enough to check mechanically:
exactly those two field names, exactly boolean, written at exactly those
two moments, and no other mutation of any party or box member anywhere in
the diff. That is the same shape of acceptance line that caught Casey on a
wall — a criterion you can grep for beats a criterion you have to judge.

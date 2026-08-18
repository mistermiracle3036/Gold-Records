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
2. **What you show them.** `Screens.push(game, "Gen2PartyMenu", { prompt,
   onChoose, onCancel })` — Snag's merchant mechanic. A promoter asks to
   see a Pokémon, and the poster, the radio spot or the word-of-mouth takes
   on that Pokémon's character. **UNPROVEN from the overworld** — see
   "Blocked on proof" below. This is the interesting one and it does not
   get specced until it boots.
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

**The HEADLINER ribbon should hang on the SHOW, not the battle.** That is
what `mon.grHeadliner` is for, and it gives promotion a mechanical reason to
exist rather than being a fetch phase before the real content. It also
means the ribbon is genuinely missable, which is what makes a ribbon worth
having.

---

## Blocked on proof — do not spec these until they boot

Both are mine to prove, not a work order's to assume. This is the rule that
kept `map_scripts` from costing a build round.

1. **`Screens.push` → `Gen2PartyMenu` from the overworld.** Every call site
   in the engine is inside battle code. If it does not work outside a
   battle, Act III loses its most interesting choice and falls back to
   "who you walk up to", which still works but is thinner.
2. **A custom item on a Gold boot.** `items` is absent from `Schemas.GEN2`,
   which means it keeps the shared `data.items` target — and
   `src/core/gen2/ItemEffects.lua` says a mod's write "has to end up back
   on `data.items`", so it should work. Not the same as having seen a FLYER
   in a Gold bag. The whole flyer conceit rests on it.

A small proving slice covers both and is worth cutting before either act is
written.

---

## Build order

- **0.6.x — the venue hunt.** Cheapest, no new engine surface, explains the
  park. Good work order.
- **0.6.x+1 — the proving slice** for the party menu and a custom item.
- **0.7.x — promotion**, specced against whatever the proof allows.
- **0.8.x — the rewards.** `mon.grHeadliner` on the show,
  `mon.grPiersGift`, and the gift Pokemon.

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

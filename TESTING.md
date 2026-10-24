# Gold Records 0.7.0 — test and migration handback

## Build provenance

Baseline: the supplied gold_records-0.6.4.zip, SHA-256
`25867dd46f5f9fd1d068f8bec9544d4ec0dc2825f20a3cb4b44d0c5bbb389a4e`.
It supersedes this workspace's older 0.6.2 checkout. Neither that checkout,
the original archives, nor any reference mod was modified.

Engine contracts/validator: gen1recomp commit
`0142468125cf97bb72cc0dcd242b6dc9cd31401b` (git describe:
`v0.2.11-118-g01424681`; source Version.lua says 0.0.0-dev).
This is the existing engine checkout, not a claim about today's latest upstream.
Lua execution: bundled LuaJIT from the earlier engine 0.2.4 source tree.
No game ROM, imported runtime graphics dataset or playable save was supplied
in this pack. No desktop or phone game session was run.

## Scope delivered

Milestone A repair pass and Milestone B native first-show prototype are
implemented for private playtesting. Final visual polish/placement acceptance
requires device feedback. The stage is a compact native UI screen reached from
park actors, not new map tiles. It has paired speakers, guitar, bass, centered
kit, animated picks/sticks, four spectators, and an animated Piers entrance.
No special renderer is required; it does not take over map music or camera.

Deferred: Milestone C's full venue payoffs, expanded multi-view Band Book,
audition staging, optional Channel news, Cutscene enhancement, radio fulfillment,
recording/tour, Casey/Wooper custom art, commissioned playing poses, HEADLINER
and gift-field writers. No claims of live visual or performance validation.

## Executed checks

| Check | Method | Result / limit |
|---|---|---|
| Main/module syntax | LuaJIT compilation | Passed |
| Loader, manifest, registries | Engine modkit validate --strict | Passed with fixture data |
| Gen 2 compatibility surface | Engine modkit gen2check --strict | Passed; not an edition playtest |
| Distribution contents | Engine modkit lint | Passed; commissioned originals retained |
| Regression scenarios | tests/regression.lua, mocked engine | Passed; run with all optional mods absent |
| Text | Static authored-page scan; engine Font.width with ASCII fallback | Two-line pages and 144px width checked; translated/custom font layouts untested |
| Screen bounds | Mocked draws | Text coordinates within 160×144 for exercised screens; no GPU rendering |
| Gold/Silver/Crystal | Shared API inspection and Crystal KAZU alias mock | Device behavior untested in all three |
| Assets | Byte comparison to baseline | All four commissioned PNGs unchanged |
| Native save serialization, battle AI, phone controls, FPS | Live | NOT RUN |

Regression scenarios include aborted/late dialogue; save identity changes;
owned versus unrelated battle outcomes; original carrier restoration;
local beat-50/80 handoffs; picker cancel/failure; aborted performance; once-only
friendship; removed participant; stale picker ownership; optional activity
availability after beat 90; Wooper one-shot; old busker migration; cooldown,
duplicate callback and rollback; soundcheck, pauses, abandoned and rough sets;
Piers arrival/loss/retry/win; encore/debrief/card; reprise history immutability;
legacy completed save; unknown schema; contest deferral; duplicate actors;
Crystal KAZU; mismatched trainer member; crossover removal; scene reload cleanup.

Run from the unpacked mod folder with LuaJIT:

```
luajit tests/regression.lua .
```

The test mocks engine services and does not load a game. It is not a cheat or
save editor. The engine commands are documented in tests/VALIDATION.txt.

## Migration and receipts

| Existing progress | After update |
|---|---|
| 0–40 | Existing battles/recruitment retained. New Whitney reveal supplies drummer objective locally. |
| 50 | Speak to the revealed bassist locally to get the drummer objective; Violet fallback remains. |
| 60–71 | Existing audition sequence retained. Casey's completed recruitment leads locally into venue hunt. |
| 80 | Speak to Casey in the theater; no return to Violet required. |
| 81–86 | Current venue retained; missing optional Contest/Court stops recover as before. |
| 90 | Soundcheck then opening; four badges required. |
| 100/101/102 | Existing Piers arrival/armed/retry retained; no mandatory new opening. |
| 110+ | Old victory retained. Optional new encore/debrief/card; no battle reward or historical party tag replay. |
| first_show.schema > 1 | Interactions/progress blocked without overwriting unknown record. Use a matching newer mod. |

New owned state: `first_show` schema 1 (opening, victory, encore, debrief,
keepsake, soundcheck/practice, immutable first summary, legacy marker);
`dance_friendship_v1` and `dance_completed_v1`; and `busk.clock = play_v1`
with `last` saved-playtime minute. Existing beat and award tags are preserved.
Actors, closures, screen instances and images are runtime only.

An old dance beat cannot prove a qualifying performance, so the new friendship
ledger begins unset: one newly completed qualifying showcase may earn it.
Existing Trainer Journey tags are not cleared. An old busk done flag proves
sailor recognition, but not a date; the first migration visit starts a paid
cooldown without paying. The next set becomes eligible 30 saved-playtime minutes
later. Wall-clock/day changes cannot accelerate it. Playtime rollback must catch
up to the prior high-water time; at the engine's maximum clock value, further
paid sets may remain unavailable. Restoring an old whole save restores its old
progress normally; this is not an anti-save-scumming mechanism.

The busk receipt is written before native reward calls. This bounds retries but
is **not** a crash-proof transaction: an API failure between writes can lose that
set's payout rather than pay twice. First-show keepsake is an idempotent native
boolean record. No news delivery or inventory grants are involved.

Legacy first-show details read EARLIER SHOW / Old set: unknown. Current party
members are never labeled as participants in a historical Piers win. Later
busking/rehearsal cannot rewrite the first-night summary.

## Actor locations

| Phase | Violet | Underground | Theater | Park |
|---|---|---|---|---|
| Recruitment | Roxie/fallback objectives | Feedback, then disguised Whitney | Audition cast when assigned | None |
| Venue hunt | Roxie/fallback objectives | Whitney; King/venue Roxie when unlocked | Casey; local venue actors | None |
| Show/challenge/encore | Roxie/Band Book | King remains; band removed on entry | Host remains; band removed on entry | Band, then Piers |
| Debrief complete | Roxie/card/rehearsal | King | Host | Cast removed |

Violet Roxie deliberately remains the compatibility contact. Existing side-host
positions and band park cells are retained, with the existing walkable fallback.
New instruments and audience are confined to the screen and add no collision
objects. Park anchors: Roxie (10,44), Whitney (12,44), Casey (15,44), Piers (12,42).
Actual fallback cells still require Position Reporter/device confirmation.

## Device acceptance route (back up the save first)

1. Gold Records alone: check each recruitment fight, loss, win, and a subsequent
   vanilla trainer. Names, portraits, parties and ordinary loss rules must return.
   Repeat specifically for Crystal's Basement King and for an abandoned arm.
2. With three badges, the park show remains unavailable. With four, find Roxie
   near the south area. Verify no actor blocks a gate or another mod's actor.
3. Choose SOUNDCHECK. Identify Roxie's guitar, FEEDBACK's bass and Casey's kit.
   With sound muted, choose each displayed cue using controller/keyboard and
   phone D-pad/A. Try all second choices: recovery must remain possible.
4. B pauses; A resumes; B while paused leaves. Reopen and finish. OPENING SET
   appears only after completed soundcheck. Leave the map/reload between stages.
5. Play the opening. Sailors should be present only if busking was done before
   that performance. Piers must walk onscreen before his interruption text.
6. Return to park, prepare party, and fight Piers. Lose once: retry without
   repeating soundcheck/opening. Win and finish the battle UI before opening
   PLAY ENCORE. No reward screen should interrupt battle teardown.
7. Play the encore, then BAND DEBRIEF. Cast disappears only after dialogue.
   Visit Violet for the First Show card and a short reprise; no extra rewards.
8. Load an old beat-110 save. Encore must be offered without re-fighting Piers;
   the card must show unknown earlier-set details rather than invented results.
9. Visit theater/King/Wooper after the show. Unfinished activities remain;
   resolved Wooper never reappears. Cancel and fail to open the picker where
   possible; neither may grant friendship or move beat 81. Explicit Roxie skip
   advances without performance credit. Repeat a completed dance: no extra reward.
10. Busk, repeat immediately, then after 30 saved-playtime minutes. Only the first
    and cooled-down sets pay. Existing buskers initially wait once after migration.
11. Run an active Bug-Catching Contest: no show must open or steal its state.
    Check ordinary National Park travel on contest and non-contest days.
12. Repeat on Silver and Crystal; test save/reload at each checkpoint. Record
    startup/teardown delay and repeated-set performance on phone; no measurements
    are claimed here. Report missing sprites, overflowing text or UI trapping.

## Changed files

Updated main.lua, manifest.json, mod.card, README.md, CHANGELOG.md and
THIRD_PARTY_NOTICES.md. Added concert.lua, TESTING.md, tests/regression.lua and
tests/VALIDATION.txt. The LICENSE and all four existing PNGs are byte-identical
to the baseline. No new bitmap/audio asset, public release or repository push.

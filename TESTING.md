# Gold Records 0.7.1 — paired performance test

## Current build

Baseline: exact supplied private Gold Records 0.7.0, SHA-256
`5b3fc0dce458aa6067b552b8ac641b19680a43a9265b21c2f3744eec987fc1fd`.
The older central Kanto-Rocks checkout was not used or overwritten.

This build adds an optional Crystal Cutscene livePerformance v1 adapter and
Bani's approved Larry spectator art. It retains first_show schema 1, integer
quest beats, all existing battles and the native presentation. Larry is just a
fan here; no recruitment or instrumental expertise is revealed.

Run `luajit tests/performance_integration.lua .` from the source tree. It also
runs the complete baseline suite. All **53 baseline and 35 new mocked checks**
passed. They cover callback identity/duplication, detached results, interrupted
cues, visible Piers, retry, provider absence/version/removal, option changes,
owner reload, save/session/map/checkpoint changes, foreign screens, old victories
and future save schemas. Mocks do not prove real rendering or phone behavior.

A native LÖVE graphics fixture also rendered the actual fallback concert.lua
using the real engine Font/SpriteRenderer, Crystal palettes and imported art,
and Gold Records' unmodified sprite registration prefix. All seven used sprite
definitions loaded. Cue, playing, Piers entrance and pause frames were visually
inspected; text stayed readable and Larry used his approved color sheet. The
fixture caught the old invisible ASCII selection marker. The fix uses Crystal's
supported arrow glyph; both cue selections and the Band Book were re-rendered
and visually checked, and all 88 mocked checks passed again. Exiting
cleared the screen's sprite references. World/save/dialogue services and asset
filesystem resolution were fixture adapters, not a full game playthrough.

Engine loader/source inspected for this integration:
`ca142860c67f351ed5232436f40c88a8a5e3a47d` (development checkout).
Strict modkit validation with fixture data, Gen 2 check, and distribution lint
passed. The Gen 2 scanner reports unresolved module literals in the test stubs;
these are not runtime compatibility proof or a claim of a three-edition test.

The global sprite-registry audit reports existing divergences/stale entries in
other projects. This isolated build's Larry file is checked byte-for-byte against
the approved canonical_color master, with BROWN/3 and trueColor registration.
The four existing commissioned PNGs and LICENSE remain unchanged from 0.7.0.
Larry's shared registry usage now includes Kanto-Rocks (Gold Records). Updated
credit tables were generated into this task's work folder for later portfolio
adoption; the existing mod card and notices already credit Bani. No other mod
source or canonical artwork was edited.

## Paired phone route

Import Gold Records 0.7.1 and the paired Crystal Cutscene 0.48.0 prototype,
then fully quit/relaunch. Keep Cinematic shows on. This is a private test;
back up the save and retain only one enabled copy of each mod.

1. At four badges and the existing park objective, talk to Roxie. Choose
   SOUNDCHECK. Check the actual commissioned cast, quiet Larry spectator,
   instruments, untimed cues, and readable portrait/landscape framing.
2. Pause and resume. Try Skip and Leave: neither should complete soundcheck.
   Talk to Roxie and retry; complete all three cues.
3. Complete OPENING SET, including one rough choice. Piers must visibly enter
   before completion. Prepare your real party, then talk to Piers for battle.
4. Lose and retry without repeating the opening; win, leave battle UI, then
   choose PLAY ENCORE. Debrief and review the First Show card in Violet.
5. Repeat on a save already past Piers: the encore must not require a new win.
   Rehearse/reprise without rewriting the first-show summary or extra rewards.
6. Disable Cinematic shows, or remove the optional provider and fully restart.
   The same native show remains usable with Larry in its audience.
7. Check save/reload, pause/leave, repeated shows, music restoration, controls,
   and the park's Bug-Catching Contest. Report build versions and checkpoint.

The paired native fixture used this actual performance_bridge.lua and sprite
registration prefix with Crystal Cutscene's actual renderer in portrait and
landscape. In both, three cues (including an alternate answer) and Piers' entrance
completed, exactly one result arrived after cleanup, 31 scene resources released,
and save/world/map/actors/camera/speed/zoom were unchanged. This fixture bypasses
the story/map VM; the real quest progression is covered separately by the mocks.
The future-lineup Olivine rehearsal also completed without save changes, releasing
47 resources. It is a test preview behind a default-off option, not a recruitment.
Final paired package hashes and screenshots are in the build handback. Phone
appearance, touch controls, preparation time and performance need device testing.
The following sections preserve the detailed 0.7.0 baseline test record.

# Historical 0.7.0 baseline validation

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
live bookings/tour, Casey/Wooper custom art, commissioned playing poses, HEADLINER
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

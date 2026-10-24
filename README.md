# Gold Records — private 0.7.0 test

Roxie starts a band out of spite and appoints you manager. Find FEEDBACK in
Goldenrod, recruit Casey in Ecruteak, find somewhere to play, and make the first
National Park show happen. No other mod is required.

This build targets Gold, Silver and Crystal on gen1recomp 0.2.21 or newer.
Validation here is static and mocked, **not a live three-edition playtest**.
Back up your save, import this ZIP, and fully quit/relaunch the game. Keep one
Gold Records installation enabled. Do not reset your quest or start a new game.

## The first show

After the venue hunt and with four badges, speak to Roxie in National Park.
Choose SOUNDCHECK to practice a four-count, bringing the bass forward, and
recovering after a cable crackle. Choose OPENING SET afterward.

Use Up/Down and A (including the phone's standard controls). Cues are untimed;
there is no audio-only instruction. Acknowledge each response with A. B or
Start pauses; A resumes, B while paused leaves. Unfinished sets return to the
same checkpoint. A rough set still reaches Piers; no preparation or money is lost.

Piers visibly enters the native stage screen before his interruption. After
returning to the park, prepare your party and speak to him to begin the challenge.
A loss preserves the opening and offers a direct retry. After winning and leaving
the battle screen, talk to Roxie for PLAY ENCORE, then BAND DEBRIEF.

The debrief packs up the park cast and saves a First Show card. Visit Roxie at
her usual Violet City position to read NEXT OBJECTIVE or FIRST SHOW CARD, rehearse,
or play a short reprise. Reprises give no money, friendship or profession points
and do not rewrite the first-show record. Old Piers wins need only the new encore.

## Side activities and rewards

- The Dance Theater host remains available. Cancelling does not perform or
  advance anything. At the initial venue stop, speak to local Roxie to explicitly
  skip; you can return later. The first completed qualifying showcase grants
  friendship to its actual participating Pokémon once per save. Nonqualifying
  showcases still count as performances. Old Trainer Journey tags are preserved.
- The Olivine sailor pays $300 and party friendship once per **30 saved-playtime
  minutes**, not once per calendar day. The engine exposes no absolute game date.
  Existing buskers start this cooldown on their first visit after updating.
- The Basement King remains available after booking the park. Wooper remains
  available until its existing one-shot completion flag is set.
- Prior busking brings sailors to the stage audience. This fact is fixed in the
  first-show record when the opening finishes; later busking affects reprises.

## Compatibility and ownership

Trainer Journey is optional: existing once-only award IDs and `rock_star`
profession ID are retained; its display name becomes BAND MANAGER. No ranks gate
this mod. The current chapter still cannot earn its ten-point LEGEND threshold
alone. Contest/Court flavor stops remain optional and recover when removed.
There is no Quest System journal adapter, Channel news publisher or Cutscene
adapter in this build.

Gold Records adds owned runtime actors and temporarily uses native trainer
carriers for its four battles. It restores names and its can-lose variable after
owned battle outcomes, map abandonment and save reload. Vanilla records are not
permanently edited. Piers' team remains unchanged.

`mon.grHeadliner` and `mon.grPiersGift` remain reserved set-once boolean contracts;
**neither is written**. Persistent winning-participant identity and gift delivery
need a separate verified implementation. No gift Pokémon or ribbon is promised
by this private build. The native First Show card is the implemented keepsake.

Roxie's commissioned sheets by tharkka and Piers' by Yogurcomics are unchanged.
The stage uses original code-drawn instruments, paired speakers and animated
picks/sticks. Casey still uses a Lass stand-in; there are no commissioned playing
poses. Missing sprite data uses simple temporary silhouettes. No ROM images or
songs were added. The existing map music remains; cues use the engine's short
text-confirmation sound. This is a staging prototype, not a recorded song.

## Calibration

Report quest actors defaults OFF. Enable it if your mod-options UI works to log
positions to [ERRS]. If that UI is unavailable, change only `default = false` to
`default = true` for `show_report` in main.lua in a separate private test copy
(and clear an existing saved false option). The Position Reporter mod can also
supply coordinates without changing Gold Records. Report expected versus actual
positions, edition, engine version and quest checkpoint.

See TESTING.md for migration, reproducible tests and unverified device behavior.

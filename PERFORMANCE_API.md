# Optional performance presentation

Gold Records 0.7.1 consumes Crystal Cutscene's `exports.livePerformance` v1.
`performance_bridge.lua` is the adapter. Provider source is not copied here.

Each use resolves the enabled provider again. `api.version == 1` and a callable
`api.start` are required. `api.start(game, request, onResult)` returns an accepted
handle or `nil, reason, detail`; stable rejection reasons are `busy`, `invalid`
and `unavailable`. Rejection leaves no provider screen/resources and does not
call back. An accepted handle supplies `:cancel(reason)` and `:status()`.

Requests include a per-attempt `runId`, `showId="national_park_first"`, mode,
Rock trio, Larry as an ordinary spectator, warm light/banner/music opening,
the existing optional preparation facts, `cueSet="first_show_v1"`, and a live
owner guard. Opening mode additionally supplies Piers' entrance. No musician
recruitment or configurable future roster is inferred from a presentation.

The provider calls back exactly once, after cleanup, with matching identity,
`status` (`completed`, `skipped`, `cancelled`, `failed`), `completedCues`, `rough`
and `entranceShown`. A completed current request requires three completed cues,
an integer rough count from zero to three, and a shown entrance for opening.
Gold Records normalizes a fresh bounded result and applies its own progression.
Preparation facts come from Gold Records' pre-show snapshot; provider-supplied
arbitrary text or mutable tables never enter the save.

Only completed shows count. Skip and leave are retryable, and confer no
soundcheck/opening/encore credit. The renderer does not award rewards, alter
quest flags, start Piers' battle, or modify a party. Replays preserve history.

Gold Records validates its current instance, save/session/map/checkpoint,
provider identity, and Cinematic shows option. Map/save lifecycle events request
cancellation; invalid or late callbacks cannot apply progress. The renderer
owns restoration, input, camera, audio, and resource cleanup. Neither side may
pop a different screen or release shared sprite/image caches.

Absent/incompatible/disabled providers and clean rejections use the existing
native show. After acceptance, failures never automatically start a second
presentation. Exceptions or malformed results are reported in [ERRS].

This contract is for the existing first-show integration. Booking, genre,
lineup and venue-preference systems remain Gold Records' later owned work.

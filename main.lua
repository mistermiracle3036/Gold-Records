-- Kanto Rocks -- ROXIE (Virbank City gym leader, Pokemon B2/W2, poison
-- punk and frontwoman of "Koffing and the Toxics") has come looking for a
-- scene, a band and one big show. You end up her manager.
--
-- v0.2.0 MOVES THE MOD TO GOLD (Gen 2) and to JOHTO. ROXIE now turns up in
-- VIOLET CITY once you have a badge, and is deeply unimpressed by how
-- quiet the place is. Gen 1 support is removed in this version -- see
-- CHANGELOG; the Red implementation is recoverable at commit 78a88bb.
--
-- WHY THIS IS A REWRITE AND NOT A LOCATION SWAP. Gen 2 is a PARALLEL
-- engine: a Gold boot never loads src/core/Game.lua,
-- src/world/OverworldController.lua or src/battle/BattleState.lua, so a
-- Gen 1 pattern does not "mostly work" -- it does nothing, quietly. Four
-- things had to change outright:
--
--   1. map_scripts has NO Gen 2 home. data.gen2Scripts is the cart's own
--      bytecode pool keyed by ROM pointer, and a Lua row list merged into
--      it "is not something src/script/gen2/Vm.lua can run"
--      (docs/mod-api-gen2-compat.md:712). The registry is gated on a Gold
--      boot. So ROXIE's dialogue is driven from the world.interacted
--      event instead -- see "Talking to her" below.
--   2. Gen 2 object movement is NUMERIC, not the Gen 1 "STAY" string
--      (src/world/gen2/Npc.lua MOVE table).
--   3. Badges are not in the flag table and src.inventory.Badges is not
--      served by the compat adapter. Gold keeps them in
--      save.player.badges plus save.player.kantoBadges.
--   4. src.render.TextBox is not served either. Diagnostics go through
--      Runtime.reportError into the mod manager's [ERRS] screen, which is
--      the only channel that exists on the developer's phone anyway.
--
-- Everything here is written against source read in this working tree at
-- engine v0.1.78 -- src/world/gen2/{WorldAPI,World,Npc,Map}.lua,
-- src/mods/Gen2Compat.lua, tools/rom_manifest_gold.json. Anything not yet
-- confirmed on a real Gold boot is marked TODO/CONFIRM.

return function(mod)
  local VERSION = "0.2.0"
  mod.exports.version = VERSION

  -- The ONLY engine internal this mod touches. Everything else goes
  -- through mod.world / mod.events / registries, which are
  -- generation-agnostic. Runtime is mod infrastructure rather than a
  -- generation module, so it is served on both; reportError is the
  -- channel the Gen 2 brief names for iOS, where no log exists.
  local Runtime = require("src.mods.Runtime")

  local MAP        = "VIOLET_CITY"   -- Gold: group 10, map 5, 20x18 blocks
  local OBJ_NAME   = "KR_ROXIE"
  local BADGE_GATE = 1

  -- Gold's overworld sprite space is its own (162 ids,
  -- constants.spriteOrder in rom_manifest_gold.json). SPRITE_COOLTRAINER_F
  -- exists there at index 35 and stands in until assets/roxie.png lands.
  -- NOTE: Gen 1's paletteSource ROM crosswalk is meaningless here, so the
  -- custom-sprite hook is deliberately not carried over yet -- Gold's
  -- palette story needs its own read before ROXIE gets bespoke art.
  local ROXIE_SPRITE = "SPRITE_COOLTRAINER_F"

  -- src/world/gen2/Npc.lua MOVE: STANDING_DOWN = 6. A string here is
  -- silently treated as MOVE.STILL with a default facing.
  local MOVE_STANDING_DOWN = 6

  mod.exports.owns = {
    maps      = {},
    trainers  = {},
    items     = {},
    sprites   = {},                      -- SPRITE_KR_ROXIE once art exists
    objects   = { [MAP] = { OBJ_NAME } },
    monFields = { "krHeadliner", "krPiersGift" },
  }

  ----------------------------------------------------------------------
  -- Diagnostics. The developer tests on an iPhone, where the log does not
  -- exist -- and on a Gold boot the adapter's own warning channel is
  -- log-only, so a degraded member is invisible on device by design.
  -- Runtime.reportError renders in the manager's [ERRS] screen, which
  -- wraps at 16 columns over an 11-row window: keep lines short.
  ----------------------------------------------------------------------
  local function report(msg)
    local ok = pcall(Runtime.reportError, "kanto_rocks", msg)
    if not ok then mod.log:warn("report failed: %s", tostring(msg)) end
  end

  ----------------------------------------------------------------------
  -- The gate.
  --
  -- Gold splits badges across TWO tables and neither is reachable through
  -- getFlag (ENGINE_* is a different bitfield): save.player.badges is
  -- Johto, save.player.kantoBadges is Kanto, and the cart's own
  -- VAR_BADGES counts set bits across both (src/world/gen2/World.lua:1585).
  --
  -- The gate is ONE badge, not the Gen 1 version's four. Violet City is
  -- the second town on Gold and the Zephyr Badge is earned in it, so four
  -- would strand ROXIE somewhere the player has long since left. One
  -- badge puts her there the moment the gym is done -- which is also when
  -- the town goes quiet, which is the joke.
  ----------------------------------------------------------------------
  local function countFlags(flags)
    local n = 0
    for _, has in pairs(flags or {}) do
      if has then n = n + 1 end
    end
    return n
  end

  local function badgeCount(game)
    local player = game and game.save and game.save.player
    if not player then return 0 end
    return countFlags(player.badges) + countFlags(player.kantoBadges)
  end

  ----------------------------------------------------------------------
  -- Placement.
  --
  -- Gold's manifest carries map dimensions but NO per-map object lists
  -- (rom_manifest_gold.json maps entries are group/map/width/height/name
  -- only), so there is nothing to hard-code from here even if hard-coding
  -- were wise. Resolve it live instead: anchor on whatever vanilla NPC
  -- the map has, then take the first neighbouring cell the map itself
  -- calls in-bounds, walkable and unoccupied.
  --
  -- Map:inBounds and Map:isWalkableCell both exist on Gold
  -- (src/world/gen2/Map.lua:41,97), so this half is unchanged from the
  -- Gen 1 version. Occupancy is checked by hand rather than through
  -- Collision.occupied, whose adapter note says it tests targetX/Y
  -- unconditionally as Gen 1 does while Gold's own loops test them only
  -- while moving -- a small behavioural difference, and this is two lines.
  ----------------------------------------------------------------------
  local OFFSETS = {
    { 0, 1 }, { -1, 0 }, { 1, 0 }, { 0, -1 },
    { -1, 1 }, { 1, 1 }, { -1, -1 }, { 1, -1 },
    { 0, 2 }, { -2, 0 }, { 2, 0 }, { 0, -2 },
  }

  local function anchorCell(world)
    for _, npc in ipairs(world.npcs or {}) do
      local def = npc.def
      if def and def.name ~= OBJ_NAME and npc.cellX and npc.cellY then
        return npc.cellX, npc.cellY, tostring(def.name or def.index or "?")
      end
    end
    return nil
  end

  local function occupied(world, x, y)
    for _, npc in ipairs(world.npcs or {}) do
      if npc.cellX == x and npc.cellY == y then return true end
    end
    local p = world.player
    if p and p.cellX == x and p.cellY == y then return true end
    return false
  end

  local function freeCellNear(world, ax, ay)
    local map = world.map
    if not map then return nil end
    for _, off in ipairs(OFFSETS) do
      local x, y = ax + off[1], ay + off[2]
      if map:inBounds(x, y) and map:isWalkableCell(x, y)
         and not occupied(world, x, y) then
        return x, y
      end
    end
    return nil
  end

  ----------------------------------------------------------------------
  -- Spawning.
  --
  -- World:addRuntimeObject appends to self.maps[MAP].objects and that
  -- list lives for the whole run (src/world/gen2/World.lua:7015), exactly
  -- as the Gen 1 one did -- so spawning per map entry would stack a ROXIE
  -- per visit. The guard reads the live object list rather than a Lua
  -- boolean, which would also be wrong across a save load.
  --
  -- Note the table moved: Gen 1 read Game.data.maps, Gold reads the
  -- World's own self.maps.
  ----------------------------------------------------------------------
  -- where she ended up, so the interaction handler can recognise her cell
  local roxieX, roxieY

  local function alreadyThere(world)
    local def = world.maps and world.maps[MAP]
    for _, obj in ipairs(def and def.objects or {}) do
      if obj.name == OBJ_NAME then
        roxieX, roxieY = obj.x, obj.y
        return true
      end
    end
    return false
  end

  local function placeRoxie()
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    if alreadyThere(world) then return nil end   -- nothing worth reporting

    local badges = badgeCount(mod.world.game)
    if badges < BADGE_GATE then
      return ("gate %d/%d badge"):format(badges, BADGE_GATE)
    end

    local ax, ay, anchor = anchorCell(world)
    if not ax then return "no anchor NPC" end

    local x, y = freeCellNear(world, ax, ay)
    if not x then return ("no free cell by %d,%d"):format(ax, ay) end

    local id, err = mod.world:spawnNpc(MAP, {
      name = OBJ_NAME,
      sprite = ROXIE_SPRITE,
      x = x, y = y,
      movement = MOVE_STANDING_DOWN,
    })
    if not id then return "spawn failed: " .. tostring(err) end
    roxieX, roxieY = x, y
    return ("at %d,%d by %s"):format(x, y, anchor)
  end

  ----------------------------------------------------------------------
  -- Talking to her.
  --
  -- This is the part with no Gen 1 equivalent. World:interactBody tries
  -- trainer / boulder / itemball / scriptKey / sign / hidden / std-tile /
  -- field-move in turn and, on no match, emits world.interacted with
  -- kind = "none" and the faced cell's coordinates
  -- (src/world/gen2/World.lua:7273). A mod-spawned object has no
  -- scriptKey, so an A press aimed at ROXIE falls all the way through to
  -- there -- and that is the hook.
  --
  -- Text is then driven with mod.world:queueScript, whose Gen 2 verb
  -- table serves text / warp / setflag / clearflag / start_battle (wild
  -- only). "text" is all this version needs.
  --
  -- TODO/CONFIRM, and it is the whole point of this build: that the
  -- fall-through fires for a mod-spawned NPC on a real Gold boot. Nothing
  -- in this ecosystem has done it yet.
  ----------------------------------------------------------------------
  local ROXIE_LINES = {
    "ROXIE: Finally. A face.",
    "I came all the way to JOHTO for a scene. Know what I found?",
    "Bells. Monks. Somebody's WOOPER asleep in the road.",
    "This town is so quiet I can hear my own hair.",
    "I'm ROXIE. I make noise for a living, and this place is a crime scene.",
    "So I'm starting a band. Right here. Loudest thing JOHTO has ever heard.",
    "Don't wander off. I'm gonna need hands.",
  }

  mod.events:on("world.interacted", function(ev)
    if not ev or ev.kind ~= "none" then return end
    if ev.mapId ~= MAP then return end
    if roxieX == nil or ev.x ~= roxieX or ev.y ~= roxieY then return end

    local rows = {}
    for i, line in ipairs(ROXIE_LINES) do rows[i] = { "text", line } end
    local ok, err = mod.world:queueScript(rows)
    if not ok then report("talk failed\n" .. tostring(err)) end
  end)

  ----------------------------------------------------------------------
  -- Options. Still minimal; the report row is a development aid and goes
  -- once the questline is stable.
  ----------------------------------------------------------------------
  mod.options:define({
    { key = "show_report", type = "toggle",
      label = "Report ROXIE status", default = true },
  })

  ----------------------------------------------------------------------
  -- Map entry.
  ----------------------------------------------------------------------
  local reported = false
  mod.events:on("map.entered", function(ev)
    local ok, err = pcall(function()
      -- payload is { mapId, map, fromMapId, via } -- `map` is the map
      -- OBJECT and `mapId` the string; comparing the wrong one is a
      -- table-vs-string test that never matches and silently never spawns
      if ev and ev.mapId ~= nil and ev.mapId ~= MAP then return end
      local status = placeRoxie()
      if status and not reported and mod.options:get("show_report") == true then
        reported = true
        report("KANTO ROCKS " .. VERSION .. "\nROXIE " .. status)
      end
    end)
    if not ok then mod.log:warn("map.entered failed: %s", tostring(err)) end
  end)

  mod.log:info("kanto_rocks %s loaded (gen 2)", VERSION)
end

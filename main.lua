-- Gold Records -- a Gold quest starring ROXIE.
-- Alpha release. ROXIE's assembled band plays NATIONAL PARK, where PIERS
-- arrives uninvited and challenges the manager for the encore.
--
-- Proven Gold patterns used here:
--   * owned runtime NPC + world.interacted dialogue (Court of Noctowl)
--   * owned trainer carrier + trainer.party substitution (ROXIE/WHITNEY)
--   * mod.save quest state, so loading an earlier save rewinds the quest

local Runtime = require("src.mods.Runtime")
local Happiness = require("src.core.gen2.Happiness")
local Clock = require("src.core.gen2.Clock")

return function(mod)
  local VERSION = "0.6.3"
  local MOD_ID = "gold_records"
  mod.exports.version = VERSION

  local MAP = "VIOLET_CITY"
  local OBJ_NAME = "GR_ROXIE"
  local BASS_MAP = "GOLDENROD_UNDERGROUND"
  local FEEDBACK_NAME = "GR_FEEDBACK"
  local WHITNEY_NAME = "GR_WHITNEY"
  local AUDITION_MAP = "DANCE_THEATER"
  local AUDITION_ROXIE = "GR_AUDITION_ROXIE"
  local GENE_NAME = "GR_GENE"
  local BILLY_NAME = "GR_BILLY"
  local CASEY_NAME = "GR_CASEY"
  local JIGGLY_NAME = "GR_JIGGLYPUFF"
  local RADIO_MAP = "RADIO_TOWER_1F"
  local CAFE_MAP = "OLIVINE_CAFE"
  local DANCE_HOST = "GR_DANCE_HOST"
  local RADIO_HOST = "GR_RADIO_HOST"
  local CAFE_HOST = "GR_CAFE_HOST"
  local VENUE_DANCE_ROXIE = "GR_DANCE_ROXIE"
  local VENUE_RADIO_ROXIE = "GR_RADIO_ROXIE"
  local VENUE_CAFE_ROXIE = "GR_CAFE_ROXIE"
  local VENUE_UNDER_ROXIE = "GR_UNDER_ROXIE"
  local BASEMENT_KING = "GR_BASEMENT_KING"
  local ECRUTEAK_MAP = "ECRUTEAK_CITY"
  local SLEEPING_WOOPER = "GR_SLEEPING_WOOPER"
  local OLIVINE_MAP = "OLIVINE_CITY"
  local BUSKER_SAILOR = "GR_BUSKER_SAILOR"
  local SHOW_MAP = "NATIONAL_PARK"
  local SHOW_ROXIE = "GR_SHOW_ROXIE"
  local SHOW_WHITNEY = "GR_SHOW_WHITNEY"
  local SHOW_CASEY = "GR_SHOW_CASEY"
  local PIERS_NAME = "GR_PIERS"
  local BADGE_GATE = 1
  local SHOW_BADGE_GATE = 4
  local MOVE_STANDING_DOWN = 6
  local MOVE_STANDING_RIGHT = 9
  local MOVE_STANDING_LEFT = 8
  local ROXIE_SPRITE = "SPRITE_GR_ROXIE"
  local PIERS_SPRITE = "SPRITE_GR_PIERS"
  -- Device-tested adjustment from the previous (18,19) placement:
  -- four cells right and seven cells up, facing right.
  local ROXIE_X, ROXIE_Y = 22, 12
  -- South Underground entrance placement test. Warp 2 enters at (3,34);
  -- FEEDBACK waits just to its right, facing the arrival corridor.
  local BASS_X, BASS_Y = 6, 33

  -- Runtime objects do not consume an index, but this reserves Gold Records'
  -- future map-owned object band and documents ownership for other mods.
  mod.exports.owns = {
    maps = {}, trainers = {}, items = {}, sprites = {},
    objects = {
      [MAP] = { OBJ_NAME },
      [BASS_MAP] = {
        FEEDBACK_NAME, WHITNEY_NAME, VENUE_UNDER_ROXIE, BASEMENT_KING,
      },
      [AUDITION_MAP] = {
        AUDITION_ROXIE, GENE_NAME, BILLY_NAME, CASEY_NAME, JIGGLY_NAME,
        DANCE_HOST, VENUE_DANCE_ROXIE,
      },
      [RADIO_MAP] = { RADIO_HOST, VENUE_RADIO_ROXIE },
      [CAFE_MAP] = { CAFE_HOST, VENUE_CAFE_ROXIE },
      [ECRUTEAK_MAP] = { SLEEPING_WOOPER },
      [OLIVINE_MAP] = { BUSKER_SAILOR },
      [SHOW_MAP] = { SHOW_ROXIE, SHOW_WHITNEY, SHOW_CASEY, PIERS_NAME },
      indexBand = { 160, 169 },
    },
    monFields = { "grHeadliner", "grPiersGift" },
  }

  mod.content.sprites:register(ROXIE_SPRITE, {
    id = ROXIE_SPRITE,
    image = mod.path .. "/assets/roxie.png",
    frames = 6,
    walker = true,
    spriteType = "WALKING_SPRITE",
    palette = "PAL_OW_PINK",
    paletteId = 4,
  })

  mod.content.sprites:register(PIERS_SPRITE, {
    id = PIERS_SPRITE,
    image = mod.path .. "/assets/piers.png",
    frames = 6,
    walker = true,
    spriteType = "WALKING_SPRITE",
    palette = "PAL_OW_BROWN",
    paletteId = 3,
  })

  local ROXIE_FRONT_PATH = mod.path .. "/assets/roxie_front.png"
  local PIERS_FRONT_PATH = mod.path .. "/assets/piers_front.png"

  local function report(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    pcall(Runtime.reportError, MOD_ID, ok and msg or tostring(fmt))
  end

  -- Quest beats:
  --   0 not met; 10 Roxie challenge; 11 lost; 20 won; 30 manager
  --   31 Feedback challenge armed; 32 lost; 40 Whitney beaten; 50 recruited
  --   60 drummer audition assigned; 70 Jigglypuff interruption happened
  --   71 candidate selection open; 80 Casey recruited; 81 venue hunt
  --   82 Radio Tower; 83 Olivine Cafe; 84 Underground
  --   85 optional Contest lead; 86 optional Court lead
  --   90 show assigned; 100 Piers arrived; 101 Piers battle armed
  --   102 Piers loss/retry; 110 Piers beaten
  local function beat() return tonumber(mod.save:get("beat", 0)) or 0 end
  local function setBeat(n) mod.save:set("beat", n) end

  -- Optional crossovers are presence checks only. They never read another
  -- mod's state and never make that mod a dependency.
  local crossovers = {
    olivineCafe = false,
    kantoContests = false,
    courtOfNoctowl = false,
    trainerJourney = false,
  }

  local tj
  local function tjInit()
    local handle = mod.find("trainer_journey")
    local api = handle and handle.exports and handle.exports.trainer_journey
    if not (api and api.api_version == 1) then tj = nil; return end
    tj = api
    tj.registerProfession({
      id = "rock_star",
      name = "ROCK STAR",
      owner = MOD_ID,
      summary = "managing a punk band across JOHTO",
      thresholds = { 1, 3, 6, 10 },
      rankNames = { "ROADIE", "OPENER", "HEADLINER", "LEGEND" },
    })
  end

  local function tjAward(stat, points, tag)
    if not tj then return end
    pcall(tj.awardOnce, stat, points, MOD_ID .. ":" .. tag)
  end

  local function tjProfession(points, tag)
    if not tj then return end
    pcall(tj.awardProfessionOnce, "rock_star", points, MOD_ID .. ":" .. tag)
  end

  local function tjEthos(direction, weight, tag)
    if not tj then return end
    local fn = direction == "tradition" and tj.leanTradition or tj.leanInnovation
    pcall(fn, weight, MOD_ID .. ":" .. tag)
  end

  local function tjRank(stat)
    if not tj then return 0 end
    local ok, info = pcall(tj.getStat, stat)
    return ok and type(info) == "table" and tonumber(info.rank) or 0
  end

  mod.events:on("game.ready", function()
    crossovers.olivineCafe = mod.find("olivine_cafe") ~= nil
    crossovers.kantoContests = mod.find("kanto_contests") ~= nil
    crossovers.courtOfNoctowl = mod.find("court_of_noctowl") ~= nil
    crossovers.trainerJourney = mod.find("trainer_journey") ~= nil
    if crossovers.trainerJourney then
      local ok, err = pcall(tjInit)
      if not ok then report("GR TJ INIT\n%s", tostring(err)) end
    end
    -- A disabled crossover must not strand an optional in-progress stop or
    -- mention content which is no longer installed.
    if beat() == 85 and not crossovers.kantoContests then setBeat(83) end
    if beat() == 86 and not crossovers.courtOfNoctowl then setBeat(84) end
    if beat() >= 90 then mod.save:set("basement_armed", false) end
  end)

  local function countFlags(flags)
    local n = 0
    for _, has in pairs(flags or {}) do if has then n = n + 1 end end
    return n
  end

  local function badgeCount(game)
    local player = game and game.save and game.save.player
    if not player then return 0 end
    return countFlags(player.badges) + countFlags(player.kantoBadges)
  end

  --------------------------------------------------------------------------
  -- Native Gold trainer battles. Each owned NPC temporarily rides a proven
  -- vanilla leader record for portrait/music plumbing, while trainer.party
  -- supplies the actual test team. No vanilla party or event flag is changed.
  --------------------------------------------------------------------------
  local function objectNamed(world, mapId, name)
    local def = world and world.maps and world.maps[mapId]
    for _, obj in ipairs(def and def.objects or {}) do
      if obj.name == name then return obj end
    end
    return nil
  end

  local BATTLES = {
    roxie = {
      map = MAP, npc = OBJ_NAME, class = "JANINE", member = "JANINE1",
      tempName = "ROXIE",
      seenKey = "GR_ROXIE_SEEN", winKey = "GR_ROXIE_WIN",
      lossKey = "GR_ROXIE_LOSS",
      party = { { species = "EKANS", level = 10 },
                { species = "KOFFING", level = 12 } },
    },
    whitney = {
      map = BASS_MAP, npc = FEEDBACK_NAME,
      class = "WHITNEY", member = "WHITNEY1",
      seenKey = "GR_FEEDBACK_SEEN", winKey = "GR_FEEDBACK_WIN",
      lossKey = "GR_FEEDBACK_LOSS",
      party = { { species = "CLEFAIRY", level = 20 },
                { species = "SNUBBULL", level = 20 },
                { species = "MILTANK", level = 22 } },
    },
    piers = {
      map = SHOW_MAP, npc = PIERS_NAME,
      class = "KAREN", member = "KAREN1", tempName = "PIERS",
      seenKey = "GR_PIERS_SEEN", winKey = "GR_PIERS_WIN",
      lossKey = "GR_PIERS_LOSS",
      party = { { species = "MURKROW", level = 33 },
                { species = "SNEASEL", level = 33 },
                { species = "WEEZING", level = 34 },
                { species = "CROBAT", level = 34 },
                { species = "HOUNDOOM", level = 35 } },
    },
    basement = {
      map = BASS_MAP, npc = BASEMENT_KING,
      class = "BIKER", member = "KAZU1", tempName = "KING",
      seenKey = "GR_BASEMENT_SEEN", winKey = "GR_BASEMENT_WIN",
      lossKey = "GR_BASEMENT_LOSS",
      party = { { species = "GRIMER", level = 25 },
                { species = "KOFFING", level = 26 },
                { species = "MUK", level = 28 } },
    },
  }

  mod.content.text:register(BATTLES.roxie.seenKey,
    "ROXIE: Let's see\nif you've got any\fvolume. Crank it!")
  mod.content.text:register(BATTLES.roxie.winKey,
    "ROXIE: Now THAT'S\nmore like it!")
  mod.content.text:register(BATTLES.roxie.lossKey,
    "ROXIE: Too quiet.\fCome back when you\nmake some noise.")
  mod.content.text:register(BATTLES.whitney.seenKey,
    "FEEDBACK: GYM\nbattles have rules\fMusic doesn't.\nKeep time!")
  mod.content.text:register(BATTLES.whitney.winKey,
    "WHITNEY: Hey!\fYou never missed\nthe beat!")
  mod.content.text:register(BATTLES.whitney.lossKey,
    "FEEDBACK: You lost\nthe rhythm.\fFind it and\ncome back.")
  mod.content.text:register(BATTLES.piers.seenKey,
    "PIERS: Show me\nwhat you've built.\fNo holding back.")
  mod.content.text:register(BATTLES.piers.winKey,
    "PIERS: Ha!\fNow that's a show.")
  mod.content.text:register(BATTLES.piers.lossKey,
    "PIERS: Good noise.\fNeeds a sharper\nedge.")
  mod.content.text:register(BATTLES.basement.seenKey,
    "KING: Nobody books\nthis room.\fYou earn it!")
  mod.content.text:register(BATTLES.basement.winKey,
    "KING: All right!\fRespect earned!")
  mod.content.text:register(BATTLES.basement.lossKey,
    "KING: Respect the\nbasement.\fTry me again.")

  local activeBattle, pendingBattle

  do
    local ok, err = pcall(function()
      local BattleState = require("src.ui.gen2.BattleState")
      local Assets = require("src.render.Assets")
      BattleState._grOriginals = BattleState._grOriginals or {
        new = BattleState.new,
      }
      local orig = BattleState._grOriginals.new
      BattleState.new = function(game, opts)
        local state = orig(game, opts)
        local frontPath = activeBattle == "piers" and PIERS_FRONT_PATH
                       or activeBattle == "roxie" and ROXIE_FRONT_PATH
                       or nil
        if state and frontPath then
          local loaded, image = pcall(Assets.image, frontPath)
          if loaded and image then
            state.enemyTrainerImage = image
            state.enemyTrainerPath = frontPath
            state.enemyTrainerTrueColor = true
            state.showEnemyTrainer = true
          end
        end
        return state
      end
    end)
    if not ok then report("GR PIERS PIC\n%s", tostring(err)) end
  end

  local function resolveCarrier(def)
    if def.classIx and def.memberIx then return true end
    local td = mod.game and mod.game.data and mod.game.data.gen2Trainers
    local cls = td and td.classes and td.classes[def.class]
    if not (cls and cls.index) then return false, "class " .. def.class end
    for i, row in ipairs(cls.trainers or {}) do
      if row.id == def.member or row.name == def.member then
        def.classIx, def.memberIx = cls.index, i
        def.carrierRow, def.originalName = row, row.name
        return true
      end
    end
    return false, "member " .. def.member
  end

  local function armBattle(key)
    local def = BATTLES[key]
    local world = mod.world:overworld()
    local ok, why = resolveCarrier(def)
    if not ok then report("GR CARRIER\n%s", tostring(why)); return false end
    local obj = objectNamed(world, def.map, def.npc)
    if not obj then return false end
    obj.trainer = {
      class = def.classIx, member = def.memberIx,
      seenText = def.seenKey, winText = def.winKey, lossText = def.lossKey,
    }
    return true
  end

  local function defangBattle(key)
    local def = BATTLES[key]
    local world = mod.world:overworld()
    local obj = objectNamed(world, def.map, def.npc)
    if obj then obj.trainer = nil end
    if def.carrierRow and def.originalName then
      def.carrierRow.name = def.originalName
    end
    if activeBattle == key then activeBattle = nil end
  end

  local function buildParty(rows)
    local Trainers = require("src.world.gen2.Trainers")
    local data = mod.game and mod.game.data
    if not data then return nil end
    local party = Trainers.party(data, { roster = rows })
    if not party or #party == 0 then return nil end
    return party
  end

  mod.hooks:wrap("trainer.party", function(next, class, member, party)
    local base = next()
    local key, def = activeBattle, activeBattle and BATTLES[activeBattle]
    if not def then return base end
    if class ~= def.class and class ~= def.classIx then return base end
    local ok, built = pcall(buildParty, def.party)
    pendingBattle, activeBattle = key, nil
    if not ok or not built then
      report("GR PARTY FAIL\n%s", tostring(built))
      return base
    end
    return built
  end)

  -- Gold's Cherrygrove rival battle uses this one-shot CANLOSE variable.
  local VAR_BATTLETYPE, BATTLETYPE_CANLOSE = 0x03, 1
  mod.events:on("world.trainer_engaged", function(ev)
    local ok, err = pcall(function()
      local npc = ev and ev.npc
      local name = npc and npc.def and npc.def.name
      local key = name == OBJ_NAME and "roxie"
               or name == FEEDBACK_NAME and "whitney"
               or name == PIERS_NAME and "piers"
               or name == BASEMENT_KING and "basement" or nil
      if not key then return end
      local def = BATTLES[key]
      -- Arm the party hook only at the owned NPC engagement seam. Merely
      -- writing obj.trainer is not enough: the player may walk away and fight
      -- another trainer before returning.
      activeBattle = key
      if def.tempName and def.carrierRow then def.carrierRow.name = def.tempName end
      local world = mod.world:overworld()
      if world and world.scriptVars then
        world.scriptVars[VAR_BATTLETYPE] = BATTLETYPE_CANLOSE
      end
    end)
    if not ok then report("GR ENGAGE\n%s", tostring(err)) end
  end)

  local function healParty()
    for _, mon in ipairs((mod.game and mod.game.save and mod.game.save.party) or {}) do
      if mon and mon.stats and mon.stats.hp then
        mon.hp = mon.stats.hp
        mon.status = nil
      end
    end
  end

  mod.events:on("battle.ended", function(ev)
    local ok, err = pcall(function()
      local key = pendingBattle
      if not key then return end
      pendingBattle = nil
      defangBattle(key)
      local won = ev and ev.result == "win"
      if key == "roxie" then
        setBeat(won and 20 or 11)
        if won then
          tjAward("MOXIE", 1, "roxie_battle")
          tjProfession(1, "roxie_battle")
        end
      elseif key == "whitney" then
        setBeat(won and 40 or 32)
      elseif key == "piers" then
        setBeat(won and 110 or 102)
        if won then
          tjAward("MOXIE", 1, "piers_battle")
          tjProfession(1, "piers_battle")
          tjEthos("innovation", 1, "park_show")
        end
      elseif won then
        mod.save:set("basement_respect", true)
        mod.save:set("basement_armed", false)
        tjAward("MOXIE", 1, "basement_king")
        tjProfession(1, "basement_king")
      else
        mod.save:set("basement_loss", true)
        mod.save:set("basement_armed", false)
      end
      if not won then healParty() end
    end)
    if not ok then report("GR BATTLE END\n%s", tostring(err)) end
  end)

  local roxieX, roxieY
  local bassSpawnId

  local function alreadyThere(world)
    local obj = objectNamed(world, MAP, OBJ_NAME)
    if not obj then return false end
    roxieX, roxieY = obj.x, obj.y
    return true
  end

  local function placeRoxie()
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    if alreadyThere(world) then return nil end
    local badges = badgeCount(mod.world.game)
    if badges < BADGE_GATE then return ("gate %d/%d"):format(badges, BADGE_GATE) end
    local id, err = mod.world:spawnNpc(MAP, {
      name = OBJ_NAME, sprite = ROXIE_SPRITE,
      x = ROXIE_X, y = ROXIE_Y, movement = MOVE_STANDING_RIGHT,
    })
    if not id then return "spawn " .. tostring(err) end
    roxieX, roxieY = ROXIE_X, ROXIE_Y
    return ("at %d,%d"):format(ROXIE_X, ROXIE_Y)
  end

  local function placeBassist()
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    -- Expected gate, but report it during private testing. If a conversation
    -- failed to advance, this makes the invisible state visible on device.
    if beat() < 30 then return ("FEEDBACK gate B%d"):format(beat()) end
    local revealed = beat() >= 50
    local name = revealed and WHITNEY_NAME or FEEDBACK_NAME
    if objectNamed(world, BASS_MAP, name) then return nil end
    -- If the other form survived an in-session reload, do not stack them.
    if objectNamed(world, BASS_MAP,
        revealed and FEEDBACK_NAME or WHITNEY_NAME) then return nil end
    -- Prefer the designed cell, but never strand the quest actor in a wall.
    -- The nearby fallbacks keep her in the same visible patch of corridor.
    local x, y = BASS_X, BASS_Y
    local map = world.map
    if map and map.isWalkableCell then
      local candidates = {
        { BASS_X, BASS_Y }, { BASS_X - 1, BASS_Y },
        { BASS_X + 1, BASS_Y }, { BASS_X, BASS_Y - 1 },
        { BASS_X, BASS_Y + 1 },
      }
      x, y = nil, nil
      for _, cell in ipairs(candidates) do
        local cx, cy = cell[1], cell[2]
        local okWalk, walk = pcall(map.isWalkableCell, map, cx, cy)
        local okWarp, warp = pcall(map.warpAtCell, map, cx, cy)
        if okWalk and walk == true and not (okWarp and warp)
            and not world:npcAt(cx, cy) then
          x, y = cx, cy
          break
        end
      end
      if not x then return "no bass cell near 6,33" end
    end
    local id, err = mod.world:spawnNpc(BASS_MAP, {
      name = name,
      sprite = revealed and "SPRITE_WHITNEY" or "SPRITE_KIMONO_GIRL",
      x = x, y = y, movement = MOVE_STANDING_LEFT,
    })
    if not id then return "bass spawn " .. tostring(err) end
    bassSpawnId = id
    return ("%s %d,%d"):format(revealed and "WHITNEY" or "FEEDBACK", x, y)
  end

  local function revealWhitney()
    if not bassSpawnId then
      local world = mod.world:overworld()
      local obj = objectNamed(world, BASS_MAP, FEEDBACK_NAME)
      if obj and obj.runtime and obj.index then
        bassSpawnId = BASS_MAP .. "_obj_" .. obj.index
      end
    end
    if bassSpawnId then
      pcall(function() mod.world:removeNpc(bassSpawnId) end)
      bassSpawnId = nil
    end
    setBeat(50)
    tjAward("APPEAL", 1, "feedback_recruited")
    tjProfession(1, "feedback_recruited")
    local status = placeBassist()
    if status and not status:match("^WHITNEY") then
      report("GR REVEAL\n%s", tostring(status))
    end
  end

  --------------------------------------------------------------------------
  -- Ecruteak drummer audition. Runtime actors are kept off the vanilla map
  -- data and are rebuilt from the quest beat whenever the player enters.
  --------------------------------------------------------------------------
  local auditionSpawnIds = {}
  local AUDITION_ACTORS = {
    { name = AUDITION_ROXIE, sprite = ROXIE_SPRITE, x = 4, y = 11 },
    { name = GENE_NAME, sprite = "SPRITE_ROCKER", x = 2, y = 9 },
    { name = BILLY_NAME, sprite = "SPRITE_SUPER_NERD", x = 5, y = 9 },
    { name = CASEY_NAME, sprite = "SPRITE_LASS", x = 8, y = 9 },
    { name = JIGGLY_NAME, sprite = "SPRITE_JIGGLYPUFF", x = 6, y = 11 },
  }

  local function questFlag(key)
    return mod.save:get(key, false) == true
  end

  local function setQuestFlag(key)
    mod.save:set(key, true)
  end

  local function allQuestFlags(keys)
    for _, key in ipairs(keys) do
      if not questFlag(key) then return false end
    end
    return true
  end

  local function anyQuestFlag(keys)
    for _, key in ipairs(keys) do
      if questFlag(key) then return true end
    end
    return false
  end

  local INTRO_FLAGS = { "gene_intro", "billy_intro", "casey_intro" }
  local CLUE_FLAGS = { "gene_clue", "billy_clue", "casey_clue" }

  local function cellForActor(world, actor)
    local map = world and world.map
    if not (map and map.isWalkableCell) then return actor.x, actor.y end
    local offsets = {
      { 0, 0 }, { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 },
      { -2, 0 }, { 2, 0 }, { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 },
    }
    for _, offset in ipairs(offsets) do
      local x, y = actor.x + offset[1], actor.y + offset[2]
      local okWalk, walk = pcall(map.isWalkableCell, map, x, y)
      local okWarp, warp = pcall(map.warpAtCell, map, x, y)
      if okWalk and walk == true and not (okWarp and warp)
          and not world:npcAt(x, y) then
        return x, y
      end
    end
    return nil, nil
  end

  local function removeAuditionActor(name)
    local id = auditionSpawnIds[name]
    if not id then
      local world = mod.world:overworld()
      local obj = objectNamed(world, AUDITION_MAP, name)
      if obj and obj.runtime and obj.index then
        id = AUDITION_MAP .. "_obj_" .. obj.index
      end
    end
    if id then pcall(function() mod.world:removeNpc(id) end) end
    auditionSpawnIds[name] = nil
  end

  local function placeAudition()
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    local b = beat()
    if b < 60 then return nil end

    local wanted = {}
    if b >= 80 then
      wanted[CASEY_NAME] = true
    else
      wanted[AUDITION_ROXIE] = true
      wanted[GENE_NAME] = true
      wanted[BILLY_NAME] = true
      wanted[CASEY_NAME] = true
      if b >= 70 then wanted[JIGGLY_NAME] = true end
    end

    for _, actor in ipairs(AUDITION_ACTORS) do
      if not wanted[actor.name] then removeAuditionActor(actor.name) end
    end

    local placed = {}
    for _, actor in ipairs(AUDITION_ACTORS) do
      if wanted[actor.name] then
        local existing = objectNamed(world, AUDITION_MAP, actor.name)
        if existing then
          placed[#placed + 1] = ("%s %d,%d"):format(
            actor.name:gsub("^GR_", ""), existing.x, existing.y)
        else
          local x, y = cellForActor(world, actor)
          if not x then return "no cell for " .. actor.name end
          local id, err = mod.world:spawnNpc(AUDITION_MAP, {
            name = actor.name, sprite = actor.sprite,
            x = x, y = y, movement = MOVE_STANDING_DOWN,
          })
          if not id then return "audition spawn " .. tostring(err) end
          auditionSpawnIds[actor.name] = id
          placed[#placed + 1] = ("%s %d,%d"):format(
            actor.name:gsub("^GR_", ""), x, y)
        end
      end
    end
    return table.concat(placed, " ")
  end

  local function finishDrummer()
    setBeat(80)
    tjAward("APPEAL", 1, "casey_recruited")
    tjProfession(1, "casey_recruited")
    removeAuditionActor(AUDITION_ROXIE)
    removeAuditionActor(GENE_NAME)
    removeAuditionActor(BILLY_NAME)
    removeAuditionActor(JIGGLY_NAME)
    local status = placeAudition()
    if status and not status:match("CASEY") then
      report("GR DRUMMER\n%s", tostring(status))
    end
  end

  --------------------------------------------------------------------------
  -- Act II side interactions: the road WOOPER is one-shot, while Olivine's
  -- busker stays after the venue hunt as a seed for the later tour.
  --------------------------------------------------------------------------
  local featureSpawnIds = {}
  local WOOPER_ACTOR = {
    name = SLEEPING_WOOPER, sprite = "SPRITE_MONSTER", x = 23, y = 22,
    movement = MOVE_STANDING_DOWN, label = "WOOPER",
  }
  local BUSKER_ACTOR = {
    name = BUSKER_SAILOR, sprite = "SPRITE_SAILOR", x = 9, y = 22,
    movement = MOVE_STANDING_LEFT, label = "BUSKER",
  }

  local function removeFeatureActor(mapId, actor)
    local id = featureSpawnIds[actor.name]
    if not id then
      local world = mod.world:overworld()
      local obj = objectNamed(world, mapId, actor.name)
      if obj and obj.runtime and obj.index then
        id = mapId .. "_obj_" .. obj.index
      end
    end
    if id then pcall(function() mod.world:removeNpc(id) end) end
    featureSpawnIds[actor.name] = nil
  end

  local function placeFeatureActor(mapId, actor, wanted)
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    if not wanted then
      removeFeatureActor(mapId, actor)
      return nil
    end
    local existing = objectNamed(world, mapId, actor.name)
    if existing then
      return ("%s %d,%d"):format(actor.label, existing.x, existing.y)
    end
    local x, y = cellForActor(world, actor)
    if not x then return "no feature cell for " .. actor.label end
    local id, err = mod.world:spawnNpc(mapId, {
      name = actor.name, sprite = actor.sprite,
      x = x, y = y, movement = actor.movement,
    })
    if not id then return "feature spawn " .. tostring(err) end
    featureSpawnIds[actor.name] = id
    if mod.options:get("show_report") ~= false then
      report("GR FEATURE\n%s %d,%d\nB%d", actor.label, x, y, beat())
    end
    return ("%s %d,%d"):format(actor.label, x, y)
  end

  local function removeWooper()
    removeFeatureActor(ECRUTEAK_MAP, WOOPER_ACTOR)
  end

  local function placeWooper()
    local b = beat()
    return placeFeatureActor(ECRUTEAK_MAP, WOOPER_ACTOR,
      b >= 81 and b <= 86 and not questFlag("wooper_done"))
  end

  local function placeBusker()
    return placeFeatureActor(OLIVINE_MAP, BUSKER_ACTOR, beat() >= 83)
  end

  --------------------------------------------------------------------------
  -- Act II venue hunt. Each stop lives on a vanilla map. Runtime actors are
  -- guarded by name and removed when their beat is no longer current, since
  -- Gold's runtime object list otherwise keeps every spawn for the session.
  --------------------------------------------------------------------------
  local venueSpawnIds = {}
  local VENUE_ACTORS = {
    [AUDITION_MAP] = {
      { name = DANCE_HOST, sprite = "SPRITE_KIMONO_GIRL", x = 8, y = 12,
        movement = MOVE_STANDING_DOWN, label = "KIMONO" },
      { name = VENUE_DANCE_ROXIE, sprite = ROXIE_SPRITE, x = 8, y = 12,
        movement = MOVE_STANDING_RIGHT, label = "ROXIE" },
    },
    [RADIO_MAP] = {
      { name = RADIO_HOST, sprite = "SPRITE_RECEPTIONIST", x = 6, y = 4,
        movement = MOVE_STANDING_DOWN, label = "RADIO" },
      { name = VENUE_RADIO_ROXIE, sprite = ROXIE_SPRITE, x = 6, y = 4,
        movement = MOVE_STANDING_LEFT, label = "ROXIE" },
    },
    [CAFE_MAP] = {
      { name = CAFE_HOST, sprite = "SPRITE_FISHER", x = 4, y = 6,
        movement = MOVE_STANDING_DOWN, label = "CAFE" },
      { name = VENUE_CAFE_ROXIE, sprite = ROXIE_SPRITE, x = 4, y = 6,
        movement = MOVE_STANDING_LEFT, label = "ROXIE" },
    },
    [BASS_MAP] = {
      { name = BASEMENT_KING, sprite = "SPRITE_BIKER", x = 3, y = 31,
        movement = MOVE_STANDING_DOWN, label = "KING" },
      { name = VENUE_UNDER_ROXIE, sprite = ROXIE_SPRITE,
        x = BASS_X, y = BASS_Y, movement = MOVE_STANDING_RIGHT,
        label = "ROXIE" },
    },
  }

  local function venueActive(mapId, b)
    if mapId == AUDITION_MAP then return b >= 81 and b <= 86 end
    if mapId == RADIO_MAP then return b == 82 or b == 85 end
    if mapId == CAFE_MAP then return b == 83 or b == 86 end
    if mapId == BASS_MAP then return b == 84 end
    return false
  end

  local function removeVenueActor(mapId, name)
    local id = venueSpawnIds[name]
    if not id then
      local world = mod.world:overworld()
      local obj = objectNamed(world, mapId, name)
      if obj and obj.runtime and obj.index then
        id = mapId .. "_obj_" .. obj.index
      end
    end
    if id then pcall(function() mod.world:removeNpc(id) end) end
    venueSpawnIds[name] = nil
  end

  local function placeVenue(mapId)
    local actors = VENUE_ACTORS[mapId]
    if not actors then return nil end
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    local b = beat()
    if not venueActive(mapId, b) then
      for _, actor in ipairs(actors) do
        removeVenueActor(mapId, actor.name)
      end
      return nil
    end

    local placed = {}
    for _, actor in ipairs(actors) do
      local existing = objectNamed(world, mapId, actor.name)
      if existing then
        placed[#placed + 1] = ("%s %d,%d"):format(
          actor.label, existing.x, existing.y)
      else
        local x, y = cellForActor(world, actor)
        if not x then return "no venue cell for " .. actor.label end
        local id, err = mod.world:spawnNpc(mapId, {
          name = actor.name, sprite = actor.sprite,
          x = x, y = y, movement = actor.movement,
        })
        if not id then return "venue spawn " .. tostring(err) end
        venueSpawnIds[actor.name] = id
        placed[#placed + 1] = ("%s %d,%d"):format(actor.label, x, y)
        if mod.options:get("show_report") ~= false then
          report("GR VENUE\n%s %d,%d\nB%d", actor.label, x, y, b)
        end
      end
    end
    return table.concat(placed, " ")
  end

  local function advanceVenue(mapId, nextBeat)
    setBeat(nextBeat)
    if nextBeat >= 90 then
      mod.save:set("basement_armed", false)
      removeWooper()
    end
    local status = placeVenue(mapId)
    if status then report("GR VENUE NEXT\n%s", tostring(status)) end
  end

  --------------------------------------------------------------------------
  -- NATIONAL PARK show. The three band actors arrive at beat 90; PIERS is
  -- added only after the opening set, so his interruption is a real arrival.
  --------------------------------------------------------------------------
  local showSpawnIds = {}
  local SHOW_ACTORS = {
    { name = SHOW_ROXIE, sprite = ROXIE_SPRITE, x = 10, y = 44,
      label = "ROXIE" },
    { name = SHOW_WHITNEY, sprite = "SPRITE_WHITNEY", x = 12, y = 44,
      label = "WHITNEY" },
    { name = SHOW_CASEY, sprite = "SPRITE_LASS", x = 15, y = 44,
      label = "CASEY" },
    { name = PIERS_NAME, sprite = PIERS_SPRITE, x = 12, y = 42,
      label = "PIERS" },
  }

  local function removeShowActor(name)
    local id = showSpawnIds[name]
    if not id then
      local world = mod.world:overworld()
      local obj = objectNamed(world, SHOW_MAP, name)
      if obj and obj.runtime and obj.index then
        id = SHOW_MAP .. "_obj_" .. obj.index
      end
    end
    if id then pcall(function() mod.world:removeNpc(id) end) end
    showSpawnIds[name] = nil
  end

  local function clearShowActors()
    for _, actor in ipairs(SHOW_ACTORS) do removeShowActor(actor.name) end
  end

  local function placeShow()
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    local b = beat()
    if b < 90 then
      clearShowActors()
      return nil
    end
    local badges = badgeCount(mod.world.game)
    if badges < SHOW_BADGE_GATE then
      clearShowActors()
      return ("SHOW gate %d/%d"):format(badges, SHOW_BADGE_GATE)
    end

    local wanted = {
      [SHOW_ROXIE] = true, [SHOW_WHITNEY] = true, [SHOW_CASEY] = true,
    }
    if b >= 100 then wanted[PIERS_NAME] = true end
    for _, actor in ipairs(SHOW_ACTORS) do
      if not wanted[actor.name] then removeShowActor(actor.name) end
    end

    local placed = {}
    for _, actor in ipairs(SHOW_ACTORS) do
      if wanted[actor.name] then
        local existing = objectNamed(world, SHOW_MAP, actor.name)
        if existing then
          placed[#placed + 1] = ("%s %d,%d"):format(
            actor.label, existing.x, existing.y)
        else
          local x, y = cellForActor(world, actor)
          if not x then return "no show cell for " .. actor.label end
          local id, err = mod.world:spawnNpc(SHOW_MAP, {
            name = actor.name, sprite = actor.sprite,
            x = x, y = y, movement = MOVE_STANDING_DOWN,
          })
          if not id then return "show spawn " .. tostring(err) end
          showSpawnIds[actor.name] = id
          placed[#placed + 1] = ("%s %d,%d"):format(actor.label, x, y)
          if mod.options:get("show_report") ~= false then
            report("GR SHOW\n%s %d,%d\nB%d", actor.label, x, y, b)
          end
        end
      end
    end
    return table.concat(placed, " ")
  end

  --------------------------------------------------------------------------
  -- Dialogue. Gold has no mod-facing choice box, so Roxie's manager offer
  -- becomes an in-character fait accompli.
  --------------------------------------------------------------------------
  local INTRO = {
    "ROXIE: Listen to\nthis place...",
    "Bells. Wind.\fSomebody snoring\nby the road.",
    "VIOLET CITY is\nway too quiet.",
    "I'll shake it till\nthe roof tiles\frattle.",
    "But first, I need\nto know if you can\fkeep up.",
    "C'mon! Show me\nhow much noise you\fcan make!",
  }

  local RETRY = {
    "ROXIE: Still too\nquiet.",
    "Catch your breath.\fThen turn it up\nand try again!",
  }

  local MANAGER = {
    "ROXIE: Okay...\fYou hit harder\nthan a bass drum.",
    "I've got the sound\fYou've got local\ncredentials.",
    "How about managing\nme?",
    "Yeah. That works.\fYou're hired.",
    "First job: find me\na bassist.",
    "They call the\nbassist FEEDBACK.",
    "Plays somewhere in\nGOLDENROD's\fUNDERGROUND.",
    "Problem is, they\nonly battle folks\fwith 3 BADGES.",
    "I'm here to play\nshows, not chase\fGYM badges.",
    "You get us through\nthe door.\fI'll handle the\nvolume.",
  }

  local OBJECTIVE = {
    "ROXIE: FEEDBACK.\fGOLDENROD\nUNDERGROUND.",
    "Great bassist.\fOnly faces people\nwith 3 BADGES.",
    "You get us in.\fI'll make sure\nwe're remembered.",
  }

  local ROXIE_RECRUITED = {
    "ROXIE: WHITNEY?\fThe GYM LEADER is\nFEEDBACK?",
    "Heh. I like her\nalready.",
    "But she gets one\nband-name idea.\fOne.",
    "Now we need drums.",
    "Open audition.\fECRUTEAK's DANCE\nTHEATER.",
    "Three candidates.\fFind who keeps\ntime.",
  }

  local DRUM_OBJECTIVE = {
    "ROXIE: Auditions.\fECRUTEAK's DANCE\nTHEATER.",
    "Talk to all three.\fThen report to me.",
  }

  local DRUMMER_FOUND = {
    "ROXIE: CASEY keeps\ntime in her sleep.",
    "Our drummer. Done.\fNext: spread word.",
  }

  local VENUE_START = {
    "ROXIE: CASEY keeps\ntime in her sleep.",
    "Our drummer. Done.",
    "Now we need a\nplace to play.",
    "DANCE THEATER.\fThey let us\naudition there.",
    "That means they'll\nbook us. Probably.",
    "Meet me there.",
  }

  local VENUE_OBJECTIVES = {
    [81] = { "ROXIE: First stop.\fECRUTEAK's DANCE\nTHEATER." },
    [82] = { "ROXIE: Next stop.\fGOLDENROD RADIO\nTOWER." },
    [85] = { "ROXIE: RADIO\nTOWER.", "They made one more\ncall." },
    [83] = { "ROXIE: Next stop.\fOLIVINE CAFE." },
    [86] = { "ROXIE: OLIVINE.\fOne more offer." },
    [84] = { "ROXIE: Obvious\nanswer.", "GOLDENROD\nUNDERGROUND." },
  }

  local DANCE_REFUSAL = {
    "KIMONO GIRL:\nYou auditioned",
    "here.",
    "That did not make\nit yours.",
    "Our stage is for\nour dances.",
    "ROXIE: Polite.\fThat almost hurts.",
    "RADIO TOWER next.\fThey need music.",
    "KIMONO GIRL:\nOne consolation.",
    "Show us grace.\fChoose a partner.",
  }

  local DANCE_DELIGHT = {
    "KIMONO GIRL:\nBeautiful!",
    "That one knows\nhow to move.",
    "ROXIE: Graceful.\fStill loud enough.",
  }

  local DANCE_POLITE = {
    "KIMONO GIRL:\nAn unusual dance.",
    "Very... modern.",
    "ROXIE: That means\nthey liked it.",
  }

  local DANCE_CANCEL = {
    "KIMONO GIRL:\nAnother time.",
    "ROXIE: RADIO\nTOWER next.",
  }

  local DANCE_REPEAT = {
    "KIMONO GIRL:\nShow us grace.",
  }

  local RADIO_REFUSAL = {
    "STAFF: We\nbroadcast.",
    "We do not host.",
    "ROXIE: You have a\nwhole lobby!",
    "STAFF: We can\noffer a spot on",
    "the radio.",
    "After you have a\nvenue.",
    "ROXIE: Useful.\fAlso backwards.",
  }

  local CONTEST_REFUSAL = {
    "STAFF: CONTEST\nHALL called back.",
    "A contest is a\nperformance.",
    "Your gig is a\nriot.",
    "ROXIE: Sounds like\na compliment.",
    "OLIVINE CAFE next.",
  }

  local CAFE_REFUSAL = {
    "OWNER: Forty\nseats.",
    "People come for\nthe quiet.",
    "ROXIE: Then they\nneed better taste.",
    "OWNER: And we\nneed our tables.",
    "ROXIE: Fine.\fUNDERGROUND next.",
  }

  local NONNOS_REFUSAL = {
    "CHEF: NONNO'S has\nopening night.",
    "Punk at fine\ndining?",
    "ROXIE: Dinner\nneeds more volume.",
    "CHEF: Absolutely\nnot.",
  }

  local COURT_OFFER = {
    "OWNER: One more\ncall.",
    "That NOCTOWL group\nfound you a room.",
    "Strings attached.",
    "ROXIE: Then it's\nnot our stage.",
    "We make our own.\fUNDERGROUND next.",
  }

  local UNDERGROUND_REFUSAL = {
    "WHITNEY: No way!\fNot down here.",
    "ROXIE: This is the\nobvious place.",
    "WHITNEY: If I play\nhere as myself...",
    "Everybody knows\nFEEDBACK is me.",
    "ROXIE: So your\nsecret costs gigs.",
    "WHITNEY: Sorry.",
    "ROXIE: Fine.\fNATIONAL PARK.",
    "Nobody owns it.\fNobody can say no.",
    "Bring 4 BADGES.\fThen we play.",
  }

  local KING_INTRO = {
    "KING: Hold it.\fNobody books this\nroom.",
    "You earn it.",
    "Beat me and the\nbasement respects",
    "your noise.",
    "ROXIE: Finally.\fA booking policy I\nunderstand.",
  }

  local KING_RETRY = {
    "KING: Back for\nrespect?",
    "Good. Earn it.",
  }

  local KING_RESPECT = {
    "KING: Your band\nearned respect.",
    "ROXIE: One good\nreview!",
    "WHITNEY: Still no\nshow down here.",
  }

  local BUSK_PERFORMANCE = {
    "SAILOR: Play us\nsomething loud!",
    "ROXIE strikes the\nfirst chord.",
    "The whole street\nkeeps the beat.",
  }

  local BUSK_PAID = {
    "SAILOR: Worth\nevery coin!",
    "You earned $300.",
  }

  local BUSK_DAILY = {
    "SAILOR: Great set!",
    "Come back tomorrow\nfor another.",
  }

  local WOOPER_WAKE = {
    "It's the WOOPER.\nIt was asleep.",
    "It is no longer\nasleep.",
  }

  local SHOW_OBJECTIVE = {
    "ROXIE: First show.\fNATIONAL PARK.",
    "Bring 4 BADGES.\fThen bring noise.",
  }

  local PIERS_BEAT_VIOLET = {
    "ROXIE: PIERS tried\nto steal our show.",
    "He got an encore.\fJust not his.",
  }

  local FEEDBACK_LOCKED = {
    "FEEDBACK:\nYou found me.",
    "I only audition\nfor trainers with\f3 BADGES.",
    "No shortcuts.\fCome back when you\ncan keep up.",
  }

  local FEEDBACK_INTRO = {
    "FEEDBACK:\nYou found me.",
    "Three badges. Good\fYou beat the GYM\nhere too, huh?",
    "Then you know I\ndon't go easy.",
    "GYM battles have\nrules.\fMusic doesn't.",
    "Let's see if you\ncan keep time.",
  }

  local FEEDBACK_RETRY = {
    "FEEDBACK: You lost\nthe rhythm.",
    "Catch it this time\fReady for another\nset?",
  }

  local WHITNEY_REVEAL = {
    "WHITNEY: Okay,\nokay! You got me!",
    "FEEDBACK is just\nmy name down here.",
    "Borrowed kimono.\fCheap wig.",
    "GYM regulars walk\nright past me.",
    "Battling is public\fThe bass is mine.",
    "ROXIE sounds wild.\fI'll play one set.",
    "One show. One\nencore.\fDon't tell my\ntrainers.",
    "And I get one band\nname suggestion!",
  }

  local WHITNEY_JOINED = {
    "WHITNEY: One show,\none encore.",
    "And I'm still\nnaming the band!",
  }

  local AUDITION_START = {
    "ROXIE: Welcome to\nthe drum audition.",
    "Three candidates.\fHear each one out.",
    "Then come back\nand count us in.",
  }

  local AUDITION_WAIT = {
    "ROXIE: Talk to all\nthree candidates.",
    "I want a drummer,\nnot a guess.",
  }

  local AUDITION_EVENT = {
    "ROXIE: Heard all\nthree.\fLet's start the\naudition.",
    "GENE: ONE! TWO!\nTHREE! CRASH!",
    "BILLY: One, two,\nthree, four, five.",
    "CASEY: E-LEC-\nTA-BUZZ!",
    "A pink singer\nhops onstage.",
    "JIGGLYPUFF:\nJiggly...",
    "The song drifts\noff...",
    "Everyone falls\nasleep.",
    "When you wake,\fone beat is still\ngoing.",
    "ROXIE: Four taps.\fFind who kept\ntime.",
  }

  local INVESTIGATE = {
    "ROXIE: Get clues.\fAsk all three.",
    "One of them kept\nfour steady beats.",
  }

  local PICK_DRUMMER = {
    "ROXIE: Got clues?\fOne drummer.",
    "Stand before your\npick and talk.",
  }

  local CANDIDATE_DIALOGUE = {
    [GENE_NAME] = {
      intro = {
        "GENE: Loud wins.",
        "I count in threes.\fHits harder.",
      },
      repeatIntro = { "GENE: Three beats.\fAll loud." },
      clue = {
        "GENE: My beat was\nONE-TWO-THREE.",
        "Four taps?\fWasn't me.",
      },
      wrong = {
        "GENE: You pick me?\fONE! TWO! THREE!",
        "ROXIE: Only three.\fWe heard four.",
      },
    },
    [BILLY_NAME] = {
      intro = {
        "BILLY: Five-four.",
        "Complex is better.",
      },
      repeatIntro = { "BILLY: Five-four.\fCount carefully." },
      clue = {
        "BILLY: I played\nfive-four.",
        "Five taps per bar.\fNot four.",
      },
      wrong = {
        "BILLY: Pick me?\fCount to five!",
        "ROXIE: That's five\nWe heard four.",
      },
    },
    [CASEY_NAME] = {
      intro = {
        "CASEY: Uh, hi.\fI know one rhythm.",
        "E-LEC-TA-BUZZ!\fIt's a ball chant.",
      },
      repeatIntro = { "CASEY: E-LEC-\nTA-BUZZ!" },
      clue = {
        "CASEY: I dreamed\nof baseball.",
        "E-LEC-TA-BUZZ!\fFour beats per\nchant.",
      },
      right = {
        "CASEY: Pick me?\fE-LEC-TA-BUZZ!",
        "ROXIE: Four beats.\fEvery single time.",
        "You kept the beat\nin your sleep.",
        "You're on drums.",
        "CASEY: For real?\fI get to write an\nELECTABUZZ song!",
      },
      joined = {
        "CASEY: I'm in the\nband!",
        "Wait till you hear\nthe BUZZ song!",
      },
    },
  }

  local SHOW_OPENING = {
    "ROXIE: Manager's\nhere.",
    "WHITNEY: Crowd's\nready!",
    "CASEY: Count us!",
    "One! Two! Three!\fFour!",
    "The band hits\nthe first song.",
    "A voice cuts in\nfrom the path.",
    "PIERS: Not bad.",
    "Mind if I crash\nthe encore?",
    "ROXIE: Who asked\nyou?",
    "PIERS: Nobody.\fThat's the fun.",
  }

  local PIERS_INTRO = {
    "PIERS: Finally.",
    "Something in JOHTO\nworth crashing.",
    "You lot got nerve.\fAnd volume.",
    "ROXIE: We have a\nheadliner already.",
    "PIERS: Yeah?\fLet's see who gets\nthe encore.",
    "No hard feelings.\fI wanna hear your\nbest.",
  }

  local PIERS_INTRO_FAME = {
    "PIERS: Finally.",
    "Heard you from\nthree towns over.",
    "Had to come see\nfor myself.",
    "You lot got nerve.\fAnd volume.",
    "ROXIE: We have a\nheadliner already.",
    "PIERS: Yeah?\fLet's see who gets\nthe encore.",
    "No hard feelings.\fI wanna hear your\nbest.",
  }

  local PIERS_RETRY = {
    "PIERS: Still game?\fGood.",
    "Catch your breath.\fThen bring it.",
  }

  local PIERS_BEAT = {
    "PIERS: You earned\nthe stage.",
    "Came to crash it.\fYou made me stay.",
    "That was a proper\nshow.",
  }

  local function facePlayer(mapId, name)
    local here = mod.world:current()
    local opposite = { up = "down", down = "up", left = "right", right = "left" }
    local want = here and here.facing and opposite[here.facing]
    local npc = mod.world:npc(mapId, name)
    if npc and want then pcall(npc.face, npc, want) end
  end

  local function say(pages, onDone)
    local ok, err = mod.world:queueScript({
      { "text", table.concat(pages, "\f") },
    }, {
      onDone = function()
        if not onDone then return end
        local done, why = pcall(onDone)
        if not done then report("GR TALK STATE\n%s", tostring(why)) end
      end,
    })
    if not ok then report("GR TALK FAIL\n%s", tostring(err)) end
  end

  local DANCERS = {
    BELLOSSOM = true, EEVEE = true,
    VAPOREON = true, JOLTEON = true, FLAREON = true,
    ESPEON = true, UMBREON = true,
    POLIWAG = true, POLIWHIRL = true, POLIWRATH = true, POLITOED = true,
    HITMONTOP = true,
  }

  local function finishDanceShow(pages, advance, graceful)
    say(pages, advance and function()
      tjAward("HEART", 1, "dance_showcase")
      tjProfession(1, "dance_showcase")
      if graceful then tjEthos("tradition", 1, "dance_showcase") end
      advanceVenue(AUDITION_MAP, 82)
    end or nil)
  end

  local function openDanceShow(advance)
    local ok, err = pcall(function()
      mod.ui.push(mod.game, "Gen2PartyMenu", {
        prompt = "choose",
        onChoose = function(_index, mon)
          mod.game.stack:pop()
          local species = mon and mon.species
          if species and DANCERS[species] then
            Happiness.change(mon, "GYMBATTLE")
            finishDanceShow(DANCE_DELIGHT, advance, true)
          else
            finishDanceShow(DANCE_POLITE, advance, false)
          end
        end,
        onCancel = function()
          mod.game.stack:pop()
          finishDanceShow(DANCE_CANCEL, advance, false)
        end,
      })
    end)
    if not ok then
      report("GR PARTY PICK\n%s", tostring(err))
      finishDanceShow(DANCE_CANCEL, advance, false)
    end
  end

  local function talkBasementKing()
    facePlayer(BASS_MAP, BASEMENT_KING)
    if questFlag("basement_respect") then return say(KING_RESPECT) end
    local pages
    if questFlag("basement_loss") then
      pages = KING_RETRY
    elseif tjRank("MOXIE") >= 2 then
      pages = { "KING: I heard\nabout you.", "You still earn\nthis room." }
      for _, p in ipairs(KING_INTRO) do pages[#pages + 1] = p end
    else
      pages = KING_INTRO
    end
    say(pages, function()
      mod.save:set("basement_armed", true)
      armBattle("basement")
    end)
  end

  local function buskDay()
    local save = mod.game and mod.game.save
    return Clock.weekday(save)
  end

  local function talkBusker()
    facePlayer(OLIVINE_MAP, BUSKER_SAILOR)
    local day = buskDay()
    local state = mod.save:get("busk", nil)
    if type(state) == "table" and state.done and state.day == day then
      return say(BUSK_DAILY)
    end
    say(BUSK_PERFORMANCE, function()
      local world = mod.world:overworld()
      if not world then return report("GR BUSK\nno overworld") end
      local money = world:money(0)
      world:setMoney(0, math.max(0, math.min(999999, money + 300)))
      local save = mod.game and mod.game.save
      Happiness.changeParty(save and save.party or {}, "GYMBATTLE")
      local firstBusk = not mod.save:get("busk", nil)
      mod.save:set("busk", { day = day, done = true })
      if firstBusk then
        tjAward("APPEAL", 1, "first_busk")
        tjProfession(1, "first_busk")
      end
      say(BUSK_PAID)
    end)
  end

  local function talkWooper()
    facePlayer(ECRUTEAK_MAP, SLEEPING_WOOPER)
    local ok, err = mod.world:queueScript({
      { "text", table.concat(WOOPER_WAKE, "\f") },
      { "start_battle", "wild", "WOOPER", 18 },
    }, {
      onDone = function(completed)
        if not completed then
          return report("GR WOOPER\nbattle did not run")
        end
        setQuestFlag("wooper_done")
        removeWooper()
      end,
    })
    if not ok then report("GR WOOPER\n%s", tostring(err)) end
  end

  local function talkVenueRoxie(mapId, name)
    facePlayer(mapId, name)
    local pages = VENUE_OBJECTIVES[beat()]
    if pages then say(pages) end
  end

  local function talkVenueHost(mapId, name)
    facePlayer(mapId, name)
    local b = beat()
    if mapId == AUDITION_MAP and b == 81 then
      return say(DANCE_REFUSAL, function() openDanceShow(true) end)
    end
    if mapId == AUDITION_MAP and b >= 82 and b <= 86 then
      local warmth = tjRank("HEART") >= 2
        and { "KIMONO GIRL:\nWelcome back.", "Show us grace." }
        or DANCE_REPEAT
      return say(warmth, function() openDanceShow(false) end)
    end
    if mapId == RADIO_MAP and b == 82 then
      return say(RADIO_REFUSAL, function()
        advanceVenue(mapId, crossovers.kantoContests and 85 or 83)
      end)
    end
    if mapId == RADIO_MAP and b == 85 then
      return say(CONTEST_REFUSAL, function() advanceVenue(mapId, 83) end)
    end
    if mapId == CAFE_MAP and b == 83 then
      local pages = crossovers.olivineCafe and NONNOS_REFUSAL or CAFE_REFUSAL
      return say(pages, function()
        advanceVenue(mapId, crossovers.courtOfNoctowl and 86 or 84)
      end)
    end
    if mapId == CAFE_MAP and b == 86 then
      return say(COURT_OFFER, function() advanceVenue(mapId, 84) end)
    end
  end

  local function talkRoxie()
    facePlayer(MAP, OBJ_NAME)
    local b = beat()
    if b == 0 then
      local pages = {}
      if tjRank("APPEAL") >= 2 then
        pages[#pages + 1] = "ROXIE: You're the\none they talk\fabout, right?"
      end
      for _, p in ipairs(INTRO) do pages[#pages + 1] = p end
      say(pages, function()
        setBeat(10)
        armBattle("roxie")
      end)
    elseif b == 10 then
      -- Reload-safe: restore the runtime trainer arm if it disappeared.
      say({ "ROXIE: Ready?\fThen turn it UP!" }, function()
        armBattle("roxie")
      end)
    elseif b == 11 then
      say(RETRY, function()
        setBeat(10)
        armBattle("roxie")
      end)
    elseif b == 20 then
      say(MANAGER, function() setBeat(30) end)
    elseif b < 50 then
      say(OBJECTIVE)
    elseif b == 50 then
      say(ROXIE_RECRUITED, function() setBeat(60) end)
    elseif b < 80 then
      say(DRUM_OBJECTIVE)
    elseif b == 80 then
      say(VENUE_START, function() setBeat(81) end)
    elseif b < 90 then
      say(VENUE_OBJECTIVES[b] or VENUE_OBJECTIVES[81])
    elseif b < 110 then
      say(SHOW_OBJECTIVE)
    else
      say(PIERS_BEAT_VIOLET)
    end
  end

  local function talkBassist(revealed)
    facePlayer(BASS_MAP, revealed and WHITNEY_NAME or FEEDBACK_NAME)
    local b = beat()
    if b == 84 then
      return say(UNDERGROUND_REFUSAL, function()
        advanceVenue(BASS_MAP, 90)
      end)
    end
    if revealed or b >= 50 then return say(WHITNEY_JOINED) end
    if b == 40 then return say(WHITNEY_REVEAL, revealWhitney) end
    if badgeCount(mod.world.game) < 3 then return say(FEEDBACK_LOCKED) end
    if b == 32 then
      return say(FEEDBACK_RETRY, function()
        setBeat(31)
        armBattle("whitney")
      end)
    end
    if b == 31 then
      return say({ "FEEDBACK: Ready?\fThen count us in." }, function()
        armBattle("whitney")
      end)
    end
    say(FEEDBACK_INTRO, function()
      setBeat(31)
      armBattle("whitney")
    end)
  end

  local function talkAuditionRoxie()
    facePlayer(AUDITION_MAP, AUDITION_ROXIE)
    local b = beat()
    if b == 60 then
      if not allQuestFlags(INTRO_FLAGS) then
        return say(anyQuestFlag(INTRO_FLAGS) and AUDITION_WAIT or AUDITION_START)
      end
      return say(AUDITION_EVENT, function()
        setBeat(70)
        local status = placeAudition()
        if status and not status:match("JIGGLYPUFF") then
          report("GR JIGGLY\n%s", tostring(status))
        end
      end)
    end
    if b == 70 then
      if not allQuestFlags(CLUE_FLAGS) then return say(INVESTIGATE) end
      return say(PICK_DRUMMER, function() setBeat(71) end)
    end
    if b == 71 then return say(PICK_DRUMMER) end
    say(DRUMMER_FOUND)
  end

  local function talkCandidate(name)
    facePlayer(AUDITION_MAP, name)
    local data = CANDIDATE_DIALOGUE[name]
    if not data then return end
    local b = beat()
    if b >= 80 then
      if name == CASEY_NAME then say(data.joined) end
      return
    end
    if b == 60 then
      local key = name == GENE_NAME and "gene_intro"
               or name == BILLY_NAME and "billy_intro" or "casey_intro"
      if questFlag(key) then return say(data.repeatIntro) end
      return say(data.intro, function() setQuestFlag(key) end)
    end
    if b == 70 then
      local key = name == GENE_NAME and "gene_clue"
               or name == BILLY_NAME and "billy_clue" or "casey_clue"
      if questFlag(key) then return say(data.clue) end
      return say(data.clue, function() setQuestFlag(key) end)
    end
    if b == 71 then
      if name == CASEY_NAME then return say(data.right, finishDrummer) end
      return say(data.wrong)
    end
  end

  local function talkJigglypuff()
    facePlayer(AUDITION_MAP, JIGGLY_NAME)
    say({
      "JIGGLYPUFF: PUFF!\fNobody applauded.",
      "Those face marks?\fPure coincidence.",
    })
  end

  local function talkShowRoxie()
    facePlayer(SHOW_MAP, SHOW_ROXIE)
    local b = beat()
    if b == 90 then
      return say(SHOW_OPENING, function()
        setBeat(100)
        tjAward("APPEAL", 1, "park_show")
        tjProfession(1, "park_show")
        local status = placeShow()
        if status and not status:match("PIERS") then
          report("GR PIERS ARRIVE\n%s", tostring(status))
        end
      end)
    end
    if b == 102 then
      return say({ "ROXIE: Breathe.\fThen take it back." })
    end
    if b >= 110 then return say({ "ROXIE: Our show.\fOur encore." }) end
    say({ "ROXIE: PIERS wants\nour encore." })
  end

  local function talkShowMember(name)
    facePlayer(SHOW_MAP, name)
    local b = beat()
    if name == SHOW_WHITNEY then
      if b == 90 then
        return say({ "WHITNEY: A real\ncrowd!", "Don't tell my\ntrainers." })
      elseif b >= 110 then
        return say({ "WHITNEY: We kept\nthe encore!" })
      end
      return say({ "WHITNEY: He wants\nour encore!" })
    end
    if b == 90 then return say({ "CASEY: Four beats.\fNo speeding up." }) end
    if b >= 110 then
      return say({ "CASEY: E-LEC-\nTA-BUZZ!", "We held the beat!" })
    end
    say({ "CASEY: He won't\ncount us out!" })
  end

  local function talkPiers()
    facePlayer(SHOW_MAP, PIERS_NAME)
    local b = beat()
    if b == 100 then
      local intro = tjRank("APPEAL") >= 3 and PIERS_INTRO_FAME or PIERS_INTRO
      return say(intro, function()
        setBeat(101)
        armBattle("piers")
      end)
    end
    if b == 101 then
      return say({ "PIERS: Ready?\fWake the park." }, function()
        armBattle("piers")
      end)
    end
    if b == 102 then
      return say(PIERS_RETRY, function()
        setBeat(101)
        armBattle("piers")
      end)
    end
    say(PIERS_BEAT)
  end

  mod.events:on("world.interacted", function(ev)
    local ok, err = pcall(function()
      if not ev or ev.kind ~= "none" then return end
      local world = mod.world:overworld()
      if ev.mapId == MAP then
        local obj = objectNamed(world, MAP, OBJ_NAME)
        if obj and obj.x == ev.x and obj.y == ev.y then talkRoxie() end
      elseif ev.mapId == BASS_MAP then
        local feedback = objectNamed(world, BASS_MAP, FEEDBACK_NAME)
        local whitney = objectNamed(world, BASS_MAP, WHITNEY_NAME)
        local roxie = objectNamed(world, BASS_MAP, VENUE_UNDER_ROXIE)
        local king = objectNamed(world, BASS_MAP, BASEMENT_KING)
        if feedback and feedback.x == ev.x and feedback.y == ev.y then
          talkBassist(false)
        elseif whitney and whitney.x == ev.x and whitney.y == ev.y then
          talkBassist(true)
        elseif king and king.x == ev.x and king.y == ev.y then
          talkBasementKing()
        elseif roxie and roxie.x == ev.x and roxie.y == ev.y then
          talkVenueRoxie(BASS_MAP, VENUE_UNDER_ROXIE)
        end
      elseif ev.mapId == AUDITION_MAP then
        for _, name in ipairs({
          DANCE_HOST, VENUE_DANCE_ROXIE, AUDITION_ROXIE,
          GENE_NAME, BILLY_NAME, CASEY_NAME, JIGGLY_NAME,
        }) do
          local obj = objectNamed(world, AUDITION_MAP, name)
          if obj and obj.x == ev.x and obj.y == ev.y then
            if name == DANCE_HOST then talkVenueHost(AUDITION_MAP, name)
            elseif name == VENUE_DANCE_ROXIE then
              talkVenueRoxie(AUDITION_MAP, name)
            elseif name == AUDITION_ROXIE then talkAuditionRoxie()
            elseif name == JIGGLY_NAME then talkJigglypuff()
            else talkCandidate(name) end
            return
          end
        end
      elseif ev.mapId == RADIO_MAP or ev.mapId == CAFE_MAP then
        local host = ev.mapId == RADIO_MAP and RADIO_HOST or CAFE_HOST
        local roxie = ev.mapId == RADIO_MAP
          and VENUE_RADIO_ROXIE or VENUE_CAFE_ROXIE
        for _, name in ipairs({ host, roxie }) do
          local obj = objectNamed(world, ev.mapId, name)
          if obj and obj.x == ev.x and obj.y == ev.y then
            if name == host then talkVenueHost(ev.mapId, name)
            else talkVenueRoxie(ev.mapId, name) end
            return
          end
        end
      elseif ev.mapId == ECRUTEAK_MAP then
        local wooper = objectNamed(world, ECRUTEAK_MAP, SLEEPING_WOOPER)
        if wooper and wooper.x == ev.x and wooper.y == ev.y then
          talkWooper()
        end
      elseif ev.mapId == OLIVINE_MAP then
        local sailor = objectNamed(world, OLIVINE_MAP, BUSKER_SAILOR)
        if sailor and sailor.x == ev.x and sailor.y == ev.y then
          talkBusker()
        end
      elseif ev.mapId == SHOW_MAP then
        for _, name in ipairs({
          SHOW_ROXIE, SHOW_WHITNEY, SHOW_CASEY, PIERS_NAME,
        }) do
          local obj = objectNamed(world, SHOW_MAP, name)
          if obj and obj.x == ev.x and obj.y == ev.y then
            if name == SHOW_ROXIE then talkShowRoxie()
            elseif name == PIERS_NAME then talkPiers()
            else talkShowMember(name) end
            return
          end
        end
      end
    end)
    if not ok then report("GR INTERACT\n%s", tostring(err)) end
  end)

  mod.options:define({
    { key = "show_report", type = "toggle",
      label = "Report quest actors", default = true },
  })

  local reported = {}
  mod.events:on("map.entered", function(ev)
    local ok, err = pcall(function()
      local mapId = ev and ev.mapId
      if mapId ~= MAP and mapId ~= BASS_MAP and mapId ~= AUDITION_MAP
          and mapId ~= RADIO_MAP and mapId ~= CAFE_MAP
          and mapId ~= ECRUTEAK_MAP and mapId ~= OLIVINE_MAP
          and mapId ~= SHOW_MAP then return end
      local statuses = {}
      local function addStatus(value)
        if value and value ~= "" then statuses[#statuses + 1] = value end
      end
      if mapId == MAP then
        addStatus(placeRoxie())
      elseif mapId == BASS_MAP then
        addStatus(placeBassist())
        addStatus(placeVenue(mapId))
      elseif mapId == AUDITION_MAP then
        addStatus(placeAudition())
        addStatus(placeVenue(mapId))
      elseif mapId == RADIO_MAP or mapId == CAFE_MAP then
        addStatus(placeVenue(mapId))
      elseif mapId == ECRUTEAK_MAP then
        addStatus(placeWooper())
      elseif mapId == OLIVINE_MAP then
        addStatus(placeBusker())
      else
        addStatus(placeShow())
      end
      local status = table.concat(statuses, " ")
      local world = mod.world:overworld()
      if world and mapId == MAP and beat() == 10 then armBattle("roxie") end
      if world and mapId == BASS_MAP and beat() == 31
          and badgeCount(mod.world.game) >= 3 then armBattle("whitney") end
      if world and mapId == BASS_MAP and beat() == 84
          and questFlag("basement_armed")
          and not questFlag("basement_respect") then
        armBattle("basement")
      end
      if world and mapId == SHOW_MAP and beat() == 101
          and badgeCount(mod.world.game) >= SHOW_BADGE_GATE then
        armBattle("piers")
      end
      if status ~= "" and not reported[mapId]
          and mod.options:get("show_report") ~= false then
        reported[mapId] = true
        report("GR %s\n%s\nB%d", VERSION, status, beat())
      end
    end)
    if not ok then report("GR MAP ENTER\n%s", tostring(err)) end
  end)

  mod.log:info("gold_records %s loaded (gold)", VERSION)
end

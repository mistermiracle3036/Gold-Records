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
local BugContest = require("src.core.gen2.BugContest")
local ScriptMenu = require("src.ui.gen2.ScriptMenu")

return function(mod)
  local VERSION = "0.8.2"
  local MOD_ID = "gold_records"
  mod.exports.version = VERSION
  -- The manager's decisions (quest clean-up sheet 21), filled beside say();
  -- declared first because the audition and venue code read it too.
  local M = {}
  M.SHOW_KEYS = "GR_SHOW_KEYS" -- the fourth chair on stage (sheet 21 4e)
  -- The drummer's and keys player's stage sprites follow the line-up.
  function M.stageSprite(name)
    if name == "GR_SHOW_CASEY" then return M.drum().sprite end
    if name == M.SHOW_KEYS then
      return M.keys() == "elesa" and "SPRITE_GR_ELESA" or "SPRITE_GR_LARRY"
    end
    return nil
  end

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
    maps = {}, trainers = {}, items = {},
    sprites = {ROXIE_SPRITE, PIERS_SPRITE, "SPRITE_GR_LARRY",
      "SPRITE_GR_WOOPER", "SPRITE_GR_JIGGLYPUFF",
      "SPRITE_GR_MAYLENE", "SPRITE_GR_INGO", "SPRITE_GR_ELESA"},
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
  -- Bani's approved shared color walker, unchanged. Larry is only a fan
  -- in this chapter; no keyboard/recruitment hint or world actor is added.
  mod.content.sprites:register("SPRITE_GR_LARRY", {
    id = "SPRITE_GR_LARRY", image = mod.path .. "/assets/larry.png",
    frames = 6, walker = true, spriteType = "WALKING_SPRITE",
    palette = "PAL_OW_BROWN", paletteId = 3, trueColor = true,
  })
  -- Sheet 21 4e, the bigger band: canonical sheets copied unchanged, each
  -- registered with its REGISTRY.json palette (one character, one palette).
  for _, s in ipairs({ { "MAYLENE", "PAL_OW_RED", 0 }, { "INGO", "PAL_OW_BROWN", 3 },
      { "ELESA", "PAL_OW_BLUE", 1 } }) do
    mod.content.sprites:register("SPRITE_GR_" .. s[1], {
      id = "SPRITE_GR_" .. s[1], image = mod.path .. "/assets/" .. s[1]:lower() .. ".png",
      frames = 6, walker = true, spriteType = "WALKING_SPRITE",
      palette = s[2], paletteId = s[3],
    })
  end
  -- Every Pokemon placed in the world is anima-nel art, never Crystal's own
  -- overworld (developer, 2026-11-01; REQUESTS 384). Six-frame colour
  -- walkers copied unchanged, registered as Chance Encounters does.
  for _, species in ipairs({ "WOOPER", "JIGGLYPUFF" }) do
    mod.content.sprites:register("SPRITE_GR_" .. species, {
      id = "SPRITE_GR_" .. species,
      image = mod.path .. "/assets/" .. species:lower() .. "_anima.png",
      frames = 6, walker = true, trueColor = true,
      spriteType = "WALKING_SPRITE", palette = "PAL_OW_RED", paletteId = 0,
    })
  end
  local PIERS_FRONT_PATH = mod.path .. "/assets/piers_front.png"

  -- In-game credits (work order exchange/work-orders/credits-adoption.md,
  -- REQUESTS 30): the shared library byte for byte (LIB_VERSION 4, as
  -- Credits-Book and the other adopters ship) and this mod's generated
  -- artist list. One START > CREDITS row however many mods embed it.
  do
    local function module(path)
      return assert(load(assert(mod:read(path)), "@" .. mod.id .. "/" .. path))()
    end
    local ok, err = pcall(function()
      module("lib/credits.lua").attach(mod, module("lib/credits_data.lua"))
    end)
    if not ok then pcall(Runtime.reportError, "gold_records", "GR CREDITS\n" .. tostring(err)) end
  end

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
  local function compatibleSave()
    local r = mod.save:get("first_show", nil)
    return type(r) ~= "table" or (tonumber(r.schema) or 0) <= 1
  end

  local session, operation = 0, 0
  local concert, showBook
  local function guard()
    operation = operation + 1
    local op, epoch = operation, session
    local game, save, phase = mod.game, mod.game and mod.game.save, beat()
    local here = mod.world:current()
    local mapId = here and here.mapId
    return function()
      local now = mod.world:current()
      return op == operation and epoch == session and game == mod.game
        and save == mod.game.save and phase == beat()
        and now and now.mapId == mapId
    end
  end
  mod.events:on("game.ready", function() session = session + 1 end)
  mod.events:on("map.entered", function() operation = operation + 1 end)

  -- Optional crossovers are presence checks only. They never read another
  -- mod's state and never make that mod a dependency.
  local crossovers = {
    olivineCafe = false,
    kantoContests = false,
    courtOfNoctowl = false,
    trainerJourney = false,
  }

  -- Trainer Journey API 2 (Trainer-Journey/docs/API2_CONVERSION_GUIDE.md,
  -- REQUESTS 264). The old api_version == 1 gate switched every call below
  -- off once Trainer Journey moved on. Professions and ethos are unchanged
  -- in API 2; stat awards became XP accomplishments and skill rewards, and
  -- rank tests became evaluateCheck gates (guide bands, sections 4-5).
  local tj
  -- Each paying beat, by its old tag. The band story is the mod's main arc
  -- (major, 500 XP; its stages add up and end on "complete").
  local TJ_STORY = "band_story"
  local TJ_REWARDS = {
    roxie_battle = { story = "hired" },
    feedback_recruited = { story = "bassist" },
    casey_recruited = { story = "drummer" },
    park_show = { story = "first_set" },
    piers_battle = { story = "complete" },
    basement_king = { side = "basement_respect" },
    dance_showcase = { skill = "performance", points = 2 },
    first_busk = { skill = "performance", points = 3 },
  }

  local function tjInit()
    local handle = mod.find("trainer_journey")
    local api = handle and handle.exports and handle.exports.trainer_journey
    if not (api and api.api_version == 2 and api.progression_version == 1) then
      tj = nil; return
    end
    tj = api
    -- Registering again every session answers "duplicate"; that is normal.
    pcall(tj.registerProfession, {
      id = "rock_star",
      name = "BAND MANAGER",
      owner = MOD_ID,
      summary = "managing a punk band across JOHTO",
      thresholds = { 1, 3, 6, 10 },
      rankNames = { "ROADIE", "OPENER", "HEADLINER", "LEGEND" },
    })
    pcall(tj.registerAccomplishment, MOD_ID, TJ_STORY, {
      size = "major",
      stages = { hired = 50, bassist = 75, drummer = 75, first_set = 100, complete = 200 },
    })
    pcall(tj.registerAccomplishment, MOD_ID, "basement_respect", {
      size = "small", stages = { complete = 25 },
    })
    for tag, r in pairs(TJ_REWARDS) do
      if r.skill then
        pcall(tj.registerSkillReward, MOD_ID, "lesson:" .. tag, r.skill, r.points)
      end
    end
  end

  -- Pending receipts (guide section 6): the quest fact is already saved by
  -- the caller; the intent to pay is saved here, and it clears only when
  -- Trainer Journey answers (paid or duplicate). No provider, no trainer
  -- yet, an error or a throw all leave it pending for the next retry.
  local function tjClaim(key)
    local kind, tag = key:match("^(%a+):(.+)$")
    local r = TJ_REWARDS[tag]
    if not (tj and r) then return nil end
    if kind == "prof" then
      return tj.awardProfessionOnce("rock_star", 1, MOD_ID .. ":" .. tag)
    elseif r.story then
      return tj.awardAccomplishment(MOD_ID, TJ_STORY, r.story)
    elseif r.side then
      return tj.awardAccomplishment(MOD_ID, r.side, "complete")
    end
    return tj.awardSkillReward(MOD_ID, "lesson:" .. tag)
  end

  local function tjSettle()
    local pending = mod.save:get("tj_pending", nil)
    if type(pending) ~= "table" or next(pending) == nil or not tj then return end
    for key in pairs(pending) do
      local ok, result = pcall(tjClaim, key)
      if ok and result then pending[key] = nil end
    end
    mod.save:set("tj_pending", pending)
  end

  local function tjQueue(key)
    local pending = mod.save:get("tj_pending", nil)
    if type(pending) ~= "table" then pending = {} end
    pending[key] = true
    mod.save:set("tj_pending", pending)
    tjSettle()
  end

  local function tjAward(tag) tjQueue("pay:" .. tag) end
  local function tjProfession(tag) tjQueue("prof:" .. tag) end

  local function tjEthos(direction, weight, tag)
    if not tj then return end
    local fn = direction == "tradition" and tj.leanTradition or tj.leanInnovation
    pcall(fn, weight, MOD_ID .. ":" .. tag)
  end

  mod.events:on("map.entered", function()
    local ok, err = pcall(tjSettle)
    if not ok then report("GR TJ SETTLE\n%s", tostring(err)) end
  end)

  mod.events:on("game.ready", function()
    if not compatibleSave() then report("GR NEWER SAVE\nUse a newer build"); return end
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
    tj = crossovers.trainerJourney and tj or nil
    local ok, err = pcall(tjSettle)
    if not ok then report("GR TJ SETTLE\n%s", tostring(err)) end
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
  local battleSave, battleObject, battleWorld, previousBattleType

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
        local who = activeBattle or pendingBattle
        if who and opts and opts.battle and battleSave == game.save then
          battleObject = opts.battle
        else who = nil end
        local frontPath = who == "piers" and PIERS_FRONT_PATH
                       or who == "roxie" and ROXIE_FRONT_PATH
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
      if row.id == def.member or row.name == def.member
          or (def.member == "KAZU1" and row.id == "KAZU") then
        def.classIx, def.memberIx, def.resolvedMember = cls.index, i, row.id
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
    if battleSave ~= mod.game.save then return base end
    if class ~= def.class and class ~= def.classIx then return base end
    if member ~= def.member and member ~= def.resolvedMember and member ~= def.memberIx then return base end
    -- The character's canonical roster when Trainer Journey has one (sheet
    -- 21 section 8); otherwise this mod's own party, as before.
    local ok, built = pcall(function()
      return M.rosterParty(key, def.party) or buildParty(def.party)
    end)
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
      if not compatibleSave() then return end
      local npc = ev and ev.npc
      local name = npc and npc.def and npc.def.name
      local key = name == OBJ_NAME and "roxie"
               or name == FEEDBACK_NAME and "whitney"
               or name == PIERS_NAME and "piers"
               or name == BASEMENT_KING and "basement" or nil
      if not key then return end
      local def = BATTLES[key]
      local here = mod.world:current()
      if not here or here.mapId ~= def.map or not npc.def.runtime
          or objectNamed(mod.world:overworld(), def.map, def.npc) ~= npc.def
          or not npc.def.trainer
          or ev.trainerClass ~= def.classIx or ev.partyIndex ~= def.memberIx then return end
      battleSave, battleObject = mod.game.save, nil
      -- Arm the party hook only at the owned NPC engagement seam. Merely
      -- writing obj.trainer is not enough: the player may walk away and fight
      -- another trainer before returning.
      activeBattle = key
      if def.tempName and def.carrierRow then def.carrierRow.name = def.tempName end
      local world = mod.world:overworld()
      if world and world.scriptVars then
        battleWorld = world
        previousBattleType = world.scriptVars[VAR_BATTLETYPE]
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
      if not key or battleSave ~= mod.game.save or ev.battle ~= battleObject then return end
      pendingBattle = nil
      if battleWorld and battleWorld.scriptVars then
        battleWorld.scriptVars[VAR_BATTLETYPE] = previousBattleType
      end
      battleObject, battleSave = nil, nil
      defangBattle(key)
      local won = ev and ev.result == "win"
      if key == "roxie" then
        setBeat(won and 20 or 11)
        if won then
          tjAward("roxie_battle")
          tjProfession("roxie_battle")
        end
      elseif key == "whitney" then
        setBeat(won and 40 or 32)
      elseif key == "piers" then
        setBeat(won and 110 or 102)
        if won then
          tjAward("piers_battle")
          tjProfession("piers_battle")
          tjEthos("innovation", 1, "park_show")
        end
      elseif won then
        mod.save:set("basement_respect", true)
        mod.save:set("basement_armed", false)
        tjAward("basement_king")
        tjProfession("basement_king")
      else
        mod.save:set("basement_loss", true)
        mod.save:set("basement_armed", false)
      end
      if not won then healParty() end
    end)
    if not ok then report("GR BATTLE END\n%s", tostring(err)) end
  end)

  mod.events:on("game.ready", function()
    for key, def in pairs(BATTLES) do
      defangBattle(key)
      def.classIx, def.memberIx, def.carrierRow, def.originalName = nil, nil, nil, nil
    end
    if battleWorld and battleWorld.scriptVars then
      battleWorld.scriptVars[VAR_BATTLETYPE] = previousBattleType
    end
    activeBattle, pendingBattle, battleObject, battleSave, battleWorld = nil, nil, nil, nil, nil
  end)

  mod.events:on("map.entered", function(ev)
    local key = activeBattle or pendingBattle
    if key and ev.mapId ~= BATTLES[key].map then
      defangBattle(key)
      if battleWorld and battleWorld.scriptVars then
        battleWorld.scriptVars[VAR_BATTLETYPE] = previousBattleType
      end
      pendingBattle, battleSave, battleObject = nil, nil, nil
    end
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
    if beat() >= 90 then
      for _, name in ipairs({FEEDBACK_NAME, WHITNEY_NAME}) do
        local obj = objectNamed(world, BASS_MAP, name)
        if obj and obj.runtime then mod.world:removeNpc(BASS_MAP .. "_obj_" .. obj.index) end
      end
      bassSpawnId = nil
      return nil
    end
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
      sprite = "SPRITE_KIMONO_GIRL",
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
    tjAward("feedback_recruited")
    tjProfession("feedback_recruited")
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
    -- Sheet 21 4e: MAYLENE and INGO audition in GENE's and BILLY's places
    -- (the object names stay, so saved clue flags keep their meaning).
    { name = GENE_NAME, sprite = "SPRITE_GR_MAYLENE", x = 2, y = 9 },
    { name = BILLY_NAME, sprite = "SPRITE_GR_INGO", x = 5, y = 9 },
    { name = CASEY_NAME, sprite = "SPRITE_LASS", x = 8, y = 9 },
    { name = JIGGLY_NAME, sprite = "SPRITE_GR_JIGGLYPUFF", x = 6, y = 11 },
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
      -- Whoever was hired stays in the theater until the show is booked.
      wanted[M.drum().actor] = b < 90
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
    tjAward("casey_recruited")
    tjProfession("casey_recruited")
    removeAuditionActor(AUDITION_ROXIE)
    removeAuditionActor(JIGGLY_NAME)
    -- The two not hired leave; the hired drummer stays (sheet 21 4e).
    for _, name in ipairs({ CASEY_NAME, GENE_NAME, BILLY_NAME }) do
      if name ~= M.drum().actor then removeAuditionActor(name) end
    end
    local status = placeAudition()
    local label = M.drum().actor:gsub("^GR_", "")
    if status and not status:find(label, 1, true) then
      report("GR DRUMMER\n%s", tostring(status))
    end
  end

  --------------------------------------------------------------------------
  -- Act II side interactions: the road WOOPER is one-shot, while Olivine's
  -- busker stays after the venue hunt as a seed for the later tour.
  --------------------------------------------------------------------------
  local featureSpawnIds = {}
  local WOOPER_ACTOR = {
    name = SLEEPING_WOOPER, sprite = "SPRITE_GR_WOOPER", x = 23, y = 22,
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
    if mod.options:get("show_report") == true then
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
      b >= 81 and not questFlag("wooper_done"))
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
    if mapId == AUDITION_MAP then return b >= 81 end
    if mapId == RADIO_MAP then return b == 82 or b == 85 end
    if mapId == CAFE_MAP then return b == 83 or b == 86 end
    if mapId == BASS_MAP then return b >= 84 end
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
      local isBand = actor.name == VENUE_DANCE_ROXIE or actor.name == VENUE_UNDER_ROXIE
      if isBand and b >= 90 then
        removeVenueActor(mapId, actor.name)
      else
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
        if mod.options:get("show_report") == true then
          report("GR VENUE\n%s %d,%d\nB%d", actor.label, x, y, b)
        end
      end
    end
    end
    return table.concat(placed, " ")
  end

  local function advanceVenue(mapId, nextBeat)
    setBeat(nextBeat)
    if nextBeat >= 90 then
      mod.save:set("basement_armed", false)
    end
    local status = placeVenue(mapId)
    if status and mod.options:get("show_report") == true then report("GR VENUE NEXT\n%s", tostring(status)) end
  end

  --------------------------------------------------------------------------
  -- NATIONAL PARK show. The three band actors arrive at beat 90; PIERS is
  -- added only after the opening set, so his interruption is a real arrival.
  --------------------------------------------------------------------------
  local V = {} -- the ROUTE 36 venue state; its section below fills it
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
    { name = M.SHOW_KEYS, sprite = "SPRITE_GR_LARRY", x = 17, y = 44,
      label = "KEYS" },
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
    if b < 90 or (concert and concert.departed()) or BugContest.isActive(mod.game.save)
        or V.here() then
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
      [M.SHOW_KEYS] = M.keys() ~= nil,
    }
    if b >= 100 then wanted[PIERS_NAME] = true end
    for _, actor in ipairs(SHOW_ACTORS) do
      actor.sprite = M.stageSprite(actor.name) or actor.sprite
    end
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
          if mod.options:get("show_report") == true then
            report("GR SHOW\n%s %d,%d\nB%d", actor.label, x, y, b)
          end
        end
      end
    end
    return table.concat(placed, " ")
  end

  --------------------------------------------------------------------------
  -- ROUTE 36 music venue (Johto Expanded 0.3.11+, REQUESTS 209/211). Read
  -- only when both maps exist: without Johto Expanded the show stays in
  -- NATIONAL PARK exactly as before. "show_stage" anchors a show once it
  -- starts, so a show that opened in the park finishes there and PIERS is
  -- never met twice. Spots are Johto Expanded's named cells (README "The
  -- music venue"); it spawns nobody there, so this mod places everyone.
  --------------------------------------------------------------------------
  V.ENT = "JOHTO_EXPANDED_VENUE_ENTRANCE"
  V.MAP = "JOHTO_EXPANDED_MUSIC_VENUE"
  V.PLACE, V.PARK = "ROUTE 36", "NATIONAL PARK"
  V.PHONE_ROXIE = "GR_VENUE_PHONE_ROXIE"
  V.UP = 7
  -- Where ROXIE pulls the manager to: the paved aisle just behind PIERS.
  V.FRONT_X, V.FRONT_Y = 11, 9

  function V.ready()
    local world = mod.world and mod.world:overworld()
    local maps = world and world.maps
    return maps ~= nil and maps[V.ENT] ~= nil and maps[V.MAP] ~= nil
  end

  function V.here()
    if not V.ready() then return false end
    local anchor = mod.save:get("show_stage", nil)
    if anchor ~= nil then return anchor == V.PLACE end
    return beat() <= 90
  end

  function V.place() return V.here() and V.PLACE or V.PARK end
  function V.mapId() return V.here() and V.MAP or SHOW_MAP end

  function V.busked()
    local b = mod.save:get("busk", nil)
    return type(b) == "table" and b.done == true
  end

  -- The Map Maker's crowd order and each sprite's vanilla object palette
  -- (sprites/VANILLA_OBJ_PALETTES.json "recommended").
  V.LINE_SPRITES = {
    { "SPRITE_YOUNGSTER", 9 }, { "SPRITE_LASS", 10 }, { "SPRITE_ROCKER", 10 },
    { "SPRITE_POKEFAN_M", 11 }, { "SPRITE_COOLTRAINER_F", 8 },
    { "SPRITE_SUPER_NERD", 9 }, { "SPRITE_BEAUTY", 9 },
    { "SPRITE_COOLTRAINER_M", 8 }, { "SPRITE_TWIN", 8 }, { "SPRITE_BIKER", 11 },
  }
  V.LINE_CELLS = {
    { 3, 1 }, { 6, 1 }, { 7, 1 }, { 2, 2 }, { 3, 2 }, { 4, 2 }, { 5, 2 },
    { 6, 2 }, { 7, 2 }, { 2, 3 }, { 3, 3 }, { 5, 3 }, { 6, 3 }, { 7, 3 },
    { 2, 4 }, { 4, 4 }, { 5, 4 }, { 7, 4 }, { 3, 5 }, { 4, 5 }, { 6, 5 },
    { 7, 5 },
  }
  -- Once the manager is known, these three step aside with the right-hand
  -- DOOR guard: a lane from the mat (5,7) straight up to the door (5,0).
  V.LANE = { ["5,2"] = true, ["5,3"] = true, ["5,4"] = true }

  V.ENTRANCE = {
    { name = "GR_VENUE_DOOR_L", sprite = "SPRITE_OFFICER", palette = 9,
      x = 4, y = 1, label = "DOOR" },
    { name = "GR_VENUE_DOOR_R", sprite = "SPRITE_OFFICER", palette = 9,
      x = 5, y = 1, label = "DOOR", lane = true },
    { name = "GR_VENUE_TICKETS", sprite = "SPRITE_OFFICER", palette = 9,
      x = 0, y = 4, movement = MOVE_STANDING_RIGHT, label = "TICKETS" },
    { name = V.PHONE_ROXIE, sprite = ROXIE_SPRITE, x = 8, y = 7,
      movement = MOVE_STANDING_RIGHT, label = "ROXIE", phone = true },
  }
  for i, cell in ipairs(V.LINE_CELLS) do
    local s = V.LINE_SPRITES[(i - 1) % #V.LINE_SPRITES + 1]
    V.ENTRANCE[#V.ENTRANCE + 1] = {
      name = "GR_VENUE_LINE_" .. i, sprite = s[1], palette = s[2],
      x = cell[1], y = cell[2], movement = V.UP, label = "LINE",
      lane = V.LANE[cell[1] .. "," .. cell[2]],
    }
  end

  -- The band reuses the park actors' names (objectNamed is per map), so
  -- the PIERS trainer arm and every talk handler work on either stage.
  V.STAGE = {
    { name = SHOW_CASEY, sprite = "SPRITE_LASS", x = 10, y = 2,
      label = "CASEY", band = true },
    { name = SHOW_ROXIE, sprite = ROXIE_SPRITE, x = 8, y = 4,
      label = "ROXIE", band = true },
    { name = SHOW_WHITNEY, sprite = "SPRITE_WHITNEY", x = 12, y = 4,
      label = "WHITNEY", band = true },
    -- Keys and lights (4e) beside WHITNEY on the boards (stage y2-4).
    { name = M.SHOW_KEYS, sprite = "SPRITE_GR_LARRY", x = 14, y = 3,
      label = "KEYS", band = true, keys = true },
    { name = PIERS_NAME, sprite = PIERS_SPRITE, x = 11, y = 8,
      movement = V.UP, label = "PIERS", band = true },
    { name = "GR_VENUE_BARTENDER", sprite = "SPRITE_POKEFAN_M", palette = 11,
      x = 16, y = 8, label = "BAR" },
    { name = "GR_VENUE_FAN_1", sprite = "SPRITE_LASS", palette = 10,
      x = 8, y = 7, movement = V.UP, label = "FAN" },
    { name = "GR_VENUE_FAN_2", sprite = "SPRITE_YOUNGSTER", palette = 9,
      x = 10, y = 7, movement = V.UP, label = "FAN" },
    { name = "GR_VENUE_FAN_3", sprite = "SPRITE_COOLTRAINER_M", palette = 8,
      x = 9, y = 9, movement = V.UP, label = "FAN" },
    { name = "GR_VENUE_FAN_4", sprite = "SPRITE_TWIN", palette = 8,
      x = 10, y = 10, movement = V.UP, label = "FAN" },
    { name = "GR_VENUE_TABLE_1", sprite = "SPRITE_GENTLEMAN", palette = 9,
      x = 2, y = 9, movement = MOVE_STANDING_RIGHT, label = "FAN" },
    { name = "GR_VENUE_TABLE_2", sprite = "SPRITE_POKEFAN_F", palette = 11,
      x = 5, y = 12, movement = V.UP, label = "FAN" },
    { name = "GR_VENUE_BAR_1", sprite = "SPRITE_FISHER", palette = 10,
      x = 14, y = 9, movement = MOVE_STANDING_RIGHT, label = "FAN" },
  }

  for mapId, actors in pairs({ [V.ENT] = V.ENTRANCE, [V.MAP] = V.STAGE }) do
    local names = {}
    for _, a in ipairs(actors) do names[#names + 1] = a.name end
    mod.exports.owns.objects[mapId] = names
  end

  -- One spawn table for both venue maps, keyed "<map>/<name>".
  V.spawnIds = {}
  function V.remove(mapId, name)
    local key = mapId .. "/" .. name
    local id = V.spawnIds[key]
    if not id then
      local obj = objectNamed(mod.world:overworld(), mapId, name)
      if obj and obj.runtime and obj.index then
        id = mapId .. "_obj_" .. obj.index
      end
    end
    if id then pcall(function() mod.world:removeNpc(id) end) end
    V.spawnIds[key] = nil
  end

  -- Exact designed cells, no walkable fallback: a missing spot is a map
  -- change worth reporting, not something to paper over.
  function V.placeSet(mapId, actors, wanted)
    local world = mod.world and mod.world:overworld()
    if not world then return "no overworld" end
    local placed, failed = 0, {}
    for _, a in ipairs(actors) do
      if not wanted(a) then
        V.remove(mapId, a.name)
      elseif not objectNamed(world, mapId, a.name) then
        local id, err = mod.world:spawnNpc(mapId, {
          name = a.name, sprite = a.sprite, x = a.x, y = a.y,
          movement = a.movement or MOVE_STANDING_DOWN, palette = a.palette,
        })
        if id then
          V.spawnIds[mapId .. "/" .. a.name] = id
          placed = placed + 1
        else
          failed[#failed + 1] = a.label .. " " .. tostring(err)
        end
      end
    end
    if #failed > 0 then return "venue spawn " .. table.concat(failed, " ") end
    if placed == 0 then return nil end
    return ("VENUE %s +%d"):format(mapId == V.MAP and "STAGE" or "LINE", placed)
  end

  function V.placeEntrance()
    if not V.ready() then return nil end
    local known = questFlag("venue_met")
    -- One backer gets the band onto the stage (sheet 21, 4d).
    local phone = V.here() and beat() == 90 and M.backerCount() > 0 and not known
      and badgeCount(mod.world.game) >= SHOW_BADGE_GATE
    return V.placeSet(V.ENT, V.ENTRANCE, function(a)
      if a.phone then return phone end
      if a.lane then return not known end
      return true
    end)
  end

  function V.placeStage()
    if not V.ready() then return nil end
    local band = V.here() and beat() >= 90
      and not (concert and concert.departed())
      and (questFlag("venue_met") or questFlag("venue_dragged"))
    -- A PIERS who never heard the band busk is not waiting at the front: he
    -- crashes the opening set as a stranger and is placed from beat 100.
    local piers = M.piersFriend() or beat() >= 100
    for _, a in ipairs(V.STAGE) do a.sprite = M.stageSprite(a.name) or a.sprite end
    return V.placeSet(V.MAP, V.STAGE, function(a)
      if a.name == PIERS_NAME then return band and piers end
      if a.keys then return band and M.keys() ~= nil end
      return not a.band or band
    end)
  end

  function V.clearBand()
    for _, a in ipairs(V.STAGE) do
      if a.band then V.remove(V.MAP, a.name) end
    end
  end

  -- Whichever stage the show is on; the park side keeps its own rules.
  function V.refresh()
    local here = mod.world:current()
    local mapId = here and here.mapId
    if mapId == V.MAP then return V.placeStage() end
    return placeShow()
  end

  function V.clear()
    clearShowActors()
    V.clearBand()
  end

  function V.armPiers()
    BATTLES.piers.map = V.mapId()
    return armBattle("piers")
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
    "Ask the host here.",
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
    "KIMONO GIRL:\nAn audition here",
    "does not make this\nyour stage.",
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
    "STAFF: A radio\nspot? Certainly.",
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
    "WHITNEY: He wants\nGYM name on ads.",
    "FEEDBACK is my\nmusic name.",
    "ROXIE: So your\nsecret costs gigs.",
    "WHITNEY: Sorry.",
    "ROXIE: Fine.\fNATIONAL PARK.",
    "Nobody owns it.\fNobody can say no.",
    "Bring 4 BADGES.\fThen we play.",
  }

  local KING_INTRO = {
    "KING: Hold it.\fNobody books this\nroom.",
    "You earn it.",
    "Win and we will\nrespect the noise.",
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
    "Rest the crowd for\n30 play minutes.",
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
    "The wig stays on\ndown here, though.",
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
    "MAYLENE: ONE! TWO!\nSTRIKE!",
    "INGO: Departing in\nfive. Four. Three.",
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
    -- Sheet 21 4e (approved 2026-11-10): MAYLENE and INGO in GENE's and
    -- BILLY's places. Picking either is a hire, not a wrong answer.
    [GENE_NAME] = {
      intro = { "MAYLENE: One. Two.\nSTRIKE! Like that." },
      repeatIntro = { "MAYLENE: One. Two.\nSTRIKE! Like that." },
      clue = { "MAYLENE: I count\nin threes. Always." },
    },
    [BILLY_NAME] = {
      intro = { "INGO: Five beats a\nbar. On time." },
      repeatIntro = { "INGO: Five beats a\nbar. On time." },
      clue = { "INGO: Five. Never\nfour. Never late." },
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

  -- ROUTE 36 venue (developer-approved 2026-10-24, except where marked NEW:
  -- those are connective lines written for this build, not yet reviewed).
  V.HOOK = {
    "ROXIE: Fine.",
    "Someone heard us\nbusk in OLIVINE.",
    "There's a stage on\nROUTE 36.",
    "Bring 4 BADGES.\fThen we play.",
  }

  V.HOOK_AFTER_BUSK = {
    "ROXIE: Hey!", -- NEW opener; the rest is the approved hook
    "Someone heard us\nbusk in OLIVINE.",
    "There's a stage on\nROUTE 36.",
    "Bring 4 BADGES.\fThen we play.",
  }

  V.PHONE = {
    "ROXIE: ...yeah.\nHe's here now.",
    "Gotta go. Bye!",
    "ROXIE: Manager!\fYou made it.",
    "Packed, right?\fCome on.",
  }

  V.PIERS_MEET = {
    "PIERS: So you're\nthe manager.",
    "Heard your band\nbusking.",
    "Rough. Loud.\fI liked it.",
    "ROXIE: So you got\nus in?",
    "PIERS: My crowd.\fYour stage, then.",
    "Save me a spot.\fI want the encore.",
    "ROXIE: Not a\nchance.",
  }

  V.PIERS_WAIT = { "PIERS: Save me a\nspot.", "I want the encore." }
  V.PIERS_ENCORE = { "PIERS: Told you.\fI want the encore." }
  V.PIERS_BEAT = { "PIERS: You earned\nthe stage.", "That was a proper\nshow." }

  V.DOOR_SHUT = { "DOOR: Sold out.\fNo way through." } -- NEW
  V.DOOR_OPEN = { "DOOR: Manager?\fGo on in." } -- NEW
  V.TICKETS_LINE = { "TICKETS: Sold out\ntonight." } -- NEW
  V.LINE_TALK = { "Can't move!\fIt's packed!" } -- NEW
  V.BAR_TALK = { "BARTENDER: What'll\nit be?" } -- NEW
  -- No "FAN:" label: the NPC gate matches a NAME: prefix against names AND
  -- sprites, and "FAN" also hits SPRITE_POKEFAN_*, so the line was pinned on
  -- the bartender or a far table. Unlabelled, it is whoever you face.
  V.FAN_TALK = { "Turn it up!" } -- NEW

  local function facePlayer(mapId, name)
    local here = mod.world:current()
    local opposite = { up = "down", down = "up", left = "right", right = "left" }
    local want = here and here.facing and opposite[here.facing]
    local npc = mod.world:npc(mapId, name)
    if npc and want then pcall(npc.face, npc, want) end
  end

  local function say(pages, onDone)
    local current, used = guard(), false
    local ok, err = mod.world:queueScript({
      { "text", table.concat(pages, "\f") },
    }, {
      onDone = function(completed)
        if used or completed ~= true or not current() then return end
        used = true
        if not onDone then return end
        local done, why = pcall(onDone)
        if not done then report("GR TALK STATE\n%s", tostring(why)) end
      end,
    })
    if not ok then report("GR TALK FAIL\n%s", tostring(err)) end
    return ok
  end

  --------------------------------------------------------------------------
  -- The manager decides (quest clean-up sheet 21, developer-approved
  -- 2026-11-10). Every check is a real Trainer Journey check, shown in its
  -- own menu (AUTHOR_API.md "Shared social-check UI"): a row carries its
  -- word, its skill and gate, and the reply the player says; TJ reads the
  -- skill live and hands back check.passed. Without Trainer Journey the
  -- checked rows are absent and the plain ones fall back to Crystal's own
  -- ScriptMenu, so today's story still completes. Kept in one table: the
  -- main chunk sits near Lua's 200-local cap.
  --------------------------------------------------------------------------
  M.SCREEN = "GRChoice"
  mod.content.screens:register(M.SCREEN, { new = function(game, opts)
    local labels = {}
    for i, row in ipairs(opts.rows) do labels[i] = row.action end
    local menu
    menu = ScriptMenu.new(game, { title = opts.title, style = "vertical",
      header = { left = 0, top = 5, right = 19, bottom = math.min(17, 7 + #labels * 2),
        dataFlags = 0xc0, cursor = 1, items = labels },
      onChoose = function(index)
        if game.stack:top() == menu then game.stack:pop() end
        if index == 0 then opts.onCancel() else opts.onChoose(opts.rows[index]) end
      end,
    })
    return menu
  end })

  function M.plain(id, word, reply) return { id = id, kind = "plain", action = word, reply = reply } end
  function M.stat(id, word, reply, skill, gate)
    return { id = id, kind = "stat", action = word, reply = reply, stat = skill, gate = gate }
  end

  -- rows: plain and stat rows; onPick(row, passed). Stat rows are dropped
  -- without Trainer Journey; a menu with nothing but LEAVE is not opened.
  function M.menu(title, rows, onPick, onCancel)
    onCancel = onCancel or function() end
    if tj and type(tj.openCheckMenu) == "function" then
      local called, ok, err = pcall(tj.openCheckMenu, {
        game = mod.game, title = title, rows = rows, owner = MOD_ID,
        onChoose = function(row, check)
          if row then onPick(row, row.kind ~= "stat" or (check and check.passed == true)) end
        end,
        onCancel = onCancel,
      })
      if called and ok then return true end
      report("GR CHECK MENU\n%s", tostring(called and err or ok))
    end
    local plainRows = {}
    for _, r in ipairs(rows) do if r.kind ~= "stat" then plainRows[#plainRows + 1] = r end end
    local pushed, why = pcall(mod.ui.push, mod.game, M.SCREEN, { title = title, rows = plainRows,
      onChoose = function(row) onPick(row, true) end, onCancel = onCancel })
    if not pushed then report("GR MENU\n%s", tostring(why)) end
    return pushed
  end

  -- Saved facts. Existing saves past these beats read as today's story:
  -- FEEDBACK battled, the wig on.
  function M.billing() return mod.save:get("whitney_billing", "FEEDBACK") end
  function M.wigOff() return M.billing() == "WHITNEY" end

  -- Backers (4d): who gets the band onto the ROUTE 36 stage. PIERS backs
  -- whoever has busked in OLIVINE (never closes); KIMONO and RADIO are won
  -- or closed by one check; the UNDERGROUND backs WHITNEY under her name.
  function M.backer(id)
    if id == "piers" then return V.busked() end
    local b = mod.save:get("backers", nil)
    return type(b) == "table" and b[id] == true
  end
  function M.closed(id)
    local c = mod.save:get("backers_closed", nil)
    return type(c) == "table" and c[id] == true
  end
  function M.win(id)
    if id ~= "piers" then
      local b = mod.save:get("backers", nil)
      if type(b) ~= "table" then b = {} end
      b[id] = true
      mod.save:set("backers", b)
    end
    if mod.save:get("first_backer", nil) == nil then mod.save:set("first_backer", id) end
  end
  function M.close(id)
    local c = mod.save:get("backers_closed", nil)
    if type(c) ~= "table" then c = {} end
    c[id] = true
    mod.save:set("backers_closed", c)
  end
  function M.backerCount()
    local n = 0
    for _, id in ipairs({ "piers", "kimono", "radio", "underground" }) do
      if M.backer(id) then n = n + 1 end
    end
    return n
  end
  -- A save that busked before 0.8.0 recorded no first backer: PIERS it is.
  function M.firstBacker()
    return mod.save:get("first_backer", nil) or (V.busked() and "piers") or nil
  end
  -- PIERS is a friend at the door only if he heard the band busk; else he
  -- crashes the show as a stranger, with the park's lines (sheet 4d, D4).
  function M.piersFriend() return M.backer("piers") end

  -- New lines, verbatim from sheet 21 section 6 (approved 2026-11-10).
  M.NOT_YET = { "ROXIE: Think fast.", "Quiet's winning." }
  M.SIT_PASS = { "FEEDBACK: Huh.", "You can follow.", "No BADGES. Good\nears, though." }
  M.SIT_FAIL = { "FEEDBACK: Off the\nbeat. Get BADGES." }
  M.NAME_PASS = { "WHITNEY: No wig?", "Out loud?", "...They'd see me\nmess up.",
    "Okay. Okay! My\nname on the bill.", "The wig was itchy\nanyway." }
  M.NAME_FAIL = { "WHITNEY: Nope!", "The wig stays." }
  M.ROXIE_HEARS = { "ROXIE: A GYM\nLEADER on bass.", "That sells\ntickets. Ugh." }
  M.KIMONO_BACKS = { "KIMONO GIRL:\nOur guests will", "hear of you.", "We will send them." }
  M.RADIO_PASS = { "STAFF: Announce a\nshow with no hall?", "...It would fill\nthe hall. Clever.",
    "One spot.", "Tonight at six." }
  M.RADIO_FAIL = { "STAFF: Venue\nfirst. Policy." }
  M.UNDER_BACKS = { "WHITNEY: He says\nyes if it's me.", "It's me now.", "So... yes?",
    "ROXIE: Your room's\ntoo small. Bring", "your crowd to\nROUTE 36." }
  M.HOOK_FIRST = {
    kimono = { "ROXIE: The dancers\nsent a crowd.", "Polite people.", "We'll fix that." },
    radio = { "ROXIE: We're on\nthe radio!", "Now JOHTO has to\nshow up." },
    underground = { "ROXIE: WHITNEY's\nfans are coming.", "All of them.", "Duck." },
  }
  M.NO_BACKER = { "ROXIE: Nobody's\nbacking us yet.", "Win somebody over.", "Anybody." }
  -- The approved ROUTE 36 hook's last two pages, after any first-backer line.
  M.HOOK_TAIL = { "There's a stage on\nROUTE 36.", "Bring 4 BADGES.\fThen we play." }

  --------------------------------------------------------------------------
  -- 4e, the bigger band (approved 2026-11-10, "approve revised band").
  -- Drums: CASEY free, MAYLENE or INGO [PERSUASION 25]. Keys and lights:
  -- ELESA or LARRY, never both, or nobody. Lines verbatim from the sheet
  -- unless marked NEW. Existing saves read as CASEY and no fourth member.
  --------------------------------------------------------------------------
  M.DRUMS = {
    casey = { id = "casey", name = "CASEY", sprite = "SPRITE_LASS", actor = CASEY_NAME,
      soundcheck = { "CASEY: Four beats.", "Same cues on stage." },
      debrief = "CASEY: My chant!\nOn a real stage!" },
    maylene = { id = "maylene", name = "MAYLENE", sprite = "SPRITE_GR_MAYLENE", actor = GENE_NAME,
      hireReply = "She's loud. Hire her.",
      hired = { "ROXIE: ...She IS\nloud.", "Fine. Threes.\nWe'll play faster.",
        "MAYLENE: Yes! I\nwon't hold back!" },
      count = { "MAYLENE: ONE! TWO!", "STRIKE!" },
      steady = { "PLAY LOUD", "COUNT FOUR" }, steadyLine = "MAYLENE drives it.",
      soundcheck = { "MAYLENE: Three\nbeats. Hit hard." },
      debrief = "MAYLENE: My hands\nhurt. Again!",
      talk = { "MAYLENE: Ready.\nAre they ready?" } },
    ingo = { id = "ingo", name = "INGO", sprite = "SPRITE_GR_INGO", actor = BILLY_NAME,
      hireReply = "Different is good.",
      hired = { "ROXIE: Five-four.\nI have to count?", "WHITNEY will love\nit. Fine. Hired.",
        "INGO: All aboard." },
      count = { "INGO: Departing in", "five. Four. Three." },
      steady = { "COUNT FIVE", "PLAY LOUD" }, steadyLine = "INGO keeps time.",
      soundcheck = { "INGO: Five beats.\nMind the gap." },
      debrief = "INGO: We arrived\non time. Bravo.",
      talk = { "INGO: Next stop:\nthe second verse." } },
  }
  M.ROUGH_LINE = "We stumble back." -- NEW: cue 3's rough reply for MAYLENE/INGO
  M.DRUM_FAIL = { "ROXIE: No. My\nband, my ears.", "Four beats.\fFind them." }
  function M.drum() return M.DRUMS[mod.save:get("drummer", "casey")] or M.DRUMS.casey end
  function M.keys() return mod.save:get("keys", nil) end

  M.ELESA, M.LARRY = "GR_ELESA", "GR_LARRY"
  M.ELESA_MET = { "ELESA: A rock gig.\nLit by whom?", "...Nobody? Then it\nisn't a show yet." }
  M.ELESA_AGAIN = { "ELESA: A rock gig.\nLit by whom?" }
  M.ELESA_PASS = { "ELESA: You mean\nit. Good. I'm in.", "The lights are\nmine. All of them." }
  M.ELESA_FAIL = { "ELESA: Flat. Come\nback with a spark." }
  M.ELESA_BILL = { "ELESA: My name\nfirst. Then yes.", "ROXIE: HER name\nfirst? ...Fine." }
  M.ELESA_STAGE = { "ELESA: Lights on\nmy count. Mine." }
  M.LARRY_ASK1 = { "LARRY: I'm eating.", "Keys? In school.\nThat was long ago." }
  M.LARRY_ASK2 = { "LARRY: You again.\nI have a shift." }
  M.LARRY_PASS = { "LARRY: ...One.\nOn my lunch hour.", "Don't make it a\nthing." }
  M.LARRY_FAIL = { "LARRY: No. Really.\nEnjoy your show." }
  M.LARRY_STAGE = { "LARRY: I clock out\nat nine." }

  -- Line-up tags (4e): each adds its lines; none replaces a show cue.
  function M.allGirls()
    local d = M.drum().id
    return (d == "casey" or d == "maylene") and M.keys() ~= "larry"
  end
  function M.gymLeaders()
    local n = 1 -- ROXIE
    if M.wigOff() then n = n + 1 end
    if M.drum().id == "maylene" then n = n + 1 end
    if M.keys() == "elesa" then n = n + 1 end
    return n
  end
  M.TAG_GIRLS_CROWD = { "An all-girl band!\nFinally!" }
  M.TAG_GIRLS_ROXIE = { "ROXIE: Yeah, we\nnoticed. Count in." }
  M.TAG_GYM_DOOR = { "DOOR: Three GYM\nLEADERS? Tonight?", "I should've\ncharged more." }
  function M.girlsPiers()
    return { (M.keys() and "PIERS: Four girls" or "PIERS: Three girls") .. "\nand more noise",
      "than my whole\ntown. Respect." }
  end
  -- The soundcheck carries the drummer's own lines and every tag's.
  function M.soundcheck()
    local pages = {}
    for _, p in ipairs(M.drum().soundcheck) do pages[#pages + 1] = p end
    pages[#pages + 1] = "ROXIE: Now we can\nhear the bass."
    local function add(list) for _, p in ipairs(list) do pages[#pages + 1] = p end end
    if M.allGirls() and (M.drum().id ~= "casey" or M.keys()) then add(M.TAG_GIRLS_ROXIE) end
    if M.drum().id == "ingo" then add({ "ROXIE: He bows\nafter every song." }) end
    if M.drum().id == "maylene" then add({ "WHITNEY: She broke\na stick already!" }) end
    if M.keys() == "larry" then
      add({ "WHITNEY: The keys\nguy's in a tie!", "ROXIE: Leave him.\nHe's on his lunch." })
    end
    if M.keys() == "elesa" then add({ "ROXIE: Too bright!", "ELESA: Too dim." }) end
    return pages
  end
  -- ELESA in the RADIO TOWER lobby, LARRY eating at the OLIVINE CAFE, from
  -- the drummer joining until the show opens, while the chair is free.
  -- Vanilla maps: the walkable fallback (cellForActor) picks a free cell.
  M.ELESA_ACTOR = { name = M.ELESA, sprite = "SPRITE_GR_ELESA", x = 2, y = 6,
    movement = MOVE_STANDING_DOWN, label = "ELESA" }
  M.LARRY_ACTOR = { name = M.LARRY, sprite = "SPRITE_GR_LARRY", x = 6, y = 3,
    movement = MOVE_STANDING_DOWN, label = "LARRY" }
  function M.chairOpen()
    local b = beat()
    return b >= 80 and b < 100 and M.keys() == nil
  end
  function M.placeElesa()
    return placeFeatureActor(RADIO_MAP, M.ELESA_ACTOR, M.chairOpen())
  end
  function M.placeLarry()
    return placeFeatureActor(CAFE_MAP, M.LARRY_ACTOR, M.chairOpen() and not questFlag("larry_closed"))
  end

  -- Records the fourth member; both actors leave on the next map entry
  -- (placeElesa / placeLarry), never in the middle of their own lines.
  function M.join(id) mod.save:set("keys", id) end

  -- ELESA: [PERFORMANCE 25], or first billing with no check (ROXIE resents
  -- it). A failed check closes the check only; the billing way stays.
  function M.talkElesa()
    facePlayer(RADIO_MAP, M.ELESA)
    local opener = questFlag("elesa_met") and M.ELESA_AGAIN or M.ELESA_MET
    say(opener, function()
      setQuestFlag("elesa_met")
      local rows = {}
      if not questFlag("elesa_check_closed") then
        rows[#rows + 1] = M.stat("lights", "LIGHTS", "Light our show. Join the band.", "performance", 25)
      end
      rows[#rows + 1] = M.plain("bill", "BILLING", "Your name goes first.")
      rows[#rows + 1] = M.plain("leave", "LEAVE", "Not now.")
      M.menu("THE LIGHTS", rows, function(row, passed)
        if row.id == "leave" then return end
        if row.id == "bill" then
          M.join("elesa"); setQuestFlag("elesa_first_billing")
          return say(M.ELESA_BILL)
        end
        if not passed then
          setQuestFlag("elesa_check_closed")
          return say(M.ELESA_FAIL)
        end
        M.join("elesa")
        say(M.ELESA_PASS)
      end)
    end)
  end

  -- LARRY: two plain refusals on two separate visits to the cafe, then
  -- [PERSUASION 40], 5 easier per earlier ask (30). A fail closes him.
  function M.talkLarry()
    facePlayer(CAFE_MAP, M.LARRY)
    local asks = tonumber(mod.save:get("larry_asks", 0)) or 0
    local visit = tonumber(mod.save:get("cafe_visits", 0)) or 0
    local last = tonumber(mod.save:get("larry_last_visit", -1)) or -1
    if asks < 2 then
      if visit == last then return say(asks >= 2 and M.LARRY_ASK2 or M.LARRY_ASK1) end
      mod.save:set("larry_asks", asks + 1)
      mod.save:set("larry_last_visit", visit)
      return say(asks == 0 and M.LARRY_ASK1 or M.LARRY_ASK2)
    end
    if visit == last or not (tj and type(tj.openCheckMenu) == "function") then
      return say(M.LARRY_ASK2)
    end
    say(M.LARRY_ASK2, function()
      M.menu("LARRY", {
        M.stat("ask", "ASK", "One song. That's all.", "persuasion", math.max(30, 40 - 5 * asks)),
        M.plain("leave", "LEAVE", "Enjoy your lunch."),
      }, function(row, passed)
        if row.id ~= "ask" then return end
        mod.save:set("larry_last_visit", visit)
        if not passed then
          setQuestFlag("larry_closed")
          return say(M.LARRY_FAIL)
        end
        M.join("larry")
        say(M.LARRY_PASS)
      end)
    end)
  end

  -- Bonds (REQUESTS 732, Trainer Journey 0.8.59): TJ polls this export,
  -- ungated; each fact id pays half a star once, forever. A bond rises for
  -- hiring someone and for playing the show with them, never for talking
  -- (sheet 21 4e). LARRY's gift fact waits for REQUESTS 731.
  mod.exports.getAffinityEvents = function()
    local out = {}
    local function fact(kind, who)
      out[#out + 1] = { id = MOD_ID .. ":" .. kind .. ":" .. who, schema = 1,
        character = who, kind = "chapter" }
    end
    local members = {}
    if M.drum().id ~= "casey" then members[#members + 1] = M.drum().id end
    if M.keys() then members[#members + 1] = M.keys() end
    local r = mod.save:get("first_show", nil)
    local played = type(r) == "table" and r.opening == true
    for _, who in ipairs(members) do
      fact("hired", who)
      if played then fact("show", who) end
    end
    return out
  end

  -- Character rosters (REQUESTS 705/732): ROXIE, WHITNEY and PIERS each
  -- have one canonical team across mods. Asked at the battle's own top
  -- level and size, with this mod's party as the default; nil means ours.
  M.ROSTER_KEYS = { roxie = "roxie", whitney = "whitney", piers = "piers" }
  function M.rosterParty(key, rows)
    local who = M.ROSTER_KEYS[key]
    if not (who and tj and tj.team_version == 1 and type(tj.getCharacterTeam) == "function") then
      return nil
    end
    local top = 0
    for _, r in ipairs(rows) do top = math.max(top, r.level or 0) end
    local ok, party = pcall(tj.getCharacterTeam, who, { level = top, size = #rows,
      minSize = #rows, purpose = "story", default = rows })
    if ok and type(party) == "table" and #party > 0 then return party end
    return nil
  end

  -- Concert view of the line-up (concert.lua).
  function M.band()
    local d = M.drum()
    return { drummer = d, keys = M.keys(), original = d.id == "casey" and not M.keys() }
  end

  local activePicker
  local function clearPicker()
    if activePicker and activePicker.game.stack:top() == activePicker.screen then
      activePicker.game.stack:pop()
    end
    activePicker = nil
  end
  mod.events:on("game.ready", clearPicker)
  mod.events:on("map.entered", clearPicker)

  local function openDanceShow(advance)
    local current, used = guard(), false
    local game, picker = mod.game, nil
    local function close()
      if used or not current() or game.stack:top() ~= picker then return false end
      used = true
      game.stack:pop()
      activePicker = nil
      return true
    end
    local ok, result = pcall(mod.ui.push, game, "Gen2PartyMenu", {
      prompt = "choose",
      onChoose = function(_index, mon)
        if not close() or not mon then return end
        -- 4d: delight, not politeness, is a shown [PERFORMANCE 35] check
        -- (it replaced the old species auto-delight). It is asked once: a
        -- pass makes the KIMONO GIRLS a backer, a fail closes them. Later
        -- showcases replay the answer. Without Trainer Journey: polite.
        local function finish(graceful, backs)
          local pages = {}
          for _, p in ipairs(graceful and DANCE_DELIGHT or DANCE_POLITE) do pages[#pages + 1] = p end
          if backs then for _, p in ipairs(M.KIMONO_BACKS) do pages[#pages + 1] = p end end
          say(pages, function()
            local present = false
            for _, member in ipairs(game.save.party or {}) do
              if member == mon then present = true end
            end
            if not present then return end
            if graceful and not questFlag("dance_friendship_v1") then
              Happiness.change(mon, "GYMBATTLE")
              setQuestFlag("dance_friendship_v1")
            end
            setQuestFlag("dance_completed_v1")
            tjAward("dance_showcase")
            tjProfession("dance_showcase")
            if graceful then tjEthos("tradition", 1, "dance_showcase") end
            if advance then advanceVenue(AUDITION_MAP, 82) end
          end)
        end
        if M.backer("kimono") then return finish(true, false) end
        if M.closed("kimono") or not (tj and type(tj.openCheckMenu) == "function") then
          return finish(false, false)
        end
        M.menu("THE SHOWCASE", {
          M.stat("dance", "DANCE", "Watch this. Real grace.", "performance", 35),
          M.plain("plain", "POLITE", "A simple bow will do."),
        }, function(row, passed)
          if row.id == "dance" and passed then
            M.win("kimono")
            return finish(true, true)
          end
          if row.id == "dance" then M.close("kimono") end
          finish(false, false)
        end)
      end,
      onCancel = function()
        if close() then
          say({"KIMONO GIRL:\nAnother time.", "Speak to ROXIE to\nskip the showcase."})
        end
      end,
    })
    if ok then picker = result; activePicker = {game = game, screen = picker}
    else report("GR PARTY PICK\n%s", tostring(result)) end
  end

  local function talkBasementKing()
    facePlayer(BASS_MAP, BASEMENT_KING)
    if questFlag("basement_respect") then return say(KING_RESPECT) end
    local pages
    if questFlag("basement_loss") then
      pages = KING_RETRY
    else
      pages = KING_INTRO
    end
    say(pages, function()
      mod.save:set("basement_armed", true)
      armBattle("basement")
    end)
  end

  -- This engine has only weekday (0..6), not an absolute game date.
  -- A documented playtime cooldown avoids guessing history from that token.
  local function buskMinute()
    local t = mod.game.save.playTime
    if type(t) ~= "table" then return nil end
    return (tonumber(t.hours) or 0) * 60 + (tonumber(t.minutes) or 0)
  end

  local function talkBusker()
    facePlayer(OLIVINE_MAP, BUSKER_SAILOR)
    local minute = buskMinute()
    if not minute then return say({"SAILOR: The clock\nisn't ready yet."}) end
    local state = mod.save:get("busk", nil)
    if type(state) == "table" and state.done and state.clock ~= "play_v1" then
      state = {done = true, clock = "play_v1", last = minute}
      mod.save:set("busk", state) -- migration visit counts as already paid
    end
    if state and state.done and minute < (state.last or minute) + 30 then
      return say(BUSK_DAILY)
    end
    say(BUSK_PERFORMANCE, function()
      local world = mod.world:overworld()
      if not world then return end
      -- receipt first: at-most-once attempt, not a cross-API transaction.
      mod.save:set("busk", {done = true, clock = "play_v1", last = minute})
      local money = world:money(0)
      world:setMoney(0, math.max(0, math.min(999999, money + 300)))
      Happiness.changeParty(mod.game.save.party or {}, "GYMBATTLE")
      if not (state and state.done) then
        tjAward("first_busk")
        tjProfession("first_busk")
        M.win("piers")
        -- Busked only after the UNDERGROUND sent them here, with nobody
        -- backing the band yet: PIERS heard this set, so his hook plays now.
        if beat() == 90 and V.here() and not questFlag("venue_met")
            and M.backerCount() == 1 then
          local pages = {}
          for _, p in ipairs(BUSK_PAID) do pages[#pages + 1] = p end
          for _, p in ipairs(V.HOOK_AFTER_BUSK) do pages[#pages + 1] = p end
          return say(pages)
        end
      end
      say(BUSK_PAID)
    end)
  end

  local function talkWooper()
    facePlayer(ECRUTEAK_MAP, SLEEPING_WOOPER)
    local current, used = guard(), false
    local ok, err = mod.world:queueScript({
      { "text", table.concat(WOOPER_WAKE, "\f") },
      { "start_battle", "wild", "WOOPER", 18 },
    }, {
      onDone = function(completed)
        if used or not current() then return end
        used = true
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
    if mapId == AUDITION_MAP and beat() == 81 then
      return say({"ROXIE: Skip it?\nWe can come back.", "RADIO TOWER next."},
        function() advanceVenue(AUDITION_MAP, 82) end)
    end
    local pages = VENUE_OBJECTIVES[beat()]
    if pages then say(pages) end
  end

  local function talkVenueHost(mapId, name)
    facePlayer(mapId, name)
    local b = beat()
    if mapId == AUDITION_MAP and b == 81 then
      return say(DANCE_REFUSAL, function() openDanceShow(true) end)
    end
    if mapId == AUDITION_MAP and b >= 82 then
      return say(DANCE_REPEAT, function() openDanceShow(false) end)
    end
    if mapId == RADIO_MAP and b == 82 then
      -- 4d: the refusal still stands, then the manager's pitch [PERSUASION
      -- 30] can win a radio spot. A fail closes the RADIO TOWER as a backer.
      local nextStop = crossovers.kantoContests and 85 or 83
      return say(RADIO_REFUSAL, function()
        if M.backer("radio") or M.closed("radio")
            or not (tj and type(tj.openCheckMenu) == "function") then
          return advanceVenue(mapId, nextStop)
        end
        M.menu("THE RADIO", {
          M.stat("pitch", "PITCH", "Spot first. Venue after.", "persuasion", 30),
          M.plain("leave", "LEAVE", "Fair enough."),
        }, function(row, passed)
          if row.id ~= "pitch" then return advanceVenue(mapId, nextStop) end
          if passed then M.win("radio") else M.close("radio") end
          say(passed and M.RADIO_PASS or M.RADIO_FAIL, function()
            advanceVenue(mapId, nextStop)
          end)
        end, function() advanceVenue(mapId, nextStop) end)
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
    -- Once, the first time she hears WHITNEY is on the bill under her name.
    if beat() >= 50 and M.wigOff() and not questFlag("roxie_heard_name") then
      return say(M.ROXIE_HEARS, function() setQuestFlag("roxie_heard_name") end)
    end
    if beat() >= 90 and showBook then return showBook(false) end
    local b = beat()
    if b == 0 then
      say(INTRO, function()
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
      -- 4a: the offer is asked, not imposed. NOT YET writes nothing and
      -- leaves her waiting here; the whole offer plays again next time.
      local ask, rest = {}, {}
      for i, p in ipairs(MANAGER) do
        if i <= 3 then ask[#ask + 1] = p else rest[#rest + 1] = p end
      end
      say(ask, function()
        M.menu("THE OFFER", { M.plain("in", "I'M IN", "I'm in."),
          M.plain("later", "NOT YET", "Not yet.") }, function(row)
          if row.id == "in" then return say(rest, function() setBeat(30) end) end
          say(M.NOT_YET)
        end)
      end)
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
      local pages = UNDERGROUND_REFUSAL
      if V.here() then
        -- 4d: WHITNEY under her own name brings the UNDERGROUND in as a
        -- backer; otherwise the same refusal. Then the ROUTE 36 hook, set
        -- by the first backer the band landed.
        pages = {}
        local backs = M.wigOff()
        if backs then
          for _, p in ipairs(M.UNDER_BACKS) do pages[#pages + 1] = p end
        else
          for i = 1, #UNDERGROUND_REFUSAL - 3 do pages[#pages + 1] = UNDERGROUND_REFUSAL[i] end
        end
        local first = M.firstBacker() or (backs and "underground") or nil
        local hook
        if first == "piers" then hook = V.HOOK
        elseif first then
          hook = {}
          for _, p in ipairs(M.HOOK_FIRST[first]) do hook[#hook + 1] = p end
          for _, p in ipairs(M.HOOK_TAIL) do hook[#hook + 1] = p end
        else hook = M.NO_BACKER end
        for _, p in ipairs(hook) do pages[#pages + 1] = p end
        return say(pages, function()
          if backs then M.win("underground") end
          advanceVenue(BASS_MAP, 90)
        end)
      end
      return say(pages, function()
        advanceVenue(BASS_MAP, 90)
      end)
    end
    if b == 50 then
      return say({"WHITNEY: ROXIE set\nan open audition.",
        "ECRUTEAK's DANCE\nTHEATER. Drummers!", "Meet her there."}, function() setBeat(60) end)
    end
    if revealed or b >= 50 then return say(DRUM_OBJECTIVE) end
    if b == 40 then
      local drums = { "WHITNEY: Drums!\nECRUTEAK's DANCE",
        "THEATER. ROXIE has\nan open audition." }
      local function joined(pages)
        for _, p in ipairs(drums) do pages[#pages + 1] = p end
        say(pages, function() revealWhitney(); setBeat(60) end)
      end
      -- 4b, her terms: ONE SHOW in the wig, or [PERSUASION 30] her own
      -- name on the bill. A fail leaves the wig on for good. Without
      -- Trainer Journey there is no ask and the wig stays, as before.
      return say(WHITNEY_REVEAL, function()
        if not (tj and type(tj.openCheckMenu) == "function") then return joined({}) end
        M.menu("HER TERMS", {
          M.plain("deal", "DEAL", "One show, in the wig. Deal."),
          M.stat("name", "NAME", "Play as WHITNEY. Put your own name on the bill.",
            "persuasion", 30),
        }, function(row, passed)
          if row.id ~= "name" then return joined({}) end
          if not passed then
            local pages = {}
            for _, p in ipairs(M.NAME_FAIL) do pages[#pages + 1] = p end
            return joined(pages)
          end
          mod.save:set("whitney_billing", "WHITNEY")
          local pages = {}
          for _, p in ipairs(M.NAME_PASS) do pages[#pages + 1] = p end
          joined(pages)
        end)
      end)
    end
    if badgeCount(mod.world.game) < 3 then
      -- 4b, reaching her: [PERFORMANCE 30] sits in on her set without the
      -- BADGES. A fail closes this way; the BADGES and the battle stay.
      if questFlag("sit_in_closed") or not (tj and type(tj.openCheckMenu) == "function") then
        return say(FEEDBACK_LOCKED)
      end
      return say(FEEDBACK_LOCKED, function()
        M.menu("FEEDBACK", {
          M.stat("sitin", "SIT IN", "Let me sit in on your set.", "performance", 30),
          M.plain("leave", "LEAVE", "I'll be back with BADGES."),
        }, function(row, passed)
          if row.id ~= "sitin" then return end
          if not passed then
            setQuestFlag("sit_in_closed")
            return say(M.SIT_FAIL)
          end
          mod.save:set("feedback_way", "sit_in")
          say(M.SIT_PASS, function()
            setBeat(40)
            talkBassist(false)
          end)
        end)
      end)
    end
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
    local drum = M.drum()
    if b >= 80 then
      if name ~= drum.actor then return end
      if b == 80 then
        return say(VENUE_START, function() setBeat(81); placeVenue(AUDITION_MAP) end)
      end
      if drum.id == "casey" then say(VENUE_OBJECTIVES[b] or data.joined) else say(drum.talk) end
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
      if name == CASEY_NAME then
        local pages = {}
        for _, page in ipairs(data.right) do pages[#pages+1] = page end
        for _, page in ipairs(VENUE_START) do pages[#pages+1] = page end
        return say(pages, function() finishDrummer(); setBeat(81); placeVenue(AUDITION_MAP) end)
      end
      -- 4e: MAYLENE or INGO can be hired against ROXIE's ear [PERSUASION
      -- 25]. A fail: ROXIE overrules and that candidate is closed. Without
      -- Trainer Journey, ROXIE overrules as before; CASEY is her answer.
      local id = name == GENE_NAME and "maylene" or "ingo"
      local cand = M.DRUMS[id]
      if questFlag("drum_closed_" .. id) or not (tj and type(tj.openCheckMenu) == "function") then
        return say(M.DRUM_FAIL)
      end
      return M.menu("THE DRUMMER", {
        M.stat("hire", "HIRE", cand.hireReply, "persuasion", 25),
        M.plain("back", "BACK", "Let me think."),
      }, function(row, passed)
        if row.id ~= "hire" then return end
        if not passed then
          setQuestFlag("drum_closed_" .. id)
          return say(M.DRUM_FAIL)
        end
        mod.save:set("drummer", id)
        -- VENUE_START's first two pages are CASEY's; the rest is the plan.
        local pages = {}
        for _, p in ipairs(cand.hired) do pages[#pages + 1] = p end
        for i = 3, #VENUE_START do pages[#pages + 1] = VENUE_START[i] end
        say(pages, function() finishDrummer(); setBeat(81); placeVenue(AUDITION_MAP) end)
      end)
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
    facePlayer(V.mapId(), SHOW_ROXIE)
    if showBook then showBook(true) end
  end

  local function talkShowMember(name)
    facePlayer(V.mapId(), name)
    local b = beat()
    if name == SHOW_WHITNEY then
      if b == 90 then
        return say({ "WHITNEY: A real\ncrowd!", "Don't tell my\ntrainers." })
      elseif b >= 110 then
        return say({ "WHITNEY: Ready for\none more song?" })
      end
      return say({ "WHITNEY: He wants\nour encore!" })
    end
    -- 4e: the fourth chair and a drummer other than CASEY have one stage
    -- line each (the sheet's "stage talk"); CASEY keeps hers.
    if name == M.SHOW_KEYS then
      return say(M.keys() == "elesa" and M.ELESA_STAGE or M.LARRY_STAGE)
    end
    if M.drum().id ~= "casey" then return say(M.drum().talk) end
    if b == 90 then return say({ "CASEY: Four beats.\fNo speeding up." }) end
    if b >= 110 then
      return say({ "CASEY: E-LEC-\nTA-BUZZ!", "We held the beat!" })
    end
    say({ "CASEY: He won't\ncount us out!" })
  end

  function V.meetPiers()
    facePlayer(V.MAP, PIERS_NAME)
    return say(V.PIERS_MEET, function() setQuestFlag("venue_met") end)
  end

  local function talkPiers()
    local venue = V.here()
    -- A friend only at ROUTE 36 and only if he heard the busk (sheet 21
    -- D4); otherwise the stranger who crashes, with the park's lines.
    local friend = venue and M.piersFriend()
    facePlayer(V.mapId(), PIERS_NAME)
    local b = beat()
    if friend and b == 90 then
      if not questFlag("venue_met") then return V.meetPiers() end
      return say(V.PIERS_WAIT)
    end
    if b == 100 then
      -- His fame opener now plays when two or more backers filled the room.
      local intro = friend and V.PIERS_ENCORE
        or M.backerCount() >= 2 and PIERS_INTRO_FAME or PIERS_INTRO
      return say(intro, function()
        setBeat(101)
        V.armPiers()
      end)
    end
    if b == 101 then
      return say(venue and V.PIERS_ENCORE or { "PIERS: Ready?\fWake the park." },
        function() V.armPiers() end)
    end
    if b == 102 then
      return say(PIERS_RETRY, function()
        setBeat(101)
        V.armPiers()
      end)
    end
    -- 4e: after the show, an all-girl line-up (not the original three)
    -- gets PIERS's respect too ("Three girls" when the fourth chair is empty).
    local pages = {}
    for _, p in ipairs(friend and V.PIERS_BEAT or PIERS_BEAT) do pages[#pages + 1] = p end
    if b >= 110 and M.allGirls() and not M.band().original then
      for _, p in ipairs(M.girlsPiers()) do pages[#pages + 1] = p end
    end
    say(pages)
  end

  -- ROXIE on the phone by the entrance. Her walk through the packed line is
  -- a warp to the front of the venue; PIERS greets the manager on arrival.
  function V.talkPhoneRoxie()
    facePlayer(V.ENT, V.PHONE_ROXIE)
    say(V.PHONE, function()
      mod.save:set("show_stage", V.PLACE)
      setQuestFlag("venue_dragged")
      -- No friend waiting at the front: nobody to greet, so the manager is
      -- known to the door now (the lane opens) and PIERS crashes later.
      if not M.piersFriend() then setQuestFlag("venue_met") end
      local ok, err = mod.world:warpTo(V.MAP, V.FRONT_X, V.FRONT_Y, "up")
      if not ok then report("GR VENUE WARP\n%s", tostring(err)) end
    end)
  end

  function V.talkEntrance(actor)
    facePlayer(V.ENT, actor.name)
    if actor.label == "DOOR" then
      if questFlag("venue_met") and M.gymLeaders() >= 3 then return say(M.TAG_GYM_DOOR) end
      return say(questFlag("venue_met") and V.DOOR_OPEN or V.DOOR_SHUT)
    end
    if actor.label == "TICKETS" then return say(V.TICKETS_LINE) end
    say(V.LINE_TALK)
  end

  function V.talkStage(actor)
    if actor.name == SHOW_ROXIE then return talkShowRoxie() end
    if actor.name == PIERS_NAME then return talkPiers() end
    if actor.name == SHOW_WHITNEY or actor.name == SHOW_CASEY or actor.name == M.SHOW_KEYS then
      return talkShowMember(actor.name)
    end
    facePlayer(V.MAP, actor.name)
    -- 4e: an all-girl line-up other than the original three gets its cheer.
    if actor.label == "FAN" and M.allGirls() and not M.band().original
        and questFlag("venue_dragged") then
      return say(M.TAG_GIRLS_CROWD)
    end
    say(actor.label == "BAR" and V.BAR_TALK or V.FAN_TALK)
  end

  mod.events:on("world.interacted", function(ev)
    local ok, err = pcall(function()
      if not compatibleSave() or not ev
          or (ev.kind ~= "none" and ev.kind ~= "npc") then return end
      local world = mod.world:overworld()
      -- Engine 0.3.50+ emits "npc" for an unscripted runtime actor with
      -- ev.target = the live object; older engines emit "none" with only
      -- the faced cell. "npc" matches by target identity, and only for this
      -- mod's own runtime object with no scriptKey, so a native script never
      -- gets a second conversation (JQP 0.23.2 matchesInteractedActor).
      -- trainer is NOT rejected: the engine reaches its "npc" arm for a
      -- trainer only once it is refused (beaten) and starts nothing there;
      -- armed battles still go through the engine's own trainer arm.
      local function hit(obj)
        if not obj then return false end
        if ev.kind == "npc" then
          return ev.target ~= nil and ev.target.def == obj
            and obj.runtime == true and obj.owner == mod.id
            and not obj.scriptKey
        end
        return obj.x == ev.x and obj.y == ev.y
      end
      if ev.mapId == MAP then
        local obj = objectNamed(world, MAP, OBJ_NAME)
        if hit(obj) then talkRoxie() end
      elseif ev.mapId == BASS_MAP then
        local feedback = objectNamed(world, BASS_MAP, FEEDBACK_NAME)
        local whitney = objectNamed(world, BASS_MAP, WHITNEY_NAME)
        local roxie = objectNamed(world, BASS_MAP, VENUE_UNDER_ROXIE)
        local king = objectNamed(world, BASS_MAP, BASEMENT_KING)
        if hit(feedback) then
          talkBassist(false)
        elseif hit(whitney) then
          talkBassist(true)
        elseif hit(king) then
          talkBasementKing()
        elseif hit(roxie) then
          talkVenueRoxie(BASS_MAP, VENUE_UNDER_ROXIE)
        end
      elseif ev.mapId == AUDITION_MAP then
        for _, name in ipairs({
          DANCE_HOST, VENUE_DANCE_ROXIE, AUDITION_ROXIE,
          GENE_NAME, BILLY_NAME, CASEY_NAME, JIGGLY_NAME,
        }) do
          local obj = objectNamed(world, AUDITION_MAP, name)
          if hit(obj) then
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
        local keys = ev.mapId == RADIO_MAP and M.ELESA or M.LARRY
        for _, name in ipairs({ host, roxie, keys }) do
          local obj = objectNamed(world, ev.mapId, name)
          if hit(obj) then
            if name == host then talkVenueHost(ev.mapId, name)
            elseif name == M.ELESA then M.talkElesa()
            elseif name == M.LARRY then M.talkLarry()
            else talkVenueRoxie(ev.mapId, name) end
            return
          end
        end
      elseif ev.mapId == ECRUTEAK_MAP then
        local wooper = objectNamed(world, ECRUTEAK_MAP, SLEEPING_WOOPER)
        if hit(wooper) then
          talkWooper()
        end
      elseif ev.mapId == OLIVINE_MAP then
        local sailor = objectNamed(world, OLIVINE_MAP, BUSKER_SAILOR)
        if hit(sailor) then
          talkBusker()
        end
      elseif ev.mapId == SHOW_MAP then
        for _, name in ipairs({
          SHOW_ROXIE, SHOW_WHITNEY, SHOW_CASEY, PIERS_NAME, M.SHOW_KEYS,
        }) do
          local obj = objectNamed(world, SHOW_MAP, name)
          if hit(obj) then
            if name == SHOW_ROXIE then talkShowRoxie()
            elseif name == PIERS_NAME then talkPiers()
            else talkShowMember(name) end
            return
          end
        end
      elseif ev.mapId == V.ENT then
        for _, a in ipairs(V.ENTRANCE) do
          if hit(objectNamed(world, V.ENT, a.name)) then
            if a.phone then V.talkPhoneRoxie() else V.talkEntrance(a) end
            return
          end
        end
      elseif ev.mapId == V.MAP then
        for _, a in ipairs(V.STAGE) do
          if hit(objectNamed(world, V.MAP, a.name)) then
            V.talkStage(a)
            return
          end
        end
      end
    end)
    if not ok then report("GR INTERACT\n%s", tostring(err)) end
  end)

  mod.options:define({
    { key = "cinematic_shows", type = "toggle",
      label = "Cinematic shows", default = true },
    { key = "show_report", type = "toggle",
      label = "Report quest actors", default = false },
  })

  local reported = {}
  mod.events:on("map.entered", function(ev)
    local ok, err = pcall(function()
      if not compatibleSave() then return end
      local mapId = ev and ev.mapId
      if mapId ~= MAP and mapId ~= BASS_MAP and mapId ~= AUDITION_MAP
          and mapId ~= RADIO_MAP and mapId ~= CAFE_MAP
          and mapId ~= ECRUTEAK_MAP and mapId ~= OLIVINE_MAP
          and mapId ~= SHOW_MAP and mapId ~= V.ENT
          and mapId ~= V.MAP then return end
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
        if mapId == RADIO_MAP then
          addStatus(M.placeElesa())
        else
          -- LARRY's asks must come on separate visits: count the visits.
          mod.save:set("cafe_visits", (tonumber(mod.save:get("cafe_visits", 0)) or 0) + 1)
          addStatus(M.placeLarry())
        end
      elseif mapId == ECRUTEAK_MAP then
        addStatus(placeWooper())
      elseif mapId == OLIVINE_MAP then
        addStatus(placeBusker())
      elseif mapId == V.ENT then
        addStatus(V.placeEntrance())
      elseif mapId == V.MAP then
        addStatus(V.placeStage())
        -- Pulled through the line by ROXIE: PIERS is waiting at the front.
        -- If this greeting cannot queue, talking to him plays it instead.
        if questFlag("venue_dragged") and not questFlag("venue_met")
            and V.here() and beat() == 90 then
          V.meetPiers()
        end
      else
        addStatus(placeShow())
      end
      local status = table.concat(statuses, " ")
      local world = mod.world:overworld()
      if world and mapId == MAP and beat() == 10 then armBattle("roxie") end
      if world and mapId == BASS_MAP and beat() == 31
          and badgeCount(mod.world.game) >= 3 then armBattle("whitney") end
      if world and mapId == BASS_MAP and beat() >= 84
          and questFlag("basement_armed")
          and not questFlag("basement_respect") then
        armBattle("basement")
      end
      if world and mapId == V.mapId() and beat() == 101
          and badgeCount(mod.world.game) >= SHOW_BADGE_GATE then
        V.armPiers()
      end
      if status ~= "" and not reported[mapId]
          and mod.options:get("show_report") == true then
        reported[mapId] = true
        report("GR %s\n%s\nB%d", VERSION, status, beat())
      end
    end)
    if not ok then report("GR MAP ENTER\n%s", tostring(err)) end
  end)

  local factory, loadError = load(mod:read("concert.lua"), "@gold_records/concert.lua")
  if not factory then error(loadError) end
  concert = factory()(mod, {
    beat = beat, setBeat = setBeat, guard = guard, say = say, report = report,
    refresh = V.refresh, clear = V.clear,
    place = V.place, atVenue = V.here,
    -- Sheet 21: who is on the bill, whether PIERS is a friend at ROUTE 36,
    -- and whether the line-up can use Crystal Cutscene's show (its cue set
    -- knows the original three only: ROXIE, FEEDBACK in the wig, CASEY).
    billing = M.billing,
    piersFriend = function() return V.here() and M.piersFriend() end,
    -- 4e option A: any new member plays the built-in stage; the Cutscene
    -- show stays for the original three.
    nativeOnly = function() return V.here() or M.wigOff() or not M.band().original end,
    band = M.band, soundcheck = M.soundcheck, roughLine = M.ROUGH_LINE,
    -- Sheet 21 4f: the crowd's first word after the opening set, by the
    -- band's first backer (none for a park show or before any backer).
    openingCrowd = function()
      if not V.here() then return nil end
      local lines = {
        piers = "PIERS said come.\nSo we came.",
        kimono = "So this is rock.\nHow spirited.",
        radio = "I heard it on the\nradio! It's true!",
        underground = "WHITNEY! Over\nhere! WHITNEY!",
      }
      return lines[M.firstBacker() or ""]
    end,
    -- Before ROXIE is found at ROUTE 36, the Band Book points the way there.
    objective = function()
      if not V.here() or beat() ~= 90 or questFlag("venue_met") then return nil end
      -- Sheet 21 4f (Quest Clean-Up, REQUESTS 733).
      if M.backerCount() == 0 then return { "Find a backer.", "Ask at each stop." } end
      if badgeCount(mod.world.game) < SHOW_BADGE_GATE then
        return { "Bring 4 BADGES", "to ROUTE 36." }
      end
      return { "Find ROXIE on", "ROUTE 36." }
    end,
    opened = function()
      -- The show now belongs to the stage it opened on.
      if mod.save:get("show_stage", nil) == nil then
        mod.save:set("show_stage", V.place())
      end
      tjAward("park_show")
      tjProfession("park_show")
    end,
  })
  showBook = concert.openBook

  mod.log:info("gold_records %s loaded (gen2 private test)", VERSION)
end

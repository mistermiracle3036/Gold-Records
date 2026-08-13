-- Kanto Rocks -- a Gold quest starring ROXIE.
-- Alpha release. The questline runs as far as recruiting the drummer;
-- promotion, the venue and PIERS are still to come.
--
-- Proven Gold patterns used here:
--   * owned runtime NPC + world.interacted dialogue (Court of Noctowl)
--   * native trainer arm + trainer.party substitution (Indigo Conference)
--   * mod.save quest state, so loading an earlier save rewinds the quest

local Runtime = require("src.mods.Runtime")

return function(mod)
  local VERSION = "0.4.2"
  local MOD_ID = "kanto_rocks"
  mod.exports.version = VERSION

  local MAP = "VIOLET_CITY"
  local OBJ_NAME = "KR_ROXIE"
  local BASS_MAP = "GOLDENROD_UNDERGROUND"
  local FEEDBACK_NAME = "KR_FEEDBACK"
  local WHITNEY_NAME = "KR_WHITNEY"
  local AUDITION_MAP = "DANCE_THEATER"
  local AUDITION_ROXIE = "KR_AUDITION_ROXIE"
  local GENE_NAME = "KR_GENE"
  local BILLY_NAME = "KR_BILLY"
  local CASEY_NAME = "KR_CASEY"
  local JIGGLY_NAME = "KR_JIGGLYPUFF"
  local BADGE_GATE = 1
  local MOVE_STANDING_DOWN = 6
  local MOVE_STANDING_RIGHT = 9
  local MOVE_STANDING_LEFT = 8
  local ROXIE_SPRITE = "SPRITE_COOLTRAINER_F"
  -- Device-tested adjustment from the previous (18,19) placement:
  -- four cells right and seven cells up, facing right.
  local ROXIE_X, ROXIE_Y = 22, 12
  -- South Underground entrance placement test. Warp 2 enters at (3,34);
  -- FEEDBACK waits just to its right, facing the arrival corridor.
  local BASS_X, BASS_Y = 6, 33

  -- Runtime objects do not consume an index, but this reserves Kanto Rocks'
  -- future map-owned object band and documents ownership for other mods.
  mod.exports.owns = {
    maps = {}, trainers = {}, items = {}, sprites = {},
    objects = {
      [MAP] = { OBJ_NAME },
      [BASS_MAP] = { FEEDBACK_NAME, WHITNEY_NAME },
      [AUDITION_MAP] = {
        AUDITION_ROXIE, GENE_NAME, BILLY_NAME, CASEY_NAME, JIGGLY_NAME,
      },
      indexBand = { 160, 169 },
    },
    monFields = { "krHeadliner", "krPiersGift" },
  }

  local function report(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    pcall(Runtime.reportError, MOD_ID, ok and msg or tostring(fmt))
  end

  -- Quest beats:
  --   0 not met; 10 Roxie challenge; 11 lost; 20 won; 30 manager
  --   31 Feedback challenge armed; 32 lost; 40 Whitney beaten; 50 recruited
  --   60 drummer audition assigned; 70 Jigglypuff interruption happened
  --   71 candidate selection open; 80 Casey recruited
  local function beat() return tonumber(mod.save:get("beat", 0)) or 0 end
  local function setBeat(n) mod.save:set("beat", n) end

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
      seenKey = "KR_ROXIE_SEEN", winKey = "KR_ROXIE_WIN",
      lossKey = "KR_ROXIE_LOSS",
      party = { { species = "EKANS", level = 10 },
                { species = "KOFFING", level = 12 } },
    },
    whitney = {
      map = BASS_MAP, npc = FEEDBACK_NAME,
      class = "WHITNEY", member = "WHITNEY1",
      seenKey = "KR_FEEDBACK_SEEN", winKey = "KR_FEEDBACK_WIN",
      lossKey = "KR_FEEDBACK_LOSS",
      party = { { species = "CLEFAIRY", level = 20 },
                { species = "SNUBBULL", level = 20 },
                { species = "MILTANK", level = 22 } },
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

  local activeBattle, pendingBattle

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
    if not ok then report("KR CARRIER\n%s", tostring(why)); return false end
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
      report("KR PARTY FAIL\n%s", tostring(built))
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
               or name == FEEDBACK_NAME and "whitney" or nil
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
    if not ok then report("KR ENGAGE\n%s", tostring(err)) end
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
      if key == "roxie" then setBeat(won and 20 or 11)
      else setBeat(won and 40 or 32) end
      if not won then healParty() end
    end)
    if not ok then report("KR BATTLE END\n%s", tostring(err)) end
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
    local status = placeBassist()
    if status and not status:match("^WHITNEY") then
      report("KR REVEAL\n%s", tostring(status))
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
            actor.name:gsub("^KR_", ""), existing.x, existing.y)
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
            actor.name:gsub("^KR_", ""), x, y)
        end
      end
    end
    return table.concat(placed, " ")
  end

  local function finishDrummer()
    setBeat(80)
    removeAuditionActor(AUDITION_ROXIE)
    removeAuditionActor(GENE_NAME)
    removeAuditionActor(BILLY_NAME)
    removeAuditionActor(JIGGLY_NAME)
    local status = placeAudition()
    if status and not status:match("CASEY") then
      report("KR DRUMMER\n%s", tostring(status))
    end
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
        if not done then report("KR TALK STATE\n%s", tostring(why)) end
      end,
    })
    if not ok then report("KR TALK FAIL\n%s", tostring(err)) end
  end

  local function talkRoxie()
    facePlayer(MAP, OBJ_NAME)
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
      say(MANAGER, function() setBeat(30) end)
    elseif b < 50 then
      say(OBJECTIVE)
    elseif b == 50 then
      say(ROXIE_RECRUITED, function() setBeat(60) end)
    elseif b < 80 then
      say(DRUM_OBJECTIVE)
    else
      say(DRUMMER_FOUND)
    end
  end

  local function talkBassist(revealed)
    facePlayer(BASS_MAP, revealed and WHITNEY_NAME or FEEDBACK_NAME)
    local b = beat()
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
          report("KR JIGGLY\n%s", tostring(status))
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
        if feedback and feedback.x == ev.x and feedback.y == ev.y then
          talkBassist(false)
        elseif whitney and whitney.x == ev.x and whitney.y == ev.y then
          talkBassist(true)
        end
      elseif ev.mapId == AUDITION_MAP then
        for _, name in ipairs({
          AUDITION_ROXIE, GENE_NAME, BILLY_NAME, CASEY_NAME, JIGGLY_NAME,
        }) do
          local obj = objectNamed(world, AUDITION_MAP, name)
          if obj and obj.x == ev.x and obj.y == ev.y then
            if name == AUDITION_ROXIE then talkAuditionRoxie()
            elseif name == JIGGLY_NAME then talkJigglypuff()
            else talkCandidate(name) end
            return
          end
        end
      end
    end)
    if not ok then report("KR INTERACT\n%s", tostring(err)) end
  end)

  mod.options:define({
    { key = "show_report", type = "toggle",
      label = "Report quest actors", default = true },
  })

  local reported = {}
  mod.events:on("map.entered", function(ev)
    local ok, err = pcall(function()
      local mapId = ev and ev.mapId
      if mapId ~= MAP and mapId ~= BASS_MAP and mapId ~= AUDITION_MAP then return end
      local status = mapId == MAP and placeRoxie()
                  or mapId == BASS_MAP and placeBassist()
                  or placeAudition()
      local world = mod.world:overworld()
      if world and mapId == MAP and beat() == 10 then armBattle("roxie") end
      if world and mapId == BASS_MAP and beat() == 31
          and badgeCount(mod.world.game) >= 3 then armBattle("whitney") end
      if status and not reported[mapId]
          and mod.options:get("show_report") ~= false then
        reported[mapId] = true
        report("KR %s\n%s\nB%d", VERSION, status, beat())
      end
    end)
    if not ok then report("KR MAP ENTER\n%s", tostring(err)) end
  end)

  mod.log:info("kanto_rocks %s loaded (Gold private test)", VERSION)
end

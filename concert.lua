-- Native 160x144 concert/Book with an optional Crystal Cutscene presentation.
-- Original code-drawn props; commissioned sheets are used unchanged.
local Font = require("src.render.Font")
local BugContest = require("src.core.gen2.BugContest")
return function(mod, C)
  local API = {}
  local KEY, SCHEMA = "first_show", 1
  local active
  local bridge
  local function record()
    local r = mod.save:get(KEY, nil)
    if type(r) == "table" and (tonumber(r.schema) or 0) > SCHEMA then return nil end
    if type(r) ~= "table" then
      local b = C.beat()
      r = {schema = SCHEMA, legacy = b >= 100,
        opening = b >= 100, victory = b >= 110, encore = false,
        debrief = false, keepsake = false}
      if b >= 100 then r.first = {billing = "FEEDBACK", outcome = "EARLIER SHOW",
        preparation = "UNRECORDED"} end
      mod.save:set(KEY, r)
    end
    return r
  end
  local function write(r) mod.save:set(KEY, r) end
  local function prepared()
    local b = mod.save:get("busk", nil)
    return {sailors = type(b) == "table" and b.done == true,
      theater = mod.save:get("dance_completed_v1", false) == true,
      basement = mod.save:get("basement_respect", false) == true}
  end
  function API.departed()
    local r = mod.save:get(KEY, nil)
    return type(r) == "table" and r.schema == SCHEMA and r.debrief == true
  end
  local function permitted()
    return not BugContest.isActive(mod.game.save)
      and not (mod.world:overworld() or {}).battleActive
  end
  local function text(value, x, y)
    love.graphics.setColor(1, 1, 1, 1)
    Font.draw(value, x, y)
  end
  local function rect(x,y,w,h,c)
    love.graphics.setColor(c[1],c[2],c[3],1)
    love.graphics.rectangle("fill",x,y,w,h)
  end
  local ink, cream, gold = {.10,.13,.19}, {1,1,1}, {.84,.60,.25}
  local rose, blue = {.78,.30,.42}, {.27,.52,.62}
  local function panel(title)
    rect(0,0,160,144,cream)
    rect(3,3,154,138,ink)
    rect(5,5,150,134,cream)
    text(title, math.floor((160-Font.width(title))/2), 10)
    rect(12,22,136,1,gold)
  end
  local function pop(state)
    if state.game.stack:top() ~= state then return false end
    state.game.stack:pop()
    return true
  end
  local function leave(state)
    if active == state then active = nil end
    -- SpriteRenderer/Assets own their caches; do not release shared images.
    state.sprites = nil
  end
  local function current(state)
    return state.valid() and (state.kind == "book" or permitted())
  end
  local function cancelOld()
    if bridge then bridge.cancel("owner_context_changed") end
    if active and active.game.stack:top() == active then pop(active) end
  end
  mod.events:on("game.ready", cancelOld)
  mod.events:on("map.entered", cancelOld)
  mod.events:on("checkpoint.restored", cancelOld)

  bridge = assert(load(assert(mod:read("performance_bridge.lua")),
    "@gold_records/performance_bridge.lua"))()(mod, {
      permitted=permitted, say=C.say, report=C.report,
    })

  local function register(id, factory)
    mod.content.screens:register(id, {new = function(game, opts)
      local state = factory(game, opts)
      for _, name in ipairs({"update", "draw"}) do
        local method = state[name]
        state[name] = function(self, ...)
          if self.failed then return end
          local ok, err = pcall(method, self, ...)
          if not ok then
            self.failed = true
            if C.report then C.report("GR STAGE FAIL\n%s", tostring(err)) end
            if pop(self) then
              C.say({"The stage needs a", "moment. Try again."})
            end
          end
        end
      end
      return state
    end})
  end

  local openBook, startStage, openCard
  local function objective()
    local b, r = C.beat(), record()
    if not r then return {"Newer save schema.", "Use newer build."} end
    if r.debrief then return {"FIRST SHOW SAVED", "Rehearse any time."} end
    local early = C.objective and C.objective()
    if early then return early end
    local place = C.place and C.place() or "NATIONAL PARK"
    if b >= 110 then return {r.encore and "Debrief with band." or "Play the encore.", place} end
    if b >= 100 then return {"Prepare for PIERS.", place} end
    return {"Soundcheck, then", "the opening set."}
  end

  register("GRBandBook", function(game, opts)
    local state = {game=game, kind="book", isOpaque=true, valid=opts.valid,
      rows=opts.rows, cursor=1}
    function state:exit() leave(self) end
    function state:update()
      if not current(self) then pop(self); return end
      local i = game.input
      if i:wasPressed("b") then pop(self)
      elseif i:wasPressed("up") then self.cursor=(self.cursor-2)%#self.rows+1
      elseif i:wasPressed("down") then self.cursor=self.cursor%#self.rows+1
      elseif i:wasPressed("a") then
        local fn=self.rows[self.cursor][2]
        if pop(self) then fn() end
      end
    end
    function state:draw()
      panel("BAND BOOK")
      for n,row in ipairs(self.rows) do
        text((n==self.cursor and "▶" or " ")..row[1],12,30+(n-1)*16)
      end
      text("A: READ   B: BACK",16,126)
    end
    return state
  end)

  register("GRShowCard", function(game, opts)
    local state={game=game,kind="book",isOpaque=true,valid=opts.valid}
    function state:exit() leave(self) end
    function state:update()
      if not current(self) or game.input:wasPressed("a") or game.input:wasPressed("b") then pop(self) end
    end
    function state:draw()
      panel("FIRST SHOW")
      rect(14,29,132,53,gold)
      rect(16,31,128,49,cream)
      text("GOLD RECORDS",32,34)
      local place=opts.first.venue or "NATIONAL PARK"
      text(place,math.floor((160-Font.width(place))/2),48)
      text("ROXIE / FEEDBACK",16,62)
      text("CASEY ON DRUMS",24,72)
      text(opts.first.outcome or "EARLIER SHOW",16,91)
      text(opts.first.preparation == "UNRECORDED" and "Old set: unknown"
        or opts.first.sailors and "Sailors sang along"
        or "A new park crowd", 12,105)
      text("ENCORE PLAYED",28,117)
      text("A / B: CLOSE",32,130)
    end
    return state
  end)

  local steps = {
    {"CASEY: 1 2 3 4", "Give the entry!", "COUNT IN", "RUSH IN", "TOGETHER!", "A scrappy start."},
    {"FEEDBACK: My turn!", "Bring up the bass.", "BASS UP", "GUITAR UP", "BASS TAKES LEAD", "We trade the lead."},
    {"A cable crackles!", "Help us regroup.", "COUNT FOUR", "PLAY LOUD", "BACK ON THE BEAT", "CASEY holds us."},
  }
  local function makeSprites(game)
    local S = require("src.render.SpriteRenderer")
    local defs = game.data.gen2Sprites or game.data.sprites or {}
    local out = {}
    for _,row in ipairs({{"roxie","SPRITE_GR_ROXIE"},{"bass","SPRITE_WHITNEY"},
      {"casey","SPRITE_LASS"},{"piers","SPRITE_GR_PIERS"},
      {"larry","SPRITE_GR_LARRY"},
      {"fan","SPRITE_POKEFAN_M"},{"sailor","SPRITE_SAILOR"}}) do
      local def = defs[row[2]]
      if def then
        local ok,sprite=pcall(S.new,def,0)
        if ok then
          -- Private sprite instance; palette is resolved from this game's data.
          local P=require("src.world.gen2.Palettes")
          local colors=P.spritePalette(game.data.gen2Palettes,"DAY",def)
          if colors then sprite:setObjPalette(colors,"gen2:DAY:"..tostring(def.paletteId or 0)) end
          out[row[1]]=sprite
        end
      end
    end
    return out
  end
  local function placeholder(x,y,c)
    rect(x+3,y-4,10,7,ink);rect(x+5,y-1,6,5,cream)
    rect(x+2,y+4,12,7,c);rect(x+3,y+11,4,3,ink);rect(x+9,y+11,4,3,ink)
  end
  local function actor(state,name,x,y,c,bob)
    local sprite=state.sprites and state.sprites[name]
    love.graphics.setColor(1,1,1,1)
    if sprite then sprite:draw(x,y+(bob or 0),0,0,"down",0,false)
    else placeholder(x,y+(bob or 0),c) end
  end
  register("GRConcert", function(game,opts)
    local state={game=game,kind="stage",isOpaque=true,valid=opts.valid,
      mode=opts.mode,prep=opts.prep,step=1,choice=1,phase="cue",t=0,
      rough=0,paused=false,sprites=makeSprites(game),venue=opts.venue}
    function state:exit() leave(self) end
    function state:finish()
      if not current(self) then pop(self); return end
      local result={outcome=self.rough==0 and "HELD THE BEAT" or "FOUND OUR FEET",
        sailors=self.prep.sailors,theater=self.prep.theater,basement=self.prep.basement,
        billing="FEEDBACK",rough=self.rough}
      if pop(self) then opts.done(result) end
    end
    function state:update(dt)
      if not current(self) then pop(self); return end
      local input=game.input
      if input:wasPressed("start") then self.paused=not self.paused;return end
      if input:wasPressed("b") then
        if self.paused then pop(self) else self.paused=true end
        return
      end
      if self.paused then
        if input:wasPressed("a") then self.paused=false end
        return
      end
      self.t=self.t+math.min(dt or 0,.1)
      if self.phase=="entrance" then
        if self.t>=1.5 and input:wasPressed("a") then self:finish() end
        return
      end
      if self.phase=="cue" then
        if input:wasPressed("up") or input:wasPressed("down") then self.choice=3-self.choice end
        if input:wasPressed("a") then
          if self.choice==2 then self.rough=self.rough+1 end
          self.phase="response";self.t=0
          -- Existing short UI sound, never a music takeover or a shipped song.
          local Sound=require("src.core.Sound")
          pcall(Sound.play,game.data,"SFX_READ_TEXT_2")
        end
      elseif input:wasPressed("a") and self.t>=.5 then
        if self.step<3 then
          self.step=self.step+1;self.choice=1;self.phase="cue";self.t=0
        elseif self.mode=="opening" then self.phase="entrance";self.t=0
        else self:finish() end
      end
    end
    function state:draw()
      local step=steps[self.step]
      rect(0,0,160,144,cream)
      text(self.mode=="practice" and "SOUNDCHECK" or self.mode=="opening" and "THE OPENING SET" or "ONE MORE SONG",8,3)
      -- Paired speakers and a centered kit; the right aisle is Piers' entry.
      rect(6,18,148,53,ink);rect(8,20,144,48,{.35,.40,.40})
      for _,x in ipairs({12,136}) do
        rect(x,28,12,26,ink);rect(x+3,32,6,6,gold);rect(x+3,43,6,6,gold)
      end
      local playing=self.phase~="cue" and not self.paused
      local bob=playing and math.floor(self.t*4)%2 or 0
      local bassLead=playing and self.step==2 and self.choice==1
      local untidy=playing and self.step==1 and self.choice==2
      if bassLead then
        rect(102,25,22,33,{.84,.79,.53})
        for bar=0,2 do rect(127+bar*2,42-bar*3-bob,1,4+bar*3+bob,gold) end
      end
      actor(self,"roxie",37,39,rose,bob)
      actor(self,"bass",105,39,blue,untidy and -bob or bob)
      actor(self,"casey",72,30,gold,bob)
      -- Two distinct string instruments; moving picks/sticks are code props.
      rect(41,45,10,9,rose);rect(48,42,12,3,gold);rect(44,47+bob,5,1,cream)
      rect(108,45,9,10,blue);rect(114,39,14,3,gold);rect(110,48+bob,4,1,cream)
      rect(71,43,18,14,ink);rect(73,45,14,10,cream);rect(77,47,6,6,gold)
      rect(65,38,10,5,rose);rect(86,38,10,5,rose)
      for _,x in ipairs({63,95}) do rect(x,32,1,18,ink);rect(x-4,31,9,2,gold) end
      rect(70,34+bob,7,1,cream);rect(84,34-bob,7,1,cream)
      rect(40,57,10,9,cream);rect(75,57,10,9,cream);rect(109,57,10,9,cream)
      text("R",41,58);text("C",76,58);text("F",110,58)
      for _,x in ipairs({20,50,80,110}) do
        local who=x==80 and "larry"
          or self.prep.sailors and (x==20 or x==110) and "sailor" or "fan"
        actor(self,who,x,77,blue,who=="larry" and 0 or -bob)
      end
      if self.phase=="entrance" then
        actor(self,"piers",math.floor(160-math.min(self.t/1.5,1)*25),73,ink,0)
      end
      rect(0,92,160,52,cream);rect(0,92,160,1,ink)
      if self.paused then
        text("PAUSED",8,97);text("A: RESUME",8,112);text("B: LEAVE SET",8,128)
      elseif self.phase=="entrance" and self.venue then
        -- ROUTE 36: he was in the crowd all along and steps up for the encore.
        text("PIERS: Told you.",8,98);text("I want the encore.",8,111);text("A",144,128)
      elseif self.phase=="entrance" then
        text("PIERS: Not bad.",8,98);text("Mind if I crash",8,111);text("the encore?  A",8,128)
      elseif self.phase=="response" then
        text(step[self.choice==1 and 5 or 6],8,97)
        text(self.step==3 and (self.prep.sailors and "SAILORS: TA-BUZZ!" or "CROWD: One more!")
          or self.step==2 and "FAN: Let it ring!" or "KID: Play louder!",8,112)
        text("A: NEXT  B: PAUSE",8,128)
      else
        text(step[1],8,96);text(step[2],8,107)
        text((self.choice==1 and "▶" or " ")..step[3],8,119)
        text((self.choice==2 and "▶" or " ")..step[4],8,131)
      end
    end
    return state
  end)

  local function push(id,opts)
    if active or bridge.busy() then return end
    opts.valid=opts.valid or C.guard()
    local ok,result=pcall(mod.ui.push,mod.game,id,opts)
    if ok then active=result else
      if C.report then C.report("GR STAGE OPEN\n%s", tostring(result)) end
      C.say({"The stage needs a", "moment. Try again."})
    end
  end
  openCard=function()
    local r=record()
    if r and r.keepsake then push("GRShowCard",{first=r.first}) end
  end
  startStage=function(mode)
    if active or bridge.busy() then return end
    if not permitted() then return C.say({"Let the park event", "finish first."}) end
    local r=record()
    if not r then return end
    local prep=prepared()
    local valid=C.guard()
    local venue=C.atVenue and C.atVenue() or false
    local function done(result)
      if not valid() or not permitted() then return end
      local latest=record()
      if not latest then return end
      if mode=="practice" then
        latest.practice=result.outcome;latest.soundcheck=true;write(latest)
        C.say({"CASEY: Four beats.","Same cues on stage.","ROXIE: Now we can\nhear the bass."})
      elseif mode=="opening" and C.beat()==90 and not latest.opening then
        result.venue=C.place and C.place() or nil
        latest.opening=true;latest.first=result;write(latest)
        C.setBeat(100);C.refresh();C.opened()
        if venue then
          -- NEW lines (2026-10-24 build): PIERS invited them, so no "who asked".
          C.say({"ROXIE: Still not\na chance.","PIERS: Then win\nit off me.","Prepare your team.\nThen talk to me."})
        else
          C.say({"ROXIE: Who asked\nyou?","PIERS: Nobody.\nThat's the fun.","Prepare your team.\nThen talk to me."})
        end
      elseif mode=="encore" and C.beat()>=110 and not latest.encore then
        latest.encore=true;latest.victory=true;write(latest)
        C.say({"The last chord\nrings out.","Speak to ROXIE\nfor the debrief."})
      end
    end
    -- Crystal Cutscene's livePerformance v1 stages national_park and
    -- olivine_harbor only, so a ROUTE 36 set always uses the native stage.
    if not venue and bridge.start(mode,prep,valid,done) then return end
    push("GRConcert",{mode=mode,prep=prep,valid=valid,done=done,venue=venue})
  end
  local function debrief()
    -- Developer, 2026-10-24: at ROUTE 36 only; the park keeps its line.
    local opener=C.atVenue and C.atVenue() and "ROXIE: First real\nstage. Ours now."
      or "ROXIE: We made\nour own stage."
    C.say({opener,"WHITNEY: FEEDBACK\non the poster!","One name that's\njust for music.","CASEY: My chant!\nOn a real stage!","PIERS: Your band.\nKeep that sound.","You keep the\nFIRST SHOW card.","We pack the amps.\nThe path is clear.","Visit VIOLET for\nyour BAND BOOK."},function()
      local r=record()
      if not r or not r.encore then return end
      r.keepsake=true;r.debrief=true;write(r)
      C.clear()
      openCard()
    end)
  end
  openBook=function(atPark)
    if active or bridge.busy() then return end
    local r=record()
    if not r then return C.say({"Newer save schema.","Use newer build."}) end
    local rows={{"NEXT OBJECTIVE",function() C.say(objective()) end}}
    if r.keepsake then rows[#rows+1]={"FIRST SHOW CARD",openCard} end
    if atPark and permitted() then
      if C.beat()==90 then
        rows[#rows+1]={"SOUNDCHECK",function() startStage("practice") end}
        if r.soundcheck then rows[#rows+1]={"OPENING SET",function() startStage("opening") end} end
      elseif C.beat()>=110 and not r.encore then
        rows[#rows+1]={"PLAY ENCORE",function() startStage("encore") end}
      elseif r.encore and not r.debrief then rows[#rows+1]={"BAND DEBRIEF",debrief} end
    elseif atPark then rows[#rows+1]={"PARK EVENT",function() C.say({"Let the park event", "finish first."}) end} end
    if r.debrief then
      rows[#rows+1]={"REHEARSE",function() startStage("practice") end}
      rows[#rows+1]={"SHORT REPRISE",function() startStage("replay") end}
    end
    rows[#rows+1]={"CLOSE",function() end}
    push("GRBandBook",{rows=rows})
  end
  API.openBook=openBook
  return API
end

local root = (arg and arg[1]) or "."
local reports = {}
local mockDay, effectOrder = 2, {}
local loadNative=load
load=loadstring or loadNative
package.preload["src.mods.Runtime"] = function()
  return { reportError = function(modId, message)
    reports[#reports + 1] = tostring(modId) .. ":" .. tostring(message)
  end }
end

package.preload["src.core.gen2.Happiness"] = function()
  local H = {}
  function H.change(mon)
    effectOrder[#effectOrder + 1] = "happiness"
    mon.happiness = (mon.happiness or 70) + 3
    return mon.happiness
  end
  function H.changeParty(party)
    local n = 0
    for _, mon in ipairs(party or {}) do
      if (mon.hp or 0) > 0 then H.change(mon); n = n + 1 end
    end
    return n
  end
  return H
end

-- Crystal's own menu, used when Trainer Journey is absent. The test picks a
-- row by its word through pickWord() below.
local lastMenu
package.preload["src.ui.gen2.ScriptMenu"] = function()
  return { new = function(game, opts) lastMenu = { opts = opts }; return lastMenu end }
end

-- The shared gift helper (lib/gift_jingle.lua): a bag with a test limit and
-- a TextBox the test closes with lastGift.done().
local bagFull, given, lastGift = false, {}, nil
package.preload["src.inventory.Bag"] = function()
  return { add = function(save, id, n) if bagFull then return false end
    given[id] = (given[id] or 0) + (n or 1); return true end }
end
package.preload["src.render.TextBox"] = function()
  return { soundOpts = function() return {} end,
    new = function(game, line, done) lastGift = { line = line, done = done }; return {} end }
end

package.preload["src.core.gen2.Clock"] = function()
  return { weekday = function() return mockDay end }
end

package.preload["src.world.gen2.Trainers"] = function()
  return { party = function(data, entry)
    local out = {}
    for _, row in ipairs(entry.roster or {}) do
      out[#out + 1] = { species = row.species, level = row.level,
        stats = { hp = 20 }, hp = 20 }
    end
    return out
  end }
end

local function check(label, value)
  if not value then error("FAIL " .. label, 2) end
  print("ok " .. label)
end

local state, handlers, wrappers, text = {}, {}, {}, {}
local lastScript, currentMap = nil, "VIOLET_CITY"
local installedMods = {}
local partyPicker, pickerPops = nil, 0
local mapObjects = {
  VIOLET_CITY = {}, ROUTE_36 = {}, GOLDENROD_UNDERGROUND = {}, DANCE_THEATER = {},
  RADIO_TOWER_1F = {}, OLIVINE_CAFE = {}, ECRUTEAK_CITY = {},
  OLIVINE_CITY = {}, NATIONAL_PARK = {},
}
local janine = { id = "JANINE1", name = "JANINE", party = {} }
local whitney = { id = "WHITNEY1", name = "WHITNEY", party = {} }
local karen = { id = "KAREN1", name = "KAREN", party = {} }
local biker = { id = "KAZU1", name = "KAZU", party = {} }

local world = {
  maps = {
    VIOLET_CITY = { objects = mapObjects.VIOLET_CITY },
    ROUTE_36 = { objects = mapObjects.ROUTE_36 },
    GOLDENROD_UNDERGROUND = { objects = mapObjects.GOLDENROD_UNDERGROUND },
    DANCE_THEATER = { objects = mapObjects.DANCE_THEATER },
    RADIO_TOWER_1F = { objects = mapObjects.RADIO_TOWER_1F },
    OLIVINE_CAFE = { objects = mapObjects.OLIVINE_CAFE },
    ECRUTEAK_CITY = { objects = mapObjects.ECRUTEAK_CITY },
    OLIVINE_CITY = { objects = mapObjects.OLIVINE_CITY },
    NATIONAL_PARK = { objects = mapObjects.NATIONAL_PARK },
  },
  player = { cellX = 3, cellY = 3 }, scriptVars = {},
}
function world:npcAt(x, y)
  for _, obj in ipairs(mapObjects[currentMap] or {}) do
    if obj.x == x and obj.y == y then return obj end
  end
end

local screens, registeredSprites = {}, {}
local mod = {path = root, id = "gold_records",
  exports = {},
  game = { save = {
             player = { badges = { ZEPHYR = true }, kantoBadges = {}, money = 1000 },
             party = { { species = "BELLOSSOM", happiness = 70,
                         hp = 1, status = "PSN", stats = { hp = 25 } } },
           },
           data = { gen2Trainers = { classes = {
             JANINE = { index = 43, trainers = { janine } },
             WHITNEY = { index = 3, trainers = { whitney } },
             KAREN = { index = 45, trainers = { karen } },
             BIKER = { index = 20, trainers = { biker } },
           } } } },
  log = { info = function() end },
}
world.game = mod.game

mod.save = {
  get = function(self, key, default)
    local value = state[key]; if value == nil then return default end
    return value
  end,
  set = function(self, key, value) state[key] = value end,
}
mod.content = {text = {register = function(self,key,value) text[key]=value end},
 sprites={register=function(self,key,value) registeredSprites[key]=value end},
 screens={register=function(self,key,value) screens[key]=value end}}
function mod:read(file) local f=assert(io.open(self.path.."/"..file));local s=f:read("*a");f:close();return s end
package.preload["src.core.gen2.BugContest"]=function() return {isActive=function(save) return save.bugContest and save.bugContest.active end} end
package.preload["src.render.Font"]=function() return {width=function(s) return #s*8 end,draw=function(s,x,y)
 assert(x>=0 and x+#s*8<=160 and y>=0 and y+8<=144,"UI overflow: "..s)
 end} end
package.preload["src.render.SpriteRenderer"]=function() return {new=function() return {draw=function() end} end} end
package.preload["src.core.Sound"]=function() return {play=function() end} end
package.preload["src.ui.gen2.BattleState"]=function() return {new=function(game,opts) return {battle=opts.battle} end} end
package.preload["src.render.Assets"]=function() return {image=function() return {} end} end
love={graphics={setColor=function() end,rectangle=function() end}}
mod.game.save.playTime={hours=0,minutes=0}
local pressed
mod.game.input={wasPressed=function(_,key) return key==pressed end}

mod.events = { on = function(self, name, fn)
  handlers[name] = handlers[name] or {}; table.insert(handlers[name], fn)
end }
mod.hooks = { wrap = function(self, name, fn) wrappers[name] = fn end }
mod.options = { define = function() end, get = function() return true end }
mod.find = function(id)
  local m = installedMods[id]
  if type(m) == "table" then return m end
  return m and { id = id } or nil
end
local pickerFailure=false
mod.ui={push=function(game,id,opts)
 local screen
 if id=="Gen2PartyMenu" then
   if pickerFailure then error("picker unavailable") end
   partyPicker=opts;screen={}
 else screen=screens[id].new(game,opts) end
 game.stack:push(screen)
 return screen
end}
mod.game.stack={states={},top=function(self) return self.states[#self.states] end,
 push=function(self,state) self.states[#self.states+1]=state end,
 pop=function(self) local s=table.remove(self.states);if s and s.exit then s:exit() end;pickerPops=pickerPops+1;return s end}
mod.world = { game = mod.game }
function mod.world:overworld() return world end
function mod.world:current() return { mapId = currentMap, facing = "up" } end
function mod.world:npc(mapId, name) return { face = function() end } end
function mod.world:spawnNpc(mapId, def)
  local list = mapObjects[mapId]
  world.serial=(world.serial or 0)+1
  def.index, def.runtime, def.owner = world.serial, true, "gold_records"
  table.insert(list, def)
  return mapId .. "_obj_" .. def.index
end
function mod.world:removeNpc(id)
  for mapId, list in pairs(mapObjects) do
    for i, obj in ipairs(list) do
      if mapId .. "_obj_" .. obj.index == id then table.remove(list, i); return true end
    end
  end
end
function mod.world:queueScript(rows, extra)
  lastScript = { rows = rows, extra = extra }; return true
end
function world:money(account)
  return self.game.save.player.money or 0
end
function world:setMoney(account, value)
  self.game.save.player.money = value
end

local function emit(name, ev)
  for _, fn in ipairs(handlers[name] or {}) do fn(ev) end
end

local function enter(mapId)
  currentMap = mapId
  world.map = {
    isWalkableCell = function(self, x, y) return x >= 0 and y >= 0 end,
    warpAtCell = function() return nil end,
  }
  emit("map.entered", { mapId = mapId })
end

local function talk(mapId, obj)
  currentMap = mapId
  emit("world.interacted", { kind = "none", mapId = mapId,
                              x = obj.x, y = obj.y })
end

local function engage(obj, class)
  emit("world.trainer_engaged", { npc = { def = obj }, trainerClass=obj.trainer.class,partyIndex=obj.trainer.member })
  local party=wrappers["trainer.party"](function() return {{species="PIDGEY"}} end,class,1,{})
  local battle={}
  require("src.ui.gen2.BattleState").new(mod.game,{battle=battle})
  return party,battle
end

local function findObj(mapId, name)
  for _, obj in ipairs(mapObjects[mapId]) do
    if obj.name == name then return obj end
  end
end

local function reportsContain(needle)
  for _, report in ipairs(reports) do
    if report:find(needle, 1, true) then return true end
  end
  return false
end

local init = dofile(root.."/main.lua")
init(mod)
emit("game.ready",{})
local function done(completed)
 local script=lastScript;lastScript=nil
 assert(script,"no queued dialogue")
 script.extra.onDone(completed~=false)
end
local function press(key,dt)
 local top=mod.game.stack:top();assert(top,"no screen")
 if top.draw then top:draw() end
 pressed=key;top:update(dt or 1);pressed=nil
end
local function select(label)
 local top=mod.game.stack:top();assert(top and top.rows,"no book")
 for i,row in ipairs(top.rows) do if row[1]==label then top.cursor=i;press("a");return end end
 error("missing menu: "..label)
end
local function actor(map,name) return assert(findObj(map,name),"missing "..name) end
local function sayTo(map,name) talk(map,actor(map,name)) end
local function finishSet(rough,entrance)
 for n=1,3 do
  if rough then press("down") end
  press("a");press(nil,1);press(nil,1);press(nil,1);press(nil,1);press(nil,1);press(nil,1);press("a")
 end
 if entrance then
  for i=1,16 do press(nil,1) end
  local top=mod.game.stack:top();check("visible Piers entrance",top.phase=="entrance")
  top:draw();press("a")
 end
end

-- Engine 0.3.50+ sends kind="npc" with the live object for an unscripted
-- runtime actor (0.4.3 hotfix). Match by identity, never by another object.
enter("VIOLET_CITY");lastScript=nil
local npcRoxie=actor("VIOLET_CITY","GR_ROXIE")
emit("world.interacted",{kind="npc",mapId="VIOLET_CITY",x=npcRoxie.x,y=npcRoxie.y,
  target={def={name="SOMEONE_ELSE",runtime=true,owner="other_mod"}}})
check("npc kind ignores another object",lastScript==nil)
emit("world.interacted",{kind="npc",mapId="VIOLET_CITY",x=-9,y=-9,target={def=npcRoxie}})
check("npc kind reaches ROXIE",lastScript~=nil)
lastScript.extra.onDone(false);lastScript=nil

-- Dialogue completion, save switch, late/repeated callbacks.
enter("VIOLET_CITY");sayTo("VIOLET_CITY","GR_ROXIE")
local cb=lastScript.extra.onDone;cb(false)
check("aborted intro does not advance",state.beat==nil)
sayTo("VIOLET_CITY","GR_ROXIE");cb=lastScript.extra.onDone
local oldSave=mod.game.save;mod.game.save={player=oldSave.player,party={}};cb(true)
check("save switch invalidates dialogue",state.beat==nil)
mod.game.save=oldSave;emit("game.ready",{})
sayTo("VIOLET_CITY","GR_ROXIE");done();check("intro completes",state.beat==10)
local roxie=actor("VIOLET_CITY","GR_ROXIE")
local party,battle=engage(roxie,"JANINE")
check("owned party and name",#party==2 and janine.name=="ROXIE")
emit("battle.ended",{result="win",battle={}});check("unrelated battle ignored",state.beat==10)
emit("battle.ended",{result="lose",battle=battle});check("loss retry and restore",state.beat==11 and janine.name=="JANINE" and world.scriptVars[3]==nil)
sayTo("VIOLET_CITY","GR_ROXIE");done();party,battle=engage(roxie,"JANINE")
emit("battle.ended",{result="win",battle=battle});check("win",state.beat==20)
local vanilla=wrappers["trainer.party"](function() return {{species="RATTATA"}} end,"JANINE",1,{})
check("vanilla after battle",vanilla[1].species=="RATTATA")

-- Local legacy handoffs.
state.beat=50;enter("GOLDENROD_UNDERGROUND");sayTo("GOLDENROD_UNDERGROUND","GR_WHITNEY");done()
check("local bassist handoff",state.beat==60)
state.beat=80;enter("DANCE_THEATER");sayTo("DANCE_THEATER","GR_CASEY");done()
check("local drummer handoff",state.beat==81)

-- Cancel, open failure, completed/aborted qualifying, replay, participant switch.
sayTo("DANCE_THEATER","GR_DANCE_HOST");done();partyPicker.onCancel()
check("cancel no credit or advancement",state.beat==81 and not state.dance_friendship_v1 and not state.dance_completed_v1)
done()
pickerFailure=true;sayTo("DANCE_THEATER","GR_DANCE_HOST");done();pickerFailure=false
check("open failure no credit",state.beat==81 and not state.dance_completed_v1)
local mon={species="EEVEE",hp=10,happiness=70};mod.game.save.party={mon}
sayTo("DANCE_THEATER","GR_DANCE_HOST");done();partyPicker.onChoose(1,mon);done(false)
check("aborted performance no friendship",mon.happiness==70)
-- Sheet 21 4d: delight is a [PERFORMANCE 35] check, not the species. With
-- no Trainer Journey there is no check: a polite showcase, no friendship.
sayTo("DANCE_THEATER","GR_DANCE_HOST");done();partyPicker.onChoose(1,mon)
check("no TJ: polite, no check menu",lastScript.rows[1][2]:find("unusual dance",1,true)~=nil)
done()
check("showcase completes and advances",mon.happiness==70 and state.beat==82 and state.dance_completed_v1)
sayTo("DANCE_THEATER","GR_DANCE_HOST");done();partyPicker.onChoose(1,mon);done()
check("repeat stays polite",mon.happiness==70)
sayTo("DANCE_THEATER","GR_DANCE_HOST");done();partyPicker.onChoose(1,mon)
mod.game.save.party={{species="EEVEE",happiness=70}};done()
check("participant replacement not rewarded",not state.dance_friendship_v1)
-- Stale picker never pops newer screen.
sayTo("DANCE_THEATER","GR_DANCE_HOST");done();local stalePicker=partyPicker
enter("VIOLET_CITY");mod.game.stack:push({});local top=mod.game.stack:top();stalePicker.onCancel()
check("stale picker cannot pop new UI",mod.game.stack:top()==top)
mod.game.stack.states={}

-- Optional activities remain after park; resolved WOOPER stays gone.
state.beat=90;enter("ECRUTEAK_CITY");check("late WOOPER exists",findObj("ECRUTEAK_CITY","GR_SLEEPING_WOOPER"))
sayTo("ECRUTEAK_CITY","GR_SLEEPING_WOOPER");done();enter("ECRUTEAK_CITY")
check("resolved WOOPER absent",not findObj("ECRUTEAK_CITY","GR_SLEEPING_WOOPER"))
enter("DANCE_THEATER");check("late showcase host",findObj("DANCE_THEATER","GR_DANCE_HOST"))
check("theater band departed",not findObj("DANCE_THEATER","GR_CASEY") and not findObj("DANCE_THEATER","GR_DANCE_ROXIE"))
enter("GOLDENROD_UNDERGROUND");check("late King",findObj("GOLDENROD_UNDERGROUND","GR_BASEMENT_KING"))
check("Whitney leaves Underground",not findObj("GOLDENROD_UNDERGROUND","GR_WHITNEY"))

-- Explicit playtime fallback, migration and rollback.
enter("OLIVINE_CITY");state.busk={done=true,day=2};mod.game.save.playTime={hours=2,minutes=0}
local money=mod.game.save.player.money or 0
sayTo("OLIVINE_CITY","GR_BUSKER_SAILOR");done()
check("legacy busk conservative migration",state.busk.clock=="play_v1" and (mod.game.save.player.money or 0)==money)
mod.game.save.playTime.minutes=30;sayTo("OLIVINE_CITY","GR_BUSKER_SAILOR");cb=lastScript.extra.onDone;done();cb(true)
check("cooldown payout only once",mod.game.save.player.money==money+300)
done();sayTo("OLIVINE_CITY","GR_BUSKER_SAILOR");done()
check("same minute no second payout",mod.game.save.player.money==money+300)
mod.game.save.playTime.minutes=0;sayTo("OLIVINE_CITY","GR_BUSKER_SAILOR");done()
check("rollback no payout",mod.game.save.player.money==money+300)
mod.game.save.playTime.hours=3;sayTo("OLIVINE_CITY","GR_BUSKER_SAILOR");done();done()
check("forward progress recovers",mod.game.save.player.money==money+600)

-- Standalone native soundcheck -> opening -> loss/retry -> encore -> card.
mod.game.save.player.badges={a=true,b=true,c=true,d=true}
state.first_show=nil;state.beat=90;enter("NATIONAL_PARK");sayTo("NATIONAL_PARK","GR_SHOW_ROXIE")
select("SOUNDCHECK");finishSet(false,false);done()
check("soundcheck completed",state.first_show.soundcheck and state.beat==90)
sayTo("NATIONAL_PARK","GR_SHOW_ROXIE");select("OPENING SET")
press("a");press("b");check("performance pause",mod.game.stack:top().paused)
press("b");check("abandon has no fabricated opening",not state.first_show.opening and state.beat==90)
sayTo("NATIONAL_PARK","GR_SHOW_ROXIE");select("OPENING SET");finishSet(true,true);done()
check("rough opening advances",state.beat==100 and state.first_show.first.outcome=="FOUND OUR FEET")
check("sailor payoff snapshotted",state.first_show.first.sailors)
check("Piers now on map",findObj("NATIONAL_PARK","GR_PIERS"))
sayTo("NATIONAL_PARK","GR_PIERS");done();party,battle=engage(actor("NATIONAL_PARK","GR_PIERS"),"KAREN")
check("Piers team preserved",#party==5 and party[5].species=="HOUNDOOM")
emit("battle.ended",{result="lose",battle=battle});check("loss keeps opening",state.beat==102 and state.first_show.opening)
sayTo("NATIONAL_PARK","GR_PIERS");done();party,battle=engage(actor("NATIONAL_PARK","GR_PIERS"),"KAREN")
emit("battle.ended",{result="win",battle=battle});world.battleActive=false
check("Piers win",state.beat==110 and karen.name=="KAREN")
sayTo("NATIONAL_PARK","GR_SHOW_ROXIE");select("PLAY ENCORE");finishSet(false,false);done()
check("actual encore recorded",state.first_show.encore and not state.first_show.keepsake)
sayTo("NATIONAL_PARK","GR_SHOW_ROXIE");select("BAND DEBRIEF")
check("park debrief keeps its opener",lastScript.rows[1][2]:find("We made\nour own stage.",1,true)~=nil)
done();press("b")
check("keepsake and departure",state.first_show.keepsake and not findObj("NATIONAL_PARK","GR_SHOW_ROXIE"))
local original=state.first_show.first
-- Sheet 21b: ROXIE lives on ROUTE 36 from beat 30; her first line there is
-- tested in the 21b section, so this one skips it.
state.roxie_r36_heard=true
enter("ROUTE_36");sayTo("ROUTE_36","GR_ROXIE");select("SHORT REPRISE");finishSet(false,false)
check("replay preserves first history",state.first_show.first==original)
sayTo("ROUTE_36","GR_ROXIE");select("FIRST SHOW CARD");mod.game.stack:top():draw();press("b")

-- Old wins and unknown schema.
state.first_show=nil;state.beat=110;enter("NATIONAL_PARK");sayTo("NATIONAL_PARK","GR_SHOW_ROXIE")
check("legacy win keeps unknown history",state.first_show.legacy and state.first_show.first.preparation=="UNRECORDED")
select("PLAY ENCORE");finishSet(false,false);done()
check("legacy encore without fight",state.beat==110 and state.first_show.encore)
state.first_show={schema=99,sentinel=true};enter("ROUTE_36");sayTo("ROUTE_36","GR_ROXIE")
check("future schema untouched",state.first_show.schema==99 and state.first_show.sentinel)
-- Event deferral and no duplicated park cast.
state.first_show=nil;state.beat=90;mod.game.save.bugContest={active=true};enter("NATIONAL_PARK")
check("contest defers park cast",not findObj("NATIONAL_PARK","GR_SHOW_ROXIE"))
mod.game.save.bugContest.active=false;enter("NATIONAL_PARK")
local count=#mapObjects.NATIONAL_PARK;enter("NATIONAL_PARK")
check("no duplicate show actors",#mapObjects.NATIONAL_PARK==count)
-- Crystal carrier alias: actual hook uses the resolved member ID, not index.
state.beat=90;state.first_show=nil;biker.id="KAZU";emit("game.ready",{})
enter("GOLDENROD_UNDERGROUND");sayTo("GOLDENROD_UNDERGROUND","GR_BASEMENT_KING");done()
local king=actor("GOLDENROD_UNDERGROUND","GR_BASEMENT_KING")
emit("world.trainer_engaged",{npc={def=king},trainerClass=20,partyIndex=1})
local base=function() return {{species="RATTATA"}} end
local wrong=wrappers["trainer.party"](base,"BIKER","OTHER",{})
check("same class wrong member unaffected",wrong[1].species=="RATTATA")
local kp=wrappers["trainer.party"](base,"BIKER","KAZU",{})
check("Crystal KAZU accepted",#kp==3 and kp[3].species=="MUK")
enter("VIOLET_CITY");check("abandoned battle restores carrier",biker.name=="KAZU" and world.scriptVars[3]==nil)

-- Four badges and optional mod removal recovery.
mod.game.save.player.badges={a=true,b=true,c=true};enter("NATIONAL_PARK")
check("four badge gate",not findObj("NATIONAL_PARK","GR_SHOW_ROXIE"))
mod.game.save.player.badges.d=true
state.beat=85;emit("game.ready",{});check("missing Contest recovery",state.beat==83)
state.beat=86;emit("game.ready",{});check("missing Court recovery",state.beat==84)

-- Menu abort on save/session switch; do not mark performance complete.
state.beat=90;state.first_show=nil;enter("NATIONAL_PARK");sayTo("NATIONAL_PARK","GR_SHOW_ROXIE");select("SOUNDCHECK")
local abandoned=mod.game.stack:top();emit("game.ready",{})
check("save reload releases owned scene",mod.game.stack:top()~=abandoned and not state.first_show.soundcheck)
-- ROUTE 36 venue: Johto Expanded's two maps now exist. Fresh first show.
local VE,VM="JOHTO_EXPANDED_VENUE_ENTRANCE","JOHTO_EXPANDED_MUSIC_VENUE"
mapObjects[VE],mapObjects[VM]={},{}
world.maps[VE]={objects=mapObjects[VE]};world.maps[VM]={objects=mapObjects[VM]}
local warped
function mod.world:warpTo(mapId,x,y,facing) warped={mapId,x,y,facing};return true end
local function queued() return lastScript and lastScript.rows[1][2] or "" end
for _,k in ipairs({"first_show","busk","show_stage","venue_dragged","venue_met"}) do state[k]=nil end
mod.game.save.player.badges={a=true,b=true,c=true,d=true}
state.beat=84;enter("GOLDENROD_UNDERGROUND");sayTo("GOLDENROD_UNDERGROUND","GR_WHITNEY")
check("no backer: ROXIE says nobody backs us",queued():find("Nobody's\nbacking us yet.",1,true)~=nil)
done();check("hook still assigns the show",state.beat==90)
enter(VE)
check("packed line, no ROXIE before a busk",not findObj(VE,"GR_VENUE_PHONE_ROXIE")
  and findObj(VE,"GR_VENUE_DOOR_R") and #mapObjects[VE]==25)
enter("NATIONAL_PARK");check("park stays empty for a venue show",not findObj("NATIONAL_PARK","GR_SHOW_ROXIE"))
enter("OLIVINE_CITY");sayTo("OLIVINE_CITY","GR_BUSKER_SAILOR");done()
check("first busk plays the ROUTE 36 hook",queued():find("There's a stage on",1,true)~=nil);done()
enter(VE)
local phone=actor(VE,"GR_VENUE_PHONE_ROXIE")
check("ROXIE at the phone",phone.x==8 and phone.y==7)
sayTo(VE,"GR_VENUE_PHONE_ROXIE");check("phone call plays",queued():find("He's here now",1,true)~=nil)
done()
check("ROXIE pulls you to the front",warped and warped[1]==VM and warped[2]==11 and warped[3]==9
  and state.show_stage=="ROUTE 36")
enter(VM)
check("band in the triangle",actor(VM,"GR_SHOW_CASEY").y==2 and actor(VM,"GR_SHOW_ROXIE").x==8
  and actor(VM,"GR_SHOW_WHITNEY").x==12 and actor(VM,"GR_PIERS").y==8)
check("PIERS greets on arrival",queued():find("the manager",1,true)~=nil)
done();check("met PIERS",state.venue_met==true)
enter(VE)
check("lane opens for the manager",not findObj(VE,"GR_VENUE_DOOR_R") and findObj(VE,"GR_VENUE_DOOR_L")
  and not findObj(VE,"GR_VENUE_PHONE_ROXIE") and not world:npcAt(5,3))
enter(VM);sayTo(VM,"GR_PIERS");check("PIERS waits for the encore",queued():find("Save me a",1,true)~=nil);done()
sayTo(VM,"GR_SHOW_ROXIE");select("SOUNDCHECK");finishSet(false,false);done()
sayTo(VM,"GR_SHOW_ROXIE");select("OPENING SET");finishSet(false,true)
check("no 'who asked you' at his own venue",queued():find("Still not",1,true)~=nil);done()
check("venue opening advances",state.beat==100 and state.first_show.first.venue=="ROUTE 36")
sayTo(VM,"GR_PIERS");check("encore ask",queued():find("Told you",1,true)~=nil);done()
party,battle=engage(actor(VM,"GR_PIERS"),"KAREN")
check("PIERS armed at the venue",#party==5)
emit("battle.ended",{result="win",battle=battle});world.battleActive=false
check("venue win",state.beat==110)
sayTo(VM,"GR_SHOW_ROXIE");select("PLAY ENCORE");finishSet(false,false)
check("21b: RYME takes the verse",queued():find("Here's the verse",1,true)~=nil
  and queued():find("we talked about",1,true)~=nil);done()
check("21b: RYME on stage",findObj(VM,"GR_RYME")~=nil)
sayTo(VM,"GR_SHOW_ROXIE");select("BAND DEBRIEF")
check("venue debrief opener",queued():find("First real\nstage. Ours now.",1,true)~=nil);done()
check("card names ROUTE 36",mod.game.stack:top() and state.first_show.keepsake);mod.game.stack:top():draw();press("b")
check("band leaves, crowd stays",not findObj(VM,"GR_SHOW_ROXIE") and findObj(VM,"GR_VENUE_BARTENDER"))

-- A show that opened in the park stays there even with Johto Expanded.
for _,k in ipairs({"first_show","show_stage","venue_dragged","venue_met"}) do state[k]=nil end
state.beat=100;enter("NATIONAL_PARK")
check("park-opened show stays in the park",findObj("NATIONAL_PARK","GR_PIERS") ~= nil)
-- Trainer Journey API 2 (REQUESTS 264): checks, and pay through pending
-- receipts. The first claim is refused ("creation incomplete") and must stay
-- pending; the next map entry pays it once.
local paid, profs, refuseNext = {}, {}, true
installedMods.trainer_journey = { id = "trainer_journey", exports = { trainer_journey = {
  api_version = 2, progression_version = 1,
  registerProfession = function() return true end,
  registerAccomplishment = function() return true end,
  registerSkillReward = function() return true end,
  awardAccomplishment = function(owner, id, stage)
    if refuseNext then return nil, "creation incomplete" end
    paid[#paid + 1] = owner .. "/" .. id .. ":" .. stage; return { awarded = 50 }
  end,
  awardSkillReward = function(owner, id) paid[#paid + 1] = id; return { awarded = 2 } end,
  awardProfessionOnce = function(id, pts, tag) profs[#profs + 1] = id .. "|" .. tag; return { ok = true } end,
  evaluateCheck = function(skill, gate) return { passed = skill == "performance" and gate <= 20 } end,
  leanTradition = function() end, leanInnovation = function() end,
} } }
-- Earlier beats in this run paid with no provider, so they sit pending and
-- the next game.ready pays them (guide section 6: pending until an answer).
check("backlog waits for a provider", state.tj_pending and state.tj_pending["pay:first_busk"])
refuseNext = false; emit("game.ready", {})
check("backlog paid when Trainer Journey appears", next(state.tj_pending) == nil and #paid > 0)
paid, profs = {}, {}; refuseNext = true
for _, k in ipairs({ "first_show", "show_stage", "venue_dragged", "venue_met" }) do state[k] = nil end
state.beat = 0; enter("VIOLET_CITY"); sayTo("VIOLET_CITY", "GR_ROXIE")
-- Sheet 21: the four silent flavour checks are gone; checks are shown.
check("no silent flavour line on ROXIE's intro", queued():find("one they talk", 1, true) == nil)
done(); party, battle = engage(actor("VIOLET_CITY", "GR_ROXIE"), "JANINE")
emit("battle.ended", { result = "win", battle = battle })
check("profession paid on the win", #profs == 1 and profs[1] == "rock_star|gold_records:roxie_battle")
check("refused claim stays pending", #paid == 0 and state.tj_pending["pay:roxie_battle"] == true)
enter("VIOLET_CITY"); check("still refused, still pending", #paid == 0 and state.tj_pending["pay:roxie_battle"])
refuseNext = false; enter("VIOLET_CITY")
check("retry pays the story stage", paid[1] == "gold_records/band_story:hired"
  and next(state.tj_pending) == nil)
enter("VIOLET_CITY"); check("paid once", #paid == 1)
installedMods.trainer_journey = nil; emit("game.ready", {})
-- Sheet 21 (REQUESTS 692/706): the manager decides.
local checkMenu
local function pick(id, passed)            -- Trainer Journey's shown check menu
  local m = assert(checkMenu, "no check menu"); checkMenu = nil
  for _, r in ipairs(m.rows) do if r.id == id then return m.onChoose(r, { passed = passed }) end end
  error("no row " .. id)
end
local function pickWord(word)              -- Crystal's own menu, no Trainer Journey
  local m = assert(lastMenu, "no menu"); lastMenu = nil
  for i, item in ipairs(m.opts.header.items) do if item == word then return m.opts.onChoose(i) end end
  error("no item " .. word)
end
for _, k in ipairs({ "first_show", "show_stage", "venue_dragged", "venue_met", "backers", "backers_closed",
    "first_backer", "whitney_billing", "feedback_way", "sit_in_closed", "roxie_heard_name", "busk" }) do
  state[k] = nil
end
mod.game.save.player.badges = { a = true }

-- 4a, without Trainer Journey: Crystal's own menu asks.
-- Sheet 21b: the first talk after the win, ROXIE plays and RYME walks in.
for i = #mapObjects.VIOLET_CITY, 1, -1 do mapObjects.VIOLET_CITY[i] = nil end
for _, k in ipairs({ "roxie_turn_played", "ryme_met", "roxie_r36_heard", "ryme_r36_heard" }) do state[k] = nil end
state.beat = 20; enter("VIOLET_CITY"); sayTo("VIOLET_CITY", "GR_ROXIE")
check("21b: her turn", queued():find("Cover your ears", 1, true) ~= nil); done()
check("21b: RYME walked in", findObj("VIOLET_CITY", "GR_RYME") ~= nil and state.ryme_met)
check("21b: roof tiles", queued():find("Roof tiles", 1, true) ~= nil); done()
check("4a: the offer is asked", queued():find("How about managing", 1, true) ~= nil); done()
pickWord("NOT YET")
check("4a: NOT YET writes nothing", state.beat == 20 and queued():find("Think fast", 1, true) ~= nil); done()
sayTo("VIOLET_CITY", "GR_RYME")
check("21b: RYME watches", queued():find("I'm hearing how", 1, true) ~= nil); done()
sayTo("VIOLET_CITY", "GR_ROXIE")
check("21b: the turn plays once", queued():find("Cover your ears", 1, true) == nil); done(); pickWord("I'M IN")
check("4a: I'M IN hears the rest", queued():find("You're hired", 1, true) ~= nil); done()
check("21b: a word, not here", queued():find("Too many ears", 1, true) ~= nil
  and queued():find("Find me out there", 1, true) ~= nil); done()
check("4a: hired", state.beat == 30)
enter("VIOLET_CITY"); check("21b: VIOLET is empty", not findObj("VIOLET_CITY", "GR_ROXIE")
  and not findObj("VIOLET_CITY", "GR_RYME"))
enter("ROUTE_36"); check("21b: both on ROUTE 36", findObj("ROUTE_36", "GR_ROXIE") and findObj("ROUTE_36", "GR_RYME"))
sayTo("ROUTE_36", "GR_ROXIE")
check("21b: we talked", queued():find("Don't ask. Later.", 1, true) ~= nil); done()
check("21b: then her reminder", queued():find("FEEDBACK", 1, true) ~= nil); done()
sayTo("ROUTE_36", "GR_RYME"); check("21b: RYME first", queued():find("stays in my head", 1, true) ~= nil); done()
sayTo("ROUTE_36", "GR_RYME")
check("21b: RYME after", queued():find("Then the verse", 1, true) ~= nil); done()
-- REQUESTS 804: once RYME is met, the hall's staff name her as its owner.
enter("JOHTO_EXPANDED_VENUE_ENTRANCE"); sayTo("JOHTO_EXPANDED_VENUE_ENTRANCE", "GR_VENUE_TICKETS")
check("804: TICKETS names RYME", queued():find("RYME's hall", 1, true) ~= nil); done()
enter("JOHTO_EXPANDED_MUSIC_VENUE"); sayTo("JOHTO_EXPANDED_MUSIC_VENUE", "GR_VENUE_BARTENDER")
check("804: BARTENDER names RYME", queued():find("Boss is RYME", 1, true) ~= nil); done()
state.ryme_met = nil; sayTo("JOHTO_EXPANDED_VENUE_ENTRANCE", "GR_VENUE_TICKETS")
check("804: not before she is met", queued():find("RYME", 1, true) == nil); done(); state.ryme_met = true

installedMods.trainer_journey = { id = "trainer_journey", exports = { trainer_journey = {
  api_version = 2, progression_version = 1,
  registerProfession = function() return true end, registerAccomplishment = function() return true end,
  registerSkillReward = function() return true end,
  awardAccomplishment = function() return { awarded = 1 } end, awardSkillReward = function() return { awarded = 1 } end,
  awardProfessionOnce = function() return { ok = true } end,
  leanTradition = function() end, leanInnovation = function() end,
  openCheckMenu = function(opts) checkMenu = opts; return true end,
} } }
emit("game.ready", {})

-- 4b, reaching FEEDBACK under 3 BADGES: [PERFORMANCE 30]; a fail closes it.
-- (Earlier sections left WHITNEY standing there; start the room fresh.)
for i = #mapObjects.GOLDENROD_UNDERGROUND, 1, -1 do mapObjects.GOLDENROD_UNDERGROUND[i] = nil end
enter("GOLDENROD_UNDERGROUND"); sayTo("GOLDENROD_UNDERGROUND", "GR_FEEDBACK"); done()
check("4b: sit-in offered", checkMenu and checkMenu.rows[1].stat == "performance" and checkMenu.rows[1].gate == 30)
pick("sitin", false)
check("4b: sit-in fail closes it", queued():find("Get BADGES", 1, true) ~= nil and state.sit_in_closed); done()
sayTo("GOLDENROD_UNDERGROUND", "GR_FEEDBACK"); done()
check("4b: closed means no menu", checkMenu == nil)
state.sit_in_closed = nil
sayTo("GOLDENROD_UNDERGROUND", "GR_FEEDBACK"); done(); pick("sitin", true)
check("4b: sit-in pass", queued():find("You can follow", 1, true) ~= nil); done()
check("4b: reveal follows at once", state.beat == 40 and queued():find("You got me", 1, true) ~= nil); done()
check("4b: her terms", checkMenu and checkMenu.rows[2].stat == "persuasion" and checkMenu.rows[2].gate == 30)
pick("name", true)
check("4b: wig off", queued():find("name on the bill", 1, true) ~= nil); done()
check("4b: billed as WHITNEY", state.whitney_billing == "WHITNEY" and state.beat == 60
  and state.feedback_way == "sit_in")
enter("ROUTE_36"); sayTo("ROUTE_36", "GR_ROXIE")
check("4b: ROXIE hears it once", queued():find("GYM\nLEADER on bass", 1, true) ~= nil); done()
sayTo("ROUTE_36", "GR_ROXIE")
check("4b: only once", queued():find("GYM\nLEADER", 1, true) == nil); done()

-- 4d, backers: KIMONO GIRLS by [PERFORMANCE 35], RADIO by [PERSUASION 30],
-- the UNDERGROUND for WHITNEY under her own name.
local dancer = { species = "RATTATA", hp = 10, happiness = 70 }; mod.game.save.party = { dancer }
state.beat = 81; enter("DANCE_THEATER"); sayTo("DANCE_THEATER", "GR_DANCE_HOST"); done()
partyPicker.onChoose(1, dancer)
check("4d: showcase is a check", checkMenu and checkMenu.rows[1].gate == 35); pick("dance", true)
check("4d: delight and the backing", queued():find("We will send them", 1, true) ~= nil); done()
check("4d: KIMONO back the band", dancer.happiness == 73 and state.backers.kimono
  and state.first_backer == "kimono" and state.beat == 82)
enter("RADIO_TOWER_1F"); sayTo("RADIO_TOWER_1F", "GR_RADIO_HOST"); done()
check("4d: radio pitch", checkMenu and checkMenu.rows[1].stat == "persuasion"); pick("pitch", true)
check("4d: radio spot", queued():find("Tonight at six", 1, true) ~= nil); done()
check("4d: RADIO backs, stop advances", state.backers.radio and state.beat == 83)
state.beat = 84; enter("GOLDENROD_UNDERGROUND"); sayTo("GOLDENROD_UNDERGROUND", "GR_WHITNEY")
check("4d: UNDERGROUND backs WHITNEY", queued():find("yes if it's me", 1, true) ~= nil
  and queued():find("The dancers", 1, true) ~= nil and queued():find("No way", 1, true) == nil); done()
check("4d: three backers", state.backers.underground and state.beat == 90)

-- The stage needs a backer, not a busk; PIERS never heard them, so he is a stranger.
mod.game.save.player.badges = { a = true, b = true, c = true, d = true }
enter(VE); check("4d: no busk, still the phone", findObj(VE, "GR_VENUE_PHONE_ROXIE") ~= nil)
sayTo(VE, "GR_VENUE_PHONE_ROXIE"); done()
check("4d: stranger PIERS, door knows you", state.venue_met == true)
enter(VM)
check("4d: no stranger at the front", not findObj(VM, "GR_PIERS") and findObj(VM, "GR_SHOW_ROXIE"))
sayTo(VM, "GR_SHOW_ROXIE"); select("SOUNDCHECK"); finishSet(false, false); done()
sayTo(VM, "GR_SHOW_ROXIE"); select("OPENING SET"); finishSet(false, true)
check("4d: stranger crashes", queued():find("Who asked", 1, true) ~= nil)
check("4f: crowd line by first backer", queued():find("So this is rock.", 1, true) ~= nil); done()
check("4b: billed on the record", state.first_show.first.billing == "WHITNEY")
sayTo(VM, "GR_PIERS")
check("4d: fame with two or more backers", queued():find("three towns over", 1, true) ~= nil); done()

-- 4e, the bigger band. Drums: MAYLENE [PERSUASION 25]; a fail closes her.
for _, k in ipairs({ "drummer", "keys", "first_show", "show_stage", "venue_dragged", "venue_met",
    "drum_closed_maylene", "drum_closed_ingo", "larry_asks", "larry_last_visit", "cafe_visits",
    "larry_closed", "elesa_met", "elesa_check_closed", "elesa_first_billing" }) do state[k] = nil end
for i = #mapObjects.DANCE_THEATER, 1, -1 do mapObjects.DANCE_THEATER[i] = nil end
state.beat = 71; enter("DANCE_THEATER")
check("4e: MAYLENE and INGO audition", actor("DANCE_THEATER", "GR_GENE").sprite == "SPRITE_GR_MAYLENE"
  and actor("DANCE_THEATER", "GR_BILLY").sprite == "SPRITE_GR_INGO")
sayTo("DANCE_THEATER", "GR_BILLY"); pick("hire", false)
check("4e: ROXIE overrules", queued():find("my ears", 1, true) ~= nil and state.drum_closed_ingo); done()
sayTo("DANCE_THEATER", "GR_BILLY"); check("4e: closed, no menu", checkMenu == nil); done()
sayTo("DANCE_THEATER", "GR_GENE")
check("4e: hire is a check", checkMenu and checkMenu.rows[1].gate == 25); pick("hire", true)
check("4e: MAYLENE hired", queued():find("won't hold back", 1, true) ~= nil
  and queued():find("CASEY keeps", 1, true) == nil); done()
check("4e: drummer saved, she stays", state.drummer == "maylene" and state.beat == 81
  and findObj("DANCE_THEATER", "GR_GENE") and not findObj("DANCE_THEATER", "GR_CASEY"))

-- Keys: LARRY refuses on two separate visits, then [PERSUASION 30].
state.beat = 83; enter("OLIVINE_CAFE"); sayTo("OLIVINE_CAFE", "GR_LARRY")
check("4e: LARRY no. 1", queued():find("I'm eating", 1, true) ~= nil); done()
sayTo("OLIVINE_CAFE", "GR_LARRY"); check("4e: same visit, no new ask", state.larry_asks == 1); done()
enter("OLIVINE_CAFE"); sayTo("OLIVINE_CAFE", "GR_LARRY")
check("4e: LARRY no. 2", queued():find("I have a shift", 1, true) ~= nil and state.larry_asks == 2); done()
sayTo("OLIVINE_CAFE", "GR_LARRY"); done(); check("4e: third ask waits a visit", checkMenu == nil)
enter("OLIVINE_CAFE"); sayTo("OLIVINE_CAFE", "GR_LARRY"); done()
check("4e: third ask is PERSUASION 30", checkMenu and checkMenu.rows[1].gate == 30); pick("ask", true)
check("4e: LARRY plays", queued():find("lunch hour", 1, true) ~= nil and state.keys == "larry"); done()
enter("RADIO_TOWER_1F"); check("4e: not both", not findObj("RADIO_TOWER_1F", "GR_ELESA"))

-- The show follows the line-up: tags in the soundcheck, the keys on stage,
-- MAYLENE's cues.
state.beat = 90; state.venue_dragged = true; state.venue_met = true; state.show_stage = "ROUTE 36"
for i = #mapObjects[VM], 1, -1 do mapObjects[VM][i] = nil end   -- the 4d band, CASEY's sprite
enter(VM)
check("4e: keys on stage", findObj(VM, "GR_SHOW_KEYS") and findObj(VM, "GR_SHOW_KEYS").sprite == "SPRITE_GR_LARRY"
  and findObj(VM, "GR_SHOW_CASEY").sprite == "SPRITE_GR_MAYLENE")
sayTo(VM, "GR_SHOW_ROXIE"); select("SOUNDCHECK")
local stage = mod.game.stack:top()
check("4e: MAYLENE's cues", stage.steps[1][1] == "MAYLENE: ONE! TWO!" and stage.steps[3][3] == "PLAY LOUD")
finishSet(false, false)
check("4e: soundcheck tags", queued():find("Three\nbeats", 1, true) ~= nil
  and queued():find("in a tie", 1, true) ~= nil and queued():find("broke\na stick", 1, true) ~= nil); done()
sayTo(VM, "GR_SHOW_KEYS"); check("4e: keys stage talk", queued():find("clock out", 1, true) ~= nil); done()

-- ELESA: a failed LIGHTS check leaves first billing open.
state.keys = nil; state.beat = 83; enter("RADIO_TOWER_1F"); sayTo("RADIO_TOWER_1F", "GR_ELESA")
check("4e: ELESA first meeting", queued():find("isn't a show yet", 1, true) ~= nil); done()
pick("lights", false); check("4e: ELESA flat", queued():find("spark", 1, true) ~= nil); done()
sayTo("RADIO_TOWER_1F", "GR_ELESA")
check("4e: later opener", queued():find("isn't a show yet", 1, true) == nil); done()
check("4e: check closed, billing stays", checkMenu.rows[1].id == "bill"); pick("bill", true)
check("4e: ELESA billed first", queued():find("HER name", 1, true) ~= nil and state.keys == "elesa"); done()

-- Bonds (REQUESTS 732): one fact per hire, one per show played together.
state.first_show = { schema = 1, opening = true }
local facts = {}
for _, f in ipairs(mod.exports.getAffinityEvents()) do facts[f.id] = f.character end
check("bonds: hire and show facts", facts["gold_records:hired:maylene"] == "maylene"
  and facts["gold_records:show:elesa"] == "elesa" and not facts["gold_records:hired:casey"])

-- LARRY's gift (REQUESTS 731): at the debrief, once, with the gift jingle.
-- A full bag keeps it, and ROXIE hands it over in VIOLET.
state.keys = "larry"; state.beat = 110
state.first_show = { schema = 1, opening = true, encore = true, victory = true, debrief = false,
  first = { billing = "FEEDBACK", outcome = "HELD THE BEAT" } }
for i = #mapObjects[VM], 1, -1 do mapObjects[VM][i] = nil end
bagFull = true; enter(VM); sayTo(VM, "GR_SHOW_ROXIE"); select("BAND DEBRIEF"); done()
check("gift: LARRY thanks you", queued():find("Nobody does that", 1, true) ~= nil); done()
check("gift: full bag keeps it", not given.LEFTOVERS and state.larry_gift_pending and not state.larry_gift_given)
done(); mod.game.stack.states = {}
bagFull = false; enter("ROUTE_36"); sayTo("ROUTE_36", "GR_ROXIE")
check("gift: ROXIE has it", queued():find("LARRY left", 1, true) ~= nil); done()
check("gift: LEFTOVERS once", given.LEFTOVERS == 1 and state.larry_gift_given
  and lastGift.line:find("LEFTOVERS", 1, true) ~= nil)
sayTo("ROUTE_36", "GR_ROXIE")
-- (No gift left: ROXIE opens her Band Book, which is a screen, not a line.)
check("gift: never twice", queued():find("LARRY left", 1, true) == nil)
lastScript = nil; mod.game.stack.states = {}
installedMods.trainer_journey = nil; emit("game.ready", {})

-- REQUESTS 384: Pokemon in the world are anima-nel colour walkers.
for _, s in ipairs({ "SPRITE_GR_WOOPER", "SPRITE_GR_JIGGLYPUFF" }) do
  local def = registeredSprites[s]
  check(s .. " is anima-nel trueColor", def and def.trueColor == true and def.frames == 6
    and def.image:find("_anima.png", 1, true) ~= nil)
end
print("ALL MOCKED REGRESSIONS PASSED")

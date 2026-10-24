-- Optional Crystal Cutscene livePerformance v1 adapter.
-- Gold Records owns all progress; the provider owns only its temporary scene.
return function(mod, C)
  local API, active, serial = {}, nil, 0
  local instance = {}
  local owner = {}
  mod.exports._livePerformanceOwner = owner
  local function provider()
    local handle = mod.find("crystal_cutscene")
    local api = handle and handle.exports and handle.exports.livePerformance
    if type(api) == "table" and api.version == 1 and type(api.start) == "function" then
      return api
    end
  end
  local function enabled()
    return mod.options:get("cinematic_shows") ~= false
  end
  local function report(message)
    if C.report then C.report("GR CINEMA\n%s", tostring(message)) end
  end
  function API.busy() return active ~= nil end
  function API.cancel(reason)
    local run = active
    if not run then return end
    run.invalidated = true
    if run.handle and type(run.handle.cancel) == "function" then
      local ok, err = pcall(run.handle.cancel, run.handle, reason or "owner_cancelled")
      if not ok then report(err) end
    end
  end
  -- true: this attempt was handled here; false: clean native fallback allowed.
  function API.start(mode, preparation, guard, done)
    if active then return true end
    if not enabled() then return false end
    local found, api = pcall(provider)
    if not found or not api then return false end
    local game = mod.game
    local stackTop = game.stack:top()
    local prep = {sailors=preparation.sailors==true,
      theater=preparation.theater==true, basement=preparation.basement==true}
    serial = serial + 1
    local run = {id="gold_records:"..tostring(instance)..":"..serial, api=api}
    local function valid()
      if run.invalidated or not guard() or not C.permitted() or not enabled() then return false end
      local ownerOk, currentOwner = pcall(mod.find, "gold_records")
      if not ownerOk or not currentOwner or not currentOwner.exports
          or currentOwner.exports._livePerformanceOwner ~= owner then return false end
      local ok, current = pcall(provider)
      return ok and current == api
    end
    local request = {
      version=1, runId=run.id, showId="national_park_first", mode=mode,
      venue="national_park", genre="rock", cueSet="first_show_v1",
      cast={
        {id="roxie",name="ROXIE",spriteId="SPRITE_GR_ROXIE",role="guitar"},
        {id="whitney",name="FEEDBACK",spriteId="SPRITE_WHITNEY",role="bass"},
        {id="casey",name="CASEY",spriteId="SPRITE_LASS",role="drums"},
      },
      spectators={{id="larry",name="LARRY",spriteId="SPRITE_GR_LARRY"}},
      stage={lighting="warm",backdrop="banner",opening="music"},
      preparation={sailors=prep.sailors,theater=prep.theater,basement=prep.basement},
      valid=valid,
    }
    if mode == "opening" then
      request.entrance={id="piers",name="PIERS",spriteId="SPRITE_GR_PIERS"}
    end
    local function retry(status, reason)
      if status == "failed" then report(reason or "Performance failed") end
      C.say({"The set is waiting.","Talk to ROXIE\nto try it again."})
    end
    local function receive(result)
      if run.settled then return end
      run.settled = true
      if active == run then active = nil end
      if not valid() then return end
      if type(result) ~= "table" or result.runId ~= run.id
          or result.showId ~= "national_park_first" or result.mode ~= mode then
        retry("failed", "Mismatched performance result")
        return
      end
      if result.status ~= "completed" then
        retry(result.status, result.reason)
        return
      end
      -- Incomplete cues or an invisible Piers must never advance the chapter.
      local rough = result.rough
      if result.completedCues ~= 3 or type(rough) ~= "number"
          or rough < 0 or rough > 3 or rough % 1 ~= 0
          or (mode == "opening" and result.entranceShown ~= true) then
        retry("failed", "Incomplete performance result")
        return
      end
      -- Keep only the owned, bounded first-show facts. Never save provider
      -- handles, functions, arbitrary strings, or mutable result tables.
      done({rough=rough, billing="FEEDBACK",
        outcome=rough==0 and "HELD THE BEAT" or "FOUND OUR FEET",
        sailors=prep.sailors,theater=prep.theater,basement=prep.basement})
    end
    active = run
    local ok, handle, reason, detail = pcall(api.start, game, request, receive)
    if not ok then
      -- Contract violation: an exception cannot prove that no scene started.
      -- Invalidate its guard; never overlap it with a native performance.
      run.invalidated = true
      if active == run then active = nil end
      report(handle)
      if guard() and game.stack:top() == stackTop then
        C.say({"The stage needs a", "moment. Try again."})
      end
      return true
    end
    if handle == nil then
      if active == run then active = nil end
      if run.settled then return true end
      run.invalidated, run.settled = true, true
      -- v1 guarantees rejection cleaned up and did not call back. Guard the
      -- actual stack too before launching the native screen.
      if guard() and C.permitted() and game.stack:top() == stackTop
          and (reason == "busy" or reason == "invalid" or reason == "unavailable") then
        return false
      end
      report(detail or reason or "Invalid performance rejection")
      return true
    end
    run.handle = handle
    if type(handle) ~= "table" or type(handle.cancel) ~= "function"
        or type(handle.status) ~= "function" then
      run.invalidated = true
      if active == run then active = nil end
      report("Invalid performance handle")
    end
    return true
  end
  return API
end

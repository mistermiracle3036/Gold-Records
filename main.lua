-- Kanto Rocks -- ROXIE (Virbank City gym leader, Pokemon B2/W2, poison
-- punk and frontwoman of "Koffing and the Toxics") is in Kanto trying to
-- get a band together and play one big show. You are her manager: recruit
-- the members, promote the gig, then find out what happens when PIERS
-- (Spikemuth, Pokemon Sword) turns up to crash the encore.
--
-- v0.1.0 IS A SCAFFOLD SLICE. It deliberately registers NO content: no
-- maps, no items, no trainers, no NPCs, no dialogue, no quest. Its only
-- jobs are to load cleanly on the phone, name its own version on screen,
-- and report what Quest System's exports actually look like at runtime.
-- That way, when v0.1.1 puts ROXIE in Vermilion, a load failure can only
-- be ROXIE's fault. Same opening move indigo_conference v0.1.0 used.
--
-- Everything here is written against source read in this working tree --
-- engine/src/mods/Loader.lua and Schemas.lua, engine/src/render/TextBox.lua,
-- engine/src/world/WorldAPI.lua -- or against shipped mods beside it
-- (Pokemon-Snag 0.14.0, Kanto-Contests 0.8.0, Indigo-Plateau-Conference
-- 0.1.0). Anything still unverified is marked TODO/CONFIRM.

return function(mod)
  local VERSION = "0.1.0"
  mod.exports.version = VERSION

  ----------------------------------------------------------------------
  -- Ownership, declared up front even though v0.1.0 registers nothing,
  -- so another mod (or another agent working this tree) can check at
  -- runtime instead of reading a handoff note. Ids get reserved here
  -- first and filled in by the slice that actually registers them.
  --
  -- monFields is the one that matters to the ecosystem today.
  -- kanto_ribbons has NO ribbon-award API: confirmed by reading its
  -- main.lua, whose exports are only { version, hasRibbon, catalog }.
  -- Every ribbon it grants comes from a resolver INSIDE that mod reading
  -- save state -- exactly how it reads snag_quest's mon.snagged and
  -- kanto_contests' mon.contestWins. So the HEADLINER reward is this mod
  -- writing mon.krHeadliner and kanto_ribbons learning to read it later.
  -- Reserved now, first written in v0.5.x. Nothing else may write these.
  ----------------------------------------------------------------------
  mod.exports.owns = {
    maps      = {},   -- v0.4.x: the venue
    tilesets  = {},   -- v0.4.x: the venue's tiles
    trainers  = {},   -- v0.2.x: the drummer; v0.5.x: PIERS
    items     = {},   -- v0.2.x: instruments; v0.3.x: the FLYER
    commands  = {},   -- v0.1.1 onwards
    monFields = { "krHeadliner", "krPiersGift" },
  }

  ----------------------------------------------------------------------
  -- On-screen diagnostics.
  --
  -- mod.log writes to a console that does not exist on iPhone, so
  -- anything the developer has to READ has to be drawn. A TextBox pushed
  -- on the game stack is the channel with the most room. Confirmed from
  -- engine/src/render/TextBox.lua: "\n" is the second line, "\f" is a
  -- page break (wait for A, clear), and paginate() soft-wraps on glyph
  -- boundaries by itself -- so short lines here are belt-and-braces, not
  -- a requirement.
  ----------------------------------------------------------------------
  local function say(msg)
    local ok = pcall(function()
      local TextBox = require("src.render.TextBox")
      local game = mod.world.game
      if not (game and game.stack) then return end
      game.stack:push(TextBox.new(game, msg))
    end)
    if not ok then mod.log:warn("say failed: %s", tostring(msg)) end
  end

  -- Fold a space-separated list onto short lines at word boundaries, so
  -- a long probe result reads as a list instead of one soft-wrapped run.
  local function wrap(text, width)
    local lines, line = {}, ""
    for word in tostring(text):gmatch("%S+") do
      if line == "" then
        line = word
      elseif #line + 1 + #word <= width then
        line = line .. " " .. word
      else
        lines[#lines + 1] = line
        line = word
      end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return table.concat(lines, "\n")
  end

  ----------------------------------------------------------------------
  -- Quest System handshake -- the one open question this mod cannot
  -- answer by reading, so it asks the running game instead.
  --
  -- quest_system's own source is NOT in this working tree. What IS
  -- confirmed is the subset Pokemon-Snag 0.14.0 calls and ships to
  -- device: register(def), advance(id, n), complete(id) -- plus
  -- `markers` as a FIELD of the register() table, NOT a function, and
  -- `status`/`objective` as functions of `game` inside that same table.
  -- `start` and `track` are named in the handoff notes and called by
  -- neither of the mods here, so both are TODO/CONFIRM.
  --
  -- This reports which of the six names are actually functions on the
  -- exports table. One screenshot closes the ledger item, and v0.2.x
  -- gets to use advance() knowing whether start() was needed first.
  ----------------------------------------------------------------------
  local PROBE_NAMES = { "register", "start", "advance", "complete",
                        "track", "markers" }

  local function probeQuestSystem()
    local handle = mod.find("quest_system")
    if not handle then return "NOT INSTALLED" end
    local exports = handle.exports
    if type(exports) ~= "table" then return "NO EXPORTS TABLE" end
    local found = {}
    for _, name in ipairs(PROBE_NAMES) do
      local kind = type(exports[name])
      if kind == "function" then
        found[#found + 1] = name .. "()"
      elseif kind ~= "nil" then
        found[#found + 1] = name .. "=" .. kind
      end
    end
    if #found == 0 then return "EXPORTS EMPTY" end
    return table.concat(found, " ")
  end

  ----------------------------------------------------------------------
  -- Options. Minimal on purpose (the brief's rule): a player-facing row
  -- earns its place only once there is a real choice behind it. The dev
  -- replay toggle arrives with the flags it would clear, in v0.1.1.
  ----------------------------------------------------------------------
  mod.options:define({
    { key = "show_banner", type = "toggle",
      label = "Show load banner", default = true },
  })

  ----------------------------------------------------------------------
  -- Load banner.
  --
  -- NOT on game.ready: Game.lua emits that while nothing is on the stack
  -- yet and pushes the title screen immediately afterwards, so a TextBox
  -- there is discarded -- kanto_contests v0.1 lost its banner to exactly
  -- this and indigo_conference v0.1.0 documents the same trap. The first
  -- map entry of the session is the first moment a box survives.
  ----------------------------------------------------------------------
  local bannerShown = false
  mod.events:on("map.entered", function()
    local ok, err = pcall(function()
      if bannerShown then return end
      if mod.options:get("show_banner") ~= true then return end
      bannerShown = true
      say("KANTO ROCKS\nv" .. VERSION .. " loaded!"
        .. "\fQUEST SYSTEM\n" .. wrap(probeQuestSystem(), 16))
    end)
    if not ok then mod.log:warn("banner failed: %s", tostring(err)) end
  end)

  mod.log:info("kanto_rocks %s loaded", VERSION)
end

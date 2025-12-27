if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end

-- these make sense in global state, they're like singletons.
_G.AssetManager = require("lib.AssetManager")
_G.SceneManager = require("lib.SceneManager")

local Game = require("src.game")
local Program = require("lib.Program")
local ProgramCfg = require("program_cfg")

love.load = function ()
  Program.Setup(ProgramCfg, Game)
end
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end

-- these make sense in global state, they're like singletons.
_G.AssetManager = require("lib.AssetManager")
_G.Settings = require("lib.Settings")
_G.AudioManager = require("lib.AudioManager")
_G.SceneManager = require("lib.SceneManager")
_G.Scenes = require("src.scenes")
_G.DEBUG_UI = false

local Game = require("src.game")
local Program = require("lib.Program")
local ProgramCfg = require("program_cfg")

love.load = function ()
  Program.Setup(ProgramCfg, Game)
end
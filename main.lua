if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end

_G.DEBUG_UI = false
_G.__NOOP__ = function (...) return nil end
-- these make sense in global state, they're like singletons.
_G.AssetManager = require("lib.AssetManager") ; AssetManager.load_assets()
_G.InputManager = require("lib.InputManager")
_G.UI = require("lib.ui")
_G.CONFIG = require("program_cfg")
_G.Settings = require("lib.Settings")
_G.AudioManager = require("lib.AudioManager")
_G.SceneManager = require("lib.SceneManager")
_G.Scenes = require("src.scenes.scenes")

local Game = require("src.game")
local Program = require("lib.Program")

love.load = function ()
  Program.Setup(_G.CONFIG, Game)
end
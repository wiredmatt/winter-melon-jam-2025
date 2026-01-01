local inputmap = require("src.scenes.Settings.inputmap")
local SoundPoolPicker = require("lib.SoundPoolPicker")

local actions = inputmap.actions
local bindings = inputmap.bindings

---@class SettingsScene : Scene
local SettingsScene = {
    name = "Settings",
}

SettingsScene.Enter = function(self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, bindings)
    InputManager.SetActiveMap(self.name)

    local tiny5_8px_font = AssetManager.assets.fonts.Tiny5_ttf[8]
    tiny5_8px_font:setFilter("nearest", "nearest")
end

SettingsScene.HandleInput = function(self, dt)
end

SettingsScene.Update = function(self, dt)
    self:HandleInput(dt)
end

SettingsScene.Draw = function(self)
end

SettingsScene.Exit = function(self) end

return SettingsScene

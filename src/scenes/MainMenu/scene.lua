local inputmap = require("src.scenes.MainMenu.inputmap")

local SoundPoolPicker = require "lib.SoundPoolPicker"
---@class MainMenuScene : Scene
local MainMenuScene = {
    name = "MainMenu",
    transition_in = SceneManager.Transitions.DiagonalOut.New({
        w = CONFIG.virtual_cfg.width,
        h = CONFIG.virtual_cfg.height
    }),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = inputmap
}

MainMenuScene.Enter = function(self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)
    AudioManager.PlayMusic(AssetManager.assets.music.menu_wav, true)
end

MainMenuScene.HandleInput = function(self, dt)
end

MainMenuScene.Update = function(self, dt)
    self:HandleInput(dt)
end

MainMenuScene.Draw = function(self)
end

MainMenuScene.Exit = function(self) end

return MainMenuScene

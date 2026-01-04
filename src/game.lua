---@type IGame
local Game = {}

Game.Load = function (self)
    Settings.Load()
    Settings.ApplyVideoSettings()
    AudioManager.Init(Settings.current.audio)
    AudioManager.Init()

    SoundPoolPicker.RegisterPool("click", {
        AssetManager.assets.sfx.click1_wav
    })

    SceneManager.RegisterAll(Scenes)
    SceneManager.SwitchTo(Scenes.MainMenu)
end

Game.Draw = function (self)
    SceneManager.Draw()
end

Game.Update = function (self, dt)
    SceneManager.Update(dt)
    SceneGraph.PluginManager.Update(dt)
end

return Game
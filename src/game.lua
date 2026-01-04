---@type IGame
local Game = {}

Game.Load = function (self)
    -- Settings.Load()
    -- Settings.ApplyVideoSettings()
    -- AudioManager.Init(Settings.current.audio)
    AudioManager.Init()

    local SoundPoolPicker = require("lib.SoundPoolPicker")
    if AssetManager.assets.sfx then
        local click_sounds = {}
        table.insert(click_sounds, AssetManager.assets.sfx.click1_wav)
        -- todo add more click sounds for variety
        if #click_sounds > 0 then
            SoundPoolPicker.RegisterPool("click", click_sounds)
        end
    end

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
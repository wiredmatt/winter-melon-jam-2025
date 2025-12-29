---@type IGame
local Game = {}

Game.Load = function (self)
    Settings.Load()
    Settings.ApplyVideoSettings()
    AudioManager.Init(Settings.current.audio)

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
end

Game.MouseMoved = function (self, x, y, dx, dy, istouch, rawx, rawy, rawdx, rawdy)
    if SceneManager.current.root_node then
        SceneManager.current.root_node:HandleMouseMoved(x, y, dx, dy)
    end
end

Game.MousePressed = function (self, x, y, button, istouch, presses, rawx, rawy)
    if SceneManager.current.root_node then
        SceneManager.current.root_node:HandleMousePressed(x, y, button)
    end
end

Game.MouseReleased = function (self, x, y, button, istouch, presses, rawx, rawy)
    if SceneManager.current.root_node then
        SceneManager.current.root_node:HandleMouseReleased(x, y, button)
    end
end

Game.KeyPressed = function (self, key, scancode, isrepeat)
    if key == "g" then
        DEBUG_UI = not DEBUG_UI
        print("[Debug] UI Debug Mode: " .. (DEBUG_UI and "ON" or "OFF"))
    end
end

return Game
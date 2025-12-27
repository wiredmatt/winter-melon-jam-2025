local Scenes = require "src.scenes"

---@type IGame
local Game = {}

Game.Load = function (self)
    AssetManager.Load()
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
    if SceneManager.current and SceneManager.current.root_node then
        SceneManager.current.root_node:HandleMouseMoved(x, y, dx, dy)
    end
end

Game.MousePressed = function (self, x, y, button, istouch, presses, rawx, rawy)
    if SceneManager.current and SceneManager.current.root_node then
        SceneManager.current.root_node:HandleMousePressed(x, y, button)
    end
end

Game.MouseReleased = function (self, x, y, button, istouch, presses, rawx, rawy)
    if SceneManager.current and SceneManager.current.root_node then
        SceneManager.current.root_node:HandleMouseReleased(x, y, button)
    end
end

return Game
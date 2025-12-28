---@class GameplayScene : Scene
local GameplayScene = {
    name = "Gameplay",
}

GameplayScene.Enter = function (self)
    if Settings.current.flags.intro_seen then
        SceneManager.SwitchTo(Scenes.Battle)
    else
        SceneManager.SwitchTo(Scenes.Intro)
    end
end

GameplayScene.Draw = function (self) end

GameplayScene.Update = function (self, dt) end

GameplayScene.Exit = function (self) end

return GameplayScene
local inputmap = require("src.scenes.LoseFight.inputmap")

---@class LoseFightScene : Scene
local LoseFightScene = {
    name = "LoseFight",
    inputmap = inputmap
}

LoseFightScene.Enter = function(self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)

    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")
end

LoseFightScene.Draw = function(self)
end

LoseFightScene.HandleInput = function(self)
    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        SceneManager.SwitchTo(Scenes.Battle)
    end
end

LoseFightScene.Update = function(self, dt)
    self:HandleInput()
end

LoseFightScene.Exit = function(_)
end

return LoseFightScene

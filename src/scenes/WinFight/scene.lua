local inputmap = require("src.scenes.WinFight.inputmap")

---@class WinFightScene : Scene
local WinFightScene = {
    name = "WinFight",
    inputmap = inputmap,
}

WinFightScene.Enter = function(self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)

    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")
end

WinFightScene.Draw = function(self)
end

WinFightScene.HandleInput = function(self)
    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        SceneManager.SwitchTo(Scenes.MainMenu)
    end
end

WinFightScene.Update = function(self, dt)
    self:HandleInput()
end

WinFightScene.Exit = function(_)
end

return WinFightScene

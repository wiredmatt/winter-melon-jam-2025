local BattleManager = require("src.scenes.Battle.BattleManager")

---@class WinFightScene : Scene
local WinFightScene = {
    name = "WinFight",
    inputmap = require("src.scenes.WinFight.inputmap"),
}

WinFightScene.Enter = function (self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)

    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")

    self.root_node = UI.Node.New()

    self.root_node:AddChild(
        UI.Label.New({
            text = "VICTORY!",
            font = tiny5_16px_font,
            x = CONFIG.virtual_cfg.width / 2 - 50,
            y = CONFIG.virtual_cfg.height / 2 - 60,
            color = {1, 1, 0, 1}
        })
    )

    self.root_node:AddChild(
        UI.Label.New({
            text = "You've reclaimed all five masks.",
            font = tiny5_16px_font,
            x = CONFIG.virtual_cfg.width / 2 - 120,
            y = CONFIG.virtual_cfg.height / 2 - 20,
            color = {1, 1, 1, 1}
        })
    )

    self.continue_prompt = UI.Label.New({
        text = "[Press SPACE to return to menu]",
        font = tiny5_16px_font,
        x = CONFIG.virtual_cfg.width / 2 - 120,
        y = CONFIG.virtual_cfg.height / 2 + 20,
        color = {0.7, 0.7, 0.7, 1}
    })
    self.root_node:AddChild(self.continue_prompt)
end

WinFightScene.Draw = function (self)
    self.root_node:Draw()
end

WinFightScene.HandleInput = function (self)
    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        BattleManager.Reset()
        SceneManager.SwitchTo(Scenes.MainMenu)
    end
end

WinFightScene.Update = function (self, dt)
    self:HandleInput()

    if self.continue_prompt then
        local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
        self.continue_prompt.color[4] = alpha
    end
end

WinFightScene.Exit = function (_)
end

return WinFightScene
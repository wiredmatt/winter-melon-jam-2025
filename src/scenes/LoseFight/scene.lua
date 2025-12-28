local BattleManager = require("src.scenes.Battle.BattleManager")

---@class LoseFightScene : Scene
local LoseFightScene = {
    name = "LoseFight",
    inputmap = require("src.scenes.LoseFight.inputmap"),
    ---@type nil|Label
    continue_prompt = nil
}

LoseFightScene.Enter = function (self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)

    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")

    self.root_node = UI.Node.New()

    self.root_node:AddChild(
        UI.Label.New({
            text = "DEFEATED",
            font = tiny5_16px_font,
            x = CONFIG.virtual_cfg.width / 2 - 50,
            y = CONFIG.virtual_cfg.height / 2 - 60,
            color = {1, 0, 0, 1}
        })
    )

    self.root_node:AddChild(
        UI.Label.New({
            text = "You were not strong enough...",
            font = tiny5_16px_font,
            x = CONFIG.virtual_cfg.width / 2 - 120,
            y = CONFIG.virtual_cfg.height / 2 - 20,
            color = {1, 1, 1, 1}
        })
    )

    self.continue_prompt = UI.Label.New({
        text = "[Press SPACE to retry]",
        font = tiny5_16px_font,
        x = CONFIG.virtual_cfg.width / 2 - 90,
        y = CONFIG.virtual_cfg.height / 2 + 20,
        color = {0.7, 0.7, 0.7, 1}
    })
    self.root_node:AddChild(self.continue_prompt)
end

LoseFightScene.Draw = function (self)
    self.root_node:Draw()
end

LoseFightScene.HandleInput = function (self)
    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        BattleManager.Reset()
        SceneManager.SwitchTo(Scenes.Battle)
    end
end

LoseFightScene.Update = function (self, dt)
    self:HandleInput()

    if self.continue_prompt then
        local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
        self.continue_prompt.color[4] = alpha
    end
end

LoseFightScene.Exit = function (_)
end

return LoseFightScene
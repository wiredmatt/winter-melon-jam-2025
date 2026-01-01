local inputmap = require("src.scenes.Battle.inputmap")

---@class BattleScene : Scene
---@field state string current battle state
---@field battle_config BattleConfig current battle config
local BattleScene = {
    name = "Battle",
    transition_in = SceneManager.Transitions.FadeIn.New(),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = inputmap,
}

BattleScene.Enter = function(self)
end

BattleScene.HandleInput = function(self)
end

BattleScene.Update = function(self, dt)
end

BattleScene.Draw = function(self)
end

BattleScene.Exit = function(self)
end

return BattleScene

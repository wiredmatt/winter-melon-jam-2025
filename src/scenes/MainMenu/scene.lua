local inputmap = require("src.scenes.MainMenu.inputmap")
local SceneGraph = require("lib.SceneGraph")

local SoundPoolPicker = require("lib.SoundPoolPicker")

---@class MainMenuScene : Scene
local MainMenuScene = {
    name = "MainMenu",
    -- transition_in = SceneManager.Transitions.DiagonalOut.New({
    --     w = CONFIG.virtual_cfg.width,
    --     h = CONFIG.virtual_cfg.height
    -- }),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = inputmap,
    ---@type BaseNode
    root_node = nil
}

MainMenuScene.Enter = function(self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)
    AudioManager.PlayMusic(AssetManager.assets.music.menu_wav, true)

    self.root_node = SceneGraph.Nodes.BaseNode.New()

    local btn_node_1 = SceneGraph.Nodes.BaseNode.New({
        x = 0,
        y = 0,
        width = 32,
        height = 32
    })
    SceneGraph.Graphics.On(btn_node_1).Add(
        SceneGraph.Graphics.Rect.New({
            color = { 100/255, 149/255, 237/255, 1},
            mode = "fill",
        })
    )
    SceneGraph.Plugins.MouseInput.InstallTo(btn_node_1).OnMouseDown(function (_, x, y, btn)
        print("btn1", x, y, btn)
    end)

    local btn_node_2 = SceneGraph.Nodes.BaseNode.New({
        x = 60,
        y = 0,
        width = 32,
        height = 32
    })
    SceneGraph.Graphics.On(btn_node_2).Add(
        require("lib.SceneGraph.Graphics.Rect").New({
            color = { 100/255, 149/255, 237/255, 1},
            mode = "line",
        })
    )
    SceneGraph.Plugins.MouseInput.InstallTo(btn_node_2).OnMouseDown(function (_, x, y, btn)
        print("btn2", x, y, btn)
    end)

    self.root_node:AddChild(btn_node_1)
    self.root_node:AddChild(btn_node_2)
end

MainMenuScene.HandleInput = function(self, dt)
end

MainMenuScene.Update = function(self, dt)
    self.root_node:Update(dt)
    SceneGraph.Update(dt)
end

MainMenuScene.Draw = function(self)
    love.graphics.clear()
    self.root_node:Draw()
end

MainMenuScene.Exit = function(self) end

return MainMenuScene

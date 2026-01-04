local inputmap = require("src.scenes.MainMenu.inputmap")

---@class MainMenuScene : Scene
---@field layers LayerManager
---@field ui_layer Layer
local MainMenuScene = {
    name = "MainMenu",
    -- transition_in = SceneManager.Transitions.DiagonalOut.New({
    --     w = CONFIG.virtual_cfg.width,
    --     h = CONFIG.virtual_cfg.height
    -- }),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = inputmap,
    ---@type SpriteDrawable
    icon = nil
}

MainMenuScene.Enter = function(self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)
    AudioManager.PlayMusic(AssetManager.assets.music.menu_wav, true)

    self.layers = SceneGraph.LayerManager.New()
    self.ui_layer = SceneGraph.Layer.New({
        name = "ui",
        render_order = 100
    })
    self.layers:Add(self.ui_layer)

    local start_button = SceneGraph.Nodes.BaseNode.New({
        x = 60,
        y = 10,
        width = 200,
        height = 100
    })

    SceneGraph.Graphics.On(start_button)
        :Add(SceneGraph.Graphics.Rect.New({
            color = { 100/255, 149/255, 237/255, 1},
            mode = "fill",
        }), "border")
        :Add(SceneGraph.Graphics.Rect.New({
            color = { 100/255, 149/255, 237/255, 1},
            mode = "line",
        }), "border")
    SceneGraph.Plugins.Input.InstallTo(start_button)
        .OnActivate(function(_, x, y, btn)
            SceneManager.SwitchTo(Scenes.Gameplay)
        end)
        .OnFocus(function(_)
            print("[btn_node_1] focused!")
        end)
        .OnHover(function (_)
            print("[btn_node_1] hovering")
        end)
        .OnBlur(function(_)
            print("[btn_node_1] blurred!")
        end)

    self.ui_layer:AddChild(start_button)
end

MainMenuScene.HandleInput = function(self, _dt)
    local actions = self.inputmap.actions

    if InputManager.JustPressed(actions.UP) then
        SceneGraph.Plugins.Input.Navigate("up")
    elseif InputManager.JustPressed(actions.DOWN) then
        SceneGraph.Plugins.Input.Navigate("down")
    elseif InputManager.JustPressed(actions.LEFT) then
        SceneGraph.Plugins.Input.Navigate("left")
    elseif InputManager.JustPressed(actions.RIGHT) then
        SceneGraph.Plugins.Input.Navigate("right")
    end

    if InputManager.JustPressed(actions.CONFIRM) then
        SceneGraph.Plugins.Input.Confirm()
    end
end

local k = 1

MainMenuScene.Update = function(self, dt)
    self:HandleInput(dt)
    self.layers:Update(dt)
end

MainMenuScene.Draw = function(self)
    self.layers:Draw()
end

MainMenuScene.Exit = function(self)
    self.layers:Destroy()
end

return MainMenuScene

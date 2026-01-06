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

    local f = AssetManager.assets.fonts.Tiny5_ttf[16]
    f:setFilter("nearest", "nearest")

    self.layers = SceneGraph.LayerManager.New()
    self.ui_layer = SceneGraph.Layer.New({
        name = "ui",
        render_order = 100
    })
    self.layers:Add(self.ui_layer)

    local play_button = SceneGraph.Nodes.BaseNode.New({
        x = 110,
        y = 60,
        width = 100,
        height = 30
    })

    SceneGraph.Graphics.On(play_button)
        :Add(SceneGraph.Graphics.Rect.New({
            color = { 100/255, 149/255, 237/255, 1},
            mode = "fill",
        }), "fill")
        :Add(SceneGraph.Graphics.Rect.New({
            color = { 100/255, 149/255, 237/255, 1},
            mode = "line",
        }), "border")
        :Add(SceneGraph.Graphics.Text.New({
            text = "Play",
            font = f,
            x = 0,
            y = 0,
            color = {1, 1, 1, 1},
            align = "center",
            valign = "middle",
            shadow = { x = 2, y = 2, color = {0, 0, 0, 0.5} },
        }), "label")
    SceneGraph.Plugins.Input.InstallTo(play_button)
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

    self.ui_layer:AddChild(play_button)
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

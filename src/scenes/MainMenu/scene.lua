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
}

MainMenuScene.Enter = function(self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)
    -- AudioManager.PlayMusic(AssetManager.assets.music.menu_wav, true)

    local f = AssetManager.assets.fonts.Tiny5_ttf[16]
    f:setFilter("nearest", "nearest")

    self.layers = SceneGraph.LayerManager.New()
    self.ui_layer = SceneGraph.Layer.New({
        name = "ui",
        render_order = 100
    })
    self.layers:Add(self.ui_layer)

    -- Create play button using new component system
    local play_button = SceneGraph.Node.New({
        x = 110,
        y = 60,
        width = 100,
        height = 30,
        ox = 50,
        oy = 15
    })
    :AddComponent(SceneGraph.Components.Input.New())
    :On("Activate", function()
        InputManager.UnsetActiveMap()
        SceneManager.SwitchTo(Scenes.Gameplay)
    end)
    :AddComponent(SceneGraph.Components.Rect.New({
        color = { 100/255, 149/255, 237/255, 1},
        mode = "fill",
        ox = 50,
        oy = 15
    }))
    :AddComponent(SceneGraph.Components.Rect.New({
        color = { 100/255, 149/255, 237/255, 1},
        mode = "line",
        ox = 50,
        oy = 15
    }))
    :AddComponent(SceneGraph.Components.Text.New({
        text = "Play",
        font = f,
        color = { 1, 1, 1, 1 },
        shadow = { x = 1, y = 1, color = {0, 0, 0, 0.5} },
        align = "center",
        valign = "middle",
        ox = 50,
        oy = 15
    }))
    :AddComponent(SceneGraph.Components.HoverColor.New({
        on_enter_color = { 1, 0.3, 1, 1 },
        target_components = { "Rect" }
    }))
    :AddComponent(SceneGraph.Components.HoverScale.New({
        on_enter_scale = 1.1,
        step = 0.05,
        target_components = { "Rect" },
    }))

    self.ui_layer:AddChild(play_button)
end

MainMenuScene.HandleInput = function(self, _dt)
    local actions = self.inputmap.actions

    if InputManager.JustPressed(actions.UP) then
        SceneGraph.InputPlugin.Navigate("up")
    elseif InputManager.JustPressed(actions.DOWN) then
        SceneGraph.InputPlugin.Navigate("down")
    elseif InputManager.JustPressed(actions.LEFT) then
        SceneGraph.InputPlugin.Navigate("left")
    elseif InputManager.JustPressed(actions.RIGHT) then
        SceneGraph.InputPlugin.Navigate("right")
    end

    if InputManager.JustPressed(actions.CONFIRM) then
        SceneGraph.InputPlugin.Activate()
    end
end

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

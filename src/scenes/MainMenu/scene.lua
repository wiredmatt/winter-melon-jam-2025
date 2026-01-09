local MainMenuInputMap = require("src.scenes.MainMenu.inputmap")
local MainMenuGUI = require("src.scenes.MainMenu.gui")

---@class MainMenuScene : Scene
---@field layers LayerManager
---@field ui_layer Layer
local MainMenuScene = {
    name = "MainMenu",
    transition_in = SceneManager.Transitions.DiagonalOut.New({
        w = CONFIG.virtual_cfg.width,
        h = CONFIG.virtual_cfg.height
    }),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = MainMenuInputMap,
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

    MainMenuGUI.Build(self.ui_layer)
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

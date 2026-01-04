local inputmap = require("src.scenes.MainMenu.inputmap")
local SceneGraph = require("lib.SceneGraph")
local CHARACTERS = require("data.characters")

---@class MainMenuScene : Scene
---@field layers LayerManager
---@field ui_layer Layer
---@field btn_node_1 BaseNode
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

    -- todo: make ox and oy work with 0.0 - 1.0? or just use anchors instead
    local btn_node_1 = SceneGraph.Nodes.BaseNode.New({
        x = 60,
        y = 60,
        width = 32,
        height = 32,
        ox = 32/2,
        oy = 32/2
    })
    local _,_, pw, ph = CHARACTERS.Player.sprite_quad:getViewport()
    CHARACTERS.Player.sprite_image:setFilter("nearest")

    SceneGraph.Graphics.On(btn_node_1)
        :Add(SceneGraph.Graphics.Rect.New({
            color = { 100/255, 149/255, 237/255, 1},
            mode = "line",
        }), "border")
        :Add(SceneGraph.Graphics.Sprite.New(
            CHARACTERS.Player.sprite_image,
            CHARACTERS.Player.sprite_quad,
            {
                x = pw/2,
                y = ph/2,
                r = math.rad(90),
                ox = pw/2,
                oy = ph/2
            }
        ), "icon")
    SceneGraph.Plugins.MouseInput.InstallTo(btn_node_1).OnMouseDown(function (_, x, y, btn)
        print("btn1", x, y, btn)
    end)

    self.ui_layer:AddChild(btn_node_1)
    self.btn_node_1 = btn_node_1
    self.icon = self.btn_node_1.graphics:Get("icon") --[[@as SpriteDrawable]]
end

MainMenuScene.HandleInput = function(_self, _dt)
end

MainMenuScene.Update = function(self, dt)
    self.layers:Update(dt)

    if self.btn_node_1.sx <= 3 then
        self.btn_node_1:SetScale(self.btn_node_1.sx + 1 * dt)
    end

    self.icon.r = self.icon.r + math.rad(1)
end

MainMenuScene.Draw = function(self)
    love.graphics.clear()
    self.layers:Draw()
end

MainMenuScene.Exit = function(self)
    self.layers:Destroy()
end

return MainMenuScene

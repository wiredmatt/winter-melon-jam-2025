local SoundPoolPicker = require "lib.SoundPoolPicker"
---@class MainMenuScene : Scene
local MainMenuScene = {
    name = "MainMenu",
    transition_in = SceneManager.Transitions.DiagonalOut.New({
        w = CONFIG.virtual_cfg.width,
        h = CONFIG.virtual_cfg.height
    }),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = require("src.scenes.MainMenu.inputmap")
}

MainMenuScene.Enter = function (self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)
    AudioManager.PlayMusic(AssetManager.assets.music.menu_wav, true)
    self:BuildGUI()
end

MainMenuScene.BuildGUI = function (self)
    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")

    self.root_node = UI.Node.New()

    local title = UI.Label.New({
        x = 60,
        y = 10,
        width = 200,
        text = CONFIG.window_cfg.title,
        align = "center",
        color = {1, 1, 1, 1},
        font = tiny5_16px_font
    })
    self.root_node:AddChild(title)

    local start_button = UI.Button.New({
        x = 110,
        y = 60,
        width = 100,
        height = 30,
        text = "Play",
        font = tiny5_16px_font,
        focusable = true
    })
    start_button.OnClick = function()
        SoundPoolPicker.Play("click")
        SceneManager.SwitchTo(Scenes.Gameplay)
    end

    self.root_node:AddChild(start_button)

    local options_button = UI.Button.New({
        x = 110,
        y = 100,
        width = 100,
        height = 30,
        text = "Settings",
        font = tiny5_16px_font,
        focusable = true
    })
    options_button.OnClick = function()
        SoundPoolPicker.Play("click")
        SceneManager.SwitchTo(Scenes.Settings, SceneManager.Transitions.NONE, SceneManager.Transitions.NONE)
    end
    self.root_node:AddChild(options_button)

    local quit_button = UI.Button.New({
        x = 110,
        y = 140,
        width = 100,
        height = 30,
        text = "Quit",
        font = tiny5_16px_font,
        focusable = true
    })
    quit_button.OnClick = function()
        love.event.quit()
    end
    self.root_node:AddChild(quit_button)
end

local input_cooldown = 0
local AXIS_THRESHOLD = 0.5
local INPUT_COOLDOWN_TIME = 0.2

MainMenuScene.HandleInput = function (self, dt)
    input_cooldown = input_cooldown - dt

    local dx, dy = 0, 0
    local has_input = false

    if input_cooldown <= 0 then
        if InputManager.IsDown(self.inputmap.actions.UP) then
            dy = -1
            has_input = true
        elseif InputManager.IsDown(self.inputmap.actions.DOWN) then
            dy = 1
            has_input = true
        end

        if InputManager.IsDown(self.inputmap.actions.LEFT) then
            dx = -1
            has_input = true
        elseif InputManager.IsDown(self.inputmap.actions.RIGHT) then
            dx = 1
            has_input = true
        end

        if not has_input then
            local axis_x = InputManager.GetValue(self.inputmap.actions.HORIZONTAL)
            local axis_y = InputManager.GetValue(self.inputmap.actions.VERTICAL)

            if math.abs(axis_x) > AXIS_THRESHOLD then
                dx = axis_x > 0 and 1 or -1
                has_input = true
            elseif math.abs(axis_y) > AXIS_THRESHOLD then
                dy = axis_y > 0 and 1 or -1
                has_input = true
            end
        end

        -- apply navigation
        if has_input then
            input_cooldown = INPUT_COOLDOWN_TIME
            self.root_node:FocusDirection(dx, dy)
        end
    end

    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        self.root_node:ActivateFocused()
    end
end

MainMenuScene.Update = function (self, dt)
    self:HandleInput(dt)
    self.root_node:Update(dt)
end

MainMenuScene.Draw = function (self)
    self.root_node:Draw()
end

MainMenuScene.Exit = function (self) end

return MainMenuScene
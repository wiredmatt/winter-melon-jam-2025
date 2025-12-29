local Node = require("lib.ui.Node")
local SettingsPanel = require("src.ui.SettingsPanel")
local inputmap = require("src.scenes.Settings.inputmap")
local SoundPoolPicker = require("lib.SoundPoolPicker")

local actions = inputmap.actions
local bindings = inputmap.bindings

---@class SettingsScene : Scene
local SettingsScene = {
    name = "Settings",
    ---@type SettingsPanel
    settings_panel = nil
}

local input_cooldown = 0
local AXIS_THRESHOLD = 0.5
local INPUT_COOLDOWN_TIME = 0.2
local SLIDER_COOLDOWN_TIME = 0.05
local SLIDER_STEP = 0.01

SettingsScene.Enter = function (self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, bindings)
    InputManager.SetActiveMap(self.name)

    local tiny5_8px_font = AssetManager.assets.fonts.Tiny5_ttf[8]
    tiny5_8px_font:setFilter("nearest", "nearest")

    self.root_node = Node.New()

    self.settings_panel = SettingsPanel.New({
        x = 0,
        y = 0,
        font = tiny5_8px_font,
        show_title = true,
        on_back = function()
            SceneManager.SwitchTo(Scenes.MainMenu, SceneManager.Transitions.NONE, SceneManager.Transitions.NONE)
        end
    })
    self.root_node:AddChild(self.settings_panel)
end

SettingsScene.HandleInput = function (self, dt)
    input_cooldown = input_cooldown - dt

    local focused = self.root_node:GetFocused()

    if focused and input_cooldown <= 0 then
        -- slider
        if focused.SetValue and focused.GetValue then
            focused = focused --[[@as Slider]]
            local slider_input_handled = false

            if InputManager.IsDown(actions.LEFT) then
                SoundPoolPicker.Play("click")
                local new_value = math.max(focused.min or 0, focused.value - SLIDER_STEP)
                focused:SetValue(new_value)
                slider_input_handled = true
            elseif InputManager.IsDown(actions.RIGHT) then
                SoundPoolPicker.Play("click")
                local new_value = math.min(focused.max or 1, focused.value + SLIDER_STEP)
                focused:SetValue(new_value)
                slider_input_handled = true
            else
                local axis_x = InputManager.GetValue(actions.HORIZONTAL)
                if math.abs(axis_x) > AXIS_THRESHOLD then
                    SoundPoolPicker.Play("click")
                    local new_value = focused.value + (axis_x * SLIDER_STEP)
                    new_value = math.max(focused.min or 0, math.min(focused.max or 1, new_value))
                    focused:SetValue(new_value)
                    slider_input_handled = true
                end
            end

            if slider_input_handled then
                input_cooldown = SLIDER_COOLDOWN_TIME
                return
            end
        end

        -- checkbox
        if focused.Toggle and focused.checked ~= nil then
            focused = focused --[[@as Checkbox]]
            if InputManager.JustPressed(actions.CONFIRM) then
                SoundPoolPicker.Play("click")
                focused:Toggle()
                input_cooldown = INPUT_COOLDOWN_TIME
                return
            end
        end
    end

    -- nav
    if input_cooldown <= 0 then
        local dx, dy = 0, 0
        local has_input = false

        if InputManager.IsDown(actions.UP) then
            dy = -1
            has_input = true
        elseif InputManager.IsDown(actions.DOWN) then
            dy = 1
            has_input = true
        end

        if InputManager.IsDown(actions.LEFT) then
            dx = -1
            has_input = true
        elseif InputManager.IsDown(actions.RIGHT) then
            dx = 1
            has_input = true
        end

        if not has_input then
            local axis_x = InputManager.GetValue(actions.HORIZONTAL)
            local axis_y = InputManager.GetValue(actions.VERTICAL)

            if math.abs(axis_x) > AXIS_THRESHOLD then
                dx = axis_x > 0 and 1 or -1
                has_input = true
            elseif math.abs(axis_y) > AXIS_THRESHOLD then
                dy = axis_y > 0 and 1 or -1
                has_input = true
            end
        end

        if has_input then
            input_cooldown = INPUT_COOLDOWN_TIME
            self.root_node:FocusDirection(dx, dy)
        end
    end

    if InputManager.JustPressed(actions.CONFIRM) then
        self.root_node:ActivateFocused()
    end

    if InputManager.JustPressed(actions.BACK) then
        SceneManager.SwitchTo(Scenes.MainMenu, SceneManager.Transitions.NONE, SceneManager.Transitions.NONE)
    end

    -- tab
    if self.settings_panel and self.settings_panel.tab_container then
        local tab_container = self.settings_panel.tab_container

        if InputManager.JustPressed(actions.PREV_TAB) then
            SoundPoolPicker.Play("click")
            local new_index = tab_container.active_tab_index - 1
            if new_index < 1 then
                new_index = #tab_container.tabs
            end
            tab_container:SetActiveTab(new_index)
        elseif InputManager.JustPressed(actions.NEXT_TAB) then
            SoundPoolPicker.Play("click")
            local new_index = tab_container.active_tab_index + 1
            if new_index > #tab_container.tabs then
                new_index = 1
            end
            tab_container:SetActiveTab(new_index)
        end
    end
end

SettingsScene.Update = function (self, dt)
    self:HandleInput(dt)
    self.root_node:Update(dt)
end

SettingsScene.Draw = function (self)
    self.root_node:Draw()
end

SettingsScene.Exit = function (self) end

return SettingsScene

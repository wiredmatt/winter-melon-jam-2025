---@class GamepadInputSource : InputSource
local GamepadInputSource = {
    down = {},
    prev_down = {},
    ---@type love.Joystick|nil
    joystick = nil
}
GamepadInputSource.__index = GamepadInputSource

GamepadInputSource.IsDown = function (button)
    if GamepadInputSource.joystick == nil then return false end
    return GamepadInputSource.joystick:isGamepadDown(button)
end

GamepadInputSource.JustPressed = function (button)
    if GamepadInputSource.joystick == nil then return false end
    local current = GamepadInputSource.IsDown(button)
    local was = GamepadInputSource.prev_down[button] or false
    local result = current and not was
    -- Update prev_down for next frame
    if current then
        GamepadInputSource.prev_down[button] = current
    end
    return result
end

GamepadInputSource.JustReleased = function (button)
    if GamepadInputSource.joystick == nil then return false end
    local was = GamepadInputSource.down[button]
    local current = GamepadInputSource.IsDown(button)
    GamepadInputSource.down[button] = current
    local is = was and not current
    return is
end

GamepadInputSource.Update = function ()
    -- Clear prev_down and update with current state
    local new_prev = {}
    for button, _ in pairs(GamepadInputSource.prev_down) do
        new_prev[button] = GamepadInputSource.IsDown(button)
    end
    GamepadInputSource.prev_down = new_prev
end

return GamepadInputSource
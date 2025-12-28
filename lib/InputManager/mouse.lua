---@class MouseInputSource : InputSource
local MouseInputSource = { down = {}, prev_down = {} }; MouseInputSource.__index = MouseInputSource

MouseInputSource.IsDown = function (button)
    return love.mouse.isDown(button)
end

MouseInputSource.JustPressed = function (button)
    local current = MouseInputSource.IsDown(button)
    local was = MouseInputSource.prev_down[button] or false
    local result = current and not was
    -- Update prev_down for next frame
    if current then
        MouseInputSource.prev_down[button] = current
    end
    return result
end

MouseInputSource.JustReleased = function (button)
    local was = MouseInputSource.down[button]
    local current = MouseInputSource.IsDown(button)
    MouseInputSource.down[button] = current
    local is = was and not current
    return is
end

MouseInputSource.Update = function ()
    -- Clear prev_down and update with current state
    local new_prev = {}
    for button, _ in pairs(MouseInputSource.prev_down) do
        new_prev[button] = MouseInputSource.IsDown(button)
    end
    MouseInputSource.prev_down = new_prev
end

return MouseInputSource
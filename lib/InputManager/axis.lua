---@class AxisInputSource
local AxisInputSource = {
    ---@type love.Joystick|nil
    joystick = nil,
    down = {}
}
AxisInputSource.__index = AxisInputSource

---@param axis love.GamepadAxis
AxisInputSource.GetAxis = function (axis)
    if AxisInputSource.joystick == nil then return 0 end
    return AxisInputSource.joystick:getGamepadAxis(axis)
end

AxisInputSource.IsDown = function (axis)
    if AxisInputSource.joystick == nil then return 0 end
    local is = AxisInputSource.joystick:getGamepadAxis(axis) ~= 0
    AxisInputSource.down[axis] = is
    return is
end

AxisInputSource.JustReleased = function (button)
    if AxisInputSource.joystick == nil then return false end
    local was = AxisInputSource.down[button]
    local current = AxisInputSource.IsDown(button)
    local is = was and not current; print(is)
    return is
end

return AxisInputSource
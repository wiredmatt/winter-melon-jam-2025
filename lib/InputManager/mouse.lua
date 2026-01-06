---@class MouseInputSource : InputSource
local MouseInputSource = {
    current = {},
    previous = {}
}
MouseInputSource.__index = MouseInputSource

function MouseInputSource.Update()
    MouseInputSource.previous = MouseInputSource.current
    MouseInputSource.current = {}

    for button = 1, 3 do
        MouseInputSource.current[button] = love.mouse.isDown(button)
    end
end

function MouseInputSource.IsDown(button)
    return MouseInputSource.current[button] or false
end

function MouseInputSource.JustPressed(button)
    return MouseInputSource.current[button]
       and not MouseInputSource.previous[button]
end

function MouseInputSource.JustReleased(button)
    return not MouseInputSource.current[button]
       and MouseInputSource.previous[button]
end

function MouseInputSource.GetPosition()
    return love.mouse.getPosition()
end

return MouseInputSource
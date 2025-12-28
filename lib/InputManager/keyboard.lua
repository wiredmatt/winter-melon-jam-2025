---@class KeyboardInputSource : InputSource
local KeyboardInputSource = { down = {}, prev_down = {} }; KeyboardInputSource.__index = KeyboardInputSource

KeyboardInputSource.IsDown = function (key)
    return love.keyboard.isDown(key)
end

KeyboardInputSource.JustPressed = function (key)
    local current = KeyboardInputSource.IsDown(key)
    local was = KeyboardInputSource.prev_down[key] or false
    local result = current and not was
    -- Update prev_down for next frame
    if current then
        KeyboardInputSource.prev_down[key] = current
    end
    return result
end

-- TODO: Redo this. It relies on IsDown having been called previously to work.
KeyboardInputSource.JustReleased = function (key)
    local was = KeyboardInputSource.down[key]
    local current = KeyboardInputSource.IsDown(key)
    KeyboardInputSource.down[key] = current
    local is = was and not current
    return is
end

KeyboardInputSource.Update = function ()
    -- Clear prev_down and update with current state
    -- This is called at the end of each frame to prepare for the next frame
    local new_prev = {}
    for key, _ in pairs(KeyboardInputSource.prev_down) do
        new_prev[key] = KeyboardInputSource.IsDown(key)
    end
    KeyboardInputSource.prev_down = new_prev
end

return KeyboardInputSource
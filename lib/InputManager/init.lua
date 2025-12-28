local IMUTMT = {__newindex = function(...) error("this table must not be modified at runtime") end}

local InputSourceEnum = setmetatable({
    keyboard = "keyboard",
    mouse = "mouse",
    gamepad = "gamepad",
    axis = "axis"
}, IMUTMT)

local InputSources = setmetatable({
    [InputSourceEnum.keyboard] = require("lib.InputManager.keyboard"),
    [InputSourceEnum.mouse] = require("lib.InputManager.mouse"),
    [InputSourceEnum.gamepad] = require("lib.InputManager.gamepad"),
    [InputSourceEnum.axis] = require("lib.InputManager.axis")
}, IMUTMT)

---@class InputSource
local InputSource = {}; InputSource.__index = InputSource
InputSource.IsDown = function (...) return false end
InputSource.JustPressed = function (...) return false end
InputSource.New = function (overrides)
    return setmetatable(overrides or {}, InputSource)
end

---@alias MouseButton 1|2|3
--                          jump   :    {"space", "w", "up"}
---@alias ActionBindings { [string]: (string|MouseButton)[] }
--                          "space"|"up"  : jump
---@alias BindingActions { [string|MouseButton]: string|nil }

---@class InputMap
---@field actions { [string]: ActionBindings }
---@field bindings { [string]: BindingActions }
---@field order string[] actions display order
local InputMap = {}; InputMap.__index = InputMap
InputMap.New = function (name)
    local imap = {
        name = name,
        actions = {},
        bindings = {},
        order = {}
    }
    for k, _ in pairs(InputSourceEnum) do imap.bindings[k] = {} end
    return setmetatable(imap, InputMap)
end

---@class InputManager
local InputManager = {
    ---@private
    active_map = nil,
    ---@private
    input_maps = {},
    ---@private
    sources = InputSources,
    InputSourceEnum = InputSourceEnum
}
---@private
InputManager.__index = InputManager

---@param joystick love.Joystick
InputManager.SetGamepadJoystick = function (joystick)
    InputManager.sources[InputSourceEnum.gamepad].joystick = joystick
    InputManager.sources[InputSourceEnum.axis].joystick = joystick
end
---@param joystick love.Joystick
InputManager.UnSetGamepadJoystick = function (joystick)
    if InputManager.sources[InputSourceEnum.gamepad].joystick == joystick then
        InputManager.sources[InputSourceEnum.gamepad].joystick = nil
    end
    if InputManager.sources[InputSourceEnum.axis].joystick == joystick then
        InputManager.sources[InputSourceEnum.axis].joystick = nil
    end
end

---@param map_name string
InputManager.DefineMap = function (map_name)
    InputManager.input_maps[map_name] = InputMap.New(map_name)
end

---@private
---@param map_name string
---@return InputMap
InputManager.get_map = function (map_name)
    local map = InputManager.input_maps[map_name];assert(map ~= nil, map_name .. " does not exist")
    return map
end

---@private
---@param map_name string|table
---@param action_name string
---@return ActionBindings
InputManager.get_action = function (map_name, action_name)
    local map = (type(map_name) == "string" and InputManager.get_map(map_name) or map_name)
    local action = map.actions[action_name]
    assert(action ~= nil, action_name .. " does not exist in map " .. map_name.name)
    return action
end

---@param map_name string
InputManager.SetActiveMap = function (map_name)
    InputManager.active_map = InputManager.get_map(map_name)
end

---@param map_name string
---@param action_name string
InputManager.DefineAction = function (map_name, action_name)
    local imap = InputManager.get_map(map_name)
    imap.actions[action_name] = {}

    for k, _ in pairs(InputManager.sources) do
        imap.actions[action_name][k] = {}
    end
end

---@param map_name string
---@param action_name string
---@param rebind boolean|nil
---@return Bindable
InputManager.BindAction = function (map_name, action_name, rebind)
    local imap = InputManager.get_map(map_name); InputManager.get_action(imap, action_name)

    ---@param source string
    local clear_action_source = function (source)
        imap.actions[action_name][source] = {}
    end

    ---@class Bindable
    local Bindable = {}

    ---@param key love.KeyConstant
    function Bindable:WithKeyboard(key)
        local source = InputSourceEnum.keyboard
        if rebind then clear_action_source(source) end
        table.insert(imap.actions[action_name][source], key)
        imap.bindings[source][key] = action_name
        return Bindable
    end
    ---@param button MouseButton
    function Bindable:WithMouse(button)
        local source = InputSourceEnum.mouse
        if rebind then clear_action_source(source) end
        table.insert(imap.actions[action_name][source], button)
        imap.bindings[source][button] = action_name
        return Bindable
    end
    ---@param button love.GamepadButton
    function Bindable:WithGamepad(button)
        local source = InputSourceEnum.gamepad
        if rebind then clear_action_source(source) end
        table.insert(imap.actions[action_name][source], button)
        imap.bindings[source][button] = action_name
        return Bindable
    end
    ---@param axis love.GamepadAxis
    function Bindable:WithAxis(axis)
        local source = InputSourceEnum.axis
        if rebind then clear_action_source(source) end
        table.insert(imap.actions[action_name][source], axis)
        imap.bindings[source][axis] = action_name
        return Bindable
    end
    ---@param source string
    ---@param key string|MouseButton
    function Bindable:With(source, key)
        if rebind then clear_action_source(source) end
        table.insert(imap.actions[action_name][source], key)
        imap.bindings[source][key] = action_name
        return Bindable
    end

    return Bindable
end

---@param map_name string
---@param action_name string
---@return Bindable
InputManager.ReBindAction = function (map_name, action_name)
    return InputManager.BindAction(map_name, action_name, true)
end

---@param map_name string
---@param action_name string
InputManager.UnBindAction = function (map_name, action_name)
    local imap = InputManager.get_map(map_name)
    local action = InputManager.get_action(imap, action_name)

    ---@class UnBindable
    local UnBindable = {}

    local function remove_src_binding(source)
        for _, key in ipairs(action[source]) do
            imap.bindings[source][key] = nil
        end
        imap.actions[action_name][source] = {}
    end

    function UnBindable:WithoutKeyboard()
        remove_src_binding(InputSourceEnum.keyboard)
        return UnBindable
    end
    function UnBindable:WithoutMouse()
        remove_src_binding(InputSourceEnum.mouse)
        return UnBindable
    end
    function UnBindable:WithoutGamepad()
        remove_src_binding(InputSourceEnum.gamepad)
        return UnBindable
    end
    function UnBindable:WithoutAxis()
        remove_src_binding(InputSourceEnum.axis)
        return UnBindable
    end
    function UnBindable:WithoutAny()
        for src, _ in pairs(action) do
            remove_src_binding(src)
        end
    end

    return UnBindable
end

---@param map_name string
---@param action_bindings { [string]: { keyboard?: love.KeyConstant[], mouse?: (1|2|3)[], gamepad?: love.GamepadButton[], axis?: love.GamepadAxis[] } }
InputManager.LoadBindings = function (map_name, action_bindings)
    InputManager.DefineMap(map_name)

    for action_name, bindings in pairs(action_bindings) do
        InputManager.DefineAction(map_name, action_name)

        for source, keys in pairs(bindings) do
            for _, key in ipairs(keys) do
                InputManager.BindAction(map_name, action_name):With(source, key)
            end
        end
    end
end

---@param order string[]
InputManager.SetMapDisplayOrder = function (map_name, order)
    local imap = InputManager.get_map(map_name)
    imap.order = order
end

InputManager.GetMapDisplayOrder = function (map_name)
    local imap = InputManager.get_map(map_name)
    return imap.order
end

---@param action_name string
---@return boolean
InputManager.IsDown = function (action_name)
    local amap = InputManager.active_map; if not amap then return false end
    local action = amap.actions[action_name]; if not action then return false end

    for source, isource in pairs(InputManager.sources) do
        for _, key in ipairs(action[source]) do
            if isource.IsDown(key) then return true end
        end
    end

    return false
end

---@param action_name string
---@return boolean
InputManager.JustPressed = function (action_name)
    local amap = InputManager.active_map; if not amap then return false end
    local action = amap.actions[action_name]; if not action then return false end

    for source, isource in pairs(InputManager.sources) do
        for _, key in ipairs(action[source]) do
            if isource.JustPressed and isource.JustPressed(key) then return true end
        end
    end

    return false
end

---@param action_name string
---@return boolean
InputManager.JustReleased = function (action_name)
    local amap = InputManager.active_map; if not amap then return false end
    local action = amap.actions[action_name]; if not action then return false end

    for source, isource in pairs(InputManager.sources) do
        for _, key in ipairs(action[source]) do
            if isource.JustReleased(key) then return true end
        end
    end

    return false
end

---@param action_name  string
---@return number
InputManager.GetValue = function (action_name)
    local amap = InputManager.active_map; if not amap then return 0 end
    local action = amap.actions[action_name]; if not action then return 0 end

    for _, axis in ipairs(action["axis"]) do
        local v = InputManager.sources.axis.GetAxis(axis --[[@as love.GamepadAxis]])
        if v ~= 0 then return v end
    end

    return 0
end

InputManager.Update = function ()
    for _, isource in pairs(InputManager.sources) do
        if isource.Update then
            isource.Update()
        end
    end
end

love.joystickadded = InputManager.SetGamepadJoystick
love.joystickremoved = InputManager.UnSetGamepadJoystick

return InputManager
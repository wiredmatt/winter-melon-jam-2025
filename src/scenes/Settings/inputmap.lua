local actions = {
    BACK = "BACK",
    CONFIRM = "CONFIRM",
    UP = "UP",
    DOWN = "DOWN",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    HORIZONTAL = "HORIZONTAL",
    VERTICAL = "VERTICAL",
    PREV_TAB = "PREV_TAB",
    NEXT_TAB = "NEXT_TAB",
}

local bindings = {
    [actions.BACK] = {
        ---@type love.KeyConstant[]
        keyboard = {"backspace", "escape"},
        ---@type love.GamepadButton[]
        gamepad = {"b", "back"}
    },
    [actions.CONFIRM] = {
        ---@type love.KeyConstant[]
        keyboard = {"return", "space"},
        ---@type love.GamepadButton[]
        gamepad = {"a"}
    },
    [actions.UP] = {
        ---@type love.KeyConstant[]
        keyboard = {"up", "w"},
        ---@type love.GamepadButton[]
        gamepad = {"dpup"}
    },
    [actions.DOWN] = {
        ---@type love.KeyConstant[]
        keyboard = {"down", "s"},
        ---@type love.GamepadButton[]
        gamepad = {"dpdown"}
    },
    [actions.LEFT] = {
        ---@type love.KeyConstant[]
        keyboard = {"left", "a"},
        ---@type love.GamepadButton[]
        gamepad = {"dpleft"}
    },
    [actions.RIGHT] = {
        ---@type love.KeyConstant[]
        keyboard = {"right", "d"},
        ---@type love.GamepadButton[]
        gamepad = {"dpright"}
    },
    [actions.HORIZONTAL] = {
        ---@type love.GamepadAxis[]
        axis = {"leftx"}
    },
    [actions.VERTICAL] = {
        ---@type love.GamepadAxis[]
        axis = {"lefty"}
    },
    [actions.PREV_TAB] = {
        ---@type love.GamepadButton[]
        gamepad = {"leftshoulder"}
    },
    [actions.NEXT_TAB] = {
        ---@type love.KeyConstant[]
        keyboard = {"tab"},
        ---@type love.GamepadButton[]
        gamepad = {"rightshoulder"}
    },
}

return {
    actions = actions,
    bindings = bindings
}
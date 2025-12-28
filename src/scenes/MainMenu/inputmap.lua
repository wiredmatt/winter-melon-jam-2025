local actions = {
    CONFIRM = "CONFIRM",
    UP = "UP",
    DOWN = "DOWN",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    HORIZONTAL = "HORIZONTAL",
    VERTICAL = "VERTICAL"
}

local bindings = {
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
}

return {
    actions = actions,
    bindings = bindings
}
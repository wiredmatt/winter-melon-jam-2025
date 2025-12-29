local actions = {
    CONFIRM = "CONFIRM",
    CANCEL = "CANCEL",
    NAVIGATE_LEFT = "NAVIGATE_LEFT",
    NAVIGATE_RIGHT = "NAVIGATE_RIGHT",
    NAVIGATE_UP = "NAVIGATE_UP",
    NAVIGATE_DOWN = "NAVIGATE_DOWN",
}

local bindings = {
    [actions.CONFIRM] = {
        ---@type love.KeyConstant[]
        keyboard = {"return", "space"},
        ---@type love.GamepadButton[]
        gamepad = {"a"},
        ---@type integer[]
        mouse = {}
    },
    [actions.CANCEL] = {
        ---@type love.KeyConstant[]
        keyboard = {"escape"},
        ---@type love.GamepadButton[]
        gamepad = {"b"},
        ---@type integer[]
        mouse = {}
    },
    [actions.NAVIGATE_LEFT] = {
        ---@type love.KeyConstant[]
        keyboard = {"left"},
        ---@type love.GamepadButton[]
        gamepad = {"dpleft"},
        ---@type integer[]
        mouse = {}
    },
    [actions.NAVIGATE_RIGHT] = {
        ---@type love.KeyConstant[]
        keyboard = {"right"},
        ---@type love.GamepadButton[]
        gamepad = {"dpright"},
        ---@type integer[]
        mouse = {}
    },
    [actions.NAVIGATE_UP] = {
        ---@type love.KeyConstant[]
        keyboard = {"up"},
        ---@type love.GamepadButton[]
        gamepad = {"dpup"},
        ---@type integer[]
        mouse = {}
    },
    [actions.NAVIGATE_DOWN] = {
        ---@type love.KeyConstant[]
        keyboard = {"down"},
        ---@type love.GamepadButton[]
        gamepad = {"dpdown"},
        ---@type integer[]
        mouse = {}
    },
}

return {
    actions = actions,
    bindings = bindings
}

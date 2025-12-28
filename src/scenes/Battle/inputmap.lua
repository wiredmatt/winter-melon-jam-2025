local actions = {
    CONFIRM = "CONFIRM",
}

local bindings = {
    [actions.CONFIRM] = {
        ---@type love.KeyConstant[]
        keyboard = {"return", "space"},
        ---@type love.GamepadButton[]
        gamepad = {"a"},
        ---@type integer[]
        mouse = {1}  -- Left mouse button
    },
}

return {
    actions = actions,
    bindings = bindings
}

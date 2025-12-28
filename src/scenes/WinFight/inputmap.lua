local actions = {
    CONFIRM = "CONFIRM",
}

local bindings = {
    [actions.CONFIRM] = {
        keyboard = {"return", "space"},
        gamepad = {"a"},
        mouse = {1}
    },
}

return {
    actions = actions,
    bindings = bindings
}

---@type IProgramConfig
local ProgramConfig = {
    window_cfg = {
        title = "The Masked King",
        resizable = true,
        width = 960,
        height = 540,
        minwidth = 320,
        minheight = 180
    },
    virtual_cfg = {
        width = 320,
        height = 180
    },
    canvas_cfg = {
        filter_min = "nearest", -- for sharp pixel art
        clear_color = {0,0,0,1}
    }
}

return ProgramConfig
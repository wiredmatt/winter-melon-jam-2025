---@class Components
---@field Rect RectComponentClass
---@field Sprite SpriteComponentClass
---@field Text TextComponentClass
---@field Input InputComponentClass
---@field HoverColor HoverColorComponentClass
---@field HoverScale HoverScaleComponentClass
local Components = {
    Rect = require("src.components.Rect"),
    Sprite = require("src.components.Sprite"),
    Text = require("src.components.Text"),

    Input = require("src.components.Input"),

    HoverColor = require("src.components.HoverColor"),
    HoverScale = require("src.components.HoverScale"),

    -- Layout components (TODO: implement these)
    -- Layout = require("src.components.Layout"),
    -- LayoutChild = require("src.components.LayoutChild"),
}

return Components

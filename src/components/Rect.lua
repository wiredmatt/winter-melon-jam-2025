---@class RectComponent : Component
---@field width number?
---@field height number?
---@field x number
---@field y number
---@field r number
---@field sx number
---@field sy number
---@field ox number
---@field oy number
---@field color love.Color
---@field mode love.DrawMode
---@field line_width number?

---@class RectComponentClass
---@field New fun(config: { width: number?, height: number?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: love.Color?, mode: love.DrawMode?, line_width: number? }?): RectComponent

local RectComponent = SceneGraph.Component.Define("Rect", {
    ---@param self RectComponent
    ---@param config { width: number?, height: number?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: love.Color?, mode: love.DrawMode?, line_width: number? }
    Init = function(self, config)
        self.width = config.width
        self.height = config.height

        self.x = config.x or 0
        self.y = config.y or 0
        self.r = config.r or 0
        self.sx = config.sx or 1
        self.sy = config.sy or 1
        self.ox = config.ox or 0
        self.oy = config.oy or 0

        self.color = config.color or {1, 1, 1, 1}
        self.mode = config.mode or "fill"
        self.line_width = config.line_width or 1

        -- Register as both Rect and Drawable for queries
        self.types = {"Rect", "Drawable"}
    end,

    ---@param self RectComponent
    Draw = function(self)
        local w = self.width or (self.node and self.node.width) or 0
        local h = self.height or (self.node and self.node.height) or 0

        love.graphics.push()
        love.graphics.translate(self.ox, self.oy)
        love.graphics.rotate(self.r)
        love.graphics.scale(self.sx, self.sy)
        love.graphics.translate(-self.ox, -self.oy)

        love.graphics.translate(self.x, self.y)

        love.graphics.setColor(self.color)
        love.graphics.setLineWidth(self.line_width)
        love.graphics.rectangle(self.mode, 0, 0, w, h)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.pop()
    end,
})

return RectComponent --[[@as RectComponentClass]]
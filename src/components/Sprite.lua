---@class SpriteComponent : Component
---@field image love.Image
---@field quad love.Quad?
---@field width number
---@field height number
---@field x number
---@field y number
---@field r number
---@field sx number
---@field sy number
---@field ox number
---@field oy number
---@field color love.Color

---@class SpriteComponentClass
---@field New fun(config: { image: love.Image, quad: love.Quad?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: love.Color? }): SpriteComponent

local SpriteComponent = SceneGraph.Component.Define("Sprite", {
    ---@param self SpriteComponent
    ---@param config { image: love.Image, quad: love.Quad?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: love.Color? }
    Init = function(self, config)
        self.image = config.image
        self.quad = config.quad

        -- Get dimensions from quad or image
        local w, h
        if self.quad ~= nil then
            local _, _, quad_w, quad_h = self.quad:getViewport()
            w, h = quad_w, quad_h
        else
            w, h = self.image:getDimensions()
        end

        self.width = w
        self.height = h

        self.x = config.x or 0
        self.y = config.y or 0
        self.r = config.r or 0
        self.sx = config.sx or 1
        self.sy = config.sy or 1
        self.ox = config.ox or 0
        self.oy = config.oy or 0

        self.color = config.color or {1, 1, 1, 1}

        -- Register as both Sprite and Drawable for queries
        self.types = {"Sprite", "Drawable"}
    end,

    ---@param self SpriteComponent
    Draw = function(self)
        love.graphics.push()
        love.graphics.translate(self.ox, self.oy)
        love.graphics.rotate(self.r)
        love.graphics.scale(self.sx, self.sy)
        love.graphics.translate(-self.ox, -self.oy)

        love.graphics.translate(self.x, self.y)

        love.graphics.setColor(self.color)

        if self.quad then
            love.graphics.draw(self.image, self.quad, 0, 0, 0, 1, 1, 0, 0)
        else
            love.graphics.draw(self.image, 0, 0, 0, 1, 1, 0, 0)
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.pop()
    end,
})

return SpriteComponent --[[@as SpriteComponentClass]]
---@class SpriteDrawable
---@field image love.Image
---@field quad love.Quad?
---@field x number
---@field y number
---@field r number
---@field sx number
---@field sy number
---@field ox number
---@field oy number
---@field color number[]
---@field _node BaseNode?
local Sprite = {}

---@param image love.Image
---@param quad love.Quad?
---@param opts { x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: number[]? }?
---@return SpriteDrawable
function Sprite.New(image, quad, opts)
    opts = opts or {}

    local self = {
        image = image,
        quad = quad,

        x = opts.x or 0,
        y = opts.y or 0,
        r = opts.r or 0,
        sx = opts.sx or 1,
        sy = opts.sy or 1,
        ox = opts.ox or 0,
        oy = opts.oy or 0,

        color = opts.color or {1, 1, 1, 1},

        _node = nil,
    }

    function self:Draw()
        love.graphics.setColor(self.color)

        if self.quad then
            love.graphics.draw(self.image, self.quad, self.x, self.y, self.r, self.sx, self.sy, self.ox, self.oy)
        else
            love.graphics.draw(self.image, self.x, self.y, self.r, self.sx, self.sy, self.ox, self.oy)
        end

        love.graphics.setColor(1, 1, 1, 1)
    end

    return self
end

return Sprite

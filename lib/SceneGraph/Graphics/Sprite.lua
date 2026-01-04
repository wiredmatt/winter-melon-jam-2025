---@class SpriteDrawable
---@field image love.Image
---@field quad love.Quad?
---@field x number
---@field y number
---@field r number
---@field sx number
---@field sy number
---@field color number[]
---@field _node BaseNode?
local Sprite = {}

---@param image love.Image
---@param quad love.Quad?
---@param opts { x: number?, y: number?, r: number?, sx: number?, sy: number?, color: number[]? }?
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

        color = opts.color or {1, 1, 1, 1},

        _node = nil,
    }

    function self:Draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.r)
        love.graphics.scale(self.sx, self.sy)

        love.graphics.setColor(self.color)
        love.graphics.draw(self.image, self.quad)
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.pop()
    end

    return self
end

return Sprite

---@class RectDrawable : Drawable
---@field mode love.DrawMode
local Rect = {}
Rect.__index = Rect

---@param opts { width: number?, height: number?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: number[]?, mode: love.DrawMode? }?
---@return RectDrawable
function Rect.New(opts)
    opts = opts or {}

    local self = {
        width = opts.width,
        height = opts.height,

        x = opts.x or 0,
        y = opts.y or 0,
        r = opts.r or 0,
        sx = opts.sx or 1,
        sy = opts.sy or 1,
        ox = opts.ox or 0,
        oy = opts.oy or 0,

        color = opts.color or {1, 1, 1, 1},
        mode = opts.mode or "fill",

        ---@type Node?
        _node = nil,
    }

    function self:Draw()
        local w = self.width or (self._node and self._node.width) or 0
        local h = self.height or (self._node and self._node.height) or 0

        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.r)
        love.graphics.scale(self.sx, self.sy)

        love.graphics.setColor(self.color)
        love.graphics.rectangle(self.mode, -self.ox, -self.oy, w, h)
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.pop()
    end

    return self
end

return Rect

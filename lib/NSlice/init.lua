---@class NSlice
---@field img love.Image
---@field quad love.Quad
---@field quad_x number
---@field quad_y number
---@field imgw number
---@field imgh number
---@field min_width number
---@field min_height number
---@field border { left: number, right: number, top: number, bottom: number}
---@field batch love.SpriteBatch
---@field quads { [number]: { [number]: love.Quad} }
---@field quad_sizes { [number]: { [number]: [number,number] } }
local NSlice = {}
NSlice.__index = NSlice

---@param img love.Image
---@param quad love.Quad|nil  region inside img (if nil, use whole image)
---@param left number
---@param right number
---@param top number
---@param bottom number
function NSlice.New(img, quad, left, right, top, bottom)
    local iw, ih = img:getDimensions()
    if quad == nil then quad = love.graphics.newQuad(0, 0, iw, ih, iw, ih) end

    local nsl = setmetatable({ img = img, quad = quad }, NSlice)

    nsl.quad_x, nsl.quad_y, nsl.min_width, nsl.min_height = quad:getViewport()
    nsl.imgw, nsl.imgh = iw, ih

    nsl.border = {
        left   = left  or nsl.min_width  / 3,
        right  = right or nsl.min_width  / 3,
        top    = top   or nsl.min_height / 3,
        bottom = bottom or nsl.min_height / 3
    }

    nsl.batch = love.graphics.newSpriteBatch(img, 9)
    for _ = 1, 9 do
        nsl.batch:add(0, 0)
    end

    nsl.quads = {}
    nsl.quad_sizes = {}

    nsl:GenerateQuads()

    return nsl
end

function NSlice:GenerateQuads()
    local b = self.border

    local qx = { 0, b.left, self.min_width - b.right }
    local qy = { 0, b.top,  self.min_height - b.bottom }
    local qw = { b.left, math.max(0, self.min_width - b.left - b.right), b.right }
    local qh = { b.top,  math.max(0, self.min_height - b.top - b.bottom), b.bottom }

    -- base offset inside the spritesheet. must be added to each cell's x,y
    local base_x, base_y = self.quad_x, self.quad_y

    for row = 1, 3 do
        self.quads[row] = {}
        self.quad_sizes[row] = {}
        for col = 1, 3 do
            local x = base_x + qx[col]
            local y = base_y + qy[row]
            local w = qw[col]
            local h = qh[row]

            local quad = love.graphics.newQuad(x, y, w, h, self.imgw, self.imgh)
            self.quads[row][col] = quad
            self.quad_sizes[row][col] = { w, h }
        end
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
function NSlice:BuildSpriteBatch(x, y, w, h)
    w = math.max(math.floor(w), self.min_width)
    h = math.max(math.floor(h), self.min_height)

    if self.cached_width == w and self.cached_height == h then return end

    local b = self.border
    local widths = {
        b.left,
        math.max(0, w - b.left - b.right),
        b.right
    }
    local heights = {
        b.top,
        math.max(0, h - b.top - b.bottom),
        b.bottom
    }

    local dy = y
    local index = 1
    for row = 1, 3 do
        local dh = heights[row]
        local dx = x
        for col = 1, 3 do
            local dw = widths[col]
            if dw > 0 and dh > 0 then
                local quad = self.quads[row][col]
                local qw, qh = unpack(self.quad_sizes[row][col])

                self.batch:set(index, quad, dx, dy, 0, dw / qw, dh / qh)
                index = index + 1
            end
            dx = dx + dw
        end
        dy = dy + dh
    end

    self.cached_width = w
    self.cached_height = h
end

function NSlice:Draw(x, y, w, h)
    self:BuildSpriteBatch(x, y, w, h)
    love.graphics.draw(self.batch)
end

return NSlice

local DEFAULT_COLOR = { 1, 1, 1, 1 }

local DiagonalOut = {}
DiagonalOut.__index = DiagonalOut

---@return fun(): Transition
DiagonalOut.New = function(config)
    config = config or {}
    return function ()
        local self = setmetatable({}, DiagonalOut)

        self.color = config.color or { 0, 0, 0, 1 }
        self.duration = config.duration or 2
        self.elapsed_time = 0

        self.x = config.x or 0
        self.y = config.y or 0
        self.w = config.w or love.graphics.getWidth()
        self.h = config.h or love.graphics.getHeight()

        self.completed = false
        self.progress = 0

        return self
    end
end

DiagonalOut.Update = function(self, dt)
    if self.completed then return end

    self.elapsed_time = self.elapsed_time + dt
    self.progress = math.min(self.elapsed_time / self.duration, 1)
    self.completed = self.progress >= 1
end

DiagonalOut.Draw = function(self)
    local p = self.progress
    local x, y, w, h = self.x, self.y, self.w, self.h
    local r, g, b, a = unpack(self.color)

    local offsetX = w * p
    local offsetY = h * p

    local t1 = {
        x - offsetX, y - offsetY,
        x + w - offsetX, y - offsetY,
        x - offsetX, y + h - offsetY
    }

    local t2 = {
        x + offsetX, h + offsetY,
        x + w + offsetX, y + offsetY,
        x + w + offsetX, y + h + offsetY
    }

    love.graphics.setColor(r, g, b, a)
    love.graphics.polygon("fill", t1)
    love.graphics.polygon("fill", t2)
    love.graphics.setColor(DEFAULT_COLOR)
end

return DiagonalOut
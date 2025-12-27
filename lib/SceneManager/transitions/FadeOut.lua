local DEFAULT_COLOR = { 1, 1, 1, 1 } -- white

local FadeOutTransition = {}
FadeOutTransition.__index = FadeOutTransition

---@return fun(): Transition
FadeOutTransition.New = function(config)
    config = config or {}
    return function ()
        local self = setmetatable({}, FadeOutTransition)

        self.target_color = (config.color) or { 0, 0, 0, 1 }
        self.duration = config.duration or 0.5 -- in seconds
        self.elapsed_time = 0

        self.x = config.x or 0
        self.y = config.y or 0
        self.w = config.w or love.graphics.getWidth()
        self.h = config.h or love.graphics.getHeight()

        self.completed = false
        self.current_alpha = 0

        return self
    end
end

FadeOutTransition.Update = function(self, dt)
    if self.completed then return end

    self.elapsed_time = self.elapsed_time + dt
    local progress = math.min(self.elapsed_time / self.duration, 1)
    self.completed = progress >= 1

    -- Fade from 1 (fully opaque) to 0 (fully transparent)
    self.current_alpha = progress
end

FadeOutTransition.Draw = function(self)
    local r, g, b = self.target_color[1], self.target_color[2], self.target_color[3]
    local a = self.current_alpha
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.setColor(DEFAULT_COLOR)
end

return FadeOutTransition
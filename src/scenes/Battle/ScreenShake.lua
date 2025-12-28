---@class ScreenShake
---@field timer number
---@field intensity number
local ScreenShake = {}
ScreenShake.__index = ScreenShake

---@return ScreenShake
ScreenShake.New = function()
    local self = setmetatable({}, ScreenShake)
    self.timer = 0
    self.intensity = 0
    return self
end

---@param duration number Shake duration in seconds
---@param intensity number Shake intensity in pixels
ScreenShake.Start = function(self, duration, intensity)
    self.timer = duration
    self.intensity = intensity
end

---@param dt number
ScreenShake.Update = function(self, dt)
    if self.timer > 0 then
        self.timer = self.timer - dt
        if self.timer < 0 then
            self.timer = 0
        end
    end
end

---Get shake offset for current frame
---@return number shake_x, number shake_y
ScreenShake.GetOffset = function(self)
    if self.timer <= 0 then
        return 0, 0
    end

    local shake_x = (math.random() - 0.5) * 2 * self.intensity
    local shake_y = (math.random() - 0.5) * 2 * self.intensity
    return shake_x, shake_y
end

---@return boolean
ScreenShake.IsActive = function(self)
    return self.timer > 0
end

return ScreenShake

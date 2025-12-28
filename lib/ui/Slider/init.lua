local Node = require("lib.ui.Node")

---@class SliderConfig : NodeConfig
---@field value number?
---@field min number?
---@field max number?
---@field handle_width number?
---@field track_height number?
---@field track_color table?
---@field filled_color table?
---@field handle_color table?
---@field handle_hover_color table?

---@class Slider : Node
---@field value number
---@field min number
---@field max number
---@field handle_width number
---@field track_height number
---@field track_color table
---@field filled_color table
---@field handle_color table
---@field handle_hover_color table
---@field dragging boolean
---@field OnValueChanged function?
local Slider = setmetatable({}, { __index = Node })
Slider.__index = Slider

---@param config SliderConfig?
---@return Slider
Slider.New = function (config)
    config = config or {}

    local base_node = Node.New(config)

    local self = setmetatable(base_node, Slider) --[[@as Slider]]

    self.value = config.value or 0.5
    self.min = config.min or 0
    self.max = config.max or 1
    self.handle_width = config.handle_width or 12
    self.track_height = config.track_height or 8
    self.track_color = config.track_color or {0.3, 0.3, 0.3, 1}
    self.filled_color = config.filled_color or {0.5, 0.7, 1.0, 1}
    self.handle_color = config.handle_color or {1, 1, 1, 1}
    self.handle_hover_color = config.handle_hover_color or {0.9, 0.9, 0.9, 1}
    self.dragging = false
    self.OnValueChanged = nil

    -- Default height to track height if not specified
    if not config.height then
        self.height = self.track_height
    end

    return self
end

---@param value number Value between min and max
Slider.SetValue = function (self, value)
    local new_value = math.max(self.min, math.min(self.max, value))
    if new_value ~= self.value then
        self.value = new_value
        if self.OnValueChanged then
            self.OnValueChanged(new_value)
        end
    end
end

---@return number
Slider.GetValue = function (self)
    return self.value
end

---@return number
Slider.GetNormalizedValue = function (self)
    if self.max == self.min then return 0 end
    return (self.value - self.min) / (self.max - self.min)
end

---@return number x, number y, number width, number height
Slider.GetLocalBounds = function (self)
    local half_handle = self.handle_width / 2
    return -half_handle, 0, self.width + self.handle_width, self.height
end

---@param x number World X coordinate
---@param y number World Y coordinate
Slider.UpdateValueFromMouse = function (self, x, y)
    local lx, ly = self:WorldToLocal(x, y)

    -- Calculate percentage along the track
    -- Note(matt): lx is relative to the slider origin (0, 0), not the extended bounds
    local percent = math.max(0, math.min(1, lx / self.width))

    -- Convert to value in range
    local new_value = self.min + percent * (self.max - self.min)

    self:SetValue(new_value)
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button
---@return boolean consumed
Slider.HandleMousePressed = function (self, x, y, button)
    if button == 1 and self:ContainsPoint(x, y) and self.enabled then
        self.dragging = true
        self:UpdateValueFromMouse(x, y)
        return true
    end

    return false
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button
---@return boolean consumed
Slider.HandleMouseReleased = function (self, x, y, button)
    -- handle left click release
    if button == 1 and self.dragging then
        self.dragging = false
        return true
    end

    return false
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param dx number Mouse delta X
---@param dy number Mouse delta Y
---@return boolean consumed
Slider.HandleMouseMoved = function (self, x, y, dx, dy)
    if self.dragging then
        self:UpdateValueFromMouse(x, y)
    end

    -- call parent's mouse moved for hover tracking
    return Node.HandleMouseMoved(self, x, y, dx, dy)
end

Slider.Draw = function (self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    local prev_line_width = love.graphics.getLineWidth()
    local pr, pg, pb, pa = love.graphics.getColor()

    -- track vertical centering
    local track_y = (self.height - self.track_height) / 2

    -- track background
    love.graphics.setColor(self.track_color)
    love.graphics.rectangle("fill", 0, track_y, self.width, self.track_height)

    -- filled portion
    local percent = self:GetNormalizedValue()
    local filled_width = self.width * percent

    love.graphics.setColor(self.filled_color)
    love.graphics.rectangle("fill", 0, track_y, filled_width, self.track_height)

    local handle_x = filled_width - (self.handle_width / 2)
    local handle_y = (self.height - self.handle_width) / 2

    if self.hovered or self.dragging or self.focused then
        love.graphics.setColor(self.handle_hover_color)
    else
        love.graphics.setColor(self.handle_color)
    end

    love.graphics.rectangle("fill", handle_x, handle_y, self.handle_width, self.handle_width)

    love.graphics.setLineWidth(prev_line_width)
    love.graphics.setColor(pr, pg, pb, pa)

    self:DrawDebugOverlay()

    love.graphics.pop()
end

return Slider

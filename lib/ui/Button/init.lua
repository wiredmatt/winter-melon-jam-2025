local Node = require("lib.ui.Node")

---@class ButtonConfig : NodeConfig
---@field text string?
---@field font love.Font?
---@field normal_color table?
---@field hover_color table?
---@field pressed_color table?
---@field text_color table?
---@field border_width number?
---@field border_color table?
---@field focused_border_color table?
---@field focused_border_width number?
---@field icon love.Image?
---@field icon_quad love.Quad?
---@field icon_position string?
---@field icon_spacing number?
---@field icon_color table?
---@field nineslice NSlice?

---@class Button : Node
---@field text string
---@field font love.Font
---@field normal_color table
---@field hover_color table
---@field pressed_color table
---@field text_color table
---@field border_width number
---@field border_color table
---@field focused_border_color table
---@field focused_border_width number
---@field pressed boolean
---@field OnClick function?
---@field icon love.Image?
---@field icon_quad love.Quad?
---@field icon_position string
---@field icon_spacing number
---@field icon_color table
---@field nineslice NSlice?
local Button = setmetatable({}, { __index = Node })
Button.__index = Button

---@param config ButtonConfig?
---@return Button
Button.New = function (config)
    config = config or {}

    local base_node = Node.New(config)

    local self = setmetatable(base_node, Button) --[[@as Button]]

    self.text = config.text or "Button"
    self.font = config.font or love.graphics.getFont()
    self.normal_color = config.normal_color or {0.3, 0.3, 0.3, 1}
    self.hover_color = config.hover_color or {0.4, 0.4, 0.4, 1}
    self.pressed_color = config.pressed_color or {0.2, 0.2, 0.2, 1}
    self.text_color = config.text_color or {1, 1, 1, 1}
    self.border_width = config.border_width or 2
    self.border_color = config.border_color or {1, 1, 1, 1}
    self.focused_border_color = config.focused_border_color or {0.3, 0.7, 1, 1}
    self.focused_border_width = config.focused_border_width or 3
    self.pressed = false
    self.OnClick = nil

    self.icon = config.icon
    self.icon_quad = config.icon_quad
    self.icon_position = config.icon_position or "left"
    self.icon_spacing = config.icon_spacing or 4
    self.icon_color = config.icon_color or {1, 1, 1, 1}

    self.nineslice = config.nineslice

    return self
end

---@return number width, number height
Button.GetIconSize = function (self)
    if not self.icon then
        return 0, 0
    end

    if self.icon_quad then
        local _, _, w, h = self.icon_quad:getViewport()
        return w, h
    else
        return self.icon:getWidth(), self.icon:getHeight()
    end
end

---@return number icon_x, number icon_y, number text_x, number text_y
Button.CalculateLayout = function (self)
    local icon_w, icon_h = self:GetIconSize()

    -- Calculate text dimensions (accounting for multi-line text)
    local text_w = 0
    local text_h = 0
    if self.text ~= "" then
        -- Find the widest line for horizontal centering
        for line in self.text:gmatch("[^\n]+") do
            local line_w = self.font:getWidth(line)
            if line_w > text_w then
                text_w = line_w
            end
        end
        -- Calculate total height based on line count
        local line_count = select(2, self.text:gsub("\n", "\n")) + 1
        text_h = self.font:getHeight() * line_count
    end

    local spacing = (icon_w > 0 and text_w > 0) and self.icon_spacing or 0

    -- Account for border width when centering (border is drawn centered on edge)
    -- For a border of width N, we lose N/2 pixels on each side visually
    local border_offset = (not self.nineslice and self.border_width > 0) and (self.border_width / 2) or 0
    local inner_width = self.width - (border_offset * 2)
    local inner_height = self.height - (border_offset * 2)

    if self.icon_position == "left" or self.icon_position == "right" then
        -- Horizontal layout
        local total_w = icon_w + spacing + text_w
        local content_x = border_offset + (inner_width - total_w) / 2

        local icon_x, text_x
        if self.icon_position == "left" then
            icon_x = content_x
            text_x = content_x + icon_w + spacing
        else  -- right
            text_x = content_x
            icon_x = content_x + text_w + spacing
        end

        local icon_y = border_offset + (inner_height - icon_h) / 2
        local text_y = border_offset + (inner_height - text_h) / 2

        return icon_x, icon_y, text_x, text_y

    else  -- top or bottom
        -- Vertical layout
        local total_h = icon_h + spacing + text_h
        local content_y = border_offset + (inner_height - total_h) / 2

        local icon_y, text_y
        if self.icon_position == "top" then
            icon_y = content_y
            text_y = content_y + icon_h + spacing
        else  -- bottom
            text_y = content_y
            icon_y = content_y + text_h + spacing
        end

        local icon_x = border_offset + (inner_width - icon_w) / 2
        local text_x = border_offset + (inner_width - text_w) / 2

        return icon_x, icon_y, text_x, text_y
    end
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button (1 = left, 2 = right, 3 = middle)
---@return boolean consumed True if event was handled
Button.HandleMousePressed = function (self, x, y, button)
    for _, child in ipairs(self.children) do
        if child.HandleMousePressed then
            if child:HandleMousePressed(x, y, button) then
                return true  -- Child consumed event
            end
        end
    end

    if button == 1 and self:ContainsPoint(x, y) and self.enabled then
        self.pressed = true
        return true
    end

    return false
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button (1 = left, 2 = right, 3 = middle)
---@return boolean consumed True if event was handled
Button.HandleMouseReleased = function (self, x, y, button)
    for _, child in ipairs(self.children) do
        if child.HandleMouseReleased then
            if child:HandleMouseReleased(x, y, button) then
                return true  -- Child consumed event
            end
        end
    end

    if button == 1 and self.pressed then
        self.pressed = false

        -- Trigger OnClick if released within bounds
        if self:ContainsPoint(x, y) and self.enabled and self.OnClick then
            self.OnClick()
        end

        return true
    end

    return false
end

Button.Draw = function (self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    local prev_line_width = love.graphics.getLineWidth()
    local pr, pg, pb, pa = love.graphics.getColor()
    local prev_font = love.graphics.getFont()

    local bg_color = self.normal_color
    if not self.enabled then
        bg_color = {0.2, 0.2, 0.2, 0.5}
    elseif self.pressed then
        bg_color = self.pressed_color
    elseif self.hovered or self.focused then
        bg_color = self.hover_color
    end

    -- Draw background (nineslice or rectangle)
    if self.nineslice then
        -- Use nineslice with color tinting
        love.graphics.setColor(bg_color)
        self.nineslice:Draw(0, 0, self.width, self.height)
    else
        -- Use solid color rectangle
        love.graphics.setColor(bg_color)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)

        -- Draw border
        if self.border_width > 0 then
            love.graphics.setColor(self.border_color)
            love.graphics.setLineWidth(self.border_width)
            love.graphics.rectangle("line", 0, 0, self.width, self.height)
        end
    end

    -- calculate layout for icon and text
    local icon_x, icon_y, text_x, text_y = self:CalculateLayout()

    if self.icon then
        love.graphics.setColor(self.icon_color)
        if self.icon_quad then
            love.graphics.draw(self.icon, self.icon_quad, icon_x, icon_y)
        else
            love.graphics.draw(self.icon, icon_x, icon_y)
        end
    end

    if self.text ~= "" then
        love.graphics.setFont(self.font)
        love.graphics.setColor(self.text_color)
        love.graphics.print(self.text, text_x, text_y)
    end

    love.graphics.setLineWidth(prev_line_width)
    love.graphics.setColor(pr, pg, pb, pa)
    love.graphics.setFont(prev_font)

    for _, child in ipairs(self.children) do
        child:Draw()
    end

    self:DrawDebugOverlay()

    love.graphics.pop()
end

return Button

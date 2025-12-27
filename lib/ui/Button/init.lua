local Node = require("lib.ui.Node")
local NSlice = require("lib.NSlice")

---@class ButtonConfig : NodeConfig
---@field text string?
---@field font love.Font?
---@field normal_color table?
---@field hover_color table?
---@field pressed_color table?
---@field text_color table?
---@field border_width number?
---@field border_color table?
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
    self.pressed = false
    self.OnClick = nil

    -- Icon properties
    self.icon = config.icon
    self.icon_quad = config.icon_quad
    self.icon_position = config.icon_position or "left"
    self.icon_spacing = config.icon_spacing or 4
    self.icon_color = config.icon_color or {1, 1, 1, 1}

    -- NineSlice background
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
    local text_w = self.text ~= "" and self.font:getWidth(self.text) or 0
    local text_h = self.font:getHeight()

    local spacing = (icon_w > 0 and text_w > 0) and self.icon_spacing or 0

    if self.icon_position == "left" or self.icon_position == "right" then
        -- Horizontal layout
        local total_w = icon_w + spacing + text_w
        local content_x = (self.width - total_w) / 2

        local icon_x, text_x
        if self.icon_position == "left" then
            icon_x = content_x
            text_x = content_x + icon_w + spacing
        else  -- right
            text_x = content_x
            icon_x = content_x + text_w + spacing
        end

        local icon_y = (self.height - icon_h) / 2
        local text_y = (self.height - text_h) / 2

        return icon_x, icon_y, text_x, text_y

    else  -- top or bottom
        -- Vertical layout
        local total_h = icon_h + spacing + text_h
        local content_y = (self.height - total_h) / 2

        local icon_y, text_y
        if self.icon_position == "top" then
            icon_y = content_y
            text_y = content_y + icon_h + spacing
        else  -- bottom
            text_y = content_y
            icon_y = content_y + text_h + spacing
        end

        local icon_x = (self.width - icon_w) / 2
        local text_x = (self.width - text_w) / 2

        return icon_x, icon_y, text_x, text_y
    end
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button (1 = left, 2 = right, 3 = middle)
---@return boolean consumed True if event was handled
Button.HandleMousePressed = function (self, x, y, button)
    -- Check children first
    for _, child in ipairs(self.children) do
        if child.HandleMousePressed then
            if child:HandleMousePressed(x, y, button) then
                return true  -- Child consumed event
            end
        end
    end

    -- Handle left click on this button
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
    -- Check children first
    for _, child in ipairs(self.children) do
        if child.HandleMouseReleased then
            if child:HandleMouseReleased(x, y, button) then
                return true  -- Child consumed event
            end
        end
    end

    -- Handle left click release
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

    -- Save previous graphics state
    local prev_line_width = love.graphics.getLineWidth()
    local pr, pg, pb, pa = love.graphics.getColor()
    local prev_font = love.graphics.getFont()

    -- Determine background color based on state
    local bg_color = self.normal_color
    if not self.enabled then
        bg_color = {0.2, 0.2, 0.2, 0.5}
    elseif self.pressed then
        bg_color = self.pressed_color
    elseif self.hovered then
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

    -- Calculate layout for icon and text
    local icon_x, icon_y, text_x, text_y = self:CalculateLayout()

    -- Draw icon
    if self.icon then
        love.graphics.setColor(self.icon_color)
        if self.icon_quad then
            love.graphics.draw(self.icon, self.icon_quad, icon_x, icon_y)
        else
            love.graphics.draw(self.icon, icon_x, icon_y)
        end
    end

    -- Draw text
    if self.text ~= "" then
        love.graphics.setFont(self.font)
        love.graphics.setColor(self.text_color)
        love.graphics.print(self.text, text_x, text_y)
    end

    -- Restore previous state
    love.graphics.setLineWidth(prev_line_width)
    love.graphics.setColor(pr, pg, pb, pa)
    love.graphics.setFont(prev_font)

    -- Draw children
    for _, child in ipairs(self.children) do
        child:Draw()
    end

    -- Draw debug overlay
    self:DrawDebugOverlay()

    love.graphics.pop()
end

return Button

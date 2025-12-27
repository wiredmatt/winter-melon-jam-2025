local Node = require("lib.ui.Node")

---@class CheckboxConfig : NodeConfig
---@field checked boolean?
---@field label string?
---@field font love.Font?
---@field box_size number?
---@field box_color table?
---@field check_color table?
---@field text_color table?
---@field label_spacing number?

---@class Checkbox : Node
---@field checked boolean
---@field label string
---@field font love.Font
---@field box_size number
---@field box_color table
---@field check_color table
---@field text_color table
---@field label_spacing number
---@field pressed boolean
---@field OnChanged function?
local Checkbox = setmetatable({}, { __index = Node })
Checkbox.__index = Checkbox

---@param config CheckboxConfig?
---@return Checkbox
Checkbox.New = function (config)
    config = config or {}

    -- Calculate width from box + label if not provided
    if not config.width then
        local box_size = config.box_size or 16
        local label_spacing = config.label_spacing or 8
        local font = config.font or love.graphics.getFont()
        local label_width = (config.label and config.label ~= "") and font:getWidth(config.label) or 0
        config.width = box_size + (label_width > 0 and (label_spacing + label_width) or 0)
    end

    -- Calculate height from box or font if not provided
    if not config.height then
        local box_size = config.box_size or 16
        local font = config.font or love.graphics.getFont()
        config.height = math.max(box_size, font:getHeight())
    end

    local base_node = Node.New(config)

    local self = setmetatable(base_node, Checkbox) --[[@as Checkbox]]

    self.checked = config.checked or false
    self.label = config.label or ""
    self.font = config.font or love.graphics.getFont()
    self.box_size = config.box_size or 16
    self.box_color = config.box_color or {0.3, 0.3, 0.3, 1}
    self.check_color = config.check_color or {0, 1, 0, 1}
    self.text_color = config.text_color or {1, 1, 1, 1}
    self.label_spacing = config.label_spacing or 8
    self.pressed = false
    self.OnChanged = nil

    return self
end

---@param checked boolean
Checkbox.SetChecked = function (self, checked)
    if self.checked ~= checked then
        self.checked = checked
        if self.OnChanged then
            self.OnChanged(checked)
        end
    end
end

Checkbox.Toggle = function (self)
    self:SetChecked(not self.checked)
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button
---@return boolean consumed
Checkbox.HandleMousePressed = function (self, x, y, button)
    if button == 1 and self:ContainsPoint(x, y) and self.enabled then
        self.pressed = true
        return true
    end

    return false
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button
---@return boolean consumed
Checkbox.HandleMouseReleased = function (self, x, y, button)
    if button == 1 and self.pressed then
        self.pressed = false

        -- toggle if released within bounds
        if self:ContainsPoint(x, y) and self.enabled then
            self:Toggle()
        end

        return true
    end

    return false
end

Checkbox.Draw = function (self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    local prev_line_width = love.graphics.getLineWidth()
    local pr, pg, pb, pa = love.graphics.getColor()
    local prev_font = love.graphics.getFont()

    -- Calculate vertical centering for box
    local box_y = (self.height - self.box_size) / 2

    -- box background
    love.graphics.setColor(self.box_color)
    love.graphics.rectangle("fill", 0, box_y, self.box_size, self.box_size)

    -- box border
    love.graphics.setColor(self.text_color)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, box_y, self.box_size, self.box_size)

    if self.checked then
        love.graphics.setColor(self.check_color)
        love.graphics.setLineWidth(3)

        -- checkmark symbol
        local padding = 4
        local x1 = padding
        local y1 = box_y + self.box_size / 2
        local x2 = self.box_size / 2 - 1
        local y2 = box_y + self.box_size - padding
        local x3 = self.box_size - padding
        local y3 = box_y + padding

        love.graphics.line(x1, y1, x2, y2)
        love.graphics.line(x2, y2, x3, y3)
    end

    if self.label ~= "" then
        love.graphics.setFont(self.font)
        love.graphics.setColor(self.text_color)

        local text_x = self.box_size + self.label_spacing
        local text_y = (self.height - self.font:getHeight()) / 2

        love.graphics.print(self.label, text_x, text_y)
    end

    love.graphics.setLineWidth(prev_line_width)
    love.graphics.setColor(pr, pg, pb, pa)
    love.graphics.setFont(prev_font)

    self:DrawDebugOverlay()

    love.graphics.pop()
end

return Checkbox

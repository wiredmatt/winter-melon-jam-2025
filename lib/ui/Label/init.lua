local Node = require("lib.ui.Node")

---@class LabelConfig : NodeConfig
---@field text string?
---@field font love.Font?
---@field color table?
---@field align love.AlignMode?

---@class Label : Node
---@field text string
---@field font love.Font
---@field color table
---@field align love.AlignMode
local Label = setmetatable({}, { __index = Node })
Label.__index = Label

---@param config LabelConfig?
---@return Label
Label.New = function (config)
    config = config or {}

    local base_node = Node.New(config)

    local self = setmetatable(base_node, Label) --[[@as Label]]

    self.text = config.text or ""
    self.font = config.font or love.graphics.getFont()
    self.color = config.color or {1, 1, 1, 1} 
    self.align = config.align or "left"

    -- calculate width/height if not provided
    if not config.width then
        self.width = self.font:getWidth(self.text)
    end
    if not config.height then
        self.height = self.font:getHeight()
    end

    return self
end

---@param text string
Label.SetText = function (self, text)
    self.text = text
    self.width = self.font:getWidth(text)
end

Label.Draw = function (self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    local prev_font = love.graphics.getFont()
    local pr, pg, pb, pa = love.graphics.getColor()

    love.graphics.setFont(self.font)
    love.graphics.setColor(self.color)

    love.graphics.printf(self.text, 0, 0, self.width, self.align)

    love.graphics.setFont(prev_font)
    love.graphics.setColor(pr, pg, pb, pa)

    self:DrawDebugOverlay()

    love.graphics.pop()
end

return Label

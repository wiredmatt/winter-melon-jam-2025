---@alias TextAlign "left" | "center" | "right"
---@alias TextVAlign "top" | "middle" | "bottom"

---@class TextShadow
---@field x number
---@field y number
---@field color number[]

---@class TextOutline
---@field width number
---@field color number[]

---@class TextDrawable : Drawable
---@field text string
---@field font love.Font
---@field align TextAlign
---@field valign TextVAlign
---@field limit number?
---@field line_height number
---@field shadow TextShadow?
---@field outline TextOutline?
---@field width number
---@field height number
---@field _cached_text string
---@field _cached_font love.Font
---@field _cached_limit number
local Text = {}
Text.__index = Text

---@param opts { text: string?, font: love.Font?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: number[]?, align: TextAlign?, valign: TextVAlign?, limit: number?, line_height: number?, shadow: TextShadow?, outline: TextOutline? }?
---@return TextDrawable
function Text.New(opts)
    opts = opts or {}

    local self = {
        text = opts.text or "",
        font = opts.font or love.graphics.getFont(),

        x = opts.x or 0,
        y = opts.y or 0,
        r = opts.r or 0,
        sx = opts.sx or 1,
        sy = opts.sy or 1,
        ox = opts.ox or 0,
        oy = opts.oy or 0,

        color = opts.color or {1, 1, 1, 1},

        align = opts.align or "left",
        valign = opts.valign or "top",
        limit = opts.limit,
        line_height = opts.line_height or 1.0,

        shadow = opts.shadow,
        outline = opts.outline,

        width = 0,
        height = 0,

        ---@type Node?
        _node = nil,
        _cached_text = nil,
        _cached_font = nil,
        _cached_limit = nil,
    }

    return setmetatable(self, Text)
end


    ---@private
Text._update_dimensions = function(self)
    if self._cached_text == self.text and self._cached_font == self.font and self._cached_limit == self.limit then
        return false
    end

    local old_width, old_height = self.width, self.height

    local font = self.font
    self._cached_font = font
    self._cached_text = self.text
    self._cached_limit = self.limit

    if self.limit then
        local _, lines = font:getWrap(self.text, self.limit)
        self.width = self.limit
        self.height = #lines * font:getHeight() * self.line_height
    else
        self.width = font:getWidth(self.text)
        self.height = font:getHeight() * self.line_height
    end

    local changed = self.width ~= old_width or self.height ~= old_height
    if changed and self._node and self._node._on_content_size_changed then
        self._node:_on_content_size_changed(self.width, self.height)
    end

    return changed
end

    ---@param text string
    ---@return TextDrawable
Text.SetText = function(self, text)
    self.text = text
    return self
end

---@param font love.Font
---@return TextDrawable
Text.SetFont = function(self, font)
    self.font = font
    return self
end

---@param color number[]
---@return TextDrawable
Text.SetColor = function(self, color)
    self.color = color
    return self
end

---@param align TextAlign
---@return TextDrawable
Text.SetAlign = function(self, align)
    self.align = align
    return self
end

---@param valign TextVAlign
---@return TextDrawable
Text.SetVAlign = function(self, valign)
    self.valign = valign
    return self
end

---@param limit number?
---@return TextDrawable
Text.SetLimit = function(self, limit)
    self.limit = limit
    return self
end

---@param shadow TextShadow?
---@return TextDrawable
Text.SetShadow = function(self, shadow)
    self.shadow = shadow
    return self
end

---@param outline TextOutline?
---@return TextDrawable
Text.SetOutline = function(self, outline)
    self.outline = outline
    return self
end

---@return number
Text.GetWidth = function(self)
    self:_update_dimensions()
    return self.width * self.sx
end

---@return number
Text.GetHeight = function(self)
    self:_update_dimensions()
    return self.height * self.sy
end

---@private
Text._draw_text = function(self, offset_x, offset_y, color)
    love.graphics.setColor(color)
    if self.limit then
        love.graphics.printf(self.text, offset_x, offset_y, self.limit, self.align)
    else
        love.graphics.print(self.text, offset_x, offset_y)
    end
end

Text.Draw = function(self)
    self:_update_dimensions()

    local prev_font = love.graphics.getFont()
    love.graphics.setFont(self.font)

    local container_w = self._node.width
    local container_h = self._node.height

    local x_offset = 0
    local y_offset = 0

    if self.align == "center" then
        x_offset = (container_w - self.width) / 2
    elseif self.align == "right" then
        x_offset = container_w - self.width
    end

    if self.valign == "middle" then
        y_offset = (container_h - self.height) / 2
    elseif self.valign == "bottom" then
        y_offset = container_h - self.height
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    local draw_x = -self.ox + x_offset
    local draw_y = -self.oy + y_offset

    if self.outline and self.outline.width > 0 then
        local w = self.outline.width
        local outline_color = self.outline.color or {0, 0, 0, 1}
        for dx = -w, w, w do
            for dy = -w, w, w do
                if dx ~= 0 or dy ~= 0 then
                    self:_draw_text(draw_x + dx, draw_y + dy, outline_color)
                end
            end
        end
    end

    if self.shadow then
        local shadow_color = self.shadow.color or {0, 0, 0, 0.5}
        self:_draw_text(draw_x + self.shadow.x, draw_y + self.shadow.y, shadow_color)
    end

    self:_draw_text(draw_x, draw_y, self.color)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(prev_font)
    love.graphics.pop()
end

return Text

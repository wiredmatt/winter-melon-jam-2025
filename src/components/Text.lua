---@alias TextAlign "left" | "center" | "right"
---@alias TextVAlign "top" | "middle" | "bottom"

---@class TextShadow
---@field x number
---@field y number
---@field color number[]

---@class TextOutline
---@field width number
---@field color number[]

---@class TextComponent : Component
---@field text string
---@field font love.Font
---@field x number
---@field y number
---@field r number
---@field sx number
---@field sy number
---@field ox number
---@field oy number
---@field color love.Color
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
---@field _draw_text fun(self, offset_x: number, offset_y: number, color: love.Color)
---@field _update_dimensions fun(self)

---@class TextComponentClass
---@field New fun(config: { text: string?, font: love.Font?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: love.Color?, align: TextAlign?, valign: TextVAlign?, limit: number?, line_height: number?, shadow: TextShadow?, outline: TextOutline? }?): TextComponent

local TextComponent = SceneGraph.Component.Define("Text", {
    ---@param self TextComponent
    ---@param config { text: string?, font: love.Font?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: love.Color?, align: TextAlign?, valign: TextVAlign?, limit: number?, line_height: number?, shadow: TextShadow?, outline: TextOutline? }
    Init = function(self, config)
        self.text = config.text or ""
        self.font = config.font or love.graphics.getFont()

        self.x = config.x or 0
        self.y = config.y or 0
        self.r = config.r or 0
        self.sx = config.sx or 1
        self.sy = config.sy or 1
        self.ox = config.ox or 0
        self.oy = config.oy or 0

        self.color = config.color or {1, 1, 1, 1}

        self.align = config.align or "left"
        self.valign = config.valign or "top"
        self.limit = config.limit
        self.line_height = config.line_height or 1.0

        self.shadow = config.shadow
        self.outline = config.outline

        self.width = 0
        self.height = 0

        self._cached_text = nil
        self._cached_font = nil
        self._cached_limit = nil

        -- Register as both Text and Drawable for queries
        self.types = {"Text", "Drawable"}
    end,

    ---@param self TextComponent
    ---@private
    _update_dimensions = function(self)
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

        return changed
    end,

    ---@param self TextComponent
    ---@param text string
    ---@return TextComponent
    SetText = function(self, text)
        self.text = text
        return self
    end,

    ---@param self TextComponent
    ---@param font love.Font
    ---@return TextComponent
    SetFont = function(self, font)
        self.font = font
        return self
    end,

    ---@param self TextComponent
    ---@param color love.Color
    ---@return TextComponent
    SetColor = function(self, color)
        self.color = color
        return self
    end,

    ---@param self TextComponent
    ---@param align TextAlign
    ---@return TextComponent
    SetAlign = function(self, align)
        self.align = align
        return self
    end,

    ---@param self TextComponent
    ---@param valign TextVAlign
    ---@return TextComponent
    SetVAlign = function(self, valign)
        self.valign = valign
        return self
    end,

    ---@param self TextComponent
    ---@param limit number?
    ---@return TextComponent
    SetLimit = function(self, limit)
        self.limit = limit
        return self
    end,

    ---@param self TextComponent
    ---@param shadow TextShadow?
    ---@return TextComponent
    SetShadow = function(self, shadow)
        self.shadow = shadow
        return self
    end,

    ---@param self TextComponent
    ---@param outline TextOutline?
    ---@return TextComponent
    SetOutline = function(self, outline)
        self.outline = outline
        return self
    end,

    ---@param self TextComponent
    ---@return number
    GetWidth = function(self)
        self:_update_dimensions()
        return self.width * self.sx
    end,

    ---@param self TextComponent
    ---@return number
    GetHeight = function(self)
        self:_update_dimensions()
        return self.height * self.sy
    end,

    ---@param self TextComponent
    ---@private
    _draw_text = function(self, offset_x, offset_y, color)
        love.graphics.setColor(color)
        if self.limit then
            love.graphics.printf(self.text, offset_x, offset_y, self.limit, self.align)
        else
            love.graphics.print(self.text, offset_x, offset_y)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end,

    ---@param self TextComponent
    Draw = function(self)
        self:_update_dimensions()

        local prev_font = love.graphics.getFont()
        love.graphics.setFont(self.font)

        local container_w = self.node and self.node.width or 0
        local container_h = self.node and self.node.height or 0

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
        love.graphics.translate(self.ox, self.oy)
        love.graphics.rotate(self.r)
        love.graphics.scale(self.sx, self.sy)
        love.graphics.translate(-self.ox, -self.oy)

        love.graphics.translate(self.x, self.y)

        local draw_x = x_offset
        local draw_y = y_offset

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

        love.graphics.setFont(prev_font)
        love.graphics.pop()
    end,
})

return TextComponent --[[@as TextComponentClass]]

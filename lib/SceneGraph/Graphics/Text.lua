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
---@field font love.Font?
---@field align TextAlign
---@field valign TextVAlign
---@field limit number?
---@field lineHeight number
---@field shadow TextShadow?
---@field outline TextOutline?
---@field width number
---@field height number
local Text = {}

---@param opts { text: string?, font: love.Font?, x: number?, y: number?, r: number?, sx: number?, sy: number?, ox: number?, oy: number?, color: number[]?, align: TextAlign?, valign: TextVAlign?, limit: number?, lineHeight: number?, shadow: TextShadow?, outline: TextOutline?, containerWidth: number?, containerHeight: number? }?
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
        lineHeight = opts.lineHeight or 1.0,

        shadow = opts.shadow,
        outline = opts.outline,

        -- Optional explicit container dimensions for alignment
        -- Falls back to node dimensions if not set
        containerWidth = opts.containerWidth,
        containerHeight = opts.containerHeight,

        width = 0,
        height = 0,

        ---@type BaseNode?
        _node = nil,
        _cachedText = nil,
        _cachedFont = nil,
        _cachedLimit = nil,
    }

    ---@private
    function self:_updateDimensions()
        if self._cachedText == self.text and self._cachedFont == self.font and self._cachedLimit == self.limit then
            return
        end

        local font = self.font
        self._cachedText = self.text
        self._cachedFont = font
        self._cachedLimit = self.limit

        if self.limit then
            local _, lines = font:getWrap(self.text, self.limit)
            self.width = self.limit
            self.height = #lines * font:getHeight() * self.lineHeight
        else
            self.width = font:getWidth(self.text)
            self.height = font:getHeight() * self.lineHeight
        end
    end

    ---@param text string
    ---@return TextDrawable
    function self:SetText(text)
        self.text = text
        return self
    end

    ---@param font love.Font
    ---@return TextDrawable
    function self:SetFont(font)
        self.font = font
        return self
    end

    ---@param color number[]
    ---@return TextDrawable
    function self:SetColor(color)
        self.color = color
        return self
    end

    ---@param align TextAlign
    ---@return TextDrawable
    function self:SetAlign(align)
        self.align = align
        return self
    end

    ---@param valign TextVAlign
    ---@return TextDrawable
    function self:SetVAlign(valign)
        self.valign = valign
        return self
    end

    ---@param limit number?
    ---@return TextDrawable
    function self:SetLimit(limit)
        self.limit = limit
        return self
    end

    ---@param shadow TextShadow?
    ---@return TextDrawable
    function self:SetShadow(shadow)
        self.shadow = shadow
        return self
    end

    ---@param outline TextOutline?
    ---@return TextDrawable
    function self:SetOutline(outline)
        self.outline = outline
        return self
    end

    ---@return number
    function self:GetWidth()
        self:_updateDimensions()
        return self.width * self.sx
    end

    ---@return number
    function self:GetHeight()
        self:_updateDimensions()
        return self.height * self.sy
    end

    ---@private
    function self:_drawText(offsetX, offsetY, color)
        love.graphics.setColor(color)
        if self.limit then
            love.graphics.printf(self.text, offsetX, offsetY, self.limit, self.align)
        else
            love.graphics.print(self.text, offsetX, offsetY)
        end
    end

    function self:Draw()
        self:_updateDimensions()

        local prevFont = love.graphics.getFont()
        love.graphics.setFont(self.font)

        -- Get container dimensions (explicit, or from node, or none)
        local containerW = self.containerWidth or (self._node and self._node.width)
        local containerH = self.containerHeight or (self._node and self._node.height)

        -- Calculate alignment offsets
        local xOffset = 0
        local yOffset = 0

        if containerW then
            -- Align within container
            if self.align == "center" then
                xOffset = (containerW - self.width) / 2
            elseif self.align == "right" then
                xOffset = containerW - self.width
            end
        else
            -- No container: align relative to position
            if self.align == "center" then
                xOffset = -self.width / 2
            elseif self.align == "right" then
                xOffset = -self.width
            end
        end

        if containerH then
            -- Align within container
            if self.valign == "middle" then
                yOffset = (containerH - self.height) / 2
            elseif self.valign == "bottom" then
                yOffset = containerH - self.height
            end
        else
            -- No container: align relative to position
            if self.valign == "middle" then
                yOffset = -self.height / 2
            elseif self.valign == "bottom" then
                yOffset = -self.height
            end
        end

        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.r)
        love.graphics.scale(self.sx, self.sy)

        local drawX = -self.ox + xOffset
        local drawY = -self.oy + yOffset

        -- Draw outline (multiple offset draws)
        if self.outline and self.outline.width > 0 then
            local w = self.outline.width
            local outlineColor = self.outline.color or {0, 0, 0, 1}
            -- 8-direction outline for smooth edges
            for dx = -w, w, w do
                for dy = -w, w, w do
                    if dx ~= 0 or dy ~= 0 then
                        self:_drawText(drawX + dx, drawY + dy, outlineColor)
                    end
                end
            end
        end

        -- Draw shadow
        if self.shadow then
            local shadowColor = self.shadow.color or {0, 0, 0, 0.5}
            self:_drawText(drawX + self.shadow.x, drawY + self.shadow.y, shadowColor)
        end

        -- Draw main text
        self:_drawText(drawX, drawY, self.color)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(prevFont)
        love.graphics.pop()
    end

    return self
end

return Text

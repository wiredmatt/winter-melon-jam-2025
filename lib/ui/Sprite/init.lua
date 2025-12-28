local Node = require("lib.ui.Node")

---@class SpriteConfig : NodeConfig
---@field image love.Image?
---@field quad love.Quad?
---@field color table?

---@class Sprite : Node
---@field image love.Image?
---@field quad love.Quad?
---@field color table
local Sprite = setmetatable({}, { __index = Node })
Sprite.__index = Sprite

---@param config SpriteConfig?
---@return Sprite
Sprite.New = function (config)
    config = config or {}

    -- calculate width/height from image if not provided
    if not config.width or not config.height then
        local img_w, img_h = 0, 0

        if config.quad and config.image then
            local _, _, qw, qh = config.quad:getViewport()
            img_w, img_h = qw, qh
        elseif config.image then
            img_w = config.image:getWidth()
            img_h = config.image:getHeight()
        end

        if not config.width then
            config.width = img_w
        end
        if not config.height then
            config.height = img_h
        end
    end

    local base_node = Node.New(config)

    local self = setmetatable(base_node, Sprite) --[[@as Sprite]]

    self.image = config.image
    self.quad = config.quad
    self.color = config.color or {1, 1, 1, 1}  -- White (no tint)

    return self
end

---@param image love.Image?
---@param quad love.Quad?
Sprite.SetImage = function (self, image, quad)
    self.image = image
    self.quad = quad

    if self.quad and self.image then
        local _, _, qw, qh = self.quad:getViewport()
        self.width, self.height = qw, qh
    elseif self.image then
        self.width = self.image:getWidth()
        self.height = self.image:getHeight()
    else
        self.width, self.height = 0, 0
    end
end

Sprite.Draw = function (self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    local pr, pg, pb, pa = love.graphics.getColor()

    if self.image then
        love.graphics.setColor(self.color)
        if self.quad then
            love.graphics.draw(self.image, self.quad, 0, 0)
        else
            love.graphics.draw(self.image, 0, 0)
        end
    end

    love.graphics.setColor(pr, pg, pb, pa)

    for _, child in ipairs(self.children) do
        child:Draw()
    end

    self:DrawDebugOverlay()

    love.graphics.pop()
end

return Sprite

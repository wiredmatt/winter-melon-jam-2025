---@class BaseNodeConfig
---@field x number?
---@field y number?
---@field r number?
---@field sx number?
---@field sy number?
---@field width number?
---@field height number?
---@field enabled boolean?
---@field visible boolean?

---@class BaseNode : BaseNodeConfig
---@field parent BaseNode?
---@field children BaseNode[]
---@field plugins { [table]: boolean }
local BaseNode = {}
BaseNode.__index = BaseNode

---@param config BaseNodeConfig?
BaseNode.New = function(config)
    config = config or {}
    local self = setmetatable(config, BaseNode)

    self.x = self.x or 0
    self.y = self.y or 0
    self.r = self.r or 0
    self.sx = self.sx or 1
    self.sy = self.sy or 1
    self.width = self.width or 0
    self.height = self.height or 0

    self.children = {}

    self.enabled = self.enabled or true
    self.visible = self.visible or true
    self.plugins = {}

    return self --[[@as BaseNode]]
end

---@param child BaseNode
BaseNode.AddChild = function(self, child)
    if child.parent then
        child.parent:RemoveChild(child)
    end

    table.insert(self.children, child)
    child.parent = self
end

---@param child BaseNode
---@return boolean
BaseNode.RemoveChild = function(self, child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            return true
        end
    end
    return false
end

---@return number x, number y, number r, number sx, number sy
BaseNode.GetWorldTransform = function(self)
    if not self.parent then
        return self.x, self.y, self.r, self.sx, self.sy
    end

    local px, py, pr, psx, psy = self.parent:GetWorldTransform()

    -- apply parent rotation to local position
    local cos_r = math.cos(pr)
    local sin_r = math.sin(pr)
    local rx = self.x * cos_r - self.y * sin_r
    local ry = self.x * sin_r + self.y * cos_r

    -- accumulate transforms
    local wx = px + rx * psx
    local wy = py + ry * psy
    local wr = pr + self.r
    local wsx = psx * self.sx
    local wsy = psy * self.sy

    return wx, wy, wr, wsx, wsy
end

BaseNode.Draw = function(self)
    if not self.visible then return end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    -- override this method in subclasses to draw content here
    -- ...

    -- draw all children after
    for _, child in ipairs(self.children) do
        child:Draw()
    end

    love.graphics.pop()
end

---@param dt number
BaseNode.Update = function(self, dt)
    -- override this method in subclasses
    -- ...

    -- update all children
    for _, child in ipairs(self.children) do
        child:Update(dt)
    end
end

---@return number x, number y, number width, number height
BaseNode.GetLocalBounds = function(self)
    return 0, 0, self.width, self.height
end

---@param wx number world X coordinate
---@param wy number world Y coordinate
---@return number lx, number ly
BaseNode.WorldToLocal = function(self, wx, wy)
    local world_x, world_y, world_r, world_sx, world_sy = self:GetWorldTransform()

    local tx = wx - world_x
    local ty = wy - world_y

    local cos_r = math.cos(-world_r)
    local sin_r = math.sin(-world_r)
    local rx = tx * cos_r - ty * sin_r
    local ry = tx * sin_r + ty * cos_r

    local lx = rx / world_sx
    local ly = ry / world_sy

    return lx, ly
end

---@param wx number world X coordinate
---@param wy number world Y coordinate
---@return boolean
BaseNode.ContainsPoint = function(self, wx, wy)
    if not self.enabled then
        return false
    end

    local lx, ly = self:WorldToLocal(wx, wy)

    local bx, by, bw, bh = self:GetLocalBounds()
    return lx >= bx and lx <= bx + bw and ly >= by and ly <= by + bh
end

BaseNode.Destroy = function(self)
    if self.parent then
        self.parent:RemoveChild(self)
    end

    for i = #self.children, 1, -1 do
        self.children[i]:Destroy()
    end

    self.children = {}
end


return BaseNode

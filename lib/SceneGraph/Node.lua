---@class NodeConfig
---@field x number?
---@field y number?
---@field r number?
---@field sx number?
---@field sy number?
---@field ox number?
---@field oy number?
---@field width number?
---@field height number?
---@field enabled boolean?
---@field visible boolean?

---@class Node : NodeConfig
---@field x number
---@field y number
---@field r number
---@field sx number
---@field sy number
---@field ox number
---@field oy number
---@field width number
---@field height number
---@field parent Node?
---@field children Node[]
---@field plugins { [table]: boolean }
---@field graphics NodeGraphics
---@field _transform_dirty boolean
---@field _cached_wx number
---@field _cached_wy number
---@field _cached_wr number
---@field _cached_wsx number
---@field _cached_wsy number
---@field _layer Layer?
local Node = {}
Node.__index = Node

---@param config NodeConfig?
Node.New = function(config)
    config = config or {}
    local self = setmetatable(config, Node)

    self.x = self.x or 0
    self.y = self.y or 0
    self.r = self.r or 0
    self.sx = self.sx or 1
    self.sy = self.sy or 1
    self.ox = self.ox or 0
    self.oy = self.oy or 0
    self.width = self.width or 0
    self.height = self.height or 0

    self.children = {}

    self.enabled = self.enabled or true
    self.visible = self.visible or true
    self.plugins = {}

    -- transform cache (dirty by default, computed on first GetWorldTransform)
    self._transform_dirty = true
    self._cached_wx = 0
    self._cached_wy = 0
    self._cached_wr = 0
    self._cached_wsx = 1
    self._cached_wsy = 1

    return self --[[@as Node]]
end

---@param child Node
Node.AddChild = function(self, child)
    if child.parent then
        child.parent:RemoveChild(child)
    end

    table.insert(self.children, child)
    child.parent = self
    child:MarkTransformDirty()

    -- Propagate layer to child and its descendants
    if self._layer then
        child:SetLayerRecursive(self._layer)
    end
end

---@param child Node
---@return boolean
Node.RemoveChild = function(self, child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            child:MarkTransformDirty()
            return true
        end
    end
    return false
end

--- marks this node and all descendants as needing transform recalculation.
Node.MarkTransformDirty = function(self)
    if self._transform_dirty then
        return -- already dirty, children must be dirty too
    end
    self._transform_dirty = true
    for _, child in ipairs(self.children) do
        child:MarkTransformDirty()
    end
end

--- Sets the layer reference on this node and all descendants
---@param layer Layer?
Node.SetLayerRecursive = function(self, layer)
    self._layer = layer
    for _, child in ipairs(self.children) do
        child:SetLayerRecursive(layer)
    end
end

---@param x number
---@param y number
Node.SetPosition = function(self, x, y)
    if self.x ~= x or self.y ~= y then
        self.x = x
        self.y = y
        self:MarkTransformDirty()
    end
end

---@param x number
Node.SetX = function(self, x)
    if self.x ~= x then
        self.x = x
        self:MarkTransformDirty()
    end
end

---@param y number
Node.SetY = function(self, y)
    if self.y ~= y then
        self.y = y
        self:MarkTransformDirty()
    end
end

---@param r number
Node.SetRotation = function(self, r)
    if self.r ~= r then
        self.r = r
        self:MarkTransformDirty()
    end
end

---@param sx number
---@param sy number?
Node.SetScale = function(self, sx, sy)
    sy = sy or sx
    if self.sx ~= sx or self.sy ~= sy then
        self.sx = sx
        self.sy = sy
        self:MarkTransformDirty()
    end
end

---@param sx number
Node.SetSX = function(self, sx)
    if self.sx ~= sx then
        self.sx = sx
        self:MarkTransformDirty()
    end
end

---@param sy number
Node.SetSY = function(self, sy)
    if self.sy ~= sy then
        self.sy = sy
        self:MarkTransformDirty()
    end
end

---@param ox number
---@param oy number
Node.SetOrigin = function(self, ox, oy)
    if self.ox ~= ox or self.oy ~= oy then
        self.ox = ox
        self.oy = oy
        self:MarkTransformDirty()
    end
end

---@param ox number
Node.SetOX = function(self, ox)
    if self.ox ~= ox then
        self.ox = ox
        self:MarkTransformDirty()
    end
end

---@param oy number
Node.SetOY = function(self, oy)
    if self.oy ~= oy then
        self.oy = oy
        self:MarkTransformDirty()
    end
end

---@param w number
Node.SetWidth = function(self, w)
    if self.width ~= w then
        self.width = w
        if self._on_size_changed then
            self:_on_size_changed()
        end
    end
end

---@param h number
Node.SetHeight = function(self, h)
    if self.height ~= h then
        self.height = h
        if self._on_size_changed then
            self:_on_size_changed()
        end
    end
end

---@param w number
---@param h number
Node.SetSize = function(self, w, h)
    if self.width ~= w or self.height ~= h then
        self.width = w
        self.height = h
        if self._on_size_changed then
            self:_on_size_changed()
        end
    end
end

---@return number x, number y, number r, number sx, number sy
Node.GetWorldTransform = function(self)
    if not self._transform_dirty then
        return self._cached_wx, self._cached_wy, self._cached_wr, self._cached_wsx, self._cached_wsy
    end

    local wx, wy, wr, wsx, wsy = 0, 0, 0, 1, 1

    if not self.parent then
        wx, wy, wr, wsx, wsy = self.x, self.y, self.r, self.sx, self.sy
    else
        local px, py, pr, psx, psy = self.parent:GetWorldTransform()

        -- apply parent rotation to local position
        local cos_r = math.cos(pr)
        local sin_r = math.sin(pr)
        local rx = self.x * cos_r - self.y * sin_r
        local ry = self.x * sin_r + self.y * cos_r

        -- accumulate transforms
        wx = px + rx * psx
        wy = py + ry * psy
        wr = pr + self.r
        wsx = psx * self.sx
        wsy = psy * self.sy
    end

    -- Cache the computed values
    self._cached_wx = wx
    self._cached_wy = wy
    self._cached_wr = wr
    self._cached_wsx = wsx
    self._cached_wsy = wsy
    self._transform_dirty = false

    return wx, wy, wr, wsx, wsy
end

Node.Draw = function(self)
    if not self.visible then return end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    if self.ox ~= 0 or self.oy ~= 0 then
        love.graphics.translate(-self.ox, -self.oy)
    end

    -- draw graphics layers
    if self.graphics then
        self.graphics:Draw()
    end

    -- draw all children after
    for _, child in ipairs(self.children) do
        child:Draw()
    end

    love.graphics.pop()
end

---@param dt number
Node.Update = function(self, dt)
    -- override this method in subclasses
    -- ...

    -- update all children
    for _, child in ipairs(self.children) do
        child:Update(dt)
    end
end

---@return number x, number y, number width, number height
Node.GetLocalBounds = function(self)
    return -self.ox, -self.oy, self.width, self.height
end

---@param wx number world X coordinate
---@param wy number world Y coordinate
---@return number lx, number ly
Node.WorldToLocal = function(self, wx, wy)
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
Node.ContainsPoint = function(self, wx, wy)
    if not self.enabled then
        return false
    end

    local lx, ly = self:WorldToLocal(wx, wy)

    local bx, by, bw, bh = self:GetLocalBounds()
    return lx >= bx and lx <= bx + bw and ly >= by and ly <= by + bh
end

Node.Destroy = function(self)
    if self.parent then
        self.parent:RemoveChild(self)
    end

    for i = #self.children, 1, -1 do
        self.children[i]:Destroy()
    end

    self.children = {}
end


return Node

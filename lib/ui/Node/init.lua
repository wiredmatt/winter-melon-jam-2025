---@class NodeConfig
---@field x number?
---@field y number?
---@field r number?
---@field sx number?
---@field sy number?
---@field width number?
---@field height number?
---@field enabled boolean?

---@class Node : NodeConfig
---@field parent Node?
---@field children Node[]
---@field width number
---@field height number
---@field enabled boolean
---@field hovered boolean
---@field OnHover function?
---@field OnLeave function?
---@field debug_color table
local Node = {}
Node.__index = Node

---@param config NodeConfig?
---@return Node
Node.New = function (config)
    config = config or {}
    local self = setmetatable({}, Node)

    self.x = config.x or 0
    self.y = config.y or 0
    self.r = config.r or 0
    self.sx = config.sx or 1
    self.sy = config.sy or 1
    self.width = config.width or 0
    self.height = config.height or 0
    self.enabled = config.enabled ~= false
    self.hovered = false
    self.parent = nil
    self.children = {}
    self.OnHover = nil
    self.OnLeave = nil

    self.debug_color = {
        math.random(),
        math.random(),
        math.random(),
        1
    }

    return self
end

---@param child Node
Node.AddChild = function (self, child)
    -- Remove from old parent if exists
    if child.parent then
        child.parent:RemoveChild(child)
    end

    -- then add to this node
    table.insert(self.children, child)
    child.parent = self
end

---@param child Node
---@return boolean success
Node.RemoveChild = function (self, child)
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
Node.GetWorldTransform = function (self)
    if not self.parent then
        return self.x, self.y, self.r, self.sx, self.sy
    end

    local px, py, pr, psx, psy = self.parent:GetWorldTransform()

    -- Apply parent rotation to local position
    local cos_r = math.cos(pr)
    local sin_r = math.sin(pr)
    local rx = self.x * cos_r - self.y * sin_r
    local ry = self.x * sin_r + self.y * cos_r

    -- Accumulate transforms
    local wx = px + rx * psx
    local wy = py + ry * psy
    local wr = pr + self.r
    local wsx = psx * self.sx
    local wsy = psy * self.sy

    return wx, wy, wr, wsx, wsy
end

-- NOTE(matt): call this at the end of every draw override, but before pop()
Node.DrawDebugOverlay = function (self)
    if _G.DEBUG_UI and (self.width > 0 or self.height > 0) then
        local pr, pg, pb, pa = love.graphics.getColor()
        local prev_line_width = love.graphics.getLineWidth()

        love.graphics.setColor(self.debug_color)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", 0, 0, self.width, self.height)

        love.graphics.setColor(pr, pg, pb, pa)
        love.graphics.setLineWidth(prev_line_width)
    end
end

Node.Draw = function (self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    -- Override this method in subclasses to draw content here
    -- ...

    -- Draw all children after
    for _, child in ipairs(self.children) do
        child:Draw()
    end

    -- Draw debug outline
    self:DrawDebugOverlay()

    love.graphics.pop()
end

---@param dt number
Node.Update = function (self, dt)
    -- Override this method in subclasses to update logic here
    -- ...

    -- Update all children
    for _, child in ipairs(self.children) do
        child:Update(dt)
    end
end

---Get local bounds (AABB)
---@return number x, number y, number width, number height
Node.GetLocalBounds = function (self)
    return 0, 0, self.width, self.height
end

---@param wx number World X coordinate
---@param wy number World Y coordinate
---@return number lx, number ly Local coordinates
Node.WorldToLocal = function (self, wx, wy)
    -- Get world transform
    local world_x, world_y, world_r, world_sx, world_sy = self:GetWorldTransform()

    -- Translate to origin
    local tx = wx - world_x
    local ty = wy - world_y

    -- Inverse rotate
    local cos_r = math.cos(-world_r)
    local sin_r = math.sin(-world_r)
    local rx = tx * cos_r - ty * sin_r
    local ry = tx * sin_r + ty * cos_r

    -- Inverse scale
    local lx = rx / world_sx
    local ly = ry / world_sy

    return lx, ly
end

---@param wx number World X coordinate
---@param wy number World Y coordinate
---@return boolean
Node.ContainsPoint = function (self, wx, wy)
    if not self.enabled then
        return false
    end

    local lx, ly = self:WorldToLocal(wx, wy)

    -- Check bounds
    local bx, by, bw, bh = self:GetLocalBounds()
    return lx >= bx and lx <= bx + bw and ly >= by and ly <= by + bh
end

Node.Destroy = function (self)
    -- Remove from parent
    if self.parent then
        self.parent:RemoveChild(self)
    end

    -- Destroy all children
    for i = #self.children, 1, -1 do
        self.children[i]:Destroy()
    end

    self.children = {}
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param dx number Mouse delta X
---@param dy number Mouse delta Y
---@return boolean consumed True if event was handled
Node.HandleMouseMoved = function (self, x, y, dx, dy)
    local was_hovered = self.hovered
    local is_hovered = self:ContainsPoint(x, y)

    -- Update hover state
    self.hovered = is_hovered

    -- Trigger callbacks on state change
    if is_hovered and not was_hovered then
        if self.OnHover then
            self.OnHover()
        end
    elseif not is_hovered and was_hovered then
        if self.OnLeave then
            self.OnLeave()
        end
    end

    -- Propagate to children
    for _, child in ipairs(self.children) do
        if child.HandleMouseMoved then
            if child:HandleMouseMoved(x, y, dx, dy) then
                return true  -- Child consumed event
            end
        end
    end

    return is_hovered  -- Consume if hovered
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button (1 = left, 2 = right, 3 = middle)
---@return boolean consumed True if event was handled
Node.HandleMousePressed = function (self, x, y, button)
    -- Propagate to children
    for _, child in ipairs(self.children) do
        if child.HandleMousePressed then
            if child:HandleMousePressed(x, y, button) then
                return true  -- Child consumed event
            end
        end
    end

    -- Check if within bounds
    return self:ContainsPoint(x, y)
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button (1 = left, 2 = right, 3 = middle)
---@return boolean consumed True if event was handled
Node.HandleMouseReleased = function (self, x, y, button)
    -- Propagate to children
    for _, child in ipairs(self.children) do
        if child.HandleMouseReleased then
            if child:HandleMouseReleased(x, y, button) then
                return true  -- Child did consume event
            end
        end
    end

    return false
end

return Node
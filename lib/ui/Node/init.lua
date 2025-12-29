---@class NodeConfig
---@field x number?
---@field y number?
---@field r number?
---@field sx number?
---@field sy number?
---@field width number?
---@field height number?
---@field enabled boolean?
---@field focusable boolean?

---@class Node : NodeConfig
---@field parent Node?
---@field children Node[]
---@field width number
---@field height number
---@field enabled boolean
---@field hovered boolean
---@field focusable boolean
---@field focused boolean
---@field OnHover function?
---@field OnLeave function?
---@field OnFocus function?
---@field OnBlur function?
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
    self.focusable = config.focusable or false
    self.focused = false
    self.parent = nil
    self.children = {}
    self.OnHover = nil
    self.OnLeave = nil
    self.OnFocus = nil
    self.OnBlur = nil

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

---@return number x, number y, number width, number height
Node.GetLocalBounds = function (self)
    return 0, 0, self.width, self.height
end

---@param wx number World X coordinate
---@param wy number World Y coordinate
---@return number lx, number ly
Node.WorldToLocal = function (self, wx, wy)
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

---@param wx number World X coordinate
---@param wy number World Y coordinate
---@return boolean
Node.ContainsPoint = function (self, wx, wy)
    if not self.enabled then
        return false
    end

    local lx, ly = self:WorldToLocal(wx, wy)

    local bx, by, bw, bh = self:GetLocalBounds()
    return lx >= bx and lx <= bx + bw and ly >= by and ly <= by + bh
end

Node.Destroy = function (self)
    if self.parent then
        self.parent:RemoveChild(self)
    end

    for i = #self.children, 1, -1 do
        self.children[i]:Destroy()
    end

    self.children = {}
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param dx number Mouse delta X
---@param dy number Mouse delta Y
---@return boolean consumed
Node.HandleMouseMoved = function (self, x, y, dx, dy)
    local was_hovered = self.hovered
    local is_hovered = self:ContainsPoint(x, y)

    self.hovered = is_hovered

    if is_hovered and not was_hovered then
        if self.OnHover then
            self.OnHover()
        end
    elseif not is_hovered and was_hovered then
        if self.OnLeave then
            self.OnLeave()
        end
    end

    for _, child in ipairs(self.children) do
        if child.HandleMouseMoved then
            if child:HandleMouseMoved(x, y, dx, dy) then
                return true  -- Child consumed event
            end
        end
    end

    return is_hovered
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button (1 = left, 2 = right, 3 = middle)
---@return boolean consumed
Node.HandleMousePressed = function (self, x, y, button)
    for _, child in ipairs(self.children) do
        if child.HandleMousePressed then
            if child:HandleMousePressed(x, y, button) then
                return true  -- Child consumed event
            end
        end
    end

    return self:ContainsPoint(x, y)
end

---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button number Mouse button (1 = left, 2 = right, 3 = middle)
---@return boolean consumed
Node.HandleMouseReleased = function (self, x, y, button)
    for _, child in ipairs(self.children) do
        if child.HandleMouseReleased then
            if child:HandleMouseReleased(x, y, button) then
                return true  -- Child did consume event
            end
        end
    end

    return false
end

-- Focus Management

---Get the world-space center position of this node
---@return number cx, number cy
Node.GetWorldCenter = function (self)
    local wx, wy = self:GetWorldTransform()
    return wx + self.width / 2, wy + self.height / 2
end

---Recursively get all focusable descendants
---@return Node[]
Node.GetFocusableDescendants = function (self)
    local focusables = {}

    if self.focusable and self.enabled then
        table.insert(focusables, self)
    end

    for _, child in ipairs(self.children) do
        if child.GetFocusableDescendants then
            local child_focusables = child:GetFocusableDescendants()
            for _, focusable in ipairs(child_focusables) do
                table.insert(focusables, focusable)
            end
        end
    end

    return focusables
end

---@return Node?
Node.GetFocused = function (self)
    if self.focused then
        return self
    end

    for _, child in ipairs(self.children) do
        if child.GetFocused then
            local focused = child:GetFocused()
            if focused then
                return focused
            end
        end
    end

    return nil
end

Node.ClearFocus = function (self)
    if self.focused then
        self.focused = false
        if self.OnBlur then
            self.OnBlur()
        end
    end

    for _, child in ipairs(self.children) do
        if child.ClearFocus then
            child:ClearFocus()
        end
    end
end

---@param node Node?
Node.SetFocused = function (self, node)
    self:ClearFocus()

    if node then
        node.focused = true
        if node.OnFocus then
            node.OnFocus()
        end
    end
end

---@param dx number Direction X (-1 for left, 1 for right, 0 for vertical only)
---@param dy number Direction Y (-1 for up, 1 for down, 0 for horizontal only)
---@return boolean success True if focus changed
Node.FocusDirection = function (self, dx, dy)
    local current = self:GetFocused()
    local focusables = self:GetFocusableDescendants()

    if not current then
        if #focusables > 0 then
            self:SetFocused(focusables[1])
            return true
        end
        return false
    end

    local cx, cy = current:GetWorldCenter()

    local dir_length = math.sqrt(dx * dx + dy * dy)
    if dir_length == 0 then return false end
    dx = dx / dir_length
    dy = dy / dir_length

    local best_candidate = nil
    local best_score = -math.huge
    local best_distance = math.huge

    for _, candidate in ipairs(focusables) do
        if candidate ~= current then
            local nx, ny = candidate:GetWorldCenter()

            local delta_x = nx - cx
            local delta_y = ny - cy

            local alignment = delta_x * dx + delta_y * dy

            if alignment > 0 then
                local distance = math.sqrt(delta_x * delta_x + delta_y * delta_y)

                local score = alignment / distance

                if score > best_score or (math.abs(score - best_score) < 0.001 and distance < best_distance) then
                    best_score = score
                    best_distance = distance
                    best_candidate = candidate
                end
            end
        end
    end

    if best_candidate then
        self:SetFocused(best_candidate)
        return true
    end

    return false
end

---@return boolean success True if an action was triggered
Node.ActivateFocused = function (self)
    local focused = self:GetFocused()

    if focused and focused.OnClick then
        focused.OnClick()
        return true
    end

    return false
end

return Node
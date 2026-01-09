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
---@field _components Component[]?
---@field _components_by_type { [string]: Component[] }?
---@field _components_by_name { [string]: Component }?
---@field _event_handlers { [string]: EventHandler[] }?
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
    end
end

---@param h number
Node.SetHeight = function(self, h)
    if self.height ~= h then
        self.height = h
    end
end

---@param w number
---@param h number
Node.SetSize = function(self, w, h)
    if self.width ~= w or self.height ~= h then
        self.width = w
        self.height = h
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

    love.graphics.translate(self.ox, self.oy)

    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    love.graphics.translate(-self.ox, -self.oy)
    love.graphics.translate(self.x, self.y)

    -- dispatch Draw event to components
    self:Dispatch("Draw")

    -- draw all children after
    for _, child in ipairs(self.children) do
        child:Draw()
    end

    love.graphics.pop()
end

---@param dt number
Node.Update = function(self, dt)
    self:Dispatch("Update", dt)

    for _, child in ipairs(self.children) do
        child:Update(dt)
    end
end

---@return number x, number y, number width, number height
Node.GetLocalBounds = function(self)
    return 0, 0, self.width, self.height
end

---@param wx number world X coordinate
---@param wy number world Y coordinate
---@return number lx, number ly
Node.WorldToLocal = function(self, wx, wy)
    local world_x, world_y, world_r, world_sx, world_sy = self:GetWorldTransform()

    local tx = wx - world_x
    local ty = wy - world_y

    tx = tx + self.ox
    ty = ty + self.oy

    local sx_inv = tx / world_sx
    local sy_inv = ty / world_sy

    local cos_r = math.cos(-world_r)
    local sin_r = math.sin(-world_r)
    local rx = sx_inv * cos_r - sy_inv * sin_r
    local ry = sx_inv * sin_r + sy_inv * cos_r

    local lx = rx - self.ox
    local ly = ry - self.oy

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
    if self._components then
        for i = #self._components, 1, -1 do
            local component = self._components[i]
            if component.OnRemoved then
                component:OnRemoved()
            end
        end
        self._components = nil
        self._components_by_type = nil
        self._components_by_name = nil
    end

    if self.parent then
        self.parent:RemoveChild(self)
    end

    for i = #self.children, 1, -1 do
        self.children[i]:Destroy()
    end

    self.children = {}
end

---@class EventHandler
---@field callback function
---@field tag string?

---@param component Component
---@return Node self (for chaining)
Node.AddComponent = function(self, component)
    self._components = self._components or {}
    self._components_by_type = self._components_by_type or {}

    table.insert(self._components, component)
    component.node = self

    local t = component.type
    self._components_by_type[t] = self._components_by_type[t] or {}
    table.insert(self._components_by_type[t], component)

    if component.types then
        for _, additional_type in ipairs(component.types) do
            if additional_type ~= t then
                self._components_by_type[additional_type] = self._components_by_type[additional_type] or {}
                table.insert(self._components_by_type[additional_type], component)
            end
        end
    end

    if component.name then
        self._components_by_name = self._components_by_name or {}
        self._components_by_name[component.name] = component
    end

    if component.OnAdded then
        component:OnAdded()
    end

    self:Dispatch("ComponentAdded", component)

    return self
end

---@param component_or_type Component|string
---@return boolean success
Node.RemoveComponent = function(self, component_or_type)
    if not self._components then return false end

    local component = component_or_type --[[@as Component|nil]]
    if type(component_or_type) == "string" then
        component = self:GetComponent(component_or_type)
        if not component then return false end
    end
    if component == nil then return false end

    if component.OnRemoved then
        component:OnRemoved()
    end

    for i, comp in ipairs(self._components) do
        if comp == component then
            table.remove(self._components, i)
            break
        end
    end

    if self._components_by_type then
        for _, comps in pairs(self._components_by_type) do
            for i, comp in ipairs(comps) do
                if comp == component then
                    table.remove(comps, i)
                    break
                end
            end
        end
    end

    if component.name and self._components_by_name then
        self._components_by_name[component.name] = nil
    end

    component.node = nil
    self:Dispatch("ComponentRemoved", component)
    return true
end

---@param type string
---@return Component?
Node.GetComponent = function(self, type)
    if not self._components_by_type then return nil end
    local comps = self._components_by_type[type]
    return comps and comps[1]
end

---@param type string
---@return Component[]
Node.GetComponents = function(self, type)
    if not self._components_by_type then return {} end
    return self._components_by_type[type] or {}
end

---@param name string
---@return Component?
Node.GetComponentByName = function(self, name)
    if not self._components_by_name then return nil end
    return self._components_by_name[name]
end

---@param type string
---@return boolean
Node.HasComponent = function(self, type)
    return self:GetComponent(type) ~= nil
end

---@param event_name string
---@param callback function
---@param tag string?
---@return Node self
Node.On = function(self, event_name, callback, tag)
    self._event_handlers = self._event_handlers or {}
    self._event_handlers[event_name] = self._event_handlers[event_name] or {}

    table.insert(self._event_handlers[event_name], {
        callback = callback,
        tag = tag
    })

    return self
end

---@param event_name string?
---@param tag string?
---@return Node self
Node.Off = function(self, event_name, tag)
    if not self._event_handlers then return self end

    if event_name then
        if tag then
            local handlers = self._event_handlers[event_name]
            if handlers then
                local filtered = {}
                for _, h in ipairs(handlers) do
                    if h.tag ~= tag then
                        table.insert(filtered, h)
                    end
                end
                self._event_handlers[event_name] = filtered
            end
        else
            self._event_handlers[event_name] = nil
        end
    elseif tag then
        for _, handlers in pairs(self._event_handlers) do
            local filtered = {}
            for _, h in ipairs(handlers) do
                if h.tag ~= tag then
                    table.insert(filtered, h)
                end
            end
            handlers = filtered
        end
    else
        self._event_handlers = {}
    end

    return self
end

---@param event_name string
---@param ... any
Node.Dispatch = function(self, event_name, ...)
    if self._components then
        for _, component in ipairs(self._components) do
            if component.enabled and component[event_name] then
                component[event_name](component, ...)
            end
        end
    end

    if self._event_handlers and self._event_handlers[event_name] then
        for _, handler in ipairs(self._event_handlers[event_name]) do
            handler.callback(self, ...)
        end
    end
end


return Node

---@class MouseInputPlugin : Plugin
---@field private _mouseprovider MouseInputSource
---@field private _nodes { [BaseNode]: true }
---@field private _hovered BaseNode|nil
---@field private _pressed { [1|2|3]: BaseNode|nil }
---@field private _dirty boolean
---@field private _sorted_layers Layer[]
---@field private _layer_nodes { [Layer]: BaseNode[] }
---@field private _no_layer_nodes BaseNode[]
local MouseInputPlugin = {
    name = "MouseInputPlugin",
    _nodes = {},
    _hovered = nil,
    _pressed = {},
    _dirty = true,
    _sorted_layers = {},
    _layer_nodes = {},
    _no_layer_nodes = {},
}

---@param node BaseNode
---@return integer[]
local function GetTreePath(node)
    local path = {}
    ---@type BaseNode|nil
    local current = node

    while current do
        local parent = current.parent
        if not parent then break end

        for i, child in ipairs(parent.children) do
            if child == current then
                table.insert(path, 1, i)
                break
            end
        end
        current = parent
    end

    return path
end

---@param a BaseNode
---@param b BaseNode
---@return boolean b_on_top true if a is rendered before b (meaning b is on top)
local function CompareByTreeOrder(a, b)
    local path_a = GetTreePath(a)
    local path_b = GetTreePath(b)

    local min_len = math.min(#path_a, #path_b)
    for i = 1, min_len do
        if path_a[i] ~= path_b[i] then
            return path_a[i] < path_b[i]
        end
    end

    -- if one path is a prefix of the other, the shorter one (ancestor) renders first
    return #path_a < #path_b
end

--- transform screen coordinates to world coordinates using inverse camera transform
--- Layer.Draw applies: scale(1/s) -> rotate(-r) -> translate(-pos)
--- inverse is: scale(s) -> rotate(+r) -> translate(+pos)
---@param screenx number
---@param screeny number
---@param camera BaseNode?
---@return number wx, number wy world coordinates
local function ScreenToWorld(screenx, screeny, camera)
    if not camera then
        return screenx, screeny
    end

    local cx, cy, cr, csx, csy = camera:GetWorldTransform()

    -- step 1: scale (undo 1/scale)
    local tx = screenx * csx
    local ty = screeny * csy

    -- step 2: rotate by +cr (undo -cr rotation)
    local cos_r = math.cos(cr)
    local sin_r = math.sin(cr)
    local rx = tx * cos_r - ty * sin_r
    local ry = tx * sin_r + ty * cos_r

    -- step 3: translate (undo -position)
    local wx = rx + cx
    local wy = ry + cy

    return wx, wy
end

local function RebuildSortedCache()
    local layer_set = {}  ---@type { [Layer]: boolean }
    local layer_nodes = {}  ---@type { [Layer]: BaseNode[] }
    local no_layer_nodes = {}  ---@type BaseNode[]

    for node in pairs(MouseInputPlugin._nodes) do
        local layer = node._layer
        if layer then
            layer_set[layer] = true
            if not layer_nodes[layer] then
                layer_nodes[layer] = {}
            end
            table.insert(layer_nodes[layer], node)
        else
            table.insert(no_layer_nodes, node)
        end
    end

    -- sort layers by render_order descending (highest first for hit testing)
    local sorted_layers = {}
    for layer in pairs(layer_set) do
        table.insert(sorted_layers, layer)
    end
    table.sort(sorted_layers, function(a, b)
        return a.render_order > b.render_order
    end)

    -- sort nodes within each layer by tree order
    for _, nodes in pairs(layer_nodes) do
        table.sort(nodes, CompareByTreeOrder)
    end

    -- sort no-layer nodes by tree order
    table.sort(no_layer_nodes, CompareByTreeOrder)

    MouseInputPlugin._sorted_layers = sorted_layers
    MouseInputPlugin._layer_nodes = layer_nodes
    MouseInputPlugin._no_layer_nodes = no_layer_nodes
    MouseInputPlugin._dirty = false
end

---if reparenting nodes with AddChild/RemoveChild after they've installed this plugin, 
---call MouseInputPlugin.MarkDirty() to re-sort on the next frame
---@param node BaseNode
MouseInputPlugin.InstallTo = function(node)
    if node.plugins[MouseInputPlugin] == nil then
        node.plugins[MouseInputPlugin] = true
        MouseInputPlugin._nodes[node] = true
        MouseInputPlugin._dirty = true
        local __og_Destroy = node.Destroy
        node.Destroy = function (...)
            MouseInputPlugin.UninstallFrom(node)
            return __og_Destroy(...)
        end
    end

    ---@class BaseNode
    ---@field OnMouseMove fun(self: BaseNode, x: number, y: number): boolean|nil
    ---@field OnMouseMoveBubble fun(self: BaseNode, x: number, y: number, child: BaseNode): boolean|nil
    ---@field OnMouseEnter fun(self: BaseNode, x: number, y: number): boolean|nil
    ---@field OnMouseEnterBubble fun(self: BaseNode, x: number, y: number, child: BaseNode): boolean|nil
    ---@field OnMouseLeave fun(self: BaseNode): boolean|nil
    ---@field OnMouseDown fun(self: BaseNode, x: number, y: number, btn: integer): boolean|nil
    ---@field OnMouseDownBubble fun(self: BaseNode, x: number, y: number, btn: integer, child: BaseNode): boolean|nil
    ---@field OnMouseUp fun(self: BaseNode, x: number, y: number, btn: integer): boolean|nil
    ---@field OnMouseUpBubble fun(self: BaseNode, x: number, y: number, btn: integer, child: BaseNode): boolean|nil
    ---@field IsPressed fun(self: BaseNode, btn: 1|2|3): boolean

    ---@param btn 1|2|3
    ---@return boolean
    node.IsPressed = function (self, btn)
        return MouseInputPlugin._pressed[btn] == self
    end

    ---@class MouseInputBuilder
    local builder
    builder = {
        ---@param callback fun(self: BaseNode, x: number, y: number): boolean|nil
        OnMouseMoved = function(callback)
            node.OnMouseMove = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number, child: BaseNode): boolean|nil
        OnMouseMovedBubble = function(callback)
            node.OnMouseMoveBubble = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number): boolean|nil
        OnMouseEnter = function(callback)
            node.OnMouseEnter = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number, child: BaseNode): boolean|nil
        OnMouseEnterBubble = function(callback)
            node.OnMouseEnterBubble = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode): boolean|nil
        OnMouseLeave = function(callback)
            node.OnMouseLeave = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number, btn: integer): boolean|nil
        OnMouseDown = function(callback)
            node.OnMouseDown = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number, btn: integer, child: BaseNode): boolean|nil
        OnMouseDownBubble = function(callback)
            node.OnMouseDownBubble = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number, btn: integer): boolean|nil
        OnMouseUp = function(callback)
            node.OnMouseUp = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number, btn: integer, child: BaseNode): boolean|nil
        OnMouseUpBubble = function(callback)
            node.OnMouseUpBubble = callback
            return builder
        end,
    }

    return builder
end

---@param node BaseNode
MouseInputPlugin.UninstallFrom = function(node)
    node.plugins[MouseInputPlugin] = nil
    MouseInputPlugin._nodes[node] = nil
    MouseInputPlugin._dirty = true

    node.OnMouseMove = nil
    node.OnMouseMoveBubble = nil
    node.OnMouseEnter = nil
    node.OnMouseEnterBubble = nil
    node.OnMouseLeave = nil
    node.OnMouseDown = nil
    node.OnMouseDownBubble = nil
    node.OnMouseUp = nil
    node.OnMouseUpBubble = nil

    if MouseInputPlugin._hovered == node then
        MouseInputPlugin._hovered = nil
    end
    for btn = 1, 3 do
        if MouseInputPlugin._pressed[btn] == node then
            MouseInputPlugin._pressed[btn] = nil
        end
    end
end

MouseInputPlugin.UninstallFromAll = function()
    for node in pairs(MouseInputPlugin._nodes) do
        node.plugins[MouseInputPlugin] = nil
        node.OnMouseMove = nil
        node.OnMouseMoveBubble = nil
        node.OnMouseEnter = nil
        node.OnMouseEnterBubble = nil
        node.OnMouseLeave = nil
        node.OnMouseDown = nil
        node.OnMouseDownBubble = nil
        node.OnMouseUp = nil
        node.OnMouseUpBubble = nil
    end

    MouseInputPlugin._nodes = {}
    MouseInputPlugin._hovered = nil
    MouseInputPlugin._pressed = {}
    MouseInputPlugin._sorted_layers = {}
    MouseInputPlugin._layer_nodes = {}
    MouseInputPlugin._no_layer_nodes = {}
    MouseInputPlugin._dirty = false
end

---manually call this after reparenting nodes in the scene graph.
MouseInputPlugin.MarkDirty = function()
    MouseInputPlugin._dirty = true
end

--- find the topmost node under the mouse, respecting layer order and camera transforms
---@param mx number mouse x (screen coordinates)
---@param my number mouse y (screen coordinates)
---@return BaseNode?
local function FindHitTarget(mx, my)
    for _, layer in ipairs(MouseInputPlugin._sorted_layers) do
        if layer.interactive then
            local wx, wy = ScreenToWorld(mx, my, layer.camera)

            local nodes = MouseInputPlugin._layer_nodes[layer]
            if nodes then
                for i = #nodes, 1, -1 do
                    local node = nodes[i]
                    if node:ContainsPoint(wx, wy) then
                        return node
                    end
                end
            end
        end
    end

    local no_layer = MouseInputPlugin._no_layer_nodes
    for i = #no_layer, 1, -1 do
        local node = no_layer[i]
        if node:ContainsPoint(mx, my) then
            return node
        end
    end

    return nil
end

MouseInputPlugin.Update = function(_dt)
    local mx, my = MouseInputPlugin._mouseprovider.GetPosition()

    if MouseInputPlugin._dirty then
        RebuildSortedCache()
    end

    local target = FindHitTarget(mx, my)

    local prev_hovered = MouseInputPlugin._hovered
    if prev_hovered ~= target then
        if prev_hovered and prev_hovered.OnMouseLeave then
            prev_hovered:OnMouseLeave()
        end
        if target then
            -- call OnMouseEnter on target, then bubble if not consumed
            local consumed = false
            if target.OnMouseEnter then
                consumed = target:OnMouseEnter(mx, my) == true
            end

            if not consumed then
                local child = target
                local current = target.parent
                while current do
                    if current.OnMouseEnterBubble and current:OnMouseEnterBubble(mx, my, child) then
                        break
                    end
                    child = current
                    current = current.parent
                end
            end
        end
        MouseInputPlugin._hovered = target
    end

    if target then
        -- call OnMouseMove on target, then bubble if not consumed
        local consumed = false
        if target.OnMouseMove then
            consumed = target:OnMouseMove(mx, my) == true
        end

        if not consumed then
            local child = target
            local current = target.parent
            while current do
                if current.OnMouseMoveBubble and current:OnMouseMoveBubble(mx, my, child) then
                    break
                end
                child = current
                current = current.parent
            end
        end
    end

    for btn = 1, 3 do
        if MouseInputPlugin._mouseprovider.JustReleased(btn) then
            local pressed_node = MouseInputPlugin._pressed[btn]
            if pressed_node then
                -- NOTE(matt): good ux here means that OnMouseUp "cancels" the final event
                --             if mx and my are outside the button's rect.
                -- call OnMouseUp on target, then bubble if not consumed
                local consumed = false
                if pressed_node.OnMouseUp then
                    consumed = pressed_node:OnMouseUp(mx, my, btn) == true
                end

                if not consumed then
                    local child = pressed_node
                    local current = pressed_node.parent
                    while current do
                        if current.OnMouseUpBubble and current:OnMouseUpBubble(mx, my, btn, child) then
                            break
                        end
                        child = current
                        current = current.parent
                    end
                end
            end
            MouseInputPlugin._pressed[btn] = nil
        end
    end

    for btn = 1, 3 do
        if MouseInputPlugin._mouseprovider.JustPressed(btn) then
            if target then
                -- call OnMouseDown on target, then bubble if not consumed
                local consumed = false
                if target.OnMouseDown then
                    consumed = target:OnMouseDown(mx, my, btn) == true
                end

                if not consumed then
                    local child = target
                    local current = target.parent
                    while current do
                        if current.OnMouseDownBubble and current:OnMouseDownBubble(mx, my, btn, child) then
                            break
                        end
                        child = current
                        current = current.parent
                    end
                end
            end
            MouseInputPlugin._pressed[btn] = target
        end
    end
end

---@param mouseprovider MouseInputSource
return function(mouseprovider)
    MouseInputPlugin._mouseprovider = mouseprovider
    return MouseInputPlugin
end

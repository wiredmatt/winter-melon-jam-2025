---@class MouseInputPlugin : Plugin
---@field private _mouseprovider MouseInputSource
---@field private _nodes { [BaseNode]: true }
---@field private _hovered BaseNode|nil
---@field private _pressed { [1|2|3]: BaseNode|nil }
---@field private _dirty boolean
---@field private _sorted_cache BaseNode[]
local MouseInputPlugin = {
    name = "MouseInputPlugin",
    _nodes = {},
    _hovered = nil,
    _pressed = {},
    _dirty = true,
    _sorted_cache = {},
}

--- Get the path from root to node as a list of sibling indices
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

--- Compare two nodes by their visual order (render order)
--- Returns true if a is rendered before b (meaning b is on top)
---@param a BaseNode
---@param b BaseNode
---@return boolean
local function CompareByTreeOrder(a, b)
    local path_a = GetTreePath(a)
    local path_b = GetTreePath(b)

    -- Compare paths lexicographically
    local min_len = math.min(#path_a, #path_b)
    for i = 1, min_len do
        if path_a[i] ~= path_b[i] then
            return path_a[i] < path_b[i]
        end
    end

    -- If one path is a prefix of the other, the shorter one (ancestor) renders first
    return #path_a < #path_b
end

--- Rebuild the sorted cache
local function RebuildSortedCache()
    local nodes = {}
    for node in pairs(MouseInputPlugin._nodes) do
        table.insert(nodes, node)
    end
    table.sort(nodes, CompareByTreeOrder)
    MouseInputPlugin._sorted_cache = nodes
    MouseInputPlugin._dirty = false
end

---if reparenting nodes with AddChild/RemoveChild after they've installed this plugin, 
---call MouseInputPlugin.MarkDirty() to re-sort on the next frame
---@param node BaseNode
---@return table builder
MouseInputPlugin.InstallTo = function(node)
    if node.plugins[MouseInputPlugin] == nil then
        node.plugins[MouseInputPlugin] = true
        MouseInputPlugin._nodes[node] = true
        MouseInputPlugin._dirty = true
    end

    ---@class BaseNode
    ---@field OnMouseMove fun(self: BaseNode, x: number, y: number): boolean|nil
    ---@field OnMouseEnter fun(self: BaseNode, x: number, y: number): boolean|nil
    ---@field OnMouseLeave fun(self: BaseNode): boolean|nil
    ---@field OnMouseDown fun(self: BaseNode, x: number, y: number, btn: integer): boolean|nil
    ---@field OnMouseUp fun(self: BaseNode, x: number, y: number, btn: integer): boolean|nil
    ---@field IsPressed fun(self: BaseNode, btn: 1|2|3): boolean

    ---@param btn 1|2|3
    ---@return boolean
    node.IsPressed = function (self, btn)
        return MouseInputPlugin._pressed[btn] == self
    end

    local builder
    builder = {
        ---@param callback fun(self: BaseNode, x: number, y: number): boolean|nil
        OnMouseMoved = function(callback)
            node.OnMouseMove = callback
            return builder
        end,
        ---@param callback fun(self: BaseNode, x: number, y: number): boolean|nil
        OnMouseEnter = function(callback)
            node.OnMouseEnter = callback
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
        ---@param callback fun(self: BaseNode, x: number, y: number, btn: integer): boolean|nil
        OnMouseUp = function(callback)
            node.OnMouseUp = callback
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

    -- Clear callbacks
    node.OnMouseMove = nil
    node.OnMouseEnter = nil
    node.OnMouseLeave = nil
    node.OnMouseDown = nil
    node.OnMouseUp = nil

    -- Clear global state referencing this node
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
        node.OnMouseEnter = nil
        node.OnMouseLeave = nil
        node.OnMouseDown = nil
        node.OnMouseUp = nil
    end

    MouseInputPlugin._nodes = {}
    MouseInputPlugin._hovered = nil
    MouseInputPlugin._pressed = {}
    MouseInputPlugin._sorted_cache = {}
    MouseInputPlugin._dirty = false
end

--- Mark the sort order as dirty, forcing a re-sort on next update.
--- Call this after reparenting nodes in the scene graph.
MouseInputPlugin.MarkDirty = function()
    MouseInputPlugin._dirty = true
end

MouseInputPlugin.Update = function()
    local mx, my = MouseInputPlugin._mouseprovider.GetPosition()

    if MouseInputPlugin._dirty then
        RebuildSortedCache()
    end

    local sorted = MouseInputPlugin._sorted_cache

    local target = nil
    for i = #sorted, 1, -1 do
        local node = sorted[i]
        if node:ContainsPoint(mx, my) then
            target = node
            break
        end
    end

    local prev_hovered = MouseInputPlugin._hovered
    if prev_hovered ~= target then
        if prev_hovered then
            prev_hovered:OnMouseLeave()
        end
        if target then
            target:OnMouseEnter(mx, my)
        end
        MouseInputPlugin._hovered = target
    end

    if target and target.OnMouseMove then
        target:OnMouseMove(mx, my)
    end

    for btn = 1, 3 do
        if MouseInputPlugin._mouseprovider.JustReleased(btn) then
            local pressed_node = MouseInputPlugin._pressed[btn]
            if pressed_node then
                -- NOTE(matt): good ux here means that OnMouseUp "cancels" the final event
                --             if mx and my are outside the button's rect.
                pressed_node:OnMouseUp(mx, my, btn)
            end
            MouseInputPlugin._pressed[btn] = nil
        end
    end

    for btn = 1, 3 do
        if MouseInputPlugin._mouseprovider.JustPressed(btn) then
            if target then
                target:OnMouseDown(mx, my, btn)
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

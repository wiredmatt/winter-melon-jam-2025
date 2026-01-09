---@class MouseInputSource
---@field GetPosition fun(): number, number
---@field JustPressed fun(btn: integer): boolean
---@field JustReleased fun(btn: integer): boolean

---@class InputPlugin
---@field private _mouseprovider MouseInputSource
---@field private _nodes { [Node]: true }
---@field private _focused Node?
---@field private _hovered Node?
---@field private _pressed { [1|2|3]: Node? }
---@field private _dirty boolean
---@field private _sorted_layers Layer[]
---@field private _layer_nodes { [Layer]: Node[] }
---@field private _no_layer_nodes Node[]
local InputPlugin = {
    _nodes = {},
    _focused = nil,
    _hovered = nil,
    _pressed = {},
    _dirty = true,
    _sorted_layers = {},
    _layer_nodes = {},
    _no_layer_nodes = {},
}

---@param node Node
---@return integer[]
local function GetTreePath(node)
    local path = {}
    ---@type Node?
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

---@param a Node
---@param b Node
---@return boolean
local function CompareByTreeOrder(a, b)
    local path_a = GetTreePath(a)
    local path_b = GetTreePath(b)

    local min_len = math.min(#path_a, #path_b)
    for i = 1, min_len do
        if path_a[i] ~= path_b[i] then
            return path_a[i] < path_b[i]
        end
    end

    return #path_a < #path_b
end

--- transform screen coordinates to world coordinates using inverse camera transform
---@param screenx number
---@param screeny number
---@param camera Node?
---@return number wx, number wy
local function ScreenToWorld(screenx, screeny, camera)
    if not camera then
        return screenx, screeny
    end

    local cx, cy, cr, csx, csy = camera:GetWorldTransform()

    local tx = screenx * csx
    local ty = screeny * csy

    local cos_r = math.cos(cr)
    local sin_r = math.sin(cr)
    local rx = tx * cos_r - ty * sin_r
    local ry = tx * sin_r + ty * cos_r

    local wx = rx + cx
    local wy = ry + cy

    return wx, wy
end

--- get the center position of a node in world coordinates
---@param node Node
---@return number x, number y
local function GetNodeCenter(node)
    local wx, wy, wr, wsx, wsy = node:GetWorldTransform()
    local bx, by, bw, bh = node:GetLocalBounds()

    -- center in local space
    local lcx = bx + bw / 2
    local lcy = by + bh / 2

    -- transform to world space
    local cos_r = math.cos(wr)
    local sin_r = math.sin(wr)
    local rx = lcx * cos_r - lcy * sin_r
    local ry = lcx * sin_r + lcy * cos_r

    return wx + rx * wsx, wy + ry * wsy
end

--- find the best node in a direction using spatial navigation
---@param from Node
---@param direction "up"|"down"|"left"|"right"
---@return Node?
local function FindNodeInDirection(from, direction)
    local from_x, from_y = GetNodeCenter(from)
    local from_layer = from._layer

    local best_node = nil
    local best_score = math.huge

    -- prioritize overrides if present
    local override_key = "focus_" .. direction
    if from[override_key] then
        return from[override_key]
    end

    -- get candidate nodes (same layer or no layer)
    local candidates = {}
    if from_layer and InputPlugin._layer_nodes[from_layer] then
        for _, node in ipairs(InputPlugin._layer_nodes[from_layer]) do
            if node ~= from and node.enabled then
                table.insert(candidates, node)
            end
        end
    else
        for _, node in ipairs(InputPlugin._no_layer_nodes) do
            if node ~= from and node.enabled then
                table.insert(candidates, node)
            end
        end
    end

    for _, node in ipairs(candidates) do
        local nx, ny = GetNodeCenter(node)
        local dx = nx - from_x
        local dy = ny - from_y

        -- check if node is in the right direction
        local in_direction = false
        local primary_dist = 0
        local secondary_dist = 0

        if direction == "right" and dx > 0 then
            in_direction = true
            primary_dist = dx
            secondary_dist = math.abs(dy)
        elseif direction == "left" and dx < 0 then
            in_direction = true
            primary_dist = -dx
            secondary_dist = math.abs(dy)
        elseif direction == "down" and dy > 0 then
            in_direction = true
            primary_dist = dy
            secondary_dist = math.abs(dx)
        elseif direction == "up" and dy < 0 then
            in_direction = true
            primary_dist = -dy
            secondary_dist = math.abs(dx)
        end

        if in_direction then
            -- score: prefer nodes directly in line (low secondary_dist)
            -- and closer (low primary_dist)
            -- weight secondary distance more heavily to prefer aligned nodes
            local score = primary_dist + secondary_dist * 3

            if score < best_score then
                best_score = score
                best_node = node
            end
        end
    end

    return best_node
end

local function RebuildSortedCache()
    local layer_set = {}
    local layer_nodes = {}
    local no_layer_nodes = {}

    for node in pairs(InputPlugin._nodes) do
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

    local sorted_layers = {}
    for layer in pairs(layer_set) do
        table.insert(sorted_layers, layer)
    end
    table.sort(sorted_layers, function(a, b)
        return a.render_order > b.render_order
    end)

    for _, nodes in pairs(layer_nodes) do
        table.sort(nodes, CompareByTreeOrder)
    end

    table.sort(no_layer_nodes, CompareByTreeOrder)

    InputPlugin._sorted_layers = sorted_layers
    InputPlugin._layer_nodes = layer_nodes
    InputPlugin._no_layer_nodes = no_layer_nodes
    InputPlugin._dirty = false
end

--- find the topmost node under the mouse
---@param mx number
---@param my number
---@return Node?
local function FindHitTarget(mx, my)
    for _, layer in ipairs(InputPlugin._sorted_layers) do
        if layer.interactive then
            local wx, wy = ScreenToWorld(mx, my, layer.camera)

            local nodes = InputPlugin._layer_nodes[layer]
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

    local no_layer = InputPlugin._no_layer_nodes
    for i = #no_layer, 1, -1 do
        local node = no_layer[i]
        if node:ContainsPoint(mx, my) then
            return node
        end
    end

    return nil
end

--- set focus to a node, firing Blur/Focus events
---@param node Node?
local function SetFocusInternal(node)
    local prev = InputPlugin._focused
    if prev == node then return end

    if prev then
        prev:Dispatch("Blur")
    end

    InputPlugin._focused = node

    if node then
        node:Dispatch("Focus")
    end
end

---@param node Node
InputPlugin.Register = function(node)
    InputPlugin._nodes[node] = true
    InputPlugin._dirty = true
end

---@param node Node
InputPlugin.Unregister = function(node)
    InputPlugin._nodes[node] = nil
    InputPlugin._dirty = true

    if InputPlugin._focused == node then
        InputPlugin._focused = nil
    end
    if InputPlugin._hovered == node then
        InputPlugin._hovered = nil
    end
    for btn = 1, 3 do
        if InputPlugin._pressed[btn] == node then
            InputPlugin._pressed[btn] = nil
        end
    end
end

---Navigate focus in a direction
---@param direction "up"|"down"|"left"|"right"
InputPlugin.Navigate = function(direction)
    if InputPlugin._dirty then
        RebuildSortedCache()
    end

    local current = InputPlugin._focused

    -- if nothing focused, focus first available node
    if not current then
        -- try to find first node in highest layer
        for _, layer in ipairs(InputPlugin._sorted_layers) do
            if layer.interactive then
                local nodes = InputPlugin._layer_nodes[layer]
                if nodes and #nodes > 0 then
                    SetFocusInternal(nodes[1])
                    return
                end
            end
        end
        -- fall back to no-layer nodes
        if #InputPlugin._no_layer_nodes > 0 then
            SetFocusInternal(InputPlugin._no_layer_nodes[1])
        end
        return
    end

    local next_node = FindNodeInDirection(current, direction)
    if next_node then
        SetFocusInternal(next_node)
    end
end

--- trigger activate action on focused node
InputPlugin.Activate = function()
    local focused = InputPlugin._focused
    if focused then
        focused:Dispatch("Activate")
    end
end

--- trigger cancel action on focused node
InputPlugin.Cancel = function()
    local focused = InputPlugin._focused
    if focused then
        focused:Dispatch("Cancel")
    end
end

---@param node Node?
InputPlugin.SetFocus = function(node)
    SetFocusInternal(node)
end

---@return Node?
InputPlugin.GetFocused = function()
    return InputPlugin._focused
end

InputPlugin.ClearFocus = function()
    SetFocusInternal(nil)
end

---@return Node?
InputPlugin.GetHovered = function()
    return InputPlugin._hovered
end

InputPlugin.MarkDirty = function()
    InputPlugin._dirty = true
end

---@param dt number
InputPlugin.Update = function(dt)
    local mx, my = InputPlugin._mouseprovider.GetPosition()

    if InputPlugin._dirty then
        RebuildSortedCache()
    end

    local target = FindHitTarget(mx, my)

    -- handle mouse hover
    local prev_hovered = InputPlugin._hovered
    if prev_hovered ~= target then
        if prev_hovered then
            prev_hovered:Dispatch("HoverEnd")
        end
        if target then
            target:Dispatch("Hover", mx, my)
        end
        InputPlugin._hovered = target
    end

    -- handle mouse release
    for btn = 1, 3 do
        if InputPlugin._mouseprovider.JustReleased(btn) then
            local pressed_node = InputPlugin._pressed[btn]
            if pressed_node then
                pressed_node:Dispatch("Release", mx, my, btn)
            end
            InputPlugin._pressed[btn] = nil
        end
    end

    -- handle mouse press
    for btn = 1, 3 do
        if InputPlugin._mouseprovider.JustPressed(btn) then
            if target then
                -- set focus when clicking
                SetFocusInternal(target)
                target:Dispatch("Press", mx, my, btn)
            end
            InputPlugin._pressed[btn] = target
        end
    end
end

---@param mouseprovider MouseInputSource
return function(mouseprovider)
    InputPlugin._mouseprovider = mouseprovider
    return InputPlugin
end

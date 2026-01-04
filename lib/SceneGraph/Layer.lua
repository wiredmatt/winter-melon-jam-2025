local BaseNode = require("lib.SceneGraph.Nodes.BaseNode")

---@class LayerConfig
---@field name string?
---@field render_order number?
---@field camera BaseNode?
---@field visible boolean?
---@field interactive boolean?

---@class Layer
---@field name string
---@field render_order number
---@field root BaseNode
---@field camera BaseNode?
---@field visible boolean
---@field interactive boolean
local Layer = {}
Layer.__index = Layer

---@param config LayerConfig?
---@return Layer
Layer.New = function(config)
    config = config or {}

    local self = setmetatable({}, Layer)

    self.name = config.name or "layer"
    self.render_order = config.render_order or 0
    self.camera = config.camera
    self.visible = config.visible ~= false  -- default true
    self.interactive = config.interactive ~= false  -- default true

    -- Create root node for this layer
    self.root = BaseNode.New()
    self.root._layer = self

    return self
end

--- Sets the layer reference on a node and all its descendants
---@param node BaseNode
local function SetLayerRecursive(node, layer)
    node._layer = layer
    for _, child in ipairs(node.children) do
        SetLayerRecursive(child, layer)
    end
end

--- Add a child node to this layer
---@param node BaseNode
Layer.AddChild = function(self, node)
    SetLayerRecursive(node, self)
    self.root:AddChild(node)
end

--- Remove a child node from this layer
---@param node BaseNode
---@return boolean
Layer.RemoveChild = function(self, node)
    local removed = self.root:RemoveChild(node)
    if removed then
        SetLayerRecursive(node, nil)
    end
    return removed
end

--- Update all nodes in this layer
---@param dt number
Layer.Update = function(self, dt)
    self.root:Update(dt)
end

--- Draw all nodes in this layer with optional camera transform
Layer.Draw = function(self)
    if not self.visible then return end

    love.graphics.push()

    if self.camera then
        local cx, cy, cr, csx, csy = self.camera:GetWorldTransform()
        -- Invert camera transform to move world opposite to camera
        love.graphics.scale(1 / csx, 1 / csy)
        love.graphics.rotate(-cr)
        love.graphics.translate(-cx, -cy)
    end

    self.root:Draw()

    love.graphics.pop()
end

--- Destroy this layer and all its nodes
Layer.Destroy = function(self)
    self.root:Destroy()
end

return Layer

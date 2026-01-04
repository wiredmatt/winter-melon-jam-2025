---@class Drawable
---@field _node BaseNode
---@field Draw fun(self)

---@class GraphicsBuilder
---@field Add fun(drawable: table): GraphicsBuilder

---@class Graphics
---@field private _layers table[]
---@field private _node BaseNode
local Graphics = {
    Rect = require("lib.SceneGraph.Graphics.Rect"),
    Sprite = require("lib.SceneGraph.Graphics.Sprite")
}

---@param node BaseNode
---@return GraphicsBuilder
function Graphics.On(node)
    if not node._graphics_layers then
        node._graphics_layers = {}
    end

    ---@class NodeGraphics
    local self = {
        _layers = node._graphics_layers,
        _node = node
    }

    local builder = {}

    ---@param drawable Drawable
    ---@return GraphicsBuilder
    builder.Add = function(drawable)
        drawable._node = self._node
        table.insert(self._layers, drawable)
        return builder
    end

    ---@param drawable table
    ---@return GraphicsBuilder
    builder.Remove = function(drawable)
        for i, layer in ipairs(self._layers) do
            if layer == drawable then
                table.remove(self._layers, i)
                break
            end
        end
        return builder
    end

    ---@return GraphicsBuilder
    builder.Clear = function()
        for i = #self._layers, 1, -1 do
            table.remove(self._layers, i)
        end
        return builder
    end

    function self:Draw()
        for _, layer in ipairs(self._layers) do
            layer:Draw()
        end
    end

    if not node.graphics then
        node.graphics = setmetatable(builder, { __index = self })
    end

    return node.graphics --[[@as GraphicsBuilder]]
end

return Graphics

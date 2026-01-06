---@class Drawable
---@field x number
---@field y number
---@field r number
---@field sx number
---@field sy number
---@field ox number
---@field oy number
---@field color number[]
---@field _node Node
---@field Draw fun(self)

---@class NodeGraphics
---@field drawables Drawable[]
---@field Add fun(self, drawable: Drawable, name: string?): NodeGraphics
---@field Get fun(self, name: string): Drawable?
---@field Remove fun(self, drawable: Drawable|string): NodeGraphics
---@field Clear fun(self): NodeGraphics
---@field Draw fun(self)

local Graphics = {
    Rect = require("lib.SceneGraph.Graphics.Rect"),
    Sprite = require("lib.SceneGraph.Graphics.Sprite"),
    Text = require("lib.SceneGraph.Graphics.Text"),
}

---@param node Node
---@return NodeGraphics
function Graphics.On(node)
    if node.graphics then
        return node.graphics
    end

    local graphics = {
        drawables = {},  ---@type Drawable[]
        _named = {},     ---@type { [string]: Drawable }
        _node = node,    ---@type Node
    }

    ---@param drawable Drawable
    ---@param name string?
    ---@return NodeGraphics
    function graphics:Add(drawable, name)
        drawable._node = self._node
        table.insert(self.drawables, drawable)
        if name then
            self._named[name] = drawable
        end
        return self
    end

    ---@param name string
    ---@return Drawable?
    function graphics:Get(name)
        return self._named[name]
    end

    ---@param drawable Drawable|string
    ---@return NodeGraphics
    function graphics:Remove(drawable)
        if type(drawable) == "string" then
            local name = drawable
            drawable = self._named[name]
            if drawable then
                self._named[name] = nil
            else
                return self
            end
        else
            for name, d in pairs(self._named) do
                if d == drawable then
                    self._named[name] = nil
                    break
                end
            end
        end

        for i, d in ipairs(self.drawables) do
            if d == drawable then
                table.remove(self.drawables, i)
                break
            end
        end
        return self
    end

    ---@return NodeGraphics
    function graphics:Clear()
        self.drawables = {}
        self._named = {}
        return self
    end

    function graphics:Draw()
        for _, drawable in ipairs(self.drawables) do
            drawable:Draw()
        end
    end

    node.graphics = graphics
    return graphics
end

return Graphics

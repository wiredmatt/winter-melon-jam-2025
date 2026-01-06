---@class LayerManager
---@field _layers Layer[]
---@field _sorted Layer[]
---@field _dirty boolean
local LayerManager = {}
LayerManager.__index = LayerManager

---@return LayerManager
LayerManager.New = function()
    local self = setmetatable({}, LayerManager)

    self._layers = {}
    self._sorted = {}
    self._dirty = true

    return self
end

---@param layer Layer
LayerManager.Add = function(self, layer)
    table.insert(self._layers, layer)
    self._dirty = true
end

---@param layer Layer
---@return boolean
LayerManager.Remove = function(self, layer)
    for i, l in ipairs(self._layers) do
        if l == layer then
            table.remove(self._layers, i)
            self._dirty = true
            return true
        end
    end
    return false
end

local function RebuildSortedCache(self)
    if not self._dirty then return end

    self._sorted = {}
    for i, layer in ipairs(self._layers) do
        self._sorted[i] = layer
    end

    -- (lower first = rendered behind)
    table.sort(self._sorted, function(a, b)
        return a.render_order < b.render_order
    end)

    self._dirty = false
end

---@return Layer[]
LayerManager.GetSortedLayers = function(self)
    RebuildSortedCache(self)
    return self._sorted
end

---@param dt number
LayerManager.Update = function(self, dt)
    for _, layer in ipairs(self._layers) do
        layer:Update(dt)
    end
end

LayerManager.Draw = function(self)
    RebuildSortedCache(self)
    for _, layer in ipairs(self._sorted) do
        layer:Draw()
    end
end

LayerManager.Destroy = function(self)
    for _, layer in ipairs(self._layers) do
        layer:Destroy()
    end
    self._layers = {}
    self._sorted = {}
end

return LayerManager

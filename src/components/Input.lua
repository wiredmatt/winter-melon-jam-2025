---@class InputComponent : Component

---@class InputComponentClass
---@field New fun(): InputComponent

local InputComponent = SceneGraph.Component.Define("Input", {
    ---@param self InputComponent
    Init = function(self)
    end,

    ---@param self InputComponent
    OnAdded = function(self)
        SceneGraph.InputPlugin.Register(self.node)
    end,

    ---@param self InputComponent
    OnRemoved = function(self)
        SceneGraph.InputPlugin.Unregister(self.node)
    end,
})

return InputComponent --[[@as InputComponentClass]]
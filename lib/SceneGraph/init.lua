-- Get mouse provider for UI input
local mouse_provider = require("lib.InputManager.mouse")

local SceneGraph = {
    Node = require("lib.SceneGraph.Node"),
    Component = require("lib.SceneGraph.Component"),

    InputPlugin = require("lib.SceneGraph.InputPlugin")(mouse_provider),

    Layer = require("lib.SceneGraph.Layers.Layer"),
    LayerManager = require("lib.SceneGraph.Layers.LayerManager"),
}

return SceneGraph

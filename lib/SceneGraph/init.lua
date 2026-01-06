local SceneGraph = {
    Node = require("lib.SceneGraph.Node"),
    Plugins = require("lib.SceneGraph.Plugins"),
    Behaviors = require("lib.SceneGraph.Behaviors"),
    Graphics = require("lib.SceneGraph.Graphics"),
    Layer = require("lib.SceneGraph.Layers.Layer"),
    LayerManager = require("lib.SceneGraph.Layers.LayerManager"),
}

SceneGraph.PluginManager = {}

SceneGraph.PluginManager.Update = function (dt)
    for _, p in pairs(SceneGraph.Plugins) do
        p.Update(dt)
    end
end

return SceneGraph

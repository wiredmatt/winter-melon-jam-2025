local SceneGraph = {
    Nodes = require("lib.SceneGraph.Nodes"),
    Plugins = require("lib.SceneGraph.Plugins"),
    Behaviors = require("lib.SceneGraph.Behaviors"),
    Graphics = require("lib.SceneGraph.Graphics")
}

SceneGraph.Update = function (dt)
    for _, p in pairs(SceneGraph.Plugins) do
        p.Update(dt)
    end
end

return SceneGraph

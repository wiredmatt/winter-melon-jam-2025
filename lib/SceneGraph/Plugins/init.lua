local mouseProvider = require("lib.InputManager.mouse")

local Plugins = {
    Input = require("lib.SceneGraph.Plugins.input_plugin")(mouseProvider),
    Layout = require("lib.SceneGraph.Plugins.layout_plugin"),
}

return Plugins

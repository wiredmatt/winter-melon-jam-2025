local mouseProvider = require("lib.InputManager.mouse")

local Plugins = {
    Input = require("lib.SceneGraph.Plugins.input_plugin")(mouseProvider),
}

return Plugins

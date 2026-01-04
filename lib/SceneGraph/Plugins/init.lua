local Plugins = {
    MouseInput = require("lib.SceneGraph.Plugins.mouse_input_plugin")(
        require("lib.InputManager.mouse")
    )
}

return Plugins

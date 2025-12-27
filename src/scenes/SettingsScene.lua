local Node = require("lib.ui.Node")
local SettingsPanel = require("src.ui.SettingsPanel")

---@class SettingsScene : Scene
local SettingsScene = {
    name = "Settings",
    transition_in = SceneManager.Transitions.FadeIn.New(),
    transition_out = SceneManager.Transitions.FadeOut.New(),
}

SettingsScene.Enter = function ()
    local tiny5_8px_font = AssetManager.assets.fonts.Tiny5_ttf[8]
    tiny5_8px_font:setFilter("nearest", "nearest")

    SettingsScene.root_node = Node.New()

    local settings_panel = SettingsPanel.New({
        x = 0,
        y = 0,
        font = tiny5_8px_font,
        show_title = true,
        on_back = function()
            SceneManager.SwitchTo(Scenes.MainMenu)
        end
    })
    SettingsScene.root_node:AddChild(settings_panel)
end

SettingsScene.Update = function (dt)
    SettingsScene.root_node:Update(dt)
end

SettingsScene.Draw = function ()
    SettingsScene.root_node:Draw()
end

SettingsScene.Exit = function ()
end

return SettingsScene

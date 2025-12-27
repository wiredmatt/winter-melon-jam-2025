local ProgramCfg = require("program_cfg")
local Node = require("lib.ui.Node")
local Label = require("lib.ui.Label")
local Button = require("lib.ui.Button")

---@class MainMenuScene : Scene
local MainMenuScene = {
    name = "MainMenu",
    transition_in = SceneManager.Transitions.DiagonalOut.New({
        w = ProgramCfg.virtual_cfg.width,
        h = ProgramCfg.virtual_cfg.height
    }),
    transition_out = SceneManager.Transitions.FadeOut.New(),
}

MainMenuScene.Enter = function ()
    MainMenuScene.BuildGUI()
end

MainMenuScene.BuildGUI = function ()
    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")

    MainMenuScene.root_node = Node.New()

    local title = Label.New({
        x = 60,
        y = 10,
        width = 200,
        text = ProgramCfg.window_cfg.title,
        align = "center",
        color = {1, 1, 1, 1},
        font = tiny5_16px_font
    })
    MainMenuScene.root_node:AddChild(title)

    local start_button = Button.New({
        x = 110,
        y = 60,
        width = 100,
        height = 30,
        text = "Play",
        font = tiny5_16px_font
    })
    start_button.OnClick = function()
        SceneManager.SwitchTo(Scenes.Gameplay) -- todo: "Intro" first for release
    end

    MainMenuScene.root_node:AddChild(start_button)

    local options_button = Button.New({
        x = 110,
        y = 100,
        width = 100,
        height = 30,
        text = "Settings",
        font = tiny5_16px_font
    })
    options_button.OnClick = function()
        SceneManager.SwitchTo(Scenes.Settings)
    end
    MainMenuScene.root_node:AddChild(options_button)

    local quit_button = Button.New({
        x = 110,
        y = 140,
        width = 100,
        height = 30,
        text = "Quit",
        font = tiny5_16px_font
    })
    quit_button.OnClick = function()
        love.event.quit()
    end
    MainMenuScene.root_node:AddChild(quit_button)
end

MainMenuScene.Update = function (dt)
    MainMenuScene.root_node:Update(dt)
end

MainMenuScene.Draw = function ()
    MainMenuScene.root_node:Draw()
end

MainMenuScene.Exit = function () end

return MainMenuScene
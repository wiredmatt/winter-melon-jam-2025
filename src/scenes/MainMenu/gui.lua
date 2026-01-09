local MainMenuGUI = {}

---@param f love.Font
MainMenuGUI.Title = function (f)
    local title = SceneGraph.Node.New({
        x = 110,
        y = 30,
        width = 100,
    })
    :AddComponent(SceneGraph.Components.Text.New({
        text = "The Masked King",
        font = f,
        color = { 1, 1, 1, 1 },
        shadow = { x = 1, y = 1, color = {0.2, 0.2, 0.2, 0.8} },
        align = "center",
        valign = "middle",
    }))

    return title
end

---@param f love.Font
MainMenuGUI.PlayButton = function (f)
    local play_button = SceneGraph.Node.New({
        x = 110,
        y = 60,
        width = 100,
        height = 30,
        ox = 50,
        oy = 15
    })
    :AddComponent(SceneGraph.Components.Input.New())
    :On("Activate", function()
        InputManager.UnsetActiveMap()
        SceneManager.SwitchTo(Scenes.Gameplay)
    end)
    :AddComponent(SceneGraph.Components.Rect.New({
        color = { 0.3, 0.3, 0.3, 1},
        mode = "fill",
        ox = 50,
        oy = 15,
        name = "background"
    }))
    :AddComponent(SceneGraph.Components.Rect.New({
        color = {1,1,1,1},
        mode = "line",
        line_width = 2,
        ox = 50,
        oy = 15,
        name = "border"
    }))
    :AddComponent(SceneGraph.Components.Text.New({
        text = "Play",
        font = f,
        color = {1,1,1,1},
        shadow = { x = 1, y = 1, color = {0, 0, 0, 0.5} },
        align = "center",
        valign = "middle",
        ox = 50,
        oy = 15,
        name = "text"
    }))
    :AddComponent(SceneGraph.Components.HoverScale.New({
        on_enter_scale = 1.05,
        step = 0.015,
        target_components = { "#background", "#border" },
    }))

    play_button
        :AddComponent(SceneGraph.Components.HoverColor.New({
            on_enter_color = Utils.BrightenColor(Utils.CopyColor(play_button:GetComponentByName("background").color)),
            target_components = { "#background" }
        }))
        :AddComponent(SceneGraph.Components.HoverColor.New({
            on_enter_color = Utils.BrightenColor(Utils.CopyColor(play_button:GetComponentByName("border").color)),
            target_components = { "#border" }
        }))

    return play_button
end

MainMenuGUI.SettingsButton = function (f)
    local settings_button = SceneGraph.Node.New({
        x = 110,
        y = 100,
        width = 100,
        height = 30,
        ox = 50,
        oy = 15
    })
    :AddComponent(SceneGraph.Components.Input.New())
    :On("Activate", function()
        InputManager.UnsetActiveMap()
        SceneManager.SwitchTo(Scenes.Settings, SceneManager.Transitions.NONE)
    end)
    :AddComponent(SceneGraph.Components.Rect.New({
        color = { 0.3, 0.3, 0.3, 1},
        mode = "fill",
        ox = 50,
        oy = 15,
        name = "background"
    }))
    :AddComponent(SceneGraph.Components.Rect.New({
        color = {1,1,1,1},
        mode = "line",
        line_width = 2,
        ox = 50,
        oy = 15,
        name = "border"
    }))
    :AddComponent(SceneGraph.Components.Text.New({
        text = "Settings",
        font = f,
        color = { 1, 1, 1, 1 },
        shadow = { x = 1, y = 1, color = {0, 0, 0, 0.5} },
        align = "center",
        valign = "middle",
        ox = 50,
        oy = 15
    }))
    :AddComponent(SceneGraph.Components.HoverScale.New({
        on_enter_scale = 1.05,
        step = 0.015,
        target_components = { "#background", "#border" },
    }))

    settings_button
        :AddComponent(SceneGraph.Components.HoverColor.New({
            on_enter_color = Utils.BrightenColor(settings_button:GetComponentByName("background").color),
            target_components = { "#background" }
        }))
        :AddComponent(SceneGraph.Components.HoverColor.New({
            on_enter_color = Utils.BrightenColor(settings_button:GetComponentByName("border").color),
            target_components = { "#border" }
        }))

    return settings_button
end

MainMenuGUI.QuitButton = function (f)
    local quit_button = SceneGraph.Node.New({
        x = 110,
        y = 140,
        width = 100,
        height = 30,
        ox = 50,
        oy = 15
    })
    :AddComponent(SceneGraph.Components.Input.New())
    :On("Activate", function()
        InputManager.UnsetActiveMap()
        love.event.quit(0)
    end)
    :AddComponent(SceneGraph.Components.Rect.New({
        color = { 0.3, 0.3, 0.3, 1},
        mode = "fill",
        ox = 50,
        oy = 15,
        name = "background"
    }))
    :AddComponent(SceneGraph.Components.Rect.New({
        color = {1,1,1,1},
        mode = "line",
        line_width = 2,
        ox = 50,
        oy = 15,
        name = "border"
    }))
    :AddComponent(SceneGraph.Components.Text.New({
        text = "Quit",
        font = f,
        color = { 1, 1, 1, 1 },
        shadow = { x = 1, y = 1, color = {0, 0, 0, 0.5} },
        align = "center",
        valign = "middle",
        ox = 50,
        oy = 15
    }))
    :AddComponent(SceneGraph.Components.HoverScale.New({
        on_enter_scale = 1.05,
        step = 0.015,
        target_components = { "#background", "#border" },
    }))

    quit_button
        :AddComponent(SceneGraph.Components.HoverColor.New({
            on_enter_color = Utils.BrightenColor(quit_button:GetComponentByName("background").color),
            target_components = { "#background" }
        }))
        :AddComponent(SceneGraph.Components.HoverColor.New({
            on_enter_color = Utils.BrightenColor(quit_button:GetComponentByName("border").color),
            target_components = { "#border" }
        }))

    return quit_button
end

---@param ui_layer Layer
MainMenuGUI.Build = function (ui_layer)
    local f16px = AssetManager.assets.fonts.Tiny5_ttf[16]
    f16px:setFilter("nearest", "nearest")

    local title = MainMenuGUI.Title(f16px)
    ui_layer:AddChild(title)

    local play_button = MainMenuGUI.PlayButton(f16px)
    ui_layer:AddChild(play_button)

    local settings_button = MainMenuGUI.SettingsButton(f16px)
    ui_layer:AddChild(settings_button)

    local quit_button = MainMenuGUI.QuitButton(f16px)
    ui_layer:AddChild(quit_button)

end

return MainMenuGUI
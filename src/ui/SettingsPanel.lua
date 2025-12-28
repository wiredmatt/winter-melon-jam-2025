---@class SettingsPanelConfig
---@field x number?
---@field y number?
---@field font love.Font?
---@field show_title boolean?
---@field on_back function?

---@class SettingsPanel : SettingsPanelConfig, Node
---@field tab_container TabContainer
local SettingsPanel = {}

---@param config SettingsPanelConfig
---@return SettingsPanel panel_root
SettingsPanel.New = function (config)
    config = config or {}

    local root = UI.Node.New({
        x = config.x or 0,
        y = config.y or 0
    })  --[[@as SettingsPanel]]

    local font = config.font or love.graphics.getFont()
    local show_title = config.show_title ~= false
    local y_offset = 0

    local controls = {}

    if show_title then
        local title = UI.Label.New({
            x = 60,
            y = 8,
            width = 200,
            text = "Settings",
            align = "center",
            color = {1, 1, 1, 1},
            font = font
        })
        root:AddChild(title)
        y_offset = 30
    end

    local tab_container = UI.TabContainer.New({
        x = 10,
        y = y_offset,
        width = 300,
        height = 110,
        font = font,
        tab_padding = 0
    })
    root:AddChild(tab_container)

    local video_content = UI.Node.New()

    local fullscreen_checkbox = UI.Checkbox.New({
        x = 40,
        y = 20,
        box_size = 12,
        label = "Fullscreen",
        font = font,
        checked = Settings.Get("video", "fullscreen"),
        focusable = true
    })
    fullscreen_checkbox.OnChanged = function(checked)
        Settings.Set("video", "fullscreen", checked)
        Settings.ApplyVideoSettings()
    end
    video_content:AddChild(fullscreen_checkbox)
    controls.fullscreen = fullscreen_checkbox

    local vsync_checkbox = UI.Checkbox.New({
        x = 40,
        y = 48,
        box_size = 12,
        label = "VSync",
        font = font,
        checked = Settings.Get("video", "vsync"),
        focusable = true
    })
    vsync_checkbox.OnChanged = function(checked)
        Settings.Set("video", "vsync", checked)
        Settings.ApplyVideoSettings()
    end
    video_content:AddChild(vsync_checkbox)
    controls.vsync = vsync_checkbox

    local audio_content = UI.Node.New()

    local row_spacing = 24
    local label_x = 10
    local slider_x = 65
    local slider_width = 150
    local value_x = 224

    local master_y = 10
    local master_label = UI.Label.New({
        x = label_x,
        y = master_y,
        text = "Master:",
        font = font
    })
    audio_content:AddChild(master_label)

    local master_slider = UI.Slider.New({
        x = slider_x,
        y = master_y,
        width = slider_width,
        height = 12,
        value = Settings.Get("audio", "master_volume"),
        focusable = true
    })
    audio_content:AddChild(master_slider)
    controls.master_slider = master_slider

    local master_value_label = UI.Label.New({
        x = value_x,
        y = master_y,
        width = 35,
        text = tostring(math.floor(Settings.Get("audio", "master_volume") * 100)) .. "%",
        font = font
    })
    audio_content:AddChild(master_value_label)
    controls.master_value_label = master_value_label

    master_slider.OnValueChanged = function(value)
        Settings.Set("audio", "master_volume", value)
        Settings.ApplyAudioSettings()
        master_value_label:SetText(tostring(math.floor(value * 100)) .. "%")
    end

    local music_y = master_y + row_spacing
    local music_label = UI.Label.New({
        x = label_x,
        y = music_y,
        text = "Music:",
        font = font
    })
    audio_content:AddChild(music_label)

    local music_slider = UI.Slider.New({
        x = slider_x,
        y = music_y,
        width = slider_width,
        height = 12,
        value = Settings.Get("audio", "music_volume"),
        focusable = true
    })
    audio_content:AddChild(music_slider)
    controls.music_slider = music_slider

    local music_value_label = UI.Label.New({
        x = value_x,
        y = music_y,
        width = 35,
        text = tostring(math.floor(Settings.Get("audio", "music_volume") * 100)) .. "%",
        font = font
    })
    audio_content:AddChild(music_value_label)
    controls.music_value_label = music_value_label

    music_slider.OnValueChanged = function(value)
        Settings.Set("audio", "music_volume", value)
        Settings.ApplyAudioSettings()
        music_value_label:SetText(tostring(math.floor(value * 100)) .. "%")
    end

    local sfx_y = music_y + row_spacing
    local sfx_label = UI.Label.New({
        x = label_x,
        y = sfx_y,
        text = "SFX:",
        font = font
    })
    audio_content:AddChild(sfx_label)

    local sfx_slider = UI.Slider.New({
        x = slider_x,
        y = sfx_y,
        width = slider_width,
        height = 12,
        value = Settings.Get("audio", "sfx_volume"),
        focusable = true
    })
    audio_content:AddChild(sfx_slider)
    controls.sfx_slider = sfx_slider

    local sfx_value_label = UI.Label.New({
        x = value_x,
        y = sfx_y,
        width = 35,
        text = tostring(math.floor(Settings.Get("audio", "sfx_volume") * 100)) .. "%",
        font = font
    })
    audio_content:AddChild(sfx_value_label)
    controls.sfx_value_label = sfx_value_label

    sfx_slider.OnValueChanged = function(value)
        Settings.Set("audio", "sfx_volume", value)
        Settings.ApplyAudioSettings()
        sfx_value_label:SetText(tostring(math.floor(value * 100)) .. "%")
    end

    tab_container:AddTab("Video", video_content)
    tab_container:AddTab("Audio", audio_content)

    local function RefreshUI()
        local is_fullscreen = Settings.Get("video", "fullscreen")
        controls.fullscreen:SetChecked(is_fullscreen)

        local is_vsync = Settings.Get("video", "vsync")
        controls.vsync:SetChecked(is_vsync)

        local master_vol = Settings.Get("audio", "master_volume")
        controls.master_slider.value = master_vol
        controls.master_value_label:SetText(tostring(math.floor(master_vol * 100)) .. "%")

        local music_vol = Settings.Get("audio", "music_volume")
        controls.music_slider:SetValue(music_vol)
        controls.music_value_label:SetText(tostring(math.floor(music_vol * 100)) .. "%")

        local sfx_vol = Settings.Get("audio", "sfx_volume")
        controls.sfx_slider:SetValue(sfx_vol)
        controls.sfx_value_label:SetText(tostring(math.floor(sfx_vol * 100)) .. "%")
    end

    local bottom_buttons_y = 145

    local reset_button = UI.Button.New({
        x = 60,
        y = bottom_buttons_y,
        width = 80,
        height = 28,
        text = "Reset",
        font = font,
        focusable = true
    })
    reset_button.OnClick = function()
        Settings.Reset()
        RefreshUI()
    end
    root:AddChild(reset_button)

    local back_button = UI.Button.New({
        x = 180,
        y = bottom_buttons_y,
        width = 80,
        height = 28,
        text = "Back",
        font = font,
        focusable = true
    })
    back_button.OnClick = function()
        if config.on_back then
            config.on_back()
        end
    end
    root:AddChild(back_button)

    -- expose tab_container for external access (e.g., keyboard tab switching)
    root.tab_container = tab_container

    return root
end

return SettingsPanel

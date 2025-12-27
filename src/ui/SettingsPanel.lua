local Node = require("lib.ui.Node")
local Label = require("lib.ui.Label")
local Button = require("lib.ui.Button")
local Checkbox = require("lib.ui.Checkbox")
local Slider = require("lib.ui.Slider")
local TabContainer = require("lib.ui.TabContainer")
local Settings = require("lib.Settings")

---@class SettingsPanelConfig
---@field x number?
---@field y number?
---@field font love.Font?
---@field show_title boolean?
---@field on_back function?

local SettingsPanel = {}

---@param config SettingsPanelConfig
---@return Node panel_root
SettingsPanel.New = function (config)
    config = config or {}

    local root = Node.New({
        x = config.x or 0,
        y = config.y or 0
    })

    local font = config.font or love.graphics.getFont()
    local show_title = config.show_title ~= false
    local y_offset = 0

    local controls = {}

    if show_title then
        local title = Label.New({
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

    local tab_container = TabContainer.New({
        x = 10,
        y = y_offset,
        width = 300,
        height = 110,
        font = font,
        tab_padding = 0
    })
    root:AddChild(tab_container)

    local video_content = Node.New()

    local fullscreen_checkbox = Checkbox.New({
        x = 40,
        y = 20,
        box_size = 12,
        label = "Fullscreen",
        font = font,
        checked = Settings.Get("video", "fullscreen")
    })
    fullscreen_checkbox.OnChanged = function(checked)
        Settings.Set("video", "fullscreen", checked)
        Settings.ApplyVideoSettings()
    end
    video_content:AddChild(fullscreen_checkbox)
    controls.fullscreen = fullscreen_checkbox

    local vsync_checkbox = Checkbox.New({
        x = 40,
        y = 48,
        box_size = 12,
        label = "VSync",
        font = font,
        checked = Settings.Get("video", "vsync")
    })
    vsync_checkbox.OnChanged = function(checked)
        Settings.Set("video", "vsync", checked)
        Settings.ApplyVideoSettings()
    end
    video_content:AddChild(vsync_checkbox)
    controls.vsync = vsync_checkbox

    local audio_content = Node.New()

    local row_spacing = 24
    local label_x = 10
    local slider_x = 65
    local slider_width = 110
    local value_x = 180
    local mute_x = 220

    local master_y = 10
    local master_label = Label.New({
        x = label_x,
        y = master_y,
        text = "Master:",
        font = font
    })
    audio_content:AddChild(master_label)

    local master_slider = Slider.New({
        x = slider_x,
        y = master_y,
        width = slider_width,
        height = 12,
        value = Settings.Get("audio", "master_volume")
    })
    audio_content:AddChild(master_slider)
    controls.master_slider = master_slider

    local master_value_label = Label.New({
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

    local master_mute = Checkbox.New({
        x = mute_x,
        y = master_y,
        box_size = 12,
        label = "Mute",
        font = font,
        checked = Settings.Get("audio", "master_muted")
    })
    master_mute.OnChanged = function(checked)
        Settings.Set("audio", "master_muted", checked)
        Settings.ApplyAudioSettings()
    end
    audio_content:AddChild(master_mute)
    controls.master_mute = master_mute

    local music_y = master_y + row_spacing
    local music_label = Label.New({
        x = label_x,
        y = music_y,
        text = "Music:",
        font = font
    })
    audio_content:AddChild(music_label)

    local music_slider = Slider.New({
        x = slider_x,
        y = music_y,
        width = slider_width,
        height = 12,
        value = Settings.Get("audio", "music_volume")
    })
    audio_content:AddChild(music_slider)
    controls.music_slider = music_slider

    local music_value_label = Label.New({
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

    local music_mute = Checkbox.New({
        x = mute_x,
        y = music_y,
        box_size = 12,
        label = "Mute",
        font = font,
        checked = Settings.Get("audio", "music_muted")
    })
    music_mute.OnChanged = function(checked)
        Settings.Set("audio", "music_muted", checked)
        Settings.ApplyAudioSettings()
    end
    audio_content:AddChild(music_mute)
    controls.music_mute = music_mute

    local sfx_y = music_y + row_spacing
    local sfx_label = Label.New({
        x = label_x,
        y = sfx_y,
        text = "SFX:",
        font = font
    })
    audio_content:AddChild(sfx_label)

    local sfx_slider = Slider.New({
        x = slider_x,
        y = sfx_y,
        width = slider_width,
        height = 12,
        value = Settings.Get("audio", "sfx_volume")
    })
    audio_content:AddChild(sfx_slider)
    controls.sfx_slider = sfx_slider

    local sfx_value_label = Label.New({
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

    local sfx_mute = Checkbox.New({
        x = mute_x,
        y = sfx_y,
        box_size = 12,
        label = "Mute",
        font = font,
        checked = Settings.Get("audio", "sfx_muted")
    })
    sfx_mute.OnChanged = function(checked)
        Settings.Set("audio", "sfx_muted", checked)
        Settings.ApplyAudioSettings()
    end
    audio_content:AddChild(sfx_mute)
    controls.sfx_mute = sfx_mute

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

        local is_master_muted = Settings.Get("audio", "master_muted")
        controls.master_mute:SetChecked(is_master_muted)

        local music_vol = Settings.Get("audio", "music_volume")
        controls.music_slider:SetValue(music_vol)
        controls.music_value_label:SetText(tostring(math.floor(music_vol * 100)) .. "%")

        local is_music_muted = Settings.Get("audio", "music_muted")
        controls.music_mute:SetChecked(is_music_muted)

        local sfx_vol = Settings.Get("audio", "sfx_volume")
        controls.sfx_slider:SetValue(sfx_vol)
        controls.sfx_value_label:SetText(tostring(math.floor(sfx_vol * 100)) .. "%")

        local is_sfx_muted = Settings.Get("audio", "sfx_muted")
        controls.sfx_mute:SetChecked(is_sfx_muted)
    end

    local bottom_buttons_y = 145

    local reset_button = Button.New({
        x = 60,
        y = bottom_buttons_y,
        width = 80,
        height = 28,
        text = "Reset",
        font = font
    })
    reset_button.OnClick = function()
        Settings.Reset()
        RefreshUI()
    end
    root:AddChild(reset_button)

    local back_button = Button.New({
        x = 180,
        y = bottom_buttons_y,
        width = 80,
        height = 28,
        text = "Back",
        font = font
    })
    back_button.OnClick = function()
        if config.on_back then
            config.on_back()
        end
    end
    root:AddChild(back_button)

    return root
end

return SettingsPanel

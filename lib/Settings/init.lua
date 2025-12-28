local Program = require("lib.Program")
local AudioManager = require("lib.AudioManager")

---@class VideoSettings
---@field fullscreen boolean
---@field vsync boolean
---@field window_width number
---@field window_height number
---@field pixel_scale number

---@class AudioSettings
---@field master_volume number
---@field music_volume number
---@field sfx_volume number

---@class FlagsSettings
---@field intro_seen boolean

---@class SettingsData
---@field video VideoSettings
---@field audio AudioSettings
---@field flags FlagsSettings

---@class Settings
---@field current SettingsData
local Settings = {}
Settings.current = nil

---@return SettingsData
Settings.GetDefaults = function ()
    return {
        video = {
            fullscreen = false,
            vsync = false,
            window_width = 960,
            window_height = 540,
            pixel_scale = 1
        },
        audio = {
            master_volume = 1.0,
            music_volume = 1.0,
            sfx_volume = 1.0,
        },
        flags = {
            intro_seen = false
        }
    }
end

---@param tbl table
---@param indent number?
---@return string
Settings.SerializeTable = function (tbl, indent)
    indent = indent or 0
    local lines = {}
    local spacing = string.rep("  ", indent)

    table.insert(lines, "{\n")

    for k, v in pairs(tbl) do
        local key = type(k) == "string" and k or "[" .. k .. "]"

        if type(v) == "table" then
            table.insert(lines, spacing .. "  " .. key .. " = ")
            table.insert(lines, Settings.SerializeTable(v, indent + 1))
        elseif type(v) == "string" then
            table.insert(lines, spacing .. "  " .. key .. ' = "' .. v .. '",\n')
        elseif type(v) == "boolean" then
            table.insert(lines, spacing .. "  " .. key .. " = " .. tostring(v) .. ",\n")
        else
            table.insert(lines, spacing .. "  " .. key .. " = " .. tostring(v) .. ",\n")
        end
    end

    table.insert(lines, spacing .. "}")
    if indent > 0 then
        table.insert(lines, ",\n")
    else
        table.insert(lines, "\n")
    end

    return table.concat(lines)
end

---@param loaded table
---@return SettingsData
Settings.MergeDefaults = function (loaded)
    local defaults = Settings.GetDefaults()

    loaded.video = loaded.video or {}
    loaded.audio = loaded.audio or {}
    loaded.flags = loaded.flags or {}

    for k, v in pairs(defaults.video) do
        if loaded.video[k] == nil then
            loaded.video[k] = v
        end
    end

    for k, v in pairs(defaults.audio) do
        if loaded.audio[k] == nil then
            loaded.audio[k] = v
        end
    end

    for k, v in pairs(defaults.flags) do
        if loaded.flags[k] == nil then
            loaded.flags[k] = v
        end
    end

    return loaded
end

Settings.Save = function ()
    if not Settings.current then
        return
    end

    local code = "return " .. Settings.SerializeTable(Settings.current)
    local success, message = love.filesystem.write("settings.lua", code)

    if not success then
        print("[Settings] Failed to save: " .. tostring(message))
    end
end

Settings.Load = function ()
    if love.filesystem.getInfo("settings.lua") then
        local chunk, load_err = love.filesystem.load("settings.lua")

        if chunk then
            local success, loaded = pcall(chunk)
            if success and type(loaded) == "table" then
                Settings.current = Settings.MergeDefaults(loaded)
                print("[Settings] Loaded from file")
            else
                print("[Settings] Failed to interpret settings file: " .. tostring(loaded))
                Settings.current = Settings.GetDefaults()
            end
        else
            print("[Settings] Failed to load settings file: " .. tostring(load_err))
            Settings.current = Settings.GetDefaults()
        end
    else
        print("[Settings] No settings file found, using defaults")
        Settings.current = Settings.GetDefaults()
    end
end

---@param category "video" | "audio" | "flags"
---@param key string Setting key
---@return any
Settings.Get = function (category, key)
    if not Settings.current then
        Settings.Load()
    end

    if Settings.current[category] then
        return Settings.current[category][key]
    end

    return nil
end

---@param category "video" | "audio" | "flags"
---@param key string Setting key
---@param value any Setting value
Settings.Set = function (category, key, value)
    if not Settings.current then
        Settings.Load()
    end

    if Settings.current[category] then
        Settings.current[category][key] = value
        Settings.Save()
    end
end

Settings.ApplyVideoSettings = function ()
    if not Settings.current then
        Settings.Load()
    end

    local cfg = Settings.current.video

    Program.window_cfg.fullscreen = cfg.fullscreen
    Program.window_cfg.vsync = cfg.vsync
    Program.window_cfg.width = cfg.window_width
    Program.window_cfg.height = cfg.window_height

    Program.ApplyWindowSettings()
end

Settings.ApplyAudioSettings = function ()
    if not Settings.current then
        Settings.Load()
    end

    local cfg = Settings.current.audio

    AudioManager.SetMasterVolume(cfg.master_volume)
    AudioManager.SetMusicVolume(cfg.music_volume)
    AudioManager.SetSFXVolume(cfg.sfx_volume)
end

Settings.Reset = function ()
    local defaults = Settings.GetDefaults()

    Settings.current.audio = defaults.audio
    Settings.current.video = defaults.video

    Settings.Save()
end

Settings.ResetFlags = function ()
    local defaults = Settings.GetDefaults()
    Settings.current.flags = defaults.flags
end

return Settings

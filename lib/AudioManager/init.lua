---@class AudioSourceInfo
---@field tag string "music" or "sfx"
---@field base_volume number Original volume level

---@class AudioManager
---@field sources table<love.Source, AudioSourceInfo>
---@field master_volume number
---@field music_volume number
---@field sfx_volume number
---@field master_muted boolean
---@field music_muted boolean
---@field sfx_muted boolean
local AudioManager = {
    sources = {},
    master_volume = 1.0,
    music_volume = 1.0,
    sfx_volume = 1.0,
    master_muted = false,
    music_muted = false,
    sfx_muted = false
}

---@param settings table? Optional settings table with audio config
AudioManager.Init = function (settings)
    if settings and settings.audio then
        AudioManager.master_volume = settings.audio.master_volume or 1.0
        AudioManager.music_volume = settings.audio.music_volume or 1.0
        AudioManager.sfx_volume = settings.audio.sfx_volume or 1.0
        AudioManager.master_muted = settings.audio.master_muted or false
        AudioManager.music_muted = settings.audio.music_muted or false
        AudioManager.sfx_muted = settings.audio.sfx_muted or false
        print("[AudioManager] Initialized with saved settings")
    else
        print("[AudioManager] Initialized with default settings")
    end
end

---@param source love.Source
---@param loop boolean?
---@return love.Source
AudioManager.PlayMusic = function (source, loop)
    if loop == nil then loop = true end

    source:setLooping(loop)

    AudioManager.sources[source] = {
        tag = "music",
        base_volume = source:getVolume()
    }

    AudioManager.UpdateSourceVolume(source)

    source:play()

    return source
end

---@param source love.Source
---@param loop boolean?
---@return love.Source
AudioManager.PlaySFX = function (source, loop)
    if loop == nil then loop = false end

    source:setLooping(loop)

    AudioManager.sources[source] = {
        tag = "sfx",
        base_volume = source:getVolume()
    }

    AudioManager.UpdateSourceVolume(source)

    source:play()

    return source
end

---@param source love.Source
AudioManager.UpdateSourceVolume = function (source)
    local info = AudioManager.sources[source]
    if not info then return end

    local volume = info.base_volume * AudioManager.master_volume

    if info.tag == "music" then
        volume = volume * AudioManager.music_volume
        if AudioManager.music_muted or AudioManager.master_muted then
            volume = 0
        end
    elseif info.tag == "sfx" then
        volume = volume * AudioManager.sfx_volume
        if AudioManager.sfx_muted or AudioManager.master_muted then
            volume = 0
        end
    end

    source:setVolume(volume)
end

AudioManager.UpdateAllVolumes = function ()
    for source, _ in pairs(AudioManager.sources) do
        AudioManager.UpdateSourceVolume(source)
    end
end

AudioManager.CleanupStoppedSources = function ()
    local to_remove = {}

    for source, _ in pairs(AudioManager.sources) do
        if not source:isPlaying() then
            table.insert(to_remove, source)
        end
    end

    for _, source in ipairs(to_remove) do
        AudioManager.sources[source] = nil
    end
end

---Set master volume (0.0 to 1.0)
---@param volume number
AudioManager.SetMasterVolume = function (volume)
    AudioManager.master_volume = math.max(0, math.min(1, volume))
    AudioManager.UpdateAllVolumes()
end

---Set music volume (0.0 to 1.0)
---@param volume number
AudioManager.SetMusicVolume = function (volume)
    AudioManager.music_volume = math.max(0, math.min(1, volume))
    AudioManager.UpdateAllVolumes()
end

---Set SFX volume (0.0 to 1.0)
---@param volume number
AudioManager.SetSFXVolume = function (volume)
    AudioManager.sfx_volume = math.max(0, math.min(1, volume))
    AudioManager.UpdateAllVolumes()
end

---Set master mute state
---@param muted boolean
AudioManager.SetMasterMuted = function (muted)
    AudioManager.master_muted = muted
    AudioManager.UpdateAllVolumes()
end

---Set music mute state
---@param muted boolean
AudioManager.SetMusicMuted = function (muted)
    AudioManager.music_muted = muted
    AudioManager.UpdateAllVolumes()
end

---Set SFX mute state
---@param muted boolean
AudioManager.SetSFXMuted = function (muted)
    AudioManager.sfx_muted = muted
    AudioManager.UpdateAllVolumes()
end

AudioManager.StopAllMusic = function ()
    for source, info in pairs(AudioManager.sources) do
        if info.tag == "music" then
            source:stop()
        end
    end
    AudioManager.CleanupStoppedSources()
end

AudioManager.StopAllSFX = function ()
    for source, info in pairs(AudioManager.sources) do
        if info.tag == "sfx" then
            source:stop()
        end
    end
    AudioManager.CleanupStoppedSources()
end

AudioManager.StopAll = function ()
    for source, _ in pairs(AudioManager.sources) do
        source:stop()
    end
    AudioManager.sources = {}
end

return AudioManager

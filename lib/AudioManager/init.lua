---@class AudioSourceInfo
---@field tag string "music" or "sfx"
---@field base_volume number Original volume level

---@class AudioManager
---@field sources table<love.Source, AudioSourceInfo>
---@field master_volume number
---@field music_volume number
---@field sfx_volume number
local AudioManager = {
    sources = {},
    master_volume = 1.0,
    music_volume = 1.0,
    sfx_volume = 1.0,
}

---@param settings { master_volume: number, music_volume: number, sfx_volume: number } | nil
AudioManager.Init = function (settings)
    if type(settings) == "table" then
        AudioManager.master_volume = settings.master_volume or 1.0
        AudioManager.music_volume = settings.music_volume or 1.0
        AudioManager.sfx_volume = settings.sfx_volume or 1.0
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
    elseif info.tag == "sfx" then
        volume = volume * AudioManager.sfx_volume
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

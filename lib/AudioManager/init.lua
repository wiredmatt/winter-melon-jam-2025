---@class AudioSourceInfo
---@field tag string "music" or "sfx"
---@field base_volume number Original volume level

---@class AudioManager
---@field sources table<love.Source, AudioSourceInfo>
---@field master_volume number
---@field music_volume number
---@field sfx_volume number
---@field music_crossfade table?
local AudioManager = {
    sources = {},
    master_volume = 1.0,
    music_volume = 1.0,
    sfx_volume = 1.0,
    music_crossfade = nil,  -- { from, to, elapsed, duration }
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
    -- Clear crossfade state when stopping all music
    AudioManager.music_crossfade = nil
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

---Crossfade from one music source to another, optionally syncing playback position
---@param from_source love.Source? Current playing source (nil if starting fresh)
---@param to_source love.Source Target source to fade in
---@param duration number Fade duration in seconds
---@param sync_position boolean? If true, start to_source at from_source's position
AudioManager.CrossfadeMusic = function(from_source, to_source, duration, sync_position)
    -- Get current playback position if syncing
    local start_position = 0
    if sync_position and from_source and from_source:isPlaying() then
        start_position = from_source:tell()
        print(string.format("[AudioManager] Syncing position: %.2f seconds", start_position))
    else
        print("[AudioManager] Not syncing position (from_source not playing or sync disabled)")
    end

    -- Start to_source at the synchronized position
    to_source:seek(start_position)
    to_source:setLooping(true)

    -- Add to_source to sources table with volume starting at 0
    AudioManager.sources[to_source] = {
        tag = "music",
        base_volume = 1.0
    }

    -- Set initial volume to 0 for fade in
    to_source:setVolume(0)
    to_source:play()

    print(string.format("[AudioManager] Crossfade started: duration=%.1fs, from=%s, to=%s",
        duration,
        from_source and "active" or "nil",
        to_source and "active" or "nil"))

    -- Store crossfade state
    AudioManager.music_crossfade = {
        from = from_source,
        to = to_source,
        elapsed = 0,
        duration = duration
    }
end

---Update active music crossfade (call from scene update)
---@param dt number Delta time
AudioManager.UpdateCrossfade = function(dt)
    if not AudioManager.music_crossfade then
        return
    end

    local crossfade = AudioManager.music_crossfade
    crossfade.elapsed = crossfade.elapsed + dt

    -- Calculate fade progress (0 to 1)
    local progress = math.min(1.0, crossfade.elapsed / crossfade.duration)

    -- Update volumes
    if crossfade.from and AudioManager.sources[crossfade.from] then
        -- Fade out from_source
        local from_info = AudioManager.sources[crossfade.from]
        local from_volume = from_info.base_volume * (1 - progress) * AudioManager.master_volume * AudioManager.music_volume
        crossfade.from:setVolume(from_volume)
    end

    if crossfade.to and AudioManager.sources[crossfade.to] then
        -- Fade in to_source
        local to_info = AudioManager.sources[crossfade.to]
        local to_volume = to_info.base_volume * progress * AudioManager.master_volume * AudioManager.music_volume
        crossfade.to:setVolume(to_volume)
    end

    -- Check if crossfade is complete
    if progress >= 1.0 then
        print("[AudioManager] Crossfade complete!")

        -- Stop and remove from_source
        if crossfade.from then
            crossfade.from:stop()
            AudioManager.sources[crossfade.from] = nil
        end

        -- Ensure to_source has correct final volume
        if crossfade.to and AudioManager.sources[crossfade.to] then
            AudioManager.UpdateSourceVolume(crossfade.to)
        end

        -- Clear crossfade state
        AudioManager.music_crossfade = nil
    end
end

return AudioManager

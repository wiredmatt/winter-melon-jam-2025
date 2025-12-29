local AudioManager = require("lib.AudioManager")

---@class SoundPoolPicker
---@field pools table<string, love.Source[]> Map of pool names to arrays of sound sources
local SoundPoolPicker = {
    pools = {}
}

---@param pool_name string
---@param sound_sources love.Source[]
SoundPoolPicker.RegisterPool = function(pool_name, sound_sources)
    if not sound_sources or #sound_sources == 0 then
        error("SoundPoolPicker: Cannot register empty sound pool '" .. pool_name .. "'")
    end
    SoundPoolPicker.pools[pool_name] = sound_sources
end

---@param pool_name string
---@param volume number? base volume (0.0 to 1.0), will be multiplied by AudioManager's SFX volume
---@return boolean success
SoundPoolPicker.Play = function(pool_name, volume)
    local pool = SoundPoolPicker.pools[pool_name]
    if not pool then
        print("Warning: Sound pool '" .. pool_name .. "' not found")
        return false
    end

    local sound = pool[math.random(1, #pool)]

    local source = sound:clone()

    source:setVolume(volume or 1.0)

    -- play through AudioManager to respect global SFX volume settings
    AudioManager.PlaySFX(source, false)
    return true
end

---@param pool_name string
---@return boolean exists
SoundPoolPicker.HasPool = function(pool_name)
    return SoundPoolPicker.pools[pool_name] ~= nil
end

---@param pool_name string
---@return number count
SoundPoolPicker.GetPoolSize = function(pool_name)
    local pool = SoundPoolPicker.pools[pool_name]
    return pool and #pool or 0
end

SoundPoolPicker.Clear = function()
    SoundPoolPicker.pools = {}
end

return SoundPoolPicker

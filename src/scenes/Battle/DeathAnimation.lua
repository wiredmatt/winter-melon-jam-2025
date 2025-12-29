---@class DeathAnimationPreset
---@field rotation_speed number Radians per progress (e.g., math.pi * 4 = 2 spins)
---@field fall_distance number Pixels to fall downward
---@field scale_curve function Scale over time (progress -> scale)
---@field alpha_curve function Alpha over time (progress -> alpha)
---@field duration number Total animation time in seconds
---@field translation_func function? Custom translation (progress, data -> x, y)

---@class DeathAnimationConfig
---@field preset string? "spin_fall" | "explode" | "slide" | "fade"
---@field overrides table? Override specific preset values
---@field rotation_speed number? For custom animations
---@field fall_distance number? For custom animations
---@field scale_curve function? For custom animations
---@field alpha_curve function? For custom animations
---@field duration number? For custom animations
---@field translation_func function? For custom animations

---@class DeathAnimation
---@field timer number
---@field duration number
---@field active boolean
---@field sprite Sprite The sprite node to animate
---@field preset DeathAnimationPreset
---@field start_center_x number Initial center X position
---@field start_center_y number Initial center Y position
local DeathAnimation = {}
DeathAnimation.__index = DeathAnimation

local function table_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

local PRESETS = {
    --- spin and fall
    spin_fall = {
        rotation_speed = math.pi * 4,  -- 2 full rotations
        fall_distance = 200,
        scale_curve = function(p)
            return 1 + math.sin(p * math.pi) * 0.3  -- bounce scale
        end,
        alpha_curve = function(p)
            return 1 - (p * p)  -- quadratic fade out
        end,
        duration = 1.8
    },

    --- explosive defeat
    explode = {
        rotation_speed = math.pi * 8,  -- 4 fast spins
        fall_distance = 150,
        scale_curve = function(p)
            if p < 0.3 then
                -- grow quickly
                return 1 + (p / 0.3) * 0.5
            else
                -- shrink rapidly
                return 1.5 - ((p - 0.3) / 0.7) * 1.5
            end
        end,
        alpha_curve = function(p)
            if p < 0.2 then
                return 1
            else
                return 1 - ((p - 0.2) / 0.8)
            end
        end,
        duration = 1.2
    },

    ---Slide off screen to the right
    slide = {
        rotation_speed = 0,
        fall_distance = 0,   -- handled by custom translation
        translation_func = function(progress, data)
            return data.x + (progress * 400), data.y
        end,
        scale_curve = function(p)
            return 1
        end,
        alpha_curve = function(p)
            if p > 0.7 then
                -- Fade out at the end
                return 1 - ((p - 0.7) / 0.3)
            end
            return 1
        end,
        duration = 1.5
    },

    ---Simple fade in place
    fade = {
        rotation_speed = 0,
        fall_distance = 0,
        scale_curve = function(p)
            return 1
        end,
        alpha_curve = function(p)
            return 1 - p  -- linear fade
        end,
        duration = 2.0
    }
}

---@return DeathAnimation
DeathAnimation.New = function()
    local self = setmetatable({}, DeathAnimation)
    self.timer = 0
    self.duration = 0
    self.active = false
    self.sprite = nil
    self.preset = PRESETS.spin_fall
    self.start_center_x = 0
    self.start_center_y = 0
    return self
end

---@param config string|table Animation config
---@return DeathAnimationPreset
DeathAnimation._loadConfig = function(self, config)
    if type(config) == "string" then
        -- Simple preset reference
        return table_copy(PRESETS[config] or PRESETS.spin_fall)
    elseif type(config) == "table" then
        if config.preset then
            -- Preset with overrides
            local preset = table_copy(PRESETS[config.preset] or PRESETS.spin_fall)
            for k, v in pairs(config.overrides or {}) do
                preset[k] = v
            end
            return preset
        else
            -- Fully custom config
            return {
                rotation_speed = config.rotation_speed or 0,
                fall_distance = config.fall_distance or 0,
                scale_curve = config.scale_curve or function(p) return 1 end,
                alpha_curve = config.alpha_curve or function(p) return 1 - p end,
                duration = config.duration or 1.8,
                translation_func = config.translation_func
            }
        end
    end
    return table_copy(PRESETS.spin_fall)  -- Default fallback
end

---@param sprite Sprite The sprite node to animate
---@param animation_config string|table? Animation configuration
DeathAnimation.Start = function(self, sprite, animation_config)
    self.sprite = sprite
    self.preset = self:_loadConfig(animation_config or "spin_fall")
    self.duration = self.preset.duration
    self.timer = self.duration
    self.active = true

    -- Store starting center position
    local sprite_w, sprite_h = sprite.width, sprite.height
    self.start_center_x = sprite.x + (sprite_w / 2)
    self.start_center_y = sprite.y + (sprite_h / 2)
end

---@param dt number
---@return boolean still_animating
DeathAnimation.Update = function(self, dt)
    if not self.active or not self.sprite then
        return false
    end

    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.timer = 0
        self.active = false
        self.sprite.color[4] = 0  -- Fully transparent
        return false
    end

    self:ApplyToSprite()
    return true
end

---Apply animation transforms to sprite
DeathAnimation.ApplyToSprite = function(self)
    if not self.active or not self.sprite then
        return
    end

    local progress = 1 - (self.timer / self.duration)
    local preset = self.preset

    -- Calculate transforms
    local rotation = progress * preset.rotation_speed
    local fall = progress * preset.fall_distance
    local scale = preset.scale_curve(progress)
    local alpha = preset.alpha_curve(progress)

    -- Calculate center position
    local center_x, center_y = self.start_center_x, self.start_center_y + fall
    if preset.translation_func then
        -- Create temporary data for translation_func
        local temp_data = {
            x = self.start_center_x,
            y = self.start_center_y
        }
        center_x, center_y = preset.translation_func(progress, temp_data)
    end

    -- Convert to top-left position
    local sprite_w, sprite_h = self.sprite.width, self.sprite.height
    self.sprite.x = center_x - (sprite_w / 2)
    self.sprite.y = center_y - (sprite_h / 2)

    -- Apply transforms
    self.sprite.r = rotation
    self.sprite.sx = scale
    self.sprite.sy = scale
    self.sprite.color[4] = alpha
end

---@return boolean
DeathAnimation.IsActive = function(self)
    return self.active
end

return DeathAnimation

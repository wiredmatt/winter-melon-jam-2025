---@class AttackAnimationPreset
---@field approach_curve function Progress to distance traveled (0-1 -> 0-1)
---@field return_curve function Progress to distance traveled on return (0-1 -> 0-1)
---@field rotation_speed number? Radians per progress
---@field scale_curve function? Scale over time (progress -> scale)
---@field path_func function? Custom path deviation (progress, start_x, start_y, target_x, target_y -> x, y)
---@field duration number Total animation time in seconds

---@class AttackAnimationConfig
---@field preset string? "straight" | "spin_tackle" | "arc_tackle" | "zigzag" | "dash"
---@field overrides table? Override specific preset values

---@class AttackAnimation
---@field timer number
---@field duration number
---@field active boolean
---@field sprite Sprite The sprite node to animate
---@field target_center_x number Target center X position
---@field target_center_y number Target center Y position
---@field start_center_x number Start center X position
---@field start_center_y number Start center Y position
---@field max_distance number
---@field preset AttackAnimationPreset
local AttackAnimation = {}
AttackAnimation.__index = AttackAnimation

-- Helper function to copy table
local function table_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- Easing functions
local function easeOutQuad(t)
    return t * (2 - t)
end

local function easeInQuad(t)
    return t * t
end

local function easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

-- Attack animation presets
local PRESETS = {
    ---Straight tackle - simple fast approach and return
    straight = {
        approach_curve = function(p) return easeOutQuad(p) end,
        return_curve = function(p) return easeInQuad(1 - p) end,
        rotation_speed = 0,
        scale_curve = function(p) return 1 end,
        duration = 0.4
    },

    ---Spinning tackle - rotates while moving
    spin_tackle = {
        approach_curve = function(p) return easeOutQuad(p) end,
        return_curve = function(p) return easeInQuad(1 - p) end,
        rotation_speed = math.pi * 4,  -- 2 full rotations
        scale_curve = function(p)
            -- Slight scale bounce
            return 1 + math.sin(p * math.pi) * 0.15
        end,
        duration = 0.5
    },

    ---Arc tackle - moves in an arc path
    arc_tackle = {
        approach_curve = function(p) return easeInOutQuad(p) end,
        return_curve = function(p) return easeInOutQuad(1 - p) end,
        rotation_speed = math.pi * 2,
        path_func = function(progress, start_x, start_y, target_x, target_y)
            -- Calculate base position
            local dx = target_x - start_x
            local dy = target_y - start_y
            local base_x = start_x + dx * progress
            local base_y = start_y + dy * progress

            -- Add arc deviation perpendicular to direction
            local arc_height = 30 * math.sin(progress * math.pi)
            local perpendicular_x = -dy / math.sqrt(dx * dx + dy * dy)
            local perpendicular_y = dx / math.sqrt(dx * dx + dy * dy)

            return base_x + perpendicular_x * arc_height, base_y + perpendicular_y * arc_height
        end,
        scale_curve = function(p) return 1 end,
        duration = 0.5
    },

    ---Zigzag tackle - zigzag pattern
    zigzag = {
        approach_curve = function(p) return p end,
        return_curve = function(p) return 1 - p end,
        rotation_speed = 0,
        path_func = function(progress, start_x, start_y, target_x, target_y)
            local dx = target_x - start_x
            local dy = target_y - start_y
            local base_x = start_x + dx * progress
            local base_y = start_y + dy * progress

            -- Zigzag perpendicular to direction
            local zigzag = math.sin(progress * math.pi * 6) * 15 * (1 - progress)
            local perpendicular_x = -dy / math.sqrt(dx * dx + dy * dy)
            local perpendicular_y = dx / math.sqrt(dx * dx + dy * dy)

            return base_x + perpendicular_x * zigzag, base_y + perpendicular_y * zigzag
        end,
        scale_curve = function(p) return 1 end,
        duration = 0.45
    },

    ---Dash - very fast with anticipation
    dash = {
        approach_curve = function(p)
            -- Quick pullback then fast forward
            if p < 0.2 then
                return -p * 0.5  -- Pull back
            else
                local adjusted = (p - 0.2) / 0.8
                return easeInQuad(adjusted)
            end
        end,
        return_curve = function(p) return easeOutQuad(1 - p) end,
        rotation_speed = 0,
        scale_curve = function(p)
            -- Squash and stretch
            if p < 0.2 then
                return 1 + p * 0.5  -- Slightly bigger during anticipation
            elseif p < 0.5 then
                return 0.9  -- Squashed during dash
            else
                return 1
            end
        end,
        duration = 0.35
    },
}

---@return AttackAnimation
AttackAnimation.New = function()
    local self = setmetatable({}, AttackAnimation)
    self.timer = 0
    self.duration = 0
    self.active = false
    self.sprite = nil
    self.target_center_x = 0
    self.target_center_y = 0
    self.start_center_x = 0
    self.start_center_y = 0
    self.max_distance = 0
    self.preset = PRESETS.straight
    return self
end

---@param config string|table Animation config
---@return AttackAnimationPreset
AttackAnimation._loadConfig = function(self, config)
    if type(config) == "string" then
        return table_copy(PRESETS[config] or PRESETS.straight)
    elseif type(config) == "table" then
        if config.preset then
            local preset = table_copy(PRESETS[config.preset] or PRESETS.straight)
            for k, v in pairs(config.overrides or {}) do
                preset[k] = v
            end
            return preset
        else
            -- fully custom config
            return {
                approach_curve = config.approach_curve or function(p) return p end,
                return_curve = config.return_curve or function(p) return 1 - p end,
                rotation_speed = config.rotation_speed or 0,
                scale_curve = config.scale_curve or function(p) return 1 end,
                path_func = config.path_func,
                duration = config.duration or 0.4
            }
        end
    end
    return table_copy(PRESETS.straight)
end

---@param sprite Sprite The sprite node to animate
---@param target_center_x number Target center X position
---@param target_center_y number Target center Y position
---@param animation_config string|table? Animation configuration
AttackAnimation.Start = function(self, sprite, target_center_x, target_center_y, animation_config)
    self.sprite = sprite

    -- Get current center position from sprite
    local sprite_w, sprite_h = sprite.width, sprite.height
    self.start_center_x = sprite.x + (sprite_w / 2)
    self.start_center_y = sprite.y + (sprite_h / 2)

    self.target_center_x = target_center_x
    self.target_center_y = target_center_y

    local dx = target_center_x - self.start_center_x
    local dy = target_center_y - self.start_center_y
    self.max_distance = math.sqrt(dx * dx + dy * dy) * 0.7

    self.preset = self:_loadConfig(animation_config or "straight")
    self.duration = self.preset.duration
    self.timer = 0
    self.active = true
end

---@param dt number
---@return boolean still_animating
AttackAnimation.Update = function(self, dt)
    if not self.active then
        return false
    end

    self.timer = self.timer + dt
    if self.timer >= self.duration then
        self.timer = self.duration
        self.active = false
        self:ApplyToSprite()  -- Apply final state
        return false
    end

    self:ApplyToSprite()  -- Apply current state
    return true
end

---Apply animation transforms to sprite
AttackAnimation.ApplyToSprite = function(self)
    if not self.active or not self.sprite then
        return
    end

    local progress = self.timer / self.duration
    local preset = self.preset

    -- Determine phase
    local is_approach = progress < 0.5
    local phase_progress = is_approach and (progress * 2) or ((progress - 0.5) * 2)

    -- Calculate distance ratio
    local distance_ratio
    if is_approach then
        distance_ratio = preset.approach_curve(phase_progress)
    else
        distance_ratio = preset.return_curve(phase_progress)
    end

    -- Calculate center position
    local dx = self.target_center_x - self.start_center_x
    local dy = self.target_center_y - self.start_center_y
    local magnitude = math.sqrt(dx * dx + dy * dy)

    local traveled_distance = self.max_distance * distance_ratio
    local center_x, center_y

    if preset.path_func then
        local path_progress = is_approach and phase_progress or (1 - phase_progress)
        center_x, center_y = preset.path_func(path_progress, self.start_center_x, self.start_center_y,
                                               self.target_center_x, self.target_center_y)
        center_x = self.start_center_x + (center_x - self.start_center_x) * distance_ratio
        center_y = self.start_center_y + (center_y - self.start_center_y) * distance_ratio
    else
        center_x = self.start_center_x + (dx / magnitude) * traveled_distance
        center_y = self.start_center_y + (dy / magnitude) * traveled_distance
    end

    -- Convert to top-left position
    local sprite_w, sprite_h = self.sprite.width, self.sprite.height
    self.sprite.x = center_x - (sprite_w / 2)
    self.sprite.y = center_y - (sprite_h / 2)

    -- Apply rotation
    if preset.rotation_speed then
        self.sprite.r = progress * preset.rotation_speed
    else
        self.sprite.r = 0
    end

    -- Apply scale
    if preset.scale_curve then
        local scale = preset.scale_curve(progress)
        self.sprite.sx = scale
        self.sprite.sy = scale
    else
        self.sprite.sx = 1
        self.sprite.sy = 1
    end
end

---@return boolean
AttackAnimation.IsActive = function(self)
    return self.active
end

return AttackAnimation

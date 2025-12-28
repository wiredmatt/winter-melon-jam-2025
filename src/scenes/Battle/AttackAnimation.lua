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
---@field sprite_data table?
---@field target_x number
---@field target_y number
---@field start_x number
---@field start_y number
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
    self.sprite_data = nil
    self.target_x = 0
    self.target_y = 0
    self.start_x = 0
    self.start_y = 0
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

---@param sprite_data table {image, quad, x, y, sprite_w, sprite_h}
---@param target_x number Target X position
---@param target_y number Target Y position
---@param animation_config string|table? Animation configuration
AttackAnimation.Start = function(self, sprite_data, target_x, target_y, animation_config)
    self.sprite_data = sprite_data
    self.start_x = sprite_data.x
    self.start_y = sprite_data.y
    self.target_x = target_x
    self.target_y = target_y

    local dx = target_x - sprite_data.x
    local dy = target_y - sprite_data.y
    self.max_distance = math.sqrt(dx * dx + dy * dy) * 0.7  -- Go 70% of the way

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
        return false
    end

    return true
end

AttackAnimation.Draw = function(self)
    local data = self.sprite_data
    if not self.active or not data then
        return
    end

    local progress = self.timer / self.duration
    local preset = self.preset

    -- determine if we're approaching (first half) or returning (second half)
    local is_approach = progress < 0.5
    local phase_progress = is_approach and (progress * 2) or ((progress - 0.5) * 2)

    -- calculate distance based on phase
    local distance_ratio
    if is_approach then
        distance_ratio = preset.approach_curve(phase_progress)
    else
        distance_ratio = preset.return_curve(phase_progress)
    end

    -- calculate position
    local dx = self.target_x - self.start_x
    local dy = self.target_y - self.start_y
    local magnitude = math.sqrt(dx * dx + dy * dy)

    local traveled_distance = self.max_distance * distance_ratio
    local x, y

    if preset.path_func then
        -- custom path
        local path_progress = is_approach and phase_progress or (1 - phase_progress)
        x, y = preset.path_func(path_progress, self.start_x, self.start_y, self.target_x, self.target_y)

        -- scale by distance ratio
        x = self.start_x + (x - self.start_x) * distance_ratio
        y = self.start_y + (y - self.start_y) * distance_ratio
    else
        -- straight path
        x = self.start_x + (dx / magnitude) * traveled_distance
        y = self.start_y + (dy / magnitude) * traveled_distance
    end

    local rotation = 0
    if preset.rotation_speed then
        rotation = progress * preset.rotation_speed
    end

    local scale = 1
    if preset.scale_curve then
        scale = preset.scale_curve(progress)
    end

    local pr, pg, pb, pa = love.graphics.getColor()

    love.graphics.push()

    love.graphics.translate(x, y)
    love.graphics.rotate(rotation)
    love.graphics.scale(scale, scale)

    love.graphics.setColor(1, 1, 1, 1)
    if data.quad then
        love.graphics.draw(data.image, data.quad, -data.sprite_w / 2, -data.sprite_h / 2)
    else
        love.graphics.draw(data.image, -data.sprite_w / 2, -data.sprite_h / 2)
    end

    love.graphics.pop()
    love.graphics.setColor(pr, pg, pb, pa)
end

---@return boolean
AttackAnimation.IsActive = function(self)
    return self.active
end

return AttackAnimation

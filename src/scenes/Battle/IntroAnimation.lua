local function easeOutQuad(t)
    return t * (2 - t)
end

local function easeOutBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

local function easeOutElastic(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 or t == 1 then
        return t
    end
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

---@class IntroAnimation
---@field active boolean
---@field timer number
---@field duration number
---@field sprite Sprite The sprite node to animate
---@field start_x number Start center X position
---@field start_y number Start center Y position
---@field target_x number Target center X position
---@field target_y number Target center Y position
---@field preset table
local IntroAnimation = {}
IntroAnimation.__index = IntroAnimation

-- animation presets
local PRESETS = {
    -- simple slide from off-screen
    slide_in = {
        duration = 0.6,
        start_offset_x = -200, -- slide from left
        start_offset_y = 0,
        ease = easeOutQuad,
        rotation = 0,
        scale_start = 1.0,
        scale_end = 1.0,
    },

    -- slide from right
    slide_in_right = {
        duration = 0.6,
        start_offset_x = 200, -- slide from right
        start_offset_y = 0,
        ease = easeOutQuad,
        rotation = 0,
        scale_start = 1.0,
        scale_end = 1.0,
    },

    -- spin while entering from left
    spin_entry = {
        duration = 0.7,
        start_offset_x = -200,
        start_offset_y = 0,
        ease = easeOutQuad,
        rotation = math.pi * 2, -- full rotation
        scale_start = 1.0,
        scale_end = 1.0,
    },

    -- drop from above with bounce
    drop_bounce = {
        duration = 0.8,
        start_offset_x = 0,
        start_offset_y = -300, -- drop from above
        ease = easeOutBack,
        rotation = 0,
        scale_start = 1.0,
        scale_end = 1.0,
    },

    -- pop in with elastic effect
    pop_in = {
        duration = 0.9,
        start_offset_x = 0,
        start_offset_y = 0,
        ease = easeOutElastic,
        rotation = 0,
        scale_start = 0.0, -- start tiny
        scale_end = 1.0,
    },

    -- diagonal slide with spin
    diagonal_spin = {
        duration = 0.7,
        start_offset_x = -150,
        start_offset_y = -150,
        ease = easeOutQuad,
        rotation = math.pi * 1.5,
        scale_start = 1.0,
        scale_end = 1.0,
    },
}

IntroAnimation.New = function()
    local self = setmetatable({}, IntroAnimation)
    self.active = false
    self.timer = 0
    self.duration = 0
    self.sprite = nil
    self.start_x = 0
    self.start_y = 0
    self.target_x = 0
    self.target_y = 0
    self.preset = PRESETS.slide_in
    return self
end

---@param config string|table Animation preset name or custom config with overrides
---@return table
IntroAnimation._loadConfig = function(self, config)
    local preset_name = "slide_in"
    local overrides = {}

    if type(config) == "string" then
        preset_name = config
    elseif type(config) == "table" then
        preset_name = config.preset or "slide_in"
        overrides = config.overrides or {}
    end

    local preset = PRESETS[preset_name] or PRESETS.slide_in

    -- Apply overrides
    local final_config = {}
    for k, v in pairs(preset) do
        final_config[k] = v
    end
    for k, v in pairs(overrides) do
        final_config[k] = v
    end

    return final_config
end

---@param sprite Sprite The sprite node to animate
---@param target_center_x number Final center X position
---@param target_center_y number Final center Y position
---@param animation_config string|table Animation preset name or custom config
IntroAnimation.Start = function(self, sprite, target_center_x, target_center_y, animation_config)
    self.preset = self:_loadConfig(animation_config or "slide_in")

    self.active = true
    self.timer = 0
    self.duration = self.preset.duration
    self.sprite = sprite
    self.target_x = target_center_x
    self.target_y = target_center_y
    self.start_x = target_center_x + self.preset.start_offset_x
    self.start_y = target_center_y + self.preset.start_offset_y

    -- Set sprite to start position
    local sprite_w, sprite_h = sprite.width, sprite.height
    sprite.x = self.start_x - (sprite_w / 2)
    sprite.y = self.start_y - (sprite_h / 2)
    sprite.r = 0
    sprite.sx = self.preset.scale_start
    sprite.sy = self.preset.scale_start
    sprite.color[4] = 1
end

---@param dt number
IntroAnimation.Update = function(self, dt)
    if not self.active or not self.sprite then
        return
    end

    self.timer = self.timer + dt

    if self.timer >= self.duration then
        -- Set final position
        local sprite_w, sprite_h = self.sprite.width, self.sprite.height
        self.sprite.x = self.target_x - (sprite_w / 2)
        self.sprite.y = self.target_y - (sprite_h / 2)
        self.sprite.r = 0
        self.sprite.sx = self.preset.scale_end
        self.sprite.sy = self.preset.scale_end
        self.active = false
        return
    end

    local t = self.timer / self.duration
    local eased = self.preset.ease(t)

    -- Interpolate center position
    local current_center_x = self.start_x + (self.target_x - self.start_x) * eased
    local current_center_y = self.start_y + (self.target_y - self.start_y) * eased

    -- Convert to top-left position
    local sprite_w, sprite_h = self.sprite.width, self.sprite.height
    self.sprite.x = current_center_x - (sprite_w / 2)
    self.sprite.y = current_center_y - (sprite_h / 2)

    -- Update scale
    local current_scale = self.preset.scale_start + (self.preset.scale_end - self.preset.scale_start) * eased
    self.sprite.sx = current_scale
    self.sprite.sy = current_scale

    -- Update rotation
    if self.preset.rotation ~= 0 then
        self.sprite.r = self.preset.rotation * (1 - eased)
    else
        self.sprite.r = 0
    end
end

---@return boolean
IntroAnimation.IsActive = function(self)
    return self.active
end

return IntroAnimation

local Label = require("lib.ui.Label")

---@class TypewriterConfig : LabelConfig
---@field full_text string?
---@field chars_per_second number?
---@field on_complete function?
---@field auto_start boolean?
---@field sfx love.Source? Sound effect to play when typing
---@field sfx_interval number? Play sound every N characters (default: 1)
---@field sfx_volume number? Volume for the sound effect (0.0 - 1.0, default: 1.0)
---@field sfx_pitch_min number? Minimum pitch variation (default: 0.9)
---@field sfx_pitch_max number? Maximum pitch variation (default: 1.1)

---@class PauseMarker
---@field position number Character position where pause occurs
---@field duration number Pause duration in milliseconds

---@class Typewriter : Label
---@field full_text string
---@field chars_per_second number
---@field current_char_index number
---@field time_accumulator number
---@field is_typing boolean
---@field is_complete boolean
---@field on_complete function?
---@field sfx love.Source?
---@field sfx_interval number
---@field sfx_volume number
---@field sfx_pitch_min number
---@field sfx_pitch_max number
---@field sfx_char_counter number
---@field pause_markers PauseMarker[]
---@field is_paused boolean
---@field pause_time_remaining number
local Typewriter = setmetatable({}, { __index = Label })
Typewriter.__index = Typewriter

---Parse text and extract pause markers
---@param text string
---@return string cleaned_text, PauseMarker[] pause_markers
local function parse_pause_markers(text)
    local pause_markers = {}
    local cleaned_text = text
    local offset = 0

    -- find all pause markers: {{pause=500}}
    for pause_duration, pos in text:gmatch("{{pause=(%d+)}}()") do
        local marker_start = pos - string.len("{{pause=" .. pause_duration .. "}}")
        local actual_position = marker_start - offset

        table.insert(pause_markers, {
            position = actual_position,
            duration = tonumber(pause_duration) / 1000  -- convert ms to seconds
        })

        -- remove the marker from the cleaned text
        cleaned_text = cleaned_text:gsub("{{pause=%d+}}", "", 1)
        offset = offset + string.len("{{pause=" .. pause_duration .. "}}")
    end

    return cleaned_text, pause_markers
end

---@param config TypewriterConfig?
---@return Typewriter
Typewriter.New = function (config)
    config = config or {}

    -- init with empty text for label
    local label_config = {}
    for k, v in pairs(config) do
        label_config[k] = v
    end
    label_config.text = ""

    local base_label = Label.New(label_config)
    local self = setmetatable(base_label, Typewriter) --[[@as Typewriter]]

    -- parse pause markers from text
    local cleaned_text, pause_markers = parse_pause_markers(config.full_text or "")

    self.full_text = cleaned_text
    self.pause_markers = pause_markers
    self.chars_per_second = config.chars_per_second or 30
    self.current_char_index = 0
    self.time_accumulator = 0
    self.is_typing = false
    self.is_complete = false
    self.is_paused = false
    self.pause_time_remaining = 0
    self.on_complete = config.on_complete

    -- sound effects
    self.sfx = config.sfx
    self.sfx_interval = config.sfx_interval or 1
    self.sfx_volume = config.sfx_volume or 1.0
    self.sfx_pitch_min = config.sfx_pitch_min or 0.9
    self.sfx_pitch_max = config.sfx_pitch_max or 1.1
    self.sfx_char_counter = 0

    if config.auto_start ~= false then
        self:Start()
    end

    return self
end

--- start typing animation
Typewriter.Start = function (self)
    self.is_typing = true
    self.is_complete = false
    self.current_char_index = 0
    self.time_accumulator = 0
    self.text = ""
    self.sfx_char_counter = 0
    self.is_paused = false
    self.pause_time_remaining = 0
end

Typewriter.Reset = function (self)
    self.current_char_index = 0
    self.time_accumulator = 0
    self.is_typing = false
    self.is_complete = false
    self.text = ""
    self.sfx_char_counter = 0
    self.is_paused = false
    self.pause_time_remaining = 0
end

---@param new_text string
---@param auto_start boolean?
Typewriter.SetFullText = function (self, new_text, auto_start)
    -- parse pause markers from new text
    local cleaned_text, pause_markers = parse_pause_markers(new_text)
    self.full_text = cleaned_text
    self.pause_markers = pause_markers
    self:Reset()
    if auto_start ~= false then
        self:Start()
    end
end

---skip to the end of the current text
Typewriter.Skip = function (self)
    if not self.is_complete then
        self.current_char_index = #self.full_text
        self.text = self.full_text
        self.is_typing = false
        self.is_paused = false
        self.pause_time_remaining = 0
        self.is_complete = true

        if self.on_complete then
            self.on_complete()
        end
    end
end

---@return boolean
Typewriter.IsComplete = function (self)
    return self.is_complete
end

---@param dt number
Typewriter.Update = function (self, dt)
    if not self.is_typing then
        return
    end

    -- handle pause
    if self.is_paused then
        self.pause_time_remaining = self.pause_time_remaining - dt
        if self.pause_time_remaining <= 0 then
            self.is_paused = false
            self.pause_time_remaining = 0
        end
        -- don't add characters while paused
        for _, child in ipairs(self.children) do
            child:Update(dt)
        end
        return
    end

    self.time_accumulator = self.time_accumulator + dt
    local chars_to_add = math.floor(self.time_accumulator * self.chars_per_second)

    if chars_to_add > 0 then
        self.time_accumulator = self.time_accumulator - (chars_to_add / self.chars_per_second)
        self.current_char_index = math.min(self.current_char_index + chars_to_add, #self.full_text)

        -- update visible text
        self.text = self.full_text:sub(1, self.current_char_index)

        -- check if we hit a pause marker
        for _, marker in ipairs(self.pause_markers) do
            if self.current_char_index >= marker.position and not self.is_paused then
                self.is_paused = true
                self.pause_time_remaining = marker.duration
                -- remove this marker so we don't pause again
                for i, m in ipairs(self.pause_markers) do
                    if m == marker then
                        table.remove(self.pause_markers, i)
                        break
                    end
                end
                break
            end
        end

        -- play sound effect (only if not paused)
        if self.sfx and not self.is_paused then
            self.sfx_char_counter = self.sfx_char_counter + chars_to_add
            if self.sfx_char_counter >= self.sfx_interval then
                self.sfx_char_counter = self.sfx_char_counter % self.sfx_interval

                -- clone the source to allow overlapping sounds
                local sfx_clone = self.sfx:clone()
                sfx_clone:setVolume(self.sfx_volume)

                -- randomize pitch for variation
                local pitch = self.sfx_pitch_min + (self.sfx_pitch_max - self.sfx_pitch_min) * math.random()
                sfx_clone:setPitch(pitch)

                AudioManager.PlaySFX(sfx_clone)
            end
        end

        -- check if complete
        if self.current_char_index >= #self.full_text then
            self.is_typing = false
            self.is_complete = true

            if self.on_complete then
                self.on_complete()
            end
        end
    end

    for _, child in ipairs(self.children) do
        child:Update(dt)
    end
end

return Typewriter

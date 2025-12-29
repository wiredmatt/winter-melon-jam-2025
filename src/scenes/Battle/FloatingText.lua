local BattleConfig = require("src.scenes.Battle.config")

---@class FloatingTextEntry
---@field text string
---@field x number
---@field y number
---@field start_y number
---@field lifetime number
---@field max_lifetime number
---@field alpha number
---@field color table RGB color

---@class FloatingText
---@field texts FloatingTextEntry[]
---@field font love.Font
local FloatingText = {}
FloatingText.__index = FloatingText

---@param font love.Font
---@return FloatingText
FloatingText.New = function(font)
    local self = setmetatable({}, FloatingText)
    self.texts = {}
    self.font = font
    return self
end

---@param text string Text to display
---@param x number X position
---@param y number Y position
---@param color table? RGB color (defaults to bark color)
FloatingText.Spawn = function(self, text, x, y, color)
    -- add random positional variance to avoid overlapping
    local variance = BattleConfig.FLOATING_TEXT.POSITION_VARIANCE or 0
    local offset_x = math.random(-variance, variance)
    local offset_y = math.random(-variance, variance)

    table.insert(self.texts, {
        text = text,
        x = x + offset_x,
        y = y + offset_y,
        start_y = y + offset_y,
        lifetime = 0,
        max_lifetime = BattleConfig.FLOATING_TEXT.MAX_LIFETIME,
        alpha = 0,
        color = color or BattleConfig.FLOATING_TEXT.BARK_COLOR
    })
end

---@param dt number
FloatingText.Update = function(self, dt)
    local config = BattleConfig.FLOATING_TEXT

    for i = #self.texts, 1, -1 do
        local ft = self.texts[i]
        ft.lifetime = ft.lifetime + dt

        -- Slide up
        ft.y = ft.start_y - (ft.lifetime * config.SLIDE_SPEED)

        -- Fade in/out
        local fade_in_time = config.FADE_IN_TIME
        local fade_out_time = config.FADE_OUT_TIME
        local hold_time = ft.max_lifetime - fade_in_time - fade_out_time

        if ft.lifetime < fade_in_time then
            -- Fade in
            ft.alpha = ft.lifetime / fade_in_time
        elseif ft.lifetime < fade_in_time + hold_time then
            -- Hold
            ft.alpha = 1
        else
            -- Fade out
            local fade_progress = (ft.lifetime - fade_in_time - hold_time) / fade_out_time
            ft.alpha = 1 - fade_progress
        end

        -- Remove when lifetime expired
        if ft.lifetime >= ft.max_lifetime then
            table.remove(self.texts, i)
        end
    end
end

FloatingText.Draw = function(self)
    if #self.texts == 0 then return end

    local prev_font = love.graphics.getFont()
    local pr, pg, pb, pa = love.graphics.getColor()

    love.graphics.setFont(self.font)

    for _, ft in ipairs(self.texts) do
        local text_width = self.font:getWidth(ft.text)
        local x = ft.x - text_width / 2

        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], ft.alpha)
        love.graphics.print(ft.text, x, ft.y)
    end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(pr, pg, pb, pa)
end

FloatingText.Clear = function(self)
    self.texts = {}
end

return FloatingText

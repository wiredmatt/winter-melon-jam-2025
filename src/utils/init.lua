local Utils = {}

---@param color love.Color
---@return love.Color
Utils.CopyColor = function(color)
    return {color[1], color[2], color[3], color[4]}
end

---@param a number
---@param b number
---@param t number
---@return number
Utils.Lerp = function(a, b, t)
    return a + (b - a) * t
end

---@param c1 love.Color
---@param c2 love.Color
---@param t number
---@return love.Color
Utils.LerpColor = function(c1, c2, t)
    local result = {}
    for i = 1, 4 do
        result[i] = Utils.Lerp(c1[i], c2[i], t)
    end
    return result
end

---@param color love.Color
---@param amount number?
---@return love.Color
Utils.BrightenColor = function(color, amount)
    amount = amount or 0.02
    local result = {
        color[1] + (1 - color[1]) * amount,  -- R
        color[2] + (1 - color[2]) * amount,  -- G
        color[3] + (1 - color[3]) * amount,  -- B
        color[4] or 1                        -- A
    }
    return result
end


return Utils
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

return Utils
---@class FontProxy
local FontProxy = {}
FontProxy.__index = FontProxy

---@alias ProxiedFont { [number]: love.Font }

---@param fontpath string
---@return ProxiedFont
FontProxy.New = function (fontpath)
    local testfnt = love.graphics.newFont(fontpath, 1) -- ensure font file exists and can be loaded
    testfnt:release()

    return setmetatable({}, {
        __index = function (t, k)
            local cached = rawget(t, k)
            if cached ~= nil then return cached end
            cached = love.graphics.newFont(fontpath, k)
            t[k] = cached
            return cached
        end
    })
end

return FontProxy
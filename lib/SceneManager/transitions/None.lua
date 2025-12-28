local None = {}
None.__index = None
---@return fun(): Transition
None.New = function()
    return function () return setmetatable({ completed = true, progress = 1 }, None) end
end
None.Update = __NOOP__
None.Draw = __NOOP__
return None
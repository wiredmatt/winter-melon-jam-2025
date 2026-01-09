---@class HoverColorComponent : Component
---@field default_color love.Color
---@field current_color love.Color
---@field target_color love.Color
---@field on_enter_color love.Color
---@field step number
---@field target_components string[]?
---@field _targets Component[]

---@class HoverColorComponentClass
---@field New fun(config: { default_color: love.Color?, on_enter_color: love.Color, step: number?, target_components: string[]? }): HoverColorComponent

local HoverColorComponent = SceneGraph.Component.Define("HoverColor", {
    ---@param self HoverColorComponent
    ---@param config { default_color: love.Color?, on_enter_color: love.Color, step: number?, target_components: string[]? }
    Init = function(self, config)
        self.on_enter_color = config.on_enter_color
        self.step = config.step or 0.1
        self.target_components = config.target_components

        self.default_color = config.default_color
        self.current_color = nil
        self.target_color = nil
        self._targets = {}
    end,

    ---@param self HoverColorComponent
    OnAdded = function(self)
        if self.target_components then
            local filtered = {}
            for _, target in ipairs(self.target_components) do
                if target:sub(1, 1) == "#" then
                    local name = target:sub(2)
                    local component = self.node:GetComponentByName(name)
                    if component then
                        table.insert(filtered, component)
                    end
                else
                    local drawables = self.node:GetComponents(target)
                    for _, drawable in ipairs(drawables) do
                        table.insert(filtered, drawable)
                    end
                end
            end
            self._targets = filtered
        else
            self._targets = self.node:GetComponents("Drawable")
        end

        local initial_color = self.default_color or {1, 1, 1, 1}
        if #self._targets > 0 and self._targets[1].color then
            initial_color = Utils.CopyColor(self._targets[1].color)
        end

        self.default_color = self.default_color or initial_color
        self.current_color = Utils.CopyColor(initial_color)
        self.target_color = Utils.CopyColor(initial_color)
    end,

    ---@param self HoverColorComponent
    ---@param x number
    ---@param y number
    Hover = function(self, x, y)
        self.target_color = self.on_enter_color
    end,

    ---@param self HoverColorComponent
    HoverEnd = function(self)
        self.target_color = self.default_color
    end,

    ---@param self HoverColorComponent
    ---@param dt number
    Update = function(self, dt)
        self.current_color = Utils.LerpColor(self.current_color, self.target_color, self.step)

        for _, drawable in ipairs(self._targets) do
            drawable.color = self.current_color
        end
    end,
})

return HoverColorComponent  --[[@as HoverColorComponentClass]]

---@class HoverScaleComponent : Component
---@field default_scale number
---@field current_scale number
---@field target_scale number
---@field on_enter_scale number
---@field step number
---@field target_components string[]?
---@field _targets Component[]

---@class HoverScaleComponentClass
---@field New fun(config: { default_scale: number?, on_enter_scale: number, step: number?, target_components: string[]? }): HoverScaleComponent

local HoverScaleComponent = SceneGraph.Component.Define("HoverScale", {
    ---@param self HoverScaleComponent
    ---@param config { default_scale: number?, on_enter_scale: number, step: number?, target_components: string[]? }
    Init = function(self, config)
        self.on_enter_scale = config.on_enter_scale or 1.1
        self.step = config.step or 0.1
        self.target_components = config.target_components

        self.default_scale = config.default_scale or 1
        self.current_scale = self.default_scale
        self.target_scale = self.default_scale
        self._targets = {}
    end,

    ---@param self HoverScaleComponent
    OnAdded = function(self)
        if self.target_components then
            for _, target in ipairs(self.target_components) do
                if target:sub(1, 1) == "#" then
                    local name = target:sub(2)
                    local component = self.node:GetComponentByName(name)
                    if component then
                        table.insert(self._targets, component)
                    end
                else
                    local components = self.node:GetComponents(target)
                    for _, component in ipairs(components) do
                        table.insert(self._targets, component)
                    end
                end
            end
        end

        if self.node and #self._targets == 0 then
            self.default_scale = self.node.sx
            self.current_scale = self.default_scale
            self.target_scale = self.default_scale
        end
    end,

    ---@param self HoverScaleComponent
    ---@param x number
    ---@param y number
    Focus = function(self, x, y)
        self.target_scale = self.on_enter_scale
    end,

    ---@param self HoverScaleComponent
    ---@param x number
    ---@param y number
    Hover = function(self, x, y)
        self.target_scale = self.on_enter_scale
    end,

    ---@param self HoverScaleComponent
    HoverEnd = function(self)
        self.target_scale = self.default_scale
    end,

    ---@param self HoverScaleComponent
    Blur = function(self)
        self.target_scale = self.default_scale
    end,

    ---@param self HoverScaleComponent
    ---@param dt number
    Update = function(self, dt)
        if self.current_scale ~= self.target_scale then
            self.current_scale = Utils.Lerp(self.current_scale, self.target_scale, self.step)

            if #self._targets > 0 then
                for _, component in ipairs(self._targets) do
                    component.sx = self.current_scale
                    component.sy = self.current_scale
                end
            else
                if self.node then
                    self.node:SetScale(self.current_scale, self.current_scale)
                end
            end
        end
    end,
})

return HoverScaleComponent --[[@as HoverScaleComponentClass]]
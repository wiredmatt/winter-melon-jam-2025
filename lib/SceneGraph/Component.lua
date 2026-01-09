---@class Component
---@field type string
---@field enabled boolean
---@field node Node?
---@field name string?
---@field types string[]?
---@field OnAdded fun(self: Component)?
---@field Update fun(self: Component, dt: number)?
---@field Draw fun(self: Component)?
---@field OnRemoved fun(self: Component)?

---@class ComponentClass
---@field New fun(config: table?): Component

local Component = {}

---@param type_name string the component type identifier
---@param impl table implementation table with Init, Update, Draw, etc.
---@return ComponentClass
function Component.Define(type_name, impl)
    local ComponentClass = {}
    ComponentClass.__index = ComponentClass

    ---@param config table?
    ---@return Component
    function ComponentClass.New(config)
        config = config or {}

        local instance = {
            type = type_name,
            enabled = true,
            node = nil,
            name = config.name or nil,
        }

        for k, v in pairs(impl) do
            if k ~= "Init" then
                instance[k] = v
            end
        end

        if impl.Init then
            impl.Init(instance, config)
        end

        return setmetatable(instance, ComponentClass)
    end

    return ComponentClass
end

return Component

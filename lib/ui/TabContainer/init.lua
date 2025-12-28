local Node = require("lib.ui.Node")
local Button = require("lib.ui.Button")

---@class TabDefinition
---@field label string
---@field content Node

---@class TabContainerConfig : NodeConfig
---@field tab_height number?
---@field tab_padding number?
---@field font love.Font?
---@field active_tab_color table?
---@field inactive_tab_color table?
---@field tab_text_color table?
---@field content_background_color table?

---@class TabContainer : Node
---@field tabs TabDefinition[]
---@field active_tab_index number
---@field tab_height number
---@field tab_padding number
---@field font love.Font
---@field active_tab_color table
---@field inactive_tab_color table
---@field tab_text_color table
---@field content_background_color table
---@field tab_buttons Button[]
---@field content_container Node
local TabContainer = setmetatable({}, { __index = Node })
TabContainer.__index = TabContainer

---@param config TabContainerConfig?
---@return TabContainer
TabContainer.New = function (config)
    config = config or {}

    local base_node = Node.New(config)

    local self = setmetatable(base_node, TabContainer) --[[@as TabContainer]]

    self.tabs = {}
    self.active_tab_index = 1
    self.tab_height = config.tab_height or 30
    self.tab_padding = config.tab_padding or 0
    self.font = config.font or love.graphics.getFont()
    self.active_tab_color = config.active_tab_color or {0.5, 0.7, 1.0, 1}
    self.inactive_tab_color = config.inactive_tab_color or {0.3, 0.3, 0.3, 1}
    self.tab_text_color = config.tab_text_color or {1, 1, 1, 1}
    self.content_background_color = config.content_background_color or {0.15, 0.15, 0.15, 1}
    self.tab_buttons = {}

    self.content_container = Node.New({
        x = 0,
        y = self.tab_height,
        width = self.width,
        height = self.height - self.tab_height
    })
    base_node:AddChild(self.content_container)

    return self
end

---@param label string
---@param content Node
TabContainer.AddTab = function (self, label, content)
    table.insert(self.tabs, {
        label = label,
        content = content
    })

    self:RebuildTabButtons()

    -- if this is the first tab, set it as active
    if #self.tabs == 1 then
        self:SetActiveTab(1)
    end
end

TabContainer.RebuildTabButtons = function (self)
    -- clear existing tab buttons
    for _, button in ipairs(self.tab_buttons) do
        button:Destroy()
    end
    self.tab_buttons = {}

    self:RemoveChild(self.content_container)

    -- calculate tab button width
    local tab_width = math.floor((self.width - (self.tab_padding * (#self.tabs + 1))) / #self.tabs)

    -- tab buttons
    for tab_idx, tab in ipairs(self.tabs) do
        local button = Button.New({
            x = math.floor(self.tab_padding + (tab_idx - 1) * (tab_width + self.tab_padding)),
            y = math.floor(self.tab_padding),
            width = tab_width,
            height = math.floor(self.tab_height - (self.tab_padding * 2)),
            text = tab.label,
            font = self.font,
            normal_color = tab_idx == self.active_tab_index and self.active_tab_color or self.inactive_tab_color,
            hover_color = tab_idx == self.active_tab_index and self.active_tab_color or {0.4, 0.4, 0.4, 1},
            pressed_color = {0.2, 0.2, 0.2, 1},
            text_color = self.tab_text_color,
            border_width = 0,
            focusable = false
        })

        button.OnClick = function() self:SetActiveTab(tab_idx) end

        self:AddChild(button)
        table.insert(self.tab_buttons, button)
    end

    self:AddChild(self.content_container)
end

---@param index number
TabContainer.SetActiveTab = function (self, index)
    if index < 1 or index > #self.tabs then
        return
    end

    self.active_tab_index = index
    self.content_container.children = {}

    local active_tab = self.tabs[index]
    if active_tab and active_tab.content then
        self.content_container:AddChild(active_tab.content)
    end

    for i, button in ipairs(self.tab_buttons) do
        if i == index then
            button.normal_color = self.active_tab_color
            button.hover_color = self.active_tab_color
        else
            button.normal_color = self.inactive_tab_color
            button.hover_color = {0.4, 0.4, 0.4, 1}
        end
    end
end

TabContainer.Draw = function (self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.r)
    love.graphics.scale(self.sx, self.sy)

    local pr, pg, pb, pa = love.graphics.getColor()

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.tab_height)

    love.graphics.setColor(self.content_background_color)
    love.graphics.rectangle("fill", 0, self.tab_height, self.width, self.height - self.tab_height)

    love.graphics.setColor(pr, pg, pb, pa)

    for _, child in ipairs(self.children) do
        child:Draw()
    end

    self:DrawDebugOverlay()

    love.graphics.pop()
end

return TabContainer

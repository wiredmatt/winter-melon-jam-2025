---@class MaskSwapUIConfig
---@field screen_width number
---@field screen_height number
---@field inputmap table
---@field title_font love.Font
---@field body_font love.Font
---@field small_font? love.Font
---@field on_mask_selected function
---@field on_close function? when menu is closed

---@class MaskSwapUI : MaskSwapUIConfig
---@field visible boolean
---@field root_node Node
---@field on_close function?
---@field screen_width number
---@field screen_height number
---@field current_mask_id string
---@field overlay Sprite
---@field selected_mask Mask?
---@field legend_labels table<string, Label>
local MaskSwapUI = {}
MaskSwapUI.__index = MaskSwapUI

---@param config MaskSwapUIConfig
---@return MaskSwapUI
MaskSwapUI.New = function(config)
    local self = setmetatable({}, MaskSwapUI)

    self.visible = false
    self.root_node = UI.Node.New()
    self.on_mask_selected = config.on_mask_selected or function() end
    self.on_close = config.on_close
    self.screen_width = config.screen_width
    self.screen_height = config.screen_height
    self.title_font = config.title_font
    self.body_font = config.body_font
    self.small_font = config.small_font or config.body_font
    self.inputmap = config.inputmap
    self.current_mask_id = ""
    self.selected_mask = nil
    self.legend_labels = {}

    return self
end

---@param collected_masks Mask[]
---@param current_mask_id string
MaskSwapUI.Show = function(self, collected_masks, current_mask_id)
    self.visible = true
    self.current_mask_id = current_mask_id

    self.root_node = UI.Node.New()

    local screen_w = self.screen_width
    local screen_h = self.screen_height

    -- dark overlay
    self.overlay = UI.Sprite.New({
        x = 0,
        y = 0,
        width = screen_w,
        height = screen_h,
        color = {0, 0, 0, 0.8}
    })
    self.root_node:AddChild(self.overlay)

    -- main panel dimensions
    local panel_w = 240
    local panel_h = 150
    local panel_x = (screen_w - panel_w) / 2
    local panel_y = (screen_h - panel_h) / 2

    local panel_bg = UI.Sprite.New({
        x = panel_x,
        y = panel_y,
        width = panel_w,
        height = panel_h,
        color = {0.15, 0.15, 0.15, 1}
    })
    self.root_node:AddChild(panel_bg)

    local title = UI.Label.New({
        text = "Select Mask",
        font = self.title_font,
        x = panel_x,
        y = panel_y + 3,
        width = panel_w,
        align = "center",
        color = {1, 1, 0.5, 1}
    })
    self.root_node:AddChild(title)

    -- grid configuration: 3 columns x 2 rows
    local grid_cols = 3
    local grid_rows = 2
    local slot_size = 24  -- fit 16x16 sprites, with some padding
    local slot_spacing = 6
    local grid_w = grid_cols * slot_size + (grid_cols - 1) * slot_spacing
    local grid_x = panel_x + (panel_w - grid_w) / 2
    local grid_y = panel_y + title.height + 8

    -- legend panel (details area at bottom)
    local legend_y = grid_y + grid_rows * (slot_size + slot_spacing) + 6
    local legend_h = panel_y + panel_h - legend_y - 5

    local legend_bg = UI.Sprite.New({
        x = panel_x + 5,
        y = legend_y,
        width = panel_w - 10,
        height = legend_h,
        color = {0.2, 0.2, 0.2, 1}
    })
    self.root_node:AddChild(legend_bg)

    -- legend labels (updated when mask is selected/hovered)
    local legend_padding = 3
    local legend_inner_x = panel_x + 5 + legend_padding
    local legend_inner_y = legend_y + legend_padding
    local legend_inner_w = panel_w - 10 - legend_padding * 2

    self.legend_labels.name = UI.Label.New({
        text = "---",
        font = self.body_font,
        x = legend_inner_x,
        y = legend_inner_y,
        width = legend_inner_w,
        align = "left",
        color = {1, 1, 1, 1}
    })
    self.root_node:AddChild(self.legend_labels.name)

    self.legend_labels.description = UI.Label.New({
        text = "",
        font = self.small_font,
        x = legend_inner_x,
        y = legend_inner_y + 10,
        width = legend_inner_w,
        align = "left",
        color = {0.7, 0.7, 0.7, 1}
    })
    self.root_node:AddChild(self.legend_labels.description)

    self.legend_labels.passive = UI.Label.New({
        text = "",
        font = self.small_font,
        x = legend_inner_x,
        y = legend_inner_y + 28,
        width = legend_inner_w,
        align = "left",
        color = {0.5, 1, 0.5, 1}
    })
    self.root_node:AddChild(self.legend_labels.passive)

    self.legend_labels.active = UI.Label.New({
        text = "",
        font = self.small_font,
        x = legend_inner_x,
        y = legend_inner_y + 42,
        width = legend_inner_w,
        align = "left",
        color = {1, 0.5, 0.5, 1}
    })
    self.root_node:AddChild(self.legend_labels.active)

    -- create mask grid slots
    for i = 1, 6 do
        local col = (i - 1) % grid_cols
        local row = math.floor((i - 1) / grid_cols)
        local slot_x = grid_x + col * (slot_size + slot_spacing)
        local slot_y = grid_y + row * (slot_size + slot_spacing)

        local mask = collected_masks[i]

        if mask then
            local is_equipped = mask.id == current_mask_id

            -- create mask button with icon
            local button = UI.Button.New({
                text = "",
                x = slot_x,
                y = slot_y,
                width = slot_size,
                height = slot_size,
                focusable = true,
                normal_color = {0.25, 0.25, 0.25, 1},
                hover_color = {0.35, 0.35, 0.35, 1},
                pressed_color = {0.2, 0.2, 0.2, 1},
                border_color = is_equipped and {1, 1, 0, 1} or {0.5, 0.5, 0.5, 1},
                border_width = is_equipped and 2 or 1,
                icon = mask.sprite_image,
                icon_quad = mask.sprite_quad,
                icon_position = "left",
            })

            -- store mask ref for detail display
            button.mask_data = mask

            button.OnClick = function()
                self.on_mask_selected(mask.id)
                self:Hide()
            end

            button.OnHover = function()
                self:UpdateLegend(mask)
            end

            button.OnFocus = function()
                self:UpdateLegend(mask)
            end

            self.root_node:AddChild(button)

            if is_equipped then
                button.focused = true
                self:UpdateLegend(mask)
            end
        else
            local empty_slot = UI.Sprite.New({
                x = slot_x,
                y = slot_y,
                width = slot_size,
                height = slot_size,
                color = {0.1, 0.1, 0.1, 1}
            })
            self.root_node:AddChild(empty_slot)

            local border = UI.Sprite.New({
                x = slot_x,
                y = slot_y,
                width = slot_size,
                height = slot_size,
                color = {0.3, 0.3, 0.3, 1}
            })
            self.root_node:AddChild(border)
        end
    end
end

---@param mask Mask
MaskSwapUI.UpdateLegend = function(self, mask)
    if not mask then return end

    self.selected_mask = mask

    self.legend_labels.name.text = mask.name

    self.legend_labels.description.text = mask.description

    local passive_text = "Passive: " .. (mask.passive.type or "none")
    if mask.passive.value then
        passive_text = passive_text .. " (" .. (mask.passive.value * 100) .. "%)"
    end
    self.legend_labels.passive.text = passive_text

    local active_text = "Active: " .. (mask.active.name or "none")
    if mask.active.description then
        active_text = active_text .. " - " .. mask.active.description
    end
    self.legend_labels.active.text = active_text
end

MaskSwapUI.Hide = function(self)
    self.visible = false
    if self.on_close then
        self.on_close()
    end
    self.root_node:ClearFocus()
    for i = #self.root_node.children, 1, -1 do
        self.root_node:RemoveChild(self.root_node.children[i])
    end
    self.selected_mask = nil
    self.legend_labels = {}
end

MaskSwapUI.HandleInput = function(self)
    if not self.visible then
        return
    end

    if InputManager.JustPressed(self.inputmap.actions.CANCEL) then
        self:Hide()
        return
    end

    local dx, dy = 0, 0
    local has_input = false

    if InputManager.JustPressed(self.inputmap.actions.NAVIGATE_UP) then
        dy = -1
        has_input = true
    elseif InputManager.JustPressed(self.inputmap.actions.NAVIGATE_DOWN) then
        dy = 1
        has_input = true
    elseif InputManager.JustPressed(self.inputmap.actions.NAVIGATE_LEFT) then
        dx = -1
        has_input = true
    elseif InputManager.JustPressed(self.inputmap.actions.NAVIGATE_RIGHT) then
        dx = 1
        has_input = true
    end

    if has_input then
        self.root_node:FocusDirection(dx, dy)
    end

    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        self.root_node:ActivateFocused()
    end
end

MaskSwapUI.Update = function(self, dt)
    if not self.visible then
        return
    end

    self.root_node:Update(dt)
end

MaskSwapUI.Draw = function(self)
    if not self.visible then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    self.root_node:Draw()
end

return MaskSwapUI

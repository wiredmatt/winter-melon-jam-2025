---@class MaskUnlockedUIConfig
---@field screen_width number
---@field screen_height number
---@field inputmap table
---@field title_font love.Font
---@field body_font love.Font
---@field small_font? love.Font
---@field on_continue function

---@class MaskUnlockedUI : MaskUnlockedUIConfig
---@field visible boolean
---@field root_node Node
---@field screen_width number
---@field screen_height number
---@field overlay Sprite
---@field unlocked_mask Mask?
local MaskUnlockedUI = {}
MaskUnlockedUI.__index = MaskUnlockedUI

---@param config MaskUnlockedUIConfig
---@return MaskUnlockedUI
MaskUnlockedUI.New = function(config)
    local self = setmetatable({}, MaskUnlockedUI)

    self.visible = false
    self.root_node = UI.Node.New()
    self.on_continue = config.on_continue or function() end
    self.screen_width = config.screen_width
    self.screen_height = config.screen_height
    self.title_font = config.title_font
    self.body_font = config.body_font
    self.small_font = config.small_font or config.body_font
    self.inputmap = config.inputmap
    self.unlocked_mask = nil

    return self
end

---@param mask Mask
MaskUnlockedUI.Show = function(self, mask)
    self.visible = true
    self.unlocked_mask = mask

    AudioManager.PlaySFX(AssetManager.assets.sfx.mask_unlocked_wav)

    self.root_node = UI.Node.New()

    local screen_w = self.screen_width
    local screen_h = self.screen_height

    self.overlay = UI.Sprite.New({
        x = 0,
        y = 0,
        width = screen_w,
        height = screen_h,
        color = {0, 0, 0, 0.85}
    })
    self.root_node:AddChild(self.overlay)

    local panel_w = 200
    local panel_h = 140
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
        text = "Mask Unlocked!",
        font = self.title_font,
        x = panel_x,
        y = panel_y + 3,
        width = panel_w,
        align = "center",
        color = {1, 0.8, 0.2, 1}
    })
    self.root_node:AddChild(title)

    local mask_size = 16
    local mask_x = panel_x + (panel_w - mask_size) / 2
    local mask_y = panel_y + title.height + 10

    if mask.sprite_image then
        local mask_sprite = UI.Sprite.New({
            image = mask.sprite_image,
            quad = mask.sprite_quad,
            x = mask_x,
            y = mask_y,
            width = mask_size,
            height = mask_size,
        })
        self.root_node:AddChild(mask_sprite)
    end

    local details_y = mask_y + mask_size + 8
    local details_h = panel_y + panel_h - details_y - 18

    local details_bg = UI.Sprite.New({
        x = panel_x + 5,
        y = details_y,
        width = panel_w - 10,
        height = details_h,
        color = {0.2, 0.2, 0.2, 1}
    })
    self.root_node:AddChild(details_bg)

    local details_padding = 3
    local details_x = panel_x + 5 + details_padding
    local details_inner_y = details_y + details_padding
    local details_w = panel_w - 10 - details_padding * 2

    local name_label = UI.Label.New({
        text = mask.name,
        font = self.body_font,
        x = details_x,
        y = details_inner_y,
        width = details_w,
        align = "center",
        color = {1, 1, 1, 1}
    })
    self.root_node:AddChild(name_label)

    local desc_label = UI.Label.New({
        text = mask.description,
        font = self.small_font,
        x = details_x,
        y = details_inner_y + 10,
        width = details_w,
        align = "center",
        color = {0.7, 0.7, 0.7, 1}
    })
    self.root_node:AddChild(desc_label)

    local passive_text = "Passive: " .. (mask.passive.type or "none")
    if mask.passive.value then
        passive_text = passive_text .. " (" .. (mask.passive.value * 100) .. "%)"
    end
    local passive_label = UI.Label.New({
        text = passive_text,
        font = self.small_font,
        x = details_x,
        y = details_inner_y + 28,
        width = details_w,
        align = "left",
        color = {0.5, 1, 0.5, 1}
    })
    self.root_node:AddChild(passive_label)

    local active_text = "Active: " .. (mask.active.name or "none")
    if mask.active.description then
        active_text = active_text .. " - " .. mask.active.description
    end
    local active_label = UI.Label.New({
        text = active_text,
        font = self.small_font,
        x = details_x,
        y = details_inner_y + 42,
        width = details_w,
        align = "left",
        color = {1, 0.5, 0.5, 1}
    })
    self.root_node:AddChild(active_label)

    local footer_y = panel_y + panel_h - 12
    local footer_label = UI.Label.New({
        text = "Press Space to Continue",
        font = self.small_font,
        x = panel_x,
        y = footer_y,
        width = panel_w,
        align = "center",
        color = {0.8, 0.8, 0.8, 1}
    })
    self.root_node:AddChild(footer_label)
end

MaskUnlockedUI.Hide = function(self)
    self.visible = false
    for i = #self.root_node.children, 1, -1 do
        self.root_node:RemoveChild(self.root_node.children[i])
    end
    self.unlocked_mask = nil
end

MaskUnlockedUI.HandleInput = function(self)
    if not self.visible then
        return
    end

    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        self:Hide()
        self.on_continue()
    end
end

MaskUnlockedUI.Update = function(self, dt)
    if not self.visible then
        return
    end

    self.root_node:Update(dt)
end

MaskUnlockedUI.Draw = function(self)
    if not self.visible then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    self.root_node:Draw()
end

return MaskUnlockedUI

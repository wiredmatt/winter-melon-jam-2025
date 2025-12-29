local BattleSceneConfig = require("src.scenes.Battle.config")
local CHARACTERS        = require("data.characters")
local MASKS             = require("data.masks")
local SoundPoolPicker   = require("lib.SoundPoolPicker")

---@class BattleUIConfig
---@field battle_config BattleConfig
---@field font love.Font
---@field screen_width number
---@field screen_height number
---@field player_hp number
---@field player_max_hp number
---@field enemy_hp number
---@field enemy_max_hp number
---@field on_action_selected function? Callback when action button clicked

---@class BattleUI
---@field root_node Node
---@field player_hp_label Label
---@field enemy_hp_label Label
---@field player_sprite Sprite
---@field enemy_sprite Sprite
---@field battle_config BattleConfig
---@field screen_width number
---@field screen_height number
---@field action_buttons table[] Array of {type: string, button: Button}
---@field selected_button_index number Currently selected button (1-3)
---@field mask_name_label Label Label showing current mask name
---@field skill_cooldown_label Label Label showing skill cooldown status
---@field on_action_selected function? Callback when action button clicked
---@field attack_button Button
---@field skill_button Button
---@field swap_button Button
---@field player_mask_sprite Sprite?
---@field enemy_mask_sprite Sprite?
---@field player_home_center_x number Center X position for player sprite
---@field player_home_center_y number Center Y position for player sprite
---@field enemy_home_center_x number Center X position for enemy sprite
---@field enemy_home_center_y number Center Y position for enemy sprite
local BattleUI = {}
BattleUI.__index = BattleUI


---@param config BattleUIConfig
---@return BattleUI
BattleUI.New = function(config)
    local self = setmetatable({}, BattleUI)

    self.battle_config = config.battle_config
    self.screen_width = config.screen_width
    self.screen_height = config.screen_height
    self.on_action_selected = config.on_action_selected
    self.root_node = UI.Node.New()

    self:_setupUI(config)

    return self
end

---@param config BattleUIConfig
BattleUI._setupUI = function(self, config)
    local screen_w = self.screen_width
    local screen_h = self.screen_height

    if AssetManager.assets.sprites.battle_bg_png then
        self.root_node:AddChild(UI.Sprite.New({
            image = AssetManager.assets.sprites.battle_bg_png,
            x = 0,
            y = 0,
        }))
    end

    local enemy_image = self.battle_config.enemy.sprite_image
    if enemy_image then
        enemy_image:setFilter("nearest")
        local enemy_quad = self.battle_config.enemy.sprite_quad

        local enemy_x = screen_w * BattleSceneConfig.LAYOUT.ENEMY_POS.x
        local enemy_y = screen_h * BattleSceneConfig.LAYOUT.ENEMY_POS.y

        -- Store home center position
        self.enemy_home_center_x = enemy_x
        self.enemy_home_center_y = enemy_y

        local sprite_w, sprite_h
        if enemy_quad then
            local _, _, qw, qh = enemy_quad:getViewport()
            sprite_w, sprite_h = qw, qh
        else
            sprite_w = enemy_image:getWidth()
            sprite_h = enemy_image:getHeight()
        end

        self.enemy_sprite = UI.Sprite.New({
            image = enemy_image,
            quad = enemy_quad,
            x = enemy_x - (sprite_w / 2),
            y = enemy_y - (sprite_h / 2),
        })
        self.root_node:AddChild(self.enemy_sprite)

        if self.battle_config.mask_reward then
            local enemy_mask_pos = self.battle_config.enemy.mask_pos
            self.enemy_mask_sprite = self:CreateMaskSprite(self.battle_config.mask_reward, enemy_mask_pos)
            self.enemy_sprite:AddChild(self.enemy_mask_sprite)
        end
    end

    local player_image = AssetManager.assets.sprites.animals_png
    if player_image then
        player_image:setFilter("nearest")

        local player_x = screen_w * BattleSceneConfig.LAYOUT.PLAYER_POS.x
        local player_y = screen_h * BattleSceneConfig.LAYOUT.PLAYER_POS.y

        -- Store home center position
        self.player_home_center_x = player_x
        self.player_home_center_y = player_y

        local player_quad = love.graphics.newQuad(64, 448, 32, 32, player_image)

        self.player_sprite = UI.Sprite.New({
            image = player_image,
            quad = player_quad,
            x = player_x - (32 / 2),
            y = player_y - (32 / 2),
        })
        self.root_node:AddChild(self.player_sprite)

        local MaskManager = require("src.scenes.Battle.MaskManager")
        local equipped_mask = MaskManager.GetEquippedMask()
        if equipped_mask then
            local mask_pos = CHARACTERS.Player.mask_pos
            if CHARACTERS.Player.other_masks_pos_map and CHARACTERS.Player.other_masks_pos_map[equipped_mask.id] then
                mask_pos = CHARACTERS.Player.other_masks_pos_map[equipped_mask.id]
            end
            self.player_mask_sprite = self:CreateMaskSprite(equipped_mask.id, mask_pos)
            self.player_sprite:AddChild(self.player_mask_sprite)
        end
    end

    self.root_node:AddChild(
        UI.Label.New({
            text = "Battle " .. self.battle_config.id .. ": " .. self.battle_config.enemy.name,
            font = config.font,
            x = screen_w / 2 + BattleSceneConfig.LAYOUT.TITLE_OFFSET.x,
            y = BattleSceneConfig.LAYOUT.TITLE_OFFSET.y,
            color = BattleSceneConfig.COLORS.BATTLE_TITLE
        })
    )

    self.player_hp_label = UI.Label.New({
        text = "HP: " .. config.player_hp .. "/" .. config.player_max_hp,
        font = config.font,
        x = 20,
        y = screen_h + BattleSceneConfig.LAYOUT.HP_LABEL_Y,
        color = BattleSceneConfig.COLORS.PLAYER_HP
    })
    self.root_node:AddChild(self.player_hp_label)

    self.enemy_hp_label = UI.Label.New({
        text = "HP: " .. config.enemy_hp .. "/" .. config.enemy_max_hp,
        font = config.font,
        x = screen_w - 120,
        y = screen_h + BattleSceneConfig.LAYOUT.HP_LABEL_Y,
        color = BattleSceneConfig.COLORS.ENEMY_HP
    })
    self.root_node:AddChild(self.enemy_hp_label)

    self.skill_cooldown_label = UI.Label.New({
        text = "Skill: Ready",
        font = config.font,
        x = self.player_hp_label.x,
        y = self.player_sprite.y+self.player_sprite.height+40,
        color = BattleSceneConfig.COLORS.SKILL_READY
    })
    self.root_node:AddChild(self.skill_cooldown_label)

    local buttons_y = screen_h + BattleSceneConfig.LAYOUT.ACTION_PROMPT_Y
    local button_width = 50
    local button_spacing = 4

    local attack_button = UI.Button.New({
        text = "Attack",
        x = 20,
        y = buttons_y,
        width = button_width,
        height = 14,
        font = config.font,
        focusable = true,
        color = BattleSceneConfig.COLORS.BUTTON_NORMAL,
        border_color = BattleSceneConfig.COLORS.BUTTON_NORMAL_BORDER,
    })
    attack_button.OnClick = function()
        if self.on_action_selected then
            self.on_action_selected("attack")
        end
    end
    self.root_node:AddChild(attack_button)

    local skill_button = UI.Button.New({
        text = "Skill",
        x = 20 + button_width + button_spacing,
        y = buttons_y,
        width = button_width,
        height = 14,
        font = config.font,
        focusable = true,
        color = BattleSceneConfig.COLORS.BUTTON_NORMAL,
        border_color = BattleSceneConfig.COLORS.BUTTON_NORMAL_BORDER,
    })
    skill_button.OnClick = function()
        if self.on_action_selected then
            self.on_action_selected("skill")
        end
    end
    self.root_node:AddChild(skill_button)

    local swap_button = UI.Button.New({
        text = "Swap",
        x = 20 + (button_width + button_spacing) * 2,
        y = buttons_y,
        width = button_width,
        height = 14,
        font = config.font,
        focusable = true,
        color = BattleSceneConfig.COLORS.BUTTON_NORMAL,
        border_color = BattleSceneConfig.COLORS.BUTTON_NORMAL_BORDER,
    })
    swap_button.OnClick = function()
        if self.on_action_selected then
            self.on_action_selected("swap")
        end
    end
    self.root_node:AddChild(swap_button)

    self.attack_button = attack_button
    self.skill_button = skill_button
    self.swap_button = swap_button
end

BattleUI.UpdatePlayerHP = function(self, current, max)
    if self.player_hp_label then
        self.player_hp_label:SetText("HP: " .. current .. "/" .. max)
    end
end

BattleUI.UpdateEnemyHP = function(self, current, max)
    if self.enemy_hp_label then
        self.enemy_hp_label:SetText("HP: " .. current .. "/" .. max)
    end
end

BattleUI.GetPlayerSpritePosition = function(self)
    return self.player_home_center_x, self.player_home_center_y
end

BattleUI.GetEnemySpritePosition = function(self)
    return self.enemy_home_center_x, self.enemy_home_center_y
end

BattleUI.CreateMaskSprite = function(self, mask_id, mask_pos)
    local mask_data = nil
    for _, mask in ipairs(MASKS) do
        if mask.id == mask_id then
            mask_data = mask
            break
        end
    end

    if not mask_data or not mask_data.sprite_image then
        return UI.Sprite.New({x = 0, y = 0, width = 0, height = 0})
    end

    mask_pos = mask_pos or {x = 8, y = -6}

    local mask_sprite = UI.Sprite.New({
        image = mask_data.sprite_image,
        quad = mask_data.sprite_quad,
        x = mask_pos.x,
        y = mask_pos.y,
    })

    return mask_sprite
end

BattleUI.UpdatePlayerMask = function(self, mask_id)
    if self.player_mask_sprite then
        self.player_sprite:RemoveChild(self.player_mask_sprite)
    end

    local mask_pos = CHARACTERS.Player.mask_pos
    if CHARACTERS.Player.other_masks_pos_map and CHARACTERS.Player.other_masks_pos_map[mask_id] then
        mask_pos = CHARACTERS.Player.other_masks_pos_map[mask_id]
    end

    self.player_mask_sprite = self:CreateMaskSprite(mask_id, mask_pos)
    self.player_sprite:AddChild(self.player_mask_sprite)
end

---@param sprite Sprite
---@param center_x number Center X position
---@param center_y number Center Y position
BattleUI.SetSpriteCenter = function(self, sprite, center_x, center_y)
    local sprite_w, sprite_h = sprite.width, sprite.height
    sprite.x = center_x - (sprite_w / 2)
    sprite.y = center_y - (sprite_h / 2)
end

---@param sprite Sprite
---@return number center_x, number center_y
BattleUI.GetSpriteCenter = function(self, sprite)
    return sprite.x + sprite.width / 2, sprite.y + sprite.height / 2
end

BattleUI.ResetPlayerSprite = function(self)
    if self.player_sprite then
        self:SetSpriteCenter(self.player_sprite, self.player_home_center_x, self.player_home_center_y)
        self.player_sprite.r = 0
        self.player_sprite.sx = 1
        self.player_sprite.sy = 1
        self.player_sprite.color[4] = 1
    end
end

BattleUI.ResetEnemySprite = function(self)
    if self.enemy_sprite then
        self:SetSpriteCenter(self.enemy_sprite, self.enemy_home_center_x, self.enemy_home_center_y)
        self.enemy_sprite.r = 0
        self.enemy_sprite.sx = 1
        self.enemy_sprite.sy = 1
        self.enemy_sprite.color[4] = 1
    end
end

BattleUI.UpdateMaskDisplay = function(self, mask_name, skill_ready, cooldown_remaining)
    if self.mask_name_label then
        self.mask_name_label:SetText(mask_name)
    end

    if self.skill_cooldown_label then
        if skill_ready then
            self.skill_cooldown_label:SetText("Skill: Ready")
            self.skill_cooldown_label.color = BattleSceneConfig.COLORS.SKILL_READY
        else
            self.skill_cooldown_label:SetText("Skill: " .. cooldown_remaining .. " turns")
            self.skill_cooldown_label.color = BattleSceneConfig.COLORS.SKILL_COOLDOWN
        end
    end
end

BattleUI.UpdateActionButtons = function(self, is_player_turn, skill_ready)
    if self.attack_button then
        if not is_player_turn then
            self.attack_button.normal_color = BattleSceneConfig.COLORS.BUTTON_DISABLED
        else
            self.attack_button.normal_color = BattleSceneConfig.COLORS.BUTTON_NORMAL
        end
    end

    if self.skill_button then
        if not is_player_turn or not skill_ready then
            self.skill_button.normal_color = BattleSceneConfig.COLORS.BUTTON_DISABLED
        else
            self.skill_button.normal_color = BattleSceneConfig.COLORS.BUTTON_NORMAL
        end
    end

    if self.swap_button then
        if not is_player_turn then
            self.swap_button.normal_color = BattleSceneConfig.COLORS.BUTTON_DISABLED
        else
            self.swap_button.normal_color = BattleSceneConfig.COLORS.BUTTON_NORMAL
        end
    end
end

BattleUI.Update = function(self, dt)
    self.root_node:Update(dt)
end

BattleUI.Draw = function(self)
    self.root_node:Draw()
end

return BattleUI

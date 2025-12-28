local BattleSceneConfig = require("src.scenes.Battle.config")

---@class BattleUIConfig
---@field battle_config BattleConfig
---@field font love.Font
---@field screen_width number
---@field screen_height number
---@field player_hp number
---@field player_max_hp number
---@field enemy_hp number
---@field enemy_max_hp number

---@class BattleUI
---@field root_node Node
---@field player_hp_label Label
---@field enemy_hp_label Label
---@field player_sprite Sprite
---@field enemy_sprite Sprite
---@field battle_config BattleConfig
---@field screen_width number
---@field screen_height number
local BattleUI = {}
BattleUI.__index = BattleUI

---@param config BattleUIConfig
---@return BattleUI
BattleUI.New = function(config)
    local self = setmetatable({}, BattleUI)

    self.battle_config = config.battle_config
    self.screen_width = config.screen_width
    self.screen_height = config.screen_height

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
    end

    local player_image = AssetManager.assets.sprites.animals_png
    if player_image then
        player_image:setFilter("nearest")

        local player_x = screen_w * BattleSceneConfig.LAYOUT.PLAYER_POS.x
        local player_y = screen_h * BattleSceneConfig.LAYOUT.PLAYER_POS.y
        local player_quad = love.graphics.newQuad(64, 448, 32, 32, player_image)

        self.player_sprite = UI.Sprite.New({
            image = player_image,
            quad = player_quad,
            x = player_x - (32 / 2),
            y = player_y - (32 / 2),
        })
        self.root_node:AddChild(self.player_sprite)
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

    -- action prompt... todo: replace with a proper attack button, also defend, skill and swap mask
    self.root_node:AddChild(
        UI.Label.New({
            text = "[SPACE] Attack",
            font = config.font,
            x = 20,
            y = screen_h + BattleSceneConfig.LAYOUT.ACTION_PROMPT_Y,
            color = BattleSceneConfig.COLORS.ACTION_PROMPT
        })
    )
end

---@param current number
---@param max number
BattleUI.UpdatePlayerHP = function(self, current, max)
    if self.player_hp_label then
        self.player_hp_label:SetText("HP: " .. current .. "/" .. max)
    end
end

---@param current number
---@param max number
BattleUI.UpdateEnemyHP = function(self, current, max)
    if self.enemy_hp_label then
        self.enemy_hp_label:SetText("HP: " .. current .. "/" .. max)
    end
end

--- for death animation
BattleUI.HideEnemySprite = function(self)
    if self.enemy_sprite then
        self.enemy_sprite.x = -1000
        self.enemy_sprite.y = -1000
    end
end

---@return number x, number y
BattleUI.GetPlayerSpritePosition = function(self)
    local x = self.screen_width * BattleSceneConfig.LAYOUT.PLAYER_POS.x
    local y = self.screen_height * BattleSceneConfig.LAYOUT.PLAYER_POS.y
    return x, y
end

---@return number x, number y
BattleUI.GetEnemySpritePosition = function(self)
    local x = self.screen_width * BattleSceneConfig.LAYOUT.ENEMY_POS.x
    local y = self.screen_height * BattleSceneConfig.LAYOUT.ENEMY_POS.y
    return x, y
end

---@return table {image, quad, x, y, sprite_w, sprite_h}
BattleUI.GetEnemySpriteData = function(self)
    local enemy_x = self.screen_width * BattleSceneConfig.LAYOUT.ENEMY_POS.x
    local enemy_y = self.screen_height * BattleSceneConfig.LAYOUT.ENEMY_POS.y

    local sprite_w, sprite_h
    if self.battle_config.enemy.sprite_quad then
        local _, _, qw, qh = self.battle_config.enemy.sprite_quad:getViewport()
        sprite_w, sprite_h = qw, qh
    else
        sprite_w = self.battle_config.enemy.sprite_image:getWidth()
        sprite_h = self.battle_config.enemy.sprite_image:getHeight()
    end

    return {
        image = self.battle_config.enemy.sprite_image,
        quad = self.battle_config.enemy.sprite_quad,
        x = enemy_x,
        y = enemy_y,
        sprite_w = sprite_w,
        sprite_h = sprite_h,
    }
end

---@return table {image, quad, x, y, sprite_w, sprite_h}
BattleUI.GetPlayerSpriteData = function(self)
    local player_x = self.screen_width * BattleSceneConfig.LAYOUT.PLAYER_POS.x
    local player_y = self.screen_height * BattleSceneConfig.LAYOUT.PLAYER_POS.y

    local player_image = AssetManager.assets.sprites.animals_png
    local player_quad = love.graphics.newQuad(64, 448, 32, 32, player_image)

    return {
        image = player_image,
        quad = player_quad,
        x = player_x,
        y = player_y,
        sprite_w = 32,
        sprite_h = 32,
    }
end

---Hide player sprite (for attack animation)
BattleUI.HidePlayerSprite = function(self)
    if self.player_sprite then
        self.player_sprite.x = -1000
        self.player_sprite.y = -1000
    end
end

---Show player sprite at original position
BattleUI.ShowPlayerSprite = function(self)
    if self.player_sprite then
        local player_x = self.screen_width * BattleSceneConfig.LAYOUT.PLAYER_POS.x
        local player_y = self.screen_height * BattleSceneConfig.LAYOUT.PLAYER_POS.y
        self.player_sprite.x = player_x - 16
        self.player_sprite.y = player_y - 16
    end
end

---Show enemy sprite at original position
BattleUI.ShowEnemySprite = function(self)
    if self.enemy_sprite then
        local enemy_x = self.screen_width * BattleSceneConfig.LAYOUT.ENEMY_POS.x
        local enemy_y = self.screen_height * BattleSceneConfig.LAYOUT.ENEMY_POS.y

        local sprite_w, sprite_h
        if self.battle_config.enemy.sprite_quad then
            local _, _, qw, qh = self.battle_config.enemy.sprite_quad:getViewport()
            sprite_w, sprite_h = qw, qh
        else
            sprite_w = self.battle_config.enemy.sprite_image:getWidth()
            sprite_h = self.battle_config.enemy.sprite_image:getHeight()
        end

        self.enemy_sprite.x = enemy_x - (sprite_w / 2)
        self.enemy_sprite.y = enemy_y - (sprite_h / 2)
    end
end

BattleUI.Draw = function(self)
    self.root_node:Draw()
end

return BattleUI

local BattleManager = require("src.scenes.Battle.BattleManager")
local BattleSceneConfig = require("src.scenes.Battle.config")
local Combat = require("src.scenes.Battle.Combat")
local DialogueUI = require("src.scenes.Battle.DialogueUI")
local BattleUI = require("src.scenes.Battle.BattleUI")
local DeathAnimation = require("src.scenes.Battle.DeathAnimation")
local AttackAnimation = require("src.scenes.Battle.AttackAnimation")
local IntroAnimation = require("src.scenes.Battle.IntroAnimation")
local FloatingText = require("src.scenes.Battle.FloatingText")
local ScreenShake = require("src.scenes.Battle.ScreenShake")
local MaskSwapUI = require("src.scenes.Battle.MaskSwapUI")
local MaskUnlockedUI = require("src.scenes.Battle.MaskUnlockedUI")
local MaskManager = require("src.scenes.Battle.MaskManager")
local MASKS = require("data.masks")

---@class BattleScene : Scene
---@field state string current battle state
---@field battle_config BattleConfig current battle config
---@field dialogue_index number Current dialogue line index
---@field waiting_for_input boolean
---@field combat Combat
---@field dialogue_ui DialogueUI
---@field battle_ui BattleUI
---@field death_anim DeathAnimation
---@field player_attack_anim AttackAnimation
---@field enemy_attack_anim AttackAnimation
---@field player_intro_anim IntroAnimation
---@field enemy_intro_anim IntroAnimation
---@field floating_text FloatingText
---@field screen_shake ScreenShake
---@field mask_swap_ui MaskSwapUI
---@field mask_unlocked_ui MaskUnlockedUI
---@field swap_menu_open boolean
---@field pending_enemy_attack boolean
---@field player_using_skill boolean
---@field transitioning boolean
local BattleScene = {
    name = "Battle",
    transition_in = SceneManager.Transitions.FadeIn.New(),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = require("src.scenes.Battle.inputmap"),
    initialized = false,
    transitioning = false
}

-- Battle states
local STATE = {
    OPENING_DIALOGUE = "opening_dialogue",
    BATTLE = "battle",
    CLOSING_DIALOGUE = "closing_dialogue",
    MASK_UNLOCKED = "mask_unlocked",
    COMPLETE = "complete",
}

BattleScene.Enter = function (self)
    if not self.initialized then
        InputManager.DefineMap(self.name)
        InputManager.LoadBindings(self.name, self.inputmap.bindings)
        InputManager.SetActiveMap(self.name)
        MaskManager.Init()
        self.initialized = true
    end

    self.root_node = UI.Node.New()

    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")
    local tiny5_8px_font = AssetManager.assets.fonts.Tiny5_ttf[8]
    tiny5_8px_font:setFilter("nearest", "nearest")

    self.battle_config = BattleManager.GetCurrentBattle()
    if not self.battle_config then error("No battle config found") end

    MaskManager.ResetCooldowns()

    self.state = STATE.OPENING_DIALOGUE
    self.dialogue_index = 1
    self.waiting_for_input = false

    local screen_w = CONFIG.virtual_cfg.width
    local screen_h = CONFIG.virtual_cfg.height

    self.dialogue_ui = DialogueUI.New({
        font = tiny5_16px_font,
        screen_width = screen_w,
        screen_height = screen_h,
        on_dialogue_complete = function()
            self.waiting_for_input = true
        end
    })

    self.floating_text = FloatingText.New(tiny5_16px_font)
    self.screen_shake = ScreenShake.New()
    self.death_anim = DeathAnimation.New()
    self.player_attack_anim = AttackAnimation.New()
    self.enemy_attack_anim = AttackAnimation.New()
    self.player_intro_anim = IntroAnimation.New()
    self.enemy_intro_anim = IntroAnimation.New()
    self.pending_enemy_attack = false
    self.player_using_skill = false
    self.transitioning = false

    self.mask_swap_ui = MaskSwapUI.New({
        screen_width = screen_w,
        screen_height = screen_h,
        title_font = tiny5_16px_font,
        body_font = tiny5_8px_font,
        inputmap = self.inputmap,
        on_mask_selected = function(mask_id)
            self:OnMaskSwapped(mask_id)
        end,
        on_close = function()
            self.swap_menu_open = false
            self.root_node:RemoveChild(self.mask_swap_ui.root_node)

            if self.battle_ui and self.battle_ui.root_node then
                self.battle_ui.root_node.enabled = true
                local focusables = self.battle_ui.root_node:GetFocusableDescendants()
                if #focusables > 0 then
                    self.battle_ui.root_node:SetFocused(focusables[1])
                end
            end
        end
    })
    self.swap_menu_open = false

    self.mask_unlocked_ui = MaskUnlockedUI.New({
        screen_width = screen_w,
        screen_height = screen_h,
        title_font = tiny5_16px_font,
        body_font = tiny5_8px_font,
        small_font = tiny5_8px_font,
        inputmap = self.inputmap,
        on_continue = function()
            self:OnMaskUnlockedContinue()
        end
    })

    -- setup combat with callbacks
    self.combat = Combat.New({
        enemy_max_hp = self.battle_config.enemy.max_hp,
        enemy_attack_power = self.battle_config.enemy.attack_power,
        bark_lines = self.battle_config.bark_lines,

        on_player_damage = function(damage, remaining_hp)
            local x, y = self.battle_ui:GetPlayerSpritePosition()
            self.floating_text:Spawn("-" .. damage, x, y, BattleSceneConfig.FLOATING_TEXT.DAMAGE_COLOR)
            self.battle_ui:UpdatePlayerHP(remaining_hp, self.combat:GetPlayerMaxHP())
        end,

        on_enemy_damage = function(damage, remaining_hp)
            local x, y = self.battle_ui:GetEnemySpritePosition()
            self.floating_text:Spawn("-" .. damage, x, y, BattleSceneConfig.FLOATING_TEXT.DAMAGE_COLOR)
            self.battle_ui:UpdateEnemyHP(remaining_hp, self.combat:GetEnemyMaxHP())
        end,

        on_enemy_defeat = function()
            local death_config = self.battle_config.enemy.death_animation or "spin_fall"

            self.death_anim:Start(self.battle_ui.enemy_sprite, death_config)
            self.screen_shake:Start(
                BattleSceneConfig.SCREEN_SHAKE.DEATH_DURATION,
                BattleSceneConfig.SCREEN_SHAKE.DEATH_INTENSITY
            )

            -- collect enemy's mask
            local mask_reward = self.battle_config.mask_reward
            if mask_reward and not MaskManager.HasMask(mask_reward) then
                MaskManager.CollectMask(mask_reward)
            end
        end,

        on_enemy_bark = function(text)
            local x = CONFIG.virtual_cfg.width * BattleSceneConfig.LAYOUT.ENEMY_POS.x
            local y = CONFIG.virtual_cfg.height * BattleSceneConfig.LAYOUT.ENEMY_BARK_Y_OFFSET
            self.floating_text:Spawn(text, x, y, BattleSceneConfig.FLOATING_TEXT.BARK_COLOR)
        end,

        on_player_defeat = function()
            -- defeat handled by combat timer
            -- could be used for something else anyway so leaving it
        end,

        on_skill_used = function(skill_name)
            -- visual feedback for skill usage
            local x = CONFIG.virtual_cfg.width * BattleSceneConfig.LAYOUT.PLAYER_POS.x
            local y = CONFIG.virtual_cfg.height * BattleSceneConfig.LAYOUT.ENEMY_BARK_Y_OFFSET
            self.floating_text:Spawn(skill_name .. "!", x, y, BattleSceneConfig.FLOATING_TEXT.BARK_COLOR)
        end,

        on_passive_triggered = function(passive_name, amount)
            -- visual feedback for passive effects
            if passive_name == "Thorns" or passive_name == "Lifesteal" then
                local x = CONFIG.virtual_cfg.width * BattleSceneConfig.LAYOUT.PLAYER_POS.x
                local y = CONFIG.virtual_cfg.height * BattleSceneConfig.LAYOUT.ENEMY_BARK_Y_OFFSET
                local text = passive_name .. " " .. amount
                self.floating_text:Spawn(text, x, y, BattleSceneConfig.FLOATING_TEXT.BARK_COLOR)
            end
        end,
    })

    self.dialogue_ui:ShowDialogue(self.battle_config.opening_dialogue[1])
end

BattleScene.AdvanceDialogue = function (self)
    if self.transitioning then return end

    local dialogues = self.state == STATE.OPENING_DIALOGUE
        and self.battle_config.opening_dialogue
        or self.battle_config.closing_dialogue

    self.dialogue_index = self.dialogue_index + 1

    if self.dialogue_index > #dialogues then
        if self.state == STATE.OPENING_DIALOGUE then
            self.state = STATE.BATTLE
            self:SetupBattleUI()
        elseif self.state == STATE.CLOSING_DIALOGUE then
            if self.battle_config.mask_reward then
                self.state = STATE.MASK_UNLOCKED
                local unlocked_mask = nil
                for _, mask in ipairs(MASKS) do
                    if mask.id == self.battle_config.mask_reward then
                        unlocked_mask = mask
                        break
                    end
                end
                if unlocked_mask then
                    self.mask_unlocked_ui:Show(unlocked_mask)
                end
            else
                -- no mask reward, transition directly
                self:OnMaskUnlockedContinue()
            end
        end
    else
        self.dialogue_ui:ShowDialogue(dialogues[self.dialogue_index])
        self.waiting_for_input = false
    end
end

BattleScene.SetupBattleUI = function (self)
    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    local player_hp, player_max_hp = self.combat:GetPlayerHP()
    local enemy_hp, enemy_max_hp = self.combat:GetEnemyHP()

    self.battle_ui = BattleUI.New({
        battle_config = self.battle_config,
        font = tiny5_16px_font,
        screen_width = CONFIG.virtual_cfg.width,
        screen_height = CONFIG.virtual_cfg.height,
        player_hp = player_hp,
        player_max_hp = player_max_hp,
        enemy_hp = enemy_hp,
        enemy_max_hp = enemy_max_hp,
        on_action_selected = function(action)
            self:OnActionButtonClicked(action)
        end,
    })

    self.root_node:AddChild(self.battle_ui.root_node)

    local player_intro_config = self.battle_config.player_intro_animation or "slide_in"
    self.player_intro_anim:Start(
        self.battle_ui.player_sprite,
        self.battle_ui.player_home_center_x,
        self.battle_ui.player_home_center_y,
        player_intro_config
    )

    local enemy_intro_config = self.battle_config.enemy.intro_animation or "slide_in_right"
    self.enemy_intro_anim:Start(
        self.battle_ui.enemy_sprite,
        self.battle_ui.enemy_home_center_x,
        self.battle_ui.enemy_home_center_y,
        enemy_intro_config
    )
end

BattleScene.TriggerPlayerAttack = function (self)
    local target_x, target_y = self.battle_ui:GetEnemySpritePosition()
    local player_anim_config = self.battle_config.player_attack_animation or "straight"

    self.player_attack_anim:Start(
        self.battle_ui.player_sprite,
        target_x,
        target_y,
        player_anim_config
    )
end

BattleScene.TriggerEnemyAttack = function (self)
    local target_x, target_y = self.battle_ui:GetPlayerSpritePosition()
    local enemy_anim_config = self.battle_config.enemy.attack_animation or "straight"

    self.enemy_attack_anim:Start(
        self.battle_ui.enemy_sprite,
        target_x,
        target_y,
        enemy_anim_config
    )
end

BattleScene.TriggerPlayerSkill = function (self)
    local target_x, target_y = self.battle_ui:GetEnemySpritePosition()
    local player_anim_config = self.battle_config.player_attack_animation or "straight"

    self.player_attack_anim:Start(
        self.battle_ui.player_sprite,
        target_x,
        target_y,
        player_anim_config
    )
    self.player_using_skill = true
end

BattleScene.OpenMaskSwapMenu = function (self)
    local collected_masks = MaskManager.GetCollectedMasks()
    local equipped_mask = MaskManager.GetEquippedMask(); if equipped_mask == nil then error() end

    self.mask_swap_ui:Show(collected_masks, equipped_mask.id)
    self.swap_menu_open = true

    if self.battle_ui and self.battle_ui.root_node then
        self.battle_ui.root_node.enabled = false
        self.battle_ui.root_node:ClearFocus()
    end

    self.root_node:AddChild(self.mask_swap_ui.root_node)
end

BattleScene.OnMaskSwapped = function (self, mask_id)
    MaskManager.EquipMask(mask_id)

    local mask = MaskManager.GetEquippedMask(); if mask == nil then error() end
    local skill_ready = MaskManager.IsSkillReady(mask.active.name)
    local cooldown = MaskManager.skill_cooldowns[mask.active.name] or 0
    self.battle_ui:UpdateMaskDisplay(mask.name, skill_ready, cooldown)
    self.battle_ui:UpdatePlayerMask(mask_id)
end

BattleScene.OnMaskUnlockedContinue = function (self)
    self.transitioning = true
    if BattleManager.HasNextBattle() then
        BattleManager.NextBattle()
        SceneManager.SwitchTo(Scenes.Battle)
    else
        SceneManager.SwitchTo(Scenes.WinFight)
    end
end

BattleScene.OnActionButtonClicked = function (self, action)
    if action == "attack" and self.combat:IsPlayerTurn() and not self.swap_menu_open then
        self:TriggerPlayerAttack()
    elseif action == "skill" and self.combat:IsPlayerTurn() and not self.swap_menu_open then
        local mask = MaskManager.GetEquippedMask()
        if mask and MaskManager.IsSkillReady(mask.active.name) then
            self:TriggerPlayerSkill()
        end
    elseif action == "swap" and not self.swap_menu_open then
        self:OpenMaskSwapMenu()
    end
end

BattleScene.HandleInput = function (self)
    if self.state == STATE.OPENING_DIALOGUE or self.state == STATE.CLOSING_DIALOGUE then
        if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
            if self.dialogue_ui:IsWaitingForInput() then
                self:AdvanceDialogue()
            else
                self.dialogue_ui:Skip()
            end
        end
    elseif self.state == STATE.MASK_UNLOCKED then
        self.mask_unlocked_ui:HandleInput()
    elseif self.state == STATE.BATTLE then
        if self.swap_menu_open then
            self.mask_swap_ui:HandleInput()
            return
        end

        if self.player_intro_anim:IsActive() or self.enemy_intro_anim:IsActive() or
           self.combat:IsDefeated() or self.death_anim:IsActive() or
           self.player_attack_anim:IsActive() or self.enemy_attack_anim:IsActive() then
            return
        end

        local dx, dy = 0, 0
        local has_input = false

        if InputManager.JustPressed(self.inputmap.actions.NAVIGATE_LEFT) then
            dx = -1
            has_input = true
        elseif InputManager.JustPressed(self.inputmap.actions.NAVIGATE_RIGHT) then
            dx = 1
            has_input = true
        end

        if has_input then
            self.battle_ui.root_node:FocusDirection(dx, dy)
        end

        if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
            self.battle_ui.root_node:ActivateFocused()
        end
    end
end

BattleScene.Update = function (self, dt)
    self:HandleInput()

    if self.state == STATE.OPENING_DIALOGUE or self.state == STATE.CLOSING_DIALOGUE then
        self.dialogue_ui:Update(dt)
        return
    end

    if self.state == STATE.MASK_UNLOCKED then
        self.mask_unlocked_ui:Update(dt)
        return
    end

    if self.state == STATE.BATTLE then
        self.root_node:Update(dt)
        if self.player_intro_anim:IsActive() then
            self.player_intro_anim:Update(dt)
            if not self.player_intro_anim:IsActive() then
                self.battle_ui:ResetPlayerSprite()
            end
        end

        if self.enemy_intro_anim:IsActive() then
            self.enemy_intro_anim:Update(dt)
            if not self.enemy_intro_anim:IsActive() then
                self.battle_ui:ResetEnemySprite()
            end
        end

        if self.player_attack_anim:IsActive() then
            self.player_attack_anim:Update(dt)
            if not self.player_attack_anim:IsActive() then
                self.battle_ui:ResetPlayerSprite()
                if self.player_using_skill then
                    self.combat:PlayerExecuteSkill()
                    self.player_using_skill = false
                else
                    self.combat:PlayerAttack()
                end
            end
        end

        if self.enemy_attack_anim:IsActive() then
            self.enemy_attack_anim:Update(dt)
            if not self.enemy_attack_anim:IsActive() then
                self.battle_ui:ResetEnemySprite()
                self.combat:EnemyAttack()
                self.pending_enemy_attack = false
            end
        end

        if self.combat.defeat_timer > 0 then
            self.combat.defeat_timer = self.combat.defeat_timer - dt
        end

        if not self.player_intro_anim:IsActive() and not self.enemy_intro_anim:IsActive() and
           not self.player_attack_anim:IsActive() and not self.enemy_attack_anim:IsActive() then
            if self.combat.current_turn == "enemy" and self.combat.player_hp > 0 and self.combat.enemy_hp > 0 then
                self.combat.bark_timer = self.combat.bark_timer - dt
                if self.combat.bark_timer <= 0 and not self.pending_enemy_attack then
                    self:TriggerEnemyAttack()
                    self.pending_enemy_attack = true
                end
            end
        end

        if self.combat:ShouldTransitionToLose() then
            SceneManager.SwitchTo(Scenes.LoseFight)
            return
        end

        if self.death_anim:IsActive() then
            self.death_anim:Update(dt)
            if not self.death_anim:IsActive() then
                self.state = STATE.CLOSING_DIALOGUE
                self.dialogue_index = 1
                self.dialogue_ui:ShowDialogue(self.battle_config.closing_dialogue[1])
                self.waiting_for_input = false
            end
        end

        local mask = MaskManager.GetEquippedMask()
        if mask then
            local skill_ready = MaskManager.IsSkillReady(mask.active.name)
            local cooldown = MaskManager.skill_cooldowns[mask.active.name] or 0
            self.battle_ui:UpdateMaskDisplay(mask.name, skill_ready, cooldown)
            self.battle_ui:UpdateActionButtons(
                self.combat:IsPlayerTurn(),
                skill_ready
            )
        end

        self.screen_shake:Update(dt)
        self.floating_text:Update(dt)
    end
end

BattleScene.Draw = function (self)
    local shake_x, shake_y = 0, 0
    if self.state == STATE.BATTLE then
        shake_x, shake_y = self.screen_shake:GetOffset()
    end

    love.graphics.push()
    love.graphics.translate(shake_x, shake_y)

    if self.state == STATE.OPENING_DIALOGUE or self.state == STATE.CLOSING_DIALOGUE then
        self.dialogue_ui:Draw()
    elseif self.state == STATE.BATTLE then
        self.floating_text:Draw()
    end

    love.graphics.pop()

    if self.state == STATE.BATTLE then
        self.root_node:Draw()
    elseif self.state == STATE.MASK_UNLOCKED then
        self.mask_unlocked_ui:Draw()
    end
end

BattleScene.Exit = function (_)
end

return BattleScene

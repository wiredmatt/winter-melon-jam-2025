local BattleManager = require("src.scenes.Battle.BattleManager")
local BattleSceneConfig = require("src.scenes.Battle.config")
local Combat = require("src.scenes.Battle.Combat")
local DialogueUI = require("src.scenes.Battle.DialogueUI")
local BattleUI = require("src.scenes.Battle.BattleUI")
local DeathAnimation = require("src.scenes.Battle.DeathAnimation")
local AttackAnimation = require("src.scenes.Battle.AttackAnimation")
local FloatingText = require("src.scenes.Battle.FloatingText")
local ScreenShake = require("src.scenes.Battle.ScreenShake")

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
---@field floating_text FloatingText
---@field screen_shake ScreenShake
---@field pending_enemy_attack boolean
---@field transitioning boolean
local BattleScene = {
    name = "Battle",
    transition_in = SceneManager.Transitions.FadeIn.New(),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = require("src.scenes.Battle.inputmap"),
    transitioning = false
}

-- Battle states
local STATE = {
    OPENING_DIALOGUE = "opening_dialogue",
    BATTLE = "battle",
    CLOSING_DIALOGUE = "closing_dialogue",
    COMPLETE = "complete",
}

BattleScene.Enter = function (self)
    InputManager.DefineMap(self.name)
    InputManager.LoadBindings(self.name, self.inputmap.bindings)
    InputManager.SetActiveMap(self.name)

    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")

    self.battle_config = BattleManager.GetCurrentBattle()
    if not self.battle_config then
        print("[BattleScene] ERROR: No battle config found!")
        return
    end

    print("[BattleScene] Starting battle " .. self.battle_config.id .. ": " .. self.battle_config.enemy.name)

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
    self.pending_enemy_attack = false
    self.transitioning = false

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
            local sprite_data = self.battle_ui:GetEnemySpriteData()
            local death_config = self.battle_config.enemy.death_animation or "spin_fall"

            self.death_anim:Start(sprite_data, death_config)
            self.screen_shake:Start(
                BattleSceneConfig.SCREEN_SHAKE.DEATH_DURATION,
                BattleSceneConfig.SCREEN_SHAKE.DEATH_INTENSITY
            )
            self.battle_ui:HideEnemySprite()
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
    })

    self.dialogue_ui:ShowDialogue(self.battle_config.opening_dialogue[1])
end

BattleScene.AdvanceDialogue = function (self)
    -- Prevent advancing dialogue multiple times during scene transition
    if self.transitioning then
        return
    end

    local dialogues = self.state == STATE.OPENING_DIALOGUE
        and self.battle_config.opening_dialogue
        or self.battle_config.closing_dialogue

    self.dialogue_index = self.dialogue_index + 1

    if self.dialogue_index > #dialogues then
        -- dialogue complete, transition to next state
        if self.state == STATE.OPENING_DIALOGUE then
            self.state = STATE.BATTLE
            self:SetupBattleUI()
        elseif self.state == STATE.CLOSING_DIALOGUE then
            -- battle complete, move to next battle or end
            self.transitioning = true  -- Prevent multiple calls
            if BattleManager.HasNextBattle() then
                BattleManager.NextBattle()
                SceneManager.SwitchTo(Scenes.Battle)
            else
                SceneManager.SwitchTo(Scenes.WinFight)
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
    })
end

BattleScene.TriggerPlayerAttack = function (self)
    local player_sprite_data = self.battle_ui:GetPlayerSpriteData()
    local target_x, target_y = self.battle_ui:GetEnemySpritePosition()

    local player_anim_config = self.battle_config.player_attack_animation or "straight"
    self.player_attack_anim:Start(player_sprite_data, target_x, target_y, player_anim_config)
    self.battle_ui:HidePlayerSprite()
end

BattleScene.TriggerEnemyAttack = function (self)
    local enemy_sprite_data = self.battle_ui:GetEnemySpriteData()
    local target_x, target_y = self.battle_ui:GetPlayerSpritePosition()

    local enemy_anim_config = self.battle_config.enemy.attack_animation or "straight"
    self.enemy_attack_anim:Start(enemy_sprite_data, target_x, target_y, enemy_anim_config)
    self.battle_ui:HideEnemySprite()
end

BattleScene.HandleInput = function (self)
    -- handle dialogue states
    if self.state == STATE.OPENING_DIALOGUE or self.state == STATE.CLOSING_DIALOGUE then
        if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
            if self.dialogue_ui:IsWaitingForInput() then
                self:AdvanceDialogue()
            else
                self.dialogue_ui:Skip()
            end
        end
    -- handle battle state
    elseif self.state == STATE.BATTLE then
        -- block input during defeat countdown, death animation, or attack animations
        if self.combat:IsDefeated() or self.death_anim:IsActive() or
           self.player_attack_anim:IsActive() or self.enemy_attack_anim:IsActive() then
            return
        end

        if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
            if self.combat:IsPlayerTurn() then
                self:TriggerPlayerAttack()
            end
        end
    end
end

BattleScene.Update = function (self, dt)
    self:HandleInput()
    if self.state == STATE.OPENING_DIALOGUE or self.state == STATE.CLOSING_DIALOGUE then
        self.dialogue_ui:Update(dt)
        return
    end

    if self.state == STATE.BATTLE then
        -- Update attack animations
        if self.player_attack_anim:IsActive() then
            self.player_attack_anim:Update(dt)
            if not self.player_attack_anim:IsActive() then
                -- Player attack animation complete - deal damage
                self.battle_ui:ShowPlayerSprite()
                self.combat:PlayerAttack()
            end
        end

        if self.enemy_attack_anim:IsActive() then
            self.enemy_attack_anim:Update(dt)
            if not self.enemy_attack_anim:IsActive() then
                -- Enemy attack animation complete - deal damage and show sprite
                self.battle_ui:ShowEnemySprite()
                self.combat:EnemyAttack()
                self.pending_enemy_attack = false
            end
        end

        -- Update defeat timer
        if self.combat.defeat_timer > 0 then
            self.combat.defeat_timer = self.combat.defeat_timer - dt
        end

        -- Update combat timing, but intercept enemy attacks
        if not self.player_attack_anim:IsActive() and not self.enemy_attack_anim:IsActive() then
            -- Only update combat when no animations are playing
            if self.combat.current_turn == "enemy" and self.combat.player_hp > 0 and self.combat.enemy_hp > 0 then
                self.combat.bark_timer = self.combat.bark_timer - dt
                if self.combat.bark_timer <= 0 and not self.pending_enemy_attack then
                    -- Time for enemy to attack - trigger animation instead
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
                -- Death animation completed, transition to closing dialogue
                self.state = STATE.CLOSING_DIALOGUE
                self.dialogue_index = 1
                self.dialogue_ui:ShowDialogue(self.battle_config.closing_dialogue[1])
                self.waiting_for_input = false
            end
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

    -- draw UI for current state
    if self.state == STATE.OPENING_DIALOGUE or self.state == STATE.CLOSING_DIALOGUE then
        self.dialogue_ui:Draw()
    elseif self.state == STATE.BATTLE then
        self.battle_ui:Draw()

        self.player_attack_anim:Draw()
        self.enemy_attack_anim:Draw()

        self.death_anim:Draw()

        self.floating_text:Draw()
    end

    love.graphics.pop()
end

BattleScene.Exit = function (_)
end

return BattleScene

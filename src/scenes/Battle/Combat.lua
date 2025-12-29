local BattleConfig = require("src.scenes.Battle.config")
local SkillSystem = require("src.scenes.Battle.SkillSystem")
local MaskManager = require("src.scenes.Battle.MaskManager")

---@class CombatConfig
---@field player_max_hp number?
---@field player_hp number?
---@field player_attack_power number?
---@field enemy_max_hp number
---@field enemy_attack_power number
---@field enemy_mask Mask? Enemy's equipped mask (for passives/actives)
---@field bark_lines string[]
---@field on_player_damage function?
---@field on_enemy_damage function?
---@field on_player_heal function?
---@field on_enemy_defeat function?
---@field on_player_defeat function?
---@field on_enemy_bark function?
---@field on_skill_used function?
---@field on_passive_triggered function?
---@field on_enemy_skill_used function?

---@class Combat
---@field player_max_hp number
---@field player_hp number
---@field player_attack_power number
---@field enemy_max_hp number
---@field enemy_hp number
---@field enemy_attack_power number
---@field enemy_mask Mask? Enemy's equipped mask
---@field enemy_skill_cooldown number Enemy skill cooldown counter
---@field enemy_skill_used boolean Whether enemy has used their skill
---@field enemy_turn_count number How many turns the enemy has taken
---@field bark_lines string[]
---@field current_turn "player" | "enemy"
---@field bark_timer number
---@field last_bark_index number
---@field defeat_timer number
---@field enemy_turn_skip boolean Whether enemy should skip next turn
---@field player_turn_skip boolean Whether player should skip next turn
---@field player_shield_active boolean Whether player has active shield
---@field on_player_damage function
---@field on_enemy_damage function
---@field on_player_heal function
---@field on_enemy_defeat function
---@field on_player_defeat function
---@field on_enemy_bark function
---@field on_skill_used function?
---@field on_passive_triggered function?
---@field on_enemy_skill_used function?
local Combat = {}
Combat.__index = Combat

---@param config CombatConfig
---@return Combat
Combat.New = function(config)
    local self = setmetatable({}, Combat)

    self.player_max_hp = config.player_max_hp or BattleConfig.COMBAT.PLAYER_MAX_HP
    self.player_hp = config.player_hp or self.player_max_hp
    self.player_attack_power = config.player_attack_power or BattleConfig.COMBAT.PLAYER_ATTACK_POWER

    self.enemy_max_hp = config.enemy_max_hp
    self.enemy_hp = config.enemy_max_hp
    self.enemy_attack_power = config.enemy_attack_power
    self.enemy_mask = config.enemy_mask
    self.enemy_skill_cooldown = 0
    self.enemy_skill_used = false
    self.enemy_turn_count = 0

    self.bark_lines = config.bark_lines or {}
    self.current_turn = "player"
    self.bark_timer = 0
    self.last_bark_index = 0
    self.defeat_timer = 0

    -- skill system state
    self.enemy_turn_skip = false
    self.player_turn_skip = false
    self.player_shield_active = false

    self.on_player_damage = config.on_player_damage or function() end
    self.on_enemy_damage = config.on_enemy_damage or function() end
    self.on_player_heal = config.on_player_heal or function() end
    self.on_enemy_defeat = config.on_enemy_defeat or function() end
    self.on_player_defeat = config.on_player_defeat or function() end
    self.on_enemy_bark = config.on_enemy_bark or function() end
    self.on_skill_used = config.on_skill_used or function() end
    self.on_passive_triggered = config.on_passive_triggered or function() end
    self.on_enemy_skill_used = config.on_enemy_skill_used or function() end

    return self
end

---@return table {damage: number, enemy_defeated: boolean}
Combat.PlayerAttack = function(self)
    if self.current_turn ~= "player" then
        return {damage = 0, enemy_defeated = false}
    end

    -- check if player turn should be skipped
    if self.player_turn_skip then
        self.player_turn_skip = false
        self.current_turn = "enemy"
        self.bark_timer = BattleConfig.TIMING.ENEMY_ATTACK_DELAY
        -- visual feedback for skipped turn
        if self.on_enemy_bark then
            self.on_enemy_bark("...And another one!")
        end
        return {damage = 0, enemy_defeated = false}
    end

    local damage = self.player_attack_power + math.random(-BattleConfig.COMBAT.PLAYER_DAMAGE_VARIANCE, BattleConfig.COMBAT.PLAYER_DAMAGE_VARIANCE)

    -- apply passive damage modifiers
    local mask = MaskManager.GetEquippedMask()
    if mask then
        damage = SkillSystem.ApplyPassiveToDamageDealt(damage, mask)
    end

    self.enemy_hp = math.max(0, self.enemy_hp - damage)

    self.on_enemy_damage(damage, self.enemy_hp)

    -- trigger player passive effects on damage dealt (lifesteal, etc)
    if mask then
        local effects = SkillSystem.TriggerPassiveOnDamageDealt(damage, mask, self)
        if effects and effects.lifesteal_amount then
            self.on_passive_triggered("Lifesteal", effects.lifesteal_amount)
        end
    end

    -- trigger enemy passive effects on damage received (thorns, etc)
    if self.enemy_mask then
        local enemy_effects = SkillSystem.TriggerPassiveOnDamageReceived(damage, self.enemy_mask, self)
        if enemy_effects and enemy_effects.thorns_damage then
            -- enemy thorns damages the player
            self.player_hp = math.max(0, self.player_hp - enemy_effects.thorns_damage)
            self.on_player_damage(enemy_effects.thorns_damage, self.player_hp)
            self.on_passive_triggered("Enemy Thorns", enemy_effects.thorns_damage)
        end
    end

    if self.enemy_hp <= 0 then
        self.on_enemy_defeat()
        return {damage = damage, enemy_defeated = true}
    end

    self.current_turn = "enemy"
    self.bark_timer = BattleConfig.TIMING.ENEMY_ATTACK_DELAY

    return {damage = damage, enemy_defeated = false}
end

---@return table {damage: number, bark_text: string?, player_defeated: boolean, used_skill: boolean?}
Combat.EnemyAttack = function(self)
    -- check if enemy turn should be skipped
    if self.enemy_turn_skip then
        self.enemy_turn_skip = false
        self.current_turn = "player"
        MaskManager.TickCooldowns()
        return {damage = 0, bark_text = "Turn skipped!", player_defeated = false}
    end

    local damage = self.enemy_attack_power + math.random(-BattleConfig.COMBAT.ENEMY_DAMAGE_VARIANCE, BattleConfig.COMBAT.ENEMY_DAMAGE_VARIANCE)

    -- apply enemy passive damage modifiers (berserk, etc)
    if self.enemy_mask then
        damage = SkillSystem.ApplyPassiveToDamageDealt(damage, self.enemy_mask)
    end

    -- check if player has active shield
    if self.player_shield_active then
        self.player_shield_active = false
        self.current_turn = "player"
        MaskManager.TickCooldowns()
        return {damage = 0, bark_text = "Blocked by shield!", player_defeated = false}
    end

    -- apply passive damage reduction
    local mask = MaskManager.GetEquippedMask()
    if mask then
        damage = SkillSystem.ApplyPassiveToDamageReceived(damage, mask)
    end

    self.player_hp = math.max(0, self.player_hp - damage)

    -- random bark line... 40% chance, but always shows the first one
    local bark_text = nil
    local should_bark = self.last_bark_index == 0 or math.random() < BattleConfig.COMBAT.BARK_CHANCE
    if #self.bark_lines > 0 and should_bark then
        self.last_bark_index = (self.last_bark_index % #self.bark_lines) + 1
        bark_text = self.bark_lines[self.last_bark_index]
        self.on_enemy_bark(bark_text)
    end

    self.on_player_damage(damage, self.player_hp)

    -- trigger player passive effects on damage received (thorns, armor, etc)
    if mask then
        local effects = SkillSystem.TriggerPassiveOnDamageReceived(damage, mask, self)
        if effects and effects.thorns_damage then
            self.on_passive_triggered("Thorns", effects.thorns_damage)
        end
    end

    -- trigger enemy passive effects on damage dealt (lifesteal, etc)
    if self.enemy_mask then
        local enemy_effects = SkillSystem.TriggerPassiveOnDamageDealt(damage, self.enemy_mask, self)
        if enemy_effects and enemy_effects.lifesteal_amount then
            -- enemy heals from lifesteal
            self.enemy_hp = math.min(self.enemy_max_hp, self.enemy_hp + enemy_effects.lifesteal_amount)
            local x, y = self.on_enemy_damage and 0 or 0  -- placeholder, will be handled in callback
            if self.on_player_heal then
                -- reuse player heal callback logic but for enemy (visual only)
                self.on_passive_triggered("Enemy Lifesteal", enemy_effects.lifesteal_amount)
            end
        end
    end

    if self.player_hp <= 0 then
        self.defeat_timer = BattleConfig.TIMING.DEFEAT_DELAY
        self.on_player_defeat()
        return {damage = damage, bark_text = bark_text, player_defeated = true}
    end

    self.current_turn = "player"

    -- tick cooldowns at end of turn
    MaskManager.TickCooldowns()

    -- tick enemy skill cooldown
    if self.enemy_skill_cooldown > 0 then
        self.enemy_skill_cooldown = self.enemy_skill_cooldown - 1
    end

    return {damage = damage, bark_text = bark_text, player_defeated = false}
end

--- execute player's active skill instead of normal attack
---@return table {damage: number, heal: number, effects: string[], enemy_defeated: boolean}
Combat.PlayerExecuteSkill = function(self)
    if self.current_turn ~= "player" then
        return {damage = 0, heal = 0, effects = {}, enemy_defeated = false}
    end

    local mask = MaskManager.GetEquippedMask()
    if not mask or not mask.active then
        return {damage = 0, heal = 0, effects = {}, enemy_defeated = false}
    end

    if not MaskManager.IsSkillReady(mask.active.name) then
        return {damage = 0, heal = 0, effects = {"Skill on cooldown!"}, enemy_defeated = false}
    end

    local result = SkillSystem.ExecuteActiveSkill(mask.active, self)

    if result.damage > 0 then
        self.enemy_hp = math.max(0, self.enemy_hp - result.damage)
        self.on_enemy_damage(result.damage, self.enemy_hp)

        -- trigger player passive effects on damage dealt (lifesteal, etc)
        local effects = SkillSystem.TriggerPassiveOnDamageDealt(result.damage, mask, self)
        if effects and effects.lifesteal_amount then
            self.on_passive_triggered("Lifesteal", effects.lifesteal_amount)
        end

        -- trigger enemy passive effects on damage received (thorns, etc)
        if self.enemy_mask then
            local enemy_effects = SkillSystem.TriggerPassiveOnDamageReceived(result.damage, self.enemy_mask, self)
            if enemy_effects and enemy_effects.thorns_damage then
                -- enemy thorns damages the player
                self.player_hp = math.max(0, self.player_hp - enemy_effects.thorns_damage)
                self.on_player_damage(enemy_effects.thorns_damage, self.player_hp)
                self.on_passive_triggered("Enemy Thorns", enemy_effects.thorns_damage)
            end
        end
    end

    -- set skill on cooldown
    MaskManager.UseSkill(mask.active.name, mask.active.cooldown)

    self.on_skill_used(mask.active.name, result.effects)

    local enemy_defeated = false
    if self.enemy_hp <= 0 then
        self.on_enemy_defeat()
        enemy_defeated = true
    else
        self.current_turn = "enemy"
        self.bark_timer = BattleConfig.TIMING.ENEMY_ATTACK_DELAY
    end

    return {
        damage = result.damage,
        heal = result.heal,
        effects = result.effects,
        enemy_defeated = enemy_defeated
    }
end

--- execute enemy's active skill instead of normal attack
---@return table {damage: number, heal: number, bark_text: string?, player_defeated: boolean}
Combat.EnemyExecuteSkill = function(self)
    if not self.enemy_mask or not self.enemy_mask.active then
        -- fallback to normal attack
        return self:EnemyAttack()
    end

    -- check if skill is ready (cooldown)
    if self.enemy_skill_cooldown > 0 then
        return self:EnemyAttack()
    end

    -- execute the skill
    local result = SkillSystem.ExecuteActiveSkill(self.enemy_mask.active, self)

    -- handle turn_skip: when enemy uses it, skip player's turn instead
    if self.enemy_mask.active.effect and self.enemy_mask.active.effect.type == "turn_skip" then
        self.player_turn_skip = true
        self.enemy_turn_skip = false  -- reset in case ExecuteActiveSkill set it
    end

    -- bark the skill name
    local bark_text = self.enemy_mask.active.name .. "!"

    if result.damage > 0 then
        -- apply passive damage reduction from player
        local player_mask = MaskManager.GetEquippedMask()
        local damage = result.damage
        if player_mask then
            damage = SkillSystem.ApplyPassiveToDamageReceived(damage, player_mask)
        end

        -- check if player has active shield
        if self.player_shield_active then
            self.player_shield_active = false
            self.current_turn = "player"
            self.enemy_skill_cooldown = self.enemy_mask.active.cooldown
            self.enemy_skill_used = true
            MaskManager.TickCooldowns()
            return {damage = 0, heal = 0, bark_text = "Blocked by shield!", player_defeated = false}
        end

        self.player_hp = math.max(0, self.player_hp - damage)
        self.on_player_damage(damage, self.player_hp)

        -- trigger player thorns on damage received
        if player_mask then
            local effects = SkillSystem.TriggerPassiveOnDamageReceived(damage, player_mask, self)
            if effects and effects.thorns_damage then
                self.on_passive_triggered("Thorns", effects.thorns_damage)
            end
        end
    end

    -- set skill on cooldown
    self.enemy_skill_cooldown = self.enemy_mask.active.cooldown
    self.enemy_skill_used = true

    self.on_enemy_skill_used(self.enemy_mask.active.name, result.effects)

    if self.player_hp <= 0 then
        self.defeat_timer = BattleConfig.TIMING.DEFEAT_DELAY
        self.on_player_defeat()
        return {damage = result.damage, heal = result.heal, bark_text = bark_text, player_defeated = true}
    end

    self.current_turn = "player"
    MaskManager.TickCooldowns()

    -- also tick enemy cooldown
    if self.enemy_skill_cooldown > 0 then
        self.enemy_skill_cooldown = self.enemy_skill_cooldown - 1
    end

    return {damage = result.damage, heal = result.heal, bark_text = bark_text, player_defeated = false}
end

---@param dt number
Combat.Update = function(self, dt)
    if self.defeat_timer > 0 then
        self.defeat_timer = self.defeat_timer - dt
    end

    if self.current_turn == "enemy" and self.player_hp > 0 and self.enemy_hp > 0 then
        self.bark_timer = self.bark_timer - dt
        if self.bark_timer <= 0 then
            self:EnemyAttack()
        end
    end
end

---@return number current, number max
Combat.GetPlayerHP = function(self)
    return self.player_hp, self.player_max_hp
end

---@return number current, number max
Combat.GetEnemyHP = function(self)
    return self.enemy_hp, self.enemy_max_hp
end

---@return number
Combat.GetPlayerMaxHP = function(self)
    return self.player_max_hp
end

---@return number
Combat.GetEnemyMaxHP = function(self)
    return self.enemy_max_hp
end

---@return boolean
Combat.IsPlayerTurn = function(self)
    return self.current_turn == "player"
end

---@return boolean
Combat.IsDefeated = function(self)
    return self.defeat_timer > 0
end

---@return boolean
Combat.ShouldTransitionToLose = function(self)
    return self.defeat_timer <= 0 and self.defeat_timer > -1 and self.player_hp <= 0
end

return Combat

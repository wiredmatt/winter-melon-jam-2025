local BattleConfig = require("src.scenes.Battle.config")
local SkillSystem = require("src.scenes.Battle.SkillSystem")
local MaskManager = require("src.scenes.Battle.MaskManager")

---@class CombatConfig
---@field player_max_hp number?
---@field player_hp number?
---@field player_attack_power number?
---@field enemy_max_hp number
---@field enemy_attack_power number
---@field bark_lines string[]
---@field on_player_damage function?
---@field on_enemy_damage function?
---@field on_player_heal function?
---@field on_enemy_defeat function?
---@field on_player_defeat function?
---@field on_enemy_bark function?
---@field on_skill_used function?
---@field on_passive_triggered function?

---@class Combat
---@field player_max_hp number
---@field player_hp number
---@field player_attack_power number
---@field enemy_max_hp number
---@field enemy_hp number
---@field enemy_attack_power number
---@field bark_lines string[]
---@field current_turn "player" | "enemy"
---@field bark_timer number
---@field last_bark_index number
---@field defeat_timer number
---@field enemy_turn_skip boolean Whether enemy should skip next turn
---@field player_shield_active boolean Whether player has active shield
---@field on_player_damage function
---@field on_enemy_damage function
---@field on_player_heal function
---@field on_enemy_defeat function
---@field on_player_defeat function
---@field on_enemy_bark function
---@field on_skill_used function?
---@field on_passive_triggered function?
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

    self.bark_lines = config.bark_lines or {}
    self.current_turn = "player"
    self.bark_timer = 0
    self.last_bark_index = 0
    self.defeat_timer = 0

    -- skill system state
    self.enemy_turn_skip = false
    self.player_shield_active = false

    self.on_player_damage = config.on_player_damage or function() end
    self.on_enemy_damage = config.on_enemy_damage or function() end
    self.on_player_heal = config.on_player_heal or function() end
    self.on_enemy_defeat = config.on_enemy_defeat or function() end
    self.on_player_defeat = config.on_player_defeat or function() end
    self.on_enemy_bark = config.on_enemy_bark or function() end
    self.on_skill_used = config.on_skill_used or function() end
    self.on_passive_triggered = config.on_passive_triggered or function() end

    return self
end

---@return table {damage: number, enemy_defeated: boolean}
Combat.PlayerAttack = function(self)
    if self.current_turn ~= "player" then
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

    -- trigger passive effects on damage dealt
    if mask then
        local effects = SkillSystem.TriggerPassiveOnDamageDealt(damage, mask, self)
        if effects and effects.lifesteal_amount then
            self.on_passive_triggered("Lifesteal", effects.lifesteal_amount)
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

---@return table {damage: number, bark_text: string?, player_defeated: boolean}
Combat.EnemyAttack = function(self)
    -- check if enemy turn should be skipped
    if self.enemy_turn_skip then
        self.enemy_turn_skip = false
        self.current_turn = "player"
        MaskManager.TickCooldowns()
        return {damage = 0, bark_text = "Turn skipped!", player_defeated = false}
    end

    local damage = self.enemy_attack_power + math.random(-BattleConfig.COMBAT.ENEMY_DAMAGE_VARIANCE, BattleConfig.COMBAT.ENEMY_DAMAGE_VARIANCE)

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

    -- trigger passive effects on damage received
    if mask then
        local effects = SkillSystem.TriggerPassiveOnDamageReceived(damage, mask, self)
        if effects and effects.thorns_damage then
            self.on_passive_triggered("Thorns", effects.thorns_damage)
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

        -- trigger passive effects on damage dealt (e.g., lifesteal)
        local effects = SkillSystem.TriggerPassiveOnDamageDealt(result.damage, mask, self)
        if effects and effects.lifesteal_amount then
            self.on_passive_triggered("Lifesteal", effects.lifesteal_amount)
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

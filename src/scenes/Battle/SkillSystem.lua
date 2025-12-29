-- SkillSystem: Handles execution of passive and active mask skills

local SkillSystem = {}

--- apply passive skill modifiers to damage received by player
---@param damage number incoming damage
---@param mask Mask player's equipped mask
---@return number modified_damage damage after passive modifiers
SkillSystem.ApplyPassiveToDamageReceived = function(damage, mask)
    if not mask or not mask.passive then
        return damage
    end

    local passive_type = mask.passive.type

    -- armor: reduce incoming damage
    if passive_type == "armor" then
        local reduction = mask.passive.value or 0.2
        return math.floor(damage * (1 - reduction))
    end

    -- berserk: take more damage
    if passive_type == "berserk" then
        local increase = 0.25  -- Take 25% more damage
        return math.floor(damage * (1 + increase))
    end

    return damage
end

--- apply passive skill modifiers to damage dealt by player
---@param damage number outgoing damage
---@param mask Mask player's equipped mask
---@return number modified_damage damage after passive modifiers
SkillSystem.ApplyPassiveToDamageDealt = function(damage, mask)
    if not mask or not mask.passive then
        return damage
    end

    local passive_type = mask.passive.type

    -- berserk: deal more damage
    if passive_type == "berserk" then
        local increase = mask.passive.value or 0.5
        return math.floor(damage * (1 + increase))
    end

    return damage
end

--- trigger passive skill side effects when player receives damage
---@param damage number damage received (after armor reduction)
---@param mask Mask player's equipped mask
---@param combat table combat instance
---@return table? effects {thorns_damage: number?}
SkillSystem.TriggerPassiveOnDamageReceived = function(damage, mask, combat)
    if not mask or not mask.passive then
        return nil
    end

    local passive_type = mask.passive.type
    local effects = {}

    -- thorns: return damage to attacker
    if passive_type == "thorns" then
        local return_percent = mask.passive.value or 0.3
        local thorns_damage = math.floor(damage * return_percent)
        effects.thorns_damage = thorns_damage

        -- Note: damage application is handled by the caller (Combat.lua)
        -- to ensure correct target and visual feedback

        print("[SkillSystem] Thorns: dealt " .. thorns_damage .. " damage back")
    end

    return effects
end

--- trigger passive skill side effects when player deals damage
---@param damage number damage dealt
---@param mask Mask player's equipped mask
---@param combat table combat instance
---@return table? effects {lifesteal_amount: number?}
SkillSystem.TriggerPassiveOnDamageDealt = function(damage, mask, combat)
    if not mask or not mask.passive then
        return nil
    end

    local passive_type = mask.passive.type
    local effects = {}

    -- lifesteal: heal for percent of damage dealt
    if passive_type == "lifesteal" then
        local heal_percent = mask.passive.value or 0.25
        local heal_amount = math.floor(damage * heal_percent)
        effects.lifesteal_amount = heal_amount

        -- apply healing to player
        combat.player_hp = math.min(combat.player_max_hp, combat.player_hp + heal_amount)

        -- notify UI of healing
        if combat.on_player_heal then
            combat.on_player_heal(heal_amount, combat.player_hp)
        end

        print("[SkillSystem] Lifesteal: healed for " .. heal_amount .. " HP")
    end

    return effects
end

---@param skill MaskActive active skill data
---@param combat table combat instance
---@return table result {damage: number?, heal: number?, effects: string[]}
SkillSystem.ExecuteActiveSkill = function(skill, combat)
    local effect = skill.effect
    local result = {
        damage = 0,
        heal = 0,
        effects = {}
    }

    if not effect then
        return result
    end

    local effect_type = effect.type

    if effect_type == "damage_multiplier" then
        local multiplier = effect.value or 1.5
        local base_damage = combat.player_attack_power
        local variance = 2 -- fixme!!!
        local damage = math.floor((base_damage + math.random(-variance, variance)) * multiplier)

        result.damage = damage
        table.insert(result.effects, "Dealt " .. damage .. " damage!")
    elseif effect_type == "turn_skip" then
        local base_damage = combat.player_attack_power
        local variance = 2
        local damage = base_damage + math.random(-variance, variance)

        result.damage = damage
        combat.enemy_turn_skip = true
        table.insert(result.effects, "Enemy's turn skipped!")
    elseif effect_type == "drain" then
        local base_damage = combat.player_attack_power
        local variance = 2
        local damage = base_damage + math.random(-variance, variance)
        local heal_percent = effect.value or 0.5
        local heal = math.floor(damage * heal_percent)

        result.damage = damage
        result.heal = heal
        combat.player_hp = math.min(combat.player_max_hp, combat.player_hp + heal)

        -- notify UI of healing
        if combat.on_player_heal then
            combat.on_player_heal(heal, combat.player_hp)
        end

        table.insert(result.effects, "Drained " .. heal .. " HP!")
    elseif effect_type == "shield" then
        combat.player_shield_active = true
        table.insert(result.effects, "Shield activated!")
    elseif effect_type == "execute" then
        local base_damage = combat.player_attack_power
        local variance = 2
        local base = base_damage + math.random(-variance, variance)

        -- scale damage based on missing HP
        local missing_hp_percent = (combat.enemy_max_hp - combat.enemy_hp) / combat.enemy_max_hp
        local scale_factor = 1 + (missing_hp_percent * (effect.value or 2.0))
        local damage = math.floor(base * scale_factor)

        result.damage = damage
        table.insert(result.effects, string.format("Execute! %.1fx damage!", scale_factor))
    end

    return result
end

return SkillSystem

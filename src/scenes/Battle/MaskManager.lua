-- MaskManager: Singleton manager for mask collection and equipment
local MASKS = require("data.masks")

---@class MaskManager
local MaskManager = {
    collected_masks = {},
    equipped_mask_id = nil,
    skill_cooldowns = {},  -- skill_name to remaining_turns
}

--- init MaskManager with starter mask
MaskManager.Init = function()
    MaskManager.collected_masks = {"fractured_crown"}
    MaskManager.equipped_mask_id = "fractured_crown"
    MaskManager.skill_cooldowns = {}
end

---@param mask_id string
MaskManager.CollectMask = function(mask_id)
    for _, id in ipairs(MaskManager.collected_masks) do
        if id == mask_id then
            return  -- already have this mask
        end
    end

    table.insert(MaskManager.collected_masks, mask_id)
    print("[MaskManager] Collected mask: " .. mask_id)
end

---@param mask_id string Mask ID to check
---@return boolean
MaskManager.HasMask = function(mask_id)
    for _, id in ipairs(MaskManager.collected_masks) do
        if id == mask_id then
            return true
        end
    end
    return false
end

---@param mask_id string Mask ID to equip
---@return boolean success
MaskManager.EquipMask = function(mask_id)
    MaskManager.equipped_mask_id = mask_id
    print("[MaskManager] Equipped mask: " .. mask_id)
    return true
end

---@return Mask? mask mask data or nil if none equipped
MaskManager.GetEquippedMask = function()
    if not MaskManager.equipped_mask_id then
        return nil
    end

    for _, mask in ipairs(MASKS) do
        if mask.id == MaskManager.equipped_mask_id then
            return mask
        end
    end

    return nil
end

---@return Mask[] masks array of collected mask data
MaskManager.GetCollectedMasks = function()
    local collected = {}

    for _, mask_id in ipairs(MaskManager.collected_masks) do
        for _, mask in ipairs(MASKS) do
            if mask.id == mask_id then
                table.insert(collected, mask)
                break
            end
        end
    end

    return collected
end

MaskManager.TickCooldowns = function()
    for skill_name, cooldown in pairs(MaskManager.skill_cooldowns) do
        if cooldown > 0 then
            MaskManager.skill_cooldowns[skill_name] = cooldown - 1
        end
    end
end

---@param skill_name string Skill name to check
---@return boolean ready True if skill can be used
MaskManager.IsSkillReady = function(skill_name)
    local cooldown = MaskManager.skill_cooldowns[skill_name] or 0
    return cooldown <= 0
end

---@param skill_name string Skill name
---@param cooldown_turns number Number of turns for cooldown
MaskManager.UseSkill = function(skill_name, cooldown_turns)
    MaskManager.skill_cooldowns[skill_name] = cooldown_turns
    print("[MaskManager] Skill '" .. skill_name .. "' used, cooldown: " .. cooldown_turns .. " turns")
end

---reset cooldowns (for new battle)
MaskManager.ResetCooldowns = function()
    MaskManager.skill_cooldowns = {}
    print("[MaskManager] Cooldowns reset")
end

---reset to starter mask only (for new game only!)
MaskManager.Reset = function()
    MaskManager.collected_masks = {"fractured_crown"}
    MaskManager.equipped_mask_id = "fractured_crown"
    MaskManager.skill_cooldowns = {}
    print("[MaskManager] Reset to starter mask")
end

return MaskManager

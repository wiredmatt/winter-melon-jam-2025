local BATTLES = require("data.battles")

---@class BattleManager
---@field current_battle_index number
local BattleManager = {
    current_battle_index = 1,
}

---@return BattleConfig?
BattleManager.GetCurrentBattle = function()
    return BATTLES[BattleManager.current_battle_index]
end

---@return boolean
BattleManager.HasNextBattle = function()
    return BattleManager.current_battle_index < #BATTLES
end

BattleManager.NextBattle = function()
    if BattleManager.HasNextBattle() then
        BattleManager.current_battle_index = BattleManager.current_battle_index + 1
        return true
    end
    return false
end

BattleManager.Reset = function()
    BattleManager.current_battle_index = 1
end

---@return number
BattleManager.GetTotalBattles = function()
    return #BATTLES
end

return BattleManager

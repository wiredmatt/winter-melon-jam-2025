local BattleConfig = require("src.scenes.Battle.config")

---@class DialogueUIConfig
---@field font love.Font
---@field screen_width number
---@field screen_height number
---@field on_dialogue_complete function?

---@class DialogueUI
---@field root_node Node
---@field typewriter Typewriter
---@field continue_prompt Label
---@field waiting_for_input boolean
---@field font love.Font
---@field screen_width number
---@field screen_height number
---@field on_dialogue_complete function
local DialogueUI = {}
DialogueUI.__index = DialogueUI

---@param config DialogueUIConfig
---@return DialogueUI
DialogueUI.New = function(config)
    local self = setmetatable({}, DialogueUI)

    self.font = config.font
    self.screen_width = config.screen_width
    self.screen_height = config.screen_height
    self.waiting_for_input = false
    self.on_dialogue_complete = config.on_dialogue_complete or function() end

    self.root_node = UI.Node.New()
    self.typewriter = nil
    self.continue_prompt = nil

    return self
end

---@param dialogue table {speaker: string, text: string}
DialogueUI.ShowDialogue = function(self, dialogue)
    self.root_node = UI.Node.New()
    self.waiting_for_input = false

    self.root_node:AddChild(
        UI.Label.New({
            text = dialogue.speaker,
            font = self.font,
            x = 40,
            y = self.screen_height - 120,
            color = BattleConfig.COLORS.SPEAKER
        })
    )

    self.typewriter = UI.Typewriter.New({
        full_text = dialogue.text,
        font = self.font,
        x = 40,
        y = self.screen_height - 90,
        width = self.screen_width - 80,
        chars_per_second = BattleConfig.TIMING.TYPEWRITER_SPEED,
        on_complete = function()
            self.waiting_for_input = true
            self.on_dialogue_complete()
        end,
        sfx = AssetManager.assets.sfx and AssetManager.assets.sfx.typewriter_blip_wav or nil,
        sfx_interval = BattleConfig.AUDIO.TYPEWRITER_INTERVAL,
        sfx_pitch_min = BattleConfig.AUDIO.TYPEWRITER_PITCH_MIN,
        sfx_pitch_max = BattleConfig.AUDIO.TYPEWRITER_PITCH_MAX,
    })
    self.root_node:AddChild(self.typewriter)

    local continue_prompt = UI.Label.New({
        text = "[Press SPACE to continue]",
        font = self.font,
        x = 40,
        y = self.screen_height - 40,
        color = BattleConfig.COLORS.CONTINUE_PROMPT
    })
    self.continue_prompt = continue_prompt
    self.root_node:AddChild(continue_prompt)
end

---@return boolean
DialogueUI.CanAdvance = function(self)
    return self.waiting_for_input
end

DialogueUI.Skip = function(self)
    if self.typewriter then
        self.typewriter:Skip()
    end
end

---@return boolean
DialogueUI.IsWaitingForInput = function(self)
    return self.waiting_for_input
end

---@param dt number
DialogueUI.Update = function(self, dt)
    self.root_node:Update(dt)

    if self.waiting_for_input and self.continue_prompt then
        local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * BattleConfig.TIMING.CONTINUE_PROMPT_FLASH_SPEED)
        self.continue_prompt.color[4] = alpha
    elseif self.continue_prompt then
        self.continue_prompt.color[4] = 0
    end
end

DialogueUI.Draw = function(self)
    self.root_node:Draw()
end

return DialogueUI

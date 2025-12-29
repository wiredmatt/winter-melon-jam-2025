-- Mask definitions for the mask collection system
-- Each mask has a passive skill (auto-triggered) and an active skill (player-activated)

---@class MaskPassive
---@field type string Type of passive effect
---@field value number? Numeric value for the passive (e.g., damage %, heal %)

---@class MaskActive
---@field name string Name of the active skill
---@field description string Description of what the skill does
---@field cooldown number Number of turns before skill can be used again
---@field effect table Effect data {type = string, value = number?}

---@class Mask
---@field id string Unique identifier for the mask
---@field name string Display name
---@field description string Flavor text
---@field passive MaskPassive Passive skill data
---@field active MaskActive Active skill data
---@field sprite_image love.Image? Sprite sheet image
---@field sprite_quad love.Quad? Quad within sprite sheet

---@type Mask[]
local MASKS = {
    -- Starter mask - player begins with this
    {
        id = "fractured_crown",
        name = "Fractured Crown",
        description = "Your shattered crown. Once a symbol of absolute rule, now a reminder of betrayal.",
        sprite_image = AssetManager.assets.sprites.fractured_crown_png,
        passive = {
            type = "none"
        },
        active = {
            name = "Focus Strike",
            description = "Deal 1.3x damage",
            cooldown = 2,
            effect = {
                type = "damage_multiplier",
                value = 1.3
            }
        }
    },

    -- Battle 1 reward
    {
        id = "balanced_mask",
        name = "The Balanced Mask",
        description = "The Apostle's mask. His conviction was absolute, even if it was misguided.",
        sprite_image = AssetManager.assets.sprites.balanced_mask_png,
        passive = {
            type = "none"
        },
        active = {
            name = "Power Strike",
            description = "Deal 1.5x damage",
            cooldown = 3,
            effect = {
                type = "damage_multiplier",
                value = 1.5
            }
        }
    },

    -- Battle 2 reward
    {
        id = "opportunist_mask",
        name = "Opportunist Mask",
        description = "The Rogue's mask. A reminder that loyalty means nothing without honor.",
        sprite_image = AssetManager.assets.sprites.opportunist_mask_png,
        passive = {
            type = "thorns",
            value = 0.3
        },
        active = {
            name = "Shadow Strike",
            description = "Deal damage and skip enemy's next turn",
            cooldown = 4,
            effect = {
                type = "turn_skip",
                value = 1.0
            }
        }
    },

    -- Battle 3 reward
    {
        id = "cursed_mask",
        name = "Cursed Mask",
        description = "Consumed by the very power they stole. You freed them from their torment.",
        sprite_image = AssetManager.assets.sprites.cursed_mask_png,
        passive = {
            type = "lifesteal",
            value = 0.25
        },
        active = {
            name = "Drain",
            description = "Deal damage and heal for 50% of it",
            cooldown = 3,
            effect = {
                type = "drain",
                value = 0.5
            }
        }
    },

    -- Battle 4 reward
    {
        id = "guardian_mask",
        name = "Iron Mask",
        description = "They chose duty over friendship. In the end, they saw the truth too late.",
        sprite_image = AssetManager.assets.sprites.iron_mask_png,
        passive = {
            type = "armor",
            value = 0.2
        },
        active = {
            name = "Shield",
            description = "Block the next enemy attack completely",
            cooldown = 5,
            effect = {
                type = "shield",
                value = 1
            }
        }
    },

    -- Battle 5 reward (final boss)
    {
        id = "usurper_mask",
        name = "The Usurper's Mask",
        description = "The mask of your closest friend and greatest betrayer. The crown is yours once more.",
        sprite_image = AssetManager.assets.sprites.usurper_mask_png,
        passive = {
            type = "berserk",
            value = 0.5
        },
        active = {
            name = "Execute",
            description = "Massive damage scaling with missing enemy HP",
            cooldown = 4,
            effect = {
                type = "execute",
                value = 2.0
            }
        }
    },
}

return MASKS

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
        description = "A broken crown from a forgotten ruler. Basic but reliable.",
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
        description = "A mask of balanced power and discipline.",
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
        description = "A shadowy mask that punishes those who dare strike you.",
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
        name = "Cursed One's Mask",
        description = "A mask that feeds on the life force of enemies.",
        sprite_image = AssetManager.assets.sprites.monsters_png,
        sprite_quad = love.graphics.newQuad(0, 144, 16, 16, AssetManager.assets.sprites.monsters_png),
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
        name = "The Guardian's Mask",
        description = "A protective mask that shields its wearer from harm.",
        sprite_image = AssetManager.assets.sprites.rogues_png,
        sprite_quad = love.graphics.newQuad(48, 96, 16, 16, AssetManager.assets.sprites.rogues_png),
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
        description = "A mask of overwhelming power, but at a terrible cost.",
        sprite_image = AssetManager.assets.sprites.rogues_png,
        sprite_quad = love.graphics.newQuad(64, 96, 16, 16, AssetManager.assets.sprites.rogues_png),
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

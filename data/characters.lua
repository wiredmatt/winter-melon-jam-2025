
---@class CharacterData
---@field name string
---@field max_hp number
---@field attack_power number
---@field sprite_image love.Image?
---@field sprite_quad love.Quad?
---@field death_animation string|table? Death animation preset or config
---@field attack_animation string|table? Attack animation preset or config
---@field intro_animation string|table? Intro animation preset or config
---@field mask_pos {x: number, y: number}? Position offset for mask sprite relative to character sprite
---@field other_masks_pos_map table<string, {x: number, y: number}>? Map of mask IDs to positions (player only)

local CHARACTERS = {
    Player = {
        sprite_image = AssetManager.assets.sprites.rogues_png,
        sprite_quad = love.graphics.newQuad(128, 192, 32, 32, AssetManager.assets.sprites.rogues_png),
        mask_pos = { x = 3, y = 2 },  -- default pos, for fractured_crown
        other_masks_pos_map = {
            -- map each other mask to its position on player sprite
            ["balanced_mask"] = { x = 4, y = 2 },
            ["opportunist_mask"] = { x = 4, y = 2 },
            ["cursed_mask"] = { x = 4, y = 2 },
            ["guardian_mask"] = { x = 4, y = 2 },
            ["usurper_mask"] = { x = 3, y = 2 },
        }
    },
    TheApostle = {
        name = "The Apostle",
        max_hp = 30,
        attack_power = 5,
        sprite_image = AssetManager.assets.sprites.rogues_png,
        sprite_quad = love.graphics.newQuad(32, 64, 32, 32, AssetManager.assets.sprites.rogues_png),
        death_animation = "fade",  -- Fades with conviction, righteous to the end
        attack_animation = "straight",  -- Disciplined, precise strikes
        intro_animation = "spin_entry",  -- Ceremonial, formal entrance
        mask_pos = {x = 4, y = 2},
    },
    TheRogue = {
        name = "The Rogue",
        max_hp = 40,
        attack_power = 7,
        sprite_image = AssetManager.assets.sprites.rogues_png,
        sprite_quad = love.graphics.newQuad(96, 0, 32, 32, AssetManager.assets.sprites.rogues_png),
        death_animation = "slide",  -- Slides away into the shadows
        attack_animation = "zigzag",  -- Unpredictable, tricky strikes
        intro_animation = "drop_bounce",  -- Drops in unexpectedly from above
        mask_pos = {x = 8, y = -6},
    },
    TheCursedOne = {
        name = "Cursed One",
        max_hp = 60,
        attack_power = 10,
        sprite_image = AssetManager.assets.sprites.monsters_png,
        sprite_quad = love.graphics.newQuad(64, 128, 32, 32, AssetManager.assets.sprites.monsters_png),
        death_animation = "fade",  -- Dissolves as the curse releases them
        attack_animation = "spin_tackle",  -- Erratic, corrupted movements
        intro_animation = "diagonal_spin",  -- Chaotic, uncontrolled entrance
        mask_pos = {x = 8, y = -6},
    },
    TheGuardian = {
        name = "The Guardian",
        max_hp = 50,
        attack_power = 8,
        sprite_image = AssetManager.assets.sprites.rogues_png,
        sprite_quad = love.graphics.newQuad(128, 32, 32, 32, AssetManager.assets.sprites.rogues_png),
        death_animation = "fade",  -- Dignified, honorable end
        attack_animation = "arc_tackle",  -- Defensive, protective counter-strikes
        intro_animation = "spin_entry",  -- Formal, ceremonial entrance
        mask_pos = {x = 8, y = -6},
    },
    TheUsurper = {
        name = "The Usurper",
        max_hp = 80,
        attack_power = 12,
        sprite_image = AssetManager.assets.sprites.rogues_png,
        sprite_quad = love.graphics.newQuad(160, 64, 32, 32, AssetManager.assets.sprites.rogues_png),
        death_animation = {  -- Dramatic fall from power, the crown taken
            preset = "spin_fall",
            overrides = {
                rotation_speed = math.pi * 10,
                fall_distance = 300,
                duration = 2.5,
            }
        },
        attack_animation = "spin_tackle",  -- Aggressive, overwhelming power
        intro_animation = {  -- Confident, commanding presence
            preset = "pop_in",
            overrides = {
                duration = 1.2,
            }
        },
        mask_pos = {x = 8, y = -4},
    }
}

return CHARACTERS
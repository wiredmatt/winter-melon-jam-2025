-- each battle has: opening dialogue, enemy data, bark lines, and closing dialogue

---@class BattleEnemy
---@field name string
---@field max_hp number
---@field attack_power number
---@field sprite_image love.Image?
---@field sprite_quad love.Quad?
---@field death_animation string|table? Death animation preset or config
---@field attack_animation string|table? Attack animation preset or config

---@class BattleDialogue
---@field text string
---@field speaker string

---@class BattleConfig
---@field id number
---@field opening_dialogue BattleDialogue[]
---@field enemy BattleEnemy
---@field bark_lines string[] short lines enemy says during combat
---@field closing_dialogue BattleDialogue[]
---@field player_attack_animation string|table? Player attack animation preset or config

---@type BattleConfig[]
local BATTLES = {
    -- Battle 1
    {
        id = 1,
        opening_dialogue = {
            { speaker = "The Apostle", text = "You seek the masks?{{pause=500}}\nYou'll have to prove yourself first." },
        },
        enemy = {
            name = "The Apostle",
            max_hp = 30,
            attack_power = 5,
            sprite_image = AssetManager.assets.sprites.rogues_png,
            sprite_quad = love.graphics.newQuad(32, 64, 32, 32, AssetManager.assets.sprites.rogues_png),
            death_animation = "spin_fall",
            attack_animation = "straight",
        },
        player_attack_animation = "dash",
        bark_lines = {
            "Is that all you've got?",
            "Pathetic...",
            "I've seen worse.",
        },
        closing_dialogue = {
            { speaker = "The Apostle", text = "Impressive...{{pause=600}}\nBut this is only the beginning." },
        },
    },
    -- Battle 2
    {
        id = 2,
        opening_dialogue = {
            { speaker = "Shadowy Figure", text = "Another one seeking power?{{pause=400}}\nHow dull." },
        },
        enemy = {
            name = "Shadow Seeker",
            max_hp = 40,
            attack_power = 7,
            sprite_image = AssetManager.assets.sprites.rogues_png,
            sprite_quad = love.graphics.newQuad(32, 64, 32, 32, AssetManager.assets.sprites.rogues_png),
            death_animation = "explode",
            attack_animation = "zigzag",  -- Shadowy, erratic movement
        },
        player_attack_animation = "spin_tackle",
        bark_lines = {
            "You're stronger than you look.",
            "But not strong enough!",
            "Feel the shadows!",
        },
        closing_dialogue = {
            { speaker = "Shadow Seeker", text = "You... you actually did it.{{pause=800}}\nTake what you've earned." },
        },
    },

    -- Battle 3
    {
        id = 3,
        opening_dialogue = {
            { speaker = "Masked One", text = "You've claimed two masks already.{{pause=500}}\nLet's see if you deserve a third." },
        },
        enemy = {
            name = "Mask Guardian",
            max_hp = 50,
            attack_power = 8,
            sprite_image = AssetManager.assets.sprites.rogues_png,
            sprite_quad = love.graphics.newQuad(32, 64, 32, 32, AssetManager.assets.sprites.rogues_png),
            death_animation = "fade",
            attack_animation = "arc_tackle",  -- Graceful, controlled arc
        },
        player_attack_animation = "arc_tackle",
        bark_lines = {
            "The masks test your worth!",
            "Are you truly worthy?",
            "Show me your resolve!",
        },
        closing_dialogue = {
            { speaker = "Mask Guardian", text = "You've proven yourself.{{pause=600}}\nThe third mask is yours." },
        },
    },

    -- Battle 4
    {
        id = 4,
        opening_dialogue = {
            { speaker = "Ancient Voice", text = "Three masks...{{pause=700}}\nBut can you handle the burden of four?" },
        },
        enemy = {
            name = "Ancient One",
            max_hp = 60,
            attack_power = 10,
            sprite_image = AssetManager.assets.sprites.rogues_png,
            sprite_quad = love.graphics.newQuad(32, 64, 32, 32, AssetManager.assets.sprites.rogues_png),
            death_animation = "slide",
            attack_animation = "dash",  -- Ancient and swift
        },
        player_attack_animation = "zigzag",
        bark_lines = {
            "The weight of power crushes the weak!",
            "Do you feel it yet?",
            "Your strength... impressive.",
        },
        closing_dialogue = {
            { speaker = "Ancient One", text = "Four masks...{{pause=500}}\nOne remains.{{pause=800}}\nBut the final trial will test everything." },
        },
    },

    -- Battle 5 - Final Battle
    {
        id = 5,
        opening_dialogue = {
            { speaker = "The Betrayer", text = "So you've made it this far.{{pause=800}}\nI was the one who took them from you.{{pause=600}}\nAnd now...{{pause=400}} you want them back?" },
        },
        enemy = {
            name = "The Betrayer",
            max_hp = 80,
            attack_power = 12,
            sprite_image = AssetManager.assets.sprites.rogues_png,
            sprite_quad = love.graphics.newQuad(32, 64, 32, 32, AssetManager.assets.sprites.rogues_png),
            death_animation = {  -- Epic boss death with overrides
                preset = "spin_fall",
                overrides = {
                    rotation_speed = math.pi * 10,  -- 5 spins!
                    fall_distance = 300,            -- Falls further
                    duration = 2.5,                 -- Longer, more dramatic
                }
            },
            attack_animation = "spin_tackle",  -- Aggressive spinning attack
        },
        player_attack_animation = {  -- Epic final battle player attack
            preset = "dash",
            overrides = {
                duration = 0.5,  -- Slightly longer for dramatic effect
            }
        },
        bark_lines = {
            "I know all your moves!",
            "We were allies once!",
            "This ends today!",
            "You can't win!",
        },
        closing_dialogue = {
            { speaker = "The Betrayer", text = "I... I understand now.{{pause=1000}}\nThe masks chose you for a reason.{{pause=800}}\nTake them... and rule wisely." },
        },
    },
}

return BATTLES

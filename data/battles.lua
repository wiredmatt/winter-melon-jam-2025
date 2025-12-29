local CHARACTERS = require("data.characters")
local MASKS = require("data.masks")

-- each battle has: opening dialogue, enemy data, bark lines, and closing dialogue

---@class BattleDialogue
---@field text string
---@field speaker string

---@class BattleConfig
---@field id number
---@field opening_dialogue BattleDialogue[]
---@field enemy CharacterData
---@field bark_lines string[] short lines enemy says during combat
---@field closing_dialogue BattleDialogue[]
---@field player_attack_animation string|table? Player attack animation preset or config
---@field player_intro_animation string|table? Player intro animation preset or config
---@field mask_reward string? Mask ID rewarded for defeating this enemy

---@type BattleConfig[]
local BATTLES = {
    -- Battle 1
    {
        id = 1,
        opening_dialogue = {
            { speaker = CHARACTERS.TheApostle.name, text = "You seek the masks?{{pause=500}}\nYou'll have to prove yourself first." },
        },
        enemy = CHARACTERS.TheApostle,
        mask_reward = "balanced_mask",
        bark_lines = {
            "Is that all you've got?",
            "Pathetic...",
            "I've seen worse.",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheApostle.name, text = "Impressive...{{pause=600}}\nBut this is only the beginning." },
        },
        player_attack_animation = "dash",
        player_intro_animation = "slide_in",
    },
    -- Battle 2
    {
        id = 2,
        opening_dialogue = {
            { speaker = CHARACTERS.TheRogue.name, text = "Another one seeking power?{{pause=400}}\nHow dull." },
        },
        enemy = CHARACTERS.TheRogue,
        mask_reward = "opportunist_mask",
        bark_lines = {
            "You're stronger than you look.",
            "But not strong enough!",
            "Feel the shadows!",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheRogue.name, text = "You... you actually did it.{{pause=800}}\nTake what you've earned." },
        },
        player_attack_animation = "spin_tackle",
        player_intro_animation = "spin_entry",
    },
    -- Battle 3
    {
        id = 3,
        opening_dialogue = {
            { speaker = CHARACTERS.TheCursedOne.name, text = "You've claimed two masks already.{{pause=500}}\nLet's see if you deserve a third." },
        },
        enemy = CHARACTERS.TheCursedOne,
        player_attack_animation = "zigzag",
        player_intro_animation = "pop_in",
        mask_reward = "cursed_mask",
        bark_lines = {
            "The weight of power crushes the weak!",
            "Do you feel it yet?",
            "Your strength... impressive.",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheCursedOne.name, text = "You've proven yourself.{{pause=600}}\nThe third mask is yours." },
        },
    },
    -- Battle 4
    {
        id = 4,
        opening_dialogue = {
            { speaker = "The Guardian", text = "Three masks...{{pause=700}}\nBut can you handle the burden of four?" },
        },
        enemy = CHARACTERS.TheGuardian,
        mask_reward = "guardian_mask",
        bark_lines = {
            "The masks test your worth!",
            "Are you truly worthy?",
            "Show me your resolve!",
        },
        closing_dialogue = {
            { speaker = "The Guardian", text = "Four masks...{{pause=500}}\nOne remains.{{pause=800}}\nBut the final trial will test everything." },
        },
        player_attack_animation = "arc_tackle",
        player_intro_animation = "drop_bounce",
    },
    -- Battle 5
    {
        id = 5,
        opening_dialogue = {
            { speaker = CHARACTERS.TheUsurper.name, text = "So you've made it this far.{{pause=800}}\nI was the one who took them from you.{{pause=600}}\nAnd now...{{pause=400}} you want them back?" },
        },
        enemy = CHARACTERS.TheUsurper,
        player_attack_animation = {
            preset = "dash",
            overrides = {
                duration = 0.5,
            }
        },
        player_intro_animation = {
            preset = "slide_in",
            overrides = {
                duration = 0.8,
            }
        },
        mask_reward = "usurper_mask",
        bark_lines = {
            "I know all your moves!",
            "We were allies once!",
            "This ends today!",
            "You can't win!",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheUsurper.name, text = "I... I understand now.{{pause=1000}}\nThe masks chose you for a reason.{{pause=800}}\nTake them... and rule wisely." },
        },
    },
}

return BATTLES

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
            { speaker = CHARACTERS.TheApostle.name, text = "You...{{pause=800}} It can't be.{{pause=600}}\nWe watched you fall." },
            { speaker = CHARACTERS.TheApostle.name, text = "Your rule was weak!{{pause=500}}\nWhat we did was necessary.{{pause=400}}\nJustice." },
        },
        enemy = CHARACTERS.TheApostle,
        mask_reward = "balanced_mask",
        bark_lines = {
            "The old order is dead!",
            "We were right to act!",
            "You don't deserve that crown!",
            "Justice will prevail!",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheApostle.name, text = "No...{{pause=600}} this changes nothing.{{pause=800}}\nThe others will stop you." },
        },
        player_attack_animation = "dash",
        player_intro_animation = "slide_in",
    },
    -- Battle 2
    {
        id = 2,
        opening_dialogue = {
            { speaker = CHARACTERS.TheRogue.name, text = "Well, well.{{pause=600}} The ghost returns.{{pause=500}}\nI should've made sure myself." },
            { speaker = CHARACTERS.TheRogue.name, text = "Nothing personal, you understand.{{pause=400}}\nI just backed the winning side.{{pause=600}}\nOr so I thought." },
        },
        enemy = CHARACTERS.TheRogue,
        mask_reward = "opportunist_mask",
        bark_lines = {
            "I've killed you once already!",
            "Loyalty? That was business.",
            "You were always too trusting!",
            "Should've stayed dead!",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheRogue.name, text = "Heh...{{pause=600}} should've known.{{pause=800}}\nYou always were... the better blade..." },
        },
        player_attack_animation = "spin_tackle",
        player_intro_animation = "spin_entry",
    },
    -- Battle 3
    {
        id = 3,
        opening_dialogue = {
            { speaker = CHARACTERS.TheCursedOne.name, text = "You...{{pause=1000}} I thought I'd feel victorious when this day came.{{pause=800}}\nBut the masks...{{pause=600}} they hunger." },
            { speaker = CHARACTERS.TheCursedOne.name, text = "We took your power, but it consumed us!{{pause=700}}\nI can't... stop... MAKE IT STOP!" },
        },
        enemy = CHARACTERS.TheCursedOne,
        player_attack_animation = "zigzag",
        player_intro_animation = "pop_in",
        mask_reward = "cursed_mask",
        bark_lines = {
            "The masks whisper... they scream!",
            "I can't control it anymore!",
            "This power... it burns!",
            "Help me... no, FIGHT ME!",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheCursedOne.name, text = "Finally...{{pause=800}} silence.{{pause=1000}}\nThank you... old friend..." },
        },
    },
    -- Battle 4
    {
        id = 4,
        opening_dialogue = {
            { speaker = CHARACTERS.TheGuardian.name, text = "I knew you would come.{{pause=800}}\nI took an oath to protect this realm.{{pause=600}}\nEven from you." },
            { speaker = CHARACTERS.TheGuardian.name, text = "Your ambition threatened everything!{{pause=700}}\nI had no choice but to stand with the others.{{pause=600}}\nDuty before friendship." },
        },
        enemy = CHARACTERS.TheGuardian,
        mask_reward = "guardian_mask",
        bark_lines = {
            "My oath demands this!",
            "I won't fail my duty again!",
            "This hurts me too, old friend!",
            "Forgive me, but I must!",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheGuardian.name, text = "I see it now...{{pause=800}} we were wrong.{{pause=700}}\nThe real threat... was among us all along.{{pause=1000}}\nThe masks..." },
        },
        player_attack_animation = "arc_tackle",
        player_intro_animation = "drop_bounce",
    },
    -- Battle 5
    {
        id = 5,
        opening_dialogue = {
            { speaker = CHARACTERS.TheUsurper.name, text = "I've been expecting you.{{pause=800}}\nDid you really think I'd leave loose ends?" },
            { speaker = CHARACTERS.TheUsurper.name, text = "We were closest, you and I.{{pause=700}}\nI stood at your side while you wore that crown.{{pause=900}}\nAnd I knew... I could wear it better." },
            { speaker = CHARACTERS.TheUsurper.name, text = "The others?{{pause=500}} Tools.{{pause=400}} Pawns.{{pause=700}}\nBut you... you I respected.{{pause=600}}\nThat's why I made sure you'd never return.{{pause=1000}}\nAnd yet here you are." },
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
            "I know every move you'll make!",
            "I was there for your every victory!",
            "The throne is MINE now!",
            "You were always too merciful!",
            "This crown suits me better!",
        },
        closing_dialogue = {
            { speaker = CHARACTERS.TheUsurper.name, text = "Impossible...{{pause=1000}} after everything...{{pause=800}}\nYou... you've become stronger than I ever imagined." },
            { speaker = CHARACTERS.TheUsurper.name, text = "Perhaps...{{pause=600}} perhaps the masks did choose correctly.{{pause=1000}}\nBut know this...{{pause=700}} I have no regrets." },
        },
    },
}

return BATTLES

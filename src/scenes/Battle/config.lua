---@class BattleSceneConfig
local BattleSceneConfig = {
    LAYOUT = {
        ENEMY_POS = {x = 0.7, y = 0.4},
        ENEMY_BARK_Y_OFFSET = 0.3, -- for bark text above enemy
        PLAYER_POS = {x = 0.25, y = 0.55},
        TITLE_OFFSET = {x = -100, y = 20},
        HP_LABEL_Y = -140,
        ACTION_PROMPT_Y = -18,
    },

    COLORS = {
        SPEAKER = {1, 1, 0.5, 1},
        PLAYER_HP = {0.5, 1, 0.5, 1},
        ENEMY_HP = {1, 0.5, 0.5, 1},
        BATTLE_TITLE = {1, 1, 0.5, 1},
        CONTINUE_PROMPT = {0.7, 0.7, 0.7, 0},
        ACTION_PROMPT = {0.8, 0.8, 0.8, 1},
    },

    -- in seconds
    TIMING = {
        TYPEWRITER_SPEED = 30,           -- characters per second
        ENEMY_ATTACK_DELAY = 1.0,        -- delay before enemy attacks
        DEFEAT_DELAY = 2.0,              -- delay before loss screen
        CONTINUE_PROMPT_FLASH_SPEED = 3, -- flash animation speed
    },

    FLOATING_TEXT = {
        SLIDE_SPEED = 20,                -- pixels per second upward
        FADE_IN_TIME = 0.3,
        FADE_OUT_TIME = 0.5,
        MAX_LIFETIME = 2.5,
        DAMAGE_COLOR = {1, 0.3, 0.3},    -- red
        BARK_COLOR = {1, 1, 0},          -- yellow
    },

    SCREEN_SHAKE = {
        DEATH_DURATION = 0.3,            -- shake duration on enemy death
        DEATH_INTENSITY = 5,             -- shake intensity (pixels)
    },

    COMBAT = {
        PLAYER_MAX_HP = 50,
        PLAYER_ATTACK_POWER = 10,
        PLAYER_DAMAGE_VARIANCE = 2,      -- +/- random damage
        ENEMY_DAMAGE_VARIANCE = 1,       -- +/- random damage
        BARK_CHANCE = 0.4,               -- 40% chance for bark line
    },

    AUDIO = {
        TYPEWRITER_INTERVAL = 2,
        TYPEWRITER_PITCH_MIN = 0.95,
        TYPEWRITER_PITCH_MAX = 1.05,
    },
}

return BattleSceneConfig

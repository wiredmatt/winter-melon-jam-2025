---@class BattleSceneConfig
local BattleSceneConfig = {
    LAYOUT = {
        ENEMY_POS = {x = 0.7, y = 0.45},
        ENEMY_BARK_Y_OFFSET = 0.3, -- for bark text above enemy
        PLAYER_POS = {x = 0.25, y = 0.45},
        TITLE_OFFSET = {x = -100, y = 5},
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
        BUTTON_NORMAL = {0.3, 0.3, 0.3, 1},
        BUTTON_SELECTED_BORDER = {1, 1, 1, 1},
        BUTTON_NORMAL_BORDER = {0.5, 0.5, 0.5, 1},
        BUTTON_DISABLED = {0.2, 0.2, 0.2, 0.5},
        MASK_NAME = {1, 1, 0.5, 1},
        SKILL_READY = {0.5, 1, 0.5, 1},
        SKILL_COOLDOWN = {1, 0.5, 0.5, 1},
    },

    -- in seconds
    TIMING = {
        TYPEWRITER_SPEED = 30,           -- characters per second
        ENEMY_ATTACK_DELAY = 1.0,        -- delay before enemy attacks
        DEFEAT_DELAY = 2.0,              -- delay before loss screen
        CONTINUE_PROMPT_FLASH_SPEED = 3, -- flash animation speed
    },

    FLOATING_TEXT = {
        SLIDE_SPEED = 25,                -- pixels per second upward (faster)
        FADE_IN_TIME = 0.2,             -- faster fade in
        FADE_OUT_TIME = 0.25,             -- faster fade out
        MAX_LIFETIME = 1.25,              -- shorter duration
        POSITION_VARIANCE = 10,          -- random X/Y offset range in pixels
        DAMAGE_COLOR = {1, 0.3, 0.3},    -- red
        BARK_COLOR = {1, 1, 0},          -- yellow
    },

    SCREEN_SHAKE = {
        DEATH_DURATION = 0.3,            -- shake duration on enemy death
        DEATH_INTENSITY = 5,             -- shake intensity (pixels)
    },

    COMBAT = {
        PLAYER_MAX_HP = 100,
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

    MUSIC = {
        CROSSFADE_DURATION = 2.0,  -- Crossfade duration in seconds
        TRANSITION_THRESHOLD = 0.8,  -- Default HP percentage for music transition
    },
}

return BattleSceneConfig

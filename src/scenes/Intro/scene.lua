---@class IntroScene : Scene
---@field current_page number
---@field waiting_for_input boolean
---@field image_sprite Sprite
---@field typewriter Typewriter
local IntroScene = {
    name = "Intro",
    transition_in = SceneManager.Transitions.FadeIn.New(),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = require("src.scenes.Intro.inputmap"),
}

-- story pages config
-- each page has text and an optional image
-- you can use {{pause=500}} to pause typing for 500 milliseconds
local STORY_PAGES = {
    {
        text = "The masked ones chose a king.{{pause=500}}\nAnd they chose you.",
        image = nil,
    },
    {
        text = "They stood at your side...{{pause=800}}\nUntil they didn't.",
        image = nil,
    },
    {
        text = "You'll get them back...{{pause=600}}\nOne mask at a time.",
        image = nil,
    },
}

IntroScene.Enter = function (self)
    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")

    local tiny5_8px_font = AssetManager.assets.fonts.Tiny5_ttf[8]
    tiny5_8px_font:setFilter("nearest", "nearest")

    -- story state
    self.current_page = 1
    self.waiting_for_input = false

    self.root_node = UI.Node.New()

    self.image_sprite = UI.Sprite.New({
        x = CONFIG.virtual_cfg.width / 2,
        y = CONFIG.virtual_cfg.height / 3,
        image = STORY_PAGES[1].image,
    })
    if self.image_sprite.image then
        self.image_sprite.x = self.image_sprite.x - self.image_sprite.width / 2
        self.image_sprite.y = self.image_sprite.y - self.image_sprite.height / 2
    end
    self.root_node:AddChild(self.image_sprite)

    self.typewriter = UI.Typewriter.New({
        full_text = STORY_PAGES[1].text,
        font = tiny5_16px_font,
        x = 40,
        y = CONFIG.virtual_cfg.height - 80,
        width = CONFIG.virtual_cfg.width - 80,
        chars_per_second = 15,
        on_complete = function()
            self.waiting_for_input = true
        end,
        -- sound effect config
        sfx = AssetManager.assets.sfx.typewriter_blip_wav,
        sfx_interval = 1,
        sfx_pitch_min = 0.95,  -- minimum pitch (default: 0.9)
        sfx_pitch_max = 1.05,  -- maximum pitch (default: 1.1)
    })
    self.root_node:AddChild(self.typewriter)
end

IntroScene.HandleInput = function (self)
    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
        self:AdvancePage()
    end
end

IntroScene.Update = function (self, dt)
    self.root_node:Update(dt)

    self:HandleInput()
end

IntroScene.Draw = function (self)
    self.root_node:Draw()
end

IntroScene.Exit = function (_)
end

-- advance to next page or complete intro
IntroScene.AdvancePage = function (self)
    if not self.waiting_for_input then
        -- skip current typewriter animation
        self.typewriter:Skip()
        return
    end

    -- move to next page
    self.current_page = self.current_page + 1

    if self.current_page > #STORY_PAGES then
        -- intro complete, switch to gameplay
        Settings.Set("flags", "intro_seen", true)
        SceneManager.SwitchTo(Scenes.Gameplay)
    else
        -- load next page
        local page = STORY_PAGES[self.current_page]

        -- update img
        if page.image then
            self.image_sprite:SetImage(page.image)
            -- center the sprite
            local screen_width = love.graphics.getWidth()
            local screen_height = love.graphics.getHeight()
            self.image_sprite.x = (screen_width / 2) - (self.image_sprite.width / 2)
            self.image_sprite.y = (screen_height / 3) - (self.image_sprite.height / 2)
        else
            self.image_sprite:SetImage(nil)
        end

        self.typewriter:SetFullText(page.text, true)
        self.waiting_for_input = false
    end
end

return IntroScene
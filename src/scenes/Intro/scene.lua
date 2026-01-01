local inputmap = require("src.scenes.Intro.inputmap")

---@class IntroScene : Scene
---@field current_page number
---@field waiting_for_input boolean
local IntroScene = {
    name = "Intro",
    transition_in = SceneManager.Transitions.FadeIn.New(),
    transition_out = SceneManager.Transitions.FadeOut.New(),
    inputmap = inputmap,
}

-- story pages config
-- each page has text and an optional image
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

IntroScene.Enter = function(self)
    local tiny5_16px_font = AssetManager.assets.fonts.Tiny5_ttf[16]
    tiny5_16px_font:setFilter("nearest", "nearest")

    local tiny5_8px_font = AssetManager.assets.fonts.Tiny5_ttf[8]
    tiny5_8px_font:setFilter("nearest", "nearest")
end

IntroScene.HandleInput = function(self)
    if InputManager.JustPressed(self.inputmap.actions.CONFIRM) then
    end
end

IntroScene.Update = function(self, dt)
    self:HandleInput()
end

IntroScene.Draw = function(self)
end

IntroScene.Exit = function(_)
end

return IntroScene

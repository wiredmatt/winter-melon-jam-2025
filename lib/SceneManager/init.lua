---@class Scene
---@field name string
---@field Enter fun(self)
---@field Exit fun(self)
---@field Update fun(self, dt)
---@field Draw fun(self)
---@field transition_in Transition|nil
---@field transition_out Transition|nil
---@field root_node Node?

---@class Transition
---@field completed boolean
---@field Update fun(self, dt: number)
---@field Draw fun(self)

---@class SceneManager
---@field scenes table<string, Scene>
---@field current Scene|nil
---@field mid_transition boolean
---@field private _prev Scene|nil
---@field private _next Scene|nil
---@field private _transition Transition|nil
---@field private _pending_in Transition|nil
local SceneManager = {
    scenes = {},
    current = nil,
    _prev = nil,
    _next = nil,
    _transition = nil,
    _pending_in = nil,
    mid_transition = false
}
SceneManager.__index = SceneManager

_G.__NOOP__ = _G.__NOOP__ or function (...) return nil end

---@param scene Scene
SceneManager._validate = function(scene)
    assert(type(scene) == 'table')
    assert(type(scene.name) == 'string')
    if type(scene.Enter) ~= "function" then scene.Enter = __NOOP__ end
    if type(scene.Draw) ~= "function" then scene.Draw = __NOOP__ end
    if type(scene.Update) ~= "function" then scene.Update = __NOOP__ end
    if type(scene.Exit) ~= "function" then scene.Exit = __NOOP__ end
end

---@param scene Scene
SceneManager.Register = function(scene)
    SceneManager._validate(scene) -- trigger validations
    SceneManager.scenes[scene.name] = scene
end

---@param scenes_tbl Scene[]
SceneManager.RegisterAll = function (scenes_tbl)
    for _,v in pairs(scenes_tbl) do
        SceneManager._validate(v)
        SceneManager.scenes[v.name] = v
    end
end

---@param name string|Scene
---@param transition_in fun()|nil
---@param transition_out fun()|nil
SceneManager.SwitchTo = function (name, transition_in, transition_out)
    if type(name) == "table" then if name.name ~= nil then name = name.name end end

    assert(type(name) == 'string', "Scene name must be string")
    local next_scene = SceneManager.scenes[name]
    assert(next_scene ~= nil, "Scene not registered: " .. name)

    if SceneManager.mid_transition and next_scene == SceneManager._next then return end

    SceneManager._prev = SceneManager.current
    SceneManager._next = next_scene
    SceneManager.mid_transition = true

    local out_t = transition_out or (SceneManager._prev and SceneManager._prev.transition_out)
    local in_t = transition_in or (next_scene.transition_in)

    if SceneManager._prev == nil and SceneManager.current == nil then -- first SwitchTo call.
        SceneManager._transition = (type(in_t) == "function" and in_t()) or nil
        SceneManager.current = SceneManager._next; SceneManager._next = nil
        SceneManager.current:Enter()
        return
    else
        if type(out_t) == "function" then
            SceneManager._transition = out_t()
            SceneManager._pending_in = type(in_t) == "function" and in_t() or nil
            return
        elseif type(in_t) == "function" then
            SceneManager._transition = in_t()
            SceneManager._pending_in = nil

            SceneManager.current = SceneManager._next; SceneManager._next = nil
            SceneManager.current:Enter()

            return
        end
    end

    if SceneManager._transition == nil then
        SceneManager._prev = nil
        SceneManager.current = SceneManager._next
        SceneManager._next = nil
        SceneManager.mid_transition = false
        SceneManager.current:Enter()
    end
end

---@param dt number
SceneManager.Update = function(dt)
    if SceneManager._transition ~= nil then
        SceneManager._transition:Update(dt)

        if SceneManager._transition.completed then
            if SceneManager._pending_in ~= nil then
                if SceneManager._prev then SceneManager._prev:Exit() end
                SceneManager._prev = nil
                SceneManager.current = SceneManager._next
                SceneManager._next = nil
                SceneManager._transition = SceneManager._pending_in
                SceneManager._pending_in = nil
                SceneManager.current:Enter()

                SceneManager._transition.completed = false
            else
                SceneManager._transition = nil
                if SceneManager._next ~= nil then
                    SceneManager.current = SceneManager._next
                    SceneManager._next = nil
                    SceneManager.current:Enter()
                end
            end
        end
    end

    SceneManager.mid_transition = SceneManager._transition ~= nil or SceneManager._pending_in ~= nil

    if SceneManager.current ~= nil then SceneManager.current:Update(dt) end
end

SceneManager.Draw = function()
    if SceneManager.current ~= nil then SceneManager.current:Draw() end
    if SceneManager._transition ~= nil then SceneManager._transition:Draw() end
end

SceneManager.Transitions = {
    NONE = require("lib.SceneManager.transitions.None").New(),
    FadeIn = require("lib.SceneManager.transitions.FadeIn"),
    FadeOut = require("lib.SceneManager.transitions.FadeOut"),
    DiagonalOut = require("lib.SceneManager.transitions.DiagonalOut")
}

return SceneManager
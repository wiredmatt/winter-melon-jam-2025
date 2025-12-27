---@class IGame
---@field Load fun(self) | nil
---@field Draw fun(self) | nil
---@field Update fun(self, dt) | nil
---@field MouseMoved fun(self, x: number, y: number, dx: number, dy: number, istouch: number, rawx: number, rawy: number, rawdx: number, rawdy: number) | nil
---@field MousePressed fun(self, x: number, y: number, button: number, istouch: number, presses: number, rawx: number, rawy: number) | nil
---@field MouseReleased fun(self, x: number, y: number, button: number, istouch: number, presses: number, rawx: number, rawy: number) | nil
---@field KeyPressed fun(self, key: string, scancode: string, isrepeat: boolean) | nil
---@field TouchMoved fun(self, id: number, x: number, y: number, dx: number, dy: number, pressure: number, rawx: number, rawy: number, rawdx: number, rawdy: number) | nil
---@field TouchPressed fun(self, id: number, x: number, y: number, dx: number, dy: number, pressure: number, rawx: number, rawy: number, rawdx: number, rawdy: number) | nil
---@field TouchReleased fun(self, id: number, x: number, y: number, dx: number, dy: number, pressure: number, rawx: number, rawy: number, rawdx: number, rawdy: number) | nil

---@class ResolutionConfig_WindowOptions
---@field width number
---@field height number
---@field fullscreen boolean? 
---@field fullscreentype love.FullscreenType?
---@field vsync boolean?
---@field msaa number?
---@field stencil boolean?
---@field depth number?
---@field resizable boolean?
---@field borderless boolean?
---@field centered boolean?
---@field display number?
---@field minwidth number?
---@field minheight number?
---@field highdpi boolean?
---@field x number?
---@field y number?
---@field usedpiscale boolean?
---@field srgb boolean?
---@field title string?

---@class ResolutionConfig_VirtualOptions
---@field width number
---@field height number

---@class ResolutionConfig_CanvasOptions
---@field clear_color [number, number, number, number]
---@field filter_min love.FilterMode?
---@field filter_max love.FilterMode?
---@field filter_ansitropy number?

---@class IProgramConfig
---@field window_cfg ResolutionConfig_WindowOptions
---@field virtual_cfg ResolutionConfig_VirtualOptions
---@field canvas_cfg ResolutionConfig_CanvasOptions
---@field scale? number
---@field offset_x? number
---@field offset_y? number

---@class Program : IProgramConfig
---@field game IGame
---@field transform love.Transform
---@field Mouse love.mouse
---@field Touch love.touch
local Program = {}
Program.__index = Program
---@class Program.Mouse
Program.Mouse = setmetatable({}, love.mouse)
---@class Program.Touch
Program.Touch = setmetatable({}, love.touch)
Program._og_mouse_fns = {
    GetPosition = love.mouse.getPosition,
    SetPosition = love.mouse.setPosition,
    GetX = love.mouse.getX,
    GetY = love.mouse.getY,
    SetX = love.mouse.setX,
    SetY = love.mouse.setY,
}
Program._og_touch_fns = {
    GetPosition = love.touch.GetPosition,
}

function __NOOP__(...) return nil end

---@param config IProgramConfig
---@param game IGame?
Program.Setup = function (config, game)
    assert(type(config) == 'table')
    assert(type(config.window_cfg) == 'table')
    assert(type(config.virtual_cfg) == 'table')
    assert(type(config.canvas_cfg) == 'table')
    assert(type(game) == 'table' or Program.game ~= nil)

    Program.scale = 1
    Program.offset_x = 0
    Program.offset_y = 0

    Program.window_cfg = config.window_cfg
    Program.virtual_cfg = config.virtual_cfg
    Program.canvas_cfg = config.canvas_cfg or { filter_min = "linear", filter_max = "linear", filter_ansitropy = 1, clear_color = {0,0,0,0} }

    Program.canvas = love.graphics.newCanvas(Program.virtual_cfg.width, Program.virtual_cfg.height)
    Program.canvas:setFilter(Program.canvas_cfg.filter_min, Program.canvas_cfg.filter_max, Program.canvas_cfg.filter_ansitropy)

    Program.transform = love.math.newTransform(Program.offset_x, Program.offset_y, 0, Program.scale, Program.scale)

    if Program.game == nil and game ~= nil then
        Program.game = game
        if type(Program.game.Load) ~= "function" then Program.game.Load = __NOOP__ end
        if type(Program.game.Draw) ~= "function" then Program.game.Draw = __NOOP__ end
        if type(Program.game.Update) ~= "function" then Program.game.Update = __NOOP__ end
        if type(Program.game.MouseMoved) ~= "function" then Program.game.MouseMoved = __NOOP__ end
        if type(Program.game.MousePressed) ~= "function" then Program.game.MousePressed = __NOOP__ end
        if type(Program.game.MouseReleased) ~= "function" then Program.game.MouseReleased = __NOOP__ end
        if type(Program.game.KeyPressed) ~= "function" then Program.game.KeyPressed = __NOOP__ end

        love.resize = function (ww, wh) Program.Resize(ww,wh,nil,nil) end
        love.draw = Program.Draw
        love.update = Program.Update
        love.mousemoved = Program.MouseMoved
        love.mousepressed = Program.MousePressed
        love.mousereleased = Program.MouseReleased
        love.keypressed = Program.KeyPressed
        love.touchmoved = Program.TouchMoved
        love.touchpressed = Program.TouchPressed
        love.touchreleased = Program.TouchReleased

        love.mouse.getPosition = Program.Mouse.GetPosition;love.mouse.getX = Program.Mouse.GetX;love.mouse.getY = Program.Mouse.GetY
        love.mouse.setPosition = Program.Mouse.SetPosition;love.mouse.setX = Program.Mouse.SetX;love.mouse.setY = Program.Mouse.SetY
        love.touch.GetPosition = Program.Touch.GetPosition

        local og_setMode = love.window.setMode
        ---@diagnostic disable-next-line: duplicate-set-field
        love.window.setMode = function (...) og_setMode(...);love.resize(...) end
    end

    Program.ApplyWindowSettings()

    Program.game:Load()
end

Program.ApplyWindowSettings = function ()
    love.window.setMode(Program.window_cfg.width, Program.window_cfg.height, {
        fullscreen = Program.window_cfg.fullscreen,
        fullscreentype = Program.window_cfg.fullscreentype,
        vsync = Program.window_cfg.vsync,
        msaa = Program.window_cfg.msaa,
        stencil = Program.window_cfg.stencil,
        depth = Program.window_cfg.depth,
        resizable = Program.window_cfg.resizable,
        borderless = Program.window_cfg.borderless,
        centered = Program.window_cfg.centered,
        display = Program.window_cfg.display,
        minwidth = Program.window_cfg.minwidth,
        minheight = Program.window_cfg.minheight,
        highdpi = Program.window_cfg.highdpi,
        x = Program.window_cfg.x,
        y = Program.window_cfg.y,
        usedpiscale = Program.window_cfg.usedpiscale,
        srgb = Program.window_cfg.srgb
    })
    if Program.window_cfg.title ~= nil then
        love.window.setTitle(Program.window_cfg.title)
    end
end

---Resolution.resize will either be called by the user when they manually resize the window, 
---or when they change the resolution options from the menu.
---@param ww number?
---@param wh number?
---@param vw number?
---@param vh number?
Program.Resize = function (ww, wh, vw, vh)
    if (ww == Program.window_cfg.width and wh == Program.window_cfg.height
        and vw == Program.virtual_cfg.width and vh == Program.virtual_cfg.height)
    then return end

    if ww ~= nil and wh ~= nil then
        Program.window_cfg.width = ww
        Program.window_cfg.height = wh
    end

    Program.scale = math.min(
        Program.window_cfg.width / Program.virtual_cfg.width,
        Program.window_cfg.height / Program.virtual_cfg.height
    )

    Program.offset_x = (Program.window_cfg.width - Program.virtual_cfg.width * Program.scale) / 2
    Program.offset_y = (Program.window_cfg.height - Program.virtual_cfg.height * Program.scale) / 2

    if (vw ~= nil and vh ~= nil) and (vw ~= Program.virtual_cfg.width and vh ~= Program.virtual_cfg.height) then
        Program.canvas = love.graphics.newCanvas(Program.virtual_cfg.width, Program.virtual_cfg.height)
        Program.canvas:setFilter(Program.canvas_cfg.filter_min, Program.canvas_cfg.filter_max, Program.canvas_cfg.filter_ansitropy)
    end

    Program.transform = love.math.newTransform(Program.offset_x, Program.offset_y, 0, Program.scale, Program.scale)
end

Program.Draw = function ()
    love.graphics.setCanvas({Program.canvas, stencil = true})
        love.graphics.clear(Program.canvas_cfg.clear_color)

        love.graphics.push()
            Program.game:Draw()
        love.graphics.pop()
    love.graphics.setCanvas()

    love.graphics.push()
        love.graphics.applyTransform(Program.transform)
        love.graphics.draw(Program.canvas, 0, 0)
    love.graphics.pop()
end

Program.Update = function (dt) Program.game:Update(dt) end

---@param gx number global x
---@param gy number global y
---@return number x, number y
Program.ScaledPoint = function (gx,gy)
    local spx,spy = Program.transform:inverseTransformPoint(gx,gy)
    return math.floor(spx), math.floor(spy)
end

---@param spx number scaled x
---@param spy number scaled y
---@return number x, number y
Program.GlobalPoint = function (spx,spy)
    local gx,gy = Program.transform:transformPoint(spx, spy)
    return math.floor(gx), math.floor(gy)
end

Program.Mouse.GetPosition = function ()
    local gx,gy = Program._og_mouse_fns.GetPosition()
    local spx,spy = Program.ScaledPoint(gx,gy)
    return spx, spy
end
Program.Mouse.GetX = function ()
    local gx,_ = Program._og_mouse_fns.GetPosition()
    local spx,_ = Program.ScaledPoint(gx,0)
    return spx
end
Program.Mouse.GetY = function ()
    local _,gy = Program._og_mouse_fns.GetPosition()
    local _,spy = Program.ScaledPoint(0,gy)
    return spy
end
Program.Mouse.SetPosition = function (x,y)
    local gx, gy = Program.GlobalPoint(x,y)
    Program._og_mouse_fns.SetPosition(gx,gy)
end
Program.Mouse.SetX = function (x)
    local gx, _ = Program.GlobalPoint(x,0)
    local _, gy = Program.Mouse.GetPosition()
    Program._og_mouse_fns.SetPosition(gx,gy)
end
Program.Mouse.SetY = function (y)
    local _, gy = Program.GlobalPoint(0,y)
    local gx, _ = Program.Mouse.GetPosition()
    Program._og_mouse_fns.SetPosition(gx,gy)
end
Program.MouseMoved = function (rawx,rawy,rawdx,rawdy, istouch)
    local spx,spy = Program.ScaledPoint(rawx, rawy)
    local spdx,spdy = Program.ScaledPoint(rawdx, rawdy)

    Program.game:MouseMoved(spx,spy,spdx,spdy,istouch,rawx,rawy,rawdx,rawdy)
end
Program.MousePressed = function (rawx,rawy,button,istouch,presses)
    local spx,spy = Program.ScaledPoint(rawx, rawy)
    Program.game:MousePressed(spx,spy,button,istouch,presses,rawx,rawy)
end
Program.MouseReleased = function (rawx,rawy,button,istouch,presses)
    local spx,spy = Program.ScaledPoint(rawx, rawy)
    Program.game:MouseReleased(spx,spy,button,istouch,presses,rawx,rawy)
end

Program.KeyPressed = function (key, scancode, isrepeat)
    Program.game:KeyPressed(key, scancode, isrepeat)
end

Program.Touch.GetPosition = function (id)
    local gx,gy = Program._og_touch_fns.GetPosition(id)
    local spx,spy = Program.ScaledPoint(gx,gy)
    return spx, spy
end
Program.TouchMoved = function (id,rawx,rawy,rawdx,rawdy,pressure)
    local spx,spy = Program.ScaledPoint(rawx, rawy)
    local spdx,spdy = Program.ScaledPoint(rawdx, rawdy)
    Program.game:TouchMoved(id,spx,spy,spdx,spdy,pressure,rawx,rawy,rawdx,rawdy)
end
Program.TouchPressed = function (id,rawx,rawy,rawdx,rawdy,pressure)
    local spx,spy = Program.ScaledPoint(rawx, rawy)
    local spdx,spdy = Program.ScaledPoint(rawdx, rawdy)
    Program.game:TouchPressed(id,spx,spy,spdx,spdy,pressure,rawx,rawy,rawdx,rawdy)
end
Program.TouchReleased = function (id,rawx,rawy,rawdx,rawdy,pressure)
    local spx,spy = Program.ScaledPoint(rawx, rawy)
    local spdx,spdy = Program.ScaledPoint(rawdx, rawdy)
    Program.game:TouchReleased(id,spx,spy,spdx,spdy,pressure,rawx,rawy,rawdx,rawdy)
end

return Program
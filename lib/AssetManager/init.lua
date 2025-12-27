-- optional dependencies
local FSok, FS = pcall(require, "lib/FS")
local FontProxyok, FontProxy = pcall(require, "lib/FontProxy")
local AsepriteLoaderok, AsepriteLoader = pcall(require, "lib/AsepriteLoader")

---@class AssetManager
---@field assets GameAssets
local AssetManager = { assets = {}, ASSETS_PATH = "assets", SOURCE_MAX_SIZE = 1024*1024 }
AssetManager.__index = AssetManager

local function sanitize_key(name)
    local sanitized = name:gsub("[^%w]", "_")
    if sanitized:match("^%d") then sanitized = "_" .. sanitized end
    if sanitized == "" then sanitized = "_asset" end
    return sanitized
end

local AssetTypeMap = {
    Image   = "love.Image",
    Source  = "love.Source",
    Font    = "ProxiedFont",
    Video   = "love.Video",
    String = "string",
    RawAse = "RawAse"
}

---@param path string
---@param tbl table
---@param class_name string
---@param classes table
local function scan_assets(path, tbl, class_name, classes)
    local items = love.filesystem.getDirectoryItems(path)

    local fields, seen = {}, {}
    for _, name in ipairs(items) do
        if name == "meta.lua" then goto continue end
        local full_path = path .. "/" .. name
        local info = love.filesystem.getInfo(full_path)
        if not info then goto continue end

        local key = sanitize_key(name)
        if seen[key] then
            print("Sanitized collision: " .. key)
            goto continue
        end
        seen[key] = true

        if info.type == "file" then
            local ext = (name:match("^.+(%..+)$") or ""):lower()
            local atype = AssetTypeMap.String
            local value

            if ext == ".png" or ext == ".jpg" or ext == ".jpeg" or ext == ".bmp" or ext == ".webp" then
                value, atype = love.graphics.newImage(full_path), AssetTypeMap.Image
            elseif ext == ".ogg" or ext == ".mp3" or ext == ".wav" then
                local size = info.size or 0
                local stype = (size <= AssetManager.SOURCE_MAX_SIZE) and "static" or "stream"
                value, atype = love.audio.newSource(full_path, stype), AssetTypeMap.Source
            elseif ext == ".ttf" or ext == ".otf" then
                value, atype = (FontProxyok and FontProxy.New(full_path) or setmetatable({}, {__index = function (_, k) return love.graphics.newFont(k) end})), AssetTypeMap.Font
            elseif ext == ".lua" or ext == ".json" or ext == ".txt" then
                value, atype = love.filesystem.read(full_path), AssetTypeMap.String
            elseif ext == ".ogv" then
                value, atype = love.graphics.newVideo(full_path), AssetTypeMap.Video
            elseif (ext == ".ase" or ext == ".aseprite") and AsepriteLoaderok then
                value, atype = AsepriteLoader.Load(full_path, {}), AssetTypeMap.RawAse
            else
                print("file extension not supported: " .. ext .. " skipping file...")
                goto continue
            end

            tbl[key] = value
            table.insert(fields, { name = key, type = atype })

        elseif info.type == "directory" then
            local child_class = class_name .. "_" .. key
            tbl[key] = {}
            table.insert(fields, { name = key, type = child_class })
            scan_assets(full_path, tbl[key], child_class, classes)
        end

        ::continue::
    end

    table.insert(classes, { name = class_name, fields = fields })
end

-- loads assets and writes meta.lua
AssetManager.load_assets = function()
    local classes = {}
    scan_assets(AssetManager.ASSETS_PATH, AssetManager.assets, "GameAssets", classes)

    -- write meta.lua
    local lines = { "---@meta", "" }
    for _, cls in ipairs(classes) do
        table.insert(lines, "---@class " .. cls.name)
        for _, f in ipairs(cls.fields) do
            table.insert(lines, string.format("---@field %s %s", f.name, f.type))
        end
        table.insert(lines, "")
    end

    local contents = table.concat(lines, "\n")
    local workdir = love.filesystem.getWorkingDirectory()

    if FSok then FS.New(workdir):SaveModule(contents, AssetManager.ASSETS_PATH .. "/" .. "meta.lua")
    else print(contents) end
end

AssetManager.Load = function (assets_path, source_max_size)
    AssetManager.ASSETS_PATH = assets_path or "assets"
    AssetManager.SOURCE_MAX_SIZE = source_max_size or (1024 * 1024)

    if not FSok then print("[WARN] FS module not found. Meta file will not be generated, create it manually.") end
    if not FontProxyok then print("[WARN] FontProxy module not found. Using less performant dynamic font generation.") end
    if not AsepriteLoaderok then print("[WARN] AsepriteLoader module not found, skipping .ase and .aseprite files.") end

    print("Loading and annotating assets...")
    local ok, err = pcall(AssetManager.load_assets)
    if ok then
        print("Assets loaded and annotations generated.")
        return true
    else
        print("Failed to load assets: " .. tostring(err))
        return false
    end
end

AssetManager.NewAse = function (raw)
    if not AsepriteLoaderok then error("Can't create a new ase instance without AsepriteLoader module.") end
    return AsepriteLoader.NewAse(raw)
end

AssetManager.ReloadAse = function () AsepriteLoader.Reload() end

return AssetManager
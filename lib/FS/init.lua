-- NOTE(matt): this module won't be necessary when LOVE12 is released.

local ffi = require("ffi")

local osx = ffi.os == "OSX" or nil
local linux = ffi.os == "Linux" or nil
local win = ffi.os =="Windows" or nil

local function findvalue(tb, value)
	for _, v in ipairs(tb) do
		if v == value then return true end
	end
	return false
end

---@class FileSystem
---@field sep string
---@field AbsPath fun(self, path: string): string
---@field Ls fun(self, dir: string): string, string[], string[], string[], string[]
---@field copy fun(self, source: string, dest: string)
local FileSystem = {}
FileSystem.__index = FileSystem

if win then require ("lib.FS.windows")(FileSystem)
elseif osx then require ("lib.FS.osx")(FileSystem)
elseif linux then require ("lib.FS.linux")(FileSystem)
else error('Platform not supported') end

function FileSystem:SwitchHidden()
	self.show_hidden = not self.show_hidden
	self:Cd()
end

function FileSystem:SetFilter(filter)
	self.filter = nil
	if type(filter) == "table" then
		self.filter = filter
	elseif type(filter) == "string" then
		local t = {}
		local f = filter:sub((filter:find('|') or 0) + 1)
		for i in string.gmatch(f, "%S+") do
			i = i:gsub('[%*%.%;]', '')
			if i ~= '' then table.insert(t, i) end
		end
		if #t > 0 then self.filter = t end
	end
	self:Cd()
end

---@param dir string?
function FileSystem:Dir(dir)
	dir = dir or ""
	return self:Ls(dir)
end

function FileSystem:Cd(dir)
	local current, tdirs, tfiles, tothers, tall = self:Ls(dir)
	if current then
		self.current = current
		self.dirs = tdirs
		self.files = tfiles
		self.others = tothers
		self.all = tall
		return true
	end
	return false
end

function FileSystem:Up()
	self:Cd(self.current:match('(.*'..self.sep..')'))
end

function FileSystem:Exists(path)
	path = self:AbsPath(path)
	local dir = self:AbsPath(path:match('(.*'..self.sep..')'))
	local name = path:match('[^'..self.sep..']+$')
	--ext = name:match('[^.]+$')
	local dir, dirs, files, others, all = self:Ls(dir)
	if dir then
		return findvalue(all, name), findvalue(dirs, name), findvalue(files, name)
	end
	return false
end

function FileSystem:IsDirectory(path)
	local exists, isdir = self:Exists(path)
	if exists then return isdir
	else return false end
end

function FileSystem:IsFile(path)
	local exists, isdir, isfile = self:Exists(path)
	if exists then return isfile
	else return false end
end

function FileSystem:LoadImage(source)
	source = source or self.selected_file
	self.selected_file = nil
	source = self:AbsPath(source)
	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file')
	return love.image.newImageData('lovefs_temp/temp.file')
end

function FileSystem:LoadSource(source)
	source = source or self.selected_file
	self.selected_file = nil
	source = self:AbsPath(source)
	love.filesystem.createDirectory('lovefs_temp')
	local ext = source:match('[^'..self.sep..']+$'):match('[^.]+$')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.'..ext)
	return love.audio.newSource('lovefs_temp/temp.'..ext, 'static')
end

function FileSystem:LoadFont(size, source)
	source = source or self.selected_file
	self.selected_file = nil
	source = self:AbsPath(source)
	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file')
	return love.graphics.newFont('lovefs_temp/temp.file', size)
end

function FileSystem:SaveImage(img, dest)
	if not pcall(function() love.graphics.newCanvas(img:getWidth(), img:getHeight()) end) then return false end
	dest = dest or self.selected_file
	dest = self:AbsPath(dest)
	self.selected_file = nil
	love.filesystem.createDirectory('lovefs_temp')
	love.filesystem.remove('lovefs_temp/temp.file')
	love.graphics.setColor(255, 255, 255)
	local canvas = love.graphics.newCanvas(img:getWidth(), img:getHeight())
	love.graphics.setCanvas(canvas)
	love.graphics.draw(img, 0, 0)
	love.graphics.setCanvas()
	local id = canvas:newImageData()
	id:encode('png', 'lovefs_temp/temp.file')
	self:copy(love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file', dest)
	return true
end

function FileSystem:SaveModule(modcode, dest)
	local _, err = load(modcode); if err ~= nil then error(err) end

	love.filesystem.createDirectory('lovefs_temp')
	love.filesystem.remove('lovefs_temp/temp.file')

	local file = love.filesystem.newFile('lovefs_temp/temp.file', "w")
	file:open("w")
	file:write(modcode)
	file:close()
	self:copy(love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file', dest)
	return true
end

function FileSystem:LoadModule(source)
	source = source or self.selected_file
	self.selected_file = nil
	source = self:AbsPath(source)

	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file')

	local contents, _ = love.filesystem.read('lovefs_temp/temp.file')
	return contents
end

---@param Dir string?
---@return FileSystem
function FileSystem.New(Dir)
	local temp = {}
	setmetatable(temp, FileSystem)
	temp.selected_file = nil
	temp.filter = nil
	temp.show_hidden = false
	temp.home = love.filesystem.getUserDirectory()
	temp.current = temp.home
	temp.sep = package.config:sub(1,1)
	Dir = Dir or temp.home
	if not temp:Cd(Dir) then
		if not temp:Cd(temp.home) then
			if not temp:Cd('c:'..temp.sep) then
				temp:Cd(temp.sep)
			end
		end
	end
	temp:UpdDrives()
	return temp
end

return FileSystem
return {
  
  -- basic settings:
  name = 'Masked King', -- name of the game for your executable
  developer = 'wiredmatt', -- dev name used in metadata of the file
  output = '', -- output location for your game, defaults to $SAVE_DIRECTORY
  version = '0.0.1', -- 'version' of your game, used to name the folder in output
  love = '11.5', -- version of LÖVE to use, must match github releases
  ignore = {'.git', 'dist', '.vscode', 'README.md'}, -- folders/files to ignore in your project
  icon = "assets/fractured_crown.png", -- 256x256px PNG icon for game, will be converted for you
  
  -- optional settings:
  use32bit = true, -- set true to build windows 32-bit as well as 64-bit
  identifier = 'com.wiredmatt.maskedking', -- macos team identifier, defaults to game.developer.name
  libs = { -- files to place in output directly rather than fuse
    windows = {}, -- can specify per platform or "all"
    all = {}
  },
  hooks = { -- hooks to run commands via os.execute before or after building
    before_build = nil,
    after_build = nil
  },
  platforms = {'windows'} -- set if you only want to build for a specific platform
  
}
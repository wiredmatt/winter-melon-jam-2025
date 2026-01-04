---@meta

---@class Plugin
---@field name string
---@field InstallTo fun(node: table)
---@field UninstallFrom fun(node: table)
---@field UninstallFromAll fun()
---@field Update fun(dt: number)
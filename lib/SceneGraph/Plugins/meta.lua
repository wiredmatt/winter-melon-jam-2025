---@meta

---@class Plugin
---@field name string
---@field InstallTo fun(self, node: table)
---@field UninstallFrom fun(self, node: table)
---@field UninstallFromAll fun(self)
---@field Update fun(self, dt: number)
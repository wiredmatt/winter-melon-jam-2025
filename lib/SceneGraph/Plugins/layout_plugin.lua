---@alias LayoutMode "flex" | "anchor"
---@alias LayoutDirection "row" | "column"
---@alias LayoutJustify "start" | "center" | "end" | "space-between" | "space-around"
---@alias LayoutAlign "start" | "center" | "end" | "stretch"
---@alias LayoutSizing "explicit" | "content"
---@alias LayoutAnchor "top-left" | "top" | "top-right" | "left" | "center" | "right" | "bottom-left" | "bottom" | "bottom-right"
---@alias LayoutDock "top" | "bottom" | "left" | "right" | "fill"

---@class LayoutConfig
---@field mode LayoutMode
---@field direction LayoutDirection
---@field justify LayoutJustify
---@field align LayoutAlign
---@field gap number
---@field padding { top: number, right: number, bottom: number, left: number }
---@field sizing_width LayoutSizing
---@field sizing_height LayoutSizing

---@class LayoutChildConfig
---@field anchor LayoutAnchor?
---@field dock LayoutDock?
---@field grow number?
---@field shrink number?
---@field align_self LayoutAlign?

---@class LayoutPlugin
local LayoutPlugin = {
    name = "Layout",
    _nodes = {},           ---@type { [BaseNode]: boolean }
    _dirty_nodes = {},     ---@type { [BaseNode]: boolean }
    _dirty = false,
}

---@return LayoutConfig
local function default_layout_config()
    return {
        mode = "flex",
        direction = "row",
        justify = "start",
        align = "start",
        gap = 0,
        padding = { top = 0, right = 0, bottom = 0, left = 0 },
        sizing_width = "explicit",
        sizing_height = "explicit",
    }
end

---@return LayoutChildConfig
local function default_child_config()
    return {
        anchor = nil,
        dock = nil,
        grow = 0,
        shrink = 0,
        align_self = nil,
    }
end

-- Parse anchor string to x,y factors (0-1)
---@param anchor LayoutAnchor
---@return number ax, number ay
local function parse_anchor(anchor)
    local anchors = {
        ["top-left"] = {0, 0},
        ["top"] = {0.5, 0},
        ["top-right"] = {1, 0},
        ["left"] = {0, 0.5},
        ["center"] = {0.5, 0.5},
        ["right"] = {1, 0.5},
        ["bottom-left"] = {0, 1},
        ["bottom"] = {0.5, 1},
        ["bottom-right"] = {1, 1},
    }
    local a = anchors[anchor] or {0, 0}
    return a[1], a[2]
end

-- Align a child on cross axis
---@param child_size number
---@param align LayoutAlign
---@param available_space number
---@param padding_start number
---@return number position
local function align_on_axis(child_size, align, available_space, padding_start)
    if align == "start" then
        return padding_start
    elseif align == "center" then
        return padding_start + (available_space - child_size) / 2
    elseif align == "end" then
        return padding_start + available_space - child_size
    else -- stretch handled separately
        return padding_start
    end
end

---@param node BaseNode
local function mark_layout_dirty(node)
    LayoutPlugin._dirty_nodes[node] = true
    LayoutPlugin._dirty = true

    if node.parent and node.parent._layout then
        local parent_layout = node.parent._layout
        if parent_layout.sizing_width == "content" or parent_layout.sizing_height == "content" then
            mark_layout_dirty(node.parent)
        end
    end
end

---@param node BaseNode
local function measure_node(node)
    local layout = node._layout
    if not layout then return end

    local needs_width_measure = layout.sizing_width == "content"
    local needs_height_measure = layout.sizing_height == "content"

    if not needs_width_measure and not needs_height_measure then
        return
    end

    -- first, recursively measure children that have layout
    for _, child in ipairs(node.children) do
        if child._layout then
            measure_node(child)
        end
    end

    local content_w, content_h = 0, 0
    local is_row = layout.direction == "row"
    local child_count = #node.children

    if layout.mode == "flex" then
        for _, child in ipairs(node.children) do
            local cw = child.width or 0
            local ch = child.height or 0

            if is_row then
                content_w = content_w + cw
                content_h = math.max(content_h, ch)
            else
                content_w = math.max(content_w, cw)
                content_h = content_h + ch
            end
        end

        -- add gaps
        if child_count > 1 then
            if is_row then
                content_w = content_w + layout.gap * (child_count - 1)
            else
                content_h = content_h + layout.gap * (child_count - 1)
            end
        end
    elseif layout.mode == "anchor" then
        -- for anchor mode, find bounding box of all children
        for _, child in ipairs(node.children) do
            local cfg = child._layout_child or default_child_config()
            local cw = child.width or 0
            local ch = child.height or 0

            -- if docked to fill, don't count toward content size
            if not cfg.dock or cfg.dock ~= "fill" then
                content_w = math.max(content_w, cw)
                content_h = math.max(content_h, ch)
            end
        end
    end

    -- apply padding
    content_w = content_w + layout.padding.left + layout.padding.right
    content_h = content_h + layout.padding.top + layout.padding.bottom

    -- update dimensions (directly, avoiding recursive dirty marking)
    if needs_width_measure then
        node.width = content_w
    end
    if needs_height_measure then
        node.height = content_h
    end
end

---@param node BaseNode
local function arrange_flex(node)
    local layout = node._layout
    local children = node.children
    local is_row = layout.direction == "row"

    local avail_w = node.width - layout.padding.left - layout.padding.right
    local avail_h = node.height - layout.padding.top - layout.padding.bottom

    -- calculate total child size and grow factors
    local total_size = 0
    local total_grow = 0
    local child_count = #children

    for _, child in ipairs(children) do
        local cfg = child._layout_child or default_child_config()
        local size = is_row and (child.width or 0) or (child.height or 0)
        total_size = total_size + size
        total_grow = total_grow + (cfg.grow or 0)
    end

    -- add gaps to total size
    if child_count > 1 then
        total_size = total_size + layout.gap * (child_count - 1)
    end

    -- calculate extra space and grow distribution
    local main_axis = is_row and avail_w or avail_h
    local extra_space = math.max(0, main_axis - total_size)
    local grow_unit = total_grow > 0 and extra_space / total_grow or 0

    -- starting position
    local pos = is_row and layout.padding.left or layout.padding.top
    local justify = layout.justify

    -- apply justify offset for start position
    if justify == "center" then
        pos = pos + extra_space / 2
    elseif justify == "end" then
        pos = pos + extra_space
    end

    -- space between/around calculation
    local space_between = 0
    if justify == "space-between" and child_count > 1 then
        space_between = extra_space / (child_count - 1)
    elseif justify == "space-around" and child_count > 0 then
        space_between = extra_space / child_count
        pos = pos + space_between / 2
    end

    -- position each child
    for _, child in ipairs(children) do
        local cfg = child._layout_child or default_child_config()
        local child_main_size = is_row and (child.width or 0) or (child.height or 0)
        local child_cross_size = is_row and (child.height or 0) or (child.width or 0)

        -- apply grow factor
        if cfg.grow and cfg.grow > 0 and grow_unit > 0 then
            local grow_amount = grow_unit * cfg.grow
            child_main_size = child_main_size + grow_amount
            if is_row then
                child.width = child_main_size
            else
                child.height = child_main_size
            end
        end

        -- determine alignment for this child
        local align = cfg.align_self or layout.align
        local cross_avail = is_row and avail_h or avail_w
        local cross_padding = is_row and layout.padding.top or layout.padding.left

        -- handle stretch
        if align == "stretch" then
            if is_row then
                child.height = cross_avail
            else
                child.width = cross_avail
            end
            child_cross_size = cross_avail
        end

        local cross_pos = align_on_axis(child_cross_size, align, cross_avail, cross_padding)

        -- Set position
        if is_row then
            child.x = pos
            child.y = cross_pos
        else
            child.x = cross_pos
            child.y = pos
        end

        -- Advance position
        pos = pos + child_main_size + layout.gap

        -- Add space-between/around
        if justify == "space-between" or justify == "space-around" then
            pos = pos + space_between
        end
    end
end

---@param node BaseNode
local function arrange_anchor(node)
    local layout = node._layout
    local avail_w = node.width - layout.padding.left - layout.padding.right
    local avail_h = node.height - layout.padding.top - layout.padding.bottom

    for _, child in ipairs(node.children) do
        local cfg = child._layout_child or default_child_config()
        local dock = cfg.dock
        local anchor = cfg.anchor or "top-left"

        if dock then
            -- Dock mode
            if dock == "fill" then
                child.x = layout.padding.left
                child.y = layout.padding.top
                child.width = avail_w
                child.height = avail_h
            elseif dock == "top" then
                child.x = layout.padding.left
                child.y = layout.padding.top
                child.width = avail_w
            elseif dock == "bottom" then
                child.x = layout.padding.left
                child.y = node.height - layout.padding.bottom - (child.height or 0)
                child.width = avail_w
            elseif dock == "left" then
                child.x = layout.padding.left
                child.y = layout.padding.top
                child.height = avail_h
            elseif dock == "right" then
                child.x = node.width - layout.padding.right - (child.width or 0)
                child.y = layout.padding.top
                child.height = avail_h
            end
        else
            -- Anchor mode
            local ax, ay = parse_anchor(anchor)
            local cw = child.width or 0
            local ch = child.height or 0
            child.x = layout.padding.left + (avail_w - cw) * ax
            child.y = layout.padding.top + (avail_h - ch) * ay
        end
    end
end

---@param node BaseNode
local function layout_node(node)
    local layout = node._layout
    if not layout then return end

    -- measure phase (content sizing)
    measure_node(node)

    -- arrange phase
    if layout.mode == "flex" then
        arrange_flex(node)
    elseif layout.mode == "anchor" then
        arrange_anchor(node)
    end
end

---@class LayoutBuilder
---@field _node BaseNode
---@field SetMode fun(mode: LayoutMode): LayoutBuilder
---@field SetDirection fun(direction: LayoutDirection): LayoutBuilder
---@field SetJustify fun(justify: LayoutJustify): LayoutBuilder
---@field SetAlign fun(align: LayoutAlign): LayoutBuilder
---@field SetGap fun(gap: number): LayoutBuilder
---@field SetPadding fun(top: number?, right: number?, bottom: number?, left: number?): LayoutBuilder
---@field SetSizing fun(width_sizing: LayoutSizing, height_sizing: LayoutSizing?): LayoutBuilder

---@param node BaseNode
---@return LayoutBuilder
local function create_layout_builder(node)
    local builder = { _node = node }

    ---@param mode LayoutMode
    ---@return LayoutBuilder
    function builder.SetMode(mode)
        node._layout.mode = mode
        mark_layout_dirty(node)
        return builder
    end

    ---@param direction LayoutDirection
    ---@return LayoutBuilder
    function builder.SetDirection(direction)
        node._layout.direction = direction
        mark_layout_dirty(node)
        return builder
    end

    ---@param justify LayoutJustify
    ---@return LayoutBuilder
    function builder.SetJustify(justify)
        node._layout.justify = justify
        mark_layout_dirty(node)
        return builder
    end

    ---@param align LayoutAlign
    ---@return LayoutBuilder
    function builder.SetAlign(align)
        node._layout.align = align
        mark_layout_dirty(node)
        return builder
    end

    ---@param gap number
    ---@return LayoutBuilder
    function builder.SetGap(gap)
        node._layout.gap = gap
        mark_layout_dirty(node)
        return builder
    end

    ---@param top number|{ top: number?, right: number?, bottom: number?, left: number? }
    ---@param right number?
    ---@param bottom number?
    ---@param left number?
    ---@return LayoutBuilder
    function builder.SetPadding(top, right, bottom, left)
        if type(top) == "table" then
            node._layout.padding = {
                top = top.top or top[1] or 0,
                right = top.right or top[2] or top[1] or 0,
                bottom = top.bottom or top[3] or top[1] or 0,
                left = top.left or top[4] or top[2] or top[1] or 0,
            }
        else
            node._layout.padding = {
                top = top or 0,
                right = right or top or 0,
                bottom = bottom or top or 0,
                left = left or right or top or 0,
            }
        end
        mark_layout_dirty(node)
        return builder
    end

    ---@param width_sizing LayoutSizing
    ---@param height_sizing LayoutSizing?
    ---@return LayoutBuilder
    function builder.SetSizing(width_sizing, height_sizing)
        node._layout.sizing_width = width_sizing
        node._layout.sizing_height = height_sizing or width_sizing
        mark_layout_dirty(node)
        return builder
    end

    return builder
end

---@class LayoutChildBuilder
---@field _node BaseNode
---@field SetAnchor fun(anchor: LayoutAnchor): LayoutChildBuilder
---@field SetDock fun(dock: LayoutDock): LayoutChildBuilder
---@field SetGrow fun(grow: number): LayoutChildBuilder
---@field SetShrink fun(shrink: number): LayoutChildBuilder
---@field SetAlignSelf fun(align: LayoutAlign): LayoutChildBuilder

---@param node BaseNode
---@return LayoutChildBuilder
local function create_child_builder(node)
    local builder = { _node = node }

    ---@param anchor LayoutAnchor
    ---@return LayoutChildBuilder
    function builder.SetAnchor(anchor)
        node._layout_child.anchor = anchor
        node._layout_child.dock = nil  -- anchor and dock are mutually exclusive
        if node.parent then mark_layout_dirty(node.parent) end
        return builder
    end

    ---@param dock LayoutDock
    ---@return LayoutChildBuilder
    function builder.SetDock(dock)
        node._layout_child.dock = dock
        node._layout_child.anchor = nil  -- anchor and dock are mutually exclusive
        if node.parent then mark_layout_dirty(node.parent) end
        return builder
    end

    ---@param grow number
    ---@return LayoutChildBuilder
    function builder.SetGrow(grow)
        node._layout_child.grow = grow
        if node.parent then mark_layout_dirty(node.parent) end
        return builder
    end

    ---@param shrink number
    ---@return LayoutChildBuilder
    function builder.SetShrink(shrink)
        node._layout_child.shrink = shrink
        if node.parent then mark_layout_dirty(node.parent) end
        return builder
    end

    ---@param align LayoutAlign
    ---@return LayoutChildBuilder
    function builder.SetAlignSelf(align)
        node._layout_child.align_self = align
        if node.parent then mark_layout_dirty(node.parent) end
        return builder
    end

    return builder
end

---@param node BaseNode
---@return LayoutBuilder
function LayoutPlugin.InstallTo(node)
    if node.plugins[LayoutPlugin] then
        return create_layout_builder(node)
    end

    ---@class BaseNode
    ---@field _layout LayoutConfig
    ---@field _layout_child LayoutChildConfig
    ---@field _on_size_changed fun(self): nil
    ---@field _on_content_size_changed fun(self,w,h): nil

    node.plugins[LayoutPlugin] = true
    LayoutPlugin._nodes[node] = true
    node._layout = default_layout_config()

    local __og_AddChild = node.AddChild
    node.AddChild = function(self, child)
        __og_AddChild(self, child)
        if not child._layout_child then
            child._layout_child = default_child_config()
        end
        mark_layout_dirty(self)
    end

    local __og_RemoveChild = node.RemoveChild
    node.RemoveChild = function(self, child)
        local result = __og_RemoveChild(self, child)
        if result then
            mark_layout_dirty(self)
        end
        return result
    end

    node._on_size_changed = function(self)
        mark_layout_dirty(self)
    end

    node._on_content_size_changed = function(self, w, h)
        if self._layout and (self._layout.sizing_width == "content" or self._layout.sizing_height == "content") then
            mark_layout_dirty(self)
        end
        if self.parent and self.parent._layout then
            mark_layout_dirty(self.parent)
        end
    end

    local __og_Destroy = node.Destroy
    node.Destroy = function(self)
        LayoutPlugin.UninstallFrom(self)
        return __og_Destroy(self)
    end

    mark_layout_dirty(node)
    local lb = create_layout_builder(node)

    return lb
end

---@param node BaseNode
---@return LayoutChildBuilder
function LayoutPlugin.Configure(node)
    if not node._layout_child then
        node._layout_child = default_child_config()
    end
    local clb = create_child_builder(node)

    return clb
end

---@param node BaseNode
function LayoutPlugin.UninstallFrom(node)
    if not node.plugins[LayoutPlugin] then
        return
    end

    node.plugins[LayoutPlugin] = nil
    LayoutPlugin._nodes[node] = nil
    LayoutPlugin._dirty_nodes[node] = nil
    node._layout = nil
end

function LayoutPlugin.UninstallFromAll()
    for node in pairs(LayoutPlugin._nodes) do
        LayoutPlugin.UninstallFrom(node)
    end
end

-- manually trigger layout refresh for a node
---@param node BaseNode
function LayoutPlugin.Refresh(node)
    if node._layout then
        mark_layout_dirty(node)
    end
end

-- mark the plugin as dirty (forces recalculation)
function LayoutPlugin.MarkDirty()
    LayoutPlugin._dirty = true
end

-- process all dirty layouts
---@param dt number
function LayoutPlugin.Update(dt)
    if not LayoutPlugin._dirty then
        return
    end

    -- Process dirty nodes
    -- we need to process parents before children for proper sizing cascade
    -- but for content sizing, we need children measured first
    -- solution: separate measure and arrange passes

    -- collect root layout nodes (nodes without layout parents)
    local roots = {}
    for node in pairs(LayoutPlugin._dirty_nodes) do
        local isRoot = true
        local p = node.parent
        while p do
            if p._layout then
                isRoot = false
                break
            end
            p = p.parent
        end
        if isRoot then
            roots[node] = true
        end
    end

    -- process each root. recursively handle children
    for node in pairs(roots) do
        layout_node(node)
    end

    LayoutPlugin._dirty_nodes = {}
    LayoutPlugin._dirty = false
end

return LayoutPlugin

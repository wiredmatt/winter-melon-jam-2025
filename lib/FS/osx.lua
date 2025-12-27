return function (filesystem)
    local ffi = require("ffi")

    ffi.cdef[[
        struct dirent {
            uint64_t d_ino;
            uint64_t d_seekoff;
            uint16_t d_reclen;
            uint16_t d_namlen;
            uint8_t  d_type;
            char     d_name[1024];
        };
    ]]

    ffi.cdef[[
            struct DIR *opendir(const char *name);
            struct dirent *readdir(struct DIR *dirstream);
            int closedir (struct DIR *dirstream);
    ]]

    local function join(tb1, tb2, tb3)
        local tb = {}
        for _,v in ipairs(tb1) do table.insert(tb, v) end
        for _,v in ipairs(tb2) do table.insert(tb, v) end
        for _,v in ipairs(tb3) do table.insert(tb, v) end
        return tb
    end

    local function removevalue(tb, value)
        for n = #tb, 1, -1 do
            if value == 'hidden' then
                if tb[n]:match('^%..') then table.remove(tb, n) end
            else
                if tb[n] == value then table.remove(tb, n) end
            end
        end
    end

    function filesystem:AbsPath(path)
        if path == '.' then path = self.current end
        if (path:sub(1,2) == '.'..self.sep) then path = self.current..path:sub(2) end
        if not (path:sub(1,1) == '/') then path = self.current..self.sep..path end
        path = path:gsub('\\', self.sep)
        path = path:gsub(self.sep..self.sep, self.sep)
        if #path > 1 and path:sub(-1) == self.sep then path = path:sub(1, -2) end
        return path
    end

    function filesystem:Ls(dir)
        dir = dir or self.current
        dir = self:AbsPath(dir)
        local tdirs, tfiles, tothers = {}, {}, {}
        local hdir = ffi.C.opendir(dir)
        if hdir ~= nil then
            while true do
                local dirent = ffi.C.readdir(hdir)
                if dirent == nil then break end
                local fn = ffi.string(dirent.d_name)
                if dirent.d_type == 4 then
                    table.insert(tdirs, fn)
                elseif dirent.d_type == 8 then
                    table.insert(tfiles, fn)
                else
                    table.insert(tothers, fn)
                end
            end
            ffi.C.closedir(hdir)
        end
        if #tdirs == 0 then return false end
        removevalue(tdirs, '.')
        removevalue(tdirs, '..')
        if not self.show_hidden then removevalue(tdirs, 'hidden') end
        table.sort(tdirs)

        if self.filter then
            for n = #tfiles, 1, -1 do
                local ext = tfiles[n]:match('[^.]+$')
                local valid = false
                for _, v in ipairs(self.filter) do
                    valid = valid or (ext == v)
                end
                if not valid then table.remove(tfiles, n) end
            end
        end
        if not self.show_hidden then
            removevalue(tfiles, 'hidden')
            removevalue(tothers, 'hidden')
        end
        table.sort(tfiles)
        table.sort(tothers)
        return dir, tdirs, tfiles, tothers, join(tdirs, tfiles, tothers)
    end

    function filesystem:UpdDrives()
        local drives = {}
        local dir, dirs = self:Ls('/Volumes')
        if dir and dirs then
            for n, d in ipairs(dirs) do dirs[n] = '/Volumes/'..dirs[n] end
            drives = dirs
        end
        table.insert(drives, 1, '/')
        self.drives = drives
    end

    function filesystem:copy(source, dest)
        local inp = assert(io.open(source, "rb"))
        local out = assert(io.open(dest, "wb"))
        local data = inp:read("*all")
        out:write(data)
        assert(out:close())
    end

    --https://github.com/3scale/luafilesystem-ffi/blob/master/lfs_ffi.lua
    ------------------------------ stat ------------------------------------
    MAXPATH = 1024
    local bit = require("bit")
    local band, bnot, rshift = bit.band, bit.bnot, bit.rshift
    local concat = table.concat

    local has_table_new, new_tab = pcall(require, "table.new")
    if not has_table_new or type(new_tab) ~= "function" then
        new_tab = function (...) return {} end
    end

    local stat_func
    local lstat_func

    ffi.cdef[[
        struct timespec {
            long tv_sec;
            long tv_nsec;
        };
        struct stat {
            uint32_t          st_dev;
            uint16_t          st_mode;
            uint16_t          st_nlink;
            uint64_t          st_ino;
            uint32_t          st_uid;
            uint32_t          st_gid;
            uint32_t          st_rdev;
            struct timespec   st_atimespec;
            struct timespec   st_mtimespec;
            struct timespec   st_ctimespec;
            struct timespec   st_birthtimespec;
            int64_t           st_size;
            int64_t           st_blocks;
            int32_t           st_blksize;
            uint32_t          st_flags;
            uint32_t          st_gen;
            int32_t           st_lspare;
            int64_t           st_qspare[2];
        };
        int stat(const char *path, struct stat *buf);
        int lstat(const char *path, struct stat *buf);
    ]]

    stat_func = ffi.C.stat
    lstat_func = ffi.C.lstat

    local STAT = {
        FMT   = 0xF000,
        FSOCK = 0xC000,
        FLNK  = 0xA000,
        FREG  = 0x8000,
        FBLK  = 0x6000,
        FDIR  = 0x4000,
        FCHR  = 0x2000,
        FIFO  = 0x1000,
    }

    local ftype_name_map = {
        [STAT.FREG]  = 'file',
        [STAT.FDIR]  = 'directory',
        [STAT.FLNK]  = 'link',
        [STAT.FSOCK] = 'socket',
        [STAT.FCHR]  = 'char device',
        [STAT.FBLK]  = "block device",
        [STAT.FIFO]  = "named pipe",
    }

    ffi.cdef([[
        char* strerror(int errnum);
    ]])

    local function errno()
        return ffi.string(ffi.C.strerror(ffi.errno()))
    end

    local function mode_to_ftype(mode)
        local ftype = band(mode, STAT.FMT)
        return ftype_name_map[ftype] or 'other'
    end

    local function mode_to_perm(mode)
        local perm_bits = band(mode, tonumber("777", 8))
        local perm = new_tab(9, 0)
        local i = 9
        while i > 0 do
            local perm_bit = band(perm_bits, 7)
            perm[i] = (band(perm_bit, 1) > 0 and 'x' or '-')
            perm[i-1] = (band(perm_bit, 2) > 0 and 'w' or '-')
            perm[i-2] = (band(perm_bit, 4) > 0 and 'r' or '-')
            i = i - 3
            perm_bits = rshift(perm_bits, 3)
        end
        return concat(perm)
    end

    local function time_or_timespec(time, timespec)
        local t = tonumber(time)
        if not t and timespec then
            t = tonumber(timespec.tv_sec)
        end
        return t
    end

    local attr_handlers = {
        access = function(st) return time_or_timespec(st.st_atime, st.st_atimespec) end,
        blksize = function(st) return tonumber(st.st_blksize) end,
        blocks = function(st) return tonumber(st.st_blocks) end,
        change = function(st) return time_or_timespec(st.st_ctime, st.st_ctimespec) end,
        dev = function(st) return tonumber(st.st_dev) end,
        gid = function(st) return tonumber(st.st_gid) end,
        ino = function(st) return tonumber(st.st_ino) end,
        mode = function(st) return mode_to_ftype(st.st_mode) end,
        modification = function(st) return time_or_timespec(st.st_mtime, st.st_mtimespec) end,
        nlink = function(st) return tonumber(st.st_nlink) end,
        permissions = function(st) return mode_to_perm(st.st_mode) end,
        rdev = function(st) return tonumber(st.st_rdev) end,
        size = function(st) return tonumber(st.st_size) end,
        uid = function(st) return tonumber(st.st_uid) end,
    }

    -- Add target field for symlinkattributes, which is the absolute path of linked target
    local get_link_target_path

    ffi.cdef('unsigned long readlink(const char *path, char *buf, size_t bufsize);')
    function get_link_target_path(link_path)
        local size = MAXPATH
        while true do
            local buf = ffi.new('char[?]', 512)
            local read = ffi.C.readlink(link_path, buf, size)
            if read == -1 then
                return nil, errno()
            end
            if read < size then
                return ffi.string(buf)
            end
            size = size * 2
        end
    end

    local mt = {
        __index = function(self, attr_name)
            local func = attr_handlers[attr_name]
            return func and func(self)
        end
    }
    local stat_type = ffi.metatype('struct stat', mt)

    local function attributes(filepath, attr, follow_symlink)
        local buf = ffi.new("struct stat[1]")
        local func = follow_symlink and stat_func or lstat_func
        if func(filepath, buf) == -1 then
            return nil, errno()
        end
        local st = buf[0]
        local atype = type(attr)
        if atype == 'string' then
            if attr == 'target' and not follow_symlink then
                return get_link_target_path(filepath)
            end
            local handler = attr_handlers[attr]
            if not handler then error("invalid attribute name '" .. attr .. "'") end
            return handler(st)
        else
            local tab = (atype == 'table') and attr or {}
            for k, f in pairs(attr_handlers) do
                tab[k] = f(st)
            end
            if not follow_symlink then
                tab.target = get_link_target_path(filepath)
            end
            return tab
        end
    end

    function filesystem:attr(filepath, attr, follow_symlink)
        if(follow_symlink == nil) then follow_symlink = false end
        return attributes(filepath, attr, follow_symlink)
    end
    ------------------------------ end stat --------------------------------
end
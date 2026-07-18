-- Pure-Lua fallback for the native `env` module.
-- Provides the subset needed for seed generation (create_directory, join_path,
-- file_exists, operating_system) plus optional extras for the full runner.

local env_lua = {}

-- Simple path join with '/' separator
function env_lua.join_path(...)
    local parts = {...}
    local result = ""
    for i, p in ipairs(parts) do
        if i > 1 and result ~= "" and not result:match("/$") then
            result = result .. "/"
        end
        result = result .. p
    end
    return result
end

-- Check if a file or directory exists
function env_lua.file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Create a directory (equivalent to mkdir -p)
function env_lua.create_directory(path)
    os.execute('mkdir -p "' .. path .. '"')
end

-- Return the operating system name
function env_lua.operating_system()
    local uname = io.popen("uname -s 2>/dev/null"):read("*l") or ""
    io.popen():close()  -- close any pending popen
    if uname:match("Darwin") then
        return "macos"
    elseif uname:match("Linux") then
        return "linux"
    elseif uname:match("MINGW") or uname:match("MSYS") or uname:match("CYGWIN") then
        return "win32"
    else
        return "linux"  -- default
    end
end

-- Monotonic clock in seconds (for timing)
function env_lua.monotonic_clock()
    -- Lua's os.clock() is CPU time, we want wall time
    -- Use a simple approach: read /proc/uptime or use a cached start time
    local f = io.popen("date +%s.%N 2>/dev/null || python3 -c 'import time; print(time.time())' 2>/dev/null || date +%s")
    local t = f:read("*l")
    f:close()
    return tonumber(t) or os.time()
end

-- Number of processors
function env_lua.processor_count()
    local f = io.popen("nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4")
    local n = f:read("*l")
    f:close()
    return math.max(1, tonumber(n) or 4)
end

-- Spawn a background process. Returns a handle for wait_for_background_process.
-- This is a simplified version using shell job control.
function env_lua.spawn_background_process(command)
    local pid = io.popen(command .. " & echo $!")
    local handle = pid:read("*l")
    pid:close()
    return handle
end

-- Wait for a background process. Returns handle, success (boolean).
-- In this pure-Lua fallback, we poll with `wait`.
function env_lua.wait_for_background_process()
    -- Non-blocking check for any finished child
    local f = io.popen("wait -n 2>/dev/null; echo $?,$!")
    local result = f:read("*l") or ""
    f:close()
    if result == "" then
        return nil  -- no children or not supported
    end
    local exit_code, handle = result:match("^(%d+),?(.*)$")
    return handle ~= "" and handle or "unknown", tonumber(exit_code) == 0
end

return env_lua

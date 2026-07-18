-- Pure-Lua fallback for the native `zip` module.
-- Extracts the entire zip archive to a temp directory on first access, then
-- reads files from the filesystem. Much faster than per-file `unzip -p` calls.

local zip_lua = {}

-- Cache: archive_path -> temp_dir
local extracted_dirs = {}

-- Extract a single file from a zip archive, returning its contents as a string.
function zip_lua.extract(archive_path, internal_path)
    -- Check if we've already extracted this archive
    local tmpdir = extracted_dirs[archive_path]
    if not tmpdir then
        -- Extract the whole archive to a temp directory
        tmpdir = os.tmpname() .. "_se"
        os.execute('mkdir -p "' .. tmpdir .. '"')
        local ok = os.execute('unzip -q -o "' .. archive_path .. '" -d "' .. tmpdir .. '" 2>/dev/null')
        if ok ~= 0 and ok ~= true then
            -- Try to check exit code (Lua os.execute returns varied types)
            -- Fall back to per-file extraction if bulk extract fails
            tmpdir = nil
        end
        if tmpdir then
            extracted_dirs[archive_path] = tmpdir
        end
    end

    if tmpdir then
        -- Read from extracted directory
        local f = io.open(tmpdir .. "/" .. internal_path, "rb")
        if f then
            local data = f:read("*a")
            f:close()
            return data
        end
    end

    -- Fallback: per-file extraction
    local cmd = 'unzip -p "' .. archive_path .. '" "' .. internal_path .. '" 2>/dev/null'
    local f = io.popen(cmd, "r")
    if not f then
        return nil, "cannot execute unzip"
    end
    local data = f:read("*a")
    local exit_ok = ({f:close()})[3] == 0
    if not exit_ok then
        return nil, "unzip failed for " .. internal_path
    end
    return data
end

return zip_lua

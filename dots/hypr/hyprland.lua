local home   = os.getenv("HOME")
local hypr   = home .. "/.config/hypr"
package.path = package.path .. ";" .. home .. "/.config/hypr/?.lua"

-- Create a file if it doesn't exist, optionally with initial content
local function maybe_create(file, content)
    local f = io.open(file)

    if f then
        f:close()
        return
    end

    f = io.open(file, "w")
    if f then
        if content then f:write(content) end
        f:close()
    end
end

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
    local out = io.open(dst)
    if out then
        out:close()
        return
    end

    local input = io.open(src, "r")
    if not input then return end

    out = io.open(dst, "w")
    if out then
        out:write(input:read("*a"))
        out:close()
    end
    input:close()
end

-- Maybe set current colours to defaults
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

-- User variables
maybe_create(home .. "/.config/hypr/hypr-vars.lua", "return {}\n")
local ok, overrides = pcall(require, "hypr-vars")
if ok and type(overrides) == "table" then
    local vars = require("variables")
    for k, v in pairs(overrides) do
        vars[k] = v
    end
end

-- Default monitor conf
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Persistent monitor configuration
pcall(require, "monitors")

-- Safe loader so a failure in an individual subsystem (e.g. gestures or decorations)
-- never aborts config loading and never leaves Hyprland in emergency mode without binds.
local function safe_require(module)
    local ok, err = pcall(require, module)
    if not ok then
        io.stderr:write("[Hyprland Lua] Error loading " .. module .. ": " .. tostring(err) .. "\n")
    end
    return ok
end

-- Configs
safe_require("hyprland.env")
safe_require("hyprland.general")
safe_require("hyprland.input")
safe_require("hyprland.misc")
safe_require("hyprland.animations")
safe_require("hyprland.decoration")
safe_require("hyprland.group")
safe_require("hyprland.execs")
safe_require("hyprland.rules")
safe_require("hyprland.gestures")
safe_require("hyprland.keybinds")

-- User configs
-- maybe_create(home .. "/.config/hypr/hypr-user.lua")
-- require("hypr-user")

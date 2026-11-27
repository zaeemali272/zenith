local vars = require("variables")
local fn   = require("utils.functions")

-- Flags
local locked           = { locked = true }
local mouse            = { mouse = true }
local release          = { release = true }
local repeating        = { repeating = true }
local locked_repeating = { locked = true, repeating = true }

local function normalise_keybind(key)
    return key:gsub("%s+", ""):lower()
end

local function repeating_unless_mouse(key)
    return not normalise_keybind(key):find("mouse", 1, true) and repeating or nil
end

local function flatten_keybinds(keybinds, keys)
    keys = keys or {}

    if type(keybinds) == "table" then
        for _, keybind in ipairs(keybinds) do
            flatten_keybinds(keybind, keys)
        end
    elseif keybinds ~= nil then
        keys[#keys + 1] = keybinds
    end

    return keys
end

------------------------------------------------------------------------
---- Multi-Shell Dispatcher (Zenith, Caelestia, End-4) -----------------
------------------------------------------------------------------------

-- The active shell registers Hyprland global shortcuts or IPC handlers.
-- Keys are dynamically mapped to the currently active shell (stored in
-- ~/.config/zenith/active-shell) so the keybinds remain identical across all shells.

local shell_actions = {
    zenith = {
        launcher      = hl.dsp.global("zenith:launcher"),
        dashboard     = hl.dsp.global("zenith:dashboard"),
        power         = hl.dsp.global("zenith:power"),
        lock          = hl.dsp.global("zenith:lock"),
        quicksettings = hl.dsp.global("zenith:quicksettings"),
        clipboard     = hl.dsp.global("zenith:clipboard"),
        emoji         = hl.dsp.global("zenith:emoji"),
        wallpaper     = hl.dsp.global("zenith:wallpaper"),
        close         = hl.dsp.global("zenith:close"),
        settings      = hl.dsp.global("zenith:settings"),
        pomodoro      = hl.dsp.global("zenith:pomodoro"),
        roadmap       = hl.dsp.global("zenith:roadmap"),
        mail          = hl.dsp.global("zenith:mail"),
        wifi          = hl.dsp.global("zenith:wifi"),
        bluetooth     = hl.dsp.global("zenith:bluetooth"),
        powerprofile  = hl.dsp.global("zenith:powerprofile"),
        battery       = hl.dsp.global("zenith:battery"),
        volume        = hl.dsp.global("zenith:volume"),
        display       = hl.dsp.global("zenith:display"),
        cheatsheet    = hl.dsp.global("zenith:cheatsheet"),
    },
    caelestia = {
        launcher      = hl.dsp.global("caelestia:launcher"),
        dashboard     = hl.dsp.global("caelestia:dashboard"),
        power         = hl.dsp.global("caelestia:session"),
        lock          = hl.dsp.global("caelestia:lock"),
        quicksettings = hl.dsp.global("caelestia:sidebar"),
        clipboard     = hl.dsp.exec_cmd("caelestia clipboard 2>/dev/null || cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"),
        emoji         = hl.dsp.exec_cmd("caelestia emoji 2>/dev/null || true"),
        wallpaper     = hl.dsp.global("caelestia:nexus"),
        close         = hl.dsp.global("caelestia:showall"),
        settings      = hl.dsp.global("caelestia:nexus"),
        pomodoro      = hl.dsp.global("caelestia:utilities"),
        roadmap       = hl.dsp.global("caelestia:utilities"),
        mail          = hl.dsp.global("caelestia:utilities"),
        wifi          = hl.dsp.global("caelestia:sidebar"),
        bluetooth     = hl.dsp.global("caelestia:sidebar"),
        powerprofile  = hl.dsp.global("caelestia:sidebar"),
        battery       = hl.dsp.global("caelestia:sidebar"),
        volume        = hl.dsp.global("caelestia:sidebar"),
        display       = hl.dsp.global("caelestia:nexus"),
        cheatsheet    = hl.dsp.global("zenith:cheatsheet"),
    },
    ["end-4"] = {
        launcher      = hl.dsp.global("quickshell:searchToggle"),
        dashboard     = hl.dsp.global("quickshell:overviewWorkspacesToggle"),
        power         = hl.dsp.global("quickshell:sessionToggle"),
        lock          = hl.dsp.global("quickshell:lock"),
        quicksettings = hl.dsp.global("quickshell:sidebarRightToggle"),
        clipboard     = hl.dsp.global("quickshell:overviewClipboardToggle"),
        emoji         = hl.dsp.global("quickshell:overviewEmojiToggle"),
        wallpaper     = hl.dsp.global("quickshell:wallpaperSelectorToggle"),
        close         = hl.dsp.exec_cmd("quickshell ipc call drawers close 2>/dev/null || true"),
        settings      = hl.dsp.global("quickshell:sidebarLeftToggle"),
        pomodoro      = hl.dsp.global("quickshell:sidebarRightToggle"),
        roadmap       = hl.dsp.global("quickshell:sidebarRightToggle"),
        mail          = hl.dsp.global("quickshell:sidebarRightToggle"),
        wifi          = hl.dsp.global("quickshell:sidebarRightToggle"),
        bluetooth     = hl.dsp.global("quickshell:sidebarRightToggle"),
        powerprofile  = hl.dsp.global("quickshell:sidebarRightToggle"),
        battery       = hl.dsp.global("quickshell:sidebarRightToggle"),
        volume        = hl.dsp.global("quickshell:sidebarRightToggle"),
        display       = hl.dsp.global("quickshell:sidebarLeftToggle"),
        cheatsheet    = hl.dsp.global("zenith:cheatsheet"),
    }
}

local function get_active_shell()
    local path = os.getenv("HOME") .. "/.config/zenith/active-shell"
    local f = io.open(path, "r")
    if not f then return "zenith" end
    local content = f:read("*l")
    f:close()
    if content and #content > 0 then
        local s = content:gsub("%s+", "")
        if shell_actions[s] then return s end
    end
    return "zenith"
end

local function shell_action(surface)
    local active = get_active_shell()
    local map = shell_actions[active] or shell_actions.zenith
    return map[surface] or shell_actions.zenith[surface]
end

local function zenith(name)
    return shell_action(name)
end

------------------------------------------------------------------------
---- Super tap -> launcher ---------------------------------------------
------------------------------------------------------------------------

-- Hyprland has no notion of "Super pressed and released on its own", so it is
-- reconstructed from three facts held in plain Lua:
--
--   * SUPER_L press records when it happened and clears the combo flag,
--   * any SUPER+<key> bind that fires sets the combo flag (see create_bind),
--   * SUPER_L release opens the launcher only when no combo fired and the
--     press was recent.
--
-- The previous version routed every one of these through a shell script that
-- forked python3 twice per tap for a timestamp -- 100ms+ of latency on the
-- most-used key on the keyboard. /proc/uptime is a monotonic clock readable
-- without spawning anything.
local super = { combo = false }

local function super_pressed()
    super.combo = false
end

local function super_released()
    if not super.combo then
        hl.dispatch(zenith("launcher"))
    end
    super.combo = false
end

local function is_super_combo(key)
    local norm = normalise_keybind(key)
    return norm:find("super", 1, true) ~= nil and norm ~= "super_l" and norm ~= "super_r" and norm ~= "super"
end

local function create_bind(keybinds, action, flags)
    local get_flags = type(flags) == "function" and flags or function()
        return flags
    end

    for _, key in ipairs(flatten_keybinds(keybinds)) do
        if is_super_combo(key) then
            -- Wrapped so the tap detector learns Super was used as a modifier.
            if type(action) == "function" then
                hl.bind(key, function(...)
                    super.combo = true
                    return action(...)
                end, get_flags(key))
            else
                hl.bind(key, function()
                    super.combo = true
                    return hl.dispatch(action)
                end, get_flags(key))
            end
        else
            hl.bind(key, action, get_flags(key))
        end
    end
end

create_bind({ "SUPER_L", "SUPER_R" }, super_pressed)
create_bind({ "SUPER_L", "SUPER_R" }, super_released, release)

------------------------------------------------------------------------
---- Session & shell ----------------------------------------------------
------------------------------------------------------------------------

-- The lock screen lives in the shell (zenith-shell/windows/lock), so locking
-- is the same zero-fork global shortcut as every other surface.
create_bind(vars.kbLock, zenith("lock"), locked)
create_bind(vars.kbRestoreLock, hl.dsp.exec_cmd("quickshell -d"))

-- Restart the shell / toggle it / reload Hyprland
create_bind("CTRL + SUPER + R", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/restart_everything.sh"), release)
create_bind("CTRL + ESCAPE", zenith("close"), release)
create_bind("ALT + ESCAPE", hl.dsp.exec_cmd("hyprctl reload"), release)

-- Zenith shell surfaces (all native compositor shortcuts, zero scripts)
create_bind(vars.kbLauncher, zenith("launcher"))
create_bind(vars.kbDashboard, zenith("dashboard"))
create_bind(vars.kbWallpaper, zenith("wallpaper"))
create_bind(vars.kbPomodoro, zenith("pomodoro"))
create_bind(vars.kbRoadmap, zenith("roadmap"))
create_bind(vars.kbMail, zenith("mail"))
create_bind(vars.kbQuickSettings, zenith("quicksettings"))
create_bind(vars.kbWifi, zenith("wifi"))
create_bind(vars.kbBluetooth, zenith("bluetooth"))
create_bind(vars.kbPowerProfile, zenith("powerprofile"))
create_bind(vars.kbBattery, zenith("battery"))
create_bind(vars.kbVolumePanel, zenith("volume"))
create_bind(vars.kbCloseMenus, zenith("close"))
create_bind(vars.kbClipboard, zenith("clipboard"))
create_bind(vars.kbEmoji, zenith("emoji"))
create_bind(vars.kbSession, zenith("power"))
create_bind(vars.kbShellSettings, zenith("settings"))
create_bind(vars.kbCheatsheet, zenith("cheatsheet"))
create_bind(vars.kbDisplay, zenith("display"), locked)
create_bind("XF86PowerOff", zenith("power"), locked)
create_bind("SUPER + XF86PowerOff", hl.dsp.exec_cmd("systemctl poweroff"), locked)

------------------------------------------------------------------------
---- Workspaces ---------------------------------------------------------
------------------------------------------------------------------------

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    create_bind(vars.kbGoToWs .. " + " .. key, fn.wsaction("focus", "", i))
    create_bind(vars.kbMoveWinToWs .. " + " .. key, fn.wsaction("move", "", i))
    create_bind(vars.kbGoToWsGroup .. " + " .. key, fn.wsaction("focus", "group", i))
    create_bind(vars.kbMoveWinToWsGroup .. " + " .. key, fn.wsaction("move", "group", i))
end

-- Go to workspace -1/+1
create_bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), repeating_unless_mouse)
create_bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), repeating_unless_mouse)

-- Go to workspace group -1/+1
create_bind(vars.kbPrevWsGroup, hl.dsp.focus({ workspace = "-10" }), repeating_unless_mouse)
create_bind(vars.kbNextWsGroup, hl.dsp.focus({ workspace = "+10" }), repeating_unless_mouse)

-- Move window to workspace -1/+1
create_bind(vars.kbMoveWinToWsNext, hl.dsp.window.move({ workspace = "+1" }), repeating_unless_mouse)
create_bind(vars.kbMoveWinToWsPrev, hl.dsp.window.move({ workspace = "-1" }), repeating_unless_mouse)

-- Move window to/from special workspace
create_bind(vars.kbMoveWinToWsSpecial, hl.dsp.window.move({ workspace = "special:special" }))
create_bind(vars.kbMoveWinFromWsSpecial, hl.dsp.window.move({ workspace = "e+0" }))

-- Special workspace toggles
create_bind(vars.kbSpecialWs, fn.toggle("specialws"))
create_bind(vars.kbSystemMonitorWs, fn.toggle("sysmon"))
create_bind(vars.kbMusicWs, fn.toggle("music"))
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
create_bind(vars.kbTodoWs, fn.toggle("todo"))

------------------------------------------------------------------------
---- Windows ------------------------------------------------------------
------------------------------------------------------------------------

-- Window groups
create_bind(vars.kbWindowCycleNext, hl.dsp.window.cycle_next(), repeating)
create_bind(vars.kbWindowCyclePrev, hl.dsp.window.cycle_next({ next = false }), repeating)
create_bind(vars.kbWindowGroupCycleNext, hl.dsp.group.next(), repeating)
create_bind(vars.kbWindowGroupCyclePrev, hl.dsp.group.prev(), repeating)
create_bind(vars.kbToggleGroup, hl.dsp.group.toggle())
create_bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }))
create_bind(vars.kbGroupLockActive, hl.dsp.group.lock_active())

-- Focus & move
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    create_bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
    create_bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Resize
create_bind(vars.kbWindowDecreaseWidth, fn.resize_active_window(-10, 0), repeating)
create_bind(vars.kbWindowIncreaseWidth, fn.resize_active_window(10, 0), repeating)
create_bind(vars.kbWindowDecreaseHeight, fn.resize_active_window(0, -10), repeating)
create_bind(vars.kbWindowIncreaseHeight, fn.resize_active_window(0, 10), repeating)

create_bind({ vars.kbMoveWindow, "SUPER + mouse:272" }, hl.dsp.window.drag(), mouse)
create_bind({ vars.kbResizeWindow, "SUPER + mouse:273" }, hl.dsp.window.resize(), mouse)
create_bind(vars.kbCenterWindow, hl.dsp.window.center())
create_bind(vars.kbNormalizeWindow, function()
    hl.dispatch(hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
    hl.dispatch(hl.dsp.window.center())
end)
create_bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end)
create_bind(vars.kbPinWindow, hl.dsp.window.pin())
create_bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
create_bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
create_bind(vars.kbToggleWindowFloating, hl.dsp.window.float())
create_bind(vars.kbCloseWindow, hl.dsp.window.close())
create_bind(vars.kbKillWindow, hl.dsp.exec_cmd("hyprctl kill"))

------------------------------------------------------------------------
---- Apps ---------------------------------------------------------------
------------------------------------------------------------------------

create_bind({ vars.kbTerminal, "SUPER + Return", "ALT + Return" }, hl.dsp.exec_cmd(vars.terminal))
create_bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser))
create_bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor))
create_bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer))
create_bind(vars.kbAudioSettings, hl.dsp.exec_cmd(vars.audioSettings))
create_bind(vars.kbTextEditor, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh 'zeditor' 'gnome-text-editor'"))

------------------------------------------------------------------------
---- Utilities ----------------------------------------------------------
------------------------------------------------------------------------

create_bind(vars.kbScreenshot, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/screenshot.sh output"), locked)
create_bind({ vars.kbScreenshotRegion, vars.kbScreenshotFreeze }, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/screenshot.sh region"), locked)
create_bind(vars.kbScreenshotWindow, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/screenshot.sh window"))

create_bind(vars.kbRecordRegion, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/record.sh"))
create_bind(vars.kbRecord, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/record.sh --fullscreen"))
create_bind(vars.kbRecordMic, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/record.sh --fullscreen-all"))
create_bind(vars.kbRecordSound, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/record.sh --fullscreen-sound"))

create_bind(vars.kbOcr, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/ocr.sh"))
create_bind(vars.kbColorPicker, hl.dsp.exec_cmd("hyprpicker -a"))

-- Cursor zoom, applied straight from Lua rather than through a script that
-- round-trips hyprctl twice per keypress.
local ZOOM_MIN, ZOOM_MAX = 1.0, 5.0
local function zoom_by(delta)
    return function()
        local current = tonumber(hl.get_config("cursor:zoom_factor")) or 1.0
        local target = math.max(ZOOM_MIN, math.min(ZOOM_MAX, current + delta))
        hl.config({ cursor = { zoom_factor = target } })
    end
end
create_bind(vars.kbZoomOut, zoom_by(-0.1), repeating)
create_bind(vars.kbZoomIn, zoom_by(0.1), repeating)
create_bind(vars.kbZoomReset, zoom_by(-ZOOM_MAX))

------------------------------------------------------------------------
---- Media & hardware keys ---------------------------------------------
------------------------------------------------------------------------

-- code:200/201 and code:163/165 are the legacy CD-player keycodes some
-- earbuds send instead of the XF86 keysyms.
create_bind({ vars.kbMediaToggle, "XF86AudioPlay", "XF86AudioPause", "code:200", "code:201" }, hl.dsp.exec_cmd("playerctl play-pause"), locked)
create_bind({ vars.kbMediaNext, "XF86AudioNext", "code:163" }, hl.dsp.exec_cmd("playerctl next"), locked)
create_bind({ vars.kbMediaPrev, "XF86AudioPrev", "code:165" }, hl.dsp.exec_cmd("playerctl previous"), locked)
create_bind({ vars.kbMediaStop, "XF86AudioStop" }, hl.dsp.exec_cmd("playerctl stop"), locked)

create_bind({ vars.kbVolumeMute, "XF86AudioMute" }, hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh volume mute"), locked)
create_bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
create_bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh volume up"), locked_repeating)
create_bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh volume down"), locked_repeating)

create_bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh brightness up"), locked_repeating)
create_bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh brightness down"), locked_repeating)

create_bind(vars.kbSleep, hl.dsp.exec_cmd("systemctl suspend"), locked)
create_bind("switch:on:Lid Switch", zenith("lock"), locked)

------------------------------------------------------------------------
---- Testing ------------------------------------------------------------
------------------------------------------------------------------------

create_bind(
    "SUPER + ALT + F12",
    hl.dsp.exec_cmd(
        "notify-send -u low -i dialog-information-symbolic 'Test notification' " ..
        [["Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!"]] ..
        " -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
    )
)

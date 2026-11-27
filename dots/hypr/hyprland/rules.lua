local vars = require("variables")

-- Tags an array of window matches. If `field` is given, matches should be an
-- array of strings. Otherwise, it should be an array of tables.
local function tagged_rule(tag, matches, field)
    for _, match in ipairs(matches) do
        if field then
            local table = {}
            table[field] = match
            match = table
        end
        hl.window_rule({ match = match, tag = "+" .. tag })
    end
end

local function create_tag(tag, rules)
    local rule = { match = { tag = tag } }
    for k, v in pairs(rules) do
        rule[k] = v
    end
    hl.window_rule(rule)
end

-- All tags
local opaque_tag = "opaque"
local float_tag = "float"
local float_35_16_tag = "float_35_16"
local float_45_45_tag = "float_45_45"
local float_50_55_tag = "float_50_55"
local float_50_60_tag = "float_50_60"
local float_60_65_tag = "float_60_65"
local float_60_70_tag = "float_60_70"
local float_70_80_tag = "float_70_80"
local float_40_80_tag = "float_40_80"
local game_tag = "game"
local xwl_popup_tag = "xwl_popup"
local system_monitor_tag = "system_monitor"
local music_player_tag = "music_player"
local communication_app_tag = "communication_app"
local todo_app_tag = "todo_app"

-- Your custom tags
local browser_tag = "browser"
local terminal_tag = "terminal"
local email_tag = "email"
local projects_tag = "projects"
local screenshare_tag = "screenshare"
local im_tag = "im"
local gamestore_tag = "gamestore"
local file_manager_tag = "file_manager"
local multimedia_tag = "multimedia"
local player_tag = "player"
local settings_tag = "settings"
local viewer_tag = "viewer"


----------------------
---- Window rules ----
----------------------

-- Apply default opacity to all windows except fullscreen
hl.window_rule({ match = { fullscreen = false }, opacity = vars.windowOpacity .. " override" })

-- Center all floating windows except xwayland windows (xwayland popups count as windows)
hl.window_rule({ match = { float = true, xwayland = false }, center = true })

-- Catch-all for untitled popups and classless submenus
hl.window_rule({ match = { title = "^()$" }, float = true })
hl.window_rule({ match = { class = "^()$" }, float = true })

-- Titles without a hyphen (usually not main apps)
hl.window_rule({ match = { title = "^(?!.* - ).*$" }, float = true, center = true })

-- Picture in picture
hl.window_rule({
    match             = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    move              = "(monitor_w*0.744) (monitor_h*0.739)",
    size              = "(monitor_w*0.25) (monitor_h*0.25)",
    pin               = true,
    float             = true,
    keep_aspect_ratio = true,
})

-- Global blur configuration (Your preference: disable global blur, but re-enable for specific tags)
hl.window_rule({ match = { class = ".*" }, no_blur = true })


----------------------
---- Tagged rules ----
----------------------

-- Opaque apps
tagged_rule(opaque_tag, {
    "foot",                                   -- Terminal
    "equibop",                                -- Discord client
    "org.quickshell",                         -- Quickshell
    "feh|imv|swappy",                         -- Image viewers
    "krita|gimp|inkscape|darktable",          -- Image editors
    "resolve|kdenlive|shotcut",               -- Video editors
    "blender|godot",                          -- 3D editors
    "(steam_app_(default|[0-9]+))|gamescope", -- Games
    "[Zz]en.*|[Ff]irefox.*|[Cc]hrome.*|chromium.*|brave.*", -- Browsers
    "vlc|mpv|totem|celluloid",                -- Media players
}, "class")


-- Floating apps
tagged_rule(float_tag, {
    "guifetch",                           -- System info
    "yad|zenity",                         -- Dialogs
    "wev",                                -- Input detector
    "org.gnome.FileRoller|file-roller",   -- Archive manager
    "blueman-manager",                    -- Bluetooth GUI
    "com.github.GradienceTeam.Gradience", -- GTK themer (deprecated)
    "feh|imv|swappy",                     -- Image viewers
    "org.quickshell",                     -- Quickshell
    "nm-connection-editor",               -- Network manager
    "blueberry\\.py",                     -- Bluetooth
    "pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol",
}, "class")

tagged_rule(float_tag, {
    "File (Operation|Upload)( Progress)?",                    -- File manager operation progress
    ".* Properties",                                          -- File properties
    ".*Select.*", ".*Confirm.*", ".*Warning.*", ".*Error.*",
    "^(Receiving file — KDE Connect Daemon)$",
    "^(Overview)(.*)$",
    "^(Wallpaper Selector)(.*)$",
    "^(Hyprland Keybinds Cheatsheet)(.*)$",
    "^(Extract)(.*)$", "^(Compress)(.*)$", "^(Rename)(.*)$",
    "^(WallpaperPicker)(.*)$", "^(Zenith Installer)(.*)$",
    "^(Open File|Select a File|Open Folder|Save As|Library|File Upload)(.*)$",
    "^(.*)(wants to save|wants to open)$",
    ".*Welcome",
    ".*Shell conflicts.*",
}, "title")


-- Sized floaters (Custom & Zenith dimensions)
tagged_rule(float_35_16_tag, { "org.gnome.FileRoller" }, "class")
tagged_rule(float_45_45_tag, { "blueberry\\.py", "pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol", "nm-connection-editor" }, "class")
tagged_rule(float_50_55_tag, { "Wallpaper Selector" }, "title")
tagged_rule(float_60_65_tag, { "org.freedesktop.impl.portal.desktop.kde" }, "class")

tagged_rule(float_60_70_tag, {
    "(Select|Open)( a)? (File|Folder)(s)?", -- File dialogs
    "Save As",
    "Library",
}, "title")
tagged_rule(float_60_70_tag, {
    { title = "(Save|Export) Image", class = "gimp" },
})
tagged_rule(float_60_70_tag, {
    "yad-icon-browser",
}, "class")

tagged_rule(float_70_80_tag, {
    "org.gnome.Settings",
}, "class")

tagged_rule(float_40_80_tag, {
    "Hyprland Keybinds Cheatsheet",
}, "title")


-- Games & Tearing
tagged_rule(game_tag, {
    "steam_app_[0-9]+",
    "steam_app_default",
    "gamescope",
})


-- Xwayland popups
tagged_rule(xwl_popup_tag, {
    { xwayland = true, title = "win[0-9]+" },
    { xwayland = true, title = "",         class = "", initial_title = "", initial_class = "" }
})


-- Special workspaces & Apps
tagged_rule(system_monitor_tag, { "btop" }, "class")
tagged_rule(music_player_tag, {
    "feishin|Supersonic|Plexamp",
    "Spotify",
    "Cider",
    "com.github.th-ch.youtube-music|com-maxrave-simpmusic-MainKt",
    "youtube-music-bin|youtube-music|youtube-music-git|[Aa]udacious"
}, "class")
tagged_rule(music_player_tag, { "Spotify|Spotify Free" }, "initial_title")
tagged_rule(communication_app_tag, {
    "discord|equibop|vesktop",
    "whatsapp"
}, "class")
tagged_rule(todo_app_tag, { "todoist" }, "class")


-- Your Custom Tags
tagged_rule(browser_tag, { "[Zz]en-browser|zen|zen-browser|[Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr" }, "class")
tagged_rule(terminal_tag, { "Alacritty|kitty|kitty-dropterm|gnome-terminal|foot|terminal" }, "class")
tagged_rule(email_tag, { "[Tt]hunderbird|org.gnome.Evolution|eu.betterbird.Betterbird" }, "class")
tagged_rule(projects_tag, { "VSCode|code-url-handler|code|visual-studio-code|vscode|zeditor|antigravity-ide|antigravity" }, "class")
tagged_rule(screenshare_tag, { "com.obsproject.Studio" }, "class")
tagged_rule(im_tag, { "[Dd]iscord|[Ww]ebCord|[Vv]esktop" }, "class")
tagged_rule(gamestore_tag, { "[Ss]team" }, "class")
tagged_rule(file_manager_tag, { "[Nn]emo|[Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt" }, "class")
tagged_rule(multimedia_tag, { "youtube-music-bin|youtube-music|youtube-music-git|[Aa]udacious" }, "class")
tagged_rule(player_tag, { "vlc|mpv" }, "class")
tagged_rule(settings_tag, { "gnome-disks|wihotspot(-gui)?|file-roller|org.gnome.FileRoller|nm-applet|nm-connection-editor|blueman-manager|pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol|nwg-look|qt5ct|qt6ct|[Yy]ad|xdg-desktop-portal-gtk|org.kde.polkit-kde-authentication-agent-1" }, "class")
tagged_rule(viewer_tag, { "gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter|eog|org.gnome.Loupe" }, "class")


-----------------------
---- Per app rules ----
-----------------------

-- Steam & Games
tagged_rule(float_tag, { { class = "steam", title = "Friends List" } })
tagged_rule(xwl_popup_tag, { { class = "steam", title = "" } })
hl.window_rule({ match = { class = "dev.warp.Warp" }, tile = true })

-- Immediate / Tearing rules
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- Ueberzugpp & Fusion 360
hl.window_rule({ match = { class = "ueberzugpp_.*" }, float = true, no_initial_focus = true })
hl.window_rule({ match = { class = "fusion360.exe", title = "Fusion360|(Marking Menu)" }, no_blur = true })

-- Minecraft launcher consoles
tagged_rule(float_tag, {
    { class = "com-atlauncher-App", title = "ATLauncher Console" },
    { class = "PandoraLauncher",    title = "Minecraft Game Output" },
})

-- Shadows on floating state
hl.window_rule({ match = { float = false }, no_shadow = true })


-------------------------
---- Tag definitions ----
-------------------------

create_tag(opaque_tag, { opaque = true })
create_tag(float_tag, { float = true })
create_tag(float_35_16_tag, { float = true, size = "(monitor_w*0.35) (monitor_h*0.16)", center = true })
create_tag(float_45_45_tag, { float = true, size = "(monitor_w*0.45) (monitor_h*0.45)", center = true })
create_tag(float_50_55_tag, { float = true, size = "(monitor_w*0.52) (monitor_h*0.55)", center = true })
create_tag(float_60_65_tag, { float = true, size = "(monitor_w*0.60) (monitor_h*0.65)", center = true })
create_tag(float_50_60_tag, { float = true, size = "(monitor_w*0.5) (monitor_h*0.6)", center = true })
create_tag(float_60_70_tag, { float = true, size = "(monitor_w*0.6) (monitor_h*0.7)", center = true })
create_tag(float_70_80_tag, { float = true, size = "(monitor_w*0.7) (monitor_h*0.8)", center = true })
create_tag(float_40_80_tag, { float = true, size = "(monitor_w*0.40) (monitor_h*0.80)", center = true })
create_tag(game_tag, { immediate = true, idle_inhibit = "always" })
create_tag(xwl_popup_tag, {
    no_dim = true,
    no_shadow = true,
    no_blur = true,
    opaque = true,
    rounding = math.min(10, vars.windowRounding),
})
create_tag(system_monitor_tag, { workspace = "special:sysmon" })
create_tag(music_player_tag, { workspace = "special:music" })
create_tag(communication_app_tag, { workspace = "special:communication" })
create_tag(todo_app_tag, { workspace = "special:todo" })

-- Opacity mappings (Your Custom App Rules)
hl.window_rule({ match = { tag = "browser" }, opaque = true, no_blur = true, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.85 override 0.8 override", no_blur = false })
hl.window_rule({ match = { tag = "projects" }, opacity = "0.98 override 0.95 override", no_blur = true })
hl.window_rule({ match = { tag = "im" }, opacity = "0.95 override 0.9 override" })
hl.window_rule({ match = { tag = "multimedia" }, opacity = "0.95 override 0.9 override" })
hl.window_rule({ match = { tag = "player" }, opaque = true, no_blur = true, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { tag = "file_manager" }, opaque = true, no_blur = true })
hl.window_rule({ match = { tag = "settings" }, opacity = "0.95 override 0.9 override" })
hl.window_rule({ match = { tag = "viewer" }, opaque = true, no_blur = true })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.95 override 0.9 override" })


-------------------------
---- Workspace rules ----
-------------------------

hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })


---------------------
---- Layer rules ----
---------------------

hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "logout_dialog" }, animation = "fade", blur = true })
hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "wayfreeze" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%", blur = true, ignore_alpha = 0.5 })

-- Layer rules from your config
hl.layer_rule({ match = { namespace = ".*" }, xray = true })
hl.layer_rule({ match = { namespace = "(walker|selection|overview|anyrun|indicator.*|osk|hyprpicker|noanim)" }, animation = "noanim" })
hl.layer_rule({ match = { namespace = "(gtk-layer-shell|notifications|osd)" }, blur = true })
hl.layer_rule({ match = { namespace = "(notifications|osd)" }, ignore_alpha = 0.69 })
hl.layer_rule({ match = { namespace = "gtk4-layer-shell" }, animation = "noanim" })

-- Zenith Shell surfaces (0-latency: custom fluid physics handled inside Quickshell)
hl.layer_rule({ match = { namespace = "(controlcenter|quicksettings|zenith-menu|zenith-dynamic-island-overlay)" }, no_anim = true, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "dismiss_overlay" }, no_anim = true })
hl.layer_rule({ match = { namespace = "(zenith|quickshell|caelestia|ii)-(border-exclusion|area-picker)" }, no_anim = true })
hl.layer_rule({ match = { namespace = "(zenith|quickshell|caelestia|ii)-(drawers|background)" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "(caelestia|ii)-.*" }, blur = true, ignore_alpha = 0.5 })
local scheme = require("scheme_loader")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "kitty -1",
    browser                    = "zen",
    editor                     = "antigravity-ide",
    fileExplorer               = "thunar",
    audioSettings              = "pavucontrol",

    -- Keyboard Layout & Options
    kbLayout                   = os.getenv("HYPRLAND_KB_LAYOUT") or "us",
    kbOptions                  = os.getenv("HYPRLAND_KB_OPTIONS") or "caps:escape,grp:alt_shift_toggle",
    kbVariant                  = os.getenv("HYPRLAND_KB_VARIANT") or "",

    -- Touchpad & Mouse
    touchpadTapToClick         = true,
    touchpadDisableTyping      = true,
    touchpadScrollFactor       = 1.0,
    mouseScrollFactor          = 1.0,
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = false,
    blurInputMethods           = false,
    blurSize                   = 8,
    blurPasses                 = 1,
    blurXray                   = false,

    -- Shadow
    shadowEnabled              = false,
    shadowRange                = 15,
    shadowRenderPower          = 4,
    shadowColour               = "rgba(" .. scheme.inversePrimary .. "10)",

    -- Gaps
    workspaceGaps              = 20,
    windowGapsIn               = 5,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 10,

    -- Window styling
    windowOpacity              = 0.95,
    windowRounding             = 15,
    windowBorderSize           = 0,
    activeWindowBorderColour   = "rgba(" .. scheme.primary .. "e6)",
    inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",

    -- Misc
    volumeStep                 = 10,
    volumeMax                  = 150,
    cursorTheme                = "Bibata-Modern-Classic", -- keep in sync with zenith-nixos modules/home/theme.nix
    cursorSize                 = 24,
    sleepGestureCmd            = "systemctl suspend-then-hibernate",

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Modifier only, the actual binds will be mod + 0-9. These should be strings and not arrays.
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbMoveWinToWs              = "SUPER + ALT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

    -- All the following binds can be either an array of binds to bind multiple keys, or a single string.

    -- Workspaces
    kbMoveWinToWsSpecial       = { "SUPER + ALT + S", "CTRL + SUPER + SHIFT + Up" },
    kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
    kbMoveWinToWsNext          = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
    kbMoveWinToWsPrev          = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
    kbNextWs                   = { "SUPER + mouse_down", "CTRL + SUPER + Right", "SUPER + Page_Down" },
    kbPrevWs                   = { "SUPER + mouse_up", "CTRL + SUPER + Left", "SUPER + Page_Up" },
    kbNextWsGroup              = "CTRL + SUPER + mouse_down",
    kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

    -- Window Group
    kbWindowCycleNext          = "ALT + TAB",
    kbWindowCyclePrev          = "SHIFT + ALT + TAB",
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",
    kbGroupLockActive          = "SUPER + SHIFT + Comma",

    -- Window Actions
    kbWindowDecreaseWidth      = { "SUPER + Minus", "SUPER + ALT + Left" },
    kbWindowIncreaseWidth      = { "SUPER + Equal", "SUPER + ALT + Right" },
    kbWindowDecreaseHeight     = { "SUPER + SHIFT + Minus", "SUPER + ALT + Up" },
    kbWindowIncreaseHeight     = { "SUPER + SHIFT + Equal", "SUPER + ALT + Down" },

    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbCenterWindow             = "CTRL + SUPER + Backslash",
    kbNormalizeWindow          = "CTRL + SUPER + ALT + Backslash",
    kbWindowPip                = "SUPER + ALT + Backslash",
    kbPinWindow                = "SUPER + ALT + P",
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + Space",
    kbCloseWindow              = "SUPER + Q",
    kbKillWindow               = "SUPER + SHIFT + ALT + Q",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + M",
    kbCommunicationWs          = "SUPER + ALT + D",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + T",
    kbBrowser                  = "SUPER + W",
    kbEditor                   = "SUPER + C",
    kbFileExplorer             = "SUPER + E",
    kbAudioSettings            = "CTRL + ALT + V",
    kbTextEditor               = "SUPER + SHIFT + X",

    -- Utilities
    kbScreenshot               = "Print",
    kbScreenshotWindow         = "ALT + Print",
    kbScreenshotFreeze         = "SUPER + SHIFT + S",
    kbScreenshotRegion         = "SUPER + SHIFT + ALT + S",
    kbRecord                   = "CTRL + ALT + R",          -- active monitor, no audio
    kbRecordSound              = "SUPER + SHIFT + R",       -- active monitor + system audio
    kbRecordMic                = "SUPER + SHIFT + ALT + R", -- active monitor + microphone
    kbRecordRegion             = "SUPER + ALT + R",         -- select a region
    kbOcr                      = "SUPER + SHIFT + T",       -- select a region, copy its text
    kbColorPicker              = "SUPER + SHIFT + C",
    kbZoomIn                   = "SUPER + ALT + Equal",
    kbZoomOut                  = "SUPER + ALT + Minus",
    kbZoomReset                = "SUPER + ALT + Backspace",

    -- Media
    kbMediaToggle              = "CTRL + SUPER + Space",
    kbMediaNext                = "CTRL + SUPER + Equal",
    kbMediaPrev                = "CTRL + SUPER + Minus",
    kbMediaStop                = "CTRL + SUPER + Backspace",
    kbVolumeMute               = "SUPER + SHIFT + M",

    -- Session
    kbSession                  = "CTRL + ALT + Delete",
    kbLock                     = "SUPER + L",
    kbRestoreLock              = "SUPER + ALT + L",
    kbSleep                    = "SUPER + SHIFT + L",

    -- Zenith shell surfaces
    kbLauncher                 = { "SUPER + D", "SUPER + Space" },
    kbDashboard                = "SUPER + A",
    kbQuickSettings            = "CTRL + SUPER + Q",
    kbWifi                     = "CTRL + SUPER + W",
    kbBluetooth                = "CTRL + SUPER + B",
    kbPowerProfile             = "CTRL + SUPER + P",
    kbBattery                  = "CTRL + SUPER + E",
    kbRoadmap                  = "CTRL + SUPER + O",
    kbMail                     = "CTRL + SUPER + M",
    kbPomodoro                 = "CTRL + SUPER + A",
    kbWallpaper                = "CTRL + SUPER + T",
    kbVolumePanel              = "CTRL + SUPER + S",
    kbCloseMenus               = "CTRL + SUPER + C",
    kbShellSettings            = "CTRL + SUPER + I",
    kbDisplay                  = { "SUPER + P", "XF86Display", "code:246" },
    kbClipboard                = "SUPER + V",
    kbEmoji                    = "SUPER + Period",
    kbCheatsheet               = { "SUPER + slash", "SUPER + question", "SUPER + F1" },
}

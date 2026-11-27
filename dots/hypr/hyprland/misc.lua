local scheme = require("scheme_loader")

hl.config({
    misc = {
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,

        disable_hyprland_logo        = true,
        force_default_wallpaper      = 0,

        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        middle_click_paste           = false,
        focus_on_activate            = true,
        session_lock_xray            = true,

        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,

        background_color             = "rgb(" .. scheme.surfaceContainer .. ")",
    },

    debug = {
        error_position = 1
    }
})

-- Actively release unused heap memory back to the Linux kernel when windows close
local trim = package.loadlib("libc.so.6", "malloc_trim")
if trim then
    hl.on("window.close", function()
        trim(0)
    end)
end


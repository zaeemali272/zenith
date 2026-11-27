local vars = require("variables")

hl.config({
    input = {
        kb_layout          = vars.kbLayout or "us",
        kb_variant         = vars.kbVariant or "",
        kb_options         = vars.kbOptions or "caps:escape,grp:alt_shift_toggle",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,
        focus_on_close     = 1,
        sensitivity        = 1.0,
        scroll_factor      = vars.mouseScrollFactor or 1.0,
        
        touchpad           = {
            tap_to_click         = vars.touchpadTapToClick,
            natural_scroll       = true,
            disable_while_typing = vars.touchpadDisableTyping,
            scroll_factor        = vars.touchpadScrollFactor,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
        no_hardware_cursors = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

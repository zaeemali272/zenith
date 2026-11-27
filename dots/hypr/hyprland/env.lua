local vars = require("variables")

-- Themes
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QSG_RHI_BACKEND", "opengl")
-- hl.env("SDL_VIDEODRIVER", "wayland,x11,windows") -- Disabled: SDL does not accept comma-separated lists
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("MOZ_WEBRENDER", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Hardware Video Decoding & Acceleration (Intel Iris Xe)
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("VDPAU_DRIVER", "va_gl")
hl.env("MESA_LOADER_DRIVER_OVERRIDE", "iris")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Memory allocator optimizations (reduce heap fragmentation and release idle memory)
hl.env("MALLOC_ARENA_MAX", "2")
hl.env("MALLOC_TRIM_THRESHOLD_", "131072")


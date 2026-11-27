# 🌌 Hyprland Configuration System

A modern, highly modular, Lua-powered **Hyprland** desktop configuration environment built for Wayland. It seamlessly integrates custom window rules, dynamic Material You design schemes, touchpad gesture controls, smooth bezier animations, OSD overlays, and unified multi-shell UI support across **Zenith Shell**, **Caelestia**, and **End-4**.

---

## 🐚 Multi-Shell Architecture & Unified Dispatch

Hyprland-dots includes a dynamic shell abstraction layer. Keybindings and actions automatically dispatch to the currently active shell (tracked via `~/.config/zenith/active-shell`):
- **Zenith Shell** (`zenith`): Native global shortcuts (`zenith:launcher`, `zenith:dashboard`, `zenith:quicksettings`, etc.).
- **Caelestia Shell** (`caelestia`): Global shortcuts and CLI integrations (`caelestia:launcher`, `caelestia:sidebar`, `caelestia:nexus`, etc.).
- **End-4 Shell** (`end-4`): Seamless shortcuts mapping (`quickshell:searchToggle`, `quickshell:overviewWorkspacesToggle`, etc.).

### ⌨️ Super Key Launcher

Tapping **Super** on its own opens the desktop launcher for the active shell; holding it as a modifier (`Super + A`, `Super + drag`, ...) does not. This is done entirely in `hyprland/keybinds.lua` using unified Lua state without forking extra background processes per keystroke.

---

## 📸 Key Features

- **⚡ Lua-Driven Configuration**: Modular Lua architecture (`hyprland.lua`, `variables.lua`, `hyprland/*.lua`) backed by standard `hyprland.conf` compatibility.
- **🎨 Dynamic Material Color System**: Dynamic theme palette support via `scheme/current.lua` and `scheme/default.lua` synced with system wallpaper and shell themes.
- **🏷️ Intelligent Window & Layer Rules**: Automated tagging system (`opaque`, `float`, `browser`, `terminal`, `projects`, `game`, `im`, `settings`, `music_player`, `system_monitor`, etc.) with customizable window opacities, auto-centering, and workspace placement.
- **⌨️ Ergonomic Keybindings**: Full set of keybindings for window tiling, floating, sizing, group tabs, workspaces, scratchpads, hardware OSD, screenshots, recording, and app launching.
- **🤌 Rich Touchpad Gestures**: Horizontal 4-finger workspace navigation, vertical 3-finger gesture volume and brightness control, 3-finger horizontal track skipping, and 3-finger pinch to play/pause.
- **🌙 Native Hardware Night Light**: Direct hardware CTM (Color Transform Matrix) temperature control via `hyprsunset`.
- **🛠️ Utility Integration**: Built-in scripts for screen recording (`wl-screenrec` / `gpu-screen-recorder`), screenshot capture (`hyprshot`), OSD notifications (`osd.sh`), cursor zoom (pure Lua), and OCR text extraction (`ocr.sh`).

---

## 📂 File & Directory Architecture

```
~/.config/hypr/
├── hyprland.conf             # One line: sources hyprland.lua
├── check.sh                  # Syntax + live checks (./check.sh --live)
├── hyprland.lua              # Main Lua entrypoint initializing modules and path bindings
├── variables.lua             # Centralized settings, application defaults & keybinding map
├── monitors.lua              # Monitor resolution, scaling, and refresh rate definitions
├── scheme_loader.lua         # Resilient color scheme parser and fallback handler
├── hyprlauncher.conf         # Configuration for Hyprlauncher app menu
├── hyprtoolkit.conf          # Hyprtoolkit styling parameters
├── xdph.conf                 # XDG Desktop Portal Hyprland configuration
│
├── hyprland/                 # Core Lua configuration modules
│   ├── animations.lua        # Custom bezier curves and animation definitions
│   ├── decoration.lua        # Rounding, blur, xray, and shadow configurations
│   ├── env.lua               # System environment variables (Qt, GTK, Ozone, XDG)
│   ├── execs.lua             # System autostart daemons, keyrings & window listeners
│   ├── general.lua           # Layout parameters, dwindle engine, borders & gaps
│   ├── gestures.lua          # Multi-finger touchpad gestures and OSD handlers
│   ├── group.lua             # Tabbed window group styling and fonts
│   ├── input.lua             # Keyboard layout, repeat delay/rate, touchpad parameters
│   ├── keybinds.lua          # Dynamic multi-shell keybinding event handlers
│   ├── misc.lua              # Miscellaneous Hyprland engine settings & background color
│   ├── rules.lua             # Window tags, floating sizes, opacity rules, layer rules
│   └── scripts/              # Utility shell scripts
│       ├── launch_first_available.sh # Helper script to launch available binary
│       ├── osd.sh            # On-screen display for Volume & Brightness
│       ├── ocr.sh            # Select a region, copy its text (tesseract)
│       ├── record.sh         # Screen recording helper (region, window, sound)
│       ├── restart_everything.sh # Daemon and shell restart script
│       └── screenshot.sh     # Hyprshot screenshot helper
│
├── scheme/                   # Color scheme definitions
│   ├── current.lua           # Active dynamic color scheme palette
│   └── default.lua           # Default fallback color scheme palette
│
└── utils/                    # Utility Lua modules
    ├── functions.lua         # Window placement, workspace helpers & config loaders
    └── json.lua              # Lightweight Lua JSON parser
```

---

## ⌨️ Comprehensive Keybind Reference

### 🚀 Application Shortcuts
| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `Super` / `Super + D` | **App Launcher** | Toggle overview / app launcher |
| `Super + Return` / `Super + T` | **Terminal** | Launch terminal emulator (`ghostty` / `kitty`) |
| `Super + W` / `Super + B` | **Web Browser** | Launch web browser (`zen-beta` / `zen`) |
| `Super + E` | **File Manager** | Launch file explorer (`nemo` / `thunar`) |
| `Super + C` | **Code Editor** | Launch primary code editor (`antigravity-ide`) |
| `Super + X` | **Text Editor** | Launch secondary editor (`zeditor` / `gnome-text-editor`) |
| `Ctrl + Alt + V` | **Audio Controls** | Open volume control (`pavucontrol`) |
| `Ctrl + Shift + Esc` | **System Monitor** | Launch task manager (`missioncenter` / `btop`) |

---

### 🪟 Window Management
| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `Super + Q` / `Super + Shift + Q` | **Close Window** | Close active window |
| `Super + Space` / `Super + Alt + Space` | **Toggle Float** | Toggle floating state for active window |
| `Super + F` | **Fullscreen** | Toggle full screen mode |
| `Super + Alt + F` | **Maximized** | Toggle bordered fullscreen (maximized) |
| `Super + P` | **Pin Window** | Pin floating window across all workspaces |
| `Super + Alt + \` | **Picture-in-Picture** | Scale and move active window to PiP corner |
| `Ctrl + Super + \` | **Center Window** | Center active window on screen |
| `Super + Arrow` / `Super + H/J/K/L` | **Focus Window** | Focus window in directional movement |
| `Super + Shift + Arrow` / `H/J/K/L` | **Move Window** | Move active window position |
| `Super + Ctrl + Arrow` / `H/J/K/L` | **Resize Window** | Resize active window dimensions |
| `Super + Alt + Arrow` / `H/J/K/L` | **Move Active** | Move floating window around |
| `Super + Left Mouse Drag` | **Move Window** | Drag window with mouse |
| `Super + Right Mouse Drag` | **Resize Window** | Resize window with mouse |

---

### 🖥️ Workspaces & Groups (Tabs)
| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `Super + 1..9, 0` | **Switch Workspace** | Jump directly to workspace 1–10 |
| `Super + Shift + 1..9, 0` | **Move to Workspace** | Move window to workspace 1–10 silently |
| `Super + Mouse Scroll` | **Cycle Workspace** | Switch to previous / next workspace |
| `Ctrl + Super + Right / Left` | **Cycle Workspace** | Navigate workspace right or left |
| `Super + Alt + Page_Down / Up` | **Move Window WS** | Move window to next/prev workspace |
| `Super + S` | **Special Workspace** | Toggle general scratchpad workspace |
| `Super + M` | **Music Scratchpad** | Toggle music player scratchpad |
| `Super + Alt + D` | **Chat Scratchpad** | Toggle communication apps scratchpad |
| `Super + R` | **To-Do Scratchpad** | Toggle todoist scratchpad |
| `Alt + Tab` / `Shift + Alt + Tab` | **Cycle Windows** | Cycle focus to next / previous window |
| `Super + Comma (,)` | **Toggle Group** | Group active windows into tabbed container |
| `Super + Shift + Comma` | **Lock Group** | Lock active window group |
| `Super + U` | **Ungroup** | Remove window from group |
| `Ctrl + Alt + Tab` | **Group Next Tab** | Cycle to next tab in active group |

---

### 🔊 Media, Volume & Brightness (OSD Integration)
| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `XF86AudioRaiseVolume` | **Volume Up** | Raise output volume with OSD notification |
| `XF86AudioLowerVolume` | **Volume Down** | Lower output volume with OSD notification |
| `XF86AudioMute` / `Super + Shift + M` | **Mute Audio** | Toggle audio output mute |
| `XF86AudioMicMute` | **Mute Mic** | Toggle microphone mute |
| `XF86MonBrightnessUp` | **Brightness Up** | Raise display brightness with OSD |
| `XF86MonBrightnessDown` | **Brightness Down** | Lower display brightness with OSD |
| `XF86AudioPlay` / `Ctrl + Super + Space` | **Play / Pause** | Toggle media playback |
| `XF86AudioNext` / `Ctrl + Super + Equal` | **Next Track** | Skip to next track |
| `XF86AudioPrev` / `Ctrl + Super + Minus` | **Prev Track** | Skip to previous track |

---

### 📷 Screenshots, Recording & Utilities
| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `Print` | **Full Screenshot** | Capture active display output |
| `Super + Shift + S` / `Print Region` | **Area Screenshot** | Select region to capture |
| `Alt + Print` | **Window Screenshot** | Capture active window |
| `Super + Alt + R` | **Record Region** | Screen record selected region |
| `Ctrl + Alt + R` | **Record Display** | Active display, no audio |
| `Super + Shift + R` | **Record + Sound** | Active display with system audio |
| `Super + Shift + Alt + R` | **Record + Mic** | Active display with microphone |
| `Super + Shift + C` | **Color Picker** | Inspect color code under cursor (`hyprpicker`) |
| `Super + V` | **Clipboard** | View clipboard history manager (`cliphist`) |
| `Super + Period (.)` | **Emoji Picker** | Open emoji selector menu |
| `Super + Shift + T` | **OCR Text Capture** | Grab text from region to clipboard via Tesseract |
| `Super + Alt + Equal (=)` | **Zoom In** | Zoom screen in under cursor |
| `Super + Alt + Minus (-)` | **Zoom Out** | Zoom screen out |
| `Super + Alt + Backspace` | **Zoom Reset** | Back to 1:1 |

---

### ⚙️ Multi-Shell Surfaces & Global Shortcuts (Zenith, Caelestia, End-4)

Keybindings automatically dispatch to the active desktop shell (`zenith`, `caelestia`, or `end-4`):

| Keybinding | Action | Zenith Shell Action | Caelestia / End-4 Action |
| :--- | :--- | :--- | :--- |
| `Super` / `Super + D` / `Super + Space` | **App Launcher** | `zenith:launcher` | `caelestia:launcher` / `quickshell:searchToggle` |
| `Super + A` | **Dashboard** | `zenith:dashboard` | `caelestia:dashboard` / `quickshell:overviewWorkspacesToggle` |
| `Ctrl + Super + Q` | **Quick Settings** | `zenith:quicksettings` | `caelestia:sidebar` |
| `Ctrl + Super + W` | **Wi-Fi** | `zenith:wifi` | `caelestia:sidebar` (network tab) |
| `Ctrl + Super + B` | **Bluetooth** | `zenith:bluetooth` | `caelestia:sidebar` (bluetooth tab) |
| `Ctrl + Super + S` | **Volume Slider** | `zenith:volume` | `caelestia:sidebar` (volume panel) |
| `Ctrl + Super + P` | **Power Profile** | `zenith:powerprofile` | `caelestia:sidebar` (power profile) |
| `Ctrl + Super + E` | **Battery Status** | `zenith:battery` | `caelestia:sidebar` (battery health) |
| `Ctrl + Super + A` | **Pomodoro** | `zenith:pomodoro` | `caelestia:utilities` |
| `Ctrl + Super + O` | **Roadmap** | `zenith:roadmap` | `caelestia:utilities` |
| `Ctrl + Super + M` | **Mail** | `zenith:mail` | `caelestia:utilities` |
| `Ctrl + Super + T` | **Wallpaper** | `zenith:wallpaper` | `caelestia:nexus` (wallpaper) |
| `Super + V` | **Clipboard** | `zenith:clipboard` | `caelestia clipboard` / cliphist fuzzel |
| `Super + Period (.)` | **Emoji Picker** | `zenith:emoji` | `caelestia emoji` |
| `Ctrl + Super + I` | **Shell Settings** | `zenith:settings` | `caelestia:nexus` |
| `Super + Shift + P` | **Display Settings** | `zenith:display` | `caelestia:nexus` (display tab) |
| `Ctrl + Super + C` / `Ctrl + Escape` | **Close All** | `zenith:close` | `caelestia:showall` |
| `Ctrl + Alt + Delete` / `XF86PowerOff` | **Power Menu** | `zenith:power` | `caelestia:session` / `quickshell:sessionToggle` |
| `Super + L` | **Lock Screen** | `zenith:lock` | `caelestia:lock` |
| `Alt + Escape` | **Reload Hyprland** | Instant Hyprland config reload | Instant Hyprland config reload |
| `Ctrl + Super + R` | **Restart Everything** | Clean restart of Quickshell, portals, daemons & compositor reload | Clean restart of active shell & daemons |
| `Super + Shift + L` | **Suspend System** | Put machine to sleep | Put machine to sleep |

---

## 🤌 Touchpad Gestures

- **4-Finger Horizontal Swipe**: Navigate between active workspaces.
- **3-Finger Vertical Swipe (Up / Down)**: Raise or lower output volume with OSD feedback.
- **3-Finger + CTRL Vertical Swipe (Up / Down)**: Raise or lower screen brightness.
- **3-Finger Horizontal Swipe (Left / Right)**: Skip to previous / next media track.
- **3-Finger Pinch**: Toggle media play/pause state.
- **4-Finger Swipe Up**: Toggle special scratchpad workspace.

---

## ⚙️ Customization & User Overrides

You can easily override options without editing core files:

1. **Variables & Keybinds**: Edit `variables.lua` to change default application choices (e.g. `terminal`, `browser`, `editor`, `fileExplorer`) or adjust gaps and opacities.
2. **User Overrides (`hypr-vars.lua`)**: Create a file named `hypr-vars.lua` in `~/.config/hypr/` returning a Lua table to override any setting from `variables.lua`:
   ```lua
   return {
       terminal = "alacritty",
       browser = "firefox",
       windowRounding = 12,
   }
   ```
3. **Color Schemes**: Update `scheme/current.lua` to change theme colors (supports Material You HSL / hex tokens).

---

## 📦 Required Dependencies

- **WM**: `hyprland`
- **Shell & UI**: `quickshell` (Zenith shell, which includes the lock screen), `hyprlauncher` (or `caelestia-shell` / `end4-shell`)
- **Night Light**: `hyprsunset` (native hardware CTM temperature control)
- **Utilities**: `hyprpicker`, `wl-clipboard`, `cliphist`, `playerctl`, `wpctl`, `brightnessctl`, `hyprshot`, `slurp`, `grim`, `tesseract`
- **Recording**: `gpu-screen-recorder` / `wl-screenrec`

# 🌌 Zenith: The Universal Desktop Experience (NixOS & Arch Linux)

Welcome to **Zenith**, a performance-oriented, fluid desktop environment powered by **Hyprland** and **Quickshell**.

Zenith is organized into three specialized repositories modeled after the modular desktop ecosystem:

| Repository | Purpose | Description |
| :--- | :--- | :--- |
| **[zenith](https://github.com/zaeemali272/zenith)** *(this repo)* | **System & Dotfiles** | Unified dotfiles (`dots/hypr`, `kitty`, `fish`, `btop`, etc.), NixOS flake & modules, and Arch Linux automated installer. |
| **[zenith-shell](https://github.com/zaeemali272/zenith-shell)** | **Desktop Shell UI** | Complete Qt6/QML desktop shell powered by Quickshell: Dynamic Island, bar, sidebar, dashboard, notifications, and lockscreen. |
| **[zenith-cli](https://github.com/zaeemali272/zenith-cli)** | **Desktop & System CLI** | Unified command line interface for shell switching, special workspaces, recording, screenshots, and system maintenance. |

---

## 🚀 Key Highlights

- **Dual-Distro First Class Support**:
  - **NixOS**: Declarative system configuration via Flakes with reproducible host derivations (`hosts/V14`, `hosts/vm`, `hosts/desktop`).
  - **Arch Linux**: One-click automated setup (`./install.sh`) with intelligent hardware detection, mirror optimization, and ZRAM tuning.
- **Unified Dotfiles**: All configurations live together in `dots/` (Hyprland Lua/Hyprlang, Kitty, Fish, Starship, Btop, Yazi, Zed).
- **Multi-Shell Switcher**: Switch seamlessly between `zenith-shell`, `caelestia-shell`, and `end-4` with dynamic theme reloading.
- **Hardware-Integrated Audio & Brightness**: Granular OSD feedback, sysfs fallback brightness control, and multitouch gestures.
- **Self-Healing Diagnostics**: Built-in `zenith doctor` health check verifies session, audio, render nodes, polkit, and hardware interfaces.

---

## 🏃 Quick Start

### ❄️ Option A: NixOS (Flake)

```bash
# Clone the repository
git clone https://github.com/zaeemali272/zenith.git ~/zenith/zenith
cd ~/zenith/zenith

# Check system health & requirements
zenith doctor

# Rebuild and switch (using your hostname or desktop profile)
zenith rebuild switch
# or:
sudo nixos-rebuild switch --flake .#V14
```

### 🏹 Option B: Arch Linux

```bash
git clone https://github.com/zaeemali272/zenith.git ~/zenith/zenith
cd ~/zenith/zenith
./install.sh
```

---

## 🛠️ CLI Commands (`zenith`)

The `zenith` command provides full control over the desktop and underlying operating system:

```bash
# System Management
zenith rebuild [switch|boot|test]   # Rebuild system configuration (nh / nixos-rebuild / yay)
zenith update                       # Pull repository updates and rebuild
zenith rollback                     # Rollback to the previous NixOS generation
zenith doctor                       # 10-point system component verification
zenith clean [days]                 # Deep cleanup: garbage collection, cache, logs, temp files
zenith where                        # Print active configuration directory

# Desktop Shell
zenith shell switch <name>          # Switch between zenith, caelestia, and end-4
zenith shell restart                # Restart the active desktop shell
zenith shell list                   # Show available desktop shells

# Hyprland & Media
zenith toggle <workspace>           # Toggle special workspaces (sysmon, communication, music, todo)
zenith screenshot [-r|-f]           # Fullscreen or region screenshot with swappy editor
zenith record [-r|-s|-p]            # Toggle screen recording with audio and region support
zenith wallpaper -f <path>          # Set active wallpaper and dynamically update color palettes
zenith clipboard [-d]               # Fast clipboard history search via Fuzzel
```

---

## 📁 Repository Structure

```
zenith/
├── dots/                     # Unified user dotfiles
│   ├── hypr/                 # Hyprland window manager configurations & scripts
│   ├── fish/                 # Fish shell configuration
│   ├── kitty/                # Kitty terminal emulator configuration
│   ├── btop/                 # System monitor theme & config
│   ├── yazi/                 # Terminal file manager configuration
│   └── zed/                  # Zed editor configuration
├── hosts/                    # NixOS machine configurations
│   ├── V14/                  # Primary workstation profile
│   ├── vm/                   # Virtual machine testing profile
│   └── desktop/              # Template profile for custom hardware
├── modules/                  # Modular configuration components
│   ├── core/                 # NixOS system services, audio, bootloader, networking
│   ├── home/                 # Home-Manager user programs & environment
│   └── arch/                 # Arch Linux installation modules & helpers
├── flake.nix                 # Top-level NixOS Flake definition
└── install.sh                # Smart dual-distro installer & updater
```

---

## 📜 License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.

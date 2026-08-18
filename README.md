# ❄️ Zenith NixOS

> **Universal Frost-Phoenix Style NixOS & Hyprland Flake Configuration**

[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-hero.svg?logo=archlinux&logoColor=white)](https://hyprland.org)
[![Home-Manager](https://img.shields.io/badge/Home--Manager-Nix-green.svg)](https://github.com/nix-community/home-manager)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

**Zenith** is a modular, declarative, and elegant NixOS configuration driven by Nix Flakes. Designed for high performance, aesthetics, and developer productivity, it pairs **Hyprland** with custom UI components, AI agent integrations, and a modular architecture.

---

## 🌟 Features

- ❄️ **Nix Flakes Architecture** — Fully reproducible system declarations split into system modules (`core`) and user environments (`home`).
- 🎨 **Hyprland Desktop Environment** — Dynamic Wayland window management with smooth animations, keybindings, and window rules.
- 🚀 **QuickShell Widgets** — Modern Qt/QML UI widget engine integration.
- 🌐 **Zen Browser** — Integrated privacy-focused browser flake setup.
- 🤖 **AI Assistant Suite** — Native support for **Hermes Agent** and **Antigravity AI**.
- 🎮 **Gaming & Media** — Preconfigured Steam, PipeWire low-latency audio, Cava visualizer, and graphics drivers.
- 🛠️ **Developer Tooling** — `direnv`, `lazygit`, `bat`, `fzf`, `btop`, `micro`, `nvim`, and `treefmt`.
- ⚙️ **Centralized Configuration** — Single point of control via `vars.nix` for user profile, graphics driver selection, monitor configurations, and locale settings.

---

## 📂 Repository Structure

```text
zenith-nixos/
├── flake.nix               # Main Flake entrypoint & input dependencies
├── flake.lock              # Flake dependency lockfile
├── vars.nix                # Centralized user, system, & hardware variables
├── install.sh              # Quick deployment helper script
├── zen-mods.json           # Zen browser module definitions
├── treefmt.toml            # Code formatting options
├── hosts/                  # Machine-specific host profiles
│   ├── desktop/            # Primary desktop host configuration
│   └── vm/                 # Virtual machine configuration template
└── modules/                # Modular Nix configuration system
    ├── core/               # System-level NixOS modules (bootloader, graphics, network, etc.)
    └── home/               # User-level Home-Manager modules (hyprland, theme, apps, shell)
```

---

## ⚡ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/zaeemali272/zenith-nixos.git ~/.config/zenith-nixos
cd ~/.config/zenith-nixos
```

### 2. Configure Variables (`vars.nix`)
Customize `vars.nix` to match your personal details and hardware specifications:

```nix
{
  user = "zaeem";
  fullName = "zaeem";
  email = "zaeemali272@gmail.com";
  hostname = "V14";
  
  timeZone = "Asia/Karachi";
  locale = "en_US.UTF-8";
  keyboardLayout = "us";

  gpu = "intel"; # Options: "intel", "amd", "nvidia"
  hasBluetooth = true;

  monitors = [
    "eDP-1, 1920x1080@60, 0x0, 1"
  ];
}
```

### 3. Generate Your Hardware Configuration (required)

**Do not skip this.** A `hardware-configuration.nix` identifies your disks by
UUID, and those UUIDs are true for exactly one computer. If you build with
someone else's, the build succeeds and your **next boot drops into emergency
mode**, because systemd cannot find the root filesystem.

This repo therefore ships `hosts/desktop/hardware-configuration.nix` as a
placeholder that refuses to evaluate. Replace it with your own:

```bash
sudo nixos-generate-config --show-hardware-config \
  > hosts/desktop/hardware-configuration.nix
```

If you forget, the build stops with instructions instead of producing a system
that fails at boot.

> `hosts/v14/` is the repo author's machine and is the only host with real disk
> UUIDs committed. Build `.#desktop`, not `.#V14`.

### 4. Build and Switch Configuration
Execute the helper script or rebuild directly with `nixos-rebuild`:

```bash
# Using helper script
./install.sh

# Or directly with nixos-rebuild
sudo nixos-rebuild switch --flake .#desktop
```

---

## ⚙️ Core Modules Overview

| Category | Modules | Description |
| :--- | :--- | :--- |
| **System (`core`)** | `bootloader`, `hardware`, `network`, `services`, `pipewire`, `security` | Base system initialization, kernel hardware configuration, sound, and networking. |
| **Display (`core`)** | `wayland`, `xserver`, `fonts` | Hyprland compositor base, Wayland protocols, and system typography. |
| **User Space (`home`)**| `hyprland/`, `quickshell`, `theme`, `gtk`, `gnome` | Desktop aesthetic configuration, widget engine, GTK themes, and icon sets. |
| **Applications (`home`)**| `zen`, `browser`, `kitty`, `obsidian`, `gaming`, `antigravity` | Web browsing, terminal emulator, notes, gaming runtime, and AI development stack. |
| **CLI & Tools (`home`)** | `git`, `lazygit`, `bat`, `btop`, `cava`, `direnv`, `fzf`, `micro`, `nvim` | Command line utilities, system monitoring, git management, and text editors. |

---

## 🔧 Useful Commands

```bash
# Apply configuration changes
sudo nixos-rebuild switch --flake .#desktop

# Update flake input dependencies
nix flake update

# Format codebase
nix fmt

# Clean nix generations
nh clean all
```

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).

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

## ⚡ Using this configuration

This is someone's personal system config. It is built to be reused, but a NixOS
configuration describes one machine's disks, identity and hardware — so it
cannot be cloned and applied unchanged. Two things are always yours.

### Getting it

```bash
git clone https://github.com/zaeemali272/zenith-nixos.git ~/zenith/zenith-nixos
cd ~/zenith/zenith-nixos
```

You do not need to fork. The two things that are yours — `vars.nix` and your
host directory — are protected by a `merge=ours` rule in `.gitattributes`, so an
update keeps your version of them and takes everything else. Fork only if you
intend to publish your own changes.

### Staying up to date

```bash
./update.sh              # fetch, merge, tell you what changed
./update.sh --rebuild    # the above, then nixos-rebuild switch
./update.sh --check      # show what an update would bring, change nothing
```

It commits any local edits first (nothing is ever discarded), merges, refuses to
rebuild if your host does not evaluate, and stops with instructions if a genuine
conflict needs you. Your identity and hardware configuration are never
overwritten, even when an update changes the same file.

### 1. Your hardware configuration

**Skip this and your machine will not boot.** A `hardware-configuration.nix`
names disks by UUID. Those UUIDs are true for exactly one computer, so applying
someone else's produces a system that builds cleanly and then cannot mount its
root filesystem — you land in emergency mode.

Create a host directory named exactly after your hostname:

```bash
mkdir -p hosts/$(hostname)
sudo nixos-generate-config --show-hardware-config \
  > hosts/$(hostname)/hardware-configuration.nix
cp hosts/desktop/default.nix hosts/$(hostname)/default.nix
```

Hosts are discovered automatically from `hosts/`, so there is nothing to add to
`flake.nix` — which also means you never conflict with upstream over it.

If you build `.#desktop` without doing this, the placeholder refuses to evaluate
and tells you so. That is deliberate: a loud failure at build time beats a
silent one at boot.

### 2. Your identity

Edit `vars.nix`:

```nix
{
  user = "you";
  fullName = "Your Name";
  email = "you@example.com";
  hostname = "your-hostname";

  timeZone = "Region/City";
  locale = "en_US.UTF-8";
  keyboardLayout = "us";

  gpu = "intel";        # "intel" | "amd" | "nvidia"
  hasBluetooth = true;

  monitors = [ ", preferred, auto, 1" ];
}
```

The `desktop` host asserts that this is no longer the author's identity, so a
rebuild that forgot it fails with an explanation rather than quietly creating an
account named after someone else.

### 3. Build

```bash
sudo nixos-rebuild switch --flake .
```

With no `#host`, this selects the entry matching your current hostname — which
is why the directory name has to match it.

Or run `./install.sh`, which walks through identity, hashes a password and
copies your hardware configuration into place.

> **Password.** Until you set `hashedPassword` in `vars.nix` (the installer does
> this for you), the account is created with `initialPassword = "nixos"`. Change
> it immediately on a machine anyone else can reach.

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

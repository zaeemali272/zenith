<div align="center">

# ❄️ Zenith NixOS

**Universal Frost-Phoenix Style NixOS & Hyprland Flake Configuration**

[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3.svg?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58E1FF.svg?style=for-the-badge&logo=wayland&logoColor=black)](https://hyprland.org)
[![Home Manager](https://img.shields.io/badge/Home_Manager-Nix-7EBAE4.svg?style=for-the-badge&logo=nixos&logoColor=white)](https://github.com/nix-community/home-manager)
[![License](https://img.shields.io/badge/License-MIT-A3BE8C.svg?style=for-the-badge)](LICENSE)

A modular, declarative NixOS system — **Hyprland**, a custom **QuickShell** desktop,
and a full developer toolchain, in one reproducible flake.

<sub>

`zenith update --rebuild` &nbsp;•&nbsp; `zenith doctor` &nbsp;•&nbsp; `zenith rollback`

</sub>

</div>

---

## 📖 Contents

- [❄️ What this is](#what-this-is)
- [✨ What you get](#what-you-get)
- [🚀 Install](#install)
- [⚡ Everyday use](#everyday-use)
- [⚙️ Configuring it](#configuring-it)
- [📂 Repository layout](#layout)
- [🛡️ How updates protect your machine](#updates)
- [🩺 Troubleshooting](#troubleshooting)
- [↩️ Rolling back](#rollback)

---

<a id="what-this-is"></a>

## ❄️ What this is

A complete NixOS system: bootloader, drivers, audio, networking, a Hyprland
desktop, a Qt/QML shell, and a developer toolchain, declared in one flake.

A NixOS configuration describes **one machine**. Two parts of it are always
specific to yours and cannot be inherited from someone else:

| Yours | Why |
|---|---|
| `hosts/<hostname>/hardware-configuration.nix` | Names your disks by UUID. Someone else's UUIDs build fine and then fail to mount root — you land in emergency mode. |
| `vars.nix` | Your username, hostname, timezone, GPU. |

Everything else is shared. Both are protected from updates (see
[below](#updates)), so you set them once.

---

<a id="what-you-get"></a>

## ✨ What you get

| | |
|---|---|
| 🖥️ **Desktop** | Hyprland on Wayland, the Zenith QuickShell bar and menus, hyprlock, GTK + Qt theming driven by a wallpaper-derived Material palette |
| 🔊 **Audio & hardware** | PipeWire with low-latency config, Bluetooth, GPU drivers chosen by `vars.gpu`, battery charge limiting, earlyoom, zram, fstrim |
| 📦 **Applications** | Zen browser, kitty, yazi, Obsidian, Steam, virt-manager + libvirt, Docker |
| 🐟 **Shell & tooling** | fish with starship, direnv, lazygit, bat, btop, fzf, and the `zenith` command |
| 🧹 **Maintenance** | store auto-optimisation, scheduled GC via `nh`, capped boot generations so `/boot` cannot silently fill |

---

<a id="install"></a>

## 🚀 Install

### Requirements

A working NixOS install with flakes enabled, and `git`.

### 1. Get the repository

```bash
git clone https://github.com/zaeemali272/zenith-nixos.git ~/zenith/zenith-nixos
cd ~/zenith/zenith-nixos
```

Forking is optional — updates will not overwrite your machine files either way.
Fork only if you want to publish your own changes.

### 2. Create your host

The directory name **must equal your hostname**; that is how `nixos-rebuild`
finds it.

```bash
mkdir -p hosts/$(hostname)
sudo nixos-generate-config --show-hardware-config \
  > hosts/$(hostname)/hardware-configuration.nix
cp hosts/desktop/default.nix hosts/$(hostname)/default.nix
```

Hosts are discovered from `hosts/` automatically. You never edit `flake.nix`,
which is also why upstream changes to it never conflict with yours.

> Skipping this is the one mistake that breaks a machine. `hosts/desktop`
> deliberately ships a placeholder that **refuses to build** rather than
> applying the author's disk UUIDs to your computer.

### 3. Set your identity

Edit `vars.nix`:

```nix
{
  user = "you";                 # login name
  fullName = "Your Name";
  email = "you@example.com";    # used for git
  hostname = "your-hostname";   # must match the directory above

  configDir = "/home/you/zenith/zenith-nixos";   # where this repo lives

  timeZone = "Region/City";     # e.g. Europe/London
  locale = "en_US.UTF-8";
  keyboardLayout = "us";

  gpu = "intel";                # "intel" | "amd" | "nvidia"
  hasBluetooth = true;
}
```

`hosts/desktop` asserts this is no longer the author's identity, so a rebuild
that forgot it fails with an explanation instead of quietly creating an account
named after someone else.

### 4. Build

```bash
sudo nixos-rebuild switch --flake ~/zenith/zenith-nixos
```

This is the only time you type that. It installs the `zenith` command.

Then **reboot** — some things (udev rules for battery control, the polkit agent)
only take effect on a fresh session.

### Guided alternative

```bash
./install.sh
```

Prompts for identity, hashes a password, copies your hardware configuration into
place, and rebuilds.

> **Password.** Until `hashedPassword` is set in `vars.nix` (the installer does
> this), accounts are created with `initialPassword = "nixos"`. Change it
> immediately on any machine others can reach.

---

<a id="everyday-use"></a>

## ⚡ Everyday use

| Command | What it does |
|---|---|
| **`zenith update --rebuild`** | **pull updates and apply them — the everyday one** |
| `zenith update` | pull updates, do not rebuild yet |
| `zenith update --check` | what would an update change? changes nothing |
| `zenith rebuild [switch\|boot\|test]` | rebuild your own edits, without pulling |
| `zenith rollback` | boot the previous generation |
| `zenith gc [days]` | delete generations older than N days (default 7) |
| `zenith doctor` | check the things that commonly go wrong |
| `zenith shell` | restart the desktop shell |
| `zenith where` | print the config directory |

`zenith` finds the repository itself — `$ZENITH_DIR`, `~/zenith/zenith-nixos`,
`~/.config/zenith-nixos`, `~/zenith-nixos`, then `/etc/nixos` — so it works
wherever you cloned it, and always targets the current hostname.

It uses [`nh`](https://github.com/viperML/nh) when present, which prints a
readable diff of what actually changed, and falls back to `nixos-rebuild`
otherwise.

### `zenith doctor`

Run it first whenever something is wrong. It checks that your host directory
exists, that `vars.nix` matches the user running it, that a polkit agent is
running, that libvirt's default network is up, whether battery charge limiting
is writable without a password, and how large the store has grown.

---

<a id="configuring-it"></a>

## ⚙️ Configuring it

| To change | Edit |
|---|---|
| Username, hostname, timezone, GPU | `vars.nix` |
| Disks, filesystems, kernel modules | `hosts/<hostname>/hardware-configuration.nix` |
| System services, drivers, boot | `modules/core/*.nix` |
| Your programs and dotfiles | `modules/home/*.nix` |
| Installed packages | `modules/home/packages/*.nix` |
| Hyprland keybindings, window rules, **monitor resolution** | the [Hyprland-dots](https://github.com/zaeemali272/Hyprland-dots) repo |
| Bar and menus | the [zenith-shell](https://github.com/zaeemali272/zenith-shell) repo |

**Monitors are not configured here.** Resolution and layout live in
`Hyprland-dots/hyprland.lua` (`hl.monitor`), which defaults to
`mode = "preferred"` — your display's native mode. Override per-machine in
`~/.config/hypr/hypr-vars.lua` without touching a tracked file.

After any change:

```bash
zenith rebuild
```

---

<a id="layout"></a>

## 📂 Repository layout

```
zenith-nixos
├── flake.nix              inputs, and host discovery from hosts/
├── vars.nix               ← your identity and machine preferences
├── update.sh              what `zenith update` runs
├── install.sh             guided first-time setup
│
├── hosts/
│   └── <hostname>/        one directory per machine, named after its hostname
│       ├── default.nix    imports modules/core, sets networking.hostName
│       └── hardware-configuration.nix   ← generated per machine, never shared
│
└── modules/
    ├── core/              system: boot, drivers, services, users
    └── home/              home-manager: shell, editors, theming
        └── packages/      package lists by category
```

<sub>The two files marked ← are yours. Everything else is shared and updates cleanly.</sub>

---

<a id="updates"></a>

## 🛡️ How updates protect your machine

`.gitattributes` marks the files that belong to your machine:

```
vars.nix                            merge=ours
hosts/*/hardware-configuration.nix  merge=ours
hosts/*/default.nix                 merge=ours
```

Git keeps **your** version of these during a merge, even when an update changes
the same file. Everything else merges normally, so you still receive fixes.

`zenith update` also commits any uncommitted work first — nothing is ever
discarded — verifies that your host still evaluates before rebuilding, and stops
with instructions if a genuine conflict needs a decision from you.

---

<a id="troubleshooting"></a>

## 🩺 Troubleshooting

> Run **`zenith doctor`** first — it checks everything below and prints the fix.

<details>
<summary><b>Emergency mode after a rebuild</b></summary>

Your `hardware-configuration.nix` does not match this machine. Boot the previous
generation from the boot menu, then regenerate it:

```bash
sudo nixos-generate-config --show-hardware-config > hosts/$(hostname)/hardware-configuration.nix
```
</details>

<details>
<summary><b>"hosts/&lt;name&gt; does not evaluate"</b></summary>

Your host directory is missing or broken. `zenith doctor` prints the exact
commands to create it.
</details>

<details>
<summary><b>No password prompt appears, and privileged actions do nothing</b></summary>

No polkit agent is running — polkit decides *whether* an action is allowed, but
the agent is what draws the dialog. `security.nix` installs `hyprpolkitagent`;
rebuild and start a new session.
</details>

<details>
<summary><b>VMs will not start: <code>network 'default' is not active</code></b></summary>

libvirt ships that network defined but stopped. `virtualization.nix` starts it on
boot; until you rebuild:

```bash
sudo virsh net-start default && sudo virsh net-autostart default
```
</details>

<details>
<summary><b>Battery charge limit will not toggle</b></summary>

The sysfs node is root-owned. `battery-care.nix` adds a udev rule granting the
`wheel` group write access — udev rules apply on device add, so **reboot** after
rebuilding.
</details>

<details>
<summary><b><code>/boot</code> is full</b></summary>

Too many generations kept their kernels on the ESP.

```bash
zenith gc 7
```

`configurationLimit = 10` prevents it recurring.
</details>

<details>
<summary><b>A merge conflict during update</b></summary>

`zenith update` stops and lists the files. Resolve them, then
`git add <files> && git commit`. To abandon the update: `git merge --abort`.
</details>

---

<a id="rollback"></a>

## ↩️ Rolling back

Every rebuild creates a generation; nothing is destroyed.

```bash
zenith rollback                  # previous generation
sudo nix-env --list-generations -p /nix/var/nix/profiles/system
sudo nixos-rebuild switch --rollback
```

Older generations are also selectable from the boot menu.

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).

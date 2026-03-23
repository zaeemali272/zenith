# 🌌 Zenith: The Ultimate Arch Linux Experience

Welcome to **Zenith**, a meticulously crafted, performance-oriented, and aesthetically stunning Arch Linux environment powered by **Hyprland**. Zenith isn't just a set of dotfiles; it's a complete automation suite designed to transform a fresh Arch install into a powerful, modern workstation with zero friction.

---

## 🚀 The Zenith Philosophy
Zenith is built on three pillars:
1.  **Automation**: From mirrors to hardware drivers, everything is handled for you.
2.  **Performance**: System-level optimizations (ZRAM, Pacman tuning, Makepkg) ensure your hardware runs at its peak.
3.  **Aesthetics**: A cohesive, modern look using Material Design principles and intuitive UX.

---

## 🏃 How to Run It

Ready to reach the Zenith? Run the following command in your terminal:

```bash
git clone https://github.com/zaeemali272/zenith.git
cd zenith
./install.sh
```

### Installation Modes
1.  **Minimal Installation (Recommended)**: Installs the base system and sets up the Post-boot GUI installer. This is the fastest way to get started.
2.  **Full Installation**: Installs everything (Gaming, Themes, Extras) in one go.
3.  **Configs Only**: Only syncs your dotfiles without installing packages.

---


## 🛠️ What Happens During Installation?

The `install.sh` script is the orchestrator of the Zenith experience. Here is a breakdown of the process:

### 1. System Preparation & Tuning
*   **Mirror Optimization**: Uses `reflector` to find the fastest Arch mirrors in your region.
*   **Pacman Tuning**: Enables parallel downloads (10) and adds some "eye candy" to the terminal.
*   **Makepkg Speedup**: Configures `makepkg` to use all available CPU cores for faster AUR builds.
*   **ZRAM Configuration**: Automatically sets up ZRAM with ZSTD compression for superior memory management and system responsiveness.

### 2. Intelligent Hardware Detection
Zenith identifies your hardware and installs the correct drivers automatically:
*   **GPUs**: Proprietary drivers for **NVIDIA**, open-source drivers for **AMD** and **Intel**.
*   **Laptops**: Installs `tlp`, `acpi`, and `brightnessctl` for power management and battery health.
*   **Virtualization**: Detects if you are in a VM (VirtualBox, VMware, KVM) and installs guest utilities.
*   **Peripherals**: Sets up Bluetooth (`bluez`) and Audio (`pipewire`) out of the box.

### 3. Core Software Stack
Zenith pulls in a curated list of modern, efficient tools:
*   **Window Manager**: [Hyprland](https://hyprland.org/) (Wayland)
*   **Shell**: [Fish](https://fishshell.com/) with [Starship](https://starship.rs/) prompt.
*   **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
*   **File Manager**: [Thunar](https://docs.xfce.org/xfce/thunar/start) (with archive and volume plugins).
*   **Editor**: [Zed](https://zed.dev/) & [VS Code](https://code.visualstudio.com/).
*   **App Launcher**: [Anyrun](https://github.com/Kirogi/anyrun).
*   **System Monitor**: `glances` & `ncdu`.

### 4. Zero-Touch Experience (The Magic)
Zenith is designed to get you into your environment without a single extra keystroke:
*   **TTY1 Autologin**: Configures systemd to automatically log your user into TTY1 upon boot.
*   **Auto-Hyprland**: Your Fish shell detects if you are on TTY1 and automatically executes the Hyprland compositor.
*   **Post-Boot UI**: After the first reboot, a custom **Zenith-Shell** (powered by Quickshell) window appears to guide you through the final steps of the installation.

---

## 📦 Services & Packages

### System Services
*   **iwd**: Fast and modern wireless daemon (replaces NetworkManager for better performance).
*   **bluez**: Bluetooth support with an auto-fix service for reliability.
*   **zram-generator**: Manages high-speed swap in RAM.
*   **pipewire**: The modern standard for audio/video handling on Linux.
*   **fusuma**: Multitouch gesture support for laptops.

### Themes & Fonts
*   **GTK/Kvantum**: [Dynamic Materia Dark](https://github.com/zaeemali272/dynamic-materia-dark) for a consistent, dark aesthetic.
*   **Icons**: [OneUI Dark](https://github.com/vinceliuice/oneUI-icon-theme) icons for a clean, professional look.
*   **Cursors**: [Bibata Modern Classic](https://github.com/ful1e5/Bibata_Cursor).
*   **Fonts**:
    *   **Interface**: Noto Sans / Noto CJK.
    *   **Monospace**: JetBrains Mono Nerd Font.
    *   **Icons**: Material Design Icons & Symbols.

---

## 📂 Project Structure

```text
zenith/
├── .config/             # Comprehensive dotfiles for all apps
├── .themes/             # Custom GTK and Kvantum themes
├── modules/             # Modular bash scripts for installation logic
│   ├── hardware.sh      # GPU/Laptop/VM detection
│   ├── packages.sh      # Package installation logic
│   └── services.sh      # Systemd service configuration
├── pkgs/
│   └── packages.json    # The master list of all software
├── scripts/             # Extra utility scripts (VM setup, audio fixes, etc.)
└── install.sh           # The main entry point
```

---

## 🧩 Documentation for New Users

### Why did my screen just go black?
Don't panic! During the "Full" or "Minimal" installation, the script will reboot your computer. Upon reboot:
1.  **Autologin** will kick in on TTY1.
2.  **Hyprland** will start automatically.
3.  The **Zenith Post-Boot Installer** will open to finish the setup.

### How do I change my wallpaper?
Zenith uses `swww` for wallpaper management. You can find your wallpapers in `~/Pictures/Wallpapers`.

### How do I update?
Simply `cd` into your `zenith` directory, run `git pull`, and then run `bash install.sh` and select **Configs Only** to sync the latest changes, or **Packages Only** to ensure you have all new dependencies.

### Keybinds
*   **Mod (Super) + Q**: Open Kitty Terminal
*   **Mod (Super) + E**: Open Thunar File Manager
*   **Mod (Super) + R**: Open App Launcher (Anyrun)
*   **Mod (Super) + B**: Open Zen Browser
*   **Mod (Super) + Ctrl + T**: Open Wallpaper Selector
*   **Mod (Super) + Ctrl + K**: Open Keybinds

---

**Welcome to Zenith. Your Arch experience, perfected.**

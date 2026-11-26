{ pkgs, vars, lib, ... }:

{
  services.udisks2.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = lib.mkDefault (vars.gpu == "intel");
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
  services.dbus.enable = true;
  services.fstrim.enable = true;

  # Disable direct poweroff on power button tap so Hyprland/zenith-shell can open the power menu instead
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Enable Gnome Keyring for secret service API (org.freedesktop.secrets)
  services.gnome.gnome-keyring.enable = true;

  # AnyDesk package (service available on-demand, not started on boot)
  systemd.packages = [ pkgs.anydesk ];
  systemd.services.anydesk.wantedBy = [ ];

  # System activation script that runs on boot/rebuild:
  # Ensures dotfile symlinks (~/.config/hypr -> ~/zenith/Hyprland-dots, ~/.config/quickshell -> ~/zenith/zenith-shell)
  # exist locally without making network calls or deleting working symlinks on boot.
  system.activationScripts.syncDotfilesAndShell = {
    text = ''
      USER="${vars.user}"
      USER_HOME="/home/$USER"
      CONFIG_DIR="$USER_HOME/.config"
      REPO_ROOT="$(dirname "${vars.configDir or "/home/${vars.user}/zenith/zenith-nixos"}")"
      ZENITH_DIR="$USER_HOME/zenith"
      if [ -d "$REPO_ROOT/Hyprland-dots" ]; then
        ZENITH_DIR="$REPO_ROOT"
      fi
      CHMOD="${pkgs.coreutils}/bin/chmod"
      CHOWN="${pkgs.coreutils}/bin/chown"
      FIND="${pkgs.findutils}/bin/find"

      if [ -d "$USER_HOME" ]; then
        mkdir -p "$CONFIG_DIR"

        HYPR_DIR="$CONFIG_DIR/hypr"
        QUICKSHELL_DIR="$CONFIG_DIR/quickshell"

        # Ensure Hyprland symlink exists if local repo exists and link is missing
        if [ -d "$ZENITH_DIR/Hyprland-dots" ]; then
          if [ ! -e "$HYPR_DIR" ] && [ ! -L "$HYPR_DIR" ]; then
            ln -sf "$ZENITH_DIR/Hyprland-dots" "$HYPR_DIR"
          fi
          $FIND "$ZENITH_DIR/Hyprland-dots" -type f \( -name "*.sh" -o -name "*.py" \) -exec $CHMOD +x {} + 2>/dev/null || true
        fi

        # Ensure Quickshell symlink exists if local repo exists and link is missing
        if [ -d "$ZENITH_DIR/zenith-shell" ]; then
          if [ ! -e "$QUICKSHELL_DIR" ] && [ ! -L "$QUICKSHELL_DIR" ]; then
            ln -sf "$ZENITH_DIR/zenith-shell" "$QUICKSHELL_DIR"
          fi
          $FIND "$ZENITH_DIR/zenith-shell" -type f \( -name "*.sh" -o -name "*.py" \) -exec $CHMOD +x {} + 2>/dev/null || true
        fi

        # Restore user ownership and ensure app data directories are fully writable
        GEMINI_DIR="$USER_HOME/.gemini"
        ANTIGRAVITY_CFG_DIR="$USER_HOME/.config/antigravity"
        mkdir -p "$GEMINI_DIR" "$ANTIGRAVITY_CFG_DIR"
        $CHOWN -R $USER:users "$GEMINI_DIR" "$USER_HOME/.config/antigravity"* 2>/dev/null || true
        $CHMOD -R u+rw "$GEMINI_DIR" "$USER_HOME/.config/antigravity"* 2>/dev/null || true
        [ -e "$HYPR_DIR" ] && $CHOWN -h $USER:users "$HYPR_DIR" 2>/dev/null || true
        [ -e "$QUICKSHELL_DIR" ] && $CHOWN -h $USER:users "$QUICKSHELL_DIR" 2>/dev/null || true
      fi
    '';
  };
}


{ pkgs, inputs, config, vars, lib, ... }:

{
  programs.quickshell = {
    enable = true;
    package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  home.packages = [
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
  ];

  # Disable Home Manager hyprland.conf generator to prevent collision with out-of-store hypr directory link
  wayland.windowManager.hyprland.enable = lib.mkForce false;

  # Disable nix-store symlinking for hypr and quickshell completely so Home Manager doesn't manage them as store symlinks
  xdg.configFile."hypr".enable = lib.mkForce false;
  xdg.configFile."quickshell".enable = lib.mkForce false;

  # Home Manager activation script that runs during `sudo nixos-rebuild switch`:
  # Checks every time if Hyprland-dots and zenith-shell repos are present & updated in ~/zenith,
  # links them to ~/.config/hypr and ~/.config/quickshell, and makes scripts executable (+x).
  home.activation.syncDotfilesAndShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    USER_HOME="/home/${vars.user}"
    ZENITH_DIR="$USER_HOME/zenith"
    CONFIG_DIR="$USER_HOME/.config"
    GIT="${pkgs.git}/bin/git"
    CHMOD="${pkgs.coreutils}/bin/chmod"
    FIND="${pkgs.findutils}/bin/find"
    SU="${pkgs.shadow}/bin/su"

    $DRY_RUN_CMD mkdir -p "$ZENITH_DIR" "$CONFIG_DIR"

    # Helper function to sync a repo in ~/zenith and link it to ~/.config
    sync_and_link() {
      repo_name="$1"
      repo_url="$2"
      target_link="$3"

      src_dir="$ZENITH_DIR/$repo_name"

      # 1. Clone or pull repository
      if [ ! -d "$src_dir" ]; then
        echo "[Dotfiles Sync] Cloning $repo_name into $src_dir..."
        $SU -s ${pkgs.bash}/bin/bash ${vars.user} -c "$GIT clone '$repo_url' '$src_dir'" || true
      else
        if [ -d "$src_dir/.git" ]; then
          echo "[Dotfiles Sync] Updating $repo_name in $src_dir..."
          $SU -s ${pkgs.bash}/bin/bash ${vars.user} -c "$GIT -C '$src_dir' pull --rebase origin main" || true
        fi
      fi

      # 2. Make scripts executable
      if [ -d "$src_dir" ]; then
        $FIND "$src_dir" -type f \( -name "*.sh" -o -name "*.py" \) -exec $CHMOD +x {} + 2>/dev/null || true
      fi

      # 3. Ensure target in ~/.config is a symlink pointing to ~/zenith/$repo_name
      if [ -e "$target_link" ] && [ ! -L "$target_link" ]; then
        # If target exists as a regular directory (not a symlink), replace it with a symlink
        echo "[Dotfiles Sync] Replacing directory $target_link with symlink to $src_dir"
        rm -rf "$target_link"
      fi

      if [ ! -L "$target_link" ]; then
        echo "[Dotfiles Sync] Symlinking $target_link -> $src_dir"
        ln -s "$src_dir" "$target_link"
      fi

      chown -h ${vars.user}:users "$target_link" 2>/dev/null || true
      if [ -d "$src_dir" ]; then
        chown -R ${vars.user}:users "$src_dir" 2>/dev/null || true
      fi
    }

    sync_and_link "Hyprland-dots" "https://github.com/zaeemali272/Hyprland-dots.git" "$CONFIG_DIR/hypr"
    sync_and_link "zenith-shell" "https://github.com/zaeemali272/zenith-shell.git" "$CONFIG_DIR/quickshell"
  '';
}
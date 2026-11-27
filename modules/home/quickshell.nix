{ pkgs, inputs, config, vars, lib, ... }:

let
  end4-shell = pkgs.writeShellScriptBin "end4-shell" ''
    export QML_IMPORT_PATH="${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml:${pkgs.kdePackages.syntax-highlighting}/lib/qt-6/qml:${pkgs.kdePackages.qtpositioning}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml:${pkgs.kdePackages.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qtsvg}/lib/qt-6/qml:/etc/profiles/per-user/$USER/lib/qt-6/qml:''${QML_IMPORT_PATH:-}"
    export PATH="${lib.makeBinPath [ pkgs.imagemagick pkgs.procps pkgs.coreutils ]}:$PATH"
    SHELL_DIR="${inputs.end-4-dots}/dots/.config/quickshell/ii"
    if [ -d "$HOME/zenith/end-4-dots/dots/.config/quickshell/ii" ]; then
      SHELL_DIR="$HOME/zenith/end-4-dots/dots/.config/quickshell/ii"
    fi
    exec ${inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/quickshell -p "$SHELL_DIR" "$@"
  '';
in
{
  programs.quickshell = {
    enable = true;
    package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  home.packages = with pkgs; [
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    end4-shell
    kdePackages.qt5compat
    kdePackages.qtmultimedia
    kdePackages.qtsvg
    kdePackages.qtpositioning
    kdePackages.kirigami
    kdePackages.kirigami.unwrapped
    kdePackages.syntax-highlighting
    imagemagick
  ];

  home.sessionVariables = {
    QML_IMPORT_PATH = "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml:${pkgs.kdePackages.syntax-highlighting}/lib/qt-6/qml:${pkgs.kdePackages.qtpositioning}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml:${pkgs.kdePackages.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qtsvg}/lib/qt-6/qml:/etc/profiles/per-user/${vars.user}/lib/qt-6/qml:\${QML_IMPORT_PATH:-}";
  };

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
        $SU -s ${pkgs.bash}/bin/bash ${vars.user} -c "$GIT clone --recurse-submodules '$repo_url' '$src_dir'" || true
      else
        if [ -d "$src_dir/.git" ]; then
          echo "[Dotfiles Sync] Updating $repo_name in $src_dir..."
          $SU -s ${pkgs.bash}/bin/bash ${vars.user} -c "$GIT -C '$src_dir' pull --rebase origin main && $GIT -C '$src_dir' submodule update --init --recursive" || true
        fi
      fi

      # 2. Make scripts executable
      if [ -d "$src_dir" ]; then
        $FIND "$src_dir" -type f \( -name "*.sh" -o -name "*.py" \) -exec $CHMOD +x {} + 2>/dev/null || true
      fi

      # 3. Ensure target in ~/.config is a symlink pointing to ~/zenith/$repo_name
      if [ -n "$target_link" ]; then
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
      fi

      if [ -d "$src_dir" ]; then
        chown -R ${vars.user}:users "$src_dir" 2>/dev/null || true
      fi
    }

    if [ -d "$USER_HOME/zenith/zenith/dots/hypr" ]; then
      sync_and_link "zenith/dots/hypr" "" "$CONFIG_DIR/hypr"
    else
      sync_and_link "Hyprland-dots" "https://github.com/zaeemali272/Hyprland-dots.git" "$CONFIG_DIR/hypr"
    fi
    sync_and_link "zenith-shell" "https://github.com/zaeemali272/zenith-shell.git" "$CONFIG_DIR/quickshell"
  '';
}
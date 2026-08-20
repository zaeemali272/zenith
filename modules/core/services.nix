{ pkgs, vars, ... }:

{
  services.udisks2.enable = true;
  services.power-profiles-daemon.enable = true;
  services.dbus.enable = true;
  services.fstrim.enable = true;

  # Always run during `sudo nixos-rebuild switch`:
  # Checks if ~/.config/hypr & ~/.config/quickshell exist, clones/pulls them, and makes scripts executable (+x)
  system.activationScripts.syncDotfilesAndShell = {
    text = ''
      USER="${vars.user}"
      USER_HOME="/home/$USER"
      CONFIG_DIR="$USER_HOME/.config"
      GIT="${pkgs.git}/bin/git"
      CHMOD="${pkgs.coreutils}/bin/chmod"
      CHOWN="${pkgs.coreutils}/bin/chown"
      FIND="${pkgs.findutils}/bin/find"

      if [ -d "$USER_HOME" ]; then
        mkdir -p "$CONFIG_DIR"

        # Update a deployed config repo.
        #
        # This used to be `git pull --ff-only 2>/dev/null || true`, which turned
        # every failure into a silent no-op: one local edit made the pull
        # non-fast-forward, the reason went to /dev/null, and the machine sat on
        # a stale checkout through every later rebuild while reporting success.
        # Now local work is stashed (recoverable with `git stash pop`) so the
        # update always lands, and anything still wrong is printed instead of
        # hidden.
        sync_repo() {
          REPO_DIR="$1"
          REPO_URL="$2"
          REPO_NAME="$3"

          if [ -L "$REPO_DIR" ]; then
            rm -f "$REPO_DIR"
          fi

          if [ -d "$REPO_DIR" ] && [ ! -d "$REPO_DIR/.git" ]; then
            rm -rf "$REPO_DIR"
          fi

          if [ ! -d "$REPO_DIR" ]; then
            if ! $GIT clone "$REPO_URL" "$REPO_DIR"; then
              echo "zenith: could not clone $REPO_NAME into $REPO_DIR" >&2
              return 0
            fi
          else
            if ! $GIT -C "$REPO_DIR" fetch --quiet origin; then
              echo "zenith: could not reach the $REPO_NAME remote; keeping the current checkout" >&2
              return 0
            fi

            if ! $GIT -C "$REPO_DIR" merge --ff-only --quiet FETCH_HEAD 2>/dev/null; then
              # Local edits or a diverged branch. Park them rather than either
              # discarding them or giving up on the update.
              if $GIT -C "$REPO_DIR" -c user.email=zenith@localhost -c user.name=zenith \
                   stash push --include-untracked --quiet \
                   -m "zenith: saved before rebuild sync" 2>/dev/null; then
                echo "zenith: stashed local changes in $REPO_DIR (git stash pop to get them back)" >&2
              fi

              if ! $GIT -C "$REPO_DIR" merge --ff-only --quiet FETCH_HEAD 2>/dev/null; then
                echo "zenith: $REPO_NAME could not fast-forward, so it is out of date." >&2
                echo "zenith: fix it with: cd $REPO_DIR && git status" >&2
                return 0
              fi
            fi
          fi

          if [ -d "$REPO_DIR" ]; then
            $FIND "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec $CHMOD +x {} + 2>/dev/null || true
          fi
        }

        HYPR_DIR="$CONFIG_DIR/hypr"
        QUICKSHELL_DIR="$CONFIG_DIR/quickshell"

        sync_repo "$HYPR_DIR" "https://github.com/zaeemali272/Hyprland-dots.git" "Hyprland-dots"
        sync_repo "$QUICKSHELL_DIR" "https://github.com/zaeemali272/zenith-shell.git" "zenith-shell"

        # 3. Restore user ownership
        $CHOWN -R $USER:users "$HYPR_DIR" "$QUICKSHELL_DIR" 2>/dev/null || true
      fi
    '';
  };
}


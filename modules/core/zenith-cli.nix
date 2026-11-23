{ pkgs, vars, inputs, ... }:

let
  end4QmlPath = "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml:${pkgs.kdePackages.syntax-highlighting}/lib/qt-6/qml:${pkgs.kdePackages.qtpositioning}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml:${pkgs.kdePackages.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qtsvg}/lib/qt-6/qml:/etc/profiles/per-user/$USER/lib/qt-6/qml";

  zenith = pkgs.writeShellApplication {
    name = "zenith";
    runtimeInputs = with pkgs; [ git nix coreutils gnugrep gnused hostname findutils gawk procps ];
    text = ''
      # One entry point for the things you actually do to this system.
      #
      # The config directory is found rather than assumed, so it works whether
      # the repo lives in ~/zenith/zenith-nixos, /etc/nixos or somewhere set by
      # $ZENITH_DIR.

      BLUE=$'\033[1;34m'; GREEN=$'\033[1;32m'; RED=$'\033[1;31m'; YELLOW=$'\033[1;33m'; OFF=$'\033[0m'
      step() { printf '%s==>%s %s\n' "$BLUE" "$OFF" "$*"; }
      ok()   { printf '%s  ok%s %s\n' "$GREEN" "$OFF" "$*"; }
      warn() { printf '%s  !!%s %s\n' "$YELLOW" "$OFF" "$*"; }
      die()  { printf '%s error%s %s\n' "$RED" "$OFF" "$*" >&2; exit 1; }

      find_config() {
        for d in "''${ZENITH_DIR:-}" "$HOME/zenith/zenith-nixos" \
                 "$HOME/.config/zenith-nixos" "$HOME/zenith-nixos" /etc/nixos; do
          [ -n "$d" ] && [ -f "$d/flake.nix" ] && { printf '%s' "$d"; return 0; }
        done
        return 1
      }

      usage() {
        cat <<'USAGE'
      zenith - manage this NixOS system

        zenith update [--rebuild|--check]  pull config updates, keeping your machine files
        zenith rebuild [switch|boot|test]  rebuild this host (default: switch)
        zenith rollback                    boot the previous generation
        zenith gc [days]                   delete generations older than N days (default 7)
        zenith clean [days]                deep disk cleanup: gc, temp files, caches, and logs
        zenith doctor                      check the things that commonly go wrong
        zenith shell [switch|list|restart] manage & switch desktop shell (zenith, caelestia, end-4)
        zenith where                       print the config directory

      Anything after -- is passed through to nixos-rebuild.
      USAGE
      }

      CONFIG="$(find_config)" || die "no flake.nix found. Set ZENITH_DIR to your config directory."
      HOST="$(hostname)"

      cmd="''${1:-}"; shift || true

      case "$cmd" in
        update)
          [ -x "$CONFIG/update.sh" ] || die "update.sh missing from $CONFIG"
          exec "$CONFIG/update.sh" "$@"
          ;;

        rebuild)
          action="''${1:-switch}"
          [ -d "$CONFIG/hosts/$HOST" ] || die "no hosts/$HOST in $CONFIG -- see 'zenith doctor'"
          # nh when it is available: it shows a readable diff of what changed
          # and handles the sudo elevation itself. nixos-rebuild otherwise, so
          # this still works on a machine that has not enabled nh.
          if command -v nh >/dev/null 2>&1; then
            step "rebuilding $HOST ($action) via nh"
            exec nh os "$action" "$CONFIG#$HOST"
          else
            step "rebuilding $HOST ($action)"
            exec sudo nixos-rebuild "$action" --flake "$CONFIG#$HOST"
          fi
          ;;

        rollback)
          step "rolling back to the previous generation"
          exec sudo nixos-rebuild switch --rollback
          ;;

        gc)
          days="''${1:-7}"
          step "removing generations older than ''${days}d"
          sudo nix-collect-garbage --delete-older-than "''${days}d"
          nix-collect-garbage --delete-older-than "''${days}d" || true
          ok "done"
          ;;

        clean)
          days="''${1:-7}"
          step "1/5: running garbage collection (older than ''${days}d)"
          sudo nix-collect-garbage --delete-older-than "''${days}d" 2>/dev/null || nix-collect-garbage --delete-older-than "''${days}d" || true
          nix-collect-garbage --delete-older-than "''${days}d" || true
          ok "generations cleaned"

          step "2/5: removing build artifacts and temp files"
          rm -rf "$CONFIG/result" "$CONFIG"/result-* ~/result ~/result-* 2>/dev/null || true
          rm -rf /tmp/nix-* /tmp/nix-build-* /var/tmp/nix-* 2>/dev/null || true
          find /tmp -maxdepth 1 -user "$(id -u)" -mtime +2 -exec rm -rf {} + 2>/dev/null || true
          ok "temp files purged"

          step "3/5: clearing user cache files and trash"
          rm -rf "$HOME/.cache/nix" "$HOME/.cache/nh" "$HOME/.cache/nixpkgs-review" 2>/dev/null || true
          rm -rf "$HOME/.cache/thumbnails"/* 2>/dev/null || true
          rm -rf "$HOME/.cache/fontconfig" "$HOME/.cache/typescript" 2>/dev/null || true
          rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null || true
          ok "caches and trash emptied"

          step "4/5: vacuuming systemd journal logs"
          if [ "$(id -u)" -eq 0 ]; then
            journalctl --vacuum-time=2d --vacuum-size=50M 2>/dev/null || true
          elif command -v sudo >/dev/null 2>&1; then
            sudo journalctl --vacuum-time=2d --vacuum-size=50M 2>/dev/null || true
          else
            journalctl --user --vacuum-time=2d --vacuum-size=50M 2>/dev/null || true
          fi
          ok "journal logs vacuumed"

          step "5/5: optimizing nix store (hardlinking duplicates)"
          if [ "$(id -u)" -eq 0 ]; then
            nix-store --optimise 2>/dev/null || true
          elif command -v sudo >/dev/null 2>&1; then
            sudo nix-store --optimise 2>/dev/null || nix-store --optimise 2>/dev/null || true
          else
            nix-store --optimise 2>/dev/null || true
          fi
          ok "nix store optimized"

          step "disk space summary"
          df -h / | awk 'NR==1 || NR==2 {print "     " $0}'
          ok "cleanup complete"
          ;;

        where)
          printf '%s\n' "$CONFIG"
          ;;

        shell)
          sub="''${1:-}"
          reset_shell_themes() {
            # 1. Clean up stray GTK Thunar styles
            rm -f "$HOME/.config/gtk-3.0/thunar.css" "$HOME/.config/gtk-4.0/thunar.css" 2>/dev/null || true

            # 2. Reset duplicate fuzzel color blocks if any
            if [ -f "$HOME/.config/fuzzel/fuzzel.ini" ]; then
              sed -i '/^\[colors\]/{n;:a;/^\[/!{d;n;ba;}}' "$HOME/.config/fuzzel/fuzzel.ini" 2>/dev/null || true
            fi

            # 3. Reload Thunar daemon cleanly so file manager drops stale styling
            if command -v thunar >/dev/null 2>&1; then
              thunar -q 2>/dev/null || true
            fi
          }

          case "$sub" in
            list|ls)
              step "available desktop shells"
              current="zenith"
              if [ -f "$HOME/.config/zenith/active-shell" ]; then
                current="$(cat "$HOME/.config/zenith/active-shell" 2>/dev/null || echo "zenith")"
              fi
              for s in zenith caelestia end-4; do
                if [ "$s" = "$current" ]; then
                  printf '  * %s%s%s (active)\n' "$GREEN" "$s" "$OFF"
                else
                  printf '    %s\n' "$s"
                fi
              done
              ;;

            switch|use)
              target="''${2:-}"
              [ -n "$target" ] || die "usage: zenith shell switch <zenith|caelestia|end-4>"
              case "$target" in
                zenith)
                  step "switching desktop shell to zenith..."
                  mkdir -p "$HOME/.config/zenith"
                  printf '%s' "zenith" > "$HOME/.config/zenith/active-shell"
                  if [ -x "$HOME/.config/quickshell/launch.sh" ]; then
                    "$HOME/.config/quickshell/launch.sh" stop 2>/dev/null || true
                  fi
                  pkill -f 'caelestia-shell' 2>/dev/null || true
                  pkill -f '^quickshell( |$)' 2>/dev/null || true
                  reset_shell_themes
                  if command -v dconf >/dev/null 2>&1; then
                    dconf write /org/gnome/desktop/interface/gtk-theme "'Orchis-Dark'" 2>/dev/null || true
                    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
                  fi
                  if command -v gsettings >/dev/null 2>&1; then
                    gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark' 2>/dev/null || true
                    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
                  fi
                  sleep 1
                  if [ -x "$HOME/.config/quickshell/launch.sh" ]; then
                    "$HOME/.config/quickshell/launch.sh" start
                  else
                    (setsid quickshell -d >/dev/null 2>&1 &)
                  fi
                  if [ -x "$HOME/.config/quickshell/scripts/zenith-theme.sh" ]; then
                    "$HOME/.config/quickshell/scripts/zenith-theme.sh" --current >/dev/null 2>&1 || true
                  fi
                  if command -v hyprctl >/dev/null 2>&1; then
                    hyprctl reload >/dev/null 2>&1 || true
                  fi
                  ok "switched to zenith shell"
                  ;;
                caelestia)
                  step "switching desktop shell to caelestia..."
                  mkdir -p "$HOME/.config/zenith"
                  printf '%s' "caelestia" > "$HOME/.config/zenith/active-shell"
                  if [ -x "$HOME/.config/quickshell/launch.sh" ]; then
                    "$HOME/.config/quickshell/launch.sh" stop 2>/dev/null || true
                  fi
                  pkill -f '^quickshell( |$)' 2>/dev/null || true
                  pkill -f 'caelestia-shell' 2>/dev/null || true
                  reset_shell_themes
                  if command -v caelestia >/dev/null 2>&1; then
                    caelestia scheme set -n dynamic 2>/dev/null || true
                    curr_wall=""
                    if [ -f "$HOME/.local/state/caelestia/wallpaper/path.txt" ]; then
                      curr_wall="$(cat "$HOME/.local/state/caelestia/wallpaper/path.txt" 2>/dev/null || true)"
                    elif [ -f "$HOME/.current_wallpaper" ]; then
                      curr_wall="$(cat "$HOME/.current_wallpaper" 2>/dev/null || true)"
                    fi
                    if [ -n "$curr_wall" ] && [ -f "$curr_wall" ]; then
                      caelestia wallpaper -f "$curr_wall" >/dev/null 2>&1 || true
                    fi
                  fi
                  sleep 1
                  if command -v caelestia-shell >/dev/null 2>&1; then
                    (setsid caelestia-shell -d >/dev/null 2>&1 &)
                  else
                    die "caelestia-shell is not installed or not in PATH"
                  fi
                  if command -v hyprctl >/dev/null 2>&1; then
                    hyprctl reload >/dev/null 2>&1 || true
                  fi
                  ok "switched to caelestia shell"
                  ;;
                end-4)
                  step "switching desktop shell to end-4..."
                  mkdir -p "$HOME/.config/zenith"
                  printf '%s' "end-4" > "$HOME/.config/zenith/active-shell"
                  if [ -x "$HOME/.config/quickshell/launch.sh" ]; then
                    "$HOME/.config/quickshell/launch.sh" stop 2>/dev/null || true
                  fi
                  pkill -f 'caelestia-shell' 2>/dev/null || true
                  pkill -f '^quickshell( |$)' 2>/dev/null || true
                  reset_shell_themes
                  sleep 1
                  if command -v end4-shell >/dev/null 2>&1; then
                    (setsid end4-shell -d >/tmp/quickshell-end4.log 2>&1 &)
                  else
                    export QML_IMPORT_PATH="${end4QmlPath}:''${QML_IMPORT_PATH:-}"
                    (setsid quickshell -d -p "${inputs.end-4-dots}/dots/.config/quickshell/ii" >/tmp/quickshell-end4.log 2>&1 &)
                  fi
                  if command -v hyprctl >/dev/null 2>&1; then
                    hyprctl reload >/dev/null 2>&1 || true
                  fi
                  ok "switched to end-4 shell"
                  ;;
                *)
                  die "unknown shell: $target (available: zenith, caelestia, end-4)"
                  ;;
              esac
              ;;

            start)
              current="zenith"
              if [ -f "$HOME/.config/zenith/active-shell" ]; then
                current="$(cat "$HOME/.config/zenith/active-shell" 2>/dev/null || echo "zenith")"
              fi
              if [ "$current" = "caelestia" ] && command -v caelestia-shell >/dev/null 2>&1; then
                (setsid caelestia-shell -d >/dev/null 2>&1 &)
              elif [ "$current" = "end-4" ]; then
                if command -v end4-shell >/dev/null 2>&1; then
                  (setsid end4-shell -d >/tmp/quickshell-end4.log 2>&1 &)
                else
                  export QML_IMPORT_PATH="${end4QmlPath}:''${QML_IMPORT_PATH:-}"
                  (setsid quickshell -d -p "${inputs.end-4-dots}/dots/.config/quickshell/ii" >/tmp/quickshell-end4.log 2>&1 &)
                fi
              else
                if [ -x "$HOME/.config/quickshell/launch.sh" ]; then
                  "$HOME/.config/quickshell/launch.sh" start
                else
                  (setsid quickshell -d >/dev/null 2>&1 &)
                fi
              fi
              ;;

            restart|"")
              step "restarting the active desktop shell"
              current="zenith"
              if [ -f "$HOME/.config/zenith/active-shell" ]; then
                current="$(cat "$HOME/.config/zenith/active-shell" 2>/dev/null || echo "zenith")"
              fi
              if [ "$current" = "caelestia" ]; then
                pkill -f 'caelestia-shell' 2>/dev/null || true
                sleep 1
                (setsid caelestia-shell -d >/dev/null 2>&1 &)
                ok "caelestia shell restarted"
              elif [ "$current" = "end-4" ]; then
                pkill -f '^quickshell( |$)' 2>/dev/null || true
                sleep 1
                if command -v end4-shell >/dev/null 2>&1; then
                  (setsid end4-shell -d >/tmp/quickshell-end4.log 2>&1 &)
                else
                  export QML_IMPORT_PATH="${end4QmlPath}:''${QML_IMPORT_PATH:-}"
                  (setsid quickshell -d -p "${inputs.end-4-dots}/dots/.config/quickshell/ii" >/tmp/quickshell-end4.log 2>&1 &)
                fi
                ok "end-4 shell restarted"
              else
                if [ -x "$HOME/.config/quickshell/launch.sh" ]; then
                  "$HOME/.config/quickshell/launch.sh" restart
                else
                  pkill -f '^quickshell( |$)' 2>/dev/null || true
                  sleep 1
                  (setsid quickshell -d >/dev/null 2>&1 &)
                fi
                ok "zenith shell restarted"
              fi
              ;;

            *)
              die "unknown shell subcommand: $sub (try 'zenith shell switch <name>' or 'zenith shell list')"
              ;;
          esac
          ;;

        doctor)
          step "config"
          printf '     directory: %s\n' "$CONFIG"
          printf '     hostname:  %s\n' "$HOST"
          if [ -d "$CONFIG/hosts/$HOST" ]; then
            ok "hosts/$HOST exists"
          else
            warn "no hosts/$HOST -- this host cannot be built"
            printf '       mkdir -p %s/hosts/%s\n' "$CONFIG" "$HOST"
            printf '       sudo nixos-generate-config --show-hardware-config > %s/hosts/%s/hardware-configuration.nix\n' "$CONFIG" "$HOST"
          fi

          step "identity"
          # Compared against whoever is running this, not against a hardcoded
          # name -- otherwise the author of the config gets warned about their
          # own perfectly correct configuration.
          configured="$(sed -n 's/.*user[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG/vars.nix" 2>/dev/null | head -1)"
          if [ -z "$configured" ]; then
            warn "could not read user from vars.nix"
          elif [ "$configured" = "$(id -un)" ]; then
            ok "vars.nix user is $configured"
          else
            warn "vars.nix says user = \"$configured\" but you are $(id -un)"
            printf '       edit %s/vars.nix before rebuilding\n' "$CONFIG"
          fi

          step "desktop session"
          if pgrep -f 'polkitagent|polkit-gnome|polkit-kde' >/dev/null 2>&1; then
            ok "a polkit agent is running"
          else
            warn "no polkit agent -- privileged actions will fail silently"
          fi

          step "virtualisation"
          if command -v virsh >/dev/null 2>&1; then
            state="$(virsh -c qemu:///system net-info default 2>/dev/null | grep -i '^Active' | awk '{print $2}')"
            case "$state" in
              yes) ok "libvirt default network is active" ;;
              no)  warn "libvirt default network is inactive -- VMs will refuse to start"
                   printf '       sudo virsh net-start default && sudo virsh net-autostart default\n' ;;
              *)   printf '     libvirt not reporting a default network\n' ;;
            esac
          fi

          step "battery care"
          node=""
          for candidate in /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode \
                           /sys/class/power_supply/*/charge_control_end_threshold; do
            [ -e "$candidate" ] && { node="$candidate"; break; }
          done
          if [ -n "$node" ]; then
            if [ -w "$node" ]; then
              ok "charge limit is writable without a password"
            else
              warn "charge limit is read-only -- the desktop toggle needs a password prompt"
              printf '       a udev rule in modules/core/battery-care.nix fixes this; rebuild and reboot\n'
            fi
          fi

          step "store"
          printf '     %s\n' "$(du -sh /nix/store 2>/dev/null | cut -f1) in /nix/store"
          printf '     %s system generations\n' "$(sudo nix-env --list-generations -p /nix/var/nix/profiles/system 2>/dev/null | wc -l)"
          ;;

        ""|-h|--help|help) usage ;;
        *) die "unknown command: $cmd (try 'zenith help')" ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ zenith ];
}

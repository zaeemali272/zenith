{ pkgs, vars, ... }:

let
  zenith = pkgs.writeShellApplication {
    name = "zenith";
    runtimeInputs = with pkgs; [ git nix coreutils gnugrep gnused hostname ];
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
        zenith doctor                      check the things that commonly go wrong
        zenith shell                       restart the desktop shell
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

        where)
          printf '%s\n' "$CONFIG"
          ;;

        shell)
          step "restarting the desktop shell"
          pkill -x quickshell 2>/dev/null || true
          sleep 1
          (setsid quickshell -d >/dev/null 2>&1 &)
          ok "restarted"
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

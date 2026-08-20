#!/usr/bin/env bash
# Create the host entry for this machine.
#
# The flake discovers hosts from hosts/<hostname>/, so a machine with no
# matching directory fails with a raw nix error:
#
#   flake ... does not provide attribute 'nixosConfigurations."CB"...'
#   Did you mean vm?
#
# which says nothing about what to do. This creates the directory, generates the
# hardware configuration for this machine, and tells you what is left to edit.
set -uo pipefail

cd "$(dirname "$(readlink -f "$0")")" || exit 1

GREEN=$'\033[1;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[1;31m'; BLUE=$'\033[1;34m'; OFF=$'\033[0m'
ok()   { printf '%s  ok%s %s\n' "$GREEN" "$OFF" "$*"; }
warn() { printf '%s  !!%s %s\n' "$YELLOW" "$OFF" "$*"; }
step() { printf '%s==>%s %s\n' "$BLUE" "$OFF" "$*"; }
die()  { printf '%serror%s %s\n' "$RED" "$OFF" "$*" >&2; exit 1; }

HOST="${1:-$(hostname)}"
[[ -n "$HOST" ]] || die "could not determine the hostname; pass one: ./new-host.sh myhost"

step "Setting up hosts/$HOST"

CREATED_DIR=0
if [[ -d "hosts/$HOST" ]]; then
    ok "hosts/$HOST already exists"
else
    mkdir -p "hosts/$HOST" || die "could not create hosts/$HOST"
    CREATED_DIR=1
    ok "created hosts/$HOST"
fi

# A half-created host is worse than none: the flake discovers every directory
# under hosts/, so one without a default.nix breaks *every* build on the
# machine, not just this host. Undo it if we bail out before it is complete.
cleanup_partial() {
    if [[ $CREATED_DIR -eq 1 && ! -s "hosts/$HOST/default.nix" ]]; then
        rm -rf "hosts/$HOST"
        printf '  cleaned up the incomplete hosts/%s\n' "$HOST"
    fi
}
trap cleanup_partial EXIT

# --- hardware configuration -------------------------------------------------
HW="hosts/$HOST/hardware-configuration.nix"
if [[ -s "$HW" ]] && ! grep -q "placeholder" "$HW" 2>/dev/null; then
    ok "$HW already present"
elif command -v nixos-generate-config >/dev/null 2>&1; then
    step "Generating $HW for this machine"
    if sudo nixos-generate-config --show-hardware-config > "$HW.tmp" 2>/dev/null && [[ -s "$HW.tmp" ]]; then
        mv "$HW.tmp" "$HW"
        ok "generated from this machine's disks"
    else
        rm -f "$HW.tmp"
        die "nixos-generate-config failed. Run it yourself:
       sudo nixos-generate-config --show-hardware-config > $HW"
    fi
else
    die "nixos-generate-config not found; are you on NixOS?"
fi

# --- host module ------------------------------------------------------------
DEF="hosts/$HOST/default.nix"
if [[ -f "$DEF" ]]; then
    ok "$DEF already present"
else
    cat > "$DEF" <<EOF
# $HOST
{ config, pkgs, vars, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
  ];

  networking.hostName = "$HOST";
}
EOF
    ok "wrote $DEF"
fi
CREATED_DIR=0   # hosts/$HOST is complete now; nothing to undo

# Nix reads a git repository's flake from the *tracked* tree, not the working
# directory. An untracked hosts/$HOST is invisible to builtins.readDir, so the
# rebuild fails with the exact same "does not provide attribute" error as if the
# directory had never been made. Stage it so the flake can see it.
if git rev-parse --git-dir >/dev/null 2>&1; then
    step "Making hosts/$HOST visible to the flake"
    if git add --intent-to-add "hosts/$HOST" 2>/dev/null && git add "hosts/$HOST" 2>/dev/null; then
        ok "staged hosts/$HOST (git tracks it now; commit when you are ready)"
    else
        warn "could not stage hosts/$HOST automatically"
        printf '      nix only sees tracked files, so run this before rebuilding:\n'
        printf '      git add hosts/%s\n' "$HOST"
    fi

    # vars.nix is merge=ours and often already modified; that is expected and
    # does not affect discovery. Only untracked *host* files break the build.
    untracked="$(git ls-files --others --exclude-standard hosts/ 2>/dev/null)"
    if [[ -n "$untracked" ]]; then
        warn "these files under hosts/ are untracked and invisible to nix:"
        printf '      %s\n' $untracked
        printf '      git add hosts/\n'
    fi
fi

# --- vars.nix ---------------------------------------------------------------
step "Checking vars.nix"
CURRENT_USER="$(sed -n 's/.*user[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' vars.nix | head -1)"
CURRENT_HOST="$(sed -n 's/.*hostname[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' vars.nix | head -1)"
NEEDS_EDIT=0

if [[ "$CURRENT_USER" != "$(id -un)" ]]; then
    warn "vars.nix has user = \"$CURRENT_USER\" but you are $(id -un)"
    NEEDS_EDIT=1
fi
if [[ "$CURRENT_HOST" != "$HOST" ]]; then
    warn "vars.nix has hostname = \"$CURRENT_HOST\" but this machine is $HOST"
    NEEDS_EDIT=1
fi

if [[ $NEEDS_EDIT -eq 1 ]]; then
    printf '\n  Edit %svars.nix%s before building - at minimum:\n\n' "$YELLOW" "$OFF"
    printf '      user      = "%s";\n' "$(id -un)"
    printf '      hostname  = "%s";\n' "$HOST"
    printf '      configDir = "%s";\n' "$PWD"
    printf '      email, timeZone, gpu ("intel" | "amd" | "nvidia")\n\n'
    printf '  Then:  sudo nixos-rebuild switch --flake %s\n\n' "$PWD"
    exit 0
fi

ok "vars.nix matches this machine"

step "Checking the configuration evaluates"
if nix eval --raw ".#nixosConfigurations.$HOST.config.networking.hostName" >/dev/null 2>&1; then
    ok "hosts/$HOST evaluates"
    printf '\n  Ready:  sudo nixos-rebuild switch --flake %s\n\n' "$PWD"
else
    warn "it does not evaluate yet. See the error with:"
    printf '      nix eval .#nixosConfigurations.%s.config.networking.hostName\n\n' "$HOST"
fi

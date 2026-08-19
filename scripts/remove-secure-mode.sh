#!/usr/bin/env bash
# Undo install-secure-mode.sh.
#
# That script wrote /etc/sudoers.d/secure-mode from an unvalidated string:
#
#     USER_NAME=$(logname 2>/dev/null || echo $USER)
#     echo "$USER_NAME ALL=(ALL) NOPASSWD: /usr/local/bin/secure-mode" | sudo tee ...
#
# `logname` returns nothing when there is no controlling terminal -- which is
# exactly the case when the installer is piped, run from a service, or run under
# sudo. The file then begins with a space and sudo refuses to parse it. sudo
# fails *closed*: one malformed file in /etc/sudoers.d and every sudo command
# stops working, which is why this looked like the password had broken.
#
# This removes the file safely, verifies the sudo configuration afterwards, and
# optionally cleans up ufw and the secure-mode helper.
set -uo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

say()  { printf '  %s\n' "$*"; }
ok()   { printf '  \033[1;32mok\033[0m    %s\n' "$*"; }
warn() { printf '  \033[1;33m!!\033[0m    %s\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then printf '  would run: %s\n' "$*"; else "$@"; fi; }

[[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root."; exit 1; }

echo "== current sudo configuration =="
VISUDO_OUT="$(sudo visudo -c 2>&1)"
VISUDO_RC=$?
if [[ $VISUDO_RC -eq 0 ]]; then
    ok "sudo configuration parses"
elif printf '%s' "$VISUDO_OUT" | grep -qiE "no new privileges|not permitted|must be setuid"; then
    # Sandboxes and containers block sudo itself; that is not a sudoers problem
    # and should not be reported as one.
    warn "cannot check here -- sudo is blocked by the environment, not by a config error"
else
    warn "sudo configuration is BROKEN:"
    printf '%s\n' "$VISUDO_OUT" | sed 's/^/        /'
    say ""
    say "If sudo will not run at all, boot to a root shell and remove the file:"
    say "    rm /etc/sudoers.d/secure-mode"
fi

echo
echo "== the file this script removes =="
if [[ -f /etc/sudoers.d/secure-mode ]]; then
    say "contents of /etc/sudoers.d/secure-mode:"
    sudo cat /etc/sudoers.d/secure-mode | sed 's/^/        /'
    # A leading space or an empty user field is the failure described above.
    if sudo grep -qE '^\s' /etc/sudoers.d/secure-mode; then
        warn "line begins with whitespace -- this is the file that breaks sudo"
    fi
    run sudo rm -f /etc/sudoers.d/secure-mode
    [[ $DRY_RUN -eq 0 ]] && ok "removed"
else
    ok "/etc/sudoers.d/secure-mode is not present"
fi

echo
echo "== verify sudo still works =="
if [[ $DRY_RUN -eq 0 ]]; then
    if sudo visudo -c >/dev/null 2>&1; then
        ok "sudo configuration parses"
    else
        warn "sudo configuration STILL does not parse -- something else is wrong:"
        sudo visudo -c 2>&1 | sed 's/^/        /'
    fi
fi

echo
echo "== secure-mode helper =="
if [[ -e /usr/local/bin/secure-mode ]]; then
    run sudo rm -f /usr/local/bin/secure-mode
    [[ $DRY_RUN -eq 0 ]] && ok "removed /usr/local/bin/secure-mode"
else
    ok "no /usr/local/bin/secure-mode"
fi

echo
echo "== ufw =="
if command -v ufw >/dev/null 2>&1; then
    say "ufw is installed. Status:"
    sudo ufw status 2>/dev/null | sed 's/^/        /'
    say ""
    say "It is left enabled on purpose -- disabling a firewall is your decision,"
    say "not a repair script's. To turn it off and remove it:"
    say "    sudo ufw disable && sudo pacman -Rns ufw"
else
    ok "ufw is not installed"
fi

echo
ok "Done."

#!/usr/bin/env bash
# Static checks for the Hyprland config, plus live checks when a compositor
# is running.
#
#   ./check.sh          syntax of every Lua and shell file
#   ./check.sh --live   also reload Hyprland and inspect the loaded config
set -uo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit 1
FAILED=0
pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; FAILED=1; }
step() { echo; echo "=== $* ==="; }

step "shell script syntax"
while IFS= read -r f; do
    bash -n "$f" || fail "$f"
done < <(find . -name '*.sh' -not -path './.git/*')
pass "shell scripts parse"

step "lua syntax"
LUAC=""
if command -v luac >/dev/null 2>&1; then
    LUAC="luac"
elif command -v nix >/dev/null 2>&1; then
    LUAC="nix shell nixpkgs#lua5_4 --command luac"
fi
if [ -n "$LUAC" ]; then
    while IFS= read -r f; do
        $LUAC -p "$f" >/dev/null 2>&1 || fail "$f does not parse"
    done < <(find . -name '*.lua' -not -path './.git/*' -not -name 'current.lua')
    pass "lua files parse"
else
    echo "  SKIP  no lua compiler available"
fi

step "keybind variables"
# Every vars.kbSomething used by keybinds.lua must exist in variables.lua,
# otherwise hl.bind receives nil and the bind silently does not exist.
missing=0
for k in $(grep -o 'vars\.kb[A-Za-z]*' hyprland/keybinds.lua | sort -u | sed 's/vars\.//'); do
    grep -q "^\s*$k\s*=" variables.lua || { fail "keybinds.lua uses vars.$k which variables.lua does not define"; missing=1; }
done
[ "$missing" = 0 ] && pass "every keybind variable is defined"

step "scripts referenced by the config exist"
for s in $(grep -oh 'hyprland/scripts/[a-z_.-]*' hyprland/*.lua | sort -u); do
    [ -x "$s" ] || fail "$s is referenced but missing or not executable"
done
pass "referenced scripts present"

if [ "${1:-}" = "--live" ]; then
    if ! command -v hyprctl >/dev/null 2>&1 || [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        echo "  SKIP  no running Hyprland"
    else
        step "live reload"
        hyprctl reload >/dev/null && pass "hyprctl reload" || fail "hyprctl reload"
        errs="$(hyprctl configerrors 2>/dev/null)"
        if [ -n "$errs" ] && ! echo "$errs" | grep -q "no errors"; then
            fail "config errors:"; echo "$errs" | sed 's/^/          /'
        else
            pass "no config errors"
        fi

        step "duplicate keybinds"
        # Two binds on one chord both fire; that is almost never intended.
        dups="$(hyprctl binds -j | python3 -c '
import json, sys
seen = {}
for b in json.load(sys.stdin):
    k = (b["modmask"], b["key"].lower(), b["keycode"], b["release"])
    seen.setdefault(k, []).append(b["dispatcher"] + " " + b["arg"])
for k, v in seen.items():
    if len(v) > 1 and k[1]:
        print("mod=%s key=%s -> %s" % (k[0], k[1], " | ".join(v)))
')"
        if [ -n "$dups" ]; then
            fail "duplicate binds:"; echo "$dups" | sed 's/^/          /'
        else
            pass "no duplicate binds"
        fi
    fi
fi

echo
[ "$FAILED" -eq 0 ] && echo "ALL CHECKS PASSED" || echo "CHECKS FAILED"
exit "$FAILED"

#!/usr/bin/env bash
# Pull upstream changes without losing your machine's configuration.
#
#   ./update.sh            fetch, merge, show what changed
#   ./update.sh --rebuild  the above, then nixos-rebuild switch
#   ./update.sh --check    show what an update would bring, change nothing
#
# Your identity (vars.nix) and your host directory are protected by a
# merge=ours rule in .gitattributes, so an update can never overwrite them.
# Anything else merges normally.
set -uo pipefail

cd "$(dirname "$(readlink -f "$0")")" || exit 1

BLUE=$'\033[1;34m'; GREEN=$'\033[1;32m'; RED=$'\033[1;31m'; YELLOW=$'\033[1;33m'; OFF=$'\033[0m'
step() { printf '%s==>%s %s\n' "$BLUE" "$OFF" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$GREEN" "$OFF" "$*"; }
warn() { printf '%s  !!%s %s\n' "$YELLOW" "$OFF" "$*"; }
die()  { printf '%s error%s %s\n' "$RED" "$OFF" "$*" >&2; exit 1; }

MODE="${1:-}"

command -v git >/dev/null || die "git is not installed"
git rev-parse --git-dir >/dev/null 2>&1 || die "this is not a git repository"

# The driver that makes merge=ours work. `true` is the whole implementation:
# it exits 0 having done nothing, leaving the local file in place.
git config merge.ours.driver true

# Where updates come from: an explicit upstream if you forked, otherwise origin.
REMOTE="origin"
git remote get-url upstream >/dev/null 2>&1 && REMOTE="upstream"
BRANCH="$(git symbolic-ref --quiet --short HEAD || echo main)"
step "updating from $REMOTE/$BRANCH"

git fetch --quiet "$REMOTE" "$BRANCH" || die "could not reach $REMOTE"

BEHIND="$(git rev-list --count "HEAD..$REMOTE/$BRANCH" 2>/dev/null || echo 0)"
if [ "$BEHIND" = "0" ]; then
    ok "already up to date"
    [ "$MODE" = "--rebuild" ] || exit 0
else
    step "$BEHIND new commit(s):"
    git --no-pager log --oneline --no-decorate "HEAD..$REMOTE/$BRANCH" | head -15 | sed 's/^/     /'
fi

if [ "$MODE" = "--check" ]; then
    step "files an update would touch:"
    git --no-pager diff --name-only "HEAD..$REMOTE/$BRANCH" | sed 's/^/     /'
    exit 0
fi

# Uncommitted work is committed first so the merge has something to protect.
# Nothing is ever discarded.
if [ -n "$(git status --porcelain)" ]; then
    step "saving your local changes"
    git add -A
    git commit -q -m "local: machine configuration" || true
    ok "committed"
fi

if [ "$BEHIND" != "0" ]; then
    step "merging"
    if git merge --no-edit "$REMOTE/$BRANCH" >/dev/null 2>&1; then
        ok "merged, your machine files untouched"
    else
        CONFLICTS="$(git diff --name-only --diff-filter=U)"
        if [ -z "$CONFLICTS" ]; then
            die "merge failed; run 'git merge $REMOTE/$BRANCH' to see why"
        fi
        warn "conflicts that need you:"
        printf '%s\n' "$CONFLICTS" | sed 's/^/     /'
        echo
        echo "  Resolve them, then:  git add <files> && git commit"
        echo "  Or abandon this update:  git merge --abort"
        exit 1
    fi
fi

step "checking the configuration still evaluates"
HOST="$(hostname)"
if [ ! -d "hosts/$HOST" ]; then
    warn "no hosts/$HOST directory"
    echo "     Create one before rebuilding:"
    echo "       mkdir -p hosts/$HOST"
    echo "       sudo nixos-generate-config --show-hardware-config > hosts/$HOST/hardware-configuration.nix"
    echo "       cp hosts/desktop/default.nix hosts/$HOST/default.nix"
    exit 1
fi

if nix eval --raw ".#nixosConfigurations.$HOST.config.networking.hostName" >/dev/null 2>&1; then
    ok "hosts/$HOST evaluates"
else
    die "hosts/$HOST does not evaluate -- not rebuilding. Run:
       nix eval .#nixosConfigurations.$HOST.config.networking.hostName"
fi

if [ "$MODE" = "--rebuild" ]; then
    step "rebuilding (sudo)"
    sudo nixos-rebuild switch --flake ".#$HOST"
else
    echo
    ok "ready. To apply:  sudo nixos-rebuild switch --flake .#$HOST"
    echo "     or next time:  ./update.sh --rebuild"
fi

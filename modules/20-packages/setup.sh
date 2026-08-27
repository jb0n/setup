#!/usr/bin/env bash
# base + dev packages via homebrew (mac) or the distro pm (linux).
# the package lists live in lib/packages.sh -- edit there to add stuff.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"
source "$HERE/../../lib/packages.sh"

case "$PM" in
    brew|apt|dnf|pacman|zypper|apk) : ;;
    *)
        warn "unknown package manager ($PM), skipping package installs"
        exit 0
        ;;
esac

# on mac, install homebrew first if missing
if [ "$PLATFORM" = mac ] && ! has brew; then
    info "installing homebrew (will prompt for your sudo password)..."
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for c in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$c" ] && eval "$("$c" shellenv)" && break
    done
    has brew || die "brew not on PATH after install"
fi

pkg_update

read -r -a core <<< "$(packages_core)"
read -r -a dev <<< "$(packages_dev)"

info "installing core packages"
pkg_install "${core[@]}" || warn "some core packages failed to install"

info "installing dev packages"
if ! pkg_install "${dev[@]}"; then
    warn "bulk dev install failed; retrying one at a time"
    for p in "${dev[@]}"; do
        pkg_install "$p" || warn "  could not install $p (skipping)"
    done
fi

ok "packages installed"

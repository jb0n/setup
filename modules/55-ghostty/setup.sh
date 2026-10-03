#!/usr/bin/env bash
# ghostty terminal: install the app (platform-specific) and install the same
# config on mac and linux. the config is shared -- both platforms read
# ~/.config/ghostty/config -- so this module replaces the old mac-only block.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

FILES="$HERE/files"

# true if ghostty is present by any of the ways we install it
ghostty_installed() {
    has ghostty && return 0
    [ "$PLATFORM" = mac ] && [ -d "/Applications/Ghostty.app" ] && return 0
    has flatpak && flatpak list --app 2>/dev/null | grep -q 'com.mitchellh.ghostty' && return 0
    return 1
}

#---------------------------------------------------------------------
# install
#---------------------------------------------------------------------
if ghostty_installed; then
    ok "ghostty already installed"
else
    case "$PLATFORM" in
        mac)
            info "installing ghostty via brew cask..."
            brew install --cask ghostty
            ;;
        linux)
            if pkg_install ghostty; then
                ok "ghostty installed from $PM"
            elif has flatpak; then
                info "installing ghostty via flatpak..."
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                flatpak install -y flathub com.mitchellh.ghostty \
                    || warn "ghostty: flatpak install failed, install it manually"
            else
                warn "ghostty: not in $PM repos and no flatpak; install it manually"
            fi
            ;;
        *)
            warn "ghostty: don't know how to install on $PLATFORM; install it manually"
            ;;
    esac
fi

#---------------------------------------------------------------------
# config
#---------------------------------------------------------------------
GHOSTTY_DIR="$HOME/.config/ghostty"
GHOSTTY_FILE="$GHOSTTY_DIR/config"
mkdir -p "$GHOSTTY_DIR"
if [ -f "$GHOSTTY_FILE" ] && ! cmp -s "$FILES/ghostty.config" "$GHOSTTY_FILE"; then
    cp "$GHOSTTY_FILE" "$GHOSTTY_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $GHOSTTY_FILE"
fi
cp "$FILES/ghostty.config" "$GHOSTTY_FILE"
info "installed $GHOSTTY_FILE"

ok "ghostty done"

#!/usr/bin/env bash
# apps. add an app as a function below and register it in the APPS array.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

# signal-desktop: needed, but the install path is platform-specific.
# apt gets the official signal repo; brew gets the cask; anything else
# falls back to flatpak, otherwise warns and skips.
app_signal() {
    if has signal-desktop; then
        ok "signal-desktop already installed"
        return 0
    fi

    case "$PM" in
        apt)
            local keyring=/usr/share/keyrings/signal-desktop-keyring.gpg
            local sources=/etc/apt/sources.list.d/signal-desktop.sources
            info "installing signal-desktop from the official apt repo..."
            wget -qO- https://updates.signal.org/desktop/apt/keys.asc \
                | sudo gpg --dearmor --yes -o "$keyring"
            sudo tee "$sources" >/dev/null <<EOF
Types: deb
URIs: https://updates.signal.org/desktop/apt
Suites: xenial
Components: main
Architectures: amd64
Signed-By: $keyring
EOF
            sudo apt-get update
            sudo apt-get install -y signal-desktop
            ;;
        brew)
            info "installing signal-desktop via brew cask..."
            brew install --cask signal
            ;;
        *)
            if has flatpak; then
                info "installing signal-desktop via flatpak..."
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                flatpak install -y flathub org.signal.Signal \
                    || warn "signal-desktop: flatpak install failed, install it manually"
            else
                warn "signal-desktop: no apt/brew/flatpak path on $PM; install it manually"
            fi
            ;;
    esac
}

APPS=(app_signal)

for app in "${APPS[@]}"; do
    info "==> $app"
    "$app"
done

ok "apps done"

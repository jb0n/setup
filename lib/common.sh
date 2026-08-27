#!/usr/bin/env bash
# shared helpers for the setup modules. every module sources this first.

# true if a command exists
has() { command -v "$1" >/dev/null 2>&1; }

# ---------- platform / package manager ----------
detect_platform() {
    case "$(uname -s)" in
        Darwin) echo mac ;;
        Linux)  echo linux ;;
        MINGW*|MSYS*|CYGWIN*|*_NT-*) echo windows ;;
        *) echo unknown ;;
    esac
}

detect_pm() {
    case "$(detect_platform)" in
        mac)
            has brew && { echo brew; return; }
            ;;
        linux)
            if has apt-get; then echo apt; return; fi
            if has dnf; then echo dnf; return; fi
            if has pacman; then echo pacman; return; fi
            if has zypper; then echo zypper; return; fi
            if has apk; then echo apk; return; fi
            ;;
    esac
    echo unknown
}

# platform/pm, falling back to live detection when not run from setup.sh
PLATFORM="${SETUP_PLATFORM:-$(detect_platform)}"
PM="${SETUP_PM:-$(detect_pm)}"

# ---------- logging ----------
info() { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[setup]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[setup]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- package helpers ----------
pkg_update() {
    case "$PM" in
        apt)    sudo apt-get update ;;
        pacman) sudo pacman -Sy --noconfirm ;;
        *) : ;;
    esac
}

pkg_install() {
    case "$PM" in
        brew)   brew install "$@" ;;
        apt)    sudo apt-get install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm --needed "$@" ;;
        zypper) sudo zypper --non-interactive install "$@" ;;
        apk)    sudo apk add --no-cache "$@" ;;
        *) return 1 ;;
    esac
}

cask_install() {  # brew casks, mac only
    [ "$PM" = brew ] && brew install --cask "$@"
}

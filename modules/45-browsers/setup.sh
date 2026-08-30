#!/usr/bin/env bash
# browsers (firefox + chrome) and the extensions i use. add an extension
# by appending "name|firefox-amo-slug|chrome-web-store-id" to EXTENSIONS.
# leave a field empty when that browser doesn't have the extension
# (e.g. uBlock Origin Lite is chrome-only).

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

# name | firefox amo slug | chrome web store id
EXTENSIONS=(
    "1Password|1password-x-password-manager|aeblfdkhhhdcdjpifhhbdiojplfjncoa"
    "uBlock Origin|ublock-origin|cjpalhdlnbpafiamejdnhcphjbkeiagm"
    "uBlock Origin Lite||ddkjiahejlhfcafbddmgiahcphecmpfh"
    "Raindrop.io|raindropio|ldgfbffkinooeloadekpmfoklnobpien"
    "Dark Reader|darkreader|eimadpbcbfnmbkopoojfekhnkhdbieeh"
)

has_firefox() { has firefox || has firefox-esr || [ -d "/Applications/Firefox.app" ]; }
has_chrome()  { has google-chrome || has google-chrome-stable || [ -d "/Applications/Google Chrome.app" ]; }

#---------------------------------------------------------------------
# browser install
#---------------------------------------------------------------------
install_firefox() {
    if has_firefox; then
        echo "firefox already installed"
        return 0
    fi
    if [ "$PM" = brew ]; then
        brew install --cask firefox || true
        has_firefox || warn "firefox: brew install failed, install it manually"
    else
        pkg_install firefox || pkg_install firefox-esr || warn "could not install firefox"
    fi
}

install_chrome() {
    if has_chrome; then
        echo "google-chrome already installed"
        return 0
    fi
    if [ "$PM" = brew ]; then
        brew install --cask google-chrome || true
        has_chrome || warn "google-chrome: brew install failed, install it manually"
        return 0
    fi
    case "$PM" in
        apt)
            local deb=/tmp/google-chrome-stable_current_amd64.deb
            info "installing google-chrome from the official .deb..."
            wget -q -O "$deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            sudo apt-get install -y "$deb"
            rm -f "$deb"
            ;;
        dnf|zypper)
            local rpm=/tmp/google-chrome-stable_current_x86_64.rpm
            info "installing google-chrome from the official .rpm..."
            wget -q -O "$rpm" https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
            if [ "$PM" = dnf ]; then sudo dnf install -y "$rpm"
            else sudo zypper --non-interactive install "$rpm"; fi
            rm -f "$rpm"
            ;;
        *)
            if has flatpak; then
                info "installing google-chrome via flatpak..."
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                flatpak install -y flathub com.google.Chrome \
                    || warn "google-chrome: flatpak install failed, install it manually"
            else
                warn "google-chrome: no apt/dnf/zypper/flatpak path on $PM; install it manually"
            fi
            ;;
    esac
}

#---------------------------------------------------------------------
# firefox extensions: signed xpi from AMO dropped into the default
# profile's extensions/ dir. modern firefox may show a confirm prompt
# on next launch for profile-dropped add-ons.
#---------------------------------------------------------------------
firefox_base() {
    case "$PLATFORM" in
        mac) echo "$HOME/Library/Application Support/Firefox" ;;
        *)   echo "$HOME/.mozilla/firefox" ;;
    esac
}

find_firefox_profile() {
    local base ini default path
    base="$(firefox_base)"
    [ -d "$base" ] || return 1
    ini="$base/profiles.ini"
    [ -f "$ini" ] || return 1
    default="$(awk -F= '
        /^\[/      { section = $0 }
        /^Default/ { if ($2 == 1) print section }
    ' "$ini" | head -1 | tr -d '[]')"
    [ -n "$default" ] || return 1
    path="$(awk -F= -v sec="[$default]" '
        $0 == sec { insec = 1; next }
        insec && /^Path=/ { sub(/^Path=/,""); print; exit }
    ' "$ini")"
    [ -n "$path" ] || return 1
    case "$path" in
        /*) echo "$path" ;;
        *)  echo "$base/$path" ;;
    esac
}

ensure_firefox_profile() {
    local p t
    p="$(find_firefox_profile)" && { echo "$p"; return 0; }
    info "no firefox profile yet; launching firefox headless once to create one..."
    if has timeout; then t=timeout
    elif has gtimeout; then t=gtimeout
    fi
    if [ -n "$t" ]; then
        $t 30 firefox --headless --new-instance about:blank >/dev/null 2>&1 || true
    else
        firefox --headless --new-instance about:blank >/dev/null 2>&1 &
        local fp=$!
        sleep 20
        kill "$fp" 2>/dev/null || true
        wait "$fp" 2>/dev/null || true
    fi
    p="$(find_firefox_profile)" && { echo "$p"; return 0; }
    return 1
}

install_firefox_ext() {
    local name="$1" slug="$2" ext_dir="$3"
    local tmp url id target
    tmp="$(mktemp -d)"
    url="https://addons.mozilla.org/firefox/downloads/latest/$slug/"
    if ! curl -fsSL -o "$tmp/addon.xpi" "$url"; then
        warn "could not download $name from addons.mozilla.org"
        rm -rf "$tmp"
        return 1
    fi
    id="$(unzip -p "$tmp/addon.xpi" manifest.json 2>/dev/null | python3 -c '
        import json, sys
        m = json.load(sys.stdin)
        print(m.get("browser_specific_settings", {}).get("gecko", {}).get("id")
              or m.get("applications", {}).get("gecko", {}).get("id") or "")')"
    if [ -z "$id" ]; then
        warn "could not read the add-on id from $name manifest"
        rm -rf "$tmp"
        return 1
    fi
    target="$ext_dir/$id.xpi"
    if [ -f "$target" ] && cmp -s "$tmp/addon.xpi" "$target"; then
        ok "$name (firefox) already installed and up to date"
    else
        cp "$tmp/addon.xpi" "$target"
        ok "installed $name (firefox) -> $(basename "$target")"
    fi
    rm -rf "$tmp"
}

install_firefox_extensions() {
    local profile ext_dir entry name slug rest
    profile="$(ensure_firefox_profile)" || {
        warn "no firefox profile found; launch firefox once and re-run"
        return 1
    }
    ext_dir="$profile/extensions"
    mkdir -p "$ext_dir"
    for entry in "${EXTENSIONS[@]}"; do
        name="${entry%%|*}"
        rest="${entry#*|}"
        slug="${rest%%|*}"
        [ -n "$slug" ] || continue
        install_firefox_ext "$name" "$slug" "$ext_dir"
    done
    echo "firefox extensions installed; quit and relaunch firefox to load them"
}

#---------------------------------------------------------------------
# chrome extensions: ExtensionInstallForcelist policy. silent, but only
# works for extensions on the Chrome Web Store and needs root (we have
# passwordless sudo from module 10). takes effect on next chrome launch.
#---------------------------------------------------------------------
install_chrome_extensions() {
    local ids=() entry rest cid
    for entry in "${EXTENSIONS[@]}"; do
        rest="${entry#*|}"
        cid="${rest#*|}"
        [ -n "$cid" ] && ids+=("$cid;https://clients2.google.com/service/update2/crx")
    done
    [ ${#ids[@]} -gt 0 ] || return 0

    if [ "$PLATFORM" = mac ]; then
        local plist="/Library/Managed Preferences/$USER/com.google.Chrome.plist"
        sudo mkdir -p "$(dirname "$plist")"
        sudo defaults write "$plist" ExtensionInstallForcelist -array "${ids[@]}"
        info "chrome extensions policy written to $plist"
        return 0
    fi

    if ! has google-chrome && ! has google-chrome-stable && [ ! -d /etc/opt/chrome ]; then
        warn "chrome not installed, skipping chrome extensions"
        return 1
    fi
    local dir=/etc/opt/chrome/policies/managed tmp
    tmp="$(mktemp)"
    python3 - "$tmp" "${ids[@]}" <<'PY'
import json, sys
open(sys.argv[1], "w").write(json.dumps({"ExtensionInstallForcelist": sys.argv[2:]}, indent=2) + "\n")
PY
    sudo mkdir -p "$dir"
    sudo tee "$dir/chrome-extensions.json" < "$tmp" >/dev/null
    rm -f "$tmp"
    info "chrome extensions policy written to $dir/chrome-extensions.json"
}

#---------------------------------------------------------------------
install_firefox
install_chrome

has_firefox && { install_firefox_extensions || true; }
if has_chrome; then
    install_chrome_extensions
fi

ok "browsers done"

#!/usr/bin/env bash
# fonts. each font is one file in this directory:
#
#   FONT_NAME=Hasklig                  display name
#   FONT_URL=https://.../Hasklig.zip   download URL (linux, and mac fallback)
#   FONT_BREW=font-hasklig             brew cask name (mac, preferred)
#
# mac installs via brew cask when FONT_BREW is set, otherwise drops the zip
# into ~/Library/Fonts. linux unzips into ~/.fonts and refreshes fontconfig.
# add a font by dropping in another .font file.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

install_font() {
    local name="$1" url="$2" brewcask="$3"
    local dir zipname

    case "$PLATFORM" in
        mac)
            if [ -n "$brewcask" ] && has brew; then
                brew install --cask "$brewcask" && return
            fi
            dir="$HOME/Library/Fonts"
            ;;
        *)
            dir="$HOME/.fonts"
            ;;
    esac

    mkdir -p "$dir"
    zipname="$(basename "$url")"
    if [ -e "$dir/$zipname" ]; then
        ok "$name already installed"
        return
    fi
    info "installing $name"
    wget -q -O "$dir/$zipname" "$url"
    (cd "$dir" && unzip -oq "$zipname")
    has fc-cache && fc-cache -f >/dev/null
    ok "installed $name into $dir"
}

found=0
for f in "$HERE"/*.font; do
    [ -e "$f" ] || continue
    unset FONT_NAME FONT_URL FONT_BREW
    source "$f"
    if [ -z "${FONT_NAME:-}" ] || [ -z "${FONT_URL:-}" ]; then
        warn "bad font file $f (need FONT_NAME and FONT_URL)"
        continue
    fi
    found=1
    install_font "$FONT_NAME" "$FONT_URL" "${FONT_BREW:-}"
done

[ "$found" -eq 1 ] || warn "no .font files found in $HERE"
ok "fonts done"

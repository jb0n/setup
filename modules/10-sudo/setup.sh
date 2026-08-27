#!/usr/bin/env bash
# passwordless sudo for the invoking account. linux only.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

[ "$PLATFORM" = linux ] || { info "not linux, skipping"; exit 0; }
[ "$(id -u)" -eq 0 ] && { info "running as root, nothing to grant"; exit 0; }

whoami="$(id -un)"
sudoers="/etc/sudoers.d/90-$whoami"

if [ -f "$sudoers" ] && sudo -n true >/dev/null 2>&1; then
    ok "passwordless sudo already in place for $whoami"
    exit 0
fi

info "granting passwordless sudo to $whoami (one sudo password prompt follows)..."
sudo -v
[ -e "$sudoers" ] && sudo cp "$sudoers" "$sudoers.bak.$(date +%Y%m%d%H%M%S)"
echo "$whoami ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers" >/dev/null
sudo chmod 440 "$sudoers"
sudo visudo -c -f "$sudoers"
ok "passwordless sudo granted ($sudoers)"

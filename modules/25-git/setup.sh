#!/usr/bin/env bash
# git identity, ssh key, and shell PATH. personal defaults for jb0n.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

# ---- git identity + sane defaults ----
git config --global user.name "jgould"
git config --global user.email "jgould@fura.attlocal.net"
git config --global init.defaultBranch master
info "git configured: jgould <jgould@fura.attlocal.net>, default branch master"

# ---- ssh key (generate one only if none exists) ----
if [ ! -e "$HOME/.ssh/id_ed25519" ] && [ ! -e "$HOME/.ssh/id_rsa" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    info "generating an ed25519 ssh key..."
    ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
    ok "generated $HOME/.ssh/id_ed25519 (add the .pub to github/gitlab)"
else
    echo "ssh key already present"
fi

# ---- PATH: ~/.local/bin (omp installs there) and ~/bin ----
case "$PLATFORM" in
    mac) rc_files=("$HOME/.zshrc") ;;
    *)   rc_files=("$HOME/.bashrc") ;;
esac
for rc in "${rc_files[@]}"; do
    touch "$rc"
    for line in 'export PATH="$HOME/.local/bin:$PATH"' 'export PATH="$HOME/bin:$PATH"'; do
        if ! grep -qF "$line" "$rc"; then
            printf '%s\n' "$line" >> "$rc"
            ok "added to $rc: $line"
        fi
    done
done

ok "git done"

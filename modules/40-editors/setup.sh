#!/usr/bin/env bash
# vim + neovim, merged: plugins, configs, colorscheme. config files live
# in files/ (init.vim for nvim, vimrc for vim, ale.vim plugin config,
# eldar.vim shared colorscheme). add a plugin by appending to PLUGINS.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

FILES="$HERE/files"

VIM_PLUGINS_DIR=~/.vim/pack/git-plugins/start
NVIM_PLUGINS_DIR=~/.local/share/nvim/site/pack/plugins/start

PLUGINS=(
    "https://github.com/fatih/vim-go"
    "https://github.com/dense-analysis/ale"
    "https://github.com/tpope/vim-fugitive"
    "https://github.com/easymotion/vim-easymotion"
    "https://github.com/rhysd/committia.vim"
    "https://github.com/vim-airline/vim-airline"
)

install_plugin() {
    local dir="$1" url="$2" name dirp
    name="$(basename "$url")"
    dirp="$dir/$name"
    if [ -d "$dirp" ]; then
        info "updating $name"
        (cd "$dirp" && git pull)
    else
        info "installing $name"
        git clone --depth=1 "$url" "$dirp"
    fi
}

mkdir -p "$VIM_PLUGINS_DIR" "$NVIM_PLUGINS_DIR"
for url in "${PLUGINS[@]}"; do
    install_plugin "$VIM_PLUGINS_DIR" "$url"
    install_plugin "$NVIM_PLUGINS_DIR" "$url"
done

# ---- shared colorscheme ----
mkdir -p ~/.vim/colors ~/.config/nvim/colors
cp "$FILES/eldar.vim" ~/.vim/colors/
cp "$FILES/eldar.vim" ~/.config/nvim/colors/

# ---- vim config ----
if [ ! -e ~/.vimrc ]; then
    cp "$FILES/vimrc" ~/.vimrc
    info "installed ~/.vimrc"
fi
mkdir -p ~/.vim/plugins
if [ ! -e ~/.vim/plugins/ale.vim ]; then
    cp "$FILES/ale.vim" ~/.vim/plugins/ale.vim
    info "installed ~/.vim/plugins/ale.vim"
fi
if [ ! -h ~/.vim/ale_linter.vim ]; then
    ln -s ~/.vim/pack/git-plugins/start/ale/ale_linters/go/golangci_lint.vim \
        ~/.vim/ale_linter.vim
fi

# ---- nvim config ----
if [ ! -e ~/.config/nvim/init.vim ]; then
    mkdir -p ~/.config/nvim
    cp "$FILES/init.vim" ~/.config/nvim/init.vim
    info "installed ~/.config/nvim/init.vim"
fi

# ---- go binaries for the go plugins (vim-go needs them) ----
if has go; then
    if has vim; then
        vim -esN +GoInstallBinaries +q || warn "vim GoInstallBinaries did not finish cleanly"
    else
        warn "vim not installed, skipping its GoInstallBinaries"
    fi
    if has nvim; then
        nvim -esN +GoInstallBinaries +q || warn "nvim GoInstallBinaries did not finish cleanly"
    else
        warn "nvim not installed, skipping its GoInstallBinaries"
    fi
else
    warn "go not installed, skipping GoInstallBinaries"
fi

ok "editors done"

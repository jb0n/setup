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
# install directly instead of :GoInstallBinaries -- running that headless
# (vim -esN ... +q) hangs in vim's silent-mode input loop waiting on the tty.
# mirrors vim-go's s:packages table; each install is skipped if already done.
GO_TOOLS=(
    "github.com/klauspost/asmfmt/cmd/asmfmt@latest"
    "github.com/go-delve/delve/cmd/dlv@latest"
    "github.com/kisielk/errcheck@latest"
    "github.com/davidrjenni/reftools/cmd/fillstruct@master"
    "github.com/rogpeppe/godef@latest"
    "golang.org/x/tools/cmd/goimports@master"
    "github.com/mgechev/revive@latest"
    "golang.org/x/tools/gopls@latest"
    "github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest"
    "honnef.co/go/tools/cmd/staticcheck@latest"
    "github.com/fatih/gomodifytags@latest"
    "github.com/jstemmer/gotags@master"
    "github.com/josharian/impl@main"
    "github.com/fatih/motion@latest"
    "github.com/koron/iferr@master"
)
if has go; then
    GO_BIN_DIR="$(go env GOBIN)"
    for spec in "${GO_TOOLS[@]}"; do
        bin="$(basename "${spec%@*}")"
        if [ -x "$GO_BIN_DIR/$bin" ]; then
            info "go tool $bin already installed"
        else
            info "installing go tool $bin"
            go install "$spec" || warn "failed to install $bin"
        fi
    done
else
    warn "go not installed, skipping vim-go tools"
fi

ok "editors done"

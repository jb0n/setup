#!/usr/bin/env bash
# per-platform package lists. add a package by putting it into the lists
# for the package managers you care about.

# ---------- core: the boring stuff every box needs ----------
packages_core() {
    case "$PM" in
        brew)   echo "git curl wget unzip zip vim neovim node python3" ;;
        apt)    echo "git curl wget unzip zip fontconfig gnupg vim neovim nodejs npm" ;;
        dnf)    echo "git curl wget unzip zip fontconfig vim neovim nodejs npm" ;;
        pacman) echo "git curl wget unzip zip fontconfig vim neovim nodejs npm" ;;
        zypper) echo "git curl wget unzip zip fontconfig vim neovim nodejs npm" ;;
        apk)    echo "git curl wget unzip zip fontconfig vim neovim nodejs npm" ;;
        *) echo "" ;;
    esac
}

# ---------- dev: toolchain, languages, and the tools i reach for ----------
packages_dev() {
    case "$PM" in
        brew)   echo "go jq htop tmux ripgrep fd fzf shellcheck gh" ;;
        apt)    echo "build-essential gdb golang python3 python3-pip libssl-dev \
                      jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                      ripgrep fd-find fzf shellcheck gh" ;;
        dnf)    echo "gcc gcc-c++ make gdb golang python3 python3-pip openssl-devel \
                      jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                      ripgrep fd-find fzf ShellCheck gh" ;;
        pacman) echo "base-devel gdb go python python-pip openssl \
                      jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                      ripgrep fd fzf shellcheck github-cli" ;;
        zypper) echo "gcc gcc-c++ make gdb golang python3 python3-pip openssl-devel \
                      jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                      ripgrep fd fzf ShellCheck gh" ;;
        apk)    echo "build-base gdb go python3 py3-pip openssl-dev \
                      jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                      ripgrep fd fzf shellcheck gh libstdc++ libgcc" ;;
        *) echo "" ;;
    esac
}

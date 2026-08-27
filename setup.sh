#!/usr/bin/env bash
# jb0n/setup -- clone this repo on any machine, run ./setup.sh, get set up.
#
#   ./setup.sh                              run every module in order
#   ./setup.sh editors fonts                run only those modules
#   ./setup.sh --list                       list modules
#   ./setup.sh --deepseek-apikey=KEY        pass an api key through to the
#                                           agents module
#
# modules are directories under modules/ with a numeric prefix for ordering
# (e.g. 20-packages). each module is a standalone setup.sh that sources
# lib/common.sh and is idempotent. to add a feature, drop in a new
# modules/NN-name/setup.sh -- no changes to this file needed.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/common.sh"

case "$(detect_platform)" in
    windows)
        echo "you are on windows. i don't do windows."
        echo "if you have wsl, run this inside wsl and pretend the last five years never happened."
        exit 1
        ;;
    mac|linux) : ;;
    *)
        die "unknown platform: $(uname -s)"
        ;;
esac

export SETUP_PLATFORM="$(detect_platform)"
export SETUP_PM="$(detect_pm)"
info "platform: $SETUP_PLATFORM  (package manager: $SETUP_PM)"

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

WANT=()
export SETUP_DEEPSEEK_APIKEY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --deepseek-apikey=*) SETUP_DEEPSEEK_APIKEY="${1#*=}" ;;
        --deepseek-apikey) shift; SETUP_DEEPSEEK_APIKEY="${1:-}" ;;
        -h|--help) usage; exit 0 ;;
        -l|--list)
            echo "modules:"
            for mdir in "$HERE"/modules/*/; do
                [ -f "$mdir/setup.sh" ] || continue
                printf '  %s\n' "$(basename "$mdir")"
            done
            exit 0
            ;;
        -*) echo "unknown option: $1" >&2; exit 1 ;;
        *) WANT+=("$1") ;;
    esac
    shift
done

ran=0
for mdir in "$HERE"/modules/*/; do
    name="$(basename "$mdir")"
    short="${name#[0-9][0-9]-}"
    [ -f "$mdir/setup.sh" ] || continue
    if [ ${#WANT[@]} -gt 0 ]; then
        keep=0
        for n in "${WANT[@]}"; do
            [ "$n" = "$name" ] || [ "$n" = "$short" ] && keep=1
        done
        [ $keep -eq 1 ] || continue
    fi
    ran=1
    info "==> module: $name"
    bash "$mdir/setup.sh"
done

if [ ${#WANT[@]} -gt 0 ] && [ "$ran" -eq 0 ]; then
    warn "no modules matched: ${WANT[*]} (see --list)"
    exit 1
fi

ok "all set"

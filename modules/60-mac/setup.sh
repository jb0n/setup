#!/usr/bin/env bash
# mac desktop setup: system defaults, key bindings, ghostty, karabiner,
# hammerspoon. mac only. fonts come from the 30-fonts module, packages
# (incl. homebrew) from 20-packages.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

[ "$PLATFORM" = mac ] || { info "not mac, skipping mac desktop setup"; exit 0; }
has brew || die "mac module needs homebrew (run the packages module first)"

FILES="$HERE/files"

#unfuck the doc
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4
killall Dock


#stop dragging a window to the menu bar from filling the screen
#(System Settings > Desktop & Dock > Windows > "Drag windows to menu bar
# to fill screen"). side-edge tiling is left alone.
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
killall WindowManager 2>/dev/null || true


#---------------------------------------------------------------------
# top row sends real F1-F12, and dictation stops hijacking F5
#
# by default macOS treats the top row as media keys, so pressing F5 sends the
# dictation key instead of F5 -- that is the "do you want to enable dictation?"
# nag, and the reason VMs never see F5 at all. flipping fnState makes F5 a real
# F5 everywhere (VMs, terminals, browsers). brightness/volume on the built-in
# keyboard still work, they just need fn held down now (fn+F1/F2, fn+F10-F12).
#---------------------------------------------------------------------
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

#belt and braces on dictation: no auto-enable prompt, master switch off, and
#the dictation hotkey (symbolic hotkey 164, i.e. press-F5 / press-ctrl-twice)
#left disabled with no key assigned.
defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 0
defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs \
    DictationIMMasterDictationEnabled -bool false
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 164 \
    '{ enabled = 0; value = { parameters = (65535, 65535, 0); type = standard; }; }'

#nudge the window server into re-reading the hotkey/keyboard prefs so this
#mostly takes effect without a logout
ACTIVATE_SETTINGS="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
[ -x "$ACTIVATE_SETTINGS" ] && "$ACTIVATE_SETTINGS" -u >/dev/null 2>&1 || true


#---------------------------------------------------------------------
# text editing keys (home/end, word-wise delete) via Cocoa key bindings
#---------------------------------------------------------------------
KB_DIR="$HOME/Library/KeyBindings"
KB_FILE="$KB_DIR/DefaultKeyBinding.dict"
mkdir -p "$KB_DIR"
if [ -f "$KB_FILE" ] && ! cmp -s "$FILES/DefaultKeyBinding.dict" "$KB_FILE"; then
    cp "$KB_FILE" "$KB_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $KB_FILE"
fi
plutil -lint "$FILES/DefaultKeyBinding.dict" >/dev/null
cp "$FILES/DefaultKeyBinding.dict" "$KB_FILE"
info "installed $KB_FILE (restart apps to pick it up)"


#---------------------------------------------------------------------
# ghostty
#---------------------------------------------------------------------
if [ -d "/Applications/Ghostty.app" ]; then
    echo "ghostty already installed"
else
    echo "installing ghostty..."
    brew install --cask ghostty
fi

GHOSTTY_DIR="$HOME/.config/ghostty"
GHOSTTY_FILE="$GHOSTTY_DIR/config"
mkdir -p "$GHOSTTY_DIR"
if [ -f "$GHOSTTY_FILE" ] && ! cmp -s "$FILES/ghostty.config" "$GHOSTTY_FILE"; then
    cp "$GHOSTTY_FILE" "$GHOSTTY_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $GHOSTTY_FILE"
fi
cp "$FILES/ghostty.config" "$GHOSTTY_FILE"
info "installed $GHOSTTY_FILE"


#---------------------------------------------------------------------
# karabiner-elements: make ctrl work like cmd, everywhere except terminals
#
# this does NOT swap anything -- cmd keeps working exactly as it does now.
# it only translates the ctrl combos listed below into their cmd equivalents.
#---------------------------------------------------------------------
if [ -d "/Applications/Karabiner-Elements.app" ]; then
    echo "karabiner-elements already installed"
else
    echo "installing karabiner-elements (will prompt for your sudo password)..."
    brew install --cask karabiner-elements
fi

#apps that keep real ctrl -- terminals, plus VMs where the guest OS wants the
#real ctrl key. regex, so uninstalled ones are harmless.
COND='{ "type": "frontmost_application_unless", "bundle_identifiers": [
            "^com\\.apple\\.Terminal$",
            "^com\\.mitchellh\\.ghostty$",
            "^com\\.googlecode\\.iterm2$",
            "^org\\.alacritty$",
            "^net\\.kovidgoyal\\.kitty$",
            "^com\\.github\\.wez\\.wezterm$",
            "^com\\.vmware\\.fusion$",
            "^com\\.utmapp\\.UTM(-SE)?$"
          ] }'

#browsers, for the F5 = reload rule further down. deliberately an allowlist and
#not an "everything except" list: F5 has real meanings elsewhere (VS Code starts
#debugging, JetBrains runs), and VMs/terminals need the raw key. add a line here
#if you pick up a browser that is not covered.
BROWSER_COND='{ "type": "frontmost_application_if", "bundle_identifiers": [
            "^com\\.apple\\.Safari(TechnologyPreview)?$",
            "^com\\.google\\.Chrome",
            "^org\\.chromium\\.Chromium$",
            "^org\\.mozilla\\.(firefox|nightly)",
            "^com\\.microsoft\\.edgemac",
            "^com\\.brave\\.Browser",
            "^com\\.operasoftware\\.",
            "^com\\.vivaldi\\.Vivaldi$",
            "^company\\.thebrowser\\.",
            "^app\\.zen-browser\\.zen$",
            "^com\\.kagi\\.kagimacOS$"
          ] }'

MANIPS=""
add_manip() {
    [ -n "$MANIPS" ] && MANIPS="$MANIPS,"
    MANIPS="$MANIPS$1"
}

# ctrl+<key> -> cmd+<key>. shift passes through, so ctrl-shift-z = cmd-shift-z.
map_to_cmd() {
    add_manip "$(cat <<MANIP
        {
          "type": "basic",
          "from": { "key_code": "$1",
                    "modifiers": { "mandatory": ["control"], "optional": ["shift"] } },
          "to": [ { "key_code": "$1", "modifiers": ["left_command"] } ],
          "conditions": [ $COND ]
        }
MANIP
)"
}

# ctrl+<key> -> option+<key>, for the word-wise nav/delete keys
map_to_option() {
    add_manip "$(cat <<MANIP
        {
          "type": "basic",
          "from": { "key_code": "$1",
                    "modifiers": { "mandatory": ["control"], "optional": ["shift"] } },
          "to": [ { "key_code": "$1", "modifiers": ["left_option"] } ],
          "conditions": [ $COND ]
        }
MANIP
)"
}

# a=select all  b/i/u=bold/italic/underline  c/x/v=clipboard  d=bookmark
# f=find  g=find next  l=address bar  n=new  o=open  p=print  r=reload
# s=save  t=new tab  w=close tab  y/z=redo/undo
# q is deliberately left out -- ctrl-q typos would quit apps.
for k in a b c d f g i l n o p r s t u v w x y z; do
    map_to_cmd "$k"
done

# 1-9 jump to tab N, 0 resets zoom
for k in 1 2 3 4 5 6 7 8 9 0; do
    map_to_cmd "$k"
done

# ctrl-plus / ctrl-minus zoom
for k in equal_sign hyphen; do
    map_to_cmd "$k"
done

# word-at-a-time movement and delete.
# NOTE: this takes over ctrl-left/right from Mission Control's "move a space".
# karabiner rewrites the event before the system hotkey sees it, so you do not
# need to disable anything -- but you also lose ctrl-arrow space switching.
# delete the left_arrow/right_arrow lines below if you want spaces back.
for k in left_arrow right_arrow delete_or_backspace delete_forward; do
    map_to_option "$k"
done

KARA_DIR="$HOME/.config/karabiner"
KARA_FILE="$KARA_DIR/karabiner.json"
mkdir -p "$KARA_DIR"

TMP_KARA="$(mktemp -t karabiner)"
cat > "$TMP_KARA" <<JSON
{
  "global": {
    "check_for_updates_on_startup": true,
    "show_in_menu_bar": true,
    "show_profile_name_in_menu_bar": false
  },
  "profiles": [
    {
      "name": "Default profile",
      "selected": true,
      "virtual_hid_keyboard": { "keyboard_type_v2": "ansi" },
      "complex_modifications": {
        "parameters": {},
        "rules": [
          {
            "description": "ctrl acts as cmd (alongside cmd, except in terminals)",
            "manipulators": [
$MANIPS
            ]
          },
          {
            "description": "F5 reloads the page in browsers (shift+F5 = hard reload)",
            "manipulators": [
              {
                "type": "basic",
                "from": { "key_code": "f5",
                          "modifiers": { "optional": ["shift"] } },
                "to": [ { "key_code": "r", "modifiers": ["left_command"] } ],
                "conditions": [ $BROWSER_COND ]
              }
            ]
          }
        ]
      }
    }
  ]
}
JSON

#plutil only speaks plist, so use jq (ships in /usr/bin on modern macOS) or python3
if command -v jq >/dev/null 2>&1; then
    jq empty "$TMP_KARA" || { echo "generated karabiner.json is invalid, bailing"; exit 1; }
elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$TMP_KARA" \
        || { echo "generated karabiner.json is invalid, bailing"; exit 1; }
else
    echo "warning: no jq or python3, skipping json validation"
fi

#semantic check of the rules, once karabiner is actually installed
KARA_CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
if [ -x "$KARA_CLI" ]; then
    "$KARA_CLI" --lint-complex-modifications "$TMP_KARA" >/dev/null \
        || echo "warning: karabiner_cli did not like the rules, check them in the GUI"
fi

if [ -f "$KARA_FILE" ] && ! cmp -s "$TMP_KARA" "$KARA_FILE"; then
    cp "$KARA_FILE" "$KARA_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $KARA_FILE"
fi
mv "$TMP_KARA" "$KARA_FILE"
info "installed $KARA_FILE"


#---------------------------------------------------------------------
# hammerspoon: ctrl-click acts as cmd-click in browsers (opens links in
# new tabs). an event tap, not karabiner, so the physical mouse is never
# grabbed -- that is what broke the mouse before. do not re-add mouse
# rules to karabiner.
#---------------------------------------------------------------------
if [ -d "/Applications/Hammerspoon.app" ]; then
    echo "hammerspoon already installed"
else
    echo "installing hammerspoon..."
    brew install --cask hammerspoon
fi

HS_DIR="$HOME/.hammerspoon"
HS_FILE="$HS_DIR/init.lua"
mkdir -p "$HS_DIR"
if [ -f "$HS_FILE" ] && ! cmp -s "$FILES/hammerspoon.init.lua" "$HS_FILE"; then
    cp "$HS_FILE" "$HS_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $HS_FILE"
fi
cp "$FILES/hammerspoon.init.lua" "$HS_FILE"
info "installed $HS_FILE"

#launch at login, then (re)load the config now
defaults write org.hammerspoon.Hammerspoon HSAutoLaunch -bool true
open -g -a Hammerspoon
if command -v hs >/dev/null 2>&1; then
    sleep 2
    hs -c "hs.reload()" >/dev/null 2>&1 || true
fi

cat <<'NOTE'

karabiner needs two things granted by hand the first time -- macOS will not
let a script do either of them:

  1. open Karabiner-Elements.app. approve the driver extension when prompted
     (System Settings > General > Login Items & Extensions > Driver Extensions)
  2. System Settings > Privacy & Security > Input Monitoring
     enable karabiner_grabber and karabiner_observer
  3. reboot

after that, re-running this script just updates the mapping -- karabiner
watches karabiner.json and reloads it live.

heads up: re-running clobbers any rules you added in the karabiner GUI.
add them to this script instead (a .bak is written either way).

also: the F1-F12 / dictation prefs may need a log out and back in before the
window server picks them up. verify with System Settings > Keyboard, where
"Use F1, F2, etc. keys as standard function keys" should be on and the
Dictation shortcut should read "Off".

hammerspoon needs two permissions granted by hand (macOS will not let a
script do either of them):

  1. System Settings > Privacy & Security > Accessibility
     enable Hammerspoon (needed to post the rewritten click)
  2. System Settings > Privacy & Security > Input Monitoring
     enable Hammerspoon (needed to see the click first)

without both, ctrl-click in browsers keeps acting as a plain right-click.
Hammerspoon is set to launch at login, and ~/.hammerspoon/init.lua is the
config this script installs (a .bak is written if it differs).
NOTE

ok "mac desktop setup done"

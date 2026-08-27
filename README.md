# setup

My personal machine setup — this is **jb0n's** repo, not a general-purpose tool.
It is not for "you"; it is for me, and it reflects exactly how I like my machines:
my editors, my fonts, my apps, my API keys, my opinions. If you are not me, clone
it for ideas, but expect it to do what *I* want.

The deal: clone this on any new machine (mac or linux), run `./setup.sh`, and the
machine comes up the way I like it. Re-running it is always safe — **every part of
this repo is idempotent by contract**. I will be iterating on this forever, so the
number one rule is: never commit a change that breaks a re-run.

## Hard rules

1. Browser extensions come only from the official stores — AMO for Firefox,
   Chrome Web Store for Chrome. **NEVER** install unpacked, forked, or "custom"
   Chrome extensions. The `ExtensionInstallForcelist` policy only supports Web
   Store extensions, and that is the only Chrome extension path this repo uses.

## Usage

```sh
git clone git@github.com:jb0n/setup.git
cd setup
./setup.sh                        # run every module, in order
./setup.sh --list                 # list the modules
./setup.sh editors fonts          # run only those modules
./setup.sh --deepseek-apikey=KEY  # pass an api key through to the agents module
```

mac or linux are detected automatically. Windows gets a message and a non-zero
exit; I do not use Windows.

## How it works

- **`setup.sh`** — the runner. Detects the platform, exports `SETUP_PLATFORM` /
  `SETUP_PM` / `SETUP_DEEPSEEK_APIKEY`, then runs every `modules/*/setup.sh` in
  numeric order. Runs only the modules you name as args, if you gave any.
- **`lib/common.sh`** — shared helpers every module sources: platform/package-manager
  detection, `info`/`ok`/`warn`/`die` logging, `has`, and the `pkg_install` /
  `cask_install` / `pkg_update` wrappers that talk to brew, apt, dnf, pacman,
  zypper, or apk.
- **`lib/packages.sh`** — the per-distro package lists.
- **`modules/NN-name/setup.sh`** — one idempotent, self-contained unit. The numeric
  prefix sets the order. A module sources `lib/common.sh`, does its thing, and
  exits 0. To add a feature, drop in a new numbered module — the runner needs no
  changes.

## Idempotency contract

Running the whole thing twice must produce the same result as running it once. The
rules that keep this true:

1. Guard config/file installs with existence checks (`if [ ! -e ~/.x ]`), never
   blind `cp` over user state.
2. Never `>>` append to a config file without first checking it isn't already
   there.
3. Use marker files for downloads (e.g. the zip in `~/.fonts`) so re-runs skip.
4. Never `rm` or clobber anything the user may have touched; back it up (`.bak.$(date)`)
   instead.
5. Package/app installers (brew, apt, etc.) are naturally idempotent — just run them.
6. If a module is only for one platform, check `$PLATFORM` early and exit 0 on the
   other.

If a re-run misbehaves, that's a bug in this repo — fix the module, don't paper
over it.

## Where to update things

Everything is data-in-bash (not JSON) on purpose: an AI agent will be driving
most edits going forward, and the `.sh` functions are the most unambiguous thing
for it to find and modify. The table below is the map it (and I) use to know
exactly where each kind of change goes. When a new change is requested, update
only the section the table points at and leave everything else alone.

| I want to... | Edit |
| --- | --- |
| Add/remove a package | `lib/packages.sh` — `packages_core()` (boring base stuff) or `packages_dev()` (toolchain + tools), in the `case` row for each package manager I care about |
| Change git identity / ssh / PATH | `modules/25-git/setup.sh` |
| Add a font | Drop a file in `modules/30-fonts/`, e.g. `my-font.font`, containing `FONT_NAME`, `FONT_URL`, and `FONT_BREW` (the brew cask name, mac) |
| Add an app | `modules/50-apps/setup.sh` — write an `app_whatever()` function and add it to the `APPS` array |
| Add an editor plugin | `modules/40-editors/setup.sh` — the `PLUGINS` array (git URLs) |
| Add/remove a browser extension | `modules/45-browsers/setup.sh` — the `EXTENSIONS` array; each entry is `name\|firefox AMO slug\|chrome Web Store id`, leave a field empty when that browser doesn't have it |
| Change vim/nvim configs | `modules/40-editors/files/` — `vimrc`, `init.vim`, `ale.vim`, `eldar.vim` |
| Change mac-specific stuff | `modules/60-mac/setup.sh` and `modules/60-mac/files/` (key bindings, ghostty, karabiner, hammerspoon) |
| Change the AI agents / keys | `modules/70-agents/setup.sh` (omp + kilocode, deepseek provider config) |
| Add a whole new module | `modules/NN-name/setup.sh` — source `lib/common.sh`, follow the idempotency contract |
| Add a shared helper | `lib/common.sh` |

## Current modules

- **10-sudo** — passwordless sudo for my account (mac + linux).
- **20-packages** — base + dev packages via brew or the distro pm. Installs
  homebrew first on mac.
- **25-git** — git identity (jgould), ssh key, and `~/.local/bin` on PATH.
- **30-fonts** — Hasklig + Fira Code (one `.font` file each).
- **40-editors** — vim + neovim merged: shared colorscheme, plugin set, both configs.
- **45-browsers** — firefox + chrome, plus my extensions (1Password, uBlock,
  uBlock Origin Lite for chrome, Raindrop, Dark Reader) installed into both.
- **50-apps** — apps like signal-desktop (official apt repo, brew cask, or flatpak).
- **60-mac** — dock/keyboard defaults, Cocoa key bindings, ghostty, karabiner
  (ctrl-as-cmd), hammerspoon (ctrl-click opens links in new tabs).
- **70-agents** — omp (oh-my-pi) + kilocode, and wires the deepseek key into both
  when `--deepseek-apikey` is given.

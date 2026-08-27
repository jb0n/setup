# AGENTS.md

## No machine edits outside this repo (2026-08-27)

- NEVER edit a machine from this repo: no running the setup on the box you're
  working from unless asked, no touching `~/.config`, `~/bin`, `~/.bashrc`,
  `/etc`, installed files, or any state a `git checkout` cannot undo.
- This repo IS the way changes land on a machine: write the change as a file
  here (a module, a `.font`, a `lib/packages.sh` edit), commit, push, and the
  setup applies it. Do not mutate the machine directly.
- Exception: creating/modifying files inside this repo's working tree is fine.
  Anything else needs explicit approval from the user first.
- If you made an out-of-repo edit by mistake, say so and revert it.

## Rules that apply to every change

- README.md is the map: the "Where to update things" table says exactly which
  file/section each kind of change goes in. Update only that, nothing else.
- Everything must stay idempotent (see README "Idempotency contract") — this
  repo is re-run forever, so a change that breaks a re-run is a bug.
- Hard rule: browser extensions only from official stores (AMO / Chrome Web
  Store). NEVER unpacked/forked/"custom" Chrome extensions.
- Hard rule (mac): never add Karabiner mouse/pointing-device rules — that is
  what broke the mouse before. ctrl-click stays in Hammerspoon.

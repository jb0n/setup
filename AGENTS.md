# AGENTS.md

## Machine edits outside this repo (2026-08-27)

- You MAY edit a machine from this repo — including running the setup on the
  box you're working from, touching `~/.config`, `~/bin`, `~/.bashrc`, `/etc`,
  or installed files — but ONLY after asking the user and getting explicit
  approval for that edit. Ask every time; a past approval does not cover
  future edits.
- The preferred path is still: this repo IS the way changes land on a machine.
  Write the change as a file here (a module, a `.font`, a `lib/packages.sh`
  edit), commit, push, and the setup applies it.
- Exception: creating/modifying files inside this repo's working tree needs no
  approval.
- If you made an out-of-repo edit without asking, say so and revert it.

## Rules that apply to every change

- README.md is the map: the "Where to update things" table says exactly which
  file/section each kind of change goes in. Update only that, nothing else.
- Everything must stay idempotent (see README "Idempotency contract") — this
  repo is re-run forever, so a change that breaks a re-run is a bug.
- Hard rule: browser extensions only from official stores (AMO / Chrome Web
  Store). NEVER unpacked/forked/"custom" Chrome extensions.
- Hard rule (mac): never add Karabiner mouse/pointing-device rules — that is
  what broke the mouse before. ctrl-click stays in Hammerspoon.

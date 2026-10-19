# CLAUDE.md

Notes for Claude Code working on this repo. The README explains the setup for humans; this file
holds what an assistant needs on top of that, including work handed over from earlier sessions.

## The repo

- NixOS flake for one machine (`myMachine`), user `evilynn`. Lives at `~/.nixsysconf`
  (paths and links depend on that location).
- flake-parts + import-tree: every `.nix` file under `modules/` is loaded automatically.
  A feature is a file in `modules/features/<thing>.nix` defining `flake.nixosModules.<thing>`,
  switched on by adding `self.nixosModules.<thing>` to `imports` in
  `modules/hosts/myMachine/configuration.nix`.
- Outer `{ self, inputs, ... }:` is flake-parts (no `pkgs` there); the inner
  `{ config, pkgs, lib, ... }:` is the NixOS module.
- Home Manager is in `modules/features/home.nix` (user `evilynn`); most app configs are
  live-linked from `dotfiles/config/` with `mkOutOfStoreSymlink`, not generated.
- Comments in the .nix files are short and explain *why*; keep that style.

## Commands

```sh
git add -A                 # new files are invisible to the flake until git tracks them
nix buildswap              # fish wrapper: sudo nixos-rebuild switch --flake ~/.nixsysconf#myMachine
nix buildboot              # same, applies on next boot
nix flake check            # quick evaluation check
```

`nix buildswap` / `buildboot` are defined in `dotfiles/config/fish/functions/nix.fish`; in a
non-fish shell use the full `sudo nixos-rebuild ...` command. Rebuilding needs sudo, so ask the
user to run it if you can't.

## The user's preferences

- **Cheatsheets go in `/home/evilynn/Cheatsheets/`, not in this repo.** Markdown files.
- Never commit secrets or logins (e.g. `~/.config/gh`).
- Explanations in plain, simple English.

## Handover: Emacs Markdown rendering (in progress)

From a cloud Claude Code session (2026-10-19). Summary of that conversation:

1. The user asked for a cheatsheet on installing new things in this flake: where things go,
   a boilerplate feature module, how to tell if something needs a new flake input, and how to
   read mynixos.com. It was written as `FLAKE-CHEATSHEET.md`, first in the repo, then moved out
   because cheatsheets belong in `~/Cheatsheets/`. If `~/Cheatsheets/FLAKE-CHEATSHEET.md` is
   missing, recover it with `git show e5ab157:FLAKE-CHEATSHEET.md`. Its mynixos.com section was
   written without being able to open the site; worth checking against the real pages.
2. The user's Emacs showed the cheatsheet's Markdown as plain text. So
   `modules/features/emacs.nix` was added (and the plain `emacs-pgtk` removed from
   `systemPackages` in `configuration.nix`):
   - emacs-pgtk built with `emacsWithPackages`: `markdown-mode`, `nix-mode`, `fish-mode`, plus a
     generated `default.el` (via `trivialBuild`) holding the settings. Emacs loads `default.el`
     *after* the user's own init, so the user's config isn't touched (but can be overridden).
   - `.md` → `gfm-mode`; files under `/Cheatsheets/` → `gfm-view-mode` (read-only, markup
     hidden, tables aligned on open by `my/markdown-align-tables`, `e` switches to `gfm-mode`).
   - Bigger headings (`markdown-header-scaling`), code blocks highlighted in their language
     (`markdown-fontify-code-blocks-natively`), `visual-line-mode` for wrapping.
3. **Not tested in a real Emacs.** The cloud sandbox couldn't download the Emacs packages.
   Only checked: the module evaluates, and the generated `default.el` parses and its
   `auto-mode-alist` patterns match the right files.
4. The user says it's "almost working". **Ask them what still looks wrong** before changing
   things. Then test for real, e.g.:

   ```sh
   # after nix buildswap; check the setup without the user's init getting in the way
   emacs -Q --batch -l default ~/Cheatsheets/FLAKE-CHEATSHEET.md \
     --eval '(message "%s %s" major-mode markdown-hide-markup)'
   emacs ~/Cheatsheets/FLAKE-CHEATSHEET.md      # look at it for real
   ```

   Things that might be off (guesses, not confirmed):
   - Table alignment with hidden markup: cells with `` `code` `` or `**bold**` may line up by
     raw characters, not by what's visible.
   - `visual-line-mode` wraps wide tables, which can look messy; `truncate-lines` might be
     better in the view mode.
   - The user's own init might set `.md` handling or `inhibit-default-init`, which would stop
     `default.el` from loading or fight with it. Their Emacs config isn't in this repo; ask
     where it is.
   - The view uses the default (monospace) font; proportional text would need
     `variable-pitch-mode` + monospace faces for tables/code.

   Remove this handover section once the Emacs work is done (keep the parts above it).

## Handover: Default Apps Noctalia plugin (in progress)

Pieced together on 2026-10-19 from the git history of this repo and the plugin repo (the
earlier chat itself wasn't available, so the "why" below is partly inferred).

- **The plugin lives in its own repo**: <https://github.com/Evelynnsrepos/DefaultAppsNoctaliaPlugin>,
  checked out locally at `~/My-repos/DefaultAppsNoctaliaPlugin`. Its README explains how it
  works. In short: a bar icon opens a panel to pick the default browser, file manager,
  terminal, editor, image/video/music/PDF/archive viewer and email app. It writes
  `~/.config/mimeapps.list` itself (not via `xdg-mime`), and for the terminal also
  `~/.config/kdeglobals` and `~/.config/xdg-terminals.list`. The real work is in
  `default-apps/defaultapps.sh` (usable on its own: `scan`, `set`, `set-terminal`).
- The repo is a Noctalia **plugin source** (`registry.json` at the top, one folder per plugin
  id). It's added as a source in `dotfiles/config/noctalia/plugins.json`; Noctalia names
  the plugins `d6a79d:default-apps` and `d6a79d:dropdown-test`.
- **What happened, in order** (plugin repo commits):
  1. v1: a settings page with drop-downs (`NComboBox`).
  2. Drop-downs had zero width (`minimumWidth: 0`), fixed in 0.2.1, but they still
     **wouldn't open**.
  3. So the plugin went back to a bar icon + panel with plain clickable lists, no drop-downs.
  4. Added `dropdown-test`, a debug plugin (panel + settings page with drop-down/popup tests,
     an event log and path info, logs under the tag `DropdownTest`) to find out why.
  5. 0.3.1 (latest): search bar and "Show more" (5 apps at a time) in the app list.
- **In this repo**:
  - `configuration.nix` installs `xdg-terminal-exec` and `kdePackages.kservice`
    (`kbuildsycoca6`) for the plugin.
  - `home.nix` sets `NOCTALIA_CONFIG_DIR` to the real dotfiles folder, because
    `~/.config/noctalia` is a link and Qt refused to load plugin QML through it
    ("File name case mismatch"). This is probably what broke the drop-downs, but that's
    **not confirmed**.
  - `dotfiles/config/noctalia/plugins.json`: `default-apps` enabled, `dropdown-test`
    disabled. `settings.json` still has both widgets in the bar.
- **Open questions, ask the user before changing anything**:
  - With `NOCTALIA_CONFIG_DIR` set, do drop-downs open now (check with `dropdown-test`)?
    If yes, `dropdown-test` can be removed from the plugin repo, `plugins.json` and the
    bar in `settings.json`.
  - Does picking an app actually work (Dolphin, GTK apps, `xdg-open`, Flatpaks)?
  - Anything else they want from the plugin.

  Remove this handover section once the plugin work is done (keep the parts above it).

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

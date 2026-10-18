#!/usr/bin/env bash
# Copies ~/.config/niri/config.kdl into the flake so the next rebuild picks it up.
set -euo pipefail

src="$HOME/.config/niri/config.kdl"
dest="$HOME/.nixsysconf/modules/features/niri-config.kdl"

niri validate -c "$src"
cp "$src" "$dest"
git -C "$HOME/.nixsysconf" add "$dest"

echo "Copied $src -> $dest"
echo "Now rebuild: sudo nixos-rebuild switch --flake ~/.nixsysconf#myMachine"

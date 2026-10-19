# nixsysconf

My NixOS setup as a flake: **niri** (scrolling tiling compositor) with the **Noctalia** shell,
where the wallpaper decides the colours of almost everything: terminals, Qt/KDE apps (Material 3
look via Kvantum), GTK apps, Spotify, Discord, Steam, mpv, yazi.

One `nixos-rebuild` gives you the system, the packages and all the app configs. A few things
can't (or shouldn't) be in a flake. They are listed under [What's not included](#whats-not-included)
with steps to set them up by hand.

---

## What you get

| Part | What it is |
|---|---|
| **niri** | Compositor, with its config built into the flake (`modules/features/niri.nix` + `niri-config.kdl`) |
| **Noctalia** | Bar, launcher, notifications, wallpaper, and the colour generator for everything else |
| **KMaterial** | Material 3 look for Qt/KDE apps (Dolphin, Kate), coloured by Noctalia ([KMaterial-de](https://github.com/Evelynnsrepos/KMaterial-de)) |
| **Terminals** | Alacritty (`Mod+T`) and kitty (`Mod+Return`), fish + starship, eza/bat/zoxide/fzf, fastfetch on start |
| **Apps** | Dolphin, Kate, Vivaldi, Firefox, Discord with Vencord, Steam with Millennium, mpv (uosc), Mission Center, Godot 4.7, JetBrains Toolbox, Claude Desktop + Claude Code, Mullvad VPN |
| **Home Manager** | Links the app configs in `~/.config` to `dotfiles/config/` in this repo |
| **GNOME** | Installed as a fallback session (and for GDM, the login screen) |

### Keybinds (the ones added on top of niri's defaults)

| Key | Action |
|---|---|
| `Mod+T` | Alacritty |
| `Mod+Return` | kitty |
| `Mod+D` | Noctalia launcher |
| `Mod+E` | Dolphin |
| `Mod+Q` | Close window |
| `Mod+A` | Overview |
| `Mod+Shift+S` | Screenshot (drag a rectangle) |

The rest are in `modules/features/niri-config.kdl`.

---

## How it's put together

```
flake.nix                      inputs; every file in modules/ is loaded automatically (import-tree)
modules/
  hosts/myMachine/
    configuration.nix          the system: packages, fonts, locale, users, services
    hardware-configuration.nix disks and kernel modules (MACHINE-SPECIFIC, replace it)
    default.nix                defines nixosConfigurations.myMachine
  features/
    niri.nix                   niri + its settings (monitors, binds, window rules)
    niri-config.kdl            the rest of the niri config (copied from ~/.config/niri by sync-niri.sh)
    noctalia.nix               Noctalia shell package
    home.nix                   Home Manager: links ~/.config/<app> -> dotfiles/config/<app>
    links.nix                  link router + default apps for link types
    millennium.nix             Steam with Millennium
    claude.nix                 Claude Desktop + Claude Code
dotfiles/
  config/                      app configs (linked live by Home Manager)
  gnome-interface.dconf        GTK font, icon, cursor and dark-mode settings
  flatpaks.txt                 list of installed Flatpaks
sync-niri.sh                   copies ~/.config/niri/config.kdl into the flake
```

**Live links.** Home Manager doesn't copy the configs into the read-only Nix store. It links
`~/.config/<app>` to the folder in `dotfiles/config/`. That means apps and Noctalia can keep
writing their settings, changing the wallpaper re-themes everything right away (no rebuild),
and every change shows up in `git status`. Whole folders are linked, not single files, because
many apps save by writing a new file and renaming it over the old one, which would replace a
link to a single file.

Linked: `fish kitty alacritty noctalia mpv Kvantum qt6ct spicetify millennium fastfetch fetch
yazi Vencord/settings`.

---

## Install

You need a PC with **UEFI** (any machine from the last ~10 years) and an internet connection.

### 1. Install NixOS

1. Download the **graphical ISO** from <https://nixos.org/download/#nixos-iso>, put it on a USB
   stick (e.g. with [Ventoy](https://www.ventoy.net) or `dd`), boot it.
2. Run the installer. Pick **GNOME** as the desktop and set up your user. Remember the username.
3. Reboot into the new system and log in.

### 2. Get this repo

The repo has to live at **`~/.nixsysconf`**: the config links and scripts point there.

```sh
nix-shell -p git gh
gh auth login          # only needed while the repo is private
git clone https://github.com/Evelynnsrepos/nixsysconf ~/.nixsysconf
cd ~/.nixsysconf
```

### 3. Make it yours

**a) Hardware.** `hardware-configuration.nix` describes *my* disks; with it your PC won't boot.
Generate yours and wrap it in the same module header:

```sh
nixos-generate-config --show-hardware-config > /tmp/hw.nix
```

Open `modules/hosts/myMachine/hardware-configuration.nix`, keep the first three lines and the
two closing `};` / `}` at the bottom, and replace everything in between with the contents of
`/tmp/hw.nix` (without its own first `{ config, lib, pkgs, modulesPath, ... }:` line and the
outer braces). It should look like this:

```nix
{self, inputs, ...}: {

  flake.nixosModules.myMachineHardware = { config, lib, pkgs, modulesPath, ... }: {

    # ... everything from inside /tmp/hw.nix ...

  };

}
```

**b) Username.** My user is `evilynn`. Replace it with yours everywhere (configs, paths):

```sh
cd ~/.nixsysconf
grep -rlI evilynn --exclude-dir=.git --exclude=README.md . | xargs sed -i 's/evilynn/YOURNAME/g; s/Evilynn/YOURNAME/g'
```

This changes `configuration.nix` (the user account), `home.nix` (Home Manager user) and a few
configs with full paths (Noctalia wallpaper folder and avatar, qt6ct, spicetify, GTK bookmarks,
niri).

**c) Things you probably want to change** in `modules/hosts/myMachine/configuration.nix`:

| Setting | Mine | Note |
|---|---|---|
| `time.timeZone` | `Europe/Berlin` | |
| `i18n.defaultLocale` / `extraLocaleSettings` | English UI, German formats | |
| `services.xserver.xkb` / `console.keyMap` | German (`de`, `dsb_qwertz`) | also `input.keyboard.xkb.layout` in `niri.nix` |
| `networking.hostName` | `nixos` | |
| `boot.loader` | GRUB, EFI, finds Windows (`useOSProber`) | |
| `environment.systemPackages` | my apps | remove what you don't want |
| `services.mullvad-vpn` | on | remove if you don't use Mullvad |

And in `modules/features/niri.nix`:

- **`outputs`**: my three monitors (names, resolutions, positions). niri ignores monitors it
  can't find, so it works without changes, but you'll want your own. `niri msg outputs` lists
  yours.
- **`window-rules`**: Discord and Spotify open on specific monitors of mine.

Don't touch `system.stateVersion` / `home.stateVersion`; they don't need to match your install.

### 4. Build

```sh
cd ~/.nixsysconf
git add -A                     # flakes only see files git knows about
sudo nixos-rebuild boot --flake ~/.nixsysconf#myMachine
reboot
```

The first build takes a while (Steam, kernel, etc. are downloaded). At the login screen, click
the gear icon and choose **niri**.

If something doesn't boot, pick the previous generation in the GRUB menu: the old system is
still there.

### 5. After the first login

Do these once, in this order:

1. **Wallpaper + colours.** Put wallpapers in `~/Pictures/Wallpapers` and pick one in Noctalia.
   That generates all the colour files (they aren't in git because they change with every
   wallpaper).
2. **KMaterial (Qt/KDE theme).** Clone it where Noctalia's templates expect it:
   ```sh
   git clone https://github.com/Evelynnsrepos/KMaterial-de ~/My-repos/KMaterial-de
   ```
   The Noctalia templates (`dotfiles/config/noctalia/user-templates.toml`) and the Kvantum
   selection are already in this repo. Change the wallpaper once more so Noctalia builds the
   Kvantum theme and icons. For Kate: Settings → Configure Kate → Color Themes → **Noctalia**,
   and turn off automatic theme selection.
3. **Configs that aren't linked** (see below): copy them in once.
   ```sh
   cp -r ~/.nixsysconf/dotfiles/config/{gtk-3.0,gtk-4.0,qt5ct,kdeglobals,starship.toml} ~/.config/
   dconf load /org/gnome/desktop/interface/ < ~/.nixsysconf/dotfiles/gnome-interface.dconf
   ```
4. **Noctalia plugins.** The plugin sources are already in the config. Open Noctalia's settings →
   Plugins and install the ones you want (I use Default Apps, Keybind Cheatsheet, Custom Sticker, USB Drive Manager).
5. **Flatpaks**, see below.
6. **Spotify theme.** After Spotify (Flatpak) is installed and opened once:
   `spicetify backup apply`.
7. **Steam theme.** Open Steam → Millennium → Themes, install **Material-Theme** and pick the
   **Matugen** colour option so it follows Noctalia.

From now on, rebuild with the fish shortcuts (defined in `dotfiles/config/fish/functions/nix.fish`):

```sh
nix buildswap      # = sudo nixos-rebuild switch --flake ~/.nixsysconf#myMachine
nix buildboot      # = ... boot (applies on next reboot)
```

To update everything: `nix flake update` in `~/.nixsysconf`, then rebuild.

---

## What's not included

These aren't managed by the flake. Some can't be, some I chose not to.

### Flatpaks

Installed by hand. The list is in `dotfiles/flatpaks.txt`.

From Flathub:

```sh
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub app.zen_browser.zen com.github.Matoking.protontricks \
  com.github.tchx84.Flatseal com.vscodium.codium com.vysp3r.ProtonPlus net.davidotek.pupgui2
flatpak install --user flathub com.spotify.Client   # --user: spicetify patches the user install
```

Zen is the default browser (the link router opens links in it), so install it before clicking links.

Not on Flathub, installed from `.flatpak` files:

- **ArtCraft Launcher** (PhotoCraft, FilmCraft, PdfCraft, WordCraft, …): download
  `artcraft-launcher-<version>-linux-x86_64.flatpak` from
  <https://github.com/storytold/craft-launcher/releases>, run
  `flatpak install ./artcraft-launcher-…flatpak`, then install the apps from inside the
  launcher. It also keeps them updated.
- **Evelopment Games Designer**: `.flatpak` from
  <https://github.com/Evelynnsrepos/Evelopment-Games-Designer/releases>, installed the same way.

### Configs that are copied, not linked

These are in `dotfiles/` as a snapshot. Step 5.3 above copies them in.

| File | Why not linked |
|---|---|
| `kdeglobals` | Single file directly in `~/.config`; KDE apps replace it on save, which would break a link |
| `starship.toml` | Same (single file), and I keep it separate on purpose |
| `gtk-3.0`, `gtk-4.0`, `qt5ct` | Not linked yet; mostly Noctalia output, so they regenerate anyway |
| `gnome-interface.dconf` | dconf is a database, not a file; load it with `dconf load` |

### niri config

niri's config isn't live-linked. The flake builds its own read-only copy from
`modules/features/niri-config.kdl`. To change it: edit `~/.config/niri/config.kdl`, run
`~/.nixsysconf/sync-niri.sh` (validates it and copies it into the flake), then rebuild.
Monitors, binds and window rules are in `modules/features/niri.nix`.

### Not in this repo at all

- **Wallpapers** (`~/Pictures/Wallpapers`): bring your own.
- **Noctalia plugins**: downloaded by Noctalia's plugin manager (the list of what's enabled *is*
  in the repo, `noctalia/plugins.json`).
- **Cursor switcher scripts**: the Oreo cursors are installed (`oreo-cursors-plus`), my scripts
  for switching colours aren't. Set one with
  `gsettings set org.gnome.desktop.interface cursor-theme oreo_spark_red_cursors`
  (all names: `ls /run/current-system/sw/share/icons | grep oreo`).
- **Logins, browser profiles, Discord/Spotify/Steam accounts**: log in yourself. Nothing
  personal or secret is in this repo, and nothing should be (e.g. never add `~/.config/gh`, it
  holds a GitHub token).

---

## Fixes and tweaks in here

Problems I ran into and how this config solves them, in case you hit them elsewhere.

- **Rounder Kvantum selections.** Kvantum caps the rounding of list items at 6px, so selections
  can't be Material 3 pills. An overlay in `configuration.nix` patches Kvantum to allow 24px.
- **Qt/KDE apps ignoring the colours.** Outside of Plasma, Dolphin and Kate ignore qt6ct's
  palette. `QT_QPA_PLATFORMTHEME=kde` + `plasma-integration` makes them read `kdeglobals`, which
  Noctalia writes. `QT_STYLE_OVERRIDE=kvantum` gives them the KMaterial style. (Set in `niri.nix`.)
- **Clicked links doing nothing.** Flatpak apps opened with `--file-forwarding` go through the
  document portal; when its mount at `/run/user/$UID/doc` is gone, links silently fail. The
  link router (`links.nix`) launches Zen and Spotify directly instead, and sends
  `open.spotify.com` links to the Spotify app and Steam links to Steam.
- **Logins from the terminal.** `claude` and JetBrains Toolbox log in through custom link types
  (`claude-cli://`, `jetbrains://`); `links.nix` registers handlers for both.
- **Mission Center** is installed from nixpkgs, not as a Flatpak: its `magpie` helper has to
  run on the host, which the Flatpak version can't do on NixOS.
- **Spotify theming.** Spotify is the Flatpak (user install), patched by `spicetify-cli` from
  nixpkgs, with the Comfy theme coloured by Noctalia.
- **Steam theming.** Steam is replaced with Millennium's build through its overlay (so it builds
  against this flake's nixpkgs).
- **Discord with Vencord** via `discord.override { withVencord = true; }`, settings linked.
- **mpv** built with the `uosc` and `thumbfast` scripts, coloured by a Noctalia template.
- **Godot** is pinned to 4.7 (`godot_4_7`); plain `godot` would jump to new major versions.
- **Focus follows mouse** without niri scrolling the view to the focused window
  (`max-scroll-amount = "0%"`).
- **Fonts** are set system-wide (Lexend Deca for the UI, Maple Mono NF for terminals), and Home
  Manager's font handling is turned off so the two don't fight.
- **Noctalia plugins not loading through the link.** Qt refuses to load plugin QML through the
  `~/.config/noctalia` link ("File name case mismatch", because the real path differs from the
  one it was given). `home.nix` sets `NOCTALIA_CONFIG_DIR` to the real folder in the repo.
- **Home Manager backups.** If a config folder already exists when Home Manager wants to link
  it, it's renamed to `<name>.hm-backup` instead of the build failing.

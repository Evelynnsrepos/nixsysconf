# Cheatsheet: installing something new

How to add a program, service or someone else's flake to *this* config, where each piece goes,
and how to tell if it needs a new input in `flake.nix`.

Short version:

| What you found | Needs a new input? | Where it goes |
|---|---|---|
| A **package** in nixpkgs (`pkgs.foo`) | No | `environment.systemPackages` in `modules/hosts/myMachine/configuration.nix` |
| A **NixOS option** from nixpkgs (`programs.foo.enable`, `services.foo.*`, `hardware.foo.*`) | No | `configuration.nix`, or its own file in `modules/features/` |
| A **Home Manager option** (`programs.foo.*` for your user, `xdg.*`, `home.*`) | No (Home Manager is already an input) | inside `users.evilynn = { ... }` in `modules/features/home.nix` |
| Anything from **another flake** (a GitHub repo that says "add this to your inputs") | **Yes** | input in `flake.nix` + a feature module in `modules/features/` |

After any change:

```sh
cd ~/.nixsysconf
git add -A          # new files are invisible to the flake until git knows about them
nix buildswap       # = sudo nixos-rebuild switch --flake ~/.nixsysconf#myMachine
```

---

## 1. How this config is wired (the 30-second version)

```
flake.nix                         inputs (other flakes). Every .nix file in modules/ is loaded
                                  automatically by import-tree, you never list files here.
modules/features/<thing>.nix      one feature = one file, defines flake.nixosModules.<thing>
modules/hosts/myMachine/
  configuration.nix               imports the features you want + general system settings
  default.nix                     builds nixosConfigurations.myMachine (don't need to touch)
```

So adding a feature is always the same two steps:

1. Create `modules/features/<thing>.nix` that defines `flake.nixosModules.<thing>`.
2. Add `self.nixosModules.<thing>` to the `imports` list in `configuration.nix`.

> import-tree *loads* every file, but a feature module does nothing until step 2 turns it on.
> That's on purpose: you can keep a feature file around and switch it off by removing one line.

---

## 2. The boilerplate feature module

Copy this into `modules/features/<thing>.nix` and rename `<thing>`:

```nix
{ self, inputs, ... }: {

  # What this is and why it's here
  flake.nixosModules.<thing> = { config, pkgs, lib, ... }: {

    # NixOS options go here, exactly like in configuration.nix, e.g.
    # programs.foo.enable = true;
    # services.foo.enable = true;

    environment.systemPackages = [
      # pkgs.foo
    ];

  };

}
```

Then in `modules/hosts/myMachine/configuration.nix`:

```nix
    imports =
      [ self.nixosModules.myMachineHardware
        self.nixosModules.claude
        ...
        self.nixosModules.<thing>     # <- add this
      ];
```

Two layers, don't mix them up:

- **Outer** `{ self, inputs, ... }:` is flake-parts. Here you have `inputs` (everything in
  `flake.nix`) and `self` (this flake). You *don't* have `pkgs` or `config` here.
- **Inner** `{ config, pkgs, lib, ... }:` is a normal NixOS module. Here you have `pkgs`, `lib`,
  `config`. Because it's inside the outer one, you can *also* use `inputs` and `self` in it.

Real examples in this repo:

| File | Shows how to |
|---|---|
| `features/opentabletdriver.nix` | just set NixOS options (simplest possible, no inputs) |
| `features/claude.nix` | import another flake's NixOS module + add a package |
| `features/millennium.nix` | use another flake's overlay to replace a package |
| `features/home.nix` | Home Manager (per-user stuff) |
| `features/niri.nix` | build your own package with `perSystem` |

---

## 3. Recipes

### 3a. Just a package from nixpkgs (no input)

Add it to the list in `configuration.nix`:

```nix
    environment.systemPackages = with pkgs; [
      ...
      foo
      kdePackages.bar     # use the full attribute path the search shows
    ];
```

Unfree (Steam, Discord, Spotify…) is fine: `nixpkgs.config.allowUnfree = true` is already set.

### 3b. A program/service with NixOS options (no input)

If there's a `programs.foo.enable` or `services.foo.enable`, **prefer that over just adding the
package**. The option also sets up the systemd service, groups, udev rules, firewall, etc.
(That's why OpenTabletDriver is `hardware.opentabletdriver.enable` and not just a package.)

```nix
  flake.nixosModules.foo = { pkgs, ... }: {
    services.foo = {
      enable = true;
      settings.port = 1234;
    };
  };
```

### 3c. Home Manager options (no input)

Per-user programs and dotfiles go in `features/home.nix`, inside `users.evilynn = { config, ... }: ... in { ... }`:

```nix
      in {
        home.stateVersion = "26.05";
        ...
        programs.foo = {
          enable = true;
          settings = { ... };
        };
      };
```

`useGlobalPkgs = true` is set, so `pkgs` here is the same as the system's (overlays and
unfree included).

> Note: most app configs in this repo are *live-linked* from `dotfiles/config/` (see README).
> If you let Home Manager generate a config with `programs.foo.settings`, don't also add `foo`
> to the `xdg.configFile` link list, they'd fight over the same file.

### 3d. Something from another flake (needs an input)

**Step 1, `flake.nix`**, add the input:

```nix
  inputs = {
    ...
    # What it is
    foo.url = "github:owner/repo";
    foo.inputs.nixpkgs.follows = "nixpkgs";   # see "follows" below
  };
```

**Step 2, `modules/features/foo.nix`**, use it. What you write depends on what the flake
*offers* (its README says, or check with `nix flake show`, see section 4):

```nix
{ self, inputs, ... }: {

  flake.nixosModules.foo = { pkgs, ... }: {

    # A) It has a NixOS module (README says "imports = [ foo.nixosModules.default ]")
    imports = [ inputs.foo.nixosModules.default ];
    programs.foo.enable = true;        # whatever options its README lists

    # B) It only has a package
    environment.systemPackages = [
      inputs.foo.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # C) It has an overlay (adds/replaces things in pkgs)
    nixpkgs.overlays = [ inputs.foo.overlays.default ];
    environment.systemPackages = [ pkgs.foo ];

  };

}
```

Pick **one** of A/B/C, not all three. Preference: A (module) > C (overlay) > B (package).

**D) It has a Home Manager module** (README says `homeManagerModules.*` or `homeModules.*`):
put the import inside the user in `features/home.nix`:

```nix
      users.evilynn = { config, ... }: let ... in {
        imports = [ inputs.foo.homeManagerModules.default ];
        programs.foo.enable = true;
        ...
      };
```

**Step 3**: add `self.nixosModules.foo` to `configuration.nix` imports, then:

```sh
git add -A
nix flake lock        # downloads the new input and writes it to flake.lock
nix buildswap
```

#### About `inputs.nixpkgs.follows`

`foo.inputs.nixpkgs.follows = "nixpkgs"` makes the other flake use *your* nixpkgs instead of
downloading its own copy. Less to download, and things match.

- Add it if the flake **has** a `nixpkgs` input (check with `nix flake metadata github:owner/repo`).
- Don't add it if the flake has no `nixpkgs` input (you get a warning), or if its README says not
  to (some pin nixpkgs on purpose, e.g. for a binary cache).
- Same idea for other shared inputs, e.g. `foo.inputs.home-manager.follows = "home-manager";`.

---

## 4. "Does this need an extra input?" How to find out

Work through this in order. Stop at the first "yes".

1. **Is it in nixpkgs?** Search for it (any of these):
   - <https://search.nixos.org/packages> and <https://search.nixos.org/options> (pick **unstable**, this config is on nixos-unstable)
   - <https://mynixos.com> (see section 5)
   - terminal: `nix search nixpkgs foo`

   Found → **no input**. Use recipe 3a/3b.
2. **Is it a Home Manager option?** Search <https://home-manager-options.extranix.com> (pick
   *unstable/master*) or mynixos. Found → **no input**, recipe 3c.
3. **Does the project's README talk about `inputs`, `flake.nix`, `nixosModules`,
   `homeManagerModules` or `overlays`?** → **needs an input**, recipe 3d.
4. **Still not sure, but it's a GitHub repo with a `flake.nix`?** Ask the flake what it offers:

   ```sh
   nix flake show github:owner/repo        # outputs: packages, nixosModules, overlays, ...
   nix flake metadata github:owner/repo    # its own inputs (does it have nixpkgs? -> follows)
   ```

   Example output and what it means:

   ```
   ├───nixosModules
   │   └───default: NixOS module          -> recipe 3d A, inputs.foo.nixosModules.default
   ├───homeManagerModules
   │   └───default: ...                   -> recipe 3d D
   ├───overlays
   │   └───default: Nixpkgs overlay       -> recipe 3d C
   └───packages
       └───x86_64-linux
           └───default: package 'foo-1.2' -> recipe 3d B
   ```
5. **No flake, not in nixpkgs?** Then there's nothing to add as an input. Options: Flatpak (see
   README), AppImage (`appimage-run`), or a generic Linux binary (works thanks to
   `programs.nix-ld.enable`, already on via `claude.nix`).

### Error messages that mean "you're missing an input or an import"

| Error | Meaning | Fix |
|---|---|---|
| `The option 'programs.foo' does not exist` | No module defines that option. Either it's a typo, it's a Home Manager option you put in a NixOS module, or it comes from a flake you didn't import | Check where the option comes from (section 5), then 3c or 3d |
| `undefined variable 'foo'` | You used `foo` without `pkgs.` / `inputs.` in front, or it isn't in `with pkgs;` | Write `pkgs.foo` or `inputs.foo` |
| `attribute 'foo' missing` (on `inputs`) | The input isn't in `flake.nix` (or not locked yet) | Add it, run `nix flake lock` |
| `attribute 'default' missing` (on `inputs.foo.nixosModules`) | The flake names it differently | `nix flake show github:owner/repo` and use the real name |
| `Path '...' is not tracked by Git` / file "doesn't exist" | New file not added to git | `git add -A` |
| `undefined variable 'pkgs'` in a feature file | You used `pkgs` in the outer `{ self, inputs, ... }:` part | Move it into the inner `{ pkgs, ... }:` module |

### Poke at things before building

```sh
cd ~/.nixsysconf
nix repl
nix-repl> :lf .                                   # load this flake (also gives you `inputs`)
nix-repl> inputs.foo.<TAB>                        # what does the input offer?
nix-repl> nixosConfigurations.myMachine.config.services.foo.enable   # does the option exist / what is it set to?
nix-repl> nixosConfigurations.myMachine.pkgs.foo.version            # which version would I get?
```

---

## 5. Using mynixos.com

<https://mynixos.com> indexes packages and options from nixpkgs, Home Manager and a lot of
community flakes in one place. The trick is to **read where the thing comes from**, because that
decides where it goes in this config. It's in the URL / breadcrumb right after the domain:

| URL looks like | Source | Input? | Put it in |
|---|---|---|---|
| `mynixos.com/nixpkgs/package/foo` | nixpkgs package | No | `environment.systemPackages` → `pkgs.foo` (recipe 3a) |
| `mynixos.com/nixpkgs/option/services.foo.enable` | NixOS option | No | `configuration.nix` or a feature module (recipe 3b) |
| `mynixos.com/home-manager/option/programs.foo.enable` | Home Manager option | No | `features/home.nix`, inside `users.evilynn` (recipe 3c) |
| anything else (a flake name / `owner/repo`) | another flake | **Yes** | `flake.nix` input + feature module (recipe 3d) |

### Reading an option page

An option page shows roughly: the **name**, **description**, **type**, **default**, **example**
and **declarations** (the source file that defines it).

- **Name → Nix:** the dotted name *is* the code. `services.mullvad-vpn.gui.enable` becomes
  `services.mullvad-vpn.gui.enable = true;`. Options with the same start can be grouped:
  `services.mullvad-vpn = { enable = true; gui.enable = true; };` (that's how it is in
  `configuration.nix`).
- **Type → what to write:**

  | Type says | Write |
  |---|---|
  | `boolean` | `true` / `false` |
  | `string` | `"text"` |
  | `signed integer` / `positive integer` | `1234` |
  | `package` | `pkgs.foo` |
  | `list of ...` | `[ ... ]` |
  | `attribute set of ...` / `submodule` | `{ ... }` |
  | `null or X` | `null` or an X |
  | `one of "a", "b"` | `"a"` |
  | `path` | `./file` (relative to the .nix file) |

- **Declarations** is the tie-breaker: if it points into `NixOS/nixpkgs` → no input; into
  `nix-community/home-manager` → Home Manager; into some other repo → that repo is the flake you
  need as an input.
- **Example** is usually copy-paste-ready, just put it under the full option name.

### Reading a package page

- The **attribute name** is what goes after `pkgs.`. Watch for nested ones:
  `kdePackages.dolphin`, `fishPlugins.fzf-fish`, `nerd-fonts.jetbrains-mono`.
- Check the **version**: mynixos may show a different nixpkgs branch than *unstable*. If it
  matters, confirm with `nix repl` (above) or search.nixos.org set to unstable.
- **Before installing a package, search mynixos for an option with the same name**
  (e.g. search `steam` → `programs.steam.enable` exists). If there is one, use the option
  (recipe 3b) instead of the bare package.

### Reading a community-flake page

- It shows the flake's **URL**: that's what goes in `foo.url = "...";` in `flake.nix`. Pick a
  short, sensible input name (`foo`), that's how you refer to it as `inputs.foo`.
- It lists the flake's **options** and **packages**. Options from a flake only exist after you
  import that flake's module (recipe 3d A for NixOS options, D for Home Manager options);
  otherwise you get `The option ... does not exist`.
- Still run `nix flake show <url>` to get the exact output names (`nixosModules.default` vs
  `nixosModules.foo`, etc.) and `nix flake metadata <url>` to decide on `follows`.

---

## 6. Worked examples

**Package, no input** (e.g. `htop`): mynixos → `nixpkgs/package/htop` → add `htop` to
`environment.systemPackages` in `configuration.nix`.

**NixOS option, own feature file** (this is how `opentabletdriver.nix` was made): mynixos →
`nixpkgs/option/hardware.opentabletdriver.enable` → new file:

```nix
{ ... }: {
  flake.nixosModules.opentabletdriver = { ... }: {
    hardware.opentabletdriver.enable = true;
  };
}
```

→ add `self.nixosModules.opentabletdriver` to imports → `git add -A` → `nix buildswap`.

**Home Manager option** (e.g. `programs.git`): mynixos → `home-manager/option/programs.git.enable`
→ in `home.nix` under `users.evilynn`: `programs.git = { enable = true; settings.user.name = "..."; };`.

**Flake with a NixOS module** (this is how `claude.nix` works):

```nix
# flake.nix
claude-desktop.url = "github:poeck/claude-desktop-nix-flake";
claude-desktop.inputs.nixpkgs.follows = "nixpkgs";

# modules/features/claude.nix
flake.nixosModules.claude = { pkgs, ... }: {
  imports = [ inputs.claude-desktop.nixosModules.default ];
  programs.claude-desktop.enable = true;
};
```

**Flake with an overlay** (this is how `millennium.nix` works):

```nix
# flake.nix
millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

# modules/features/millennium.nix
flake.nixosModules.millennium = { pkgs, ... }: {
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];
  programs.steam.package = pkgs.millennium-steam;
};
```

---

## 7. If it breaks

- Read the **first** `error:` line, then look it up in the table in section 4.
- `nix buildswap` fails → nothing changed, your system is still the old one.
- It builds but the system is broken → reboot and pick the previous generation in GRUB.
- Removing a feature: delete its line from `imports` in `configuration.nix` (and the input from
  `flake.nix` if nothing else uses it, then `nix flake lock`).
- Updating one input only: `nix flake update foo`. Everything: `nix flake update`.

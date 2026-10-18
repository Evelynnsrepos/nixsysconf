# NixOS Cheat Sheet

Copied 2026-10-18 from the online doc: https://claude.ai/code/artifact/723dad53-d7d6-4022-88d7-73f60bb29791

## Rebuilding

Your safe routine: test-build first without sudo, then `boot` and reboot. Every command points at your flake with `--flake ~/.nixsysconf#myMachine`.

| Command | What it does | Needs sudo |
| --- | --- | --- |
| `nixos-rebuild build --flake ~/.nixsysconf#myMachine` | Builds only and leaves a `./result` link. Changes nothing on the system. | No |
| `sudo nixos-rebuild test --flake ~/.nixsysconf#myMachine` | Activates now, but adds no boot entry. A reboot undoes it. | Yes |
| `sudo nixos-rebuild switch --flake ~/.nixsysconf#myMachine` | Activates now and becomes the default boot entry. | Yes |
| `sudo nixos-rebuild boot --flake ~/.nixsysconf#myMachine` | Becomes the default boot entry but only takes effect after a reboot. Safest for big changes. | Yes |
| `nix flake check ~/.nixsysconf` | Checks the flake for evaluation errors without building. | No |

See what a build would change compared with the running system:

```
nixos-rebuild build --flake ~/.nixsysconf#myMachine
nix store diff-closures /run/current-system ./result
```

Add `--show-trace` to any rebuild for a longer error message when evaluation fails.

## Generations and rollback

Every `switch` or `boot` creates a new generation, and each one shows up in the GRUB menu. If something breaks, pick an older one at boot. That is how you recovered from the login problem.

| Command | What it does |
| --- | --- |
| `nixos-rebuild list-generations` | Lists system generations with date and NixOS version. |
| `sudo nixos-rebuild switch --rollback` | Switches back to the previous generation right away. |
| GRUB menu, then "NixOS - All configurations" | Boots any older generation without a working login. |
| `readlink /run/current-system` | Shows which store path is running now. |

A rollback only changes the system, not your flake files. After rolling back, fix or revert the files in `~/.nixsysconf` (for example `git diff` or `git restore <file>`) before you rebuild again.

## Garbage collection

Old generations keep their packages on disk until you delete the generation and collect garbage. Always keep at least one known-good generation.

| Command | What it does |
| --- | --- |
| `sudo nix-collect-garbage --delete-older-than 14d` | Deletes system generations older than 14 days, then frees unused packages. Keeps recent rollbacks. |
| `sudo nix-collect-garbage -d` | Deletes ALL old system generations. Only the current one is left, so no rollback. |
| `nix-collect-garbage -d` | The same for your user profile (no sudo). |
| `nix-store --gc` | Frees unused packages but keeps every generation. |
| `nix store optimise` | Deduplicates identical files in the store to save space. |
| `du -sh /nix/store` | Shows how big the store is. |

After deleting generations, run `sudo nixos-rebuild boot --flake ~/.nixsysconf#myMachine` once so the GRUB menu drops the deleted entries.

Optional automatic cleanup, added to `configuration.nix`:

```
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
};
nix.settings.auto-optimise-store = true;
```

Rebuilds create a `./result` link in your current folder. It counts as in use and blocks garbage collection of that build, so delete it (`rm result`) when you no longer need it.

## Flakes basics

A flake has two parts. **Inputs** are the sources it pulls from: nixpkgs and other flakes. **Outputs** are what it builds from them, such as your system `nixosConfigurations.myMachine`. `flake.lock` pins every input to an exact commit, so builds don't change until you update.

| Command | What it does |
| --- | --- |
| `nix flake update --flake ~/.nixsysconf` | Updates ALL inputs to their latest versions. Big jump: test-build and use `boot`. |
| `nix flake update nixpkgs --flake ~/.nixsysconf` | Updates one input only. |
| `nix flake metadata ~/.nixsysconf` | Shows every input and the commit it is locked to. |
| `nix flake show ~/.nixsysconf` | Lists the flake's outputs. |

Rules that matter for your flake:

- **git add new files.** `~/.nixsysconf` is a git repo, so Nix only sees files git tracks. A new `.nix` file you haven't `git add`ed is invisible and gives a "does not exist" error. Edits to tracked files work without a commit.
- **New inputs lock themselves.** Adding a line under `inputs` and rebuilding writes that input into `flake.lock`. The other inputs stay where they were.
- **`inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"`** makes an input use your nixpkgs instead of its own. It saves disk space but can break old flakes. Leave it off for `claude-desktop`.
- **Root-owned lock file.** If `flake.lock` becomes root-owned after a sudo build, fix it with `sudo chown evilynn:users ~/.nixsysconf/flake.lock`.

## Your dendritic setup

Inputs go only in `flake.nix`. Everything else is a module file under `modules/`, and `import-tree` loads every one of them automatically, so `outputs` never needs editing.

(Diagram of how these files fit together: see the online version linked at the top.)

A file being loaded only defines a module. It does nothing until `configuration.nix` lists it in `imports`.

```
~/.nixsysconf/
├── flake.nix                      # inputs go here (only here)
├── flake.lock                     # pinned versions, managed by nix
└── modules/                       # every .nix here is loaded by import-tree
    ├── parts.nix                  # supported systems (x86_64-linux, …)
    ├── features/
    │   ├── claude.nix             # flake.nixosModules.claude
    │   └── spicetify.nix          # flake.nixosModules.spicetify
    └── hosts/myMachine/
        ├── default.nix            # flake.nixosConfigurations.myMachine
        ├── configuration.nix      # imports features + system settings
        └── hardware-configuration.nix
```

**Where inputs go:** inside `inputs = { … };` in `flake.nix`, one line each:

```
spicetify-nix.url = "github:Gerg-L/spicetify-nix";
```

**Where outputs go:** leave this line in `flake.nix` as it is. It hands the whole `modules/` folder to flake-parts:

```
outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
```

### Adding a new feature

1. Add the input to `flake.nix` if the feature comes from another flake.
2. Create `modules/features/<name>.nix` from this template:

   ```
   {self, inputs, ...}: {
   
     flake.nixosModules.<name> = { pkgs, ... }: {
   
       imports = [ inputs.<input>.nixosModules.default ];   # only if the flake ships a module
   
       environment.systemPackages = [ pkgs.<package> ];
   
     };
   
   }
   ```
3. Add `self.nixosModules.<name>` to `imports` in `hosts/myMachine/configuration.nix`.
4. `git add modules/features/<name>.nix`, otherwise Nix can't see the file.
5. Test-build, then `sudo nixos-rebuild boot` (or `switch`).

In module files, `inputs.<name>` reaches any flake input and `self.nixosModules.<name>` reaches any other module. To use an input's package, write `inputs.<name>.packages.${pkgs.stdenv.hostPlatform.system}.<package>`.

## Git

The everyday loop is status, add, commit, push. Run it from inside `~/.nixsysconf` (`cd ~/.nixsysconf` first). Commit after every rebuild that boots fine, so you always have a known-good version to return to.

1. `git status` to see what changed and which files are untracked.
2. `git diff` to see the exact line changes (`q` quits).
3. `git add <file>`, or `git add -A` for everything.
4. `git commit -m "Add spicetify"`
5. `git push`, which only works once a remote is set up (below).

| Command | What it does |
| --- | --- |
| `git log --oneline` | Lists your commits, newest first. |
| `git restore <file>` | Throws away uncommitted changes to one file. |
| `git restore --staged <file>` | Un-adds a file but keeps your changes. |
| `git commit --amend` | Fixes the last commit's message or adds forgotten files to it. Only before you push. |
| `git checkout <commit> -- <file>` | Brings one file back as it was in an older commit. |
| `git pull` | Fetches and merges changes from the remote, for example from another machine. |
| `git remote -v` | Shows where `push` goes. |

### Setting up push (one time)

Your repo has no remote yet, so `git push` has nowhere to go. With the GitHub CLI you already have installed:

```
gh auth login                       # once, sign in to GitHub
gh repo create nixsysconf --private --source ~/.nixsysconf --push
```

After that, a plain `git push` works. Keep the repo **private** and never commit passwords or secrets: everything in it is readable by whoever can see the repo.

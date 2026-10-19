{self, inputs, ...}: {

  # Emacs (pgtk, for Wayland) with Markdown rendering: headings, tables, bold/code and
  # syntax-highlighted code blocks. The settings live in default.el, which Emacs loads
  # after the user's own init file, so ~/.config/emacs stays untouched.
  flake.nixosModules.emacs = { pkgs, ... }: let

    defaultEl = pkgs.writeText "default.el" ''
      ;;; default.el --- from ~/.nixsysconf/modules/features/emacs.nix  -*- lexical-binding: t -*-

      (require 'markdown-mode)

      ;; GitHub-flavoured Markdown (tables, ``` code blocks) for every .md file
      (add-to-list 'auto-mode-alist '("\\.md\\'" . gfm-mode))
      ;; Cheatsheets open read-only with the markup hidden ("e" to edit, see below)
      (add-to-list 'auto-mode-alist '("/Cheatsheets/.*\\.md\\'" . gfm-view-mode))

      (setopt markdown-header-scaling t                   ; bigger headings
              markdown-fontify-code-blocks-natively t)    ; highlight ```nix, ```sh, ...

      (defun my/markdown-align-tables ()
        "Line up every table in the buffer, without marking it as changed."
        (let ((inhibit-read-only t)
              (modified (buffer-modified-p)))
          ;; Mark the code blocks first, so a "|" in a shell command isn't taken for a table
          (syntax-propertize (point-max))
          (save-excursion
            (goto-char (point-min))
            (while (re-search-forward markdown-table-line-regexp nil t)
              (when (markdown-table-at-point-p)
                (markdown-table-align)
                (goto-char (markdown-table-end)))))
          (set-buffer-modified-p modified)))

      (add-hook 'markdown-view-mode-hook #'my/markdown-align-tables)
      (add-hook 'markdown-view-mode-hook #'visual-line-mode)
      (add-hook 'markdown-mode-hook #'visual-line-mode)

      ;; In the read-only view: "e" switches to editing
      (keymap-set gfm-view-mode-map "e" #'gfm-mode)
    '';

    emacs = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages (epkgs: [
      epkgs.markdown-mode
      epkgs.nix-mode    # highlighting for ```nix blocks (and .nix files)
      epkgs.fish-mode   # ... ```fish blocks
      (epkgs.trivialBuild {
        pname = "default";
        version = "1";
        src = defaultEl;
        packageRequires = [ epkgs.markdown-mode ];
      })
    ]);

  in {

    environment.systemPackages = [ emacs ];

  };

}

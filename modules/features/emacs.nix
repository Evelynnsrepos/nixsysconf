{self, inputs, ...}: {

  # Emacs (pgtk, for Wayland) with Markdown support: .md files get gfm-mode, and
  # ~/Cheatsheets open as a rendered page (real table boxes, highlighted code blocks).
  # The settings live in default.el, which Emacs loads after the user's own init file,
  # so ~/.emacs.d stays untouched.
  flake.nixosModules.emacs = { pkgs, ... }: let

    defaultEl = pkgs.writeText "default.el" ''
      ;;; default.el --- from ~/.nixsysconf/modules/features/emacs.nix  -*- lexical-binding: t -*-

      (require 'markdown-mode)
      (require 'shr)

      ;; GitHub-flavoured Markdown (tables, ``` code blocks) for every .md file
      (add-to-list 'auto-mode-alist '("\\.md\\'" . gfm-mode))
      ;; Cheatsheets open as a rendered page instead ("e" to edit, see below)
      (add-to-list 'auto-mode-alist '("/Cheatsheets/.*\\.md\\'" . my/markdown-page-mode))

      (setopt markdown-header-scaling t                   ; bigger headings
              markdown-fontify-code-blocks-natively t)    ; highlight ```nix, ```sh, ...
      (add-hook 'markdown-mode-hook #'visual-line-mode)

      ;;; Rendered page: pandoc turns the Markdown into HTML, Emacs' own HTML renderer
      ;;; (shr, as in eww) draws it. Gives real table boxes with wrapping cells.

      (defun my/markdown-page--flatten (dom)
        "Drop thead/tbody/colgroup; shr draws thead and tbody as nested tables (double borders)."
        (if (not (consp dom))
            dom
          `(,(dom-tag dom) ,(dom-attributes dom)
            ,@(mapcan (lambda (c)
                        (pcase (and (consp c) (dom-tag c))
                          ('colgroup nil)
                          ((or 'thead 'tbody 'tfoot) (mapcar #'my/markdown-page--flatten (dom-children c)))
                          (_ (list (my/markdown-page--flatten c)))))
                      (dom-children dom)))))

      (defun my/markdown-page--tag-pre (dom)
        "Code block, highlighted like in markdown-mode (```nix uses nix-mode, ...)."
        (let* ((lang (car (split-string (or (dom-attr dom 'class) ""))))
               (mode (and lang (markdown-get-lang-mode lang)))
               (code (dom-texts dom ""))
               (start (progn (shr-ensure-paragraph) (point))))
          (insert (if (fboundp mode)
                      (with-temp-buffer
                        (insert code)
                        (delay-mode-hooks (funcall mode))
                        (font-lock-ensure)
                        (buffer-string))
                    code))
          (unless (bolp) (insert "\n"))
          (add-face-text-property start (point) 'markdown-code-face t)
          (shr-ensure-paragraph)))

      (defvar-local my/markdown-page--width nil)

      (defun my/markdown-page-render (&optional window)
        "Render the visited Markdown file into this buffer, as wide as WINDOW."
        (let* ((window (or window (get-buffer-window nil t) (selected-window)))
               (width (window-body-width window))
               (file buffer-file-name)
               (dom (with-temp-buffer
                      (let ((coding-system-for-read 'utf-8)
                            (coding-system-for-write 'utf-8))
                        (insert-file-contents file)
                        (call-process-region (point-min) (point-max) "${pkgs.pandoc}/bin/pandoc"
                                             t t nil "-f" "gfm" "-t" "html" "--no-highlight"))
                      (libxml-parse-html-region (point-min) (point-max))))
               (shr-width (- width 2))
               (shr-use-fonts t)
               (shr-table-vertical-line ?│)
               (shr-table-horizontal-line ?─)
               (shr-table-corner ?┼)
               (shr-hr-line ?─)
               (shr-external-rendering-functions '((pre . my/markdown-page--tag-pre)))
               (inhibit-read-only t)
               (pos (point)))
          (erase-buffer)
          (shr-insert-document (my/markdown-page--flatten dom))
          (goto-char (min pos (point-max)))
          (set-buffer-modified-p nil)
          (setq my/markdown-page--width width)))

      (defun my/markdown-page--rerender (window)
        "Render again when the window showing the page gets a different width."
        (with-current-buffer (window-buffer window)
          (unless (eql (window-body-width window) my/markdown-page--width)
            (my/markdown-page-render window))))

      (defun my/markdown-page-edit ()
        "Leave the rendered page: show the Markdown text for editing."
        (interactive)
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert-file-contents buffer-file-name)
          (set-buffer-modified-p nil))
        (gfm-mode))

      (define-derived-mode my/markdown-page-mode special-mode "MD-Page"
        "A Markdown file shown as a rendered page.  e: edit,  g: render again."
        (setq-local buffer-undo-list t
                    ;; g, and auto-revert when the file changes on disk
                    revert-buffer-function (lambda (&rest _) (my/markdown-page-render)))
        ;; The buffer holds the rendered text: never save that over the file
        (add-hook 'write-contents-functions
                  (lambda () (user-error "This is the rendered page; press e to edit")) nil t)
        (dolist (n '(1 2 3 4 5 6))
          (face-remap-add-relative (intern (format "shr-h%d" n))
                                   (intern (format "markdown-header-face-%d" n))))
        (face-remap-add-relative 'shr-code 'markdown-inline-code-face)
        (add-hook 'window-size-change-functions #'my/markdown-page--rerender nil t)
        (add-hook 'window-buffer-change-functions #'my/markdown-page--rerender nil t)
        (my/markdown-page-render))

      (keymap-set my/markdown-page-mode-map "e" #'my/markdown-page-edit)
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

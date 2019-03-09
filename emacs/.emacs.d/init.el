;;; init.el --- Initialisation for emacs
;;; Commentary:
;; My configuration
;;; Code:

;;;; Basics

(setq user-full-name    "Michael Walker"
      user-mail-address "mike@barrucadu.co.uk")

;;; Package management
(package-initialize)

(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

(setq package-enable-at-startup nil
      use-package-always-ensure t)

;;; Better defaults
(tool-bar-mode 0)
(menu-bar-mode 0)
(blink-cursor-mode -1)
(global-hl-line-mode 1)
(show-paren-mode 1)
(electric-indent-mode 0)

(when (display-graphic-p)
  (set-scroll-bar-mode nil))

(setq ring-bell-function 'ignore
      inhibit-splash-screen t
      show-paren-delay 0
      make-backup-files nil
      kill-whole-line t
      require-final-newline t
      uniquify-buffer-name-style 'forward
      initial-major-mode 'org-mode
      vc-follow-symlinks t)

(setq-default indent-tabs-mode nil
              tab-width 8)

(defalias 'yes-or-no-p 'y-or-n-p)

;;; Utility functions used later
(defun barrucadu/switch-to-prev-buffer ()
  "Switch to the last-used buffer.
Unlike 'switch-to-prev-buffer', performing this function twice gets you back to the same buffer."
  (interactive)
  (switch-to-buffer (other-buffer)))


;;;; Appearance

(use-package color-theme)
(use-package gruvbox-theme
  :init (load-theme 'gruvbox 'no-confirm))

(use-package beacon
  :init    (beacon-mode 1)
  :diminish beacon-mode)

(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (conf-mode . rainbow-delimiters-mode)))


;;;; Keybindings

(use-package evil
  :ensure t
  :config
  (evil-mode 1)
  (defalias 'evil-insert-state 'evil-emacs-state)
  (setq evil-want-visual-char-semi-exclusive t
        evil-emacs-state-cursor  '("red" box)
        evil-normal-state-cursor '("green" box)
        evil-visual-state-cursor '("orange" box))
  (setq-default evil-cross-lines t)
  :hook
  (git-commit-mode . evil-emacs-state))

(use-package which-key
  :init    (which-key-mode)
  :diminish which-key-mode
  :config
  (which-key-setup-side-window-right-bottom)
  (setq which-key-sort-order 'which-key-key-order-alpha
        which-key-side-window-max-width 0.33
        which-key-idle-delay 0.05))

(defconst *top-level-leader*  "C-c")
(defconst *major-mode-leader* "C-c m")

(use-package general
  :config
  (general-evil-setup t)
  ;; Leaders
  (general-create-definer bind-in-top-level
    :prefix *top-level-leader*)
  (general-create-definer bind-in-major-mode
    :prefix *major-mode-leader*)
  (bind-in-top-level
    ;; Prefixes
    "!"   '(nil :which-key "fly{check,spell} prefix")
    "! t" '(nil :which-key "toggle")
    "b"   '(nil :which-key "buffers prefix")
    "c"   '(nil :which-key "comments prefix")
    "f"   '(nil :which-key "files prefix")
    "g"   '(nil :which-key "git prefix")
    "m"   '(nil :which-key "major mode prefix")
    "s"   '(nil :which-key "search prefix")
    "w"   '(nil :which-key "whitespace prefix")
    ;; Keys
    "b x" 'barrucadu/switch-to-prev-buffer
    "c d" 'comment-dwim
    "c l" 'comment-line
    "c r" 'comment-region
    "s f" 'isearch-forward-regexp
    "s b" 'isearch-backward-regexp
    "w d" 'delete-horizontal-space
    "G"   'goto-line))


;;;; Main configuration

;;; org-mode
(add-hook 'org-mode-hook 'org-indent-mode)
(add-hook 'org-mode-hook 'visual-line-mode)

(setq org-src-tab-acts-natively t
      org-src-fontify-natively  t)

;;; flycheck / flyspell
(use-package flycheck
  :init (global-flycheck-mode)
  :general
  (bind-in-top-level
    "! t c" 'flycheck-mode))

(use-package flyspell
  :diminish flyspell-mode
  :general
  (bind-in-top-level
   "! t s" 'flyspell-mode
   "! w" 'flyspell-correct-word-before-point)
  :hook
  ((text-mode  . flyspell-mode)
   (prog-mode  . flyspell-prog-mode)
   (org-mode   . flyspell-mode)
   (LaTeX-mode . flyspell-mode))
  :config
  (setq flyspell-use-meta-tab nil
        flyspell-issue-welcome-flag nil
        flyspell-issue-message-flag nil)
  (define-key flyspell-mode-map (kbd "C-c $") nil)
  (define-key flyspell-mode-map (kbd "M-t") nil)
  (define-key flyspell-mouse-map [down-mouse-2] nil)
  (define-key flyspell-mouse-map [mouse-2] nil))

(use-package ispell
  :defer t
  :config
  (setq ispell-program-name   (executable-find "aspell")
        ispell-dictionary     "en_GB"
        ispell-silently-savep t))

(flycheck-define-checker proselint
  "A linter for prose."
  :command ("proselint" source-inplace)
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ": "
            (id (one-or-more (not (any " "))))
            (message (one-or-more not-newline)
                     (zero-or-more "\n" (any " ") (one-or-more not-newline)))
            line-end))
  :modes (text-mode markdown-mode latex-mode rst-mode))

(add-to-list 'flycheck-checkers 'proselint t)
(flycheck-add-next-checker 'tex-chktex  'proselint t)
(flycheck-add-next-checker 'tex-lacheck 'proselint t)

(use-package flycheck-vale
  :after flycheck
  :hook (flycheck-mode . flycheck-vale-setup)
  :config
  (flycheck-add-next-checker 'proselint 'vale t)
  (flycheck-add-mode 'vale 'latex-mode))

;;; Accounting
(use-package flycheck-ledger)
(use-package ledger-mode
  :mode "\\.ledger\\'\\|\\.journal\\'"
  :config
  (setq ledger-binary-path                 (executable-find "hledger")
        ledger-mode-should-check-version    nil
        ledger-init-file-name               " "
        ledger-post-amount-alignment-column 80
        ledger-highlight-xact-under-point   nil))

;;; Programming

;; Elixir
(use-package elixir-mode
  :mode "\\.ex\\'\\|\\.exs\\'")

;; Forth
(use-package forth-mode
  :mode "\\.fs\\'")

;; Haskell
(use-package haskell-mode
  :mode "\\.hs\\'"
  :general
  (bind-in-major-mode
   :major-modes t
   :keymaps 'haskell-mode-map
   "i"   '(nil :which-key "imports")
   "i j" 'haskell-navigate-imports
   "i s" 'haskell-sort-imports
   "i a" 'haskell-align-imports))

(use-package haskell-cabal-mode
  :mode "\\.cabal\\'"
  :ensure haskell-mode)

;; JSON
(use-package json-mode
  :mode "\\.json\\'"
  :hook
  (json-mode . (lambda () (setq-local js-indent-level 4))))

;; Python
(use-package python
  :mode ("``.py``'" . python-mode))

;; Go
(use-package go-mode
  :mode "\\.go\\'"
  :commands (godoc gofmt gofmt-before-save)
  :general
  (bind-in-major-mode
   :major-modes t
   :keymaps 'go-mode-map
   "f" 'gofmt
   "i" 'go-goto-imports
   "r" 'go-remove-unused-imports)
  :hook
  (before-save . (lambda ()
                   (when (eq major-mode 'go-mode)
                     (gofmt-before-save)))))

;; Groovy
(use-package groovy-mode
  :mode "\\.groovy\\'")

;; Lua
(use-package lua-mode
  :mode "\\.lua\\'")

;; Nix
(use-package nix-mode
  :mode "\\.nix\\'")

;; Puppet
(use-package puppet-mode
  :mode "\\.pp\\'")

;; Rust
(use-package rust-mode
  :mode "\\.rs\\'"
  :config
  (setq rust-format-on-save t))

(use-package flycheck-rust
  :hook (flycheck-mode . flycheck-rust-setup))

;; Ruby
(setq ruby-insert-encoding-magic-comment nil)

;; Scala
(use-package scala-mode
  :mode "\\.scala\\'")

;; Shell
(use-package sh-script
  :mode ("\\.zsh\\'" . sh-mode)
  :config
  (setq sh-basic-offset 2))

;; Terraform
(use-package terraform-mode
  :mode ("\\.tf``'" . terraform-mode))

;; TOML
(use-package toml-mode
  :mode ("\\.toml``'" . toml-mode))

;; Typescript
(use-package typescript-mode
  :mode ("\\.ts\\'" "\\.tsx\\'"))

;; YAML
(use-package yaml-mode
  :mode "\\.yaml\\'"
  :hook (yaml-mode . (lambda () (run-hooks 'prog-mode-hook))))

;;; Writing
(use-package markdown-mode
  :mode "\\.md\\'\\|\\.markdown\\'")

;; LaTeX
(setq TeX-parse-self t
      TeX-electric-sub-and-superscript t
      TeX-master 'dwim
      bibtex-entry-format `(opts-or-alts numerical-fields page-dashes last-comma delimiters unify-case sort-fields)
      bibtex-entry-delimiters 'braces
      bibtex-field-delimiters 'double-quotes
      bibtex-comma-after-last-field nil)

(defvar barrucadu/bibtex-fields-ignore-list
  '("abstract" "acmid" "address" "annotation" "articleno" "eprint"
    "file" "isbn" "issn" "issue_date" "keywords" "language" "location"
    "month" "numpages" "url"))

(defun barrucadu/bibtex-clean-entry-drop-fields ()
  (save-excursion
    (let (bounds)
      (when (looking-at bibtex-entry-maybe-empty-head)
        (goto-char (match-end 0))
        (while (setq bounds (bibtex-parse-field))
          (goto-char (bibtex-start-of-field bounds))
          (if (member (bibtex-name-in-field bounds)
                      barrucadu/bibtex-fields-ignore-list)
              (kill-region (caar bounds) (nth 3 bounds))
            (goto-char (bibtex-end-of-field bounds))))))))

(defun barrucadu/bibtex-clean-entry-newline ()
  (save-excursion
    (progn (bibtex-end-of-entry) (left-char) (newline))))

(add-hook 'bibtex-clean-entry-hook 'barrucadu/bibtex-clean-entry-newline)
(add-hook 'bibtex-clean-entry-hook 'barrucadu/bibtex-clean-entry-drop-fields)

;;; Version control
(use-package diff-hl
  :init
  (global-diff-hl-mode)
  (unless (display-graphic-p) (diff-hl-margin-mode))
  :hook
  ((dired-mode . diff-hl-dired-mode)
   (magit-post-refresh . diff-hl-magit-post-refresh)))

(use-package magit
  :general
  (bind-in-top-level
   "g c" 'magit-clone
   "g s" 'magit-status
   "g b" 'magit-blame
   "g l" 'magit-log-buffer-line
   "g p" 'magit-pull)
  :init
  (setq magit-save-repository-buffers 'dontask
        magit-refs-show-commit-count 'all
        magit-revision-show-gravatars nil
        magit-repository-directories `(("~" . 2))
        magit-repolist-columns
        '(("Name"    25 magit-repolist-column-ident                  ())
          ("Version" 25 magit-repolist-column-version                ())
          ("Dirty"    1 magit-repolist-column-dirty                  ())
          ("Unpulled" 3 magit-repolist-column-unpulled-from-upstream ((:right-align t)))
          ("Unpushed" 3 magit-repolist-column-unpushed-to-upstream   ((:right-align t)))
          ("Path"    99 magit-repolist-column-path                   ())))
  :config
  (define-key magit-file-mode-map (kbd "C-c M-g") nil))

(use-package evil-magit
  :after magit)

(use-package git-timemachine
  :general
  (bind-in-top-level
   "g t" 'git-timemachine)
  :config
  (evil-make-overriding-map git-timemachine-mode-map 'normal)
  (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))


;;;; Miscellaneous

;;; Whitespace
(use-package whitespace-cleanup-mode
  :diminish (whitespace-cleanup-mode . " [W]")
  :general
  (bind-in-top-level
   "w b" 'whitespace-cleanup
   "w r" 'whitespace-cleanup-region)
  :hook
  ((prog-mode . whitespace-cleanup-mode)
   (text-mode . whitespace-cleanup-mode)
   (conf-mode . whitespace-cleanup-mode)))

(use-package whitespace
  :diminish whitespace-mode
  :general
  (bind-in-top-level
   "w m" 'whitespace-mode)
  :config (setq whitespace-line-column nil))

;;; Searching and replacing
(use-package helm-ag
  :general
  (bind-in-top-level
    "g f" 'helm-do-ag-project-root
    "s a" 'helm-do-ag
    "s b" 'helm-do-ag-buffers))

(use-package visual-regexp
  :general
  (bind-in-top-level
   "s r" 'vr/query-replace
   "s R" 'vr/replace))

;;; Helm
(use-package helm
  :bind ("M-x" . helm-M-x)
  :init (helm-mode 1)
  :diminish helm-mode)

(use-package helm-buffers
  :ensure helm
  :general
  (general-define-key
   [remap switch-to-buffer] 'helm-mini)
  (bind-in-top-level
    "b b" 'helm-mini)
  :config (setq helm-buffers-fuzzy-matching t))

(use-package helm-files
  :ensure helm
  :general
  (general-define-key
   [remap find-file] 'helm-find-files)
  (bind-in-top-level
   "f f" 'helm-for-files
   "f r" 'helm-recentf)
  :config
  (setq helm-recentf-fuzzy-match t
        helm-ff-file-name-history-use-recentf t
        helm-ff-search-library-in-sexp t))

;;; Projectile
(use-package projectile
  :init (projectile-mode)
  :config
  (setq projectile-completion-system 'helm))

(use-package helm-projectile
  :after projectile
  :general
  (bind-in-top-level
   "f p" 'helm-projectile)
  :config
  (helm-projectile-on)
  (setq projectile-switch-project-action 'helm-projectile))


;;;; Customisation

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; Local Variables:
;; byte-compile-warnings: (not free-vars)
;; End:

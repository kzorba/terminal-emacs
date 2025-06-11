;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Kostas Zorbadelos"
      user-mail-address "kzorba@nixly.net")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-font (font-spec :family "FiraCode Nerd Font Mono" :size 15 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font Mono" :size 15))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; Some dark themes doom-one was default
                                        ;(setq doom-theme 'doom-one)
(setq doom-theme 'doom-nord)
                                        ;(setq doom-theme 'doom-nova)
                                        ;(setq doom-theme 'doom-badger)
                                        ;(setq doom-theme 'doom-xcode)
;; Some white themes
                                        ;(setq doom-theme 'adwaita)
                                        ;(setq doom-theme 'tango)
                                        ;(setq doom-theme 'whiteboard)


;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;;
;; kzorba config
;;

;; properly set greek font in MacOS
(add-hook! 'after-setting-font-hook :append
           ;;(set-fontset-font t 'greek (font-spec :family "Monaco" :weight 'semi-light :size 14))
           (set-fontset-font t 'greek (font-spec :family "FiraCode Nerd Font Mono")))

;; remap meta to Apple command key
(setq mac-command-modifier 'meta)
;; remap super to Apple option key
(setq mac-option-modifier 'super)

;; org-mode related

(after! org
  ;; org files for agenda feed
  (setq org-agenda-files '("~/org/Tasks.org"
                           "~/org/CalEvents.org"
                           "~/org/Archive"))
  ;; target files for refile command
  (setq org-refile-targets
        '((nil :maxlevel . 3)
          ("~/org/Tasks.org" :tag . "INBOX")
                                        ; ("~/org/Archive/2023.org" :maxlevel . 1)
                                        ; ("~/org/Archive/2024.org" :maxlevel . 1)
          ("~/org/Archive/2025.org" :maxlevel . 1)
          ))
  ;; org default notes file (fallback for org-capture.el
  (setq org-default-notes-file "~/org/Notes.org")
  ;; store new notes at the beginning of a file or entry
  (setq org-reverse-note-order t)
  ;; Save Org buffers after refiling!
  ;; Does not work when we do org-agenda-refile, so save buffers manually for now
                                        ;(advice-add 'org-refile :after 'org-save-all-org-buffers)
  ;; display log in agenda
  (setq org-agenda-start-with-log-mode t)
  ;; when a task is DONE log time
  (setq org-log-done 'time)
  ;; The `text-scale-amount' for `org-tree-slide-mode'
  (setq +org-present-text-scale 2)
  ;; our capture templates
  (setq org-capture-templates
        '(("n" "Add notes")
          ("nl" "Item with WWW link" entry
           (file "~/org/Notes.org")
           "* To read: [[%?]]  :reading:\nCaptured date: %T\nDescription: %^{Description|An interesting read}"
           :prepend t :empty-lines-after 1)
          ("ni" "An idea" entry
           (file "~/org/Notes.org")
           "* %^{Title|IDEA}  :idea:\nCaptured date: %T\n%?" :prepend t :empty-lines-after 1)
          ("no" "Other item" entry
           (file "~/org/Notes.org")
           "* %^{Title}\nCaptured date: %T\n%?" :prepend t :empty-lines-after 1))
        )
  ;; Display timezone information in timestamps. This only affects timestamp display,
  ;; it does not add calculations or proper timezone support in agenda.
  (setq org-time-stamp-formats '("<%Y-%m-%d %a>" . "<%Y-%m-%d %a %H:%M %Z>"))
  )

;; Default values for various variables
(setq default-frame-alist '((width . 110)
                            (height . 48)) ; frame width, height
                                        ; search path for projects by projectile
      projectile-project-search-path '("~/WorkingArea")
                                        ; disable variable-pitch font in treemacs
      doom-themes-treemacs-enable-variable-pitch nil)
;; printer for emacs Generic-PDF (define it in cups)
(setq printer-name "Generic-PDF")
;; set web browser to chromium
;; use htmlfontify-buffer to print nicely via chromium
                                        ;(setq browse-url-browser-function 'browse-url-chromium)

;; Switched to zsh to have the same for macOS
(setq vterm-shell "/bin/zsh")

;; Customize indent for json-mode
(add-hook 'json-mode-hook
          (lambda ()
            (make-local-variable 'js-indent-level)
            (setq js-indent-level 4)))

;; Disable format-on-save behavior in Markdown buffers
(setq-hook! 'gfm-mode-hook +format-inhibit t)

;; https://www.gnu.org/software/emacs/manual/html_node/epa/GnuPG-Pinentry.html
(setq epg-pinentry-mode 'loopback)

;; Python stuff
;;
;; Configure apheleia to run the ruff-isort formatter followed by the ruff
;; formatter.
;; Replace default (black) to use ruff for sorting import and formatting.
(setq-hook! 'python-mode-hook +format-with '(ruff-isort ruff))
(setq-hook! 'python-ts-mode-hook +format-with '(ruff-isort ruff))

;; Use basedpyright if available as a lang server and
;; avoid using ruff (in lsp-mode).
;; If basedpyright is missing and pyright is available we use that.
(after! lsp-mode
  (when (executable-find "basedpyright")
    (setq lsp-pyright-langserver-command "basedpyright"))
  (setq lsp-disabled-clients '(ruff)))

;; Disable Dockerfile formatting
(after! dockerfile-mode
  (set-formatter! 'dockfmt nil))

;; c-x-c-c in daemon mode
;; using an argument (c-u) kills also the daemon saving buffers
(defun kzorba/emacsclient-c-x-c-c (&optional arg)
  "If running in emacsclient, make C-x C-c exit frame, and C-u C-x C-c exit Emacs."
  (interactive "P") ; prefix arg in raw form
  (if arg
      (save-buffers-kill-emacs)
    (save-buffers-kill-terminal)))

(if (daemonp)
    (global-set-key (kbd "C-x C-c") #'kzorba/emacsclient-c-x-c-c))

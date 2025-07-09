;;; kiss-menu.el --- Show a menu of installed KISS packages -*- lexical-binding: t -*-

;; Author: phoebos
;; Version: 0.2

;;; Commentary:

;; This code uses `tabulated-list-mode' to display a list of the installed
;; packages on a KISS system.  It shows the package name, installed version, and
;; if an update is available.  Packages can be marked, so the list of marked
;; packages might be used in a `kiss' command.

;; This code is mostly copied from `Buffer-menu-mode'.

;;; Code:

(require 'tabulated-list)
(require 'kiss)

;;(defgroup kiss-menu nil
;;  "Show a menu of all installed packages."
;;  :group 'kiss
;;  :prefix "kiss-menu-")

(defvar kiss-menu-marker "#"
  "The mark string (one character) for marked packages.")

(defvar-keymap kiss-menu-mode-map
  :doc "Local keymap for `kiss-menu-mode' buffers."
  :parent tabulated-list-mode-map
  "m" #'kiss-menu-mark
  "u" #'kiss-menu-unmark
  "U" #'kiss-menu-unmark-all)

(define-derived-mode kiss-menu-mode tabulated-list-mode "Kiss Menu"
  "Major mode for Kiss Menu buffers.
Invoke with \\[kiss-menu]."
  ;; :group 'kiss-menu
  (add-hook 'tabulated-list-revert-hook 'kiss-menu--refresh nil t))

(defun kiss-menu ()
  "Switch to the Kiss Menu.

Displays a list of the installed packages on a KISS system.
It shows the package name, installed version, and if an update is
available (\"U\" column).

The following commands are defined:
\\<kiss-menu-mode-map>
\\[kiss-menu-mark]    Mark packages
\\[kiss-menu-unmark]    Unmark packages
\\[kiss-menu-unmark-all]    Unmark all packages

Other commands are inherited from `tabulated-list-mode'."
  (interactive)
  (switch-to-buffer (kiss-menu-list)))

(defun list-kiss-packages ()
  "Switch to the Kiss Menu of installed packages.

Refer to `kiss-menu' for more details."
  (interactive)
  (switch-to-buffer (kiss-menu-list)))

(defun kiss-menu-list ()
  "Create and return a kiss menu buffer."
  (let ((buffer (get-buffer-create "*Kiss Menu*")))
    (with-current-buffer buffer
      (kiss-menu-mode)
      (kiss-menu--refresh)
      (tabulated-list-print))
    buffer))

;;(defun kiss-menu-toplevel ()
;;  ;; TODO: reset sort
;;  (interactive)
;;  (let ((buffer (get-buffer-create "*Kiss Menu*"))
;;	(entries `((i ["Installed" ,(number-to-string (length (kiss-list)))])
;;		   (a ["All" "0"]))))
;;    (with-current-buffer buffer
;;      (tabulated-list-mode)
;;      (setq tabulated-list-format
;;	    (vector
;;	     '("Package lists" 13 t)
;;	     '("Total" 4 sort-numerical-strings-col-1 :right-align t)))
;;      (setq tabulated-list-use-header-line t)
;;      (setq tabulated-list-entries entries)
;;      (tabulated-list-init-header))
;;    (tabulated-list-print)
;;    (switch-to-buffer buffer)))
;;
;;(defun sort-numerical-strings-col-1 (a b)
;;  (< (string-to-number (aref (cadr a) 1))
;;     (string-to-number (aref (cadr b) 1))))

(defun kiss-menu--refresh ()
  "Load the menu of KISS packages."
  (message "kiss-menu: listing installed packages...")
  (let ((pkgs (kiss-list))
	(plen 0)
	(vlen 0)
	maxvp
	entries)
    (dolist (pv pkgs)
      (let ((p (car pv))
	    (v (cadr pv)))
	(if (> (length v) vlen)
	    (setq maxvp pv))
	(setq plen (max (length p) plen))
	(setq vlen (max (length v) vlen))
	(setq update-char (if (kiss--pkg-remote-eq-pkg-local-p p) "" "*"))
	(push
	 (list p
	       (vector ""
		       update-char
		       (list p)
		       v))
	 entries)))
    (setq plen (max plen (- (window-max-chars-per-line) 1 2 1 vlen)))
    (message "kiss-menu: found %d packages" (length pkgs))
    (setq tabulated-list-format
	  (vector
	   ;; NAME WIDTH SORT . PROPS
	   '(nil 1 t :pad-right 0)
	   '("U" 1 t)
	   `("Package" ,plen t)
	   `("Version" ,vlen t)))
    (setq tabulated-list-use-header-line t)
    (setq tabulated-list-entries (nreverse entries))
    (tabulated-list-init-header)))

(defun kiss-menu-mark ()
  "Mark the current package."
  (interactive nil kiss-menu-mode)
  (tabulated-list-set-col 0 kiss-menu-marker t)
  (forward-line))

(defun kiss-menu-unmark ()
  "Unmark the current package."
  (interactive nil kiss-menu-mode)
  (tabulated-list-set-col 0 "" t)
  (forward-line))

(defun kiss-menu-unmark-all ()
  "Unmark all packages."
  (interactive nil kiss-menu-mode)
  (save-excursion
    (kiss-menu-beginning)
    (while (not (eobp))
      (kiss-menu-unmark))))

(defun kiss-menu-beginning ()
  "Go to the beginning of the package list."
  (goto-char (point-min))
  (when (tabulated-list-header-overlay-p)
    (forward-line)))

(defun kiss-menu-pkg ()
  "Return the package name of the current line."
  (tabulated-list-get-id))

(defun kiss-menu-marked-pkgs ()
  "Return the list of packages marked with `kiss-menu-mark'.
For example, to be used for (`kiss-remove' (kiss-menu-marked-pkgs))."
  (let (pkgs)
    (kiss-menu-beginning)
    (while (re-search-forward (concat "^" kiss-menu-marker) nil t)
      (push (kiss-menu-pkg) pkgs))
    (nreverse pkgs)))

(provide 'kiss-menu)
;;; kiss-menu.el ends here.

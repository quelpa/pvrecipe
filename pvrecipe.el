;;; pvrecipe.el --- Translate MELPA recipes to package-vc specifications -*- lexical-binding: t; -*-

;; Author: Reto Hubmann (@steckerhalter)
;; Version: 0.1
;; Package-Origin: (pvrecipe :url "https://github.com/quelpa/pvrecipe")
;; URL: https://github.com/quelpa/pvrecipe

;;; Commentary:

;; Fetch MELPA recipes over HTTP from the MELPA repository on GitHub
;; (https://raw.githubusercontent.com/melpa/melpa/master/recipes/) and
;; translate them into `package-vc-install' specifications.  Example:
;;
;;     (pvrecipe 'magit)  =>  (magit :url "https://github.com/magit/magit" :lisp-dir "lisp")

;;; Code:

(require 'package)
(require 'package-vc)

(defgroup pvrecipe nil
  "Translate MELPA recipes to package-vc specifications."
  :group 'package
  :prefix "pvrecipe-")

(defcustom pvrecipe-base-url
  "https://raw.githubusercontent.com/melpa/melpa/master/recipes/"
  "Base URL of the MELPA recipe directory on GitHub."
  :type 'string
  :group 'pvrecipe)

(defun pvrecipe--fetch (name)
  "Fetch the MELPA recipe for package NAME.
The recipe file is fetched via HTTP from the MELPA repository on
GitHub.  Return the recipe as a list, or nil when it can't be fetched."
  (condition-case nil
      (with-temp-buffer
        (url-insert-file-contents (concat pvrecipe-base-url (symbol-name name)))
        (goto-char (point-min))
        (when-let* ((recipe (read (current-buffer))))
          (when (listp recipe)
            recipe)))
    (error nil)))

(defconst pvrecipe--translatable-keys
  '(:fetcher :repo :url :branch :lisp-dir :ignored-files
    :main-file :doc :make :shell-command :vc-backend)
  "Recipe keys that `pvrecipe--translate' can pass on to package-vc.")

(defun pvrecipe--keys (plist)
  "Return the keys of the plist PLIST."
  (let ((keys nil))
    (while plist
      (when (keywordp (car plist))
        (push (car plist) keys))
      (setq plist (cdr plist)))
    keys))

(defun pvrecipe--untranslatable-keys (plist)
  "Return the keys of recipe plist PLIST that `pvrecipe--translate' can't translate."
  (let ((keys (pvrecipe--keys plist))
        untranslatable)
    (dolist (key keys)
      (unless (memq key pvrecipe--translatable-keys)
        (push key untranslatable)))
    (nreverse untranslatable)))

(defun pvrecipe--derive-lisp-dir (plist)
  "Derive a package-vc `:lisp-dir' value for the recipe plist PLIST.
Scan the recipe's `:files' list for the first entry naming a Lisp
file and return its repository-relative directory; nil when there is
no such entry.  Used when the recipe has no explicit `:lisp-dir'."
  (catch 'pvrecipe--done
    (dolist (entry (plist-get plist :files))
      (when (stringp entry)
        (let ((file (replace-regexp-in-string "[*?]+\\'" "" entry)))
          (when (string-match-p "\\.el\\'" file)
            (when-let* ((dir (file-name-directory file)))
              (throw 'pvrecipe--done (directory-file-name dir)))))))))

(defun pvrecipe--translate (recipe)
  "Translate MELPA recipe RECIPE into a package-vc specification.
Return a list `(NAME ...PLIST)' suitable for `package-vc-install', or
nil when the recipe can't be translated (e.g. it has no fetcher).
Keys that have no package-vc equivalent are reported with a message
but do not prevent the translation."
  (when-let* ((recipe (and (listp recipe) recipe)))
    (let* ((name (car recipe))
           (plist (cdr recipe))
           (untranslatable (pvrecipe--untranslatable-keys plist))
           (spec (pcase (plist-get plist :fetcher)
                   ('github (when-let* ((repo (plist-get plist :repo)))
                              (list :url (concat "https://github.com/" repo))))
                   ('gitlab (when-let* ((repo (plist-get plist :repo)))
                              (list :url (concat "https://gitlab.com/" repo))))
                   ((or 'srht 'sourcehut)
                    (when-let* ((repo (plist-get plist :repo)))
                      (list :url (concat "https://git.sr.ht/" repo))))
                   (_ (when-let* ((url (plist-get plist :url)))
                        (list :url url))))))
      (when untranslatable
        (message "pvrecipe: recipe for %s has keys without a package-vc equivalent: %s"
                 name (mapconcat #'symbol-name untranslatable ", ")))
      (when spec
        (append `(,name) spec
                (mapcan
                 (lambda (key)
                   (when-let* ((value (plist-get plist key)))
                     (list key value)))
                 '(:branch :lisp-dir :ignored-files
                   :main-file :doc :make :shell-command :vc-backend))
                (when-let* ((lisp-dir (and (not (plist-get plist :lisp-dir))
                                          (pvrecipe--derive-lisp-dir plist))))
                  (list :lisp-dir lisp-dir)))))))

;;;###autoload
(defun pvrecipe (name)
  "Return a package-vc install specification for package NAME.
The MELPA recipe is fetched via HTTP from the MELPA repository on
GitHub and translated into a `package-vc-install' specification.
Return nil when the recipe can't be fetched or translated.
When called interactively with NAME read from the minibuffer, print
the resulting specification in the echo area."
  (interactive
   (list (intern (completing-read "Package recipe: "
                                  (when-let* ((url (concat pvrecipe-base-url "../"))
                                              ;; Try listing or reading if possible, or read symbol.
                                              ;; Since MELPA recipe repo doesn't have a simple directory index without HTML,
                                              ;; we can prompt for a symbol.
                                              )
                                    nil)
                                  nil nil nil nil))))
  (let ((spec (when-let* ((recipe (pvrecipe--fetch name)))
                (pvrecipe--translate recipe))))
    (if (called-interactively-p 'any)
        (if spec
            (message "%S" spec)
          (message "Could not fetch or translate recipe for %s" name))
      spec)))

(provide 'pvrecipe)
;;; pvrecipe.el ends here

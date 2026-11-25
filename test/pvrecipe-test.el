;;; pvrecipe-test.el --- Tests for pvrecipe.el -*- lexical-binding: t; -*-

;; Unit tests for `pvrecipe--translate' and `pvrecipe--derive-lisp-dir'.

(require 'ert)
(require 'pvrecipe)

;;; Unit tests

(ert-deftest pvrecipe-translate-github-recipe ()
  "A github recipe translates to a package-vc spec."
  (should (equal (pvrecipe--translate
                  '(magit :fetcher github :repo "magit/magit"))
                 '(magit :url "https://github.com/magit/magit"))))

(ert-deftest pvrecipe-translate-gitlab-recipe ()
  (should (equal (pvrecipe--translate
                  '(foo :fetcher gitlab :repo "a/foo"))
                 '(foo :url "https://gitlab.com/a/foo"))))

(ert-deftest pvrecipe-translate-srht-recipe ()
  (should (equal (pvrecipe--translate
                  '(bar :fetcher srht :repo "b/bar"))
                 '(bar :url "https://git.sr.ht/b/bar"))))

(ert-deftest pvrecipe-translate-url-passthrough ()
  (should (equal (pvrecipe--translate
                  '(baz :fetcher git :url "https://example.com/repo.git"))
                 '(baz :url "https://example.com/repo.git"))))

(ert-deftest pvrecipe-translate-passes-package-vc-keys ()
  "package-vc keys are translated as flat spec entries."
  (should (equal (pvrecipe--translate
                  '(foo :fetcher github :repo "a/foo"
                        :branch "topic" :lisp-dir "lisp"
                        :ignored-files ("skip/*.el")
                        :main-file "foo.el" :doc "doc/foo.texi"
                        :make ("all" "install") :shell-command "make docs"
                        :vc-backend git))
                 '(foo :url "https://github.com/a/foo"
                       :branch "topic" :lisp-dir "lisp"
                       :ignored-files ("skip/*.el")
                       :main-file "foo.el" :doc "doc/foo.texi"
                       :make ("all" "install") :shell-command "make docs"
                       :vc-backend git))))

(ert-deftest pvrecipe-translate-derives-lisp-dir-from-files ()
  "A :lisp-dir is derived from the :files entry naming a lisp file."
  ;; Derived when the recipe has no :lisp-dir.
  (should (equal (pvrecipe--translate
                  '(foo :fetcher github :repo "a/foo"
                        :files ("lisp/foo.el" "docs/foo.texi")))
                 '(foo :url "https://github.com/a/foo" :lisp-dir "lisp")))
  ;; An explicit :lisp-dir wins over derivation.
  (should (equal (pvrecipe--translate
                  '(foo :fetcher github :repo "a/foo"
                        :files ("src/foo.el") :lisp-dir "src/lisp"))
                 '(foo :url "https://github.com/a/foo" :lisp-dir "src/lisp")))
  ;; No derivation when :files has no lisp entries.
  (should (equal (pvrecipe--translate
                  '(foo :fetcher github :repo "a/foo"
                        :files ("docs/foo.texi" "LICENSE")))
                 '(foo :url "https://github.com/a/foo"))))

(ert-deftest pvrecipe-translate-reports-untranslatable-keys ()
  "Keys without a package-vc equivalent are reported but translation proceeds."
  (let ((messages nil))
    (cl-letf (((symbol-function #'message)
               (lambda (fmt &rest args)
                 (push (apply #'format fmt args) messages))))
      (let ((spec (pvrecipe--translate
                   '(magit :fetcher github :repo "magit/magit"
                           :files ("lisp/magit*.el" "docs/magit.texi")))))
        (should (equal spec
                       '(magit :url "https://github.com/magit/magit"
                               :lisp-dir "lisp")))
        (should (member
                 "pvrecipe: recipe for magit has keys without a package-vc equivalent: :files"
                 messages))))))

(ert-deftest pvrecipe-translate-invalid-recipes ()
  (should (null (pvrecipe--translate nil)))
  (should (null (pvrecipe--translate 42)))
  (should (null (pvrecipe--translate '(no-fetcher :repo "a/b")))))

(provide 'pvrecipe-test)
;;; pvrecipe-test.el ends here

# pvrecipe

Fetch MELPA recipes over HTTP from the MELPA repository on GitHub and
translate them into `package-vc-install` specifications.  Used by
`quelpa2` as a fallback when a dependency has no recipe in
`Package-Requires-Origins`.

Keys that package-vc supports (`:branch`, `:lisp-dir`,
`:ignored-files`, `:main-file`, `:doc`, `:make`, `:shell-command`,
`:vc-backend`, …) are translated.  When a recipe has `:files` but no
`:lisp-dir`, the lisp directory is derived from the `:files` entry
naming a Lisp file (e.g. magit's `:files` → `:lisp-dir "lisp"`).
Recipe keys without a package-vc equivalent are reported with a
message when they can't be translated.

Example:

```elisp
(require 'pvrecipe)

(pvrecipe 'magit)  ;=> (magit :url "https://github.com/magit/magit")
```

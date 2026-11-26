# pvrecipe

Fetch MELPA recipes over HTTP from the MELPA repository on GitHub and
translate them into `package-vc-install` specifications.  Used by
`quelpa2` as an optional fallback when a dependency has no entry in
`Package-Requires-Origins`; enable it in `quelpa2` with
`(setq quelpa2-use-pvrecipe t)`.

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

(pvrecipe 'magit)  ;=> (magit :url "https://github.com/magit/magit" :lisp-dir "lisp")
```

You can also use it interactively with `M-x pvrecipe` to fetch and print any package's translated spec in the echo area.

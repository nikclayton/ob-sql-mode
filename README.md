# ob-sql-mode

`ob-sql-mode` is an alternative backend for
[Org-Babel SQL SRC blocks](http://orgmode.org/worg/org-contrib/babel/languages/ob-doc-sql.html) that
uses `sql-mode` to evaluate the query instead of Org-Babel's built-in
SQL backends.

The practical upshot of this is that you can use any backend that
`sql-mode` supports, not just the ones that Org-Babel supports.

Also, unlike the `sql` backend, `ob-sql-mode` supports multiple different
sessions within the same Org document.

Some familiarity with `sql-mode` is assumed.

## Installation

[![MELPA](https://melpa.org/packages/ob-sql-mode-badge.svg)](https://melpa.org/#/ob-sql-mode)

`ob-sql-mode` is available on [MELPA](https://melpa.org/). If you are
not already using MELPA, add this to your `.emacs` (or equivalent):

```lisp
(require 'package)
(add-to-list 'package-archives
	         '("melpa" . "https://melpa.org/packages/"))
(package-initialize)
```

and then evaluate that code.

You can then install `ob-sql-mode` with the following command:

<kbd>M-x package-install [RET] ob-sql-mode [RET]</kbd>

or by adding the following to your `.emacs`:

```lisp
(unless (package-installed-p 'ob-sql-mode)
  (package-install 'ob-sql-mode))
```

or by using [`use-package`](https://github.com/jwiegley/use-package):

``` lisp
(use-package ob-sql-mode
  :ensure t)
```

After installing, enable with:

``` lisp
(require 'ob-sql-mode)
```

To guard against security risks, Org defaults to prompting for
confirmation every time you evaluate a code block
(see
[Code evaluation and security issues](http://orgmode.org/manual/Code-evaluation-security.html) for
details). To disable this for `ob-sql-mode` blocks you can enter and
evaluate the following.

``` lisp
(setq org-confirm-babel-evaluate
      (lambda (lang body)
        (not (string= lang "sql-mode"))))
```

## Usage

Enter an Org SRC block that specifies `sql-mode`. For example:

```org
#+BEGIN_SRC sql-mode
SELECT 1, 2, 3;
#+END_SRC
```

Then place the point within the block and press <kbd>C-c C-c</kbd> to
evaluate it and have the results inserted in to the document.

> **Tip:** To avoid writing this in full each time you can type <kbd>&lt;Q
> [TAB]</kbd> to insert a pre-filled template (to use a key other than
> <kbd>Q</kbd> customize `org-babel-sql-mode-template-selector`).

Although all the statements in the block will be executed only the the
results from executing the final statement will be returned.

Add a `:product` header argument to set the product to use. For example:

``` org
#+BEGIN_SRC sql-mode :product oracle
SELECT COUNT(*) FROM emp;
#+END_SRC
```

The product must be known to `sql-mode` (i.e., it must be in
`sql-product-alist`).

All blocks that use the same product run in the same session. To change
this add a `:session` header argument with a name for the session. Blocks that
share a session name will be run in the same session.

Per
[Using header arguments](https://orgmode.org/manual/Using-Header-Arguments.html) in
the Org manual you can set these on a per-file level with the
following syntax:

``` org
#+PROPERTY: header-args:sql-mode :product sqlite
#+PROPERTY: header-args:sql-mode+ :session session-name
```

Or you can apply them to all blocks below a particular heading by adding
a properties drawer to the heading with the following syntax:

``` org
** TODO Perform some queries to investigate some data
:PROPERTIES:
:header-args:sql-mode: :product sqlite
:header-args:sql-mode+: :session session-name
:END:

#+BEGIN_SRC sql-mode
-- No :product or :session specified here, so the values from the
-- PROPERTIES drawer are used.
SELECT 1, 2, 3
#+END_SRC
```

To change the default product globally, customize
`org-babel-default-header-args:sql-mode`.

See header commentary in the code for implementation notes and other options.

## License

GPLv3, see the `LICENSE` file in the repository and the copyright statement
in the code for further information.

;;; ob-sql-mode-test.el --- Tests for ob-sql-mode.el -*- lexical-binding: t -*-

;; Create the test database with
;;
;;    sqlite3 test.db < test.sql
;;
;; Run the test with
;;
;;    ls *.el | entr emacs -batch -l ert -l ob-sql-mode-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(load-file "./ob-sql-mode.el")

(defvar ob-sql-mode-test-database-path
  "test.db"
  "Path to the test database.")

(defun results-block-contents (&optional position)
  "Return the contents of the *only* results block in the buffer.
Assume the source block is at POSITION if non-nil."
  (interactive)
  (save-excursion
    (progn
      (if position
	  (goto-char position)
	(goto-char 0)
	(org-babel-next-src-block))
      (goto-char (org-babel-where-is-src-block-result))
      (let ((result (org-babel-read-result)))
        result))))

(defmacro with-buffer-contents (s &rest forms)
  "Create a temporary buffer with contents S and execute FORMS."
  `(save-excursion
     (with-temp-buffer
       (progn
	 (goto-char 0)
	 (insert ,s)
	 (goto-char 0)
	 ,@forms))))

(defun setup (body)
  "Initialise the test environment and run BODY."
  (let ((old-sql-get-login (symbol-function 'sql-get-login)))
    (unwind-protect
	(progn
	  (let ((org-babel-sql-mode-start-interpreter-prompt
		 (lambda (&rest _) t))
		(org-confirm-babel-evaluate
		 (lambda (lang body)
		   (not (string= lang "sql-mode"))))
		(sql-database ob-sql-mode-test-database-path))
	    (defalias 'sql-get-login 'ignore)
	    (funcall body)))
      (defalias 'sql-get-login 'old-sql-get-login))))

(defun simple-test (sql want)
  "Execute SQL in a `sql-mode' Babel block comparing the result against WANT."
  (setup
   (lambda ()
     (let ((buffer-contents (format "Simple select.

#+BEGIN_SRC sql-mode :product sqlite
%s
#+END_SRC" sql)))
       (with-buffer-contents buffer-contents
			     (org-babel-next-src-block)
			     (org-ctrl-c-ctrl-c)
			     (should (string= want (results-block-contents))))))))

(ert-deftest test-simple-select ()
  "Simple select from no table."
  (simple-test "SELECT 1, 2, 3;" "1|2|3"))

(ert-deftest test-select-sqlite-master ()
  "Selecting from sqlite_master."
  (simple-test
   "SELECT * FROM sqlite_master;"
   "table|tbl1|tbl1|2|CREATE TABLE tbl1(one varchar(10), two smallint)"))

(ert-deftest test-select-varchar-column ()
  "Selecting two rows from a varchar column."
  (simple-test
   "SELECT one FROM tbl1;"
   "hello
world"))

(ert-deftest test-select-smallint-column ()
  "Selecting two rows from a smallint column."
  (simple-test
   "SELECT two FROM tbl1;"
   "10
20"))

(ert-deftest test-select-multiple-columns ()
  "Selecting two rows from multiple columns."
  (simple-test
   "SELECT one, two FROM tbl1;"
   "hello|10
world|20"))

(ert-deftest test-select-with-comments ()
  "Comments in various places."
  (simple-test
   "-- First line comment.
SELECT one, -- End of line comment.
-- In-query comment.
  two
FROM
  tbl1;"
   "hello|10
world|20"))

(ert-deftest test-no-session()
  "Two blocks that do not share a session should not affect one another."
  (setup
   (lambda ()
     (with-buffer-contents "SQL Content

First, verify that case_sensitive_like returns no results for this
query.

#+BEGIN_SRC sql-mode :product sqlite
PRAGMA case_sensitive_like = true;
SELECT two FROM tbl1 WHERE one LIKE 'HELLO';
#+END_SRC"
			   (org-babel-next-src-block)
			   (org-ctrl-c-ctrl-c)
			   (should (eq nil (results-block-contents))))
     (with-buffer-contents "SQL Content

Now have two blocks. Evaluate them both. The first should not return
any results, but the second should, because they run in different
sessions, so the PRAGMA in the first should not affect the second.

#+BEGIN_SRC sql-mode :product sqlite
PRAGMA case_sensitive_like = true;
SELECT two FROM tbl1 WHERE one LIKE 'HELLO';
#+END_SRC

A different block in the same session should still be nil.

#+BEGIN_SRC sql-mode :product sqlite
SELECT two FROM tbl1 WHERE one LIKE 'HELLO';
#+END_SRC"
			   (org-babel-next-src-block)
			   (org-ctrl-c-ctrl-c)
			   (should (eq nil (results-block-contents)))
			   (org-babel-next-src-block)
			   (org-ctrl-c-ctrl-c)
			   (should (eq nil (results-block-contents (point)))))
     (with-buffer-contents "SQL Content

The same two blocks, but put them in different sessions.

#+BEGIN_SRC sql-mode :product sqlite :session first
PRAGMA case_sensitive_like = true;
SELECT two FROM tbl1 WHERE one LIKE 'HELLO';
#+END_SRC

A different block in a different session should return 10.

#+BEGIN_SRC sql-mode :product sqlite :session second
SELECT two FROM tbl1 WHERE one LIKE 'HELLO';
#+END_SRC"
			   (org-babel-next-src-block)
			   (org-ctrl-c-ctrl-c)
			   (should (eq nil (results-block-contents)))
			   (org-babel-next-src-block)
			   (org-ctrl-c-ctrl-c)
			   (should (eq 10 (results-block-contents (point))))))))

(provide 'ob-sql-mode-test)
;;; ob-sql-mode-test.el ends here

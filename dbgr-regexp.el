;;; FIXME - think of a better name.
;;; dbgr-regexp.el --- Debugger regular expressions for many kinds of
;;  debuggers

;; Here we have regular expressions and names for matched patterns
;; of those regular expressions.

;;; Code:

;; -------------------------------------------------------------------
;; Variables defining regular expressions (regexp:s).
;;

(defstruct dbgr-loc-pat
  "Information to match and extract a file and line number location from
a string output by a debugger inside a process shell"
  (regexp)
  (file-group)
  (line-group))

(defvar dbgr-pat-hash (make-hash-table :test 'equal)
  "Hash key is the debugger name, a string. The values of a hash entry
  is a dbgr-loc-pat struct")

(provide 'dbgr-regexp)

;;; Local variables:
;;; eval:(put 'dbgr-debug-enter 'lisp-indent-hook 1)
;;; End:

;;; dbgr-regexp.el ends here

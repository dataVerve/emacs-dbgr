;;; Copyright (C) 2012 Rocky Bernstein <rocky@gnu.org>
;;  `rpdb2' Main interface to rpdb2 via Emacs
(require 'load-relative)
(require-relative-list '("../../common/helper"
			 "../../common/track") "realgud-")
(require-relative-list '("core" "track-mode") "realgud-rpdb2-")

;; This is needed, or at least the docstring part of it is needed to
;; get the customization menu to work in Emacs 23.
(defgroup rpdb2 nil
  "The Python rpdb2 debugger"
  :group 'processes
  :group 'dbgr
  :group 'python
  :version "23.1")

;; -------------------------------------------------------------------
;; User definable variables
;;

(defcustom rpdb2-command-name
  "rpdb2"
  "File name for executing the stock Python debugger and command options.
This should be an executable on your path, or an absolute file name."
  :type 'string
  :group 'rpdb2)

(declare-function rpdb2-track-mode (bool))

;; -------------------------------------------------------------------
;; The end.
;;

;;;###autoload
(defun realgud-rpdb2 (&optional opt-command-line no-reset)
  "Invoke the rpdb2 Python debugger and start the Emacs user interface.

String COMMAND-LINE specifies how to run rpdb2.

Normally command buffers are reused when the same debugger is
reinvoked inside a command buffer with a similar command. If we
discover that the buffer has prior command-buffer information and
NO-RESET is nil, then that information which may point into other
buffers and source buffers which may contain marks and fringe or
marginal icons is reset."


  (interactive)
  (let* (
	 (cmd-str (or opt-command-line (rpdb2-query-cmdline
					"rpdb2")))
	 (cmd-args (split-string-and-unquote cmd-str))
	 (parsed-args (rpdb2-parse-cmd-args cmd-args))
	 (script-args (cdr cmd-args))
	 (script-name (car script-args))
	 (cmd-buf))
    (realgud-run-process "rpdb2" script-name cmd-args
		      'rpdb2-track-mode no-reset)
    )
  )


(defalias 'rpdb2 'realgud-rpdb2)

(provide-me "realgud-")

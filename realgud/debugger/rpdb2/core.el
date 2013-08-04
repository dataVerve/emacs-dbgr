;;; Copyright (C) 2012 Rocky Bernstein <rocky@gnu.org>
(eval-when-compile (require 'cl))

(require 'load-relative)
(require-relative-list '("../../common/track"
			 "../../common/core"
			 "../../common/lang")
		       "realgud-")
(require-relative-list '("init") "realgud-rpdb2-")


;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(defvar rpdb2-minibuffer-history nil
  "minibuffer history list for the command `rpdb2'.")

(easy-mmode-defmap rpdb2-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of gud startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable chould be generalized, perhaps via a macro.
(defun rpdb2-query-cmdline (&optional opt-debugger)
  (realgud-query-cmdline
   'rpdb2-suggest-invocation
   rpdb2-minibuffer-local-map
   'rpdb2-minibuffer-history
   opt-debugger))

(defun rpdb2-parse-cmd-args (orig-args)
  "Parse command line ARGS for the annotate level and name of script to debug.

ARGS should contain a tokenized list of the command line to run.

We return the a list containing
- the command processor (e.g. python) and it's arguments if any - a list of strings
- the name of the debugger given (e.g. rpdb2) and its arguments - a list of strings
- the script name and its arguments - list of strings
- whether the annotate or emacs option was given ('-A', '--annotate' or '--emacs) - a boolean

For example for the following input
  (map 'list 'symbol-name
   '(python2.6 -O -Qold ./gcd.py a b))

we might return:
   ((python2.6 -O -Qold) (rpdb2) (./gcd.py a b) 't)

NOTE: the above should have each item listed in quotes.
"

  ;; Parse the following kind of pattern:
  ;;  [python python-options] rpdb2 rpdb2-options script-name script-options
  (let (
	(args orig-args)
	(pair)          ;; temp return from
	(python-opt-two-args '())
	;; Python doesn't have mandatory 2-arg options in our sense,
	;; since the two args can be run together, e.g. "-C/tmp" or "-C /tmp"
	;;
	(python-two-args '())
	;; rpdb2 doesn't have any arguments
	(rpdb2-two-args '())
	(rpdb2-opt-two-args '())
	(interp-regexp
	 (if (member system-type (list 'windows-nt 'cygwin 'msdos))
	     "^python[-0-9.]*\\(.exe\\)?$"
	   "^python[-0-9.]*$"))

	;; Things returned
	(annotate-p nil)
	(debugger-args '())
	(debugger-name nil)
	(interpreter-args '())
	(script-args '())
	(script-name nil)
	)

    (if (not (and args))
	;; Got nothing: return '(nil, nil)
	(list interpreter-args debugger-args script-args annotate-p)
      ;; else
      ;; Strip off optional "python" or "python182" etc.
      (when (string-match interp-regexp
			  (file-name-sans-extension
			   (file-name-nondirectory (car args))))
	(setq interpreter-args (list (pop args)))

	;; Strip off Python-specific options
	(while (and args
		    (string-match "^-" (car args)))
	  (setq pair (realgud-parse-command-arg
		      args python-two-args python-opt-two-args))
	  (nconc interpreter-args (car pair))
	  (setq args (cadr pair))))

      ;; Remove "rpdb2" from "rpdb2 --rpdb2-options script
      ;; --script-options"
      (setq debugger-name (file-name-sans-extension
			   (file-name-nondirectory (car args))))
      (unless (string-match "^\\(rpdb2\\|cli.py\\)$" debugger-name)
	(message
	 "Expecting debugger name `%s' to be `rpdb2' or `cli.py'"
	 debugger-name))
      (setq debugger-args (list (pop args)))

      ;; Skip to the first non-option argument.
      (while (and args (not script-name))
	(let ((arg (car args)))
	  (cond
	   ;; Options with arguments.
	   ((string-match "^-" arg)
	    (setq pair (realgud-parse-command-arg
			args rpdb2-two-args rpdb2-opt-two-args))
	    (nconc debugger-args (car pair))
	    (setq args (cadr pair)))
	   ;; Anything else must be the script to debug.
	   (t (setq script-name arg)
	      (setq script-args args))
	   )))
      (list interpreter-args debugger-args script-args annotate-p))))

(defvar rpdb2-command-name) ; # To silence Warning: reference to free variable
(defun rpdb2-suggest-invocation (debugger-name)
  "Suggest a rpdb2 command invocation via `realgud-suggest-invocaton'"
  (realgud-suggest-invocation rpdb2-command-name rpdb2-minibuffer-history
			   "python" "\\.py"))

(defun rpdb2-reset ()
  "Pydb cleanup - remove debugger's internal buffers (frame,
breakpoints, etc.)."
  (interactive)
  ;; (rpdb2-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*rpdb2-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun rpdb2-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'rpdb2-debugger-support-minor-mode minor-mode-map-alist)
;; 	  rpdb2-debugger-support-minor-mode-map-when-deactive))


(defun rpdb2-customize ()
  "Use `customize' to edit the settings of the `rpdb2' debugger."
  (interactive)
  (customize-group 'rpdb2))

(provide-me "realgud-rpdb2-")

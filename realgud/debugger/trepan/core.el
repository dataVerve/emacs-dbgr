;;; Copyright (C) 2010, 2012, 2014 Rocky Bernstein <rocky@gnu.org>
(eval-when-compile (require 'cl))

(require 'load-relative)
(require-relative-list '("../../common/track"
                         "../../common/core"
                         "../../common/lang")
                       "realgud-")
(require-relative-list '("init") "realgud:trepan-")

(declare-function realgud:expand-file-name-if-exists 'realgud-core)
(declare-function realgud-parse-command-arg  'realgud-core)
(declare-function realgud-query-cmdline      'realgud-core)
(declare-function realgud-suggest-invocation 'realgud-core)

;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(defvar realgud:trepan-minibuffer-history nil
  "minibuffer history list for the command `realgud:trepan'.")

(easy-mmode-defmap trepan-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of gud startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable chould be generalized, perhaps via a macro.
(defun realgud:trepan-query-cmdline (&optional opt-debugger)
  (realgud-query-cmdline
   'trepan-suggest-invocation
   trepan-minibuffer-local-map
   'realgud:trepan-minibuffer-history
   opt-debugger))

(defun realgud:trepan-parse-cmd-args (orig-args)
  "Parse command line ARGS for the annotate level and name of script to debug.

ORIG-ARGS should contain a tokenized list of the command line to run.

We return the a list containing

* the command processor (e.g. ruby) and it's arguments if any - a
  list of strings

* the name of the debugger given (e.g. trepan) and its arguments
  - a list of strings

* the script name and its arguments - list of strings

* whether the annotate or emacs option was given ('-A',
  '--annotate' or '--emacs) - a boolean

For example for the following input
  (map 'list 'symbol-name
   '(ruby1.9 -W -C /tmp trepan --emacs ./gcd.rb a b))

we might return:
   ((ruby1.9 -W -C) (trepan --emacs) (./gcd.rb a b) 't)

Note that the script name path has been expanded via `expand-file-name'.
"

  ;; Parse the following kind of pattern:
  ;;  [ruby ruby-options] trepan trepan-options script-name script-options
  (let (
        (args orig-args)
        (pair)          ;; temp return from
        (ruby-opt-two-args '("0" "C" "e" "E" "F" "i"))
        ;; Ruby doesn't have mandatory 2-arg options in our sense,
        ;; since the two args can be run together, e.g. "-C/tmp" or "-C /tmp"
        ;;
        (ruby-two-args '())
        ;; One dash is added automatically to the below, so
        ;; h is really -h and -host is really --host.
        (trepan-two-args '("h" "-host" "p" "-port"
                           "I" "-include" "-r" "-require"))
        (trepan-opt-two-args '())
        (interp-regexp
         (if (member system-type (list 'windows-nt 'cygwin 'msdos))
             "^ruby[-0-9]*\\(.exe\\)?$"
           "^ruby[-0-9]*$"))

        ;; Things returned
        (script-name nil)
        (debugger-name nil)
        (interpreter-args '())
        (debugger-args '())
        (script-args '())
        (annotate-p nil))

    (if (not (and args))
        ;; Got nothing: return '(nil, nil)
        (list interpreter-args debugger-args script-args annotate-p)
      ;; else
      ;; Strip off optional "ruby" or "ruby182" etc.
      (when (string-match interp-regexp
                          (file-name-sans-extension
                           (file-name-nondirectory (car args))))
        (setq interpreter-args (list (pop args)))

        ;; Strip off Ruby-specific options
        (while (and args
                    (string-match "^-" (car args)))
          (setq pair (realgud-parse-command-arg
                      args ruby-two-args ruby-opt-two-args))
          (nconc interpreter-args (car pair))
          (setq args (cadr pair))))

      ;; Remove "trepan" from "trepan --trepan-options script
      ;; --script-options"
      (setq debugger-name (file-name-sans-extension
                           (file-name-nondirectory (car args))))
      (unless (string-match "^trepan$" debugger-name)
        (message
         "Expecting debugger name `%s' to be `trepan'"
         debugger-name))
      (setq debugger-args (list (pop args)))

      ;; Skip to the first non-option argument.
      (while (and args (not script-name))
        (let ((arg (car args)))
          (cond
           ;; Annotation or emacs option with level number.
           ((or (member arg '("--annotate" "-A"))
                (equal arg "--emacs"))
            (setq annotate-p t)
            (nconc debugger-args (list (pop args))))
           ;; Combined annotation and level option.
           ((string-match "^--annotate=[0-9]" arg)
            (nconc debugger-args (list (pop args)) )
            (setq annotate-p t))
	   ;; path-argument options
	   ((member arg '("--include" "-I" "--require" "-I"))
	    (setq arg (pop args))
	    (nconc debugger-args
		   (list arg (realgud:expand-file-name-if-exists
			      (pop args)))))
           ;; Options with arguments.
           ((string-match "^-" arg)
            (setq pair (realgud-parse-command-arg
                        args trepan-two-args trepan-opt-two-args))
            (nconc debugger-args (car pair))
            (setq args (cadr pair)))
           ;; Anything else must be the script to debug.
	   (t (setq script-name (realgud:expand-file-name-if-exists arg))
	      (setq script-args (cons script-name (cdr args))))
           )))
      (list interpreter-args debugger-args script-args annotate-p))))

;; To silence Warning: reference to free variable
(defvar realgud:trepan-command-name)

(defun trepan-suggest-invocation (debugger-name)
  "Suggest a trepan command invocation via `realgud-suggest-invocaton'"
  (realgud-suggest-invocation realgud:trepan-command-name
			      realgud:trepan-minibuffer-history
			      "ruby" "\\.rb$" "trepan"))

(defun trepan-reset ()
  "Trepan cleanup - remove debugger's internal buffers (frame,
breakpoints, etc.)."
  (interactive)
  ;; (trepan-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*trepan-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun trepan-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'trepan-debugger-support-minor-mode minor-mode-map-alist)
;;        trepan-debugger-support-minor-mode-map-when-deactive))


(defun realgud:trepan-customize ()
  "Use `customize' to edit the settings of the `trepan' debugger."
  (interactive)
  (customize-group 'realgud:trepan))

(provide-me "realgud:trepan-")

;;; Copyright (C) 2010, 2012 Rocky Bernstein <rocky@gnu.org>
;;; Python "rpdb2" Debugger tracking a comint
;;; or eshell buffer.

(eval-when-compile (require 'cl))
(require 'load-relative)
(require-relative-list '(
                         "../../common/cmds"
                         "../../common/menu"
                         "../../common/track"
                         "../../common/track-mode"
                         )
                       "realgud-")
(require-relative-list '("core" "init") "realgud-rpdb2-")

(realgud-track-mode-vars "rpdb2")

(declare-function realgud-track-mode(bool))

(realgud-python-populate-command-keys rpdb2-track-mode-map)

(defun rpdb2-track-mode-hook()
  (if rpdb2-track-mode
      (progn
        (use-local-map rpdb2-track-mode-map)
        (message "using rpdb2 mode map")
        )
    (message "rpdb2 track-mode-hook disable called")
    )
)

(define-minor-mode rpdb2-track-mode
  "Minor mode for tracking Pydb debugging inside a process shell."
  :init-value nil
  ;; :lighter " rpdb2"   ;; mode-line indicator from realgud-track is sufficient.
  ;; The minor mode bindings.
  :global nil
  :group 'rpdb2
  :keymap rpdb2-track-mode-map
  (realgud-track-set-debugger "rpdb2")
  (if rpdb2-track-mode
      (progn
        (setq realgud-track-mode 't)
        (realgud-track-mode-setup 't)
        (rpdb2-track-mode-hook))
    (progn
      (setq realgud-track-mode nil)
      ))
)

(provide-me "realgud-rpdb2-")

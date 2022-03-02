(in-package :repl-server)

(defun swank-thread ()
  "Returns a thread that's acting as a Swank server."
  (dolist (thread (sb-thread:list-all-threads))
    (when (base:prefixp "Swank" (sb-thread:thread-name thread))
      (return thread))))

(defun wait-for-swank-thread ()
  "Wait for the Swank server thread to exit."
  (let ((swank-thread (swank-thread)))
    (when swank-thread
      (sb-thread:join-thread swank-thread))))

(defconstant +SIGINT+ 2)

(defmacro set-signal-handler (signo &body body)
  (let ((handler (gensym "HANDLER")))
    `(progn
       (cffi:defcallback ,handler :void ((signo :int))
         (declare (ignore signo))
         ,@body)
       (cffi:foreign-funcall "signal" :int ,signo :pointer (cffi:callback ,handler)))))

(opts:define-opts
  (:name :help
         :description "print this help text"
         :short #\h
         :long "help")
  (:name :port
         :description "port to listen default to 4005"
         :short #\p
         :long "port"
         :arg-parser #'parse-integer))

(defun swank-repl-server (&rest argv)
  "Start up a swank repl server"
  (multiple-value-bind (options free-args) (opts:get-opts argv)
    (when (getf options :help)
      (opts:describe
        :prefix "A simple wrapper for swank server"
        :args " [keyword] ")
      (uiop:quit))

    ;; Load systems
    (pushnew (uiop/os:getcwd) ql:*local-project-directories*)
    (dolist (p free-args)
      (asdf:load-system p))

    ;; Manage SIGINT
    (set-signal-handler +SIGINT+
      (format t "Stopping swank server...")
      (uiop:quit 0))

    ;; Start swank server and wait
    (let ((port (getf options :port 4005)))
      (setf swank:*configure-emacs-indentation* nil
            swank::*enable-event-history* nil
            swank:*log-events* t)
      (swank:create-server :port port :dont-close t)
      (wait-for-swank-thread))))

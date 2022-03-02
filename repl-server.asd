(defsystem "repl-server"
  :version "0.1.0"
  :author "indraniel"
  :license "BSD"
  :depends-on ("swank" "com.google.base" "asdf" "uiop" "cffi" "unix-opts")
  :description "simple program to start up a swank server")

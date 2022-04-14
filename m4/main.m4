;; main.m4
  (func $main (export "_start")
	(call $io.initialize)
	(call $byte.print _CHAR(`A'))
	(call $byte.print _LF)
  )
  
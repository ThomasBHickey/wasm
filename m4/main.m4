;; main.m4
  (func $main (export "_start")
	(local $byte i32)
	(call $io.initialize)
	(local.set $byte (call $byte.read))
	(call $byte.print _CHAR(`A'))
	(call $byte.print (local.get $byte))
	(call $byte.print _LF)
  )
  
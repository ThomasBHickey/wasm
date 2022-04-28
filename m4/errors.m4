;; errors.m4
  (func $error (result i32)
	;; throw a divide-by-zero exception!
	(i32.div_u (i32.const 1)(i32.const 0))
  )
  (func $error2
    (local $t i32)
    (local.set $t (i32.div_u (i32.const 1)(i32.const 0)))
  )
  (func $error3 (param $err i32)
    (call $byte.print _CHAR(`-'))
	(call $i32.print (local.get $err))
    (call $byte.print _CHAR(`-'))
	(call $byte.print _SP)
	(call $error2)
  )
 
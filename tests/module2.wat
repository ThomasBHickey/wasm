(module
  (type $t1t (func (param)(result i32)))
  (import "module1" "t1" (func (type $t1t)))
  (memory 1)
  (export "memory" (memory 0))
  (func $t2 (result i32)
	(i32.add (call $t1)(i32.const 2))
	(i32.div (i32.const 2)(call $t1))
  )
  (export "t2" (func $t2))
  (func $main (export "_start")
	(call $t2)
  )
)
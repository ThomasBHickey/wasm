((module
  (memory 1)
  (export "memory" (memory 0))
  (func $t1 (result i32)
	(i32.const 1)
  )
  (export "t1" (func $t1))
)

(module
  (type $t1t (func (param)(result i32)))
  (import "module1" "$t1" (func (type $t1t)))
  (memory 1)
  (export "memory" (memory 0))
  (func $t2 (result i32)
	(i32.add (call $t1)(i32.const 2))
  )
  (export "t2" (func $t2))
))
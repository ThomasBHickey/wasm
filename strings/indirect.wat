(module
  (type $type1 (func (result i32)))
  (type $type2 (func (param i32) (param i32)(result i32)))
  (table 2 funcref)
  (elem (i32.const 0) 
    $test1
	$test2)
  (memory $0 1)

  (func $test1 (type $type1) ;;(result i32)
    (i32.const 42)
  )
  (func $test2 (type $type2) ;;(result i32)
  ;;(func $test2 (param i32)(param i32)(result i32)
    (i32.add (get_local 0)(local.get 1))
  )

  (func $main (result i32)
    (call_indirect (type $type1)
      (i32.const 0)
    )
	drop
	(i32.const 40)(i32.const 41)
    (call_indirect (type $type2)
	;;This works too: (call_indirect (param i32)(param i32)(result i32)
      (i32.const 1)
    )
  )

)
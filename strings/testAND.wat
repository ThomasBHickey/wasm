(module
  (memory 1)
  (export "memory" (memory 0))
  
  (func $AND (result i32)
	(if (result i32) (i32.const 7)
	  (then
		(if (result i32) (i32.const 8)
		  (then
		    (i32.const 1))
		(else (i32.const 0))
	    )
	  )
	(else (i32.const 0)))
  )
  (func $AND2 (result i32)
    i32.const 7
    if (result i32)  ;; label = @1
      i32.const 8
      if (result i32)  ;; label = @2
        i32.const 1
      else
        i32.const 0
      end
    else
      i32.const 0
    end)

)

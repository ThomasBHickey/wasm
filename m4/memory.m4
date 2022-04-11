;; memory.m4
  (memory 1024)
  (export "memory" (memory 0))
  (func $getMem (param $size i32)(result i32)
	;; Simple memory allocation done in 4-byte chunks
	;; Should this get cleared first?
	(local $size4 i32)
	(local.set $size4 
	  (i32.mul (i32.div_u 
				(i32.add (local.get $size)(i32.const 3))
				(i32.const 4))(i32.const 4)))
	(global.get $nextFreeMem) ;; to return
	(global.set $nextFreeMem (i32.add (global.get $nextFreeMem)(local.get $size4)))
	(if (i32.gt_u (global.get $nextFreeMem)(global.get $maxFreeMem))
	  (global.set $maxFreeMem (global.get $nextFreeMem)))
  )
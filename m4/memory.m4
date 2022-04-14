;; memory.m4
  (global $memChunks i32 (i32.const 1024))
  ;;(memory (global.get $memChunks))
  (memory 1024)
  (export "memory" (memory 0))
  (global $curMemUsed (mut i32)(i32.const 100)) ;; First 100 bytes reserved
  (global $maxMemUsed (mut i32)(i32.const 100)) ;; e..g. I/O buffers in io.m4
  (global $memSize i32 (i32.const 1048576))  ;; 1024*1024
  (global $memReclaimed (mut i32)(i32.const 0))
  (global $memReclamations (mut i32)(i32.const 0))
  
  (func $mem.get (param $size i32)(result i32)
	;; Simple memory allocation done in 4-byte chunks
	;; Should this get cleared first?
	(local $size4 i32)
	(local.set $size4   ;; make sure size divisble by 4
	  (i32.mul (i32.div_u 
				 (i32.add (local.get $size)(i32.const 3))
				 (i32.const 4))
			   (i32.const 4)))
	(global.get $curMemUsed) ;; on stack to return
	(global.set $curMemUsed (i32.add (global.get $curMemUsed)(local.get $size4)))
	(if (i32.gt_u (global.get $curMemUsed)(global.get $maxMemUsed))
	  (global.set $maxMemUsed (global.get $curMemUsed)))
  )
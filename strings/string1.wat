(module
  (import "wasi_unstable" "fd_read" 
    (func $fd_read (param i32 i32 i32 i32) (result i32)))
  (import "wasi_unstable" "fd_write" 
    (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (global $nextStrOff (mut i32) (i32.const 1000))
  (global $zero i32 (i32.const 48))
  
  (memory 1)
  (export "memory" (memory 0))

  (func $i32.print (param $N i32)
	(local $Ntemp i32)
	(local.set $Ntemp (local.get $N))
	(loop $digitLoop
	  (call $C.print
		(i32.add
		  (i32.rem_u (local.get $Ntemp)(i32.const 10))
		  (global.get $zero)))
	  (i32.div_s (local.get $Ntemp)(i32.const 10))
	  (local.set $Ntemp)
	  (br_if $digitLoop (local.get $Ntemp))
	)
	(call $C.print (i32.const 10))  ;; linefeed
	)
  (func $C.print (param $C i32)
	;; iovs start at 200, buffer at 300
	(i32.store (i32.const 200) (i32.const 300))
	(i32.store (i32.const 204) (i32.const 10))  ;; length of 10?
	;; Compute char value for the number mod 10, store a offset 300
	(i32.store
		(i32.const 300)
		(local.get $C))
	(call $fd_write
		(i32.const 1) ;; stdout
		(i32.const 200) ;; *iovs
		(i32.const 1) ;; # iovs
		(i32.const 0) ;; length?
	)
	drop
	)
  (func $str.print (param $strOff i32)
	(local $curLength i32)
	(local $cpos i32)
	(local.set $curLength (i32.load (local.get $strOff)))
	(local.set $cpos (i32.const 0))
	(call $C.print (i32.load8_u (local.get $strOff)))
  )
  (func $str.mk (result i32) ;; returns an offset
	;; Strings start as an i32 curLength (0), 
	;; an i32 maxLength (4), 4 byte data (empty)
	;; 12 bytes total
	(global.get $nextStrOff) ;; this is the offset to return
	(i32.store (global.get $nextStrOff) (i32.const 0)) ;; length=0
	;; increment by 4
	(global.get $nextStrOff)(i32.const 4)(i32.add)(global.set $nextStrOff)
	(i32.store (global.get $nextStrOff) (i32.const 4))  ;; 4 bytes allocated for string data
	;; increment by 4 again
	(global.get $nextStrOff)(i32.const 4)(i32.add)(global.set $nextStrOff)
  )  

 (func $str.addChar (param $Offset i32)(param $C i32)(result i32) ;; returns an offset
	(local $maxLength i32) (local $curLength i32)
	(call $C.print (i32.const 69));; 'E'
	(call $i32.print(local.get $Offset))
	(local.set $curLength (i32.load (local.get $Offset)))
	(local.set $maxLength (i32.load (i32.add (i32.const 4)(local.get $Offset))))
	(i32.add (local.get $curLength) (i32.const 1)) 
	(local.set $curLength) ;; length it will be
	(call $i32.print(local.get $curLength))
	(i32.store (local.get $curLength)(local.get $Offset))
	;; (if (result i32)
	  ;; (i32.gt_u (local.get $maxLength)(local.get $curLength))
	  ;; (then (i32.const 0))
	  ;; (else (i32.const 0) )
	;; )
	;; drop
    (local.get $Offset)  ;; return same offset if it fits

  )
  
  (func $main (export "_start")
	(local $sp i32)
	(local.set $sp (call $str.mk))
	(call $C.print (i32.const 65))  ;; 'A'
	(local.get $sp)
	(call $i32.print)
	;;(call $str.addChar (local.get $sp) (i32.add (i32.const 3) (global.get $zero)))
	(call $str.addChar (local.get $sp) (i32.const 66))
	;;(local.set $sp)
	drop  ;; shouldn't have changed yet!!
	(call $C.print (i32.const 67)) ;; 'C'
	(call $str.print (local.get $sp))
  )
)
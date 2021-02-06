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
  (func $str.print (param $strOffset i32)
	(local $curLength i32)
	(local $dataOffset i32)  ;; offset to string data
	(local $cpos i32)  ;; steps through character positions
	(local.set $curLength (i32.load (local.get $strOffset)))
	(local.set $cpos (i32.const 0))
	(call $C.print (i32.const 34)) ;; double quote
	(local.set $dataOffset(i32.load (i32.add (i32.const 8)(local.get $strOffset))))
	(loop $cLoop
	  (if (i32.lt_u (local.get $cpos)(local.get $curLength))
		(then
		 (i32.load8_u (i32.add (local.get $dataOffset)(local.get $cpos)))
		 (call $C.print)   
	     (local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
	     (br $cLoop)
	)))
	(call $C.print (i32.const 34)) ;; double quote
 	(call $C.print (i32.const 10))  ;; linefeed
  )
  (func $str.mk (result i32) ;; returns an offset as string pointer
	;; Strings start as an i32 curLength (0), 
	;; an i32 maxLength (4), an i32 offset to the data,
	;; (initially a 4 byte chunk)
	;; 16 bytes total minimum/string: curLen, maxLen, data offset, 4 data bytes
	;; As they grow beyond their allocation it doubles.
	;; An offset into memory serves as a string pointer
	;; !!!Right now the assumption is the characters are 7-bit safe!!!

	(i32.store (global.get $nextStrOff) (i32.const 0)) ;; length=0
	(i32.store (i32.add (global.get $nextStrOff)(i32.const 4))(i32.const 4));;4 bytes allocated
	(i32.store 
		(i32.add (global.get $nextStrOff)(i32.const 8))
		(i32.add (global.get $nextStrOff)(i32.const 12))) ;; offset to initial data
	;; increment $nextStrOff over 16 bytes 
	(global.get $nextStrOff) ;; this is the offset that gets returned
	(global.set $nextStrOff (i32.add (global.get $nextStrOff)(i32.const 16)))
	;; return old $nextStrOff sitting on the stack
  )  
 (func $str.catChar (param $Offset i32)(param $C i32)
	(local $maxLength i32) (local $curLength i32) (local $dataOffset i32)
	(local.set $curLength (i32.load (local.get $Offset)))
	(local.set $maxLength (i32.load (i32.add (i32.const 4)(local.get $Offset))))
	(local.set $dataOffset(i32.load (i32.add (i32.const 8)(local.get $Offset))))
	;; (if (i32.gte (local.get $curLength) (local.get $maxLength))
		;; handle reallocation!
	;; )
	(i32.store8 (i32.add (local.get $curLength)(local.get $dataOffset))(local.get $C)) 
	(i32.store (local.get $Offset) (i32.add (local.get $curLength)(i32.const 1)));; new length
  ) 
  (func $main (export "_start")
	(local $sp i32)
	(local.set $sp (call $str.mk))
	(local.get $sp)
	(call $i32.print)
	(call $str.catChar (local.get $sp) (i32.const 65))
	(call $str.catChar (local.get $sp) (i32.const 66))
	(call $str.catChar (local.get $sp) (i32.const 67))
	(call $str.catChar (local.get $sp) (i32.const 68))
	(call $str.catChar (local.get $sp) (i32.const 69));;ERROR  overstepping allocated str mem
	(call $str.print (local.get $sp))
  )
)
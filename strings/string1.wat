;; run via "wasmtime string1.wat" 
;; or "wasmtime string1.wasm" if it has been compiled by wasm2wat
;; (wasmtime recognizes the func exported as "_start")
(module
  (import "wasi_unstable" "fd_read"  (func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (global $nextStrOff (mut i32) (i32.const 1024))
  (global $zero i32 (i32.const 48))
  
  (memory 1)
  (export "memory" (memory 0))
  (data (i32.const 128) "Hello World\00") ;; null not part of string
  
  (func $plus1 (param $v i32)(result i32)
   (i32.add (local.get $v)(i32.const 1))
  )
  (func $i32.print (param $N i32) ;; !Prints the digits backwards!
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
  (func $str.mkdata (param $dataOffset i32) (result i32)
	;; Make a string from null-terminated chunk of memory
	;; null terminator is not counted as part of string
	(local $length i32) (local $curByte i32)
	(local.set $length (i32.const 0))
	(loop $cLoop
		(local.set $curByte (i32.load8_u (i32.add (local.get $length)(local.get $dataOffset))))
		(if (i32.ne (i32.const 0)(local.get $curByte)) ;; checking for null
		  (then
		    (local.set $length (i32.add (local.get $length)(i32.const 1)))
			(br $cLoop)
		  )
		)
	)
	(global.get $nextStrOff) ;; this gets returned
	(i32.store (global.get $nextStrOff) (local.get $length))  ;; cur length
	(i32.store (i32.add (global.get $nextStrOff)(i32.const 4)) (local.get $length));; maxLength
	(i32.store (i32.add (global.get $nextStrOff)(i32.const 8)) (local.get $dataOffset))
	(global.set $nextStrOff (i32.add (global.get $nextStrOff)(i32.const 12)))
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
  (func $str.mk (result i32)
	;; returns a memory offset for a string pointer:
	;; 		curLength, maxLength, dataOffset
	;; Strings start as an i32 curLength (0), 
	;; an i32 maxLength (4), an i32 memory offset to the data,
	;; (the data is initially a 4 byte chunk)
	;; 16 bytes total minimum for a string: curLen, maxLen, dataOffset, 4 data bytes
	;; As they grow beyond their allocation it doubles.
	;; Code assumes that the maxLength starts at 4 (for i32 alignment and doubling)
	;; !!!Right now (2021-02-05) the assumption is the characters are 7-bit safe!!!

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
  (func $str.extend(param $Offset i32)
	;; double the space available for characters
	;; move old data into new data
	;; update maxLength and data offset
	;; old space is abandoned, but future optimization could recognize
	;; if new space is adjacent and avoid moving old data
	(local $maxLength i32) (local $curLength i32) (local $dataOffset i32)
	(local $newMaxLength i32) (local $newDataOffset i32)
	(local $wordPos i32) (local $wordCount i32)
	(local.set $curLength (i32.load (local.get $Offset)))
	(local.set $maxLength (i32.load (i32.add (i32.const 4)(local.get $Offset))))
	(local.set $dataOffset(i32.load (i32.add (i32.const 8)(local.get $Offset))))
	(local.set $newMaxLength (i32.mul (local.get $maxLength)(i32.const 2)))
	(local.set $newDataOffset (global.get $nextStrOff))
	(global.set $nextStrOff (i32.add (global.get $nextStrOff)(local.get $newMaxLength)))
	(i32.store (i32.add (local.get $Offset)(i32.const 4))(local.get $newMaxLength))
	(i32.store (i32.add (local.get $Offset)(i32.const 8))(local.get $newDataOffset))
	;; now move old data into the new space, i32 at a time
	(local.set $wordCount (i32.div_u (local.get $maxLength)(i32.const 4)))
	;;(call $C.print (i32.const 61))(call $i32.print (local.get $wordCount))
	(local.set $wordPos (i32.const 0))
	(loop $wordLoop
		;;(call $C.print (i32.const 62)) ;; '>'
		;;(call $i32.print (local.get $wordPos))
		(i32.store 
		  (i32.add (local.get $newDataOffset)(local.get $wordPos))
		  (i32.load (i32.add (local.get $dataOffset)(local.get $wordPos))))
		(local.set $wordPos (i32.add (local.get $wordPos)(i32.const 1)))
		(br_if $wordLoop (i32.lt_u (local.get $wordPos)(local.get $wordCount)))
	)
 	;;(call $C.print (i32.const 70))
  )
  (func $str.catChar (param $Offset i32)(param $C i32)
	(local $maxLength i32) (local $curLength i32) (local $dataOffset i32)
	(local.set $curLength (i32.load (local.get $Offset)))
	(local.set $maxLength (i32.load (i32.add (local.get $Offset)(i32.const 4))))
	;;(call $C.print (i32.const 77))(call $C.print (i32.const 58))(call $i32.print(local.get $maxLength))
	(if (i32.ge_u (local.get $curLength) (local.get $maxLength))
		;;handle reallocation!
		(then
		  (call $str.extend (local.get $Offset))
		  (local.set $maxLength (i32.load (i32.add (i32.const 4)(local.get $Offset))))
		  ;;(call $i32.print (local.get $maxLength))
		  )
	)
	(local.set $dataOffset(i32.load (i32.add (i32.const 8)(local.get $Offset))))
	(i32.store8 (i32.add (local.get $curLength)(local.get $dataOffset))(local.get $C)) 
	(i32.store (local.get $Offset) (i32.add (local.get $curLength)(i32.const 1)));; new length
  ) 
  (func $main (export "_start")
	(local $sp i32)
	(call $str.print (call $str.mkdata (i32.const 128)))
	(local.set $sp (call $str.mk))
	(call $str.catChar (local.get $sp) (i32.const 65))
	(call $str.catChar (local.get $sp) (i32.const 66))
	(call $str.catChar (local.get $sp) (i32.const 67))
	(call $str.catChar (local.get $sp) (i32.const 68))
	(call $str.catChar (local.get $sp) (i32.const 69))
	(call $str.catChar (local.get $sp) (i32.const 70))
	(call $str.print (local.get $sp))
  )
)

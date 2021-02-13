;; run via "wasmtime string1.wat" 
;; or "wasmtime string1.wasm" if it has been compiled by wasm2wat
;; (wasmtime recognizes the func exported as "_start")
(module
  (import "wasi_unstable" "fd_read"  (func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1)
  (export "memory" (memory 0))
  (global $nextstrPtr (mut i32) (i32.const 1024))
  (global $zero i32 (i32.const 48))

  (data (i32.const 128) "Hello1\00") ;; null not part of string
  (global $Hello1Data i32 (i32.const 128))
  (data (i32.const 168) "Hello2\00")
  (global $Hello2Data i32 (i32.const 168))
  (data (i32.const 208) "Catted string:\00")
  (global $CattedData i32 (i32.const 208))
  (data (i32.const 228) "reallocating string\00")
  (global $reallocatingString i32 (i32.const 228))

  (func $plus1 (param $v i32)(result i32)(i32.add (local.get $v)(i32.const 1)))

  ;; Simple i32 print, but prints the digits backwards!
  (func $i32.print1 (param $N i32) 
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
  ;; Doesn't understand negative numbers
  (func $i32.print (param $N i32)
	(local $Ntemp i32)(local $sptr i32)
	(local.set $sptr (call $str.mk))
	(local.set $Ntemp (local.get $N))
	(loop $digitLoop
	  (call $str.LcatChar (local.get $sptr)
		(i32.add
		  (i32.rem_u (local.get $Ntemp)(i32.const 10))
			(global.get $zero)))
	  (i32.div_s (local.get $Ntemp)(i32.const 10))
	  (local.set $Ntemp)
	  (br_if $digitLoop (local.get $Ntemp))
	)
	(call $str.print (local.get $sptr))
  )
  (func $C.print (param $C i32)
	;; iovs start at 200, buffer at 300
	(i32.store (i32.const 200) (i32.const 300))
	(i32.store (i32.const 204) (i32.const 10))  ;; length of 10?
	;; Compute char value for the number mod 10, store at offset 300
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
  (func $str.curLen (param $strPtr i32)(result i32)
	(i32.load (local.get $strPtr))
  )
  (func $str.setCurLen(param $strPtr i32)(param $newLen i32)
	(i32.store (local.get $strPtr) (local.get $newLen))
  )
  (func $str.maxLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 4)))
  )
  (func $str.setMaxLen(param $strPtr i32)(param $newMaxLen i32)
	(i32.store (i32.add(local.get $strPtr)(i32.const 4))(local.get $newMaxLen))
  )
  (func $str.dataOff (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 8)))
  )
  (func $str.setDataOff (param $strPtr i32)(param $newDataOff i32)
    (i32.store (i32.add(local.get $strPtr)(i32.const 8))(local.get $newDataOff))
  )
  (func $str.incrNextstrPtr
	(global.set $nextstrPtr (i32.add (global.get $nextstrPtr)(i32.const 16)))
  )
  ;; Concatenate s2 onto s1
  (func $str.catOntoStr (param $s1Ptr i32)(param $s2Ptr i32)
	(local $c2pos i32)(local $s2curLen i32)
	(local.set $c2pos (i32.const 0))
	(local.set $s2curLen (call $str.curLen (local.get $s2curLen)))
	(loop $cloop
		(if (i32.lt_u (local.get $c2pos)(local.get $s2curLen))
		  (then
			(call $str.catChar(local.get $s1Ptr)(call $str.getChar (local.get $s2Ptr)(local.get $c2pos)))
			(local.set $c2pos (i32.add (local.get $c2pos)(i32.const 1)))
			(br $cloop)
		  )
		)
	)		
  )
  ;; Returns a pointer to a new string with reversed characters
  (func $str.Rev (param $strPtr i32)(result i32)
	(local $cpos i32)(local $curLen i32)(local $revStrPtr i32)(local $curChar i32)
	(local.set $revStrPtr (call $str.mk))
	(local.set $cpos (i32.const 0))
	(local.set $curLen (call $str.curLen(local.get $strPtr)))
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $curLen))
		(then
			(local.set $curChar (call $str.getChar (local.get $strPtr)(local.get $cpos)))
			(call $str.LcatChar (local.get $revStrPtr)(local.get $curChar))
			(local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
		)
	  )
	  (br_if $cloop (i32.lt_u (local.get $cpos)(local.get $curLen)))
	)
	(local.get $revStrPtr)
  )
  ;; how to show an error beyond returning null?
  (func $str.getChar (param $strPtr i32) (param $charPos i32)(result i32)
	(if (result i32) (i32.lt_u (local.get $charPos)(call $str.curLen (local.get $strPtr)) )
	  (then
		(i32.load8_u (i32.add (call $str.dataOff (local.get $strPtr))(local.get $charPos)))
	  )
	  (else (i32.const 0))
	)
  )
  ;; Make a string from null-terminated chunk of memory
  (func $str.mkdata (param $dataOffset i32) (result i32)
	;; null terminator is not counted as part of string
	;; maxLen might not be a power of 2--makes a difference in extending space
	(local $length i32) (local $curByte i32)
	(local.set $length (i32.const 0))
	(loop $cLoop
		(local.set $curByte (i32.load8_u (i32.add (local.get $length)(local.get $dataOffset))))
		(if (i32.ne (i32.const 0)(local.get $curByte)) ;; checking for null
		  (then
		    (local.set $length (i32.add (local.get $length)(i32.const 1)))
			(br $cLoop)
	)))
	(global.get $nextstrPtr) ;; this gets returned
	(i32.store (global.get $nextstrPtr) (local.get $length))  ;; cur length
	(i32.store (i32.add (global.get $nextstrPtr)(i32.const 4)) (local.get $length));; maxLength
	(i32.store (i32.add (global.get $nextstrPtr)(i32.const 8)) (local.get $dataOffset))
	(global.set $nextstrPtr (i32.add (global.get $nextstrPtr)(i32.const 12)))
  )
  (func $str.print (param $strPtr i32)
	(local $curLength i32)
	(local $dataOffset i32)  ;; offset to string data
	(local $cpos i32)  ;; steps through character positions
	(local.set $curLength (i32.load (local.get $strPtr)))
	(local.set $cpos (i32.const 0))
	(call $C.print (i32.const 34)) ;; double quote
	(local.set $dataOffset(i32.load (i32.add (i32.const 8)(local.get $strPtr))))
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
	;; !!!Right now (2021-02-05) the assumption is the characters are 7-bit safe!!!
	(local $strPtr i32)
	(local.set $strPtr (global.get $nextstrPtr))
	(call $str.incrNextstrPtr)
	(call $str.setCurLen (local.get $strPtr) (i32.const 0))
	(call $str.setMaxLen (local.get $strPtr)(i32.const 4))
	(call $str.setDataOff (local.get $strPtr)(global.get $nextstrPtr))
	(call $str.incrNextstrPtr) ;; skips over 16 bytes
	(local.get $strPtr)
  )
  (func $str.extend(param $strPtr i32)
	;; double the space available for characters
	;; move old data into new data
	;; update maxLen and data offset
	;; old space is abandoned, but future optimization could recognize
	;; if new space is adjacent and avoid moving old data
	(local $maxLen i32) (local $curLen i32) (local $dataOff i32)
	(local $newMaxLen i32)(local $newSptr i32)(local $newDataOff i32)
	(local $cpos i32)
	(local.set $curLen (call $str.curLen (local.get $strPtr)))
	(local.set $maxLen (call $str.maxLen (local.get $strPtr)))
	(local.set $dataOff   (call $str.dataOff (local.get $strPtr)))
	(local.set $newMaxLen (i32.mul (local.get $maxLen)(i32.const 2)))
	(local.set $newDataOff (global.get $nextstrPtr))
	(global.set $nextstrPtr (i32.add (global.get $nextstrPtr)(local.get $newMaxLen)))
	(call $str.setMaxLen(local.get $strPtr)(local.get $newMaxLen))
	(call $str.setDataOff(local.get $strPtr)(local.get $newDataOff))
	(memory.copy (local.get $newDataOff)(local.get $dataOff)(local.get $curLen))
  )
  (func $str.catChar (param $Offset i32)(param $C i32)
	(local $maxLen i32) (local $curLen i32) (local $dataOffset i32)
	(local.set $curLen (i32.load (local.get $Offset)))
	(local.set $maxLen (i32.load (i32.add (local.get $Offset)(i32.const 4))))
	;;(call $C.print (i32.const 77))(call $C.print (i32.const 58))(call $i32.print(local.get $maxLen))
	(if (i32.ge_u (local.get $curLen) (local.get $maxLen))
		;;handle reallocation
		(then
		  (call $str.extend (local.get $Offset))
		  (local.set $maxLen (i32.load (i32.add (i32.const 4)(local.get $Offset))))
		)
	)
	(local.set $dataOffset(i32.load (i32.add (i32.const 8)(local.get $Offset))))
	(i32.store8 (i32.add (local.get $curLen)(local.get $dataOffset))(local.get $C)) 
	(i32.store (local.get $Offset) (i32.add (local.get $curLen)(i32.const 1)));; new length
  ) 
  ;; Add a character to beginning of a string
  ;; Not multibyte character safe
  (func $str.LcatChar (param $strPtr i32)(param $Lchar i32)
	(local $cpos i32)(local $dataOff i32)(local $curC i32)
	;; first make room for the new character (should work for multibyte characters)
	;; tack it on at the end (it will get overwritten)
	(local.set $cpos (call $str.curLen (local.get $strPtr)))
	(call $str.catChar (local.get $strPtr)(local.get $Lchar))
	(local.set $dataOff (call $str.dataOff (local.get $strPtr)))
	(loop $cloop
		(i32.store8 (i32.add (local.get $dataOff)(local.get $cpos))
			(i32.load8_u (i32.sub (i32.add (local.get $dataOff)(local.get $cpos))(i32.const 1))))
		(local.set $cpos (i32.sub (local.get $cpos)(i32.const 1)))
		(br_if $cloop (i32.gt_s (local.get $cpos)(i32.const 0)))
	)
	(i32.store8 (local.get $dataOff)(local.get $Lchar))
  )
  ;; Return a new string without any leading $charToStrip's
  (func $str.stripLeading (param $strPtr i32)(param $charToStrip i32)(result i32)
	(local $spos i32)(local $curLen i32)(local $stripped i32)
	(local.set $spos (i32.const 0))
	(loop $strip
		;; $str.getChar returns Null if $spos goes out of bounds
		(if (i32.eq (local.get $charToStrip)(call $str.getChar (local.get $strPtr)(local.get $spos)))
		  (then
			(local.set $spos (i32.add (local.get $spos)(i32.const 1)))
			(br $strip)
		  )
		)
	)
	(local.set $curLen (call $str.curLen(local.get $strPtr)))
	(local.set $stripped (call $str.mk))
	(loop $copy
		(if (i32.lt_u (local.get $spos)(local.get $curLen))
		  (then
		    (call $str.catChar (local.get $stripped)
							   (call $str.getChar(local.get $strPtr)(local.get $spos)))
			(local.set $spos (i32.add (local.get $spos)(i32.const 1)))
			(br $copy)
		  )
		)
	)
	(local.get $stripped)
  )
  (func $main (export "_start")
	(local $sp i32)(local $rsp i32)(local $stripped i32)
	(local.set $sp (call $str.mkdata (global.get $Hello1Data)))
	(call $str.print (local.get $sp))
	;; test multiple cat's
	(local.set $sp (call $str.mk))
	(call $str.catChar (local.get $sp) (i32.const 65))
	(call $str.catChar (local.get $sp) (i32.const 66))
	(call $str.catChar (local.get $sp) (i32.const 67))
	(call $str.catChar (local.get $sp) (i32.const 68))
	(call $str.catChar (local.get $sp) (i32.const 69))
	(call $str.catChar (local.get $sp) (i32.const 70))
	(call $i32.print (call $str.dataOff (local.get $sp)))
	(local.set $rsp (call $str.Rev (local.get $sp)))
	(call $str.print (local.get $rsp))
	(call $str.catOntoStr (local.get $sp)(local.get $rsp))
	(call $str.print (local.get $sp))
	(call $str.LcatChar (local.get $sp)(i32.const 120)) ;; x
	(call $str.LcatChar (local.get $sp)(i32.const 120)) ;; x
	(call $str.print (local.get $sp))
	(local.set $stripped(call $str.stripLeading (local.get $sp)(i32.const 120)))
	(call $str.print (local.get $stripped))
  )
)

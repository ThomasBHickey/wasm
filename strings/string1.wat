;; run via "wasmtime string1.wat" 
;; or "wasmtime string1.wasm" if it has been compiled by wasm2wat
;; (wasmtime recognizes the func exported as "_start")
(module
  (import "wasi_unstable" "fd_read"  (func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1)
  (export "memory" (memory 0))
  (global $nextFreeMem (mut i32) (i32.const 1024))
  (global $zero i32 (i32.const 48))

  (data (i32.const 128) "Hello1\00") ;; null not part of string
  (global $Hello1Data i32 (i32.const 128))
  (data (i32.const 168) "Hello2\00")
  (global $Hello2Data i32 (i32.const 168))
  (data (i32.const 208) "Catted string:\00")
  (global $CattedData i32 (i32.const 208))
  (data (i32.const 228) "reallocating\00")
  (global $reallocating i32 (i32.const 228))
  (data (i32.const 248) "test1\00")
  (global $test1 i32 (i32.const 248))
  (data (i32.const 258) "test2\00")
  (global $test2 i32 (i32.const 258))
  (data (i32.const 268) "adding \00")
  (global $adding i32 (i32.const 268))
  (data (i32.const 278) "at \00")
  (global $at i32 (i32.const 278))

  ;; Simple memory allocation done in 4-byte chunks
  ;; Should this get cleared first? (or checked!)
  (func $getMem (param $size i32)(result i32)
	(local $size4 i32)
	(local.set $size4 
	  (i32.mul (i32.div_u 
	             (i32.add (local.get $size)(i32.const 3))
	           (i32.const 4))(i32.const 4)))
	(global.get $nextFreeMem) ;; to return
	(global.set $nextFreeMem (i32.add (global.get $nextFreeMem)(local.get $size4)))
  )
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
  (func $PtrDump (param $ptr i32)
	(call $C.print(i32.const 123)) ;; {
	   (call $i32.print (call $i32lst.getCurLen (local.get $ptr)))
	   (call $i32.print (call $i32lst.getMaxLen (local.get $ptr)))
	   (call $i32.print (call $i32lst.getDataOff (local.get $ptr)))
	(call $C.print(i32.const 125)) ;; }
  )
  (func $C.print (param $C i32)
	;; iovs start at 200, buffer at 300
	(i32.store (i32.const 200) (i32.const 300))
	(i32.store (i32.const 204) (i32.const 10))  ;; length of 10?
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
  ;; i32Lists
  ;; an i32lst pointer points at
  ;; a curLen, maxLen, data pointer, all i32
  ;; the list starts out with a maxLen of 1 (4 bytes)
  ;; which is allocated in the next i32 (16 bytes total)
  (func $i32.printMem (param $memOff i32)
	(call $i32.print (i32.load (local.get $memOff)))
  )
  (func $i32lst.mk (result i32)
	;; returns a memory offset for an i32lst pointer:
	;; 		curLength, maxLength, dataOffset
	(local $lstPtr i32)
	;; 12 for the pointer info, 4 for first int32
	(local.set $lstPtr (call $getMem (i32.const 16))) 
	(call $i32lst.setCurLen (local.get $lstPtr) (i32.const 0))
	(call $i32lst.setMaxLen (local.get $lstPtr)(i32.const 1))
	(call $i32lst.setDataOff(local.get $lstPtr)
		(i32.add(local.get $lstPtr)(i32.const 12))) ;; 12 bytes for the pointer
	(local.get $lstPtr)  ;; return ptr to the new list
  )
  (func $i32lst.getCurLen(param $lstPtr i32)(result i32)
	(i32.load (local.get $lstPtr))
  )
  (func $i32lst.setCurLen (param $lstPtr i32)(param $newLen i32)
	(i32.store (local.get $lstPtr)(local.get $newLen))
  )
  (func $i32lst.getMaxLen (param $lstPtr i32)(result i32)
    (i32.load (i32.add (local.get $lstPtr)(i32.const 4)))
  )
  (func $i32lst.setMaxLen (param $lstPtr i32)(param $newMaxLen i32)
    (i32.store (i32.add (local.get $lstPtr)(i32.const 4))(local.get $newMaxLen))
  )
  (func $i32lst.getDataOff (param $lstPtr i32)(result i32)
    (i32.load (i32.add (local.get $lstPtr)(i32.const 8)))
  )
  (func $i32lst.setDataOff (param $lstPtr i32)(param $newDataOff i32)
    (i32.store (i32.add (local.get $lstPtr)(i32.const 8))(local.get $newDataOff))
  )
  (func $i32lst.extend (param $lstPtr i32)
    ;; double the space available
	(local $maxLen i32) (local $curLen i32) (local $dataOff i32)
	(local $newMaxLen i32)(local $newDataOff i32)
	(local $cpos i32)
	;;(call $str.print (call $str.mkdata (global.get $reallocating)))
	;;(call $PtrDump (local.get $lstPtr))
	(local.set $curLen (call $i32lst.getCurLen (local.get $lstPtr)))
	(local.set $maxLen (call $i32lst.getMaxLen (local.get $lstPtr)))
	(local.set $dataOff   (call $i32lst.getDataOff (local.get $lstPtr)))
	(local.set $newMaxLen (i32.mul (local.get $maxLen)(i32.const 2)))
	(local.set $newDataOff (call $getMem (i32.mul (local.get $newMaxLen)(i32.const 4))))
	(call $i32lst.setMaxLen (local.get $lstPtr)(local.get $newMaxLen))
	(call $i32lst.setDataOff(local.get $lstPtr)(local.get $newDataOff))
	(memory.copy (local.get $newDataOff)(local.get $dataOff)
				 (i32.mul (local.get $curLen)(i32.const 4)))
	;;(call $PtrDump (local.get $lstPtr))
  ) 
  (func $i32lst.set@ (param $lstPtr i32)(param $pos i32)(param $val i32)
    (local $dataOff i32)(local $dataOffOff i32)
	(local.set $dataOff (call $i32lst.getDataOff (local.get $lstPtr)))
	;;(call $str.print (call $str.mkdata (global.get $adding)))
	;;(call $i32.print (local.get $val))
	(local.set $dataOffOff
		(i32.add (local.get $dataOff)
		  (i32.mul (call $i32lst.getCurLen (local.get $lstPtr))(i32.const 4))))
	;;(call $str.print (call $str.mkdata (global.get $at)))
	;;(call $i32.print (local.get $dataOffOff))
    (i32.store (local.get $dataOffOff) (local.get $val))
  )
  (func $i32lst.get@ (param $lstPtr i32)(param $pos i32)(result i32)
	(i32.load
		(i32.add (call $i32lst.getDataOff (local.get $lstPtr))
				 (i32.mul (i32.const 4) (local.get $pos))))
  )
  (func $i32lst.cat (param $lstPtr i32)(param $val i32)
	(local $maxLen i32) (local $curLen i32)(local $dataOffset i32)
	(local.set $curLen (call $i32lst.getCurLen(local.get $lstPtr)))
	(local.set $maxLen (call $i32lst.getMaxLen(local.get $lstPtr)))
	;;(call $C.print (i32.const 43))(call $i32.print (local.get $val))
	(if (i32.ge_u (local.get $curLen) (local.get $maxLen))
		;;handle reallocation
		(then
		  (call $i32lst.extend (local.get $lstPtr))
		  (local.set $maxLen (call $i32lst.getMaxLen(local.get $lstPtr)))
		))
	
	(local.set $dataOffset (call $i32lst.getDataOff (local.get $lstPtr)))
	(call $i32lst.set@ (local.get $lstPtr)(local.get $curLen)(local.get $val))
	;; (i32.store (i32.add (local.get $curLen)(local.get $dataOffset))(local.get $val))
	(call $i32lst.setCurLen (local.get $lstPtr)(i32.add (local.get $curLen)(i32.const 1)))
  )
  (func $i32lst.print (param $lstPtr i32)
	(local $curLength i32)
	;;(local $dataOffset i32)
	(local $ipos i32)
	(local.set $curLength (call $i32lst.getCurLen (local.get $lstPtr)))
	(local.set $ipos (i32.const 0))
	
	(call $C.print (i32.const 91)) ;; left bracket
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (call $i32lst.get@ (local.get $lstPtr)(local.get $ipos))
		 ;;(i32.load (i32.add (local.get $dataOffset)(local.get $ipos)))
		 (call $i32.print)   
	     (local.set $ipos (i32.add (local.get $ipos)(i32.const 1)))
	     (br $iLoop)
	)))
	(call $C.print (i32.const 93)) ;; right bracket
	(call $C.print (i32.const 10)) ;; new line
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
	(local.set $strPtr (call $getMem (i32.const 16)))
	(call $str.setCurLen (local.get $strPtr) (i32.const 0))
	(call $str.setMaxLen (local.get $strPtr)(i32.const 4))
	(call $str.setDataOff (local.get $strPtr)(i32.add(local.get $strPtr)(i32.const 12)))
	(local.get $strPtr)
  )
  (func $str.getCurLen (param $strPtr i32)(result i32)
	(i32.load (local.get $strPtr))
  )
  (func $str.setCurLen(param $strPtr i32)(param $newLen i32)
	(i32.store (local.get $strPtr) (local.get $newLen))
  )
  (func $str.getMaxLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 4)))
  )
  (func $str.setMaxLen(param $strPtr i32)(param $newMaxLen i32)
	(i32.store (i32.add(local.get $strPtr)(i32.const 4))(local.get $newMaxLen))
  )
  (func $str.getDataOff (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 8)))
  )
  (func $str.setDataOff (param $strPtr i32)(param $newDataOff i32)
    (i32.store (i32.add(local.get $strPtr)(i32.const 8))(local.get $newDataOff))
  )
  ;; Concatenate s2 onto s1
  (func $str.catOntoStr (param $s1Ptr i32)(param $s2Ptr i32)
	(local $c2pos i32)(local $s2curLen i32)
	(local.set $c2pos (i32.const 0))
	(local.set $s2curLen (call $str.getCurLen (local.get $s2curLen)))
	(loop $cloop
		(if (i32.lt_u (local.get $c2pos)(local.get $s2curLen))
		  (then
			(call $str.catChar(local.get $s1Ptr)(call $str.getChar (local.get $s2Ptr)(local.get $c2pos)))
			(local.set $c2pos (i32.add (local.get $c2pos)(i32.const 1)))
			(br $cloop)
		  )))		
  )
  ;; Returns a pointer to a new string with reversed characters
  (func $str.Rev (param $strPtr i32)(result i32)
	(local $cpos i32)(local $curLen i32)(local $revStrPtr i32)(local $curChar i32)
	(local.set $revStrPtr (call $str.mk))
	(local.set $cpos (i32.const 0))
	(local.set $curLen (call $str.getCurLen(local.get $strPtr)))
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
	(if (result i32) (i32.lt_u (local.get $charPos)(call $str.getCurLen (local.get $strPtr)) )
	  (then
		(i32.load8_u (i32.add (call $str.getDataOff (local.get $strPtr))(local.get $charPos)))
	  )
	  (else (i32.const 0))
	)
  )
  ;; Make a string from null-terminated chunk of memory
  (func $str.mkdata (param $dataOffset i32) (result i32)
	;; null terminator is not counted as part of string
	(local $length i32) (local $curByte i32)(local $strPtr i32)
	(local.set $length (i32.const 0))
	(loop $cLoop
		(local.set $curByte (i32.load8_u (i32.add (local.get $length)(local.get $dataOffset))))
		(if (i32.ne (i32.const 0)(local.get $curByte)) ;; checking for null
		  (then
		    (local.set $length (i32.add (local.get $length)(i32.const 1)))
			(br $cLoop)
	)))
	(local.set $strPtr (call $getMem (i32.const 12)))  ;; just room for pointer info
	(call $str.setCurLen (local.get $strPtr)(local.get $length))
	(call $str.setMaxLen (local.get $strPtr)(local.get $length))
	(call $str.setDataOff (local.get $strPtr)(local.get $dataOffset))
	(local.get $strPtr)
  )
  (func $str.print (param $strPtr i32)
	(local $curLength i32)
	(local $dataOffset i32)  ;; offset to string data
	(local $cpos i32)  ;; steps through character positions
	(local.set $curLength (call $str.getCurLen(local.get $strPtr)))
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
  (func $str.extend(param $strPtr i32)
	;; double the space available for characters
	;; move old data into new data
	;; update maxLen and data offset
	;; old space is abandoned, but future optimization could recognize
	;; if new space is adjacent and avoid moving old data
	(local $maxLen i32) (local $curLen i32) (local $dataOff i32)
	(local $newMaxLen i32)(local $newDataOff i32)
	(local $cpos i32)
	(local.set $curLen (call $str.getCurLen (local.get $strPtr)))
	(local.set $maxLen (call $str.getMaxLen (local.get $strPtr)))
	(local.set $dataOff   (call $str.getDataOff (local.get $strPtr)))
	(local.set $newMaxLen (i32.mul (local.get $maxLen)(i32.const 2)))
	;;(local.set $newDataOff (global.get $nextstrPtr))
	(local.set $newDataOff (call $getMem (local.get $newMaxLen)))
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
		))
	(local.set $dataOffset(i32.load (i32.add (i32.const 8)(local.get $Offset))))
	(i32.store8 (i32.add (local.get $curLen)(local.get $dataOffset))(local.get $C))
	(call $str.setCurLen(local.get $Offset) (i32.add (local.get $curLen)(i32.const 1)))
  ) 
  ;; Add a character to beginning of a string
  ;; Not multibyte character safe
  (func $str.LcatChar (param $strPtr i32)(param $Lchar i32)
	(local $cpos i32)(local $dataOff i32)(local $curC i32)
	;; first make room for the new character (should work for multibyte characters)
	;; tack it on at the end (it will get overwritten)
	(local.set $cpos (call $str.getCurLen (local.get $strPtr)))
	(call $str.catChar (local.get $strPtr)(local.get $Lchar))
	(local.set $dataOff (call $str.getDataOff (local.get $strPtr)))
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
		(if (i32.eq (local.get $charToStrip)
			(call $str.getChar (local.get $strPtr)(local.get $spos)))
		  (then
			(local.set $spos (i32.add (local.get $spos)(i32.const 1)))
			(br $strip)
		  )
		)
	)
	(local.set $curLen (call $str.getCurLen(local.get $strPtr)))
	(local.set $stripped (call $str.mk))
	(loop $copy
		(if (i32.lt_u (local.get $spos)(local.get $curLen))
		  (then
		    (call $str.catChar (local.get $stripped)
							   (call $str.getChar(local.get $strPtr)(local.get $spos)))
			(local.set $spos (i32.add (local.get $spos)(i32.const 1)))
			(br $copy)
		  )))
	(local.get $stripped)
  )
  (func $str.compare (param $s1ptr i32)(param $s2ptr i32)(result i32)  ;; return True if equal
	(local $s2len i32)(local $cpos i32)
	(local.set $s2len (call $str.getCurLen (local.get $s2ptr)))
	(if (i32.ne (call $str.getCurLen (local.get $s1ptr))(local.get $s2len))
	  (then (i32.const 0)(return))
	)
	(local.set $cpos (i32.const 0))
	;;(call $str.print (local.get $s1ptr))
	;;(call $str.print (local.get $s2ptr))
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $s2len))
		(then
			(if (i32.ne (call $str.getChar (local.get $s1ptr)(local.get $cpos))
						(call $str.getChar (local.get $s2ptr)(local.get $cpos)))
			(then (i32.const 0) (return)))
			(local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
			(call $i32.print(local.get $cpos))
			(br $cloop)
		)))
	(i32.const 1)(return)
  )
  (func $main (export "_start")
	(local $sp i32)(local $rsp i32)(local $stripped i32)
	(local $lstPtr i32)
	(local.set $sp (call $str.mkdata (global.get $Hello1Data)))
	;; test multiple cat's
	(local.set $sp (call $str.mk))
	(call $str.catChar (local.get $sp) (i32.const 65))
	(call $str.catChar (local.get $sp) (i32.const 66))
	(call $str.catChar (local.get $sp) (i32.const 67))
	(call $str.catChar (local.get $sp) (i32.const 68))
	(call $str.catChar (local.get $sp) (i32.const 69))
	(call $str.catChar (local.get $sp) (i32.const 70))
	;;(call $i32.print (call $str.getDataOff (local.get $sp)))
	(local.set $rsp (call $str.Rev (local.get $sp)))
	(call $str.print (local.get $rsp))
	(call $str.catOntoStr (local.get $sp)(local.get $rsp))
	;;(call $str.print (local.get $sp))
	(call $str.LcatChar (local.get $sp)(i32.const 120)) ;; x
	(call $str.LcatChar (local.get $sp)(i32.const 120)) ;; x
	;;(call $str.print (local.get $sp))
	(local.set $stripped(call $str.stripLeading (local.get $sp)(i32.const 120))) ;; x
	(call $str.print (local.get $stripped))
	(call $i32.print (call $str.compare (local.get $sp)(local.get $rsp)))
	(local.set $lstPtr (call $i32lst.mk))
	(call $str.print (call $str.mkdata (global.get $test1)))
	;;(call $PtrDump (local.get $lstPtr))
	;;(call $i32.print (local.get $lstPtr))
	(call $i32lst.cat (local.get $lstPtr) (i32.const 42))
	(call $i32lst.print(local.get $lstPtr))
	(call $i32lst.cat (local.get $lstPtr) (i32.const 43))
	(call $i32lst.print(local.get $lstPtr))
	(call $i32lst.cat (local.get $lstPtr) (i32.const 44))
	(call $i32lst.print(local.get $lstPtr))
	;;(call $str.print (call $str.mkdata (global.get $test2)))
	;;(call $PtrDump (local.get $lstPtr))

  )
  (func $test (export "_test")
	(local $sp i32)(local $lstPtr i32)
	(call $str.print (call $str.mkdata (global.get $test1)))
  )
)

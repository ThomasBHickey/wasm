;; io.m4
  _i32GlobalConst(`readIOVsOff0',`0')
  (global $readIOVsOff4 	i32  _4 )
  (global $readBuffOff 		i32  _8 )
  (global $readBuffLen 		i32  _4 )
  (global $writeIOVsOff0 	i32  _16 )
  (global $writeIOVsOff4 	i32 (i32.const 20))
  (global $writeBuffOff 	i32 (i32.const 24))
  (global $writeBufLen 		i32  _4 )
  (global $bytesRead		i32  _4 )
  (global $bytesWritten		(mut i32)  _0 )
  (func $io.initialize
  )
  (func $byte.print (param $B i32)
	(i32.store (global.get $writeIOVsOff0)(global.get $writeBuffOff))
	(i32.store (global.get $writeIOVsOff4) _1 )
	(i32.store
		(global.get $writeBuffOff)
		(local.get $B))
	(call $fd_write
		 _1  ;; stdout
		(global.get $writeIOVsOff0)
		 _1  ;; # iovs
		 _0  ;; length?
	)
	drop
	(global.set $bytesWritten (i32.add (global.get $bytesWritten) _1 ))
  )
  (func $byte.read (result i32)
	(local $nread i32)(local $rbyte i32)
	(i32.store (global.get $readIOVsOff0) (global.get $readBuffOff))
	(i32.store (global.get $readIOVsOff4)  _1 )
	(call $fd_read
	   _0  ;; 0 for stdin
	  (global.get $readIOVsOff0) ;; *iovs
	   _1  ;; iovs_len
	  (global.get $readIOVsOff4) ;; num bytes read goes here
	)
	drop  ;; $fd_read return value
	(local.set $nread (i32.load8_u (global.get $readIOVsOff4)))
	(if (i32.eqz (local.get $nread))
	  (return (global.get $maxNeg)))
	(return (i32.load8_u (global.get $readBuffOff)))
  )
  (func $print (param $ptr i32)
    ;; 'Universal' print function
	(local $oldCurMemUsed i32)
	(local.set $oldCurMemUsed (global.get $curMemUsed))
    (call $str.print (call $toStr (local.get $ptr)))
 	(call $reclaimMem (local.get $oldCurMemUsed))
 )
  (func $printwsp (param $ptr i32)
	(call $print (local.get $ptr))
	(call $printsp)
  )
  (func $printsp (call $byte.print _SP))
  (func $printlf (call $byte.print _LF))
  (func $printwlf (param $ptr i32)
	(call $print (local.get $ptr))
	(call $printlf)
  )
  ;; print out ASCII of byte or a period if not printable
  (func $isASCII (param $byte i32)(result i32)
	(if (i32.ge_u (local.get $byte) _SP)
	  (then (if (i32.le_u (local.get $byte)_CHAR(`~'))
	    (then (return _1)))))
	(return _0)
  )
  (func $byte.dump (param $byte i32)  ;; display memory as text
    (local.set $byte (i32.and (local.get $byte)(i32.const 0xFF)))
	(if (call $isASCII (local.get $byte))
	  (then	(call $byte.print (local.get $byte)))
	  (else	(call $byte.print _CHAR(`.'))))
  )
  (func $i32.hexprint (param $N i32)
	(call $byte.print _CHAR(`0'))
	(call $byte.print _CHAR(`x')) ;; 'x'
	(call $i32.hexprintsup (local.get $N))
	(call $byte.print _SP)  ;; space
  )
  (func $i32.hexprintsup (param $n i32)
    (call $byte.hexprint (i32.shr_u (local.get $n)(i32.const 24)))
    (call $byte.hexprint (i32.shr_u (local.get $n) _16 ))
    (call $byte.hexprint (i32.shr_u (local.get $n) _8 ))
    (call $byte.hexprint (local.get $n))
  )
  (func $i64.hexprint (param $N i64)
	(call $byte.print _CHAR(`0'))
	(call $byte.print _CHAR(`x')) ;; 'x'
	(call $i64.hexprintsup (local.get $N))
	(call $byte.print _SP)  ;; space
  )
  (func $i64.hexprintsup (param $n i64)
    (call $byte.hexprint64 (i64.shr_u (local.get $n)(i64.const 56)))
    (call $byte.hexprint64 (i64.shr_u (local.get $n)(i64.const 48)))
    (call $byte.hexprint64 (i64.shr_u (local.get $n)(i64.const 40)))
    (call $byte.hexprint64 (i64.shr_u (local.get $n)(i64.const 32)))
    (call $byte.hexprint64 (i64.shr_u (local.get $n)(i64.const 24)))
    (call $byte.hexprint64 (i64.shr_u (local.get $n)(i64.const 16)))
    (call $byte.hexprint64 (i64.shr_u (local.get $n)(i64.const  8)))
    (call $byte.hexprint64 (local.get $n))
  )
  (func $byte.hexprint64 (param $byte64 i64)
    (local $byte i32)
	(local.set $byte (i32.wrap/i64 (local.get $byte64)))
	(call $byte.hexprint (local.get $byte))
  )
  (func $byte.hexprint (param $byte i32)
    (local.set $byte (i32.and (local.get $byte)(i32.const 0xff)))
	(call $nibble.hexprint (i32.shr_u (local.get $byte) _4 ))
	(call $nibble.hexprint (i32.and (i32.const 0xF)(local.get $byte)))
  )
  (func $nibble.hexprint (param $nibble i32)
	(local.set $nibble (i32.and (local.get $nibble)(i32.const 0xf)))
	(if (i32.lt_u (local.get $nibble)(i32.const 10))
	  (then
		(call $byte.print (i32.add _CHAR(`0')(local.get $nibble))))
	  (else
		(call $byte.print(i32.add (i32.const 55)(local.get $nibble))))) ;; 55=='A'-10
  )
  (func $str.read (result i32)
	(local $strPtr i32)
	(local $byte i32)
	(local.set $strPtr (call $str.mk))
	(loop $bloop
	  (local.set $byte (call $byte.read))
	  (if (i32.ge_s (local.get $byte) _0)
		(then
		  (if (i32.eq (local.get $byte) _LF)
			(return (local.get $strPtr)))
		  (call $str.catByte(local.get $strPtr)(local.get $byte))
		  (br $bloop)
		)
	  )
	  (if (i32.eq (local.get $byte)(global.get $maxNeg))
	    (then
		  (if (call $str.getByteLen (local.get $strPtr))
			(return (local.get $strPtr)))
		  (return _maxNeg)
		)
	  )
	)
	(local.get $strPtr)
  )
  ;; Clear passed string before reading line into it
  (func $str.readIntoStr (param $strPtr i32)(result i32)
    (call $str.setByteLen (local.get $strPtr) _0)
	(call $str.readOntoStr (local.get $strPtr))
  )
  ;; Add bytes up to LF to passed string
  ;; Returns eol terminator (LF or $maxNeg)
  (func $str.readOntoStr (param $strPtr i32)(result i32)
	(local $byte i32)
	(loop $bloop
	  (local.set $byte (call $byte.read))
	  (if (i32.ge_s (local.get $byte) _0)
		(then
		  (if (i32.eq (local.get $byte) _LF)
			(return _LF))
		  (if (i32.ne (local.get $byte) _CR);; skip over carriage returns!
			(call $str.catByte(local.get $strPtr)(local.get $byte)))
		  (br $bloop)
		)
		(else
		  (return _maxNeg)
		)
	  )
	)
	(return _maxNeg)
  )
  (func $readFileAsStrings (result i32)
	;; reads a file in byte-by-byte and returns a list of string pointers to the lines in it
	(local $listPtr i32)(local $strPtr i32)
	(local.set $listPtr (call $i32list.mk))
	(loop $lineLoop
	  (local.set $strPtr (call $str.read))
	  (if
		(i32.eq
		  (local.get $strPtr)
		  (global.get $maxNeg))
		(return (local.get $listPtr)))
	  (call $i32list.push (local.get $listPtr) (local.get $strPtr))
	  (br $lineLoop)
	)
	(return (local.get $listPtr))
  )
  (func $readFileAsMatrix (result i32)
	(local $matrix i32)(local $row i32)
	(local $line i32)(local $lineTerm i32)
	(local.set $line (call $str.mk))
	(local.set $matrix (call $i32Mtrx.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (if (call $str.getByteLen(local.get $line))
		(then
		  (local.set $row (call $strToInt32s (local.get $line)))
		  (call $i32Mtrx.addRow (local.get $matrix)(local.get $row))
		  (br $lineLoop)
		)
	  )
	)
	(local.get $matrix)
  )
	  


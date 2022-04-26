;; io.m4
  (func $io.initialize
  )
  (func $byte.print (param $B i32)
	(i32.store (global.get $writeIOVsOff0)(global.get $writeBuffOff))
	(i32.store (global.get $writeIOVsOff4)(i32.const 1))
	(i32.store
		(global.get $writeBuffOff)
		(local.get $B))
	(call $fd_write
		(i32.const 1) ;; stdout
		(global.get $writeIOVsOff0)
		(i32.const 1) ;; # iovs
		(i32.const 0) ;; length?
	)
	drop
	(global.set $bytesWritten (i32.add (global.get $bytesWritten)(i32.const 1)))
  )
  (func $byte.read (result i32)
	(local $nread i32)(local $rbyte i32)
	(i32.store (global.get $readIOVsOff0) (global.get $readBuffOff))
	(i32.store (global.get $readIOVsOff4) (i32.const 1))
	(call $fd_read
	  (i32.const 0) ;; 0 for stdin
	  (global.get $readIOVsOff0) ;; *iovs
	  (i32.const 1) ;; iovs_len
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
	(local $nextFreeMem i32)
	(local.set $nextFreeMem (global.get $curMemUsed))
    ;;(call $str.print (call $toStr (local.get $ptr)))
    (call $str.print (local.get $ptr))  ;; needs to call $toStr first!!!!
 	;;(call $reclaimMem (local.get $nextFreeMem))
 )
  (func $printsp (call $byte.print _SP))
  (func $printlf (call $byte.print _LF))
  (func $printwlf (param $ptr i32)
	(call $str.print (local.get $ptr))  ;; was just $print
	(call $printlf)
  )
  (func $nibble.hexprint (param $nibble i32)
	(if (i32.lt_u (local.get $nibble)(i32.const 10))
	  (then
		(call $byte.print (i32.add _CHAR(`0')(local.get $nibble))))
	  (else
		(call $byte.print(i32.add (i32.const 55)(local.get $nibble))))) ;; 55=='A'-10
  )
  (func $byte.hexprint (param $byte i32)
	(call $nibble.hexprint (i32.shr_u (local.get $byte)(i32.const 4)))
	(call $nibble.hexprint (i32.and (i32.const 0xF)(local.get $byte)))
  )
  ;; print out ASCII of byte or a period if not printable
  (func $isASCII (param $byte i32)(result i32)
	(if (i32.ge_u (local.get $byte) _SP)
	  (then (if (i32.le_u (local.get $byte)_CHAR(`~'))
	    (then (return _1)))))
	(return _0)
  )
  (func $byte.dump (param $byte i32)
    (local.set $byte (i32.and (local.get $byte)(i32.const 0xFF)))
	(if (call $isASCII (local.get $byte))
	  (then	(call $byte.print (local.get $byte)))
	  (else	(call $byte.print _CHAR(`.'))))
  )
  ;; needs to pad to 8 bytes with 0's
  (func $i32.hexprint (param $N i32)
	(call $byte.print _CHAR(`0'))
	(call $byte.print _CHAR(`x')) ;; 'x'
	(call $i32.hexprintsup (local.get $N))
	(call $byte.print _SP)  ;; space
  )
  (func $i32.hexprintsup (param $n i32)
    (call $byte.hexprint (i32.shr_u (local.get $n)(i32.const 24)))
    (call $byte.hexprint (i32.shr_u (local.get $n)(i32.const 16)))
    (call $byte.hexprint (i32.shr_u (local.get $n)(i32.const 8)))
    (call $byte.hexprint (local.get $n))
  )
  (func $str.read (result i32)
	(local $strPtr i32)
	(local $byte i32)
	(local.set $strPtr (call $str.mk))
	(loop $bloop
	  (local.set $byte (call $byte.read))
	  (if (i32.ge_s (local.get $byte)(i32.const 0))
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
		  (return (global.get $maxNeg))
		)
	  )
	)
	(local.get $strPtr)
  )

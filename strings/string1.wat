;; run via "wasmtime run string1.wat" 
;; (wasmtime recognizes the func exported as "_start")
;; or "wasmtime string1.wasm" if it has been compiled by
;; "wat2wasm --enable-bulk-memory string1.wat"
;; run tests: "wasmtime run string1.wat --invoke _test"
(module
  (import "wasi_unstable" "fd_read"
	(func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write"
	(func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1)
  (export "memory" (memory 0))

  ;; test function signatures
  (type $testSig (func (param i32)(result i32)))
  
  ;; comparison func signatures used by map
  (type $keyCompSig (func (param i32)(param i32)(result i32)))
  (type $keytoStrSig (func (param i32)(result i32)))

  (table 25 funcref)  ;; must be >= to length of elem
  (elem (i32.const 0)
    $str.compare			;;0
	$str.toStr				;;1
	$i32.compare			;;2
	$i32.toStr				;;3

	$i32list.sets.test		;;1 + 3 = $firstTestOffset
	$str.catByte.test		;;2
	$str.catStr.test		;;3
	$str.cat2Strings.test	;;4
	$str.Rev.test			;;5
	$str.mkdata.test		;;6
	$str.getByte.test		;;7
	$i32list.push.test		;;8
	$str.stripLeading.test	;;9
	$str.compare.test		;;10
	$str.Csplit.test		;;11
	$str.find.test			;;12
	$str.catChar.test		;;13
	$match.test				;;14
	$str.mkslice.test		;;15
	$str.getLastByte.test	;;16
	$map.test				;;17
    $i32list.mk.test		;;18
	$str.drop.test			;;19
	$typeNum.toStr.test		;;20
	$misc.test				;;21
  )
  (global $numTests i32 (i32.const 21)) ;; should match # tests in table
  (global $firstTestOffset 	i32 (i32.const 4))
  (global $strCompareOffset i32 (i32.const 0))
  (global $strToStrOffset	i32 (i32.const 1))
  (global $i32CompareOffset i32 (i32.const 2))
  (global $i32ToStrOffset	i32 (i32.const 3))
  (global $readIOVsOff0 	i32 (i32.const 100))
  (global $readIOVsOff4 	i32 (i32.const 104))
  (global $readBuffOff 		i32 (i32.const 200))
  (global $readBuffLen 		i32 (i32.const 2000))
  (global $writeIOVsOff0 	i32 (i32.const 2300))
  (global $writeIOVsOff4 	i32 (i32.const 2304))
  (global $writeBuffOff 	i32 (i32.const 2400))
  (global $writeBufLen 		i32 (i32.const 512))
  (global $nextFreeMem (mut i32)(i32.const 4096))
  (global $firstFreeMem 	i32 (i32.const 4096))
  (global $maxFreeMem  (mut i32)(i32.const 4096)) ;; same as initial $firstFreeMem
  (global $memReclaimed(mut i32)(i32.const 0))
  
  (func $showMemUsedHelper (param $numBytes i32)(param $msg i32)
    (call $str.print (local.get $msg))
	(call $i32.print (local.get $numBytes))(call $printsp)
	(call $byte.print (global.get $LPAREN))
	(call $i32.print
	  (i32.shr_u (local.get $numBytes) (global.get $LF)))
	(call $C.print (i32.const 75)) ;; K
	(call $C.print (global.get $RPAREN))
	(call $C.print (global.get $LF))
  )
  (func $showMemUsed 
    (local $bytesUsed i32)
	(local $memUsedMsg i32)
	(local $maxUsedMsg i32)
	(local $memReclaimedMsg i32)
	(local $maxUsed i32)
	(local.set $memUsedMsg (call $str.mkdata (global.get $gCurMemUse)))
	(local.set $maxUsedMsg (call $str.mkdata (global.get $gMaxUsed)))
	(local.set $memReclaimedMsg (call $str.mkdata (global.get $gMemReclaimed)))
	(local.set $bytesUsed
	  (i32.sub
		(global.get $nextFreeMem)
		(global.get $firstFreeMem)))
	(call $showMemUsedHelper (local.get $bytesUsed)(local.get $memUsedMsg))
	(local.set $bytesUsed
	  (i32.sub
		(global.get $maxFreeMem)
		(global.get $firstFreeMem)))
	(call $showMemUsedHelper (local.get $bytesUsed)(local.get $maxUsedMsg))
	(call $showMemUsedHelper (global.get $memReclaimed)(local.get $memReclaimedMsg))
  )
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
  (func $reclaimMem (param $newNextFreeMem i32)
  ;; A simple way to reclaim memory
  ;; Resets where new mem is allocated and clears the reclaimed words
    (local $reclaimedBytes i32)
	(local $reclaimedWords i32)
	(local $wordToClear i32)
	(local $oldNextFreeMem i32)
	(if (i32.gt_u (local.get $newNextFreeMem)(global.get $nextFreeMem))
		(call $error2))
	;; check for i32 word alignment
	(if (i32.and (local.get $newNextFreeMem)(i32.const 3))
	  (call $error3 (i32.const 32)))
	(local.set $oldNextFreeMem (global.get $nextFreeMem))
	(if (i32.and (local.get $oldNextFreeMem)(i32.const 3))
	  (call $error3 (i32.const 33)))
	(local.set $reclaimedBytes
	  (i32.sub (global.get $nextFreeMem)(local.get $newNextFreeMem)))
	(global.set $memReclaimed
	  (i32.add (global.get $memReclaimed)(local.get $reclaimedBytes)))
	(local.set $wordToClear (local.get $newNextFreeMem))
	(loop $clearLoop
	  (if (i32.lt_u
		(local.get $wordToClear)
		(local.get $oldNextFreeMem))
		(then
		  (i32.store (local.get $wordToClear)(i32.const 0))
		  (local.set $wordToClear (i32.add (local.get $wordToClear)(i32.const 4)))
		  (br $clearLoop))))
	(global.set $nextFreeMem (local.get $newNextFreeMem))
  )
  (func $error (result i32)
	;; throw a divide-by-zero exception!
	(i32.div_u (i32.const 1)(i32.const 0))
  )
  (func $error2
    (local $t i32)
    (local.set $t (i32.div_u (i32.const 1)(i32.const 0)))
  )
  (func $error3 (param $err i32)
	(call $i32.print (local.get $err))
	(call $error2)
  )
  (func $print (param $ptr i32)
    ;; 'Universal' print function
    (call $str.print (call $toStr (local.get $ptr)))
  )
  (func $printlf (call $byte.print (global.get $LF)))
  (func $printsp (call $byte.print (global.get $SP)))
  
  (func $toStr (param $ptr i32)(result i32)
    (local $strPtr i32)
    (if
	  (i32.and
		(i32.ge_u (local.get $ptr)(global.get $firstFreeMem))
		(i32.lt_u (local.get $ptr)(global.get $nextFreeMem)))
	  (return (call $ptr.toStr (local.get $ptr))))
	(if
	  (i32.and
		(i32.ge_u (local.get $ptr)(global.get $gAAA))
		(i32.le_u (local.get $ptr)(global.get $gZZZ)))
		(then
		  (local.set $strPtr (call $i32.toStr (local.get $ptr)))
		  (call $str.catsp (local.get $strPtr))
		  (call $str.catByte (local.get $strPtr)(global.get $LPAREN))
		  (call $str.catByte (local.get $strPtr)(global.get $DBLQUOTE))
		  (call $str.catStr (local.get $strPtr)(call $str.mkdata(local.get $ptr)))
		  (call $str.catByte (local.get $strPtr)(global.get $DBLQUOTE))
		  (call $str.catByte (local.get $strPtr)(global.get $RPAREN))
		  (return (local.get $strPtr))))
	(call $i32.toStr (local.get $ptr))
  )
  (func $typeNum.toStr (param $typeNum i32)(result i32)
    (local $strptr i32)
	(local.set $strptr (call $str.mk))
    (call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 24)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 16)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 8)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 0)))
	(local.get $strptr)  ;;return the new string
  )
  (func $typeNum.toStr.test (param $testNum i32)(result i32)
	(i32.eqz
	  (call $str.compare
		(call $typeNum.toStr (global.get $i32L)) ;; i32 value
		(call $str.mkdata (global.get $gi32L))))	;; null terminated string
  )
  (func $ptr.toStr (param $ptr i32)(result i32)
    (local $type i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(local.set $type (call $getTypeNum (local.get $ptr)))
	(if (i32.eq (local.get $type)(global.get $BStr))
	  (return (local.get $ptr)))
	(if (i32.eq (local.get $type)(global.get $i32L))
	  (call $str.catStr 
		  (local.get $strPtr)
		  (call $i32list.toStr (local.get $ptr)))
	  (return (local.get $strPtr)))
	(if (i32.eq (local.get $type)(global.get $Map))
	  (call $str.catStr (local.get $strPtr)(call $map.toStr (local.get $ptr)))
	  (return (local.get $strPtr)))
	(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gUnableToPrint)))
	(local.get $strPtr)
  )
  (func $byte.print.repeat (param $byte i32)(param $rep i32)
	(local $bc i32)
	(local.set $bc (i32.const 0))
	(loop $ploop
	  (if (i32.lt_u (local.get $bc)(local.get $rep))
		(then
		  (call $byte.print(local.get $byte))
		  (local.set $bc (i32.add (local.get $bc)(i32.const 1)))
		  (br $ploop))))
  )
  (func $i32.print (param $N i32)
  ;; Still doesn't recognize negatives
	(if (i32.ge_u (local.get $N)(i32.const 10))
	  (then (call $i32.print (i32.div_u (local.get $N)(i32.const 10)))))
	(call $byte.print
	  (i32.add
		(i32.rem_u (local.get $N)(i32.const 10))
		(global.get $zero)))
  )
  (func $i32.toStr (param $N i32)(result i32)
	;; return a string representing an i32
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $i32.toStrHelper (local.get $strPtr)(local.get $N))
	(local.get $strPtr)
  )
  (func $i32.toStrHelper(param $strPtr i32)(param $N i32)
    (if (i32.ge_u (local.get $N)(i32.const 10))
	  (call $i32.toStrHelper
		(local.get $strPtr)
		(i32.div_u (local.get $N)(i32.const 10))))
	(call $str.catByte (local.get $strPtr)
	  (i32.add
		(i32.rem_u (local.get $N)(i32.const 10))
		(global.get $zero)))
  )
 (func $i32.hexprint (param $N i32)
	(call $byte.print (global.get $zero))
	(call $byte.print (i32.const 120)) ;; 'x'
	(call $i32.hexprintsup (local.get $N))
	(call $byte.print (global.get $SP))  ;; space
  )
  (func $i32.hexprintsup (param $N i32)
    ;; support for $i32.hexprint
    (local $rem i32)
	(if (i32.ge_u (local.get $N)(i32.const 16))
	  (then (call $i32.hexprintsup (i32.div_u (local.get $N)(i32.const 16)))))
	(local.set $rem (i32.rem_u (local.get $N)(i32.const 16)))
	(if (i32.lt_s (local.get $rem) (i32.const 10))
	  (then
		(call $byte.print
		  (i32.add
			(local.get $rem)
			(global.get $zero))))
	  (else
		(call $byte.print
		  (i32.add
			(local.get $rem)
			(i32.const 55)))))  ;; 'A'-10
  )
  (func $PtrDump (param $ptr i32)
	(call $byte.print(global.get $LBRACE))
	  (call $i32.print (local.get $ptr))
	  (call $i32.print (call $i32list.getCurLen (local.get $ptr)))
	  (call $i32.print (call $i32list.getMaxLen (local.get $ptr)))
	  (call $i32.print (call $i32list.getDataOff (local.get $ptr)))
	(call $byte.print(global.get $RBRACE))
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
  )
  (func $C.print (param $C i32)
  ;; Print a utf-8 character
    (local $bp i32)
	;; First a little optimization: pass through single byte char's
	(if (i32.eqz (i32.and (i32.const 0xFFFFFF00)(local.get $C)))
	  (return (call $byte.print (local.get $C)))) ;; single byte character
	(local.set $bp (i32.const 4))  ;; keeps track of bytes to print
	(loop $zbloop
	  (if (i32.eqz (i32.and (i32.const 0xFF000000)(local.get $C))) ;; leading zero byte?
		(then
		  (local.set $bp (i32.sub (local.get $bp)(i32.const 1)))
		  (local.set $C (i32.shl (local.get $C)(i32.const 8)))
		  (br $zbloop)
		  )))
	(loop $ploop
	  (call $byte.print (i32.shr_u (local.get $C)(i32.const 24))) ;;high order byte
	  (local.set $C (i32.shl (local.get $C)(i32.const 8)))
	  (local.set $bp (i32.sub (local.get $bp)(i32.const 1)))
	  (if (local.get $bp)
		(br $ploop)))
  )	
  (func $Test.printTest
    (call $byte.print (i32.const  84)) ;; T
	(call $byte.print (i32.const 101)) ;; e
	(call $byte.print (i32.const 115)) ;; s
	(call $byte.print (i32.const 116)) ;; t
	(call $byte.print (global.get $SP)) ;; space
  )
  (func $Test.show (param $testNum i32)(param $testResult i32)
	(local $adjTestNum i32)
	(local.set $adjTestNum
	  (i32.add
		(i32.const 1)
		(i32.sub
		  (local.get $testNum)
		  (global.get $firstTestOffset))))
	(if (local.get $testResult)
	  (then
	    (call $Test.showFailed
		  (local.get $adjTestNum)
		  (local.get $testResult)))
	  (else
		(call $Test.showOK (local.get $adjTestNum))))
  )
  (func $Test.showOK (param $testnum i32)
    (call $Test.printTest)
	(call $i32.print (local.get $testnum))
	(call $byte.print (global.get $SP))
	(call $byte.print (i32.const 79)) ;; O
	(call $byte.print (i32.const 75)) ;; K
	(call $byte.print (global.get $LF))
  )
  (func $Test.showFailed (param $testnum i32)(param $testResult i32)
    (call $Test.printTest)
	(call $i32.print (local.get $testnum))
	(call $byte.print (global.get $SP))
	(call $byte.print (i32.const 78)) ;; N
	(call $byte.print (i32.const 79)) ;; O
	(call $byte.print (i32.const 75)) ;; K
	(call $byte.print (global.get $BANG))
	(call $byte.print (global.get $BANG))
	(call $byte.print (global.get $BANG))
	(call $byte.print (global.get $SP))
	(call $i32.print (local.get $testResult))
	(call $byte.print (i32.const 10)) ;; linefeed
	)
  (func $test (export "_test")
	;; Run tests: wasmtime run strings/string1.wat --invoke _test
	(local $testOff i32)
	(local $lastTestOff i32)
	(local $nextFreeMem i32)
	(local.set $nextFreeMem (global.get $nextFreeMem))
	(local.set $testOff (global.get $firstTestOffset))
	(local.set $lastTestOff
	  (i32.sub
		(i32.add (local.get $testOff)(global.get $numTests))
		(i32.const 1)))
	(loop $testLoop  ;; assumes there is a least one test
	  (local.get $testOff)
	  (call $Test.show
		(local.get $testOff)
		(call_indirect
		  (type $testSig)
		  (local.get $testOff)))
	  (local.set $testOff (i32.add (local.get $testOff)(i32.const 1)))
	  (if (i32.le_u (local.get $testOff)(local.get $lastTestOff))
	    (then (br $testLoop))))
	(call $reclaimMem (local.get $nextFreeMem))
	;;(call $showMemUsed)
  )

  ;; i32Lists
  ;; an i32list pointer points at
  ;; a typeNum, curLen, maxLen, data pointer, all i32
  ;; the list starts out with a maxLen of 1 (4 bytes)
  ;; which is allocated in the next i32 (20 bytes total)
  (func $i32.printMem (param $memOff i32)
	(call $i32.print (i32.load (local.get $memOff)))
  )
  (func $i32list.mk (result i32)
	;; returns a memory offset for an i32list pointer:
	;; 		typeNum, curLength, maxLength, dataOffset
	(local $lstPtr i32)
	(local.set $lstPtr (call $getMem (i32.const 20))) 
	;; 4 bytes for type, 12 for the pointer info, 4 for first int32
	(call $setTypeNum (local.get $lstPtr)(global.get $i32L))
	(call $i32list.setCurLen (local.get $lstPtr) (i32.const 0))
	(call $i32list.setMaxLen (local.get $lstPtr)(i32.const 1))
	(call $i32list.setDataOff(local.get $lstPtr)
		(i32.add(local.get $lstPtr)(i32.const 16))) ;; 16 bytes for header info
	(local.get $lstPtr)  ;; return ptr to the new list
  )
  (func $i32list.mk.test (param $testNum i32)(result i32)
	(local $lstPtr i32)
	(local.set $lstPtr (call $i32list.mk))
	(if (i32.ne 
		  (call $getTypeNum (local.get $lstPtr))
		  (global.get $i32L))
	  (return (i32.const 1)))
	(if (call $i32list.getCurLen (local.get $lstPtr)) ;; should be False
		  (return (i32.const 2)))
	(i32.const 0) ;; OK
  )
  (func $getTypeNum(param $ptr i32)(result i32)
	(i32.load (local.get $ptr))
  )
  (func $setTypeNum(param $ptr i32)(param $typeNum i32)
	(i32.store (local.get $ptr)(local.get $typeNum))
  )
  (func $i32list.getCurLen(param $lstPtr i32)(result i32)
	(i32.load (i32.add (local.get $lstPtr)(i32.const 4)))
  )
  (func $i32list.setCurLen (param $lstPtr i32)(param $newLen i32)
	(i32.store (i32.add (local.get $lstPtr)(i32.const 4))(local.get $newLen))
  )
  (func $i32list.getMaxLen (param $lstPtr i32)(result i32)
    (i32.load (i32.add (local.get $lstPtr)(i32.const 8)))
  )
  (func $i32list.setMaxLen (param $lstPtr i32)(param $newMaxLen i32)
    (i32.store (i32.add (local.get $lstPtr)(i32.const 8))(local.get $newMaxLen))
  )
  (func $i32list.getDataOff (param $lstPtr i32)(result i32)
    (i32.load (i32.add (local.get $lstPtr)(i32.const 12)))
  )
  (func $i32list.setDataOff (param $lstPtr i32)(param $newDataOff i32)
    (i32.store (i32.add (local.get $lstPtr)(i32.const 12))(local.get $newDataOff))
  )
  (func $i32list.sets.test (param $testNum i32) (result i32)
	(local $lstPtr i32)
	(local.set $lstPtr (call $i32list.mk))
	(call $i32list.setCurLen (local.get $lstPtr)(i32.const 37))
	(call $i32list.setMaxLen (local.get $lstPtr)(i32.const 38))
	(call $i32list.setDataOff (local.get $lstPtr)(i32.const 39))
	(if (i32.ne (call $getTypeNum (local.get $lstPtr))(global.get $i32L))
		(return (i32.const 1)))
	(if (i32.ne (call $i32list.getCurLen (local.get $lstPtr))(i32.const 37))
		(return (i32.const 2)))
	(if (i32.ne (call $i32list.getMaxLen (local.get $lstPtr))(i32.const 38))
		(return (i32.const 3)))
	(if (i32.ne (call $i32list.getDataOff (local.get $lstPtr))(i32.const 39))
		(return (i32.const 4)))
	(i32.const 0)
  )
  (func $i32list.extend (param $lstPtr i32)
    ;; double the space available
	(local $maxLen i32) (local $curLen i32) (local $dataOff i32)
	(local $newMaxLen i32)(local $newDataOff i32)
	(local $cpos i32)
	(local.set $curLen (call $i32list.getCurLen (local.get $lstPtr)))
	(local.set $maxLen (call $i32list.getMaxLen (local.get $lstPtr)))
	(local.set $dataOff   (call $i32list.getDataOff (local.get $lstPtr)))
	(local.set $newMaxLen (i32.mul (local.get $maxLen)(i32.const 2)))
	(local.set $newDataOff (call $getMem (i32.mul (local.get $newMaxLen)(i32.const 4))))
	(call $i32list.setMaxLen (local.get $lstPtr)(local.get $newMaxLen))
	(call $i32list.setDataOff(local.get $lstPtr)(local.get $newDataOff))
	(memory.copy (local.get $newDataOff)(local.get $dataOff)
				 (i32.mul (local.get $curLen)(i32.const 4)))
  ) 
  (func $i32list.set@ (param $lstPtr i32)(param $pos i32)(param $val i32)
	;; Needs bounds tests
    (local $dataOff i32)
	(local $dataOffOff i32)
	(local.set $dataOff (call $i32list.getDataOff (local.get $lstPtr)))
	(local.set $dataOffOff
		(i32.add (local.get $dataOff)
		  (i32.mul (local.get $pos)(i32.const 4))))
    (i32.store (local.get $dataOffOff) (local.get $val))
  )
  (func $i32list.get@ (param $lstPtr i32)(param $pos i32)(result i32)
	;; Needs bounds test
	(i32.load
		(i32.add (call $i32list.getDataOff (local.get $lstPtr))
				 (i32.mul (i32.const 4) (local.get $pos))))
  )
  (func $i32list.push (param $lstPtr i32)(param $val i32)
	(local $maxLen i32) (local $curLen i32);;(local $dataOffset i32)
	(local.set $curLen (call $i32list.getCurLen(local.get $lstPtr)))
	(local.set $maxLen (call $i32list.getMaxLen(local.get $lstPtr)))
	(if (i32.ge_u (local.get $curLen) (local.get $maxLen));;handle reallocation
		(then
		  (call $i32list.extend (local.get $lstPtr))
		  (local.set $maxLen (call $i32list.getMaxLen(local.get $lstPtr)))
		))
	;;(local.set $dataOffset (call $i32list.getDataOff (local.get $lstPtr)))
	(call $i32list.set@ (local.get $lstPtr)(local.get $curLen)(local.get $val))
	(call $i32list.setCurLen (local.get $lstPtr)
		(i32.add (local.get $curLen)(i32.const 1)))
  )
  (func $i32list.pop (param $lstPtr i32)(result i32)
    (local $curLen i32)(local $lastPos i32)(local $popped i32)
	(local.set $curLen (call $i32list.getCurLen(local.get $lstPtr)))
	(if (i32.eqz (local.get $curLen))
	  (return (call $error)))
	(local.set $lastPos (i32.sub (local.get $curLen)(i32.const 1)))
	(local.set $popped (call $i32list.get@
	    (local.get $lstPtr)(local.get $lastPos)))
	(call $i32list.setCurLen
	  (local.get $lstPtr)
	  (local.get $lastPos))
	(local.get $popped)
  )
  (func $i32list.push.test (param $testNum i32)(result i32)
    (local $lstPtr i32)(local $temp i32)
	(local.set $lstPtr (call $i32list.mk))
	(call $i32list.push (local.get $lstPtr) (i32.const 3))
	(if (i32.ne
	  (i32.const 1)
	  (call $i32list.getCurLen (local.get $lstPtr)))
	  (return (i32.const 1)))
	(local.set $temp (call $i32list.pop (local.get $lstPtr)))
	(if (i32.ne (i32.const 3) (local.get $temp))
	  (return (i32.const 2)))
	(if (i32.ne
	  (i32.const 0)
	  (call $i32list.getCurLen (local.get $lstPtr)))
	  (return (i32.const 3)))
	(i32.const 0) ;; passed
  )
  (func $i32list.toStr (param $lstPtr i32)(result i32)
	;; check if first entry is a TypeNum
	(local $strPtr i32)
	(local $strTmp i32)
	(local $curLength i32)
	(local $ipos i32)
	(local.set $strPtr (call $str.mk))
	(local.set $curLength (call $i32list.getCurLen (local.get $lstPtr)))
	(if
	  (local.get $curLength)  ;; at least one item
	  (then
		(if (call $map.is (call $i32list.get@ (local.get $lstPtr)(i32.const 0)))
		  (return (call $map.toStr (local.get $lstPtr))))))
	(call $str.catByte (local.get $strPtr)(global.get $LSQBRACK))
	(local.set $ipos (i32.const 0))
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (local.set $strTmp (call $toStr (call $i32list.get@ (local.get $lstPtr)(local.get $ipos))))
		  (call $str.catStr (local.get $strPtr)(local.get $strTmp))
		  (call $str.catByte (local.get $strPtr)(global.get $COMMA))
		  (call $str.catsp (local.get $strPtr))
	      (local.set $ipos (i32.add (local.get $ipos)(i32.const 1)))
	      (br $iLoop))))
	(if (local.get $curLength)
	  (then
		(call $str.drop (local.get $strPtr))  ;; extra comma
		(call $str.drop (local.get $strPtr))))  ;; extra final space
	(call $str.catByte (local.get $strPtr)(global.get $RSQBRACK)) ;; right bracket
	(local.get $strPtr)
  )
  (func $str.toStr (param $strPtr i32)(result i32)
	;; This is used by map routines to dump a key that is a string
	(local.get $strPtr)
  )
  (func $str.mk (result i32)
	;; returns a memory offset for a string pointer:
	;; 	 TypeNum (BStr), byteLength, maxLength, dataOffset
	;; Strings start as an i32 curLength (0), 
	;; an i32 maxLength (4), an i32 memory offset to the data,
	;; (the data is initially a 4 byte chunk)
	;; 20 bytes total minimum for a string: typeNum, curLen, maxLen, dataOffset, 4 data bytes
	;; As they grow beyond their data allocation it doubles.
	;; !!!As of now (20210511) some routines are not prepared for UTF-8
	(local $strPtr i32)
	(local.set $strPtr (call $getMem (i32.const 20)))
	(call $setTypeNum (local.get $strPtr) (global.get $BStr))
	(call $str.setByteLen (local.get $strPtr) (i32.const 0))
	(call $str.setMaxLen (local.get $strPtr)(i32.const 4))
	(call $str.setDataOff (local.get $strPtr)(i32.add(local.get $strPtr)(i32.const 16)))
	(local.get $strPtr)
  )
  (func $str.getByteLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 4)))
  )
  (func $str.setByteLen(param $strPtr i32)(param $newLen i32)
	(i32.store (i32.add (local.get $strPtr)(i32.const 4)) (local.get $newLen))
  )
  (func $str.getMaxLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 8)))
  )
  (func $str.setMaxLen(param $strPtr i32)(param $newMaxLen i32)
	(i32.store (i32.add(local.get $strPtr)(i32.const 8))(local.get $newMaxLen))
  )
  (func $str.getDataOff (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 12)))
  )
  (func $str.setDataOff (param $strPtr i32)(param $newDataOff i32)
    (i32.store (i32.add(local.get $strPtr)(i32.const 12))(local.get $newDataOff))
  )
  (func $str.catStr (param $s1Ptr i32)(param $s2Ptr i32)
	;; Modify s1 by concatenating another string to it
	(local $s2pos i32)
	(local $s2ByteLen i32)
	(local.set $s2pos (i32.const 0))
	(local.set $s2ByteLen (call $str.getByteLen (local.get $s2Ptr)))
	(loop $bloop
		(if (i32.lt_u (local.get $s2pos)(local.get $s2ByteLen))
		  (then
			(call $str.catByte(local.get $s1Ptr)
			  (call $str.getByte (local.get $s2Ptr)(local.get $s2pos)))
			(local.set $s2pos (i32.add (local.get $s2pos)(i32.const 1)))
			(br $bloop))))		
  )
  (func $str.catStr.test (param $testNum i32)(result i32)
    (local $AAA i32)(local $ZZZ i32)
	(local.set $AAA (call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ (call $str.mkdata (global.get $gZZZ)))
	(call $str.catStr (local.get $AAA)(local.get $ZZZ))
	;; $AAA string now has $ZZZ concatenated onto it!
	(i32.eqz
	  (call $str.compare
		(local.get $AAA) 
		(call $str.mkdata (global.get $gAAAZZZ))))
  )
  (func $str.cat2Strings (param $s1Ptr i32)(param $s2Ptr i32)(result i32)
    ;; Returns a new string with the result
	(local $bpos i32)
	(local $s1+2Ptr i32)
	(local $byteLen1 i32)
	(local $byteLen2 i32)
	(local.set $s1+2Ptr (call $str.mk))
	(local.set $byteLen1 (call $str.getByteLen (local.get $s1Ptr)))
	(local.set $byteLen2 (call $str.getByteLen (local.get $s2Ptr)))
	(local.set $bpos (i32.const 0))
	(loop $bloop1
	  (if (i32.lt_u (local.get $bpos)(local.get $byteLen1))
		(then
		  (call $str.catByte (local.get $s1+2Ptr)
			(call $str.getByte (local.get $s1Ptr)(local.get $bpos)))
		  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
		  (br $bloop1))))
	(local.set $bpos (i32.const 0))
	(loop $bloop2
	  (if (i32.lt_u (local.get $bpos)(local.get $byteLen2))
		(then
		  (call $str.catByte (local.get $s1+2Ptr)
			(call $str.getByte (local.get $s2Ptr)(local.get $bpos)))
		  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
		  (br $bloop2))))
	(local.get $s1+2Ptr)
  )
  (func $str.cat2Strings.test (param $testNum i32)(result i32)
    (local $AAA i32)(local $ZZZ i32)(local $AAAZZZ i32)
	(local.set $AAA (call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ (call $str.mkdata (global.get $gZZZ)))
	(local.set $AAAZZZ (call $str.cat2Strings(local.get $AAA)(local.get $ZZZ)))
	;; New string!
	(i32.eqz 
	  (call $str.compare (local.get $AAAZZZ)
	  (call $str.mkdata (global.get $gAAAZZZ))))
  )
  ;; NOT UTF-8 FRIENDLY!!
  (func $str.Rev (param $strPtr i32)(result i32)
	;; Returns a pointer to a new string with reversed characters
	(local $cpos i32)(local $curLen i32)(local $revStrPtr i32)(local $curChar i32)
	(local.set $revStrPtr (call $str.mk))
	(local.set $cpos (i32.const 0))
	(local.set $curLen (call $str.getByteLen(local.get $strPtr)))
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $curLen))
		(then
			(local.set $curChar
			  (call $str.getByte (local.get $strPtr)(local.get $cpos)))
			(call $str.LcatChar (local.get $revStrPtr)(local.get $curChar))
			(local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
		)
	  )
	  (br_if $cloop (i32.lt_u (local.get $cpos)(local.get $curLen)))
	)
	(local.get $revStrPtr)
  )
  (func $str.Rev.test (param $testNum i32)(result i32)
	(local $abc i32)(local $abc.rev i32)(local $cba i32)
	(local.set $abc (call $str.mkdata (global.get $gABCDEF)))
	(local.set $abc.rev (call $str.Rev (local.get $abc)))
	(local.set $cba (call $str.mkdata (global.get $gFEDCBA)))
	(i32.eqz
	  (call $str.compare
		(local.get $abc.rev)
		(local.get $cba)))
  )
  (func $str.getByte (param $strPtr i32) (param $bytePos i32)(result i32)
    ;; how to show an error beyond returning null?
	(if (result i32)
	  (i32.lt_u (local.get $bytePos)(call $str.getByteLen (local.get $strPtr)))
	  (then
		(i32.load8_u (i32.add (call $str.getDataOff
		  (local.get $strPtr))(local.get $bytePos)))
	  )
	  (else (i32.const 0))
	)
  )
  (func $str.getByte.test (param $testNum i32)(result i32)
    (local $ts i32)(local $lastCharPos i32)
	(local.set $ts (call $str.mkdata (global.get $gABCDEF)))
	(local.set $lastCharPos
		(i32.sub (call $str.getByteLen (local.get $ts))(i32.const 1)))
	(if (i32.ne (call $str.getByte (local.get $ts)(i32.const 0))
				(i32.const 65)) ;; 'A'
		(return (i32.const 1)))
	(if (i32.ne (call $str.getByte (local.get $ts)(local.get $lastCharPos))
				(i32.const 70)) ;; 'F'
		(return (i32.const 1)))
	(i32.const 0)  ;; success
  )
  (func $str.getLastByte (param $strPtr i32)(result i32)
	(if (i32.eqz (call $str.getByteLen (local.get $strPtr)))
	  (return (i32.const 0)))
	(call $str.getByte
	  (local.get $strPtr)
	  (i32.sub (call $str.getByteLen (local.get $strPtr))(i32.const 1)))
  )
  (func $str.getLastByte.test (param $testNum i32)(result i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(if (call $str.getLastByte (local.get $strPtr))
	  (return (i32.const 1)))  ;; should have been zero
	(local.set $strPtr (call $str.mkdata (global.get $gABCDEF)))
	(if
	  (i32.ne
		(call $str.getLastByte (local.get $strPtr))
		(i32.const 70)) ;; F
	  (return (i32.const 2))  ;; failure
	)
	(i32.const 0) ;; Success
  )
  (func $str.mkdata (param $dataOffset i32) (result i32)
    ;; Make a string from null-terminated chunk of memory
	;; null terminator is not counted as part of string
	;; Should work with UTF-8?
	(local $length i32) (local $curByte i32)(local $strPtr i32)
	(local.set $length (i32.const 0))
	(loop $cLoop
		(local.set $curByte (i32.load8_u (i32.add (local.get $length)(local.get $dataOffset))))
		(if (i32.ne (i32.const 0)(local.get $curByte)) ;; checking for null
		  (then
		    (local.set $length (i32.add (local.get $length)(i32.const 1)))
			(br $cLoop)
	)))
	(local.set $strPtr (call $getMem (i32.const 16)))  ;; just room for pointer info
	(call $setTypeNum (local.get $strPtr)(global.get $BStr))
	(call $str.setByteLen (local.get $strPtr)(local.get $length))
	(call $str.setMaxLen (local.get $strPtr)(local.get $length))
	(call $str.setDataOff (local.get $strPtr)(local.get $dataOffset))
	(local.get $strPtr)
  )
  (func $str.mkdata.test (param $testNum i32)(result i32)
	;; see if first or last data stings have gotten stomped on
	(local $aaa i32)(local $zzz i32)(local $first i32)(local $last i32)
	(local.set $first (call $str.mkdata (global.get $gAAA)))
	(local.set $last (call $str.mkdata (global.get $gZZZ)))
	(local.set $aaa (call $str.mk))
	(call $str.catByte(local.get $aaa) (i32.const 65))
	(call $str.catByte(local.get $aaa) (i32.const 65))
	(call $str.catByte(local.get $aaa) (i32.const 65))
	(local.set $zzz (call $str.mk))
	(call $str.catByte(local.get $zzz) (i32.const 90))
	(call $str.catByte(local.get $zzz) (i32.const 90))
	(call $str.catByte(local.get $zzz) (i32.const 90))
	(i32.eqz
	  (i32.and
		(call $str.compare (local.get $aaa)(local.get $first))
		(call $str.compare (local.get $zzz)(local.get $last))))
  )
  (func $str.mkslice (param $strptr i32)(param $offset i32)(param $length i32)(result i32)
	;; Not UTF-8 safe
	(local $slice i32) 	  ;; to be returned
	(local $bpos i32)	  ;; byte pointer to copy data
	(local $lastbpos i32) ;; don't go past this offset
	(local.set $slice (call $str.mk))
	(local.set $bpos (local.get $offset))
	(local.set $lastbpos (i32.add (local.get $offset)(local.get $length)))
	(loop $bLoop
	  (if (i32.lt_u (local.get $bpos)(local.get $lastbpos))
		(then
		  ;; (call $i32.printwsp (local.get $bpos))
		  ;; (call $C.print (call $str.getByte (local.get $strptr)(local.get $bpos)))
		  (call $str.catByte
			(local.get $slice)
			(call $str.getByte
			  (local.get $strptr)
			  (local.get $bpos)
			))
		  (local.set $bpos (i32.add (i32.const 1)(local.get $bpos)))
		  (br $bLoop)
		)))
	(local.get $slice)
  )
  (func $str.mkslice.test (param $testNum i32)(result i32)
	(local $AAAZZZ i32)(local $AAA i32)(local $ZZZ i32)
	(local $slice i32)
	(local.set $AAAZZZ (call $str.mkdata (global.get $gAAAZZZ)))
	(local.set $AAA (call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ (call $str.mkdata (global.get $gZZZ)))
	(local.set $slice
	  (call $str.mkslice
		(local.get $AAAZZZ)
		(i32.const 0)
		(i32.const 3)))
	(if (i32.eqz
		  (call $str.compare (local.get $AAA)(local.get $slice)))
	  (then
		(return (i32.const 1))))
	(local.set $slice
	  (call $str.mkslice
		(local.get $AAAZZZ)
		(i32.const 3)
		(i32.const 3)))
	(if (i32.eqz
		  (call $str.compare (local.get $ZZZ)(local.get $slice)))
	  (return (i32.const 2)))
	(return (i32.const 0))
  )
  (func $str.print (param $strPtr i32)
	(local $curLength i32)
	(local $dataOffset i32)  ;; offset to string data
	(local $cpos i32)  ;; steps through character positions
	(local.set $curLength (call $str.getByteLen(local.get $strPtr)))
	(local.set $cpos (i32.const 0))
	(local.set $dataOffset (call $str.getDataOff (local.get $strPtr)));;(i32.load (i32.add (i32.const 8)(local.get $strPtr))))
	(loop $cLoop
	  (if (i32.lt_u (local.get $cpos)(local.get $curLength))
		(then
		 (i32.load8_u (i32.add (local.get $dataOffset)(local.get $cpos)))
		 (call $byte.print)   
	     (local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
	     (br $cLoop))))
  )
  (func $strdata.print (param $global i32)
    (call $str.print (call $str.mkdata (local.get $global)))
  )
  (func $str.printwsp (param $strPtr i32)
	(call $str.print (local.get $strPtr))
 	(call $byte.print (i32.const 32))  ;; space
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
	(local.set $curLen (call $str.getByteLen (local.get $strPtr)))
	(local.set $maxLen (call $str.getMaxLen (local.get $strPtr)))
	(local.set $dataOff   (call $str.getDataOff (local.get $strPtr)))
	(local.set $newMaxLen (i32.mul (local.get $maxLen)(i32.const 2)))
	(local.set $newDataOff (call $getMem (local.get $newMaxLen)))
	(call $str.setMaxLen(local.get $strPtr)(local.get $newMaxLen))
	(call $str.setDataOff(local.get $strPtr)(local.get $newDataOff))
	(memory.copy (local.get $newDataOff)(local.get $dataOff)(local.get $curLen))
  )
  (func $str.catChar (param $strPtr i32)(param $C i32)
    (local $byte i32)
	(if (i32.eqz (local.get $C))  ;; handle null
	  (return (call $str.catByte (local.get $strPtr) (i32.const 0))))
	(loop $byteLoop
	  (local.set $byte ;;assigned to high order byte in $C
		(i32.shr_u
		  (i32.and
			(i32.const 0xFF000000)  ;; mask and shift right
			  (local.get $C))
		  (i32.const 24)))
	  (if (local.get $byte)  ;; ignore leading null's
		(call $str.catByte (local.get $strPtr)(local.get $byte)))
		(local.set $C (i32.shl (local.get $C)(i32.const 8)))  ;; move to next byte
	  (if (local.get $C)  ;; More?
	   (br $byteLoop)))
  )
  (func $str.catChar.test (param $testNum i32)(result i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-1))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-2))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-3))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-4))
	(if (i32.ne (call $str.getByteLen (local.get $strPtr))(i32.const 10))
	  (return (i32.const 1)))
	(i32.const 0)
  )
  (func $str.catByte (param $strPtr i32)(param $byte i32)
	(local $maxLen i32) (local $byteLen i32)
	(local.set $byteLen (call $str.getByteLen (local.get $strPtr)))
	(local.set $maxLen (call $str.getMaxLen (local.get $strPtr)))
	;;(call $C.print (i32.const 91))(call $i32.hexprint (local.get $byte))(call $C.print (i32.const 93))
	(if (i32.ge_u (local.get $byteLen) (local.get $maxLen))
	  (then (call $str.extend (local.get $strPtr))))
	(i32.store8
	  (i32.add (local.get $byteLen)(call $str.getDataOff (local.get $strPtr)))
	  (local.get $byte))
	(call $str.setByteLen(local.get $strPtr)
	  (i32.add (local.get $byteLen)(i32.const 1)))
  )
  (func $str.catsp (param $strPtr i32)
	(call $str.catByte (local.get $strPtr)(i32.const 32)))
  (func $str.catlf (param $strPtr i32)
    (call $str.catByte (local.get $strPtr)(i32.const 10)))
  
  (func $str.catByte.test (param $testNum i32)(result i32)
	(local $sp i32)
	(local $memsp i32)
	(local.set $sp
	  (call $str.mk))
	(local.set $memsp 
	  (call $str.mkdata
		(global.get $gABCDEF)))
	(call $str.catByte (local.get $sp) (i32.const 65))
	(call $str.catByte (local.get $sp) (i32.const 66))
	(call $str.catByte (local.get $sp) (i32.const 67))
	(call $str.catByte (local.get $sp) (i32.const 68))
	(call $str.catByte (local.get $sp) (i32.const 69))
	(call $str.catByte (local.get $sp) (i32.const 70))
	(if
	  (i32.eqz
		(call $str.compare
		  (local.get $sp)
		  (local.get $memsp)))
	  (then
		(return (i32.const 1))))  ;; Failure
	;; Test UTF-8 compliance a bit
	(return (i32.const 0))
  )
  (func $str.drop(param $strPtr i32)
	(if (i32.eqz (call $str.getByteLen (local.get $strPtr)))
	  (return))
	(call $str.setByteLen
	  (local.get $strPtr)
	  (i32.sub
		(call $str.getByteLen (local.get $strPtr))
		(i32.const 1)))
  )
  (func $str.drop.test (param $testNum i32)(result i32)
    (local $strptr i32)
	(local.set $strptr (call $str.mk))
	(call $str.catByte (local.get $strptr)(i32.const 65))
	(call $str.catByte (local.get $strptr)(i32.const 66))
	(if (i32.ne (call $str.getLastByte(local.get $strptr))(i32.const 66))
	  (return (i32.const 1)))
	(call $str.drop(local.get $strptr))
	(if (i32.ne (call $str.getLastByte(local.get $strptr))(i32.const 65))
	  (return (i32.const 2)))
	(call $str.drop (local.get $strptr))
	(if (i32.eqz (call $str.getByteLen (local.get $strptr)))
	  (return (i32.const 0)))  ;; OK
	(return (i32.const 3))	
  )
  (func $str.clear (param $strPtr i32)
	(call $str.setByteLen (local.get $strPtr)(i32.const 0))
  )
  (func $str.LcatChar (param $strPtr i32)(param $Lchar i32)
	;; Add a character to beginning of a string
	;; Not multibyte character safe
	(local $cpos i32)(local $dataOff i32)(local $curC i32)
	;; first make room for the new character
	;; tack it on at the end (it will get overwritten)
	(local.set $cpos (call $str.getByteLen (local.get $strPtr)))
	(call $str.catByte (local.get $strPtr)(local.get $Lchar))
	(local.set $dataOff (call $str.getDataOff (local.get $strPtr)))
	(loop $cloop
		(i32.store8 (i32.add (local.get $dataOff)(local.get $cpos))
			(i32.load8_u (i32.sub (i32.add (local.get $dataOff)(local.get $cpos))(i32.const 1))))
		(local.set $cpos (i32.sub (local.get $cpos)(i32.const 1)))
		(br_if $cloop (i32.gt_s (local.get $cpos)(i32.const 0)))
	)
	(i32.store8 (local.get $dataOff)(local.get $Lchar))
  )
  (func $str.stripLeading (param $strPtr i32)(param $charToStrip i32)(result i32)
	;; Return a new string without any leading $charToStrip's
	(local $spos i32)(local $curLen i32)(local $stripped i32)
	(local.set $spos (i32.const 0))
	(loop $strip ;; $str.getByte returns Null if $spos goes out of bounds
		(if (i32.eq (local.get $charToStrip)
			(call $str.getByte (local.get $strPtr)(local.get $spos)))
		  (then
			(local.set $spos (i32.add (local.get $spos)(i32.const 1)))
			(br $strip)
		  )))
	(local.set $curLen (call $str.getByteLen(local.get $strPtr)))
	(local.set $stripped (call $str.mk))
	(loop $copy
		(if (i32.lt_u (local.get $spos)(local.get $curLen))
		  (then
		    (call $str.catByte (local.get $stripped)
				(call $str.getByte(local.get $strPtr)(local.get $spos)))
			(local.set $spos (i32.add (local.get $spos)(i32.const 1)))
			(br $copy))))
	(local.get $stripped)
  )
  (func $str.stripLeading.test (param $testNum i32) (result i32)
	(local $strAAAZZZ i32)(local $strZZZ i32)
	(local.set $strAAAZZZ (call $str.mkdata (global.get $gAAAZZZ)))
	(local.set $strZZZ (call $str.mkdata (global.get $gZZZ)))
	(i32.eqz
	  (call $str.compare
		(local.get $strZZZ)
		(call $str.stripLeading (local.get $strAAAZZZ) (i32.const 65))))
  )
  (func $str.compare (type $keyCompSig)
	(local $s1ptr i32)(local $s2ptr i32)
	(local $s2len i32)(local $cpos i32)
	(local.set $s1ptr (local.get 0))
	(local.set $s2ptr (local.get 1))
	(local.set $s2len (call $str.getByteLen (local.get $s2ptr)))
	(if (i32.ne (call $str.getByteLen (local.get $s1ptr))(local.get $s2len))
	  (return (i32.const 0)))
	(local.set $cpos (i32.const 0))
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $s2len))
		(then
			(if (i32.ne (call $str.getByte (local.get $s1ptr)(local.get $cpos))
						(call $str.getByte (local.get $s2ptr)(local.get $cpos)))
			  (return (i32.const 0)))
			(local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
			(br $cloop)
		)))
	(i32.const 1) ;; success
  )
  (func $str.compare.test (param $testNum i32)(result i32)
	(local $spAAA i32)(local $spAAA2 i32) (local $spZZZ i32)
	(local.set $spAAA (call $str.mkdata (global.get $gAAA)))
	(local.set $spAAA2 (call $str.mk))
	(call $str.catByte (local.get $spAAA2)(i32.const 65))
	(call $str.catByte (local.get $spAAA2)(i32.const 65))
	(call $str.catByte (local.get $spAAA2)(i32.const 65))
	(local.set $spZZZ (call $str.mkdata (global.get $gZZZ)))
	(if (i32.eqz (call $str.compare (local.get $spAAA)(local.get $spAAA)))
		(return (i32.const 1)))  ;; same string, should have matched
	(if (i32.eqz (call $str.compare (local.get $spAAA)(local.get $spAAA2)))
		(return (i32.const 2)))  ;; same contents, should have matched
	(if (call $str.compare (local.get $spAAA)(local.get $spZZZ))
		(return (i32.const 3)))  ;; should not have matched!
	(i32.const 0) ;; success
  )
  (func $str.Csplit (param $toSplit i32)(param $splitC i32)(result i32)
	;; pass string, char, return list of strings split on char
	;; Not UTF-8 safe (split character needs to be a single byte long
	;; and needs a test for that!
	(local $splitList i32) (local $strCum i32) (local $bpos i32)
	(local $byte i32) (local $strLen i32)
	(local.set $splitList (call $i32list.mk))
	(local.set $strCum (call $str.mk)) ;; accumulates chars
	(local.set $bpos (i32.const 0))
	(local.set $strLen (call $str.getByteLen (local.get $toSplit)))
	(loop $bloop
	  (if (i32.lt_u (local.get $bpos)(local.get $strLen))
	    (then
		  (local.set $byte (call $str.getByte (local.get $toSplit)(local.get $bpos)))
		  ;;(call $i32.print (local.get $byte))
		  (if (i32.eq (local.get $splitC)(local.get $byte))
			(then
			  (call $i32list.push (local.get $splitList)(local.get $strCum))
			  (local.set $strCum (call $str.mk)))
			(else
			  (call $str.catByte (local.get $strCum)(local.get $byte))))
		  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
		  (br $bloop))))
	(if (call $str.getByteLen (local.get $strCum));; skip empty last $strCum
	  (then (call $i32list.push (local.get $splitList)(local.get $strCum))))
	(local.get $splitList)
  )
  (func $str.Csplit.test (param $testNum i32)(result i32)
	;; The split character is not part of the split pieces
	(local $AbCDbE i32)(local $listPtr i32)(local $strptr0 i32)
	(local.set $AbCDbE (call $str.mkdata (global.get $gAbCDbE)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 98)))  ;; 'b'
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr))(i32.const 3))
	  (return (i32.const 1)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 45)))  ;; 'E'
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr))(i32.const 1))
	  (return (i32.const 2)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 122)))  ;; 'z'
	(local.set $strptr0 (call $i32list.get@ (local.get $listPtr)(i32.const 0)))
	(if (i32.eqz 
		  (call $str.compare
			(call $i32list.get@ (local.get $listPtr)(i32.const 0))
			(local.get $AbCDbE)))
	  (return (i32.const 3)))
	(i32.const 0) ;; success
  )
  (func $str.startsAt (param $str i32)(param $pat i32)(param $startPos i32)(result i32)
	(local $patLen i32)(local $patPos i32)(local $cPos i32)
	(local.set $patLen (call $str.getByteLen(local.get $pat)))
	(if (i32.gt_u (i32.add (local.get $patLen)(local.get $startPos))
					(call $str.getByteLen (local.get $str)))
		(then (return (i32.const 0))))
	(local.set $patPos (i32.const 0))
	(local.set $cPos (local.get $startPos))
	(loop $cloop
	  (if (i32.lt_u (local.get $patPos)(local.get $patLen))
		(then
		  (if (i32.eq (call $str.getByte (local.get $pat)(local.get $patPos))
						(call $str.getByte (local.get $str)(local.get $cPos)))
			(then
			  (local.set $patPos (i32.add (i32.const 1)(local.get $patPos)))
			  (local.set $cPos   (i32.add (i32.const 1)(local.get $cPos)))
			  (br $cloop))))))
	(i32.eq (local.get $patPos)(local.get $patLen))  ;; matched whole pat?
  )
  (func $str.find (param $string i32)(param $pat i32)(result i32)
    ;; returns position where found, otherwise -1
	(local $cpos i32)(local $lastPos i32)
	(local.set $lastPos (i32.sub (call $str.getByteLen (local.get $string))
								(call $str.getByteLen(local.get $pat))))
	(local.set $cpos (i32.const 0))
	(loop $cloop
	  (if (i32.le_s (local.get $cpos) (local.get $lastPos))
		(then
		  (if (call $str.startsAt (local.get $string)(local.get $pat)(local.get $cpos))
			(then (local.get $cpos) return))
		  (local.set $cpos (i32.add (local.get $cpos) (i32.const 1)))
		  (br $cloop))))
	(i32.const -1)
  )
  (func $str.find.test (param $testNum i32) (result i32)
	(local $AAAZZZ i32)(local $AAA i32)(local $ZZZ i32)(local $aaa i32)
	(local.set $AAAZZZ 	(call $str.mkdata (global.get $gAAAZZZ)))
	(local.set $AAA 	(call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ		(call $str.mkdata (global.get $gZZZ)))
	(local.set $aaa		(call $str.mkdata (global.get $gaaa)))
	(if (i32.ne (i32.const 0) (call $str.find (local.get $AAAZZZ)(local.get $AAA)))
		(return (i32.const 1)))
	(if (i32.ne (i32.const 3) (call $str.find (local.get $AAAZZZ)(local.get $ZZZ)))
		(return (i32.const 2)))
	(if (i32.ne (i32.const -1) (call $str.find (local.get $AAAZZZ)(local.get $aaa)))
		(return (i32.const 3)))
	(if (i32.ne (i32.const -1) (call $str.find (local.get $AAA)(local.get $AAAZZZ)))
		(return (i32.const 4)))
	(i32.const 0)
  )
  (func $readFile (result i32)
	;; Reads a file in and returns a list of string pointers to the lines in it
	;; Not UTF-8 safe ?
	(local $listPtr i32)(local $strPtr i32)(local $nread i32)
	(i32.store (global.get $readIOVsOff0) (global.get $readBuffOff))
	(i32.store (global.get $readIOVsOff4) (global.get $readBuffLen))
	(call $fd_read
	  (i32.const 0) ;; 0 for stdin
	  (global.get $readIOVsOff0) ;; *iovs
	  (i32.const 1) ;; iovs_len
	  (global.get $readIOVsOff4) ;; nread goes here
	)
	drop  ;; $fd_read return value
	(local.set $listPtr (call $i32list.mk))
	(local.set $strPtr (call $str.mk))
	(call $str.setDataOff (local.get $strPtr)(global.get $readBuffOff))
	(call $str.setByteLen (local.get $strPtr)(i32.load (global.get $readIOVsOff4)))
	(call $str.setMaxLen (local.get $strPtr)(i32.load (global.get $readIOVsOff4)))
	(local.get $strPtr)
  )
  ;; match from https://www.drdobbs.com/184410904
  ;; Regular Expressions by Kernighan & Pike
  (func $match (param $re i32) (param $text i32) (result i32)
	(local $textPos i32)
    (if				;;if (re[0]=='^') return matchhere(re+1, text)
	  (i32.eq
		(call $str.getByte (local.get $re)(i32.const 0))
		(global.get $CIRCUMFLEX))
	  (return
	    (call $matchHere 
		  (local.get $re)(i32.const 1)
		  (local.get $text)(i32.const 0))
		  ))
	(local.set $textPos (i32.const 0))
	(loop $textLoop
	  (if 
		(call $matchHere
		  (local.get $re) (i32.const 0)
		  (local.get $text)(local.get $textPos))
		(return (i32.const 1)))
	  (local.set $textPos
		(i32.add
		  (local.get $textPos)
		  (i32.const 1)))
	  (if
		(i32.lt_u
		  (local.get $textPos)
		  (call $str.getByteLen (local.get $text)))
		(br $textLoop)))
	(i32.const 0)  ;; failed to match
  )
  (func $match.test (param $testNum i32)(result i32)
	(if
	  (i32.eqz
		(call $match
		  (call $str.mkdata (global.get $g^A))
		  (call $str.mkdata (global.get $gABCDEF))))
	  (return (i32.const 1)))  ;; failed test 1
	(if (call $match  ;; should not match!
		  (call $str.mkdata (global.get $g^B))
		  (call $str.mkdata (global.get $gABCDEF)))
	  (return (i32.const 2)))  ;; failed test 2
	(if
	  (i32.eqz
		(call $match
		  (call $str.mkdata (global.get $g^A$))
		  (call $str.mkdata (global.get $gA))))
	  (return (i32.const 3))) ;; failed test 3
	(if
	  (i32.eqz
		(call $match
		  (call $str.mkdata (global.get $g.*))
		  (call $str.mkdata (global.get $gABCDEF))))
	  (return (i32.const 4)))	;; Failure, should have matched
	(if
	  (i32.eqz
		(call $match
		  (call $str.mkdata (global.get $gCD))
		  (call $str.mkdata (global.get $gABCDEF))))
	  (return (i32.const 5)))  ;; Failure should have  matched
	(if
	  (i32.eqz
		(call $match
		  (call $str.mkdata (global.get $g.*F))
		  (call $str.mkdata (global.get $gABCDEF))))
	  (return (i32.const 6)))  ;; Failed, should have matched
    (i32.const 0)  ;; passed
  )
  (func $matchHere (param $re i32)(param $rePos i32)
					(param $text i32)(param $textPos i32)
					(result i32)
	(if			;; if (re[0] == '\0' return 1  (at end of re)
	  (i32.ge_u
		(local.get $rePos)
		(call $str.getByteLen (local.get $re))) ;; len(re) >= 
	  (return (i32.const 1)))  ;; end of $re
	(if			;; if (re[1]=='*' return matchstart(re[0], re+2, text)
	  (i32.eq
		(global.get $ASTERISK)
		(call $str.getByte (local.get $re)
		  (i32.add
			(i32.const 1)
			(local.get $rePos))))
	  (return
		(call $matchStar
		  (call $str.getByte (local.get $re)(local.get $rePos))
		  (local.get $re)
		  (i32.add (local.get $rePos)(i32.const 2))
		  (local.get $text)
		  (local.get $textPos))))
	(if
	  (i32.and
		(i32.eq
		  (global.get $DOLLARSIGN)
		  (call $str.getByte
			(local.get $re)
			(local.get $rePos)))
		(i32.ge_u
		  (i32.add (i32.const 1)(local.get $rePos))
		  (call
			$str.getByteLen
			(local.get $re))))
	  (return
		(i32.ge_u
		  (local.get $textPos)
		  (call
			$str.getByteLen
			  (local.get $text)))))
	;; Check rest of match
	(if
	  (i32.and   ;; &&
		(i32.lt_u ;; *text !='\0'
		  (local.get $textPos)
		  (call
			$str.getByteLen
			(local.get $text)))
		(i32.or ;; ||
		  (i32.eq  ;; re[0]=='.'
			  (call
				$str.getByte
				(local.get $re)
				(local.get $rePos)
			  (global.get $FULLSTOP)
			  ))
		  (i32.eq  ;; re[0]==*text
			(call $str.getByte (local.get $re)  (local.get $rePos))
			(call $str.getByte (local.get $text)(local.get $textPos))
		  )))
	  (return
	    (call 
	      $matchHere
		  (local.get $re)
		  (i32.add
			(local.get $rePos)
			(i32.const 1))
		  (local.get $text)
		  (i32.add
			(local.get $textPos)
			(i32.const 1)))))
	(i32.const 0)
  )
  ;; int matchstar(int c, char *re, char *text)
  (func $matchStar (param $byte i32)
	(param $re i32)(param $rePos i32)
	(param $text i32)(param $textPos i32) (result i32)
	(loop $starLoop
	  (if    					;; if (matchere(re, text)) return 1;
		(call $matchHere 
		  (local.get $re)  (local.get $rePos)
		  (local.get $text)(local.get $textPos))
		(return (i32.const 1)))
	  (br_if $starLoop
		(i32.and						;; &&
		  (i32.le_u						;; *text !='\0'
			(local.get $textPos)
			(call
			  $str.getByteLen
				(local.get $text)))  
		  (i32.or						;; ||
			(i32.eq
			  (call						;; *text++==c
				$str.getByte
				  (local.get $text)
				  (local.get $textPos))
			  (local.get $byte))
			(i32.eq
				(local.get $byte)		;; c=='.'
				(global.get $FULLSTOP))))
		(local.set $textPos (i32.add (local.get $textPos)(i32.const 1)))))
	(i32.const 0)
  )
  (func $map.mk (param $compareOff i32)(param $keyPrintOff i32)(result i32)
	;; returns a pointer to an i32 list of:
	;;	 TypeNum ('Map ')
	;;   pointer to list of keys ($mapListOff)
	;;   pointer to list of the values ($valListOff)
	;;   function offset to the key comparison routine ($compareOff)
	;;   function offset to the key print routine ($printOff) [NOT CURRENTLY USED]
	(local $mapList i32)
	(local.set $mapList
	  (call $i32list.mk))
	(call $i32list.push ;; TypeNum
	  (local.get $mapList)
	  (global.get $Map))
	(call $i32list.push	;; keys
	  (local.get $mapList)
	  (call $i32list.mk))
	(call $i32list.push	;; vals to
	  (local.get $mapList)
	  (call $i32list.mk))
	(call $i32list.push
	  (local.get $mapList)
	  (local.get $compareOff))
	(call $i32list.push
	  (local.get $mapList)
	  (local.get $keyPrintOff))
	(local.get $mapList)
  )
  (func $map.is (param $ptr i32)(result i32)
    (i32.eq (local.get $ptr)(global.get $Map))
  )
  ;; these are offsets within the state info list in each map
  (global $mapTypeOff i32 (i32.const 0))
  (global $mapListOff i32 (i32.const 1))
  (global $valListOff i32 (i32.const 2))
  (global $keyCompareOff i32 (i32.const 3))
  (global $keyPrintOff i32 (i32.const 4))
  ;; Currently here is just one type of map
  ;; Offsets for routines for key compare and key print are passed to $map.mk
  (func $strMap.mk (result i32)
	(call $map.mk
	  (global.get $strCompareOffset)
	  (global.get $strToStrOffset))
  )
  (func $i32Map.mk (result i32)
	(call $map.mk
	  (global.get $i32CompareOffset)
	  (global.get $i32ToStrOffset))
  )
  (func $map.set (param $map i32)(param $key i32)(param $val i32)
	(local $keyList i32)
	(local $valList i32)
	(local $keyCompareOff i32)
	(local $keyPrintOff i32)
	(local $mapLen i32)
	(local $mapPos i32)
	(local $testKey i32)
	(local.set $keyList
	  (call $i32list.get@ (local.get $map) (global.get $mapListOff)))
	(local.set $valList
	  (call $i32list.get@ (local.get $map) (global.get $valListOff)))
	(local.set $keyCompareOff
	  (call $i32list.get@ (local.get $map) (global.get $keyCompareOff)))
	(local.set $mapLen (call $i32list.getCurLen (local.get $keyList)))
	(local.set $mapPos (i32.const 0))
	(loop $mLoop  ;; reset value if key is already in keymap
	  (if (i32.lt_u (local.get $mapPos)(local.get $mapLen))
		(then
		  (local.set $testKey
		    (call $i32list.get@
			  (local.get $keyList)
			  (local.get $mapPos)))
		  (local.get $key)
		  (local.get $testKey)
		  (call_indirect
			(type $keyCompSig)
			(local.get $keyCompareOff))
		  (if
			(then
			  (call $i32list.set@
				(local.get $valList)
				(local.get $mapPos)
				(local.get $val))
			  return
			)
		  )
		  (local.set $mapPos (i32.add (local.get $mapPos)(i32.const 1)))
		  (br $mLoop))))
	(call $i32list.push (local.get $keyList)(local.get $key))
	(call $i32list.push (local.get $valList)(local.get $val))
  )
  (func $map.get (param $map i32)(param $key i32)(result i32)
	(local $keyList i32)
	(local $valList i32)
	(local $compareOff i32)
	(local $mapLen i32)
	(local $mapPos i32)
	(local $testKey i32)
	(local.set $keyList
	  (call $i32list.get@ (local.get $map) (global.get $mapListOff)))
	(local.set $valList
	  (call $i32list.get@ (local.get $map) (global.get $valListOff)))
	(local.set $compareOff
	  (call $i32list.get@ (local.get $map) (global.get $keyCompareOff)))
	(local.set $mapLen (call $i32list.getCurLen (local.get $keyList)))
	(local.set $mapPos (i32.const 0))
	(loop $mLoop  ;; look for $key in $keyList
	  (if (i32.lt_u (local.get $mapPos)(local.get $mapLen))
		(then
		  (local.set $testKey
		    (call $i32list.get@
			  (local.get $keyList)
			  (local.get $mapPos)))
		  (local.get $testKey)  ;; param 0
		  (local.get $key)		;; param 1
		  (call_indirect (type $keyCompSig) ;;(param i32)(param i32)(result i32)
			(local.get $compareOff))
		  (if
			(then
			  (return (call $i32list.get@
				(local.get $valList)
				(local.get $mapPos)))))
		  (local.set $mapPos (i32.add (local.get $mapPos)(i32.const 1)))
		  (br $mLoop))))
	(global.get $maxNeg)	;; didn't find any match flag
  )
  (func $map.toStr(param $map i32)(result i32)
	(local $mapLen i32)
	(local $mapPos i32)
	(local $keytoStrOff i32)
	(local $keyList i32)
	(local $valList i32)
	(local $key i32)
	(local $val i32)
	(local $strPtr i32)
	
	(local.set $strPtr (call $str.mk))
	
	(local.set $keyList
	  (call $i32list.get@ (local.get $map) (global.get $mapListOff)))
	(local.set $valList
	  (call $i32list.get@ (local.get $map) (global.get $valListOff)))

	(local.set $keytoStrOff
	  (call $i32list.get@ (local.get $map) (global.get $keyPrintOff)))
	(local.set $mapLen (call $i32list.getCurLen (local.get $keyList)))
	(local.set $mapPos (i32.const 0))
	(call $str.catlf (local.get $strPtr))
	(call $str.catByte (local.get $strPtr)(global.get $LBRACE))
	(loop $mLoop
	  (if (i32.lt_u (local.get $mapPos)(local.get $mapLen))
		(then
		  (local.set $key
		    (call $i32list.get@
			  (local.get $keyList)
			  (local.get $mapPos)))
		  (local.set $val
		    (call $i32list.get@
			  (local.get $valList)
			  (local.get $mapPos)))
		  (call $str.catStr
		    (local.get $strPtr)
			(local.get $key)
			(call $toStr))
		  (call $str.catByte (local.get $strPtr) (i32.const 58)) ;; colon
		  (call $str.catStr (local.get $strPtr) (call $toStr(local.get $val)))
		  (local.set $mapPos (i32.add (local.get $mapPos)(i32.const 1)))
		  (if (i32.lt_u (local.get $mapPos)(local.get $mapLen))
		    (then
			  (call $str.catByte (local.get $strPtr)(global.get $COMMA))
			  ;;(call $str.catlf (local.get $strPtr))
			  (call $str.catsp (local.get $strPtr))))
		  (br $mLoop))))
	(call $str.catByte (local.get $strPtr)(global.get $RBRACE))
	(local.get $strPtr)
  )
  (func $map.test (param $testNum i32)(result i32)
	(local $imap i32)
	(local $smap i32)
	(local.set $imap (call $i32Map.mk))
	;; set map 3 -> 42 and test it
	(call $map.set (local.get $imap)(i32.const 3)(i32.const 42))
	(if
	  (i32.ne
		(call $map.get (local.get $imap)(i32.const 3))
		(i32.const 42))
	  (return (i32.const 1))) ;; error #1
	;; use a key that hasn't been set
	(if
	  (i32.ne
		(call $map.get (local.get $imap)(i32.const 4))
		(global.get $maxNeg))  	;; expect it not to be there
	  (return (i32.const 2)))	;; error #2
	;; set a second key/val pair and test it 4 ->43
	(call $map.set (local.get $imap)(i32.const 4)(i32.const 43))
	(if
	  (i32.ne
		(call $map.get (local.get $imap)(i32.const 4))
		(i32.const 43))
	  (return (i32.const 3)))	;; error #3
	;; reset the value of key 3
	(call $map.set (local.get $imap)(i32.const 3)(i32.const 45))
	(if
	  (i32.ne
		(call $map.get (local.get $imap)(i32.const 3))
		(i32.const 45))
	  (return (i32.const 4)))	;; error #4
	;;(call $map.dump (local.get $imap))
	;; create a map with strings as the keys
	(local.set $smap (call $strMap.mk))
	;; set $smap 'AAA' -> 42 and test it
	(call $map.set
	  (local.get $smap)
	  (call $str.mkdata (global.get $gAAA))
	  (i32.const 42))
	(if
	  (i32.ne
		(call $map.get
		  (local.get $smap)
		  (call $str.mkdata (global.get $gAAA)))
		(i32.const 42))
	  (return (i32.const 5)))	;; error #5
	;; Add another key/value pair and look for it
	(call $map.set
	  (local.get $smap)
	  (call $str.mkdata (global.get $gZZZ))
	  (i32.const 43))
	(if
	  (i32.ne
		(call $map.get
		  (local.get $smap)
		  (call $str.mkdata (global.get $gZZZ)))
		(i32.const 43))
	  (return (i32.const 6)))	;; error #5
	;; Replace value for ZZZ and retrieve it
	(call $map.set
	  (local.get $smap)
	  (call $str.mkdata (global.get $gZZZ))
	  (i32.const 44))
	(if
	  (i32.ne
		(call $map.get
		  (local.get $smap)
		  (call $str.mkdata (global.get $gZZZ)))
		(i32.const 44))
	  (return (i32.const 6)))	;; error #5
	;;(call $map.dump (local.get $smap))
    (i32.const 0) ;; Success
  )
  (func $i32.compare (param $i1 i32)(param $i2 i32)(result i32)
	(i32.eq (local.get $i1)(local.get $i2))
  )
  (func $wam2wat (param $strPtr i32)(result i32)
	;; Accepts WAM file as a string, returns a list of tokens
	(local $wamStack i32)
	(local $token i32)
	(local $numToks i32)
	(local $tokPos i32)
	(local.set $wamStack (call $wamTokenize (local.get $strPtr)))
	;;(call $print (local.get $wamStack))(call $printlf)
	(local.get $wamStack) ;; something to return for now
  )
  ;; Tokenization closely follows
  ;; https://github.com/emilbayes/wat-tokenizer/blob/master/index.js
  (func $addToken (param $state i32)(param $token i32)
	(local $stack i32)
	(local $top i32)
	(local $node i32)
	(local $tokcopy i32)  ;; holds copy of to-be-cleared token
	(local.set $tokcopy (call $str.mk))
	(call $strdata.print(global.get $gaddToken:))
	(call $str.print (local.get $token))
	;;(call $byte.printwlf (i32.const 39)) ;; single quote
	(call $map.set (local.get $state)(global.get $ginsideString)(i32.const 0))
	(call $map.set (local.get $state)(global.get $ginsideWhiteSp)(i32.const 0))
	(call $map.set (local.get $state)(global.get $ginsideLineCom)(i32.const 0))
	(if
	  (i32.eqz  ;; ignore empty slices
		(call $str.getByteLen(local.get $token)))
	  (then
		;;(call $strdata.printwlf (global.get $gskipping))
		(return)))
	(local.set $stack (call $map.get (local.get $state)(global.get $gstack)))
	;; Copy token string before we clear it
	(call $str.catStr (local.get $tokcopy)(local.get $token))
	(call $i32list.push (local.get $stack)(local.get $tokcopy))
	(call $str.clear (local.get $token))  ;; clear the token string
  )
  (func $pushList (param $state i32)
    (local $newList i32)
	(call $map.set (local.get $state)(global.get $glast)
	  (call $map.get (local.get $state)(global.get $gcur)))
	(local.set $newList (call $i32list.mk))
	(call $map.set (local.get $state)(global.get $gcur)(local.get $newList))
  )
  (func $popList (param $state i32)
	(call $map.set
	  (local.get $state)
	  (global.get $gcur)
	  (call $map.get (local.get $state)(global.get $glast))
	  )
 	  (if (i32.eqz (call $map.get (local.get $state) (global.get $gcur)))
		(call $error2))
  )
  (func $wamTokenize (param $strPtr i32)(result i32)
    (local $token i32)
	(local $tokenStart i32)
	(local $bPos i32)
	(local $buffLen i32)
	(local $byte i32)
	(local $state i32)
	(local $stack i32)
	(local $top i32)
	(local $node i32)
	(local.set $stack (call $i32list.mk))
	(local.set $state (call $i32Map.mk)) ;; memory offsets instead of strings for keys
	(call $map.set (local.get $state)(global.get $ginsideString)(i32.const 0))
	(call $map.set (local.get $state)(global.get $ginsideWhiteSp)(i32.const 0))
	(call $map.set (local.get $state)(global.get $ginsideLineCom)(i32.const 0))
	(call $map.set (local.get $state)(global.get $gstack)(local.get $stack))
	(call $map.set (local.get $state)(global.get $gcur)(local.get $stack))
	(call $map.set (local.get $state)(global.get $glast)(i32.const 0))
	;;(call $print (local.get $state))
	(local.set $buffLen (call $str.getByteLen (local.get $strPtr)))
	(local.set $tokenStart (i32.const 0))
	(local.set $token (call $str.mk))  ;; current token built up here
	(local.set $bPos (i32.const -1))  ;; gets incr before use
	(loop $bLoop
	  (local.set $bPos (i32.add (local.get $bPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $bPos)(local.get $buffLen))
	    (then
		  (local.set $byte (call $str.getByte (local.get $strPtr)(local.get $bPos)))
		  ;; bracket with '<' and '>'
		  (call $byte.print (i32.const 60))(call $byte.print (local.get $byte))(call $byte.print(i32.const 62))
		  ;; LINEFEED
		  (if (i32.eq (local.get $byte) (global.get $LF))
			(then
			  (if (call $map.get (local.get $state)(global.get $ginsideLineCom))
				(call $addToken (local.get $state)(local.get $token)))))
		  ;; TAB/SPACE/LF
		  (if (i32.or (i32.eq (local.get $byte)(global.get $TAB))
				(i32.or
				  (i32.eq (local.get $byte)(global.get $SP))
				  (i32.eq (local.get $byte)(global.get $LF))))
			(then
			  (if 
				(i32.eqz
				  (i32.or
					(i32.or (call $map.get (local.get $state)(global.get $ginsideWhiteSp))
							(call $map.get (local.get $state)(global.get $ginsideString)))
					(call $map.get (local.get $state)(global.get $ginsideLineCom))
				  )
				)
				(then
				  (call $addToken (local.get $state) (local.get $token))
				  (call $map.set (local.get $state) (global.get $ginsideWhiteSp)(i32.const 1))
				)
			  )
			  (call $str.catByte(local.get $token)(local.get $byte))
			  (br $bLoop)
		  ))
		  ;; OPEN PAREN
		  (if (i32.eq (local.get $byte) (global.get $LPAREN))
			(then
			  (if
				(i32.and
				  (i32.eqz (call $map.get (local.get $state)(global.get $ginsideString)))
				  (i32.eqz (call $map.get (local.get $state)(global.get $ginsideLineCom))))
			  (then
				(call $addToken(local.get $state)(local.get $token))
				(call $pushList (local.get $state))
				(br $bLoop)))
			  (call $str.catByte (local.get $token)(local.get $byte)
			  (br $bLoop))))
		  ;; CLOSE PAREN
		  (if (i32.eq (local.get $byte) (global.get $RPAREN))
			(then
			  (if
				(i32.and
				  (i32.eqz (call $map.get (local.get $state)(global.get $ginsideString)))
				  (i32.eqz (call $map.get (local.get $state)(global.get $ginsideLineCom))))
				(then
				  ;;(call $strdata.printwlf(global.get $g$match))
				  ;;(call $str.catByte (local.get $token)(local.get $byte))
				  (call $addToken(local.get $state)(local.get $token))
				  (call $popList (local.get $state))
				  (br $bLoop)))
			  (call $str.catByte (local.get $token)(local.get $byte))
			  (br $bLoop)))
		  ;; SEMI
		  (if (i32.eq (local.get $byte) (global.get $SEMI))
			(then
			  (if 				;; (!insideLineComment && token[tprtr-1]==SEMI
				(i32.and 
				  (i32.eqz
					(call $map.get (local.get $state)(global.get $ginsideLineCom)))
				  (i32.eq 
					(call $str.getLastByte (local.get $token))
					(global.get $SEMI)))
				(then
				  (call $str.drop(local.get $token));; drop the previous SEMI
				  (call $addToken(local.get $state)(local.get $token))
				  (call $str.catByte(local.get $token)(global.get $SEMI))))  ;; push SEMI back on
			  (call $map.set (local.get $state)(global.get $ginsideLineCom) (i32.const 1))
			  (call $str.catByte(local.get $token)(local.get $byte))   ;; second SEMI
			  (br $bLoop)))
		  ;; DOUBLE QUOTE
		  (if (i32.eq (global.get $DBLQUOTE)(local.get $byte))
		    (then
			  (if
				(i32.and
				  (i32.eqz
					(call $map.get (local.get $state)(global.get $ginsideString)))
				  (i32.eqz
					(call $map.get (local.get $state)(global.get $ginsideLineCom))))
				(then
				  (call $addToken (local.get $state)(local.get $token))
				  (call $map.set (local.get $state)(global.get $ginsideString)(i32.const 1))
				  (call $str.catByte (local.get $token)(local.get $byte))
				  (br $bLoop)))
			  (if
				(i32.and
				  (call $map.get (local.get $state)(global.get $ginsideString))
				  (i32.ne
					(call $str.getLastByte (local.get $token))
					(global.get $BACKSLASH)))
				(then
				  (call $str.catByte (local.get $token)(local.get $byte))
				  (call $addToken (local.get $state)(local.get $token))
				  (br $bLoop)))
			  (call $str.catByte (local.get $token)(local.get $byte))
			  (br $bLoop)
			)
		  )
		  ;; DEFAULT
		  (if 
			(i32.and
			  (i32.eqz (call $map.get (local.get $state)(global.get $ginsideString)))
			  (i32.and 
				(i32.eqz (call $map.get (local.get $state)(global.get $ginsideLineCom)))
				(call $map.get (local.get $state)(global.get $ginsideWhiteSp))))
			(call $addToken(local.get $state)(local.get $token)))
		  (call $str.catByte (local.get $token)(local.get $byte))
		  (br $bLoop))))
	(call $print (local.get $state))(call $printlf)
	;;(call $print (global.get $gstack))
	(return (call $map.get (local.get $state)(global.get $gstack)))
  )
  (func $main (export "_start")
	;; Generate .wasm with: wat2wasm --enable-bulk-memory strings/string1.wat
	;; 
	(local $buffer i32)
	(local $wat i32)
    (call $test)
	(local.set $buffer (call $readFile))
	(call $print (call $str.mkdata(global.get $gBytesRead)))
	(call $print(call $str.getByteLen (local.get $buffer))) (call $printlf)
	(local.set $wat (call $wam2wat (local.get $buffer)))
	(call $print (local.get $wat))(call $printlf)
	(call $showMemUsed)
  )
  (func $misc.test (param $testNum i32)(result i32)
	(local $dictptr i32)
	(local $listptr i32)
	(return (i32.const 0))
	(call $showMemUsed)
	(call $print(call $str.mkdata(global.get $gmisc.test.start)))(call $printlf)
	;; Try an i32 list
	(local.set $listptr (call $i32list.mk))
	(call $print (local.get $listptr))(call $printlf)
	(call $i32list.push (local.get $listptr)(i32.const 42))
	(call $i32list.push (local.get $listptr)(i32.const 43))
	(call $print (local.get $listptr))(call $printlf)
	(local.set $dictptr (call $i32Map.mk))
	(call $map.set (local.get $dictptr)(i32.const 3)(i32.const 43))
	(call $map.set (local.get $dictptr)(i32.const 4)(global.get $g$starLoop))
	(call $map.set (local.get $dictptr)(i32.const 5)(i32.const 45))
	(call $print (local.get $dictptr))
	(call $printlf)
	(call $i32list.push (local.get $listptr)(local.get $dictptr))
	(call $print (local.get $listptr))(call $printlf)
	(call $print(call $str.mkdata(global.get $gmisc.test.end)))(call $printlf)
	(call $showMemUsed)
    (i32.const 0)
  )
  (global $testing	i32 (i32.const 42))
  (global $i32L	  	i32	(i32.const 0x6933324C)) ;; 'i32L' type# for i32 lists
												;; needs to match $gi32L
  (global $BStr		i32	(i32.const 0x42537472))	;; 'BStr' type# for byte strings
  (global $Map		i32 (i32.const 0x4D617020))	;; 'Map ' type# for i32 maps
  (global $maxNeg	i32  (i32.const 0x80000000));; (-2147483648)
  (global $TAB	  i32 (i32.const 0x09))			;; U+0009	Tab
  (global $LF	  i32 (i32.const 0x0A))			;; U+000A   Line Feed
  (global $CR	  i32 (i32.const 0x0D))			;; U+000D   Carriage Return
  (global $SP	  i32 (i32.const 0x20))			;; U+0020	Space
  (global $BANG		i32 (i32.const 0x21))		;; U+0021	Exclamation Mark !
  (global $DBLQUOTE i32 (i32.const 0x22))		;; U+0022	Double Quote "
  (global $UTF8-1 i32 (i32.const 0x24))  		;; U+0024	Dollar sign $
  (global $DOLLARSIGN i32 (i32.const 0x24))  	;; U+0024	Dollar sign $
  (global $LPAREN i32 (i32.const 0x28))			;; U+0028   Left Parenthesis (
  (global $RPAREN i32 (i32.const 0x29))			;; U+0029   Right Parenthesis )
  (global $zero   i32 (i32.const 0x30))			;; U+0030 	Digit Zero 0
  (global $ASTERISK i32 (i32.const 0x2A))		;; U+002A	Asterisk *
  (global $COMMA  i32 (i32.const 0x2C))			;; U+002C	Comma ,
  (global $SEMI	i32 (i32.const 0x3B))			;; U+003B	Semicolon ;
  (global $LSQBRACK i32 (i32.const 0x5B))		;; U+005B	Left Square Bracket [
  (global $RSQBRACK i32 (i32.const 0x5D))		;; U+005D	Right Square Bracket [
  (global $FULLSTOP i32 (i32.const 0x2E))		;; U+002E	Full Stop .
  (global $BACKSLASH i32 (i32.const 0x5C))		;; U+005C	Back Slash \ 
  (global $CIRCUMFLEX i32 (i32.const 0x5E))		;; U+005E	Circumflex Accent ^
  (global $LBRACE	i32 (i32.const 0x7B))		;; U+007B	Left Curly Bracket {
  (global $RBRACE	i32 (i32.const 0x7D))		;; U+007B	Right Curly Bracket }
  (global $UTF8-2 i32 (i32.const 0xC2A2))		;; U+00A2	Cent sign
  (global $UTF8-3 i32 (i32.const 0xE0A4B9))		;; U+0939	Devanagari Letter Ha
  (global $UTF8-4 i32 (i32.const 0xF0908D88))	;; U+10348	Gothic Letter Hwair
  (data (i32.const 3000) "AAA\00")			(global $gAAA i32	(i32.const 3000)) ;;KEEP FIRST
  (data (i32.const 3020) "at \00")			(global $gat i32		(i32.const 3020))
  (data (i32.const 3030) "realloc\00")		(global $grealloc i32	(i32.const 3030))
  (data (i32.const 3040) "ABCDEF\00")		(global $gABCDEF i32	(i32.const 3040))
  (data (i32.const 3080) "FEDCBA\00")		(global $gFEDCBA i32	(i32.const 3080))
  (data (i32.const 3100) "AAAZZZ\00")		(global $gAAAZZZ i32	(i32.const 3100))
  (data (i32.const 3110) "AbCDbE\00")		(global $gAbCDbE i32 (i32.const 3110))
  (data (i32.const 3120) ">aaa\0A\00")		(global $gaaa i32 (i32.const 3120))
  (data (i32.const 3130) ">bbb\0A\00")		(global $gbbb i32 (i32.const 3130))
  (data (i32.const 3140) ">ccc\0A\00")		(global $gccc i32 (i32.const 3140))
  (data (i32.const 3150) ">ddd\0A\00")		(global $gddd i32 (i32.const 3150))
  (data (i32.const 3160) "(CHAR \00")		(global $gpCHAR i32 (i32.const 3160))
  (data (i32.const 3180) "CD\00")			(global $gCD i32 (i32.const 3180))
  (data (i32.const 3190) "^A\00")			(global $g^A i32 (i32.const 3190))
  (data (i32.const 3200) "^B\00")			(global $g^B i32 (i32.const 3200))
  (data (i32.const 3210) "^A$\00")			(global $g^A$ i32 (i32.const 3210))
  (data (i32.const 3220) "A\00")			(global $gA	i32 (i32.const 3220))
  (data (i32.const 3230) "^ABCDEF$\00")		(global $g^ABCDEF$ i32 (i32.const 3230))
  (data (i32.const 3240) "$match\00")		(global $g$match i32 (i32.const 3240))
  (data (i32.const 3250) "$matchHere\00")	(global $g$matchHere i32 (i32.const 3250))
  (data (i32.const 3270) "$matchStar\00")	(global $g$matchStar i32 (i32.const 3270))
  (data (i32.const 3290) "re: \00")			(global $gre: i32 (i32.const 3290))
  (data (i32.const 3300) "End of text?\00")	(global $gEndoftext? i32 (i32.const 3300))
  (data (i32.const 3320) ".*\00")			(global $g.* i32 (i32.const 3320))
  (data (i32.const 3325) ".*F\00")			(global $g.*F i32 (i32.const 3325))
  (data (i32.const 3330) "$starLoop\00")	(global $g$starLoop i32 (i32.const 3330))
  (data (i32.const 3345) "Bytes Read \00")	(global $gBytesRead i32 (i32.const 3345))
  (data (i32.const 3360) "Tokens:\00")		(global $gTokens: i32 (i32.const 3360))
  (data (i32.const 3370) "LF\00")			(global $gLF i32 (i32.const 3370))
  (data (i32.const 3375) "Cur Mem use: \00")	(global $gCurMemUse i32 (i32.const 3375))
  (data (i32.const 3390) ";\00")			(global $gSEMI i32 (i32.const 3390))
  (data (i32.const 3395) "Found\00")		(global $gFound i32 (i32.const 3395))
  (data (i32.const 3405) "strMap\00")		(global $gstrMap i32 (i32.const 3405))
  (data (i32.const 3415) "=?\00")			(global $g=? i32 (i32.const 3415))
  (data (i32.const 3420) "Setting map\00")	(global $gSettingMap i32 (i32.const 3420))
  (data (i32.const 3435) "Resetting\00")	(global $gResetting i32 (i32.const 3435))
  (data (i32.const 3450) "i32Comparing\00")	(global $gi32Comparing i32 (i32.const 3450))
  (data (i32.const 3470) "strComparing\00")	(global $gstrComparing i32 (i32.const 3470))
  (data (i32.const 3490) "compareOffset\00")(global $gcompareOffset i32 (i32.const 3490))
  (data (i32.const 3500) "insideString\00")	(global $ginsideString  i32 (i32.const 3500))
  (data (i32.const 3515) "insideWhitesp\00")(global $ginsideWhiteSp i32 (i32.const 3515))
  (data (i32.const 3530) "insideLineCom\00")(global $ginsideLineCom i32 (i32.const 3530))
  (data (i32.const 3545) "tptr\00")			(global $gtptr i32 (i32.const 3545))
  (data (i32.const 3555) "stack\00")		(global $gstack i32 (i32.const 3555))
  (data (i32.const 3570) " addToken: '\00")	(global $gaddToken: i32 (i32.const 3570))
  (data (i32.const 3585) "skipping\00")		(global $gskipping i32 (i32.const 3585))
  (data (i32.const 3595) "#toks found:\00") (global $gntoksfound i32 (i32.const 3595))
  (data (i32.const 3610) "cur\00")			(global $gcur i32 (i32.const 3610))
  (data (i32.const 3620) "last\00")			(global $glast i32 (i32.const 3620))
  (data (i32.const 3630) "Unable to print:\00")(global $gUnableToPrint i32 (i32.const 3630))
  (data (i32.const 3650) "Print Ptr:\00")	(global $gPrintPtr i32 (i32.const 3650))
  (data (i32.const 3665) "i32L\00")			(global $gi32L i32 (i32.const 3665))
  (data (i32.const 3670) "Max used: \00")	(global $gMaxUsed i32 (i32.const 3670))
  (data (i32.const 3685) "Mem Reclaimed: \00")(global $gMemReclaimed i32 (i32.const 3685))
  (data (i32.const 3705) "Start $misc.test\00")(global $gmisc.test.start i32 (i32.const 3705))
  (data (i32.const 3725) "End $misc.test\00")(global $gmisc.test.end i32(i32.const 3725))
  (data (i32.const 4000) "ZZZ\00")			(global $gZZZ 	i32 (i32.const 4000)) ;;KEEP LAST
)

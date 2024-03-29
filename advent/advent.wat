;; run via "wasmtime run string1.wat" 
;; (wasmtime recognizes the func exported as "_start")
;; or "wasmtime string1.wasm" if it has been compiled by
;; "wat2wasm --enable-bulk-memory string1.wat"
;; run tests: "wasmtime run advent.wat --invoke _test"
(module
  (import "wasi_unstable" "fd_read"
	(func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write"
	(func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1024)
  (export "memory" (memory 0))

  ;; test function signatures
  (type $testSig (func (param i32)(result i32)))
  
  ;; comparison func signatures used by map
  (type $keyCompSig (func (param i32)(param i32)(result i32)))
  (type $keytoStrSig (func (param i32)(result i32)))

  (table 35 funcref)  ;; must be >= to length of elem
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
	$toStr.test				;;21
	$emptyStr.test			;;22
	$i32list.pop.test		;;23
	$misc.test				;;24
	$str.toI32.test			;;25
	$i32list.set@.test		;;26
	$i64list.mk.test		;;27
	$i64list.push.test		;;28
  )
  (global $numTests i32 (i32.const 28));; should match # tests in table
  (global $firstTestOffset 	i32 (i32.const 4))
  (global $strCompareOffset i32 (i32.const 0))
  (global $strToStrOffset	i32 (i32.const 1))
  (global $i32CompareOffset i32 (i32.const 2))
  (global $i32ToStrOffset	i32 (i32.const 3))
  (global $readIOVsOff0 	i32 (i32.const 100))
  (global $readIOVsOff4 	i32 (i32.const 104))
  (global $readBuffOff 		i32 (i32.const 200))	;; Need to be moved!
  (global $readBuffLen 		i32 (i32.const 2000))	;; Allocated later
  (global $writeIOVsOff0 	i32 (i32.const 2300))
  (global $writeIOVsOff4 	i32 (i32.const 2304))
  (global $writeBuffOff 	i32 (i32.const 2400))
  (global $writeBufLen 		i32 (i32.const 512))
  (global $nextFreeMem (mut i32)(i32.const 6000))
  (global $firstFreeMem 	i32 (i32.const 6000))
  (global $maxFreeMem  (mut i32)(i32.const 6000)) ;; same as initial $firstFreeMem
  (global $memReclaimed(mut i32)(i32.const 0))
  (global $memReclamations (mut i32)(i32.const 0))
  (global $debugW2W 	(mut i32)(i32.const 0))
  
  (func $showMemUsedHelper (param $numBytes i32)(param $msg i32)
    (call $str.print (local.get $msg))
	(call $i32.print (local.get $numBytes))(call $printsp)
	(call $byte.print (global.get $LPAREN))
	(call $i32.print
	  (i32.shr_u (local.get $numBytes) (global.get $LF)));;??????
	(call $C.print (i32.const 75)) ;; K
	(call $C.print (global.get $RPAREN))
	(call $C.print (global.get $LF))
  )
  (func $showMemUsed 
    (local $bytesUsed i32)
	(local $memUsedMsg i32)
	(local $maxUsedMsg i32)
	(local $memReclaimedMsg i32)
	(local $memReclamationsMsg i32)
	(local $maxUsed i32)
	(local.set $memUsedMsg (call $str.mkdata (global.get $gCurMemUse)))
	(local.set $maxUsedMsg (call $str.mkdata (global.get $gMaxUsed)))
	(local.set $memReclaimedMsg (call $str.mkdata (global.get $gMemReclaimed)))
	(local.set $memReclamationsMsg (call $str.mkdata (global.get $gMemReclamations)))
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
	(call $showMemUsedHelper (global.get $memReclamations)(local.get $memReclamationsMsg))
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
    ;;(return)
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
	(global.set $memReclamations (i32.add (global.get $memReclamations)(i32.const 1)))
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
  (func $typeError (param $typeFound i32)(param $typeExpected i32)
    (call $printwsp (global.get $gExpectedType))
	(call $printwlf (call $typeNum.toStr (local.get $typeExpected)))
	(call $printwsp (global.get $gFound:))
	(call $printwlf (call $typeNum.toStr (local.get $typeFound)))
	(call $error2)
  )
  (func $boundsError (param $pos i32)(param $max i32)
    (call $printwsp (global.get $gBoundsError))
	(call $printwsp (local.get $pos))
	(call $printwlf (local.get $max))
	(call $error2)
  )
  (func $print (param $ptr i32)
    ;; 'Universal' print function
	(local $nextFreeMem i32)
	(local.set $nextFreeMem (global.get $nextFreeMem))
    (call $str.print (call $toStr (local.get $ptr)))
 	(call $reclaimMem (local.get $nextFreeMem))
 )
  (func $printsp (call $byte.print (global.get $SP)))
  (func $printwsp (param $ptr i32)
	(call $print (local.get $ptr))
	(call $printsp)
  )
  (func $printlf (call $byte.print (global.get $LF)))
  (func $printwlf (param $ptr i32)
	(call $print (local.get $ptr))
	(call $printlf)
  )
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
	  (return (call $str.mkdata(local.get $ptr))))
	(call $i32.toStr (local.get $ptr))
  )
  (func $toStr.test (param $testNum i32)(result i32)
	(local $list i32)
	(local $map i32)
	(local.set $list (call $i32list.mk))
	(if
	  (i32.eqz (call $str.compare
		(call $toStr (local.get $list))
		(call $str.mkdata (global.get $gDblBrack))))
	  (return (i32.const 1)))
	(call $i32list.push (local.get $list)(call $i32list.mk))
	(if
	  (i32.eqz (call $str.compare
		(call $toStr (local.get $list))
		(call $str.mkdata (global.get $gDblDblBrack))))
	  (return (i32.const 2)))
	(local.set $map (call $i32Map.mk))
	(if
	  (i32.eqz (call $str.compare
		(call $toStr (local.get $map))
		(call $str.mkdata (global.get $gDblBrace))))
	  (return (i32.const 3)))
	(local.set $list (call $i32list.mk))
	(call $i32list.push (local.get $list)(call $strMap.mk))
	(if
	  (i32.eqz (call $str.compare
		(call $toStr (local.get $list))
		(call $str.mkdata (global.get $gBrackedBrace))))
	  (return (i32.const 4)))
	(return (i32.const 0))
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
	  (then
		(call $str.catByte (local.get $strPtr)(global.get $DBLQUOTE))
		(call $str.catStr (local.get $strPtr)(local.get $ptr))
		(call $str.catByte (local.get $strPtr)(global.get $DBLQUOTE))
		(return (local.get $strPtr))))
	(if (i32.eq (local.get $type)(global.get $i32L))
	  (call $str.catStr 
		  (local.get $strPtr)
		  (call $i32list.toStr (local.get $ptr)))
	  (return (local.get $strPtr)))
	(if (i32.eq (local.get $type)(global.get $i64L))
	  (call $str.catStr 
		  (local.get $strPtr)
		  (call $i64list.toStr (local.get $ptr)))
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
	(call $str.print (call $i32.toStr (local.get $N)))
  )
  (func $i32.toStr (param $N i32)(result i32)
	;; return a string representing an i32
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $i32.toStrHelper (local.get $strPtr)(local.get $N))
	(local.get $strPtr)
  )
  (func $i32.toStrHelper(param $strPtr i32)(param $N i32)
    (if (i32.eq (local.get $N)(global.get $maxNeg))
	  (then
		(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gMaxNegAsString)))
		 return))
	(if (i32.lt_s (local.get $N)(i32.const 0))
	  (then
		(call $str.catByte(local.get $strPtr)(i32.const 45))  ;; hyphen
		(call $i32.toStrHelper (local.get $strPtr)(i32.sub (i32.const 0)(local.get $N)))
		return))
    (if (i32.ge_u (local.get $N)(i32.const 10))
	  (call $i32.toStrHelper
		(local.get $strPtr)
		(i32.div_u (local.get $N)(i32.const 10))))
	(call $str.catByte (local.get $strPtr)
	  (i32.add
		(i32.rem_u (local.get $N)(i32.const 10))
		(global.get $zero)))
  )
  (func $i64.print (param $N i64)
	(call $str.print (call $i64.toStr (local.get $N)))
  )
  (func $i64.toStr (param $N i64)(result i32)
	;; return a string representing an i32
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $i64.toStrHelper (local.get $strPtr)(local.get $N))
	(local.get $strPtr)
  )
  (func $i64.toStrHelper(param $strPtr i32)(param $N i64)
    (if (i64.eq (local.get $N)(global.get $maxNeg64))
	  (then
		(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gMaxNeg64AsString)))
		 return))
	(if (i64.lt_s (local.get $N)(i64.const 0))
	  (then
		(call $str.catByte(local.get $strPtr)(i32.const 45))  ;; hyphen
		(call $i64.toStrHelper (local.get $strPtr)(i64.sub (i64.const 0)(local.get $N)))
		return))
    (if (i64.ge_u (local.get $N)(i64.const 10))
	  (call $i64.toStrHelper
		(local.get $strPtr)
		(i64.div_u (local.get $N)(i64.const 10))))
	(call $str.catByte (local.get $strPtr)
	  (i32.add
		(i32.wrap_i64 (i64.rem_u (local.get $N)(i64.const 10)))
		(global.get $zero)))
  )
  ;; from www.geeksforgeeks.org/quick-sort
  ;; fixed by using StackOverflow examp by BartoszKP
  (func $i32list.qsort (param $listPtr i32)(param $low i32)(param $high i32)
    (local $pi i32)  ;; partitioning index
	;; (call $printwsp (local.get $listPtr))
	;; (call $printwsp (global.get $gS))
	;; (call $i32.print (local.get $low))(call $printsp)
	;; (call $i32.print (local.get $high))(call $printlf)
	(if (i32.lt_s (local.get $low)(local.get $high))
	  (then
		(local.set $pi (call $i32list.partition (local.get $listPtr)(local.get $low)(local.get $high)))
		;;(call $printwsp (global.get $gP))(call $i32.print (local.get $pi))(call $printlf)
		(call $i32list.qsort(local.get $listPtr)(local.get $low)(i32.sub (local.get $pi)(i32.const 1)))
		(call $i32list.qsort(local.get $listPtr)(i32.add (local.get $pi)(i32.const 1))(local.get $high))
	  )
	)
  )
  (func $i32list.partition (param $listPtr i32)(param $low i32)(param $high i32)(result i32)
	(local $pivot i32)(local $i i32)(local $j i32);;(local $highMinus1 i32)
	(local.set $pivot (call $i32list.get@ (local.get $listPtr)(local.get $high)))
	(local.set $i (i32.sub (local.get $low)(i32.const 1)))
	;;(local.set $highMinus1 (i32.sub (local.get $high)(i32.const 1)))
	(local.set $j (local.get $low))
	(loop $swapLoop
	  (if (i32.le_s (local.get $j)(local.get $high))  ;; was highMinu1 instead of just $high
		(then
		  (if (i32.lt_s (call $i32list.get@ (local.get $listPtr)(local.get $j))(local.get $pivot))
			(then
			  (local.set $i (i32.add (local.get $i)(i32.const 1)))
			  (call $i32list.swap (local.get $listPtr)(local.get $i)(local.get $j))
			)
		  )
		(local.set $j (i32.add (local.get $j)(i32.const 1)))
		(br $swapLoop)
		)
	  )
	)
	(call $i32list.swap (local.get $listPtr)(i32.add (local.get $i)(i32.const 1))(local.get $high))
	(i32.add (local.get $i)(i32.const 1))
  )
  (func $i32list.swap (param $listPtr i32)(param $i i32)(param $j i32)
    (local $temp i32)
	(local.set $temp (call $i32list.get@ (local.get $listPtr)(local.get $i)))
	(call $i32list.set@ (local.get $listPtr)(local.get $i)
		(call $i32list.get@ (local.get $listPtr)(local.get $j)))
	(call $i32list.set@ (local.get $listPtr)(local.get $j)(local.get $temp))
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
  (func $i32.min (param $a i32)(param $b i32)(result i32)
	(if (i32.le_s (local.get $a)(local.get $b))
	  (return (local.get $a)))
	(local.get $b)
  )
  (func $i32.max (param $a i32)(param $b i32)(result i32)
	(if (i32.ge_s (local.get $a)(local.get $b))
	  (return (local.get $a)))
	(local.get $b)
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
  (func $advent1 (export "_advent1")
    (local $buffer i32)
	(call $strdata.printwlf(global.get $gAdvent1!))
	(local.set $buffer (call $readFile))
	(call $printwsp (call $str.mkdata(global.get $gBytesRead)))
	(call $print(call $str.getByteLen (local.get $buffer))) (call $printlf)
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
	(if (i32.ne 
		  (call $getTypeNum (local.get $lstPtr))
		  (global.get $i32L))
		(call $typeError
			(call $getTypeNum (local.get $lstPtr))
			(global.get $i32L)
		)
	)
	(local.set $dataOff (call $i32list.getDataOff (local.get $lstPtr)))
	(local.set $dataOffOff
		(i32.add (local.get $dataOff)
		  (i32.mul (local.get $pos)(i32.const 4))))
    (i32.store (local.get $dataOffOff) (local.get $val))
  )
  (func $i32list.get@ (param $lstPtr i32)(param $pos i32)(result i32)
	;; Needs bounds test  ;; added typecheck 2021-12-19
	(if (i32.ne 
		  (call $getTypeNum (local.get $lstPtr))
		  (global.get $i32L))
		(call $typeError
			(call $getTypeNum (local.get $lstPtr))
			(global.get $i32L)
		)
	)
	(if (i32.ge_u (local.get $pos)(call $i32list.getCurLen (local.get $lstPtr)))
	  (call $boundsError (local.get $pos)(call $i32list.getCurLen (local.get $lstPtr))))
	(i32.load
		(i32.add (call $i32list.getDataOff (local.get $lstPtr))
				 (i32.mul (i32.const 4) (local.get $pos))))
  )
  (func $i32list.set@.test (param $testNum i32)(result i32)
    (local $listPtr i32)
	(local.set $listPtr (call $i32list.mk))
	(call $i32list.set@ (local.get $listPtr)(i32.const 0)(i32.const 33)) ;; should fail
	(i32.const 0)
  )
  (func $i32list.tail (param $lstPtr i32)(result i32)
	(local $curLen i32)
	(local.set $curLen (call $i32list.getCurLen(local.get $lstPtr)))
	(if (i32.eqz (local.get $curLen))  (call $error2))
	(call $i32list.get@
	  (local.get $lstPtr)
	  (i32.sub (local.get $curLen)(i32.const 1)))
  )
  ;; Add element to the end of the list
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
    (local $curLen i32)
	(local $lastPos i32)
	(local $popped i32)
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
  (func $i32list.pop.test (param $testNum i32)(result i32)
	(local $lstPtr i32)
	(local $temp i32)
	(local.set $lstPtr (call $i32list.mk))
	(call $i32list.push (local.get $lstPtr)(i32.const 42))
	(call $i32list.push (local.get $lstPtr)(i32.const 43))
	(local.set $temp (call $i32list.pop (local.get $lstPtr)))
	(if (i32.ne (local.get $temp)(i32.const 43))
	  (return (i32.const 1)))
	(local.set $temp (call $i32list.pop (local.get $lstPtr)))
	(if (i32.ne (local.get $temp)(i32.const 42))
	  (return (i32.const 2)))
	(return (call $i32list.getCurLen (local.get $lstPtr)))
  )
  (func $i32list.push.test (param $testNum i32)(result i32)
    (local $lstPtr i32)
	(local $temp i32)
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
  (func $i64list.toStr (param $lstPtr i32)(result i32)
	(local $strPtr i32)
	(local $strTmp i32)
	(local $curLength i32)
	(local $ipos i32)
	(local.set $strPtr (call $str.mk))
	(local.set $curLength (call $i32list.getCurLen (local.get $lstPtr)))
	(call $str.catByte (local.get $strPtr)(global.get $LSQBRACK))
	(local.set $ipos (i32.const 0))
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (local.set $strTmp (call $i64.toStr (call $i64list.get@ (local.get $lstPtr)(local.get $ipos))))
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
  (func $i64list.mk (result i32)
	;; returns a memory offset for an i64list pointer:
	;; 		typeNum, curLength, maxLength, dataOffset
	;;		4 bytes	  4 bytes    4 bytes	4 bytes  (same as i32list)
	;; Reserves room for up to 10 64-bit values (80 bytes of potential data)
	(local $lstPtr i32)
	(local.set $lstPtr (call $getMem (i32.const 96))) ;; 80 +16
	(call $setTypeNum (local.get $lstPtr)(global.get $i64L))
	(call $i64list.setCurLen (local.get $lstPtr) (i32.const 0))
	(call $i64list.setMaxLen (local.get $lstPtr)(i32.const 10))
	(call $i64list.setDataOff(local.get $lstPtr)
		(i32.add(local.get $lstPtr)(i32.const 16))) ;; 16 bytes for header info
	(local.get $lstPtr)  ;; return ptr to the new list
  )
  (func $i64list.getCurLen(param $lstPtr i32)(result i32)
    (call $i32list.getCurLen (local.get $lstPtr))
  )
  (func $i64list.setCurLen (param $lstPtr i32)(param $newLen i32)
    (call $i32list.setCurLen (local.get $lstPtr)(local.get $newLen))
  )
  (func $i64list.getMaxLen (param $lstPtr i32)(result i32)
    (call $i32list.getMaxLen (local.get $lstPtr))
  )
  (func $i64list.setMaxLen (param $lstPtr i32)(param $newMaxLen i32)
	(call $i32list.setMaxLen (local.get $lstPtr)(local.get $newMaxLen))
  )
  (func $i64list.getDataOff (param $lstPtr i32)(result i32)
    (call $i32list.getDataOff (local.get $lstPtr))
  )
  (func $i64list.setDataOff (param $lstPtr i32)(param $newDataOff i32)
    (call $i32list.setDataOff (local.get $lstPtr)(local.get $newDataOff))
  )
  (func $i64list.mk.test (param $testNum i32)(result i32)
	(local $lstPtr i32)
	(local.set $lstPtr (call $i64list.mk))
	(if (i32.ne 
		  (call $getTypeNum (local.get $lstPtr))
		  (global.get $i64L))
	  (return (i32.const 1)))
	(if (i32.ne (call $i64list.getCurLen (local.get $lstPtr))(i32.const 0)) ;; should be False
		  (return (i32.const 2)))
	(i32.const 0) ;; OK
  )
  ;; Add element to the end of the list
  (func $i64list.push (param $lstPtr i32)(param $val i64)
	(local $maxLen i32) (local $curLen i32)
	(local.set $curLen (call $i64list.getCurLen(local.get $lstPtr)))
	(local.set $maxLen (call $i64list.getMaxLen(local.get $lstPtr)))
	(if (i32.ge_u (local.get $curLen) (local.get $maxLen));;fail reallocation
		(then
		  (call $error2)  ;; $i64list.extend not yet implemented
		  ;;(call $i64list.extend (local.get $lstPtr))
		  ;;(local.set $maxLen (call $i64list.getMaxLen(local.get $lstPtr)))
		))
	(call $i64list.set@ (local.get $lstPtr)(local.get $curLen)(local.get $val))
	(call $i64list.setCurLen (local.get $lstPtr)
		(i32.add (local.get $curLen)(i32.const 1)))
  )
  (func $i64list.push.test (param $testNum i32)(result i32)
    (local $lstPtr i32)
	(local $temp i64)
	(local.set $lstPtr (call $i64list.mk))
	(call $i64list.push (local.get $lstPtr) (i64.const 3))
	(if (i32.ne
	  (i32.const 1)
	  (call $i64list.getCurLen (local.get $lstPtr)))
	  (return (i32.const 1)))
	(local.set $temp (call $i64list.pop (local.get $lstPtr)))
	(if (i64.ne (i64.const 3) (local.get $temp))
	  (return (i32.const 2)))
	(if (i32.ne
	  (i32.const 0)
	  (call $i32list.getCurLen (local.get $lstPtr)))
	  (return (i32.const 3)))
	(i32.const 0) ;; passed
  )
  (func $i64list.pop (param $lstPtr i32)(result i64)
    (local $curLen i32)
	(local $lastPos i32)
	(local $popped i64)
    (local.set $curLen (call $i64list.getCurLen(local.get $lstPtr)))
	(if (i32.eqz (local.get $curLen))
	  (call $error2))
	(local.set $lastPos (i32.sub (local.get $curLen)(i32.const 1)))
	(local.set $popped (call $i64list.get@
	    (local.get $lstPtr)(local.get $lastPos)))
	(call $i64list.setCurLen
	  (local.get $lstPtr)
	  (local.get $lastPos))
	(local.get $popped)
  )
  (func $i64list.set@ (param $lstPtr i32)(param $pos i32)(param $val i64)
	;; Needs bounds tests
    (local $dataOff i32)
	(local $dataOffOff i32)
	(if (i32.ne 
		  (call $getTypeNum (local.get $lstPtr))
		  (global.get $i64L))
		(call $typeError
			(call $getTypeNum (local.get $lstPtr))
			(global.get $i64L)
		)
	)
	(local.set $dataOff (call $i32list.getDataOff (local.get $lstPtr)))
	(local.set $dataOffOff
		(i32.add (local.get $dataOff)
		  (i32.mul (local.get $pos)(i32.const 8))))
    (i64.store (local.get $dataOffOff) (local.get $val))
  )
  (func $i64list.get@ (param $lstPtr i32)(param $pos i32)(result i64)
	;; Needs bounds test  ;; added typecheck 2021-12-19
	(if (i32.ne 
		  (call $getTypeNum (local.get $lstPtr))
		  (global.get $i64L))
		(call $typeError
			(call $getTypeNum (local.get $lstPtr))
			(global.get $i64L)
		)
	)
	(if (i32.ge_u (local.get $pos)(call $i64list.getCurLen (local.get $lstPtr)))
	  (call $boundsError (local.get $pos)(call $i64list.getCurLen (local.get $lstPtr))))
	(i64.load
		(i32.add (call $i64list.getDataOff (local.get $lstPtr))
				 (i32.mul (i32.const 8) (local.get $pos))))
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
    (local $AAA i32)(local $ZZZ i32)(local $aaa i32)
	(local.set $AAA (call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ (call $str.mkdata (global.get $gZZZ)))
	;; (call $printwlf (local.get $AAA))
	;; (call $printwlf (local.get $ZZZ))
	(local.set $aaa (call $str.mk))
	(call $str.catStr (local.get $aaa)(local.get $AAA))
	(call $str.catStr (local.get $aaa)(local.get $ZZZ))
	;; $AAA string now has $ZZZ concatenated onto it!
	;; (call $printwlf (local.get $AAA))
	;; (call $printwlf (local.get $ZZZ))
	;; (call $printwlf (local.get $aaa))
	(i32.eqz
	  (call $str.compare
		(local.get $aaa) 
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
	;; Modified 1021-12-08 to not point to the original data
	;; Slower, but concatenation, etc. should now be safe
    ;; Make a string from null-terminated chunk of memory
	;; null terminator is not counted as part of string
	;; Should work with UTF-8?
	;;(local $length i32)
	(local $curByte i32)(local $strPtr i32)
	;;(local.set $length (i32.const 0))
	;; (loop $cLoop
		;; (local.set $curByte (i32.load8_u (i32.add (local.get $length)(local.get $dataOffset))))
		;; (if (i32.ne (i32.const 0)(local.get $curByte)) ;; checking for null
		  ;; (then
		    ;; (local.set $length (i32.add (local.get $length)(i32.const 1)))
			;; (br $cLoop)
	;; )))
	;; (local.set $strPtr (call $getMem (i32.const 16)))  ;; just room for pointer info
	;; (call $setTypeNum (local.get $strPtr)(global.get $BStr))
	;; (call $str.setByteLen (local.get $strPtr)(local.get $length))
	;; (call $str.setMaxLen (local.get $strPtr)(local.get $length))
	;; (call $str.setDataOff (local.get $strPtr)(local.get $dataOffset))
	(local.set $strPtr (call $str.mk))
	(loop $bLoop
	  (local.set $curByte (i32.load8_u (local.get $dataOffset)))
	  (if (local.get $curByte)
		(then
		  (call $str.catByte (local.get $strPtr)(local.get $curByte))
		  (local.set $dataOffset (i32.add (local.get $dataOffset)(i32.const 1)))
		  (br $bLoop)))
	)
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
  (func $strdata.printwlf (param $global i32)
    (call $printwlf (call $str.mkdata (local.get $global)))
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
	;;(call $print (local.get $testNum))(call $printwlf (global.get $gFloop))
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
	;; 2021.12.11 Multiple break characters in a row are collapsed
	(local $splitList i32) (local $strCum i32) (local $bpos i32)(local $inSplit i32)
	(local $byte i32) (local $strLen i32)
	(local.set $splitList (call $i32list.mk))
	(local.set $strCum (call $str.mk)) ;; accumulates chars
	(local.set $bpos (i32.const 0))
	(local.set $strLen (call $str.getByteLen (local.get $toSplit)))
	(local.set $inSplit (i32.const 0))  ;; last character was not the split char
	(loop $bloop
	  (if (i32.lt_u (local.get $bpos)(local.get $strLen))
	    (then
		  (local.set $byte (call $str.getByte (local.get $toSplit)(local.get $bpos)))
		  (if (i32.ne (local.get $byte)(local.get $splitC))
		    (then
			  (call $str.catByte (local.get $strCum)(local.get $byte))
			)
			(else ;; break char
			  (if (call $str.getByteLen (local.get $strCum))
				(then
				  (call $i32list.push (local.get $splitList)(local.get $strCum))
				  (local.set $strCum (call $str.mk))
				)
			  )
			)
		  )
		  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
		  (br $bloop)
		)
	  )
	)
	(if (call $str.getByteLen (local.get $strCum))
	  (call $i32list.push (local.get $splitList)(local.get $strCum)))
	(local.get $splitList)
  )
  (func $str.Csplit.test (param $testNum i32)(result i32)
	;; The split character is not part of the split pieces
	(local $AbCDbE i32)(local $AbCDbbE i32)(local $listPtr i32)(local $strptr0 i32)
	(local.set $AbCDbE (call $str.mkdata (global.get $gAbCDbE)))
	(local.set $AbCDbbE (call $str.mkdata (global.get $gAbCDbbE)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 98)))  ;; 'b'
	;;(call $printwlf (local.get $listPtr))
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr))(i32.const 3))
	  (return (i32.const 1)))
	  ;;(call $print (local.get $listPtr)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 69)))  ;; 'E'
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr))(i32.const 1))
	  (return (i32.const 2)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 122)))  ;; 'z'
	(local.set $strptr0 (call $i32list.get@ (local.get $listPtr)(i32.const 0)))
	(if (i32.eqz 
		  (call $str.compare
			(call $i32list.get@ (local.get $listPtr)(i32.const 0))
			(local.get $AbCDbE)))
	  (return (i32.const 3)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbbE)(i32.const 98))) ;; split on'b'
	;; test to make sure multiple split characters are treated as a single split
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr))(i32.const 3))
	  (return (i32.const 4))
	  ;;(call $printwlf (local.get $listPtr))
	  )
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
  ;; Needs error checking!
  (func $str.toI32 (param $strPtr i32)(result i32)
	(local $bpos i32)
	(local $sByteLen i32)
	(local $retv i32)
	(local $temp i32)
	(local $byte i32)
	(local.set $bpos (i32.const 0))
	(local.set $retv (i32.const 0))
	(local.set $sByteLen (call $str.getByteLen (local.get $strPtr)))
	(loop $sloop
	  (if (i32.lt_u (local.get $bpos) (local.get $sByteLen))
		(then
		  ;;(call $print (global.get $gFound))
		  (local.set $byte (call $str.getByte (local.get $strPtr)(local.get $bpos)))
		  ;;(call $print (local.get $byte))
		  (if (i32.eq (local.get $byte)(global.get $SP))
		    (then   ;; skip over blanks!
			  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
			  (br $sloop)))
			  
		  (local.set $temp (i32.sub (local.get $byte)(global.get $zero)))
		  ;;(call $i32.print (local.get $temp))
		  (local.set $retv (i32.add (local.get $temp) (i32.mul(local.get $retv)(i32.const 10))))
		  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
		  (br $sloop))))
	;;(call $i32.print (local.get $retv))
	(local.get $retv)
  )
  (func $str.toI32.test (param $testNum i32)(result i32)
    (if
	  (i32.ne (i32.const 123) (call $str.toI32 (call $toStr(global.get $g123text))))
	  (return (i32.const 1)))
	(if
	  (i32.ne (i32.const 0) (call $str.toI32 (call $toStr(global.get $gEmptyString))))
	  (return (i32.const 2)))
    (i32.const 0)
  )
  ;; Expects a string made up of '1' and '0' characters
  (func $str.binToI32 (param $strPtr i32)(result i32)
    (local $bitPos i32)
    (local $strLen i32)
	(local $accum i32)
    (local.set $strLen (call $str.getByteLen (local.get $strPtr)))
    (local.set $bitPos (i32.const 0))
	(local.set $accum (i32.const 0))
	(if (i32.eqz (local.get $strLen)) (return (i32.const 0)))
    (loop $bLoop
	  (local.set $accum (i32.shl (local.get $accum)(i32.const 1)))
	  (if (i32.eq
			(call $str.getByte (local.get $strPtr)(local.get $bitPos))
			(global.get $one))
		  (local.set $accum (i32.or (local.get $accum)(i32.const 1))))
	  (local.set $bitPos (i32.add (local.get $bitPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $bitPos)(local.get $strLen))
	    (br $bLoop))
	)
	(local.get $accum)
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
	;; NOT REALLY!! IT IS JUST RETURNING A LONG STRING
	;; Not UTF-8 safe ?
	(local $listPtr i32)(local $strPtr i32)(local $nread i32)
	(i32.store (global.get $readIOVsOff0) (global.get $readBuffOff))
	(i32.store (global.get $readIOVsOff4) (global.get $readBuffLen))
	(call $fd_read
	  (i32.const 0) ;; 0 for stdin
	  (global.get $readIOVsOff0) ;; *iovs
	  (i32.const 1) ;; iovs_len
	  (global.get $readIOVsOff4) ;; num bytes read goes here
	)
	drop  ;; $fd_read return value
	(local.set $listPtr (call $i32list.mk))
	(local.set $strPtr (call $str.mk))
	(call $str.setDataOff (local.get $strPtr)(global.get $readBuffOff))
	(call $str.setByteLen (local.get $strPtr)(i32.load (global.get $readIOVsOff4)))
	(call $str.setMaxLen (local.get $strPtr)(i32.load (global.get $readIOVsOff4)))
	(local.get $strPtr)
  )
	
  (func $readByte (result i32)
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
	;;(call $i32.print (local.get $nread))(call $printlf)
	(return (i32.load8_u (global.get $readBuffOff)))
	;; (call $print (global.get $gIn:))
	;; (call $i32.print (i32.shr_u (global.get $readBuffOff)(i32.const 18)))
	;; (call $i32.print (local.get $nread)) (call $printlf)
	;; (if (i32.eq (local.get $nread)(i32.const 0))
		;; (return (global.get $maxNeg)))
	;; (local.get $nread)
  )
  (func $readString (result i32)
	(local $strPtr i32)
	(local $byte i32)
	(local.set $strPtr (call $str.mk))
	(loop $bloop
	  (local.set $byte (call $readByte))
	  (if (i32.ge_s (local.get $byte)(i32.const 0))
		(then
		  (if (i32.eq (local.get $byte)(global.get $LF))
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
  (func $readFileSlow (result i32)
	;; reads a file in byte-by-byte and returns a list of string pointers to the lines in it
	(local $listPtr i32)(local $strPtr i32)
	(local.set $listPtr (call $i32list.mk))
	(loop $lineLoop
	  (local.set $strPtr (call $readString))
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
  ;; dummy function for commented out $match
  (func $match.test (param $testNum i32)(result i32)
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
	;;(call $str.catlf (local.get $strPtr))
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
  ;; (func $wam2wat (param $strPtr i32)(result i32)
	;; ;; Accepts WAM file as a string, returns a list of tokens
	;; (local $top i32)
	;; ;;(local $token i32)
	;; ;;(local $numToks i32)
	;; ;;(local $tokPos i32)
	;; (local.set $top (call $wamTokenize (local.get $strPtr)))
	;; ;;(call $print (local.get $wamStack))(call $printlf)
	;; ;;(call $printwsp (global.get $gtop))
	;; (local.get $top) ;; something to return for now
  ;; )
  ;; Tokenization closely follows
  ;; https://github.com/emilbayes/wat-tokenizer/blob/master/index.js
  (func $emptyStr (param $strPtr i32)(result i32)
	(local $bp i32)
	(local $byte i32)
	(local $strLen i32)
	(local.set $strLen (call $str.getByteLen (local.get $strPtr)))
	(if (i32.eqz (local.get $strLen))
	  (return (i32.const 1))) ;; empty
	(local.set $bp (i32.const 0))
	(loop $bloop
	  (local.set $byte (call $str.getByte (local.get $strPtr)(local.get $bp)))
	  (if
	    (i32.and
		  (i32.ne (local.get $byte) (global.get $SP))
		  (i32.ne (local.get $byte) (global.get $TAB)))
		(return (i32.const 0)))  ;; Not empty
	  (local.set $bp (i32.add (local.get $bp)(i32.const 1)))
	  (if (i32.lt_u (local.get $bp)(local.get $strLen))
		(br $bloop))
	)
	(i32.const 1)  ;; empty
  )
  (func $emptyStr.test (param $testNum i32)(result i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(if (i32.eqz (call $emptyStr (local.get $strPtr)))
	  (return (i32.const 1)))  ;; should be empty
	(call $str.catByte (local.get $strPtr)(global.get $SP))
	(if (i32.eqz (call $emptyStr (local.get $strPtr)))
	  (return (i32.const 2)))
	(call $str.catByte (local.get $strPtr)(global.get $TAB))
	(if (i32.eqz (call $emptyStr (local.get $strPtr)))
	  (return (i32.const 4))) ;; tabs count as empty!
	(call $str.catByte (local.get $strPtr)(global.get $DOLLARSIGN))
	(if (call $emptyStr (local.get $strPtr))
	  (return (i32.const 4)))  ;; Not empty
	(i32.const 0) ;; success
  )
  ;; Return a list of pairs from a list.  Each pair is in turn a 2-element list
  (func $pairwise (param $lstPtr i32)(result i32)
	(local $pairPtr i32)(local $lstPos i32)(local $lstLen i32)(local $pairListPtr i32)
	(local.set $lstPos (i32.const 0))
	(local.set $lstLen (call $i32list.getCurLen (local.get $lstPtr)))
	;;(call $printwlf (local.get $lstLen))
	(local.set $pairListPtr (call $i32list.mk)) ;; list of pairs
	(loop $pairLoop
	  ;;(call $printwlf (local.get $lstPos))
	  (local.set $pairPtr (call $i32list.mk))
	  (if		;; no more pairs?
	    (i32.ge_u
		  (i32.add (local.get $lstPos)(i32.const 1))
		  (local.get $lstLen)
		  )
		(return (local.get $pairListPtr)))
	  (call $i32list.push (local.get $pairPtr)
	    (call $i32list.get@
		  (local.get $lstPtr)
		  (local.get $lstPos)))
	  (call $i32list.push (local.get $pairPtr)
	    (call $i32list.get@
		  (local.get $lstPtr)
		  (i32.add (local.get $lstPos)(i32.const 1))))
	  (local.set $lstPos (i32.add (local.get $lstPos)(i32.const 1)))
	  (call $i32list.push (local.get $pairListPtr)(local.get $pairPtr))
	  (br $pairLoop)
	)
	(local.get $pairListPtr)
  )
  (func $tplwise (param $lstPtr i32)(param $winSize i32)(result i32)
	(local $tplPtr i32)(local $lstPos i32)(local $lstLen i32)
	(local $tplListPtr i32)(local $posInTpl i32)
	(local.set $lstPos (i32.const 0))
	(local.set $lstLen (call $i32list.getCurLen (local.get $lstPtr)))
	;;(call $printwlf (local.get $lstLen))
	(local.set $tplListPtr (call $i32list.mk)) ;; list of tuples
	(loop $tplLoop
	  (if		;; no more tuples?
		(i32.ge_u
		  (i32.add (local.get $lstPos)(i32.sub (local.get $winSize)(i32.const 1)))
		  (local.get $lstLen)
		  )
		(return (local.get $tplListPtr)))
	  (local.set $tplPtr (call $i32list.mk))
	  (local.set $posInTpl (i32.const 0))
	  (loop $mkTpl
		(call $i32list.push
		  (local.get $tplPtr)
		  (call $i32list.get@
			(local.get $lstPtr)
			(i32.add (local.get $lstPos)(local.get $posInTpl)))
		)
		(local.set $posInTpl (i32.add (local.get $posInTpl)(i32.const 1)))
		(if (i32.lt_u (local.get $posInTpl)(local.get $winSize))
		  (br $mkTpl))
	  )
	  ;;(call $printwlf (local.get $tplPtr))
	  (call $i32list.push (local.get $tplListPtr)(local.get $tplPtr))
	  (local.set $lstPos (i32.add (local.get $lstPos)(i32.const 1)))
	  (br $tplLoop)
	)
	(local.get $tplListPtr)
  )
  (func $day1 (export "_day1")
    (local $lines i32)(local $pairs i32)(local $greaterCount i32)
	(local $pairsLen i32)(local $pairPos i32)(local $pair i32)
	(local $p1val i32)(local $p2val i32)
	(local.set $lines (call $readFileSlow))
	(local.set $pairs (call $tplwise (local.get $lines)(i32.const 2)))
	(local.set $pairsLen (call $i32list.getCurLen (local.get $pairs)))
	(local.set $greaterCount (i32.const 0))
	(local.set $pairPos (i32.const 0))
	(loop $pairLoop
	  (local.set $pair
		(call $i32list.get@ (local.get $pairs)(local.get $pairPos)))
	  (local.set $p1val (call $str.toI32 (call $i32list.get@ (local.get $pair)(i32.const 0))))
	  (local.set $p2val (call $str.toI32 (call $i32list.get@ (local.get $pair)(i32.const 1))))
	  (if (i32.lt_u (local.get $p1val)(local.get $p2val))
		(local.set $greaterCount (i32.add (local.get $greaterCount)(i32.const 1))))
	  (local.set $pairPos (i32.add (local.get $pairPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $pairPos)(local.get $pairsLen))
	    (br $pairLoop))
	)
	(call $printwlf (local.get $greaterCount))
  )
  (func $day1b (export "_day1b")
    (local $lines i32)(local $tpls i32)(local $greaterCount i32)
	(local $tplsLen i32)(local $tplPos i32)(local $tpl i32)
	(local $t1val i32)(local $t2val i32)(local $t3val i32)
	(local $p1val i32)(local $p2val i32)
	(local $tplSum i32)(local $tplSums i32)
	(local $pairs i32)(local $pairsLen i32)(local $pairPos i32)(local $pair i32)
	(local.set $lines (call $readFileSlow))
	(local.set $tpls (call $tplwise (local.get $lines)(i32.const 3)))
	(local.set $tplsLen (call $i32list.getCurLen (local.get $tpls)))
	(local.set $tplSums (call $i32list.mk))
	(local.set $tplPos (i32.const 0))
	(loop $tplLoop
	  (local.set $tpl
		(call $i32list.get@ (local.get $tpls)(local.get $tplPos)))
	  (local.set $t1val (call $str.toI32 (call $i32list.get@ (local.get $tpl)(i32.const 0))))
	  (local.set $t2val (call $str.toI32 (call $i32list.get@ (local.get $tpl)(i32.const 1))))
	  (local.set $t3val (call $str.toI32 (call $i32list.get@ (local.get $tpl)(i32.const 2))))
	  (local.set $tplSum
		 (i32.add (local.get $t1val)(i32.add (local.get $t2val)(local.get $t3val))))
	  (call $i32list.push (local.get $tplSums)(local.get $tplSum))
	  (local.set $tplPos (i32.add (local.get $tplPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $tplPos)(local.get $tplsLen))
	    (br $tplLoop))
	)
	(local.set $pairs (call $tplwise (local.get $tplSums)(i32.const 2)))
	(local.set $pairsLen (call $i32list.getCurLen (local.get $pairs)))
	(local.set $pairPos (i32.const 0))
	(local.set $greaterCount (i32.const 0))
	(loop $pairLoop
	  (local.set $pair
		(call $i32list.get@ (local.get $pairs)(local.get $pairPos)))
	  (local.set $p1val (call $i32list.get@ (local.get $pair)(i32.const 0)))
	  (local.set $p2val (call $i32list.get@ (local.get $pair)(i32.const 1)))
	  (if (i32.lt_u (local.get $p1val)(local.get $p2val))
		(local.set $greaterCount (i32.add (local.get $greaterCount)(i32.const 1))))
	  (local.set $pairPos (i32.add (local.get $pairPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $pairPos)(local.get $pairsLen))
	    (br $pairLoop))
	)
	(call $printwlf (local.get $greaterCount))
  )
  (func $day2s (export "_day2a")
	(local $lines i32) (local $numLines i32)(local $line i32)
	(local $lineNum i32) (local $splitLine i32)
	(local $horizPos i32) (local $depth i32)
	(local $command i32) (local $param i32)
	(local $str.forward i32)(local $str.down i32)(local $str.up i32)
	(local.set $str.forward (call $str.mkdata (global.get $gforward)))
	(local.set $str.down (call $str.mkdata (global.get $gdown)))
	(local.set $str.up (call $str.mkdata (global.get $gup)))
	(local.set $horizPos (i32.const 0))
	(local.set $depth (i32.const 0))
	(local.set $lines (call $readFileSlow))
	(local.set $numLines (call $i32list.getCurLen (local.get $lines)))
	(call $printwlf (local.get $numLines))
	(local.set $lineNum (i32.const 0))
	(loop $lineLoop  ;; expects at least one line
	  (local.set $line (call $i32list.get@(local.get $lines)(local.get $lineNum)))
	  ;;(call $printwlf (local.get $line))
	  (local.set $splitLine (call $str.Csplit (local.get $line)(global.get $SP)))
	  ;;(call $printwlf (local.get $splitLine))
	  (local.set $command
		(call $i32list.get@ (local.get $splitLine)(i32.const 0)))
	  (local.set $param
		(call $str.toI32 (call $i32list.get@ (local.get $splitLine)(i32.const 1))))
	  (if 
		(call $str.compare (local.get $str.forward) (local.get $command))
		(local.set $horizPos 
			  (i32.add (local.get $horizPos)(local.get $param)))
	  )
	  (if 
		(call $str.compare (local.get $str.down) (local.get $command))
		(local.set $depth 
			  (i32.add (local.get $depth)(local.get $param)))
	  )
	  (if 
		(call $str.compare (local.get $str.up) (local.get $command))
		(local.set $depth 
			  (i32.sub (local.get $depth)(local.get $param)))
	  )
	  (local.set $lineNum (i32.add (local.get $lineNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $lineNum)(local.get $numLines))
	    (br $lineLoop))
	)
	(call $printwlf (local.get $horizPos))
	(call $printwlf (local.get $depth))
	(call $printwlf (i32.mul (local.get $depth)(local.get $horizPos)))
  )
  (func $day2b (export "_day2b")
	(local $lines i32) (local $numLines i32)(local $line i32)
	(local $lineNum i32) (local $splitLine i32)
	(local $horizPos i32) (local $depth i32)(local $aim i32)
	(local $command i32) (local $param i32)
	(local $str.forward i32)(local $str.down i32)(local $str.up i32)
	(local.set $str.forward (call $str.mkdata (global.get $gforward)))
	(local.set $str.down (call $str.mkdata (global.get $gdown)))
	(local.set $str.up (call $str.mkdata (global.get $gup)))
	(local.set $horizPos (i32.const 0))
	(local.set $depth (i32.const 0))
	(local.set $aim (i32.const 0))
	(local.set $lines (call $readFileSlow))
	(local.set $numLines (call $i32list.getCurLen (local.get $lines)))
	(call $printwlf (local.get $numLines))
	(local.set $lineNum (i32.const 0))
	(loop $lineLoop  ;; expects at least one line
	  (local.set $line (call $i32list.get@(local.get $lines)(local.get $lineNum)))
	  ;;(call $printwlf (local.get $line))
	  (local.set $splitLine (call $str.Csplit (local.get $line)(global.get $SP)))
	  (local.set $command
		(call $i32list.get@ (local.get $splitLine)(i32.const 0)))
	  (local.set $param
		(call $str.toI32 (call $i32list.get@ (local.get $splitLine)(i32.const 1))))
	  (if 
		(call $str.compare (local.get $str.forward) (local.get $command))
		(then
		  (local.set $horizPos (i32.add (local.get $horizPos)(local.get $param)))
		  (local.set
			$depth (i32.add (local.get $depth)
						   (i32.mul (local.get $param)(local.get $aim))))
		)
	  )
	  (if 
		(call $str.compare (local.get $str.down) (local.get $command))
		(local.set $aim 
			  (i32.add (local.get $aim)(local.get $param)))
	  )
	  (if 
		(call $str.compare (local.get $str.up) (local.get $command))
		(local.set $aim 
			  (i32.sub (local.get $aim)(local.get $param)))
	  )
	  (local.set $lineNum (i32.add (local.get $lineNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $lineNum)(local.get $numLines))
	    (br $lineLoop))
	)
	(call $printwlf (local.get $horizPos))
	(call $printwlf (local.get $depth))
	(call $printwlf (i32.mul (local.get $depth)(local.get $horizPos)))
  )
  ;; $lines are arrays of bits ('0' & '1')
  ;; $getBits returns a vertical slice of the bits at $bitPos
  ;; as an array of i32's
  (func $getBits (param $lines i32)(param $bitPos i32)
	(local $numLines i32)
	(local $bitCounts i32)
	(local $bitLength i32)
	(local $lineNum i32)
  )
  ;; Accepts an array of lines of 'bits'
  ;; returns an array of bitCounts, one count for each bit position
  (func $countBits (param $lines i32)(result i32)
    (local $line i32)(local $numLines i32)
	(local $lineNum i32)
	(local $bitLength i32)(local $bitPos i32)(local $bitCounts i32)
	(local.set $numLines (call $i32list.getCurLen (local.get $lines)))
	(local.set $lineNum (i32.const 0))
	(local.set $line (call $i32list.get@(local.get $lines) (i32.const 0)))
	(local.set $bitLength (call $str.getByteLen (local.get $line)))
	(local.set $bitCounts (call $i32list.mk))
	(local.set $bitPos (i32.const 0))
	(loop $bitloop0  ;; create list to hold the bit counts
	  (call $i32list.push (local.get $bitCounts) (i32.const 0))
	  (local.set $bitPos (i32.add (local.get $bitPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $bitPos)(local.get $bitLength))
		(br $bitloop0))
	)
	(local.set $lineNum (i32.const 0))
	(loop $lineLoop
	  (local.set $line (call $i32list.get@(local.get $lines)(local.get $lineNum)))
	  (local.set $bitPos (i32.const 0))
	  (loop $bitloop1
		(if (i32.eq
		  (call $str.getByte (local.get $line)(local.get $bitPos))
		  (global.get $one))
		  (call $i32list.set@
			(local.get $bitCounts)
			(local.get $bitPos)
			(i32.add 
			  (call $i32list.get@
				(local.get $bitCounts)
				(local.get $bitPos)
			  )
			  (i32.const 1)
			)
		  )
		)
		(local.set $bitPos (i32.add (local.get $bitPos)(i32.const 1)))
		(if (i32.lt_u (local.get $bitPos)(local.get $bitLength))
		  (br $bitloop1))
	  )
	  (local.set $lineNum (i32.add (local.get $lineNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $lineNum)(local.get $numLines))
	    (br $lineLoop))
	)
	(local.get $bitCounts)
  )
  ;; Accepts an array of lines of 'bits'  ('0' and '1') plus a bit position and target value
  ;; Returns only those lines that satisfy the criteria (matching $targ)
  (func $filterLinesByBit (param $lines i32)(param $bitPos i32)(param $targ i32)(result i32)
    (local $line i32)(local $lineNum i32)(local $numLines i32)(local $bit i32)
	(local $filteredLines i32)
	;; (call $printwsp (global.get $gLookingFor))(call $C.print (local.get $targ))(call $printlf)
	;; (call $printwsp (global.get $gbitPos))(call $printwlf (local.get $bitPos))
	(local.set $filteredLines (call $i32list.mk))
	(local.set $numLines (call $i32list.getCurLen (local.get $lines)))
	(local.set $lineNum (i32.const 0))
	(loop $lineLoop
	  (local.set $line (call $i32list.get@(local.get $lines)(local.get $lineNum)))
	  (local.set $bit (call $str.getByte(local.get $line)(local.get $bitPos)))
	  (if (i32.eq (local.get $bit)(local.get $targ))
		(call $i32list.push (local.get $filteredLines)(local.get $line)))
	  (local.set $lineNum (i32.add (local.get $lineNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $lineNum)(local.get $numLines))
	    (br $lineLoop))
	)
	(local.get $filteredLines)
  )
  (func $day3 (export "_day3")
	(local $lines i32)(local $numLines i32)(local $line i32)(local $targ i32)
	(local $bitLength i32)(local $bitPos i32)
	(local $halfNumLines i32)(local $filteredLines i32)
	(local $gamma i32)(local $epsilon i32)(local $O2genRating i32)(local $CO2scrubRating i32)
	(local $1count i32) (local $0count i32)
	(local $bitCounts i32)
	(local.set $gamma (i32.const 0))
	(local.set $epsilon (i32.const 0))
	(local.set $lines (call $readFileSlow))
	(local.set $numLines (call $i32list.getCurLen (local.get $lines)))
	(local.set $halfNumLines (i32.shr_u (local.get $numLines)(i32.const 1)))
	(call $printwsp (local.get $numLines)) (call $printwlf (local.get $halfNumLines))
	(local.set $bitCounts (call $countBits (local.get $lines)))
	(call $printwlf (local.get $bitCounts))
	(local.set $bitLength (call $i32list.getCurLen (local.get $bitCounts)))
	(local.set $gamma (i32.const 0))
	(local.set $epsilon (i32.const 0))
	(local.set $O2genRating (i32.const 0))
	(local.set $CO2scrubRating (i32.const 0))
	(local.set $bitPos (i32.const 0))
	(loop $bitloop2
	  (local.set $gamma (i32.shl (local.get $gamma)(i32.const 1)))
	  (local.set $epsilon (i32.shl (local.get $epsilon)(i32.const 1)))
	  (local.set $O2genRating (i32.shl (local.get $O2genRating)(i32.const 1)))
	  (local.set $CO2scrubRating (i32.shl (local.get $CO2scrubRating)(i32.const 1)))
	  (if
		(i32.ge_u
		  (call $i32list.get@ (local.get $bitCounts)(local.get $bitPos))
		  (local.get $halfNumLines))
		(then
		  (local.set $gamma (i32.or (local.get $gamma)(i32.const 1))))
		(else
		  (local.set $epsilon
			(i32.or (local.get $epsilon)(i32.const 1))))	  )
	  (local.set $bitPos (i32.add (local.get $bitPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $bitPos)(local.get $bitLength))
		(br $bitloop2))
	)
	(local.set $filteredLines (local.get $lines))
	(local.set $bitPos (i32.const 0))
	(loop $filterLoop1
	  (local.set $numLines (call $i32list.getCurLen(local.get $filteredLines)))
	  (local.set $halfNumLines (i32.shr_u (i32.add (local.get $numLines)(i32.const 1))(i32.const 1)))
	  (local.set $bitCounts (call $countBits (local.get $filteredLines)))
	  (if
		(i32.ge_u
			(call $i32list.get@ (local.get $bitCounts)(local.get $bitPos))
			(local.get $halfNumLines))
		(then
		  (local.set $targ (global.get $one))
		)
		(else 
		  (local.set $targ (global.get $zero))
		)
	  )
	  (local.set $filteredLines
		(call $filterLinesByBit (local.get $filteredLines)(local.get $bitPos)(local.get $targ)))
	  (local.set $bitPos (i32.add (local.get $bitPos)(i32.const 1)))
	  (if (i32.gt_u (call $i32list.getCurLen (local.get $filteredLines))(i32.const 1))
		(br $filterLoop1))
	)
	(call $printwsp (global.get $gH))(call $printwlf (local.get $filteredLines))
	(local.set $O2genRating (call $str.binToI32 (call $i32list.pop (local.get $filteredLines))))
	
	(call $printwlf (local.get $O2genRating))(call $printlf)
	(local.set $filteredLines (local.get $lines))
	(local.set $bitPos (i32.const 0))
	(loop $filterLoop0
	  (local.set $numLines (call $i32list.getCurLen(local.get $filteredLines)))
	  (local.set $halfNumLines (i32.shr_u (i32.add (local.get $numLines)(i32.const 1))(i32.const 1)))
	  (local.set $bitCounts (call $countBits (local.get $filteredLines)))
	  ;;(call $printwlf (local.get $bitCounts))
	  (if
		(i32.lt_u
			(call $i32list.get@ (local.get $bitCounts)(local.get $bitPos))
			(local.get $halfNumLines))
		(then
		  (local.set $targ (global.get $one))
		)
		(else 
		  (local.set $targ (global.get $zero))
		)
	  )
	  ;;(call $C.print (local.get $targ))(call $printlf)
	  (local.set $filteredLines
		(call $filterLinesByBit (local.get $filteredLines)(local.get $bitPos)(local.get $targ)))
	  ;;(call $printwlf (local.get $filteredLines))
	  (local.set $bitPos (i32.add (local.get $bitPos)(i32.const 1)))
	  (if (i32.gt_u (call $i32list.getCurLen (local.get $filteredLines))(i32.const 1))
		(br $filterLoop0))
	)
	(call $printwsp (global.get $gH))(call $printwlf (local.get $filteredLines))
	(local.set $CO2scrubRating (call $str.binToI32 (call $i32list.pop (local.get $filteredLines))))
	(call $printwlf (local.get $CO2scrubRating))
	(call $printwlf (i32.mul (local.get $O2genRating)(local.get $CO2scrubRating)))
  )
  ;; expects an i32list of pointers to numeric strings to convert to i32's
  (func $strList2intList (param $strList i32)(result i32)
	(local $listPos i32)
	(local $listLen i32)
	(local $numList i32)
	(local $textNum i32)
	(local.set $numList (call $i32list.mk))
	(local.set $listPos (i32.const 0))
	(local.set $listLen (call $i32list.getCurLen (local.get $strList)))
	(loop $numLoop
	  (local.set $textNum (call $i32list.get@ (local.get $strList)(local.get $listPos)))
	  (call $i32list.push (local.get $numList)(call $str.toI32 (local.get $textNum)))
	  (local.set $listPos (i32.add (local.get $listPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $listPos)(local.get $listLen))(br $numLoop))
	)
	(local.get $numList)
  )
  (func $board.mk (param $lines i32)(param $boardSize i32)(param $linePos i32)(result i32)
    (local $board i32)(local $lineOff i32)(local $intList i32)(local $strList i32)
	(local.set $lineOff (i32.const 0))
	(local.set $board (call $i32list.mk))
	(loop $lineLoop
	  (local.set $strList
		(call $str.Csplit 
		  (call $i32list.get@
		    (local.get $lines)(i32.add (local.get $linePos)(local.get $lineOff)))
			(global.get $SP)))
	  (local.set $intList (call $strList2intList (local.get $strList)))
	  (call $i32list.push (local.get $board)(local.get $intList))
	  (local.set $lineOff (i32.add (local.get $lineOff)(i32.const 1)))
	  (if (i32.lt_u (local.get $lineOff)(local.get $boardSize))
		(br $lineLoop))
	)
	(local.get $board)
  )
  ;; return 1 if all members of list are < 0
  (func $allMaxNegative (param $list i32)(result i32)
	(local $pos i32)(local $listLen i32)
	(local.set $pos (i32.const 0))
	(local.set $listLen (call $i32list.getCurLen (local.get $list)))
	(loop $mloop
	  (if (i32.ne (call $i32list.get@ (local.get $list)(local.get $pos))(global.get $maxNeg))
	    (return (i32.const 0))  ;; Failed, something's not max negative
	  )
	  (local.set $pos (i32.add (local.get $pos)(i32.const 1)))
	  (if (i32.lt_u (local.get $pos)(local.get $listLen))
		(br $mloop))
	)
	(i32.const 1) ;; Bingo!
  )
  ;; returns 1 if column is fully marked
  (func $checkCol (param $board i32)(param $colNum i32)(result i32)
	(local $rowNum i32)(local $row i32)(local $boardSize i32)
	(local.set $boardSize (call $i32list.getCurLen (local.get $board)))  ;; #rows == board size
	(local.set $rowNum (i32.const 0))
	(loop $rLoop
	  (local.set $row (call $i32list.get@ (local.get $board)(local.get $rowNum)))
	  (if (i32.ne (call $i32list.get@ (local.get $row)(local.get $colNum))(global.get $maxNeg))
		(return (i32.const 0))) ;; Nope!
	  (local.set $rowNum (i32.add (local.get $rowNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $rowNum)(local.get $boardSize))
		(br $rLoop))
	)
	(i32.const 1)  ;; Bingo!
  )
  ;; returns 1 if row or column is fill after marking this row/col
  (func $markNcheckBoard (param $board i32)(param $randNum i32)(result i32)
    (local $rowNum i32)(local $colNum i32)(local $boardSize i32)
	(local $row i32)(local $rowcolVal i32)
	(local.set $boardSize (call $i32list.getCurLen (local.get $board)))  ;; #rows == board size
	(local.set $rowNum (i32.const 0))
	(loop $rLoop
	  (local.set $row (call $i32list.get@ (local.get $board)(local.get $rowNum)))
	  (local.set $colNum (i32.const 0)) 
	  (loop $cLoop
		(local.set $rowcolVal (call $i32list.get@ (local.get $row)(local.get $colNum)))
		(if (i32.eq (local.get $randNum)(local.get $rowcolVal)) ;; found it!
		  (then
			(call $i32list.set@ (local.get $row)(local.get $colNum)(global.get $maxNeg))
			(if (call $allMaxNegative (local.get $row))
			  (return (i32.const 1)))  ;; Bingo!
			(if (call $checkCol (local.get $board)(local.get $colNum))
			  (return (i32.const 1)))  ;; Bingo!
		  )
		)
		(local.set $colNum (i32.add (local.get $colNum)(i32.const 1)))
		(if (i32.lt_u (local.get $colNum)(local.get $boardSize))
		  (br $cLoop))
	  )
	  (local.set $rowNum (i32.add (local.get $rowNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $rowNum)(local.get $boardSize))
		(br $rLoop))
	)
	(i32.const 0)
  )
  (func $bingoScore (param $board i32) (result i32)
	(local $row i32);;(local $col i32)
	(local $rowNum i32)(local $colNum i32)(local $colVal i32)
	(local $score i32)(local $boardSize i32)
	(local.set $score (i32.const 0))
	(local.set $boardSize (call $i32list.getCurLen (local.get $board)))
	(local.set $score (i32.const 0))
	(local.set $rowNum (i32.const 0))
	(loop $rowLoop
	  (local.set $row (call $i32list.get@(local.get $board)(local.get $rowNum)))
	  ;;(call $printwlf (local.get $row))
	  (local.set $colNum (i32.const 0))
	  (loop $colLoop
		(local.set $colVal (call $i32list.get@ (local.get $row)(local.get $colNum)))
		(if (i32.ne (local.get $colVal)(global.get $maxNeg))
		  (local.set $score (i32.add (local.get $score)(local.get $colVal))))
		(local.set $colNum (i32.add (local.get $colNum)(i32.const 1)))
		(if (i32.lt_u (local.get $colNum)(local.get $boardSize))
		  (br $colLoop))
	  )
	  (local.set $rowNum (i32.add (local.get $rowNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $rowNum)(local.get $boardSize))
	    (br $rowLoop))
	)
	(local.get $score)
  )
  ;; Return true if $targ is in $list
  (func $inList(param $list i32)(param $targ i32)(result i32)
    (local $pos i32)(local $listLen i32)
	(local.set $pos (i32.const 0))
	(local.set $listLen (call $i32list.getCurLen (local.get $list)))
	(loop $posLoop
	  (if (i32.eq (local.get $targ)(call $i32list.get@(local.get $list)(local.get $pos)))
		(return (i32.const 1)))
	  (local.set $pos (i32.add (local.get $pos)(i32.const 1)))
	  (if (i32.lt_u (local.get $pos)(local.get $listLen))
		(br $posLoop))
	)
	(i32.const 0) ;; Not found
  )
  (func $day4 (export "_day4")
	(local $boards i32)(local $boardSize i32)(local $linePos i32)
	(local $firstLine i32)(local $numLines i32)(local $boardNum i32)
	(local $ranNums i32)(local $lines i32)(local $bingo i32)(local $ranNum i32)
	(local $board i32)(local $ranPos i32)(local $numBoards i32)
	(local $bingos i32)(local $scores i32)(local $winNums i32) ;; to keep track for Day 4 part 2
	(local $boardScore i32)
	(local $temp i32)
	(local.set $boardSize (i32.const 5))
	(local.set $lines (call $readFileSlow))
	(local.set $firstLine (call $i32list.get@ (local.get $lines)(i32.const 0)))
	(local.set $numLines (call $i32list.getCurLen (local.get $lines)))
	(local.set $boards (call $i32list.mk))
	(local.set $bingos (call $i32list.mk))
	(local.set $winNums (call $i32list.mk))
	(local.set $scores (call $i32list.mk))
	(local.set $ranNums (call $str.Csplit (local.get $firstLine)(global.get $COMMA)))
	(local.set $ranNums (call $strList2intList (local.get $ranNums)))
	(local.set $linePos (i32.const 2))  ;; first boards starts at the third line (offset==2)
	(loop $boardLoop0
	  (local.set $board (call $board.mk (local.get $lines)(local.get $boardSize)(local.get $linePos)))
	  (call $i32list.push (local.get $boards)(local.get $board))
	  (local.set $linePos (i32.add (local.get $linePos)(i32.add (local.get $boardSize)(i32.const 1))))
	  (if (i32.lt_u (local.get $linePos)(local.get $numLines))
	    (br $boardLoop0))
	)	
	(local.set $numBoards (call $i32list.getCurLen (local.get $boards)))
	(local.set $ranPos (i32.const 0))
	(loop $ranLoop
	  (local.set $ranNum (call $i32list.get@ (local.get $ranNums)(local.get $ranPos)))
	  (local.set $boardNum (i32.const 0))
	  (loop $boardLoop1
		(local.set $board (call $i32list.get@ (local.get $boards)(local.get $boardNum)))
	    (local.set $bingo
		  (call $markNcheckBoard
			(call $i32list.get@
			  (local.get $boards)
			  (local.get $boardNum))
			  (local.get $ranNum)))
		(if (local.get $bingo)
		  (then
			;;(call $printwsp (global.get $gBingo!))
			;;(call $printwlf (local.get $boardNum))
			(if (i32.eqz (call $inList (local.get $bingos)(local.get $boardNum)))
			  (then
				(call $i32list.push (local.get $bingos)(local.get $boardNum))
				(local.set $boardScore (call $bingoScore (local.get $board)))
				(call $i32list.push (local.get $scores)(local.get $boardScore))
				(call $i32list.push (local.get $winNums)(local.get $ranNum))
				;;(call $printwlf (local.get $boardScore))
				;;(call $printwlf (local.get $ranNum))
				;;(call $i32.print (i32.mul (local.get $ranNum)(local.get $boardScore)))
				;;(call $printlf)
			  )
			)
		  )
		)
		(local.set $boardNum (i32.add (local.get $boardNum)(i32.const 1)))
		(if (i32.lt_u (local.get $boardNum)(local.get $numBoards))
		  (br $boardLoop1))
	  )
	  (local.set $ranPos (i32.add (local.get $ranPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $ranPos)(call $i32list.getCurLen (local.get $ranNums)))
	      (br $ranLoop))
	)
	(call $printwlf (local.get $bingos))
	(call $printwlf (local.get $winNums))
	(call $printwlf (local.get $scores))
	(call $i32.print (i32.mul (call $i32list.pop (local.get $winNums))(call $i32list.pop (local.get $scores))))
	(call $printlf)
  )
  (func $point.txtmk (param $txtRep i32)(result i32)
	(local $pt i32)
	(local $xyReps i32)
	(local $x i32) (local $y i32)
	(local.set $xyReps (call $str.Csplit (local.get $txtRep)(global.get $COMMA)))
	(local.set $x (call $str.toI32(call $i32list.get@(local.get $xyReps)(i32.const 0))))
	(local.set $y (call $str.toI32(call $i32list.get@(local.get $xyReps)(i32.const 1))))
	(local.set $pt (call $point.mk (local.get $x)(local.get $y)))
	(local.get $pt)
  )
  (func $point.mk (param $x i32)(param $y i32)(result i32)
    (local $pt i32)
	(local.set $pt (call $i32list.mk))
	(call $i32list.push (local.get $pt)(local.get $x))
	(call $i32list.push (local.get $pt)(local.get $y))
	(local.get $pt)
  )
  (func $point.getX (param $point i32)(result i32)
	(call $i32list.get@ (local.get $point)(i32.const 0))
  )
  (func $point.getY (param $point i32)(result i32)
    ;;(call $printwlf (local.get $point))
	(call $i32list.get@ (local.get $point)(i32.const 1))
  )
  ;; expects a line like '0,9 -> 5,9'
  ;; stores this as [[0, 9], [5, 9]]
  (func $lineSeg.mk (param $txtRep i32)(result i32)
	(local $seg i32)(local $arrowPos i32)(local $arrowStr i32)
	(local $pt1 i32)(local $pt2 i32)(local $pt1Txt i32)(local $pt2Txt i32)
	(local.set $arrowStr (call $str.mkdata (global.get $gArrow)))
	(local.set $arrowPos (call $str.find (local.get $txtRep)(local.get $arrowStr)))
	(local.set $pt1Txt (call $str.mkslice (local.get $txtRep)(i32.const 0)(local.get $arrowPos)))
	(local.set $pt1 (call $point.txtmk (local.get $pt1Txt)))
	(local.set $pt2Txt 
	  (call $str.mkslice
	    (local.get $txtRep)
		(i32.add (local.get $arrowPos)(i32.const 2))
		(i32.sub (call $str.getByteLen (local.get $txtRep))(i32.add (local.get $arrowPos)(i32.const 2)))))
	(local.set $pt2 (call $point.txtmk (local.get $pt2Txt)))
	(local.set $seg (call $i32list.mk))
	(call $i32list.push (local.get $seg)(local.get $pt1))
	(call $i32list.push (local.get $seg)(local.get $pt2))
	(local.get $seg)
  )
  (func $mkRow (param $numCols i32)(result i32)
    (local $colNum i32)(local $row i32)
	(local.set $row (call $i32list.mk))
	(local.set $colNum (i32.const 0))
	(loop $cLoop
		(if (i32.lt_s (local.get $colNum)(local.get $numCols))
		  (then
			(call $i32list.push (local.get $row)(i32.const 0))
			(local.set $colNum (i32.add (local.get $colNum)(i32.const 1)))
			(br $cLoop))))
	(local.get $row)
  )
  (func $chart.mk (param $numRows i32)(param $numCols i32)(result i32)
    (local $chart i32)
	(local $row i32)
	(local $rows i32)(local $rowNum i32)(local $tempRow i32)
	(local.set $rowNum (i32.const 0))
	(local.set $chart (call $i32list.mk))
	(loop $rloop
	  (local.set $row (call $mkRow (local.get $numCols)))
	  (call $i32list.push (local.get $chart)(local.get $row))
	  (local.set $rowNum (i32.add (local.get $rowNum)(i32.const 1)))
	  (if (i32.lt_u (local.get $rowNum)(local.get $numRows))
	    (br $rloop)))	
	(local.get $chart)
  )
  (func $row.score (param $row i32)(result i32)
    (local $score i32)(local $colVal i32)
	(local $colNum i32)(local $numCols i32)
	(local.set $numCols (call $i32list.getCurLen (local.get $row)))
	(local.set $score (i32.const 0))
	(local.set $colNum (i32.const 0))
	(loop $colLoop
	  (if (i32.ge_u (local.get $colNum)(local.get $numCols))(return (local.get $score)))
	  (local.set $colVal (call $i32list.get@(local.get $row)(local.get $colNum)))
	  (if (i32.ge_u (local.get $colVal) (i32.const 2))
		(local.set $score (i32.add (local.get $score)(i32.const 1))))
	  (local.set $colNum (i32.add (local.get $colNum)(i32.const 1)))
	  (br $colLoop)
	)
	;; $score is actually returned in the $colLoop. Needed for compiler
	(local.get $score)  
  )
  (func $chart.score (param $chart i32)(result i32)
	(local $row i32)(local $numRows i32)(local $rowNum i32)
	(local $score i32)
	(local.set $numRows (call $i32list.getCurLen (local.get $chart)))
	(local.set $score (i32.const 0))
	(local.set $rowNum (i32.const 0))
	(loop $rowLoop
	  (if (i32.ge_u (local.get $rowNum)(local.get $numRows))(return (local.get $score)))
	  (local.set $row (call $i32list.get@ (local.get $chart)(local.get $rowNum)))
	  (local.set $score (i32.add (local.get $score) (call $row.score (local.get $row))))
	  (local.set $rowNum (i32.add (local.get $rowNum)(i32.const 1)))
	  (br $rowLoop)
	)
	(local.get $score)
  )
  (func $chart.getRow (param $chart i32)(param $rowNum i32)(result i32)
    (call $i32list.get@ (local.get $chart)(local.get $rowNum))
  )
  (func $chart.print (param $chart i32)
	(local $rowNum i32)	(local $numRows i32)(local $row i32)
	(local.set $numRows (call $i32list.getCurLen (local.get $chart)))
	(local.set $rowNum (i32.const 0))
	(loop $rLoop
	  (if (i32.lt_u (local.get $rowNum)(local.get $numRows))
		(then
		  (local.set $row (call $i32list.get@ (local.get $chart)(local.get $rowNum)))
		  (call $printwlf (local.get $row))
		  (local.set $rowNum (i32.add (local.get $rowNum)(i32.const 1)))
		  (if (i32.lt_u (local.get $rowNum)(local.get $numRows))
			(br $rLoop)))))
  )
  (func $chart.addPoint (param $chart i32)(param $x i32)(param $y i32)
    (local $row i32)(local $oldVal i32)
	;;(call $printwsp (global.get $gS))
	(local.set $row (call $chart.getRow (local.get $chart)(local.get $y)))
	(local.set $oldVal (call $i32list.get@ (local.get $row)(local.get $x)))
	(call $i32list.set@ (local.get $row)(local.get $x)(i32.add (local.get $oldVal)(i32.const 1)))
  )
  (func $findInc (param $v1 i32)(param $v2 i32)(result i32)
	(if (i32.eq (local.get $v1)(local.get $v2))
	  (return (i32.const 0)))
	(if (i32.gt_s (local.get $v1)(local.get $v2))
	  (return (i32.const -1)))
	(i32.const 1)
  )
  (func $chart.addSeg (param $chart i32)(param $lineSeg i32)
	(local $pt1 i32)(local $pt2 i32)(local $x i32)(local $y i32)
	(local $y1 i32)(local $y2 i32)(local $x1 i32)(local $x2 i32)
	(local $temp i32)(local $xinc i32)(local $yinc i32)
	;;(call $printwlf (local.get $lineSeg))
	(local.set $pt1 (call $i32list.get@ (local.get $lineSeg)(i32.const 0)))
	(local.set $pt2 (call $i32list.get@ (local.get $lineSeg)(i32.const 1)))
	(local.set $x1 (call $point.getX (local.get $pt1)))
	(local.set $x2 (call $point.getX (local.get $pt2)))
	(local.set $y1 (call $point.getY (local.get $pt1)))
	(local.set $y2 (call $point.getY (local.get $pt2)))
	(local.set $xinc (call $findInc (local.get $x1)(local.get $x2)))
	(local.set $yinc (call $findInc (local.get $y1)(local.get $y2)))
	(local.set $x (local.get $x1))
	(local.set $y (local.get $y1))
	(loop $incLoop
	  (call $chart.addPoint (local.get $chart)(local.get $x)(local.get $y))
	  (if (i32.and 
		(i32.eq (local.get $x)(local.get $x2))
		(i32.eq (local.get $y)(local.get $y2)))
		(return))
	  (local.set $x (i32.add (local.get $x)(local.get $xinc)))
	  (local.set $y (i32.add (local.get $y)(local.get $yinc)))
	  (br $incLoop)
	)
  )
  (func $day5 (export "_day5")
    (local $lines i32)(local $chart i32)(local $lineSegs i32)
	(local $line i32)(local $lineNum i32)(local $lineSeg i32)(local $chartScore i32)
	(local $chartNumRows i32)(local $chartNumCols i32)
	(local $numLines i32)(local $chartSize i32)
	(local.set $chartSize (i32.const 1000)) ;; square
	(local.set $chartNumRows (local.get $chartSize))
	(local.set $chartNumCols (local.get $chartSize))  
	(local.set $chart (call $chart.mk (local.get $chartNumRows)(local.get $chartNumCols)))
	(local.set $lines (call $readFileSlow))
	(local.set $numLines (call $i32list.getCurLen (local.get $lines)))
	(local.set $lineSegs (call $i32list.mk))
	(local.set $lineNum (i32.const 0))
	(call $printwlf (local.get $numLines))
	(loop $lineLoop
	  (local.set $line (call $i32list.get@(local.get $lines)(local.get $lineNum)))
	  (local.set $lineSeg (call $lineSeg.mk(call $i32list.get@(local.get $lines)(local.get $lineNum))))
	  (call $chart.addSeg (local.get $chart)(local.get $lineSeg))
	  (local.set $lineNum (i32.add (local.get $lineNum)(i32.const 1)))
	  (if (i32.lt_u(local.get $lineNum)(local.get $numLines))
		(br $lineLoop))
	)
	(if (i32.eq (local.get $chartSize)(i32.const 10))
		(call $chart.print (local.get $chart)))
	(local.set $chartScore (call $chart.score (local.get $chart)))
	(call $printwsp (global.get $gS))(call $i32.print (local.get $chartScore))(call $printlf)
	(call $showMemUsed)
  )
  (func $splitLineToInt32s (param $line i32)(result i32)
    (local $cList i32)(local $numInts i32)(local $pos i32)(local $intList i32)
	(local $int i32)
	(local.set $cList (call $str.Csplit (local.get $line)(global.get $COMMA)))
	;;(call $printwlf (local.get $cList))
	(local.set $numInts (call $i32list.getCurLen (local.get $cList)))
	(local.set $pos (i32.const 0))
	(local.set $intList (call $i32list.mk))
	(loop $intLoop
	  (local.set $int (call $str.toI32 (call $i32list.get@ (local.get $cList)(local.get $pos))))
	  (call $i32list.push (local.get $intList)(local.get $int))
	  (local.set $pos (i32.add (local.get $pos)(i32.const 1)))
	  (if (i32.lt_u (local.get $pos)(local.get $numInts))
	    (br $intLoop)))
	(local.get $intList)
  )
  ;; returns a new list with the next generation
  (func $doAGeneration (param $lastGen i32)(result i32)
    (local $nextGen i32)(local $fishPos i32)(local $fish i32)
	(local.set $nextGen (call $i32list.mk))
	(loop $fishLoop
	  (local.set $fish (call $i32list.pop (local.get $lastGen)))
	  (if (i32.eqz (local.get $fish))
		(then  ;; new fish
		  (call $i32list.push (local.get $nextGen)(i32.const 6)) ;; reset to 6
		  (call $i32list.push (local.get $nextGen)(i32.const 8)) ;; new fish at 8
		)
		(else  ;; just decrement
		  (call $i32list.push(local.get $nextGen)(i32.sub (local.get $fish)(i32.const 1)))
		))
	  (if (call $i32list.getCurLen(local.get $lastGen))
	    (br $fishLoop))
	)
	(local.get $nextGen)
  )
  (func $doGenerationsOld (param $school i32)(param $numDays i32)(result i32)
	(local $day i32)
	(local.set $day (i32.const 0))
	(loop $dayLoop
	  ;;(call $printwlf (local.get $school))
	  (local.set $school (call $doAGeneration (local.get $school)))
	  (call $i32.print (local.get $day))(call $printsp)
	  (call $i32.print (call $i32list.getCurLen (local.get $school)))(call $printlf)
	  (local.set $day (i32.add (local.get $day)(i32.const 1)))
	  (if (i32.lt_u (local.get $day)(local.get $numDays))
		(br $dayLoop)))
	(call $i32list.getCurLen (local.get $school))
  )
  (func $day6old (export "_day6old")
    (local $initialState i32)(local $file i32)(local $numFish i32)
	(local.set $file (call $readFileSlow))
	(local.set $initialState (call $splitLineToInt32s (call $i32list.get@ (local.get $file)(i32.const 0))))
	;;(local.set $initialState (call $i32list.mk))
	;;(call $i32list.push (local.get $initialState)(i32.const 1))
	(local.set $numFish (call $doGenerationsOld (local.get $initialState)(i32.const 80)))
	(call $i32.print (local.get $numFish))(call $printlf)
	(call $showMemUsed)
  )
  (func $mkSchool32 (param $fishList i32)(result i32)
    (local $school i32)(local $timer i32)(local $fish i32)(local $oldCount i32)
	(local.set $school (call $i32list.mk))
	(local.set $timer (i32.const 8))
	(loop $timerLoop
	  (call $i32list.push(local.get $school)(i32.const 0))
	  (local.set $timer (i32.sub (local.get $timer)(i32.const 1)))
	  (if (i32.ge_s (local.get $timer)(i32.const 0))
	    (br $timerLoop)))
	(loop $fishLoop
	  (local.set $fish (call $i32list.pop (local.get $fishList)))
	  (local.set $oldCount (call $i32list.get@ (local.get $school)(local.get $fish)))
	  (call $i32list.set@ (local.get $school)(local.get $fish)(i32.add (local.get $oldCount)(i32.const 1)))
	  (if (call $i32list.getCurLen (local.get $fishList))
	    (br $fishLoop))
	)
	(local.get $school)
  )
  ;; shifts a school to the left in place.  location 0 get's clobbered, last location untouched
  (func $shiftLeft (param $school i32)
    (local $timer i32)(local $schoolSizeMin1 i32)
	(local.set $schoolSizeMin1 (i32.sub (call $i32list.getCurLen (local.get $school))(i32.const 1)))
	(local.set $timer (i32.const 0))
	(loop $timerLoop
	  (call $i32list.set@ (local.get $school)(local.get $timer)
		(call $i32list.get@ (local.get $school)(i32.add (local.get $timer)(i32.const 1))))
	  (local.set $timer (i32.add (local.get $timer)(i32.const 1)))
	  (if (i32.lt_u (local.get $timer)(local.get $schoolSizeMin1))
	    (br $timerLoop)))
  )
  (func $doGeneration32 (param $school i32)
    (local $timer i32)(local $zeroCount i32)(local $sixCount i32)
	(local.set $zeroCount (call $i32list.get@ (local.get $school)(i32.const 0)))
	(call $shiftLeft (local.get $school))
	(call $i32list.set@ (local.get $school)(i32.const 8)(local.get $zeroCount)) ;; new fish
	(local.set $sixCount (call $i32list.get@ (local.get $school)(i32.const 6)))
	(call $i32list.set@ (local.get $school)(i32.const 6)(i32.add (local.get $sixCount)(local.get $zeroCount)))
  )
  (func $doGenerations32 (param $school i32)(param $numDays i32)
	(loop $genLoop
	  (if (local.get $numDays)
	    (then
		  (call $doGeneration32 (local.get $school))
		  (call $printwsp (local.get $numDays))(call $printwlf (local.get $school))
		  (local.set $numDays (i32.sub (local.get $numDays)(i32.const 1)))
		  (br $genLoop))))
  )
  (func $mkSchool64 (param $fishList i32)(result i32)
    (local $school i32)(local $timer i32)(local $fish i32)(local $oldCount i64)
	(local.set $school (call $i64list.mk))
	(local.set $timer (i32.const 8))
	(loop $timerLoop
	  (call $i64list.push(local.get $school)(i64.const 0))
	  (local.set $timer (i32.sub (local.get $timer)(i32.const 1)))
	  (if (i32.ge_s (local.get $timer)(i32.const 0))
	    (br $timerLoop)))
	(loop $fishLoop
	  (local.set $fish (call $i32list.pop (local.get $fishList)))
	  (local.set $oldCount (call $i64list.get@ (local.get $school)(local.get $fish)))
	  (call $i64list.set@ (local.get $school)(local.get $fish)(i64.add (local.get $oldCount)(i64.const 1)))
	  (if (call $i32list.getCurLen (local.get $fishList))
	    (br $fishLoop))
	)
	(local.get $school)
  )
  ;; shifts a school to the left in place.  location 0 get's clobbered, last location untouched
  (func $shiftLeft64 (param $school i32)
    (local $timer i32)(local $schoolSizeMin1 i32)
	(local.set $schoolSizeMin1 (i32.sub (call $i64list.getCurLen (local.get $school))(i32.const 1)))
	(local.set $timer (i32.const 0))
	(loop $timerLoop
	  (call $i64list.set@ (local.get $school)(local.get $timer)
		(call $i64list.get@ (local.get $school)(i32.add (local.get $timer)(i32.const 1))))
	  (local.set $timer (i32.add (local.get $timer)(i32.const 1)))
	  (if (i32.lt_u (local.get $timer)(local.get $schoolSizeMin1))
	    (br $timerLoop)))
  )
  (func $doGeneration64 (param $school i32)
    (local $timer i32)(local $zeroCount i64)(local $sixCount i64)
	(local.set $zeroCount (call $i64list.get@ (local.get $school)(i32.const 0)))
	(call $shiftLeft64 (local.get $school))
	(call $i64list.set@ (local.get $school)(i32.const 8)(local.get $zeroCount)) ;; new fish
	(local.set $sixCount (call $i64list.get@ (local.get $school)(i32.const 6)))
	(call $i64list.set@ (local.get $school)(i32.const 6)(i64.add (local.get $sixCount)(local.get $zeroCount)))
  )
  (func $doGenerations64 (param $school i32)(param $numDays i32)
	(loop $genLoop
	  (if (local.get $numDays)
	    (then
		  (call $doGeneration64 (local.get $school))
		  ;;(call $printwsp (local.get $numDays))(call $printwlf (call $i64list.toStr (local.get $school)))
		  (local.set $numDays (i32.sub (local.get $numDays)(i32.const 1)))
		  (br $genLoop))))
  )
  (func $countFish64 (param $school i32)(result i64)
	(local $timer i32)(local $sum i64)(local $schoolSize i32)
	(local.set $timer (i32.const 0))
	(local.set $sum (i64.const 0))
	(local.set $schoolSize (call $i64list.getCurLen (local.get $school)))
	(loop $timerLoop
	  (local.set $sum (i64.add (local.get $sum)(call $i64list.get@ (local.get $school)(local.get $timer))))
	  (local.set $timer (i32.add (local.get $timer)(i32.const 1)))
	  (if (i32.lt_u (local.get $timer)(local.get $schoolSize))
		(br $timerLoop)))
	(local.get $sum)
  )
  (func $countFish32 (param $school i32)(result i32)
	(local $timer i32)(local $sum i32)(local $schoolSize i32)
	(local.set $timer (i32.const 0))
	(local.set $sum (i32.const 0))
	(local.set $schoolSize (call $i32list.getCurLen (local.get $school)))
	(loop $timerLoop
	  (local.set $sum (i32.add (local.get $sum)(call $i32list.get@ (local.get $school)(local.get $timer))))
	  (local.set $timer (i32.add (local.get $timer)(i32.const 1)))
	  (if (i32.lt_u (local.get $timer)(local.get $schoolSize))
		(br $timerLoop)))
	(local.get $sum)
  )
  (func $day632 (export "_day632")
    (local $initialList i32)(local $school32 i32)
	(local $file i32)(local $numFish i32)
	(local.set $file (call $readFileSlow))
	(local.set $initialList (call $splitLineToInt32s (call $i32list.get@ (local.get $file)(i32.const 0))))
	(call $printwlf (local.get $initialList))
	(local.set $school32 (call $mkSchool32 (local.get $initialList)))
	(call $doGenerations32 (local.get $school32)(i32.const 80))
	(call $printwlf (call $i32list.toStr (local.get $school32)))
	(call $printwlf (call $countFish32 (local.get $school32)))
	(call $printlf)
	(call $showMemUsed)
  )
  (func $day664 (export "_day664")
    (local $initialList i32)(local $school64 i32)
	(local $file i32)(local $numFish i64)
	(local.set $file (call $readFileSlow))
	(local.set $initialList (call $splitLineToInt32s (call $i32list.get@ (local.get $file)(i32.const 0))))
	;;(call $printwlf (local.get $initialList))
	(local.set $school64 (call $mkSchool64 (local.get $initialList)))
	;;(call $printwlf (call $i64list.toStr (local.get $school64)))
	;;(call $i64.print (call $countFish64 (local.get $school64))) (call $printlf)
	(call $doGenerations64 (local.get $school64) (i32.const 256))
	(call $printwlf (call $i64list.toStr (local.get $school64)))
	(call $i64.print (call $countFish64 (local.get $school64)))
	(call $printlf)
	(call $showMemUsed)
  )
  (func $day7p2Cost (param $diff i32)(result i32)
    (i32.shr_u 
	  (i32.mul
	    (local.get $diff)
		(i32.sub
		  (local.get $diff)
		  (i32.const 1)
		)
	  )
	  (i32.const 1)
	)
  )
  (func $day7p1Cost (param $diff i32)(result i32)
    (local.get $diff)
  )
  (func $day7FuelCost (param $listPtr i32)(param $guess i32)(result i32)
    (local $totalCost i32)(local $thisCost i32)
	(local $listPos i32)(local $listLen i32)(local $hVal i32)
	(local.set $listPos (i32.const 0))
	(local.set $totalCost (i32.const 0))
	(local.set $listLen (call $i32list.getCurLen (local.get $listPtr)))
	(loop $costLoop  ;; assumes list isn't empty
	  (local.set $hVal (call $i32list.get@ (local.get $listPtr)(local.get $listPos)))
	  ;;(call $i32.print (local.get $hVal))(call $printlf)
	  (call $printwsp (global.get $gE))(call $i32.print (i32.sub (local.get $guess)(local.get $hVal)))(call $printlf)
	  (call $printwsp (global.get $gF))(call $i32.print (i32.sub (local.get $hVal)(local.get $guess)))(call $printlf)
	  (if (i32.lt_s (local.get $hVal)(local.get $guess))
	    (then
		  (local.set $thisCost (call $day7p2Cost (i32.sub (local.get $guess)(local.get $hVal)))))
		(else
		  (local.set $thisCost (call $day7p2Cost (i32.sub (local.get $hVal)(local.get $guess))))))
	  (call $i32.print (local.get $listPos))(call $printsp)
	  (call $i32.print (local.get $hVal)(call $printsp)
	  (call $i32.print (local.get $thisCost)))(call $printlf)
	  (local.set $totalCost (i32.add (local.get $totalCost)(local.get $thisCost)))
	  (local.set $listPos (i32.add (local.get $listPos) (i32.const 1)))
	  (if (i32.lt_s (local.get $listPos) (local.get $listLen))
		(br $costLoop)
	  )
	)
	(local.get $totalCost)
  )
  (func $day7 (export "_day7")
    (local $horizontals i32)(local $listLen i32)
	(local $file i32)
	(local $guessPos i32)
	(local $thisGuess i32)(local $thisGuessCost i32)
	(local $lastGuess i32)(local $lastGuessCost i32)
	(local.set $file (call $readFileSlow))
	(local.set $horizontals (call $splitLineToInt32s (call $i32list.get@ (local.get $file)(i32.const 0))))
	(call $i32.print (call $i32list.getCurLen (local.get $horizontals)))(call $printlf)
	(local.set $listLen (call $i32list.getCurLen (local.get $horizontals)))
	(call $i32list.qsort (local.get $horizontals)(i32.const 0)(i32.sub (local.get $listLen)(i32.const 1)))
	(call $printwlf (local.get $horizontals))
	(local.set $guessPos (i32.shr_u (call $i32list.getCurLen (local.get $horizontals))(i32.const 1)))
	(call $printwlf (local.get $guessPos))

	(local.set $thisGuess (call $i32list.get@ (local.get $horizontals)(i32.sub (local.get $guessPos)(i32.const 1))))
	(call $printwsp (global.get $gG)) (call $i32.print (local.get $thisGuess))(call $printlf)
	(call $printwsp (global.get $gC))
	(local.set $lastGuessCost (call $day7FuelCost (local.get $horizontals)(local.get $thisGuess)))
	(call $i32.print (local.get $lastGuessCost))(call $printlf)
	(loop $guessLoop
	  (local.set $guessPos (i32.add (local.get $guessPos)(i32.const 1)))
	  (call $printwsp (local.get $guessPos))
	  (local.set $thisGuess (call $i32list.get@ (local.get $horizontals)(local.get $guessPos)))
	  (local.set $thisGuessCost (call $day7FuelCost (local.get $horizontals)(local.get $thisGuess)))
	  (call $i32.print (local.get $thisGuessCost))(call $printlf)
	  (if (i32.le_s (local.get $thisGuessCost)(local.get $lastGuessCost))
	   (then
	     (local.set $lastGuessCost (local.get $thisGuessCost)
	    (br $guessLoop))))
	)
	(call $i32.print (local.get $lastGuessCost))(call $printlf)
  )
  (func $main (export "_start")
	;; Generate .wasm with: wat2wasm --enable-bulk-memory strings/string1.wat
	;; (local $buffer i32)
	;; (local $tree i32)
    ;; ;;(call $test)
	;; (local.set $buffer (call $readFile))
	;; (call $print (call $str.mkdata(global.get $gBytesRead)))
	;; (call $print(call $str.getByteLen (local.get $buffer))) (call $printlf)
	;; (local.set $tree (call $wam2wat (local.get $buffer)))
	;; (global.set $debugW2W (i32.const 1))
	;; ;;(call $printwlf (local.get $tree))
	;; (call $showTree (call $i32list.pop (local.get $tree))(i32.const 0))
	;; (call $byte.print(global.get $LF))
	(call $showMemUsed)
  )
  (func $misc.test (param $testNum i32)(result i32)
	;; (local $stack i32)
	;; (local $stack2 i32)
	;; (local.set $stack (call $i32list.mk))
	;; (call $printwlf (local.get $stack))
	;; (call $i32list.push (local.get $stack)(i32.const 42))
	;; (call $i32list.push (local.get $stack)(i32.const 43))
	;; (local.set $stack2 (call $i32list.mk))
	;; (call $i32list.push (local.get $stack2)(i32.const 44))
	;; (call $printwlf (local.get $stack))
	;; (call $i32list.push (local.get $stack)(local.get $stack2))
	;; (call $printwlf (local.get $stack))
	;; (call $printwlf (call $i32list.tail (local.get $stack)))
	;; (call $i32list.set@ (local.get $stack2)(i32.const 0)(i32.const 55))
	;; (call $printwlf (local.get $stack))
	(i32.const 0)
  )
  ;;(global $debugW2W	i32 (i32.const 0))
  (global $i32L	  	i32	(i32.const 0x6933324C)) ;; 'i32L' type# for i32 lists
												;; needs to match $gi32L
  (global $i64L		i32 (i32.const 0x6936344C)) ;; 'i64L' type# for i64 lists
  (global $BStr		i32	(i32.const 0x42537472))	;; 'BStr' type# for byte strings
  (global $Map		i32 (i32.const 0x4D617020))	;; 'Map ' type# for i32 maps
  (global $maxNeg	i32  (i32.const 0x80000000));; (-2147483648)
  (global $maxNeg64 i64 (i64.const 0x8000000000000000))
  (global $TAB	  i32 (i32.const 0x09))			;; U+0009	Tab
  (global $LF	  i32 (i32.const 0x0A))			;; U+000A   Line Feed
  (global $CR	  i32 (i32.const 0x0D))			;; U+000D   Carriage Return
  (global $SP	  i32 (i32.const 0x20))			;; U+0020	Space
  (global $BANG		i32 (i32.const 0x21))		;; U+0021	Exclamation Mark !
  (global $DBLQUOTE i32 (i32.const 0x22))		;; U+0022	Double Quote "
  (global $UTF8-1 i32 (i32.const 0x24))  		;; U+0024	Dollar sign $
  (global $DOLLARSIGN i32 (i32.const 0x24))  	;; U+0024	Dollar sign $
  (global $SINGQUOTE i32 (i32.const 0x27))		;; U+0027	Singe Quote '
  (global $LPAREN i32 (i32.const 0x28))			;; U+0028   Left Parenthesis (
  (global $RPAREN i32 (i32.const 0x29))			;; U+0029   Right Parenthesis )
  (global $zero   i32 (i32.const 0x30))			;; U+0030 	Digit Zero 0
  (global $one	  i32 (i32.const 0x31))			;; U+0031	Digit One 1
  (global $ASTERISK i32 (i32.const 0x2A))		;; U+002A	Asterisk *
  (global $COMMA  i32 (i32.const 0x2C))			;; U+002C	Comma ,
  (global $COLON  i32 (i32.const 0x3A))			;; U+003A	Colon :
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
  (data (i32.const 3220) "A:\00")			(global $gA	i32 (i32.const 3220))
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
  (data (i32.const 3555) "exprStack\00")	(global $gexprStack i32 (i32.const 3555))
  (data (i32.const 3570) "addToken:\00")	(global $gaddToken: i32 (i32.const 3570))
  (data (i32.const 3585) "skipping\00")		(global $gskipping i32 (i32.const 3585))
  (data (i32.const 3595) "#toks found:\00") (global $gntoksfound i32 (i32.const 3595))
  (data (i32.const 3610) "curExpr\00")		(global $gcurExpr i32 (i32.const 3610))
  ;;(data (i32.const 3620) "last\00")			(global $glast i32 (i32.const 3620))
  (data (i32.const 3630) "Unable to print:\00")(global $gUnableToPrint i32 (i32.const 3630))
  (data (i32.const 3650) "Print Ptr:\00")	(global $gPrintPtr i32 (i32.const 3650))
  (data (i32.const 3665) "i32L\00")			(global $gi32L i32 (i32.const 3665))
  (data (i32.const 3670) "Max used: \00")	(global $gMaxUsed i32 (i32.const 3670))
  (data (i32.const 3685) "Mem Reclaimed: \00")(global $gMemReclaimed i32 (i32.const 3685))
  (data (i32.const 3705) "Start $misc.test\00")(global $gmisc.test.start i32 (i32.const 3705))
  (data (i32.const 3725) "End $misc.test\00")(global $gmisc.test.end i32 (i32.const 3725))
  (data (i32.const 3745) "[]\00")			(global $gDblBrack i32 (i32.const 3745))
  (data (i32.const 3750) "[[]]\00")			(global $gDblDblBrack i32 (i32.const 3750))
  (data (i32.const 3760) "{}\00")			(global $gDblBrace i32 (i32.const 3760))
  (data (i32.const 3765) "[{}]\00")			(global $gBrackedBrace i32 (i32.const 3765))
  (data (i32.const 3770) "pushExpr\00")		(global $gpushExpr i32 (i32.const 3770))
  (data (i32.const 3785) "popExpr\00")		(global $gpopExpr i32 (i32.const 3785))
  (data (i32.const 3795) "top\00")			(global $gtop i32 (i32.const 3795))
  (data (i32.const 3805) "In:\00")			(global $gIn: i32 (i32.const 3805))
  (data (i32.const 3810) "Out:\00")			(global $gOut: i32 (i32.const 3810))
  (data (i32.const 3820) "Empty!\00")		(global $gEmpty! i32 (i32.const 3820))
  (data (i32.const 3830) "Mem Reclamations: \00")(global $gMemReclamations  i32 (i32.const 3830))
  (data (i32.const 3900) "Advent1!\00")		(global $gAdvent1! i32 (i32.const 3900))
  (data (i32.const 3910) "\00")				(global $gEmptyString i32 (i32.const 3910))
  (data (i32.const 3915) "123\00")			(global $g123text i32 (i32.const 3915))
  (data (i32.const 3920) "forward\00")		(global $gforward i32 (i32.const 3920))
  (data (i32.const 3930) "up\00")			(global $gup i32 (i32.const 3930))
  (data (i32.const 3935) "down\00")			(global $gdown i32 (i32.const 3935))
  (data (i32.const 3945) "B:\00")			(global $gB i32 (i32.const 3945))
  (data (i32.const 3950) "C:\00")			(global $gC i32 (i32.const 3950))
  (data (i32.const 3955) "D:\00")			(global $gD i32 (i32.const 3955))
  (data (i32.const 3960) "E:\00")			(global $gE i32 (i32.const 3960))
  (data (i32.const 3965) "F:\00")			(global $gF i32 (i32.const 3965))
  (data (i32.const 3970) "G:\00")			(global $gG i32 (i32.const 3970))
  (data (i32.const 3975) "H:\00")			(global $gH i32 (i32.const 3975))
  (data (i32.const 3980) "Looking for:\00")	(global $gLookingFor i32 (i32.const 3980))
  (data (i32.const 3995) "Type error. Expected:\00")
											(global $gExpectedType i32 (i32.const 3995))
  (data (i32.const 4020) "Found:\00")		(global $gFound: i32 (i32.const 4020))
  (data (i32.const 4030) "Floop\00")		(global $gFloop i32 (i32.const 4030))
  (data (i32.const 4040) "Filter\00")		(global $gFilter i32 (i32.const 4040))
  (data (i32.const 4050) "Half#\00")		(global $gHalf# i32  (i32.const 4050))
  (data (i32.const 4060) "bitPos\00")		(global $gbitPos i32 (i32.const 4060))
  (data (i32.const 4070) "AbCDbbE\00")		(global $gAbCDbbE i32 (i32.const 4070))
  (data (i32.const 4080) "Bingo!\00")		(global $gBingo! i32 (i32.const 4080))
  (data (i32.const 4090) "-2147483648\00")	(global $gMaxNegAsString i32 (i32.const 4090))
  (data (i32.const 5005) "->\00")			(global $gArrow i32 (i32.const 5005))
  (data (i32.const 5010) "V:\00")			(global $gV i32 (i32.const 5010))
  (data (i32.const 5015) "P:\00")			(global $gP i32 (i32.const 5015))
  (data (i32.const 5020) "Seg:\00")			(global $gSeg i32 (i32.const 5020))
  (data (i32.const 5025) "S:\00")			(global $gS i32 (i32.const 5025))
  (data (i32.const 5030) "Bounds Error!\00")(global $gBoundsError i32 (i32.const 5030))
  (data (i32.const 5045) "i64L\00")			(global $gi64L i32 (i32.const 5045))
  (data (i32.const 5050) "-9,223,372,036,854,775,808")	(global $gMaxNeg64AsString i32 (i32.const 5050))
  (data (i32.const 5900) "ZZZ\00")			(global $gZZZ 	i32  (i32.const 5900)) ;;KEEP LAST & BELOW $maxFreeMem
)

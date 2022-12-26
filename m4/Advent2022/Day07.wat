;;Advent2022/Day07.m4
;; stdHeaders.m4
;;defines.m4
;; Character defines
;; Global defines
;; global null terminated strings (gnts's):
;; gAAA needs to be the first global declared
;; str.toStr uses the address to recognize the global null terminated strings
 
 

;;moduleHead.m4
;; run resulting file via "wasmtime run xxx.wat" 
;; (wasmtime recognizes the func exported as "_start")
;; or "wasmtime string1.wasm" if it has been compiled by
;; "wat2wasm --enable-bulk-memory string1.wat"
;; run tests: "wasmtime run xxx.wat --invoke _test"

(module
  (import "wasi_unstable" "fd_read"
	(func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write"
	(func $fd_write (param i32 i32 i32 i32) (result i32)))

;; table.m4
  ;; test function signatures
  (type $testSig (func (param i32)(result i32)))

  (global $strCompareOffset i32 (i32.const 0))
     (global $strToStrOffset	i32 (i32.const 1))
     (global $i32CompareOffset i32 (i32.const 2))
     (global $i32ToStrOffset	i32 (i32.const 3))
     
  (func $test (export "_test")
	;; Run tests: wasmtime run XXX.wat --invoke _test
	(local $testOff i32)
	(local $oldCurMemUsed i32)
	(local.set $testOff (global.get $gFirstTestOffset))
	(local.set $oldCurMemUsed (global.get $curMemUsed))
	(loop $testLoop
	  (if (i32.lt_u (local.get $testOff)(global.get $tableLength))
	    (then
		  (local.get $testOff)
		  (call $Test.show
			(i32.const 42)  ;; I've forgotten why this is needed!
			(call_indirect
			  (type $testSig)
			  (local.get $testOff)))
		  (local.set $testOff (i32.add(local.get $testOff)(i32.const 1)))
		  (br $testLoop)
		)
	  )
	)
	(call $reclaimMem (local.get $oldCurMemUsed))
	(call $showMemUsed)
  )
  (func $Test.show (param $testNum i32)(param $testResult i32)
	(if (local.get $testResult)
	  (then
	    (call $Test.showFailed
		  (local.get $testNum)
		  (local.get $testResult)))
	  (else
		(call $Test.showOK (local.get $testNum))))
  )
  ;; try to avoid allocations during tests
  (func $Test.printTest
    (call $byte.print (i32.const 84(;T;)))
	(call $byte.print (i32.const 101(;e;)))
	(call $byte.print (i32.const 115(;s;)))
	(call $byte.print (i32.const 116(;t;)))
	(call $printsp)
  )
  (func $Test.showOK (param $testnum i32)
    (call $Test.printTest)
	(call $i32.print (i32.sub (local.get $testnum)(global.get $gFirstTestOffset)))
	(call $printsp)
	(call $byte.print (i32.const 79(;O;)))
	(call $byte.print (i32.const 75(;K;)))
	(call $printlf)
  )
  (func $Test.showFailed (param $testnum i32)(param $testResult i32)
    (call $Test.printTest)
	(call $i32.print (i32.sub(local.get $testnum)(global.get $gFirstTestOffset)))
	(call $printsp)
	(call $byte.print (i32.const 78(;N;)))
	(call $byte.print (i32.const 79(;O;)))
	(call $byte.print (i32.const 75(;K;)))
	(call $byte.print (i32.const 33(;!;)))
	(call $byte.print (i32.const 33(;!;)))
	(call $printsp)
	(call $i32.print (local.get $testResult))
	(call $printlf)
	)


;; errors.m4
  (func $error (result i32)
	;; throw a divide-by-zero exception!
	(i32.div_u (i32.const 1) (i32.const 0))
  )
  (func $error2
    (local $t i32)
    (local.set $t (i32.div_u (i32.const 1) (i32.const 0)))
  )
  (func $error3 (param $err i32)
    (call $byte.print (i32.const 45(;-;)))
	(call $i32.print (local.get $err))
    (call $byte.print (i32.const 45(;-;)))
	(call $byte.print (i32.const 32(;SP;)))
	(call $error2)
  )
 
;; memory.m4
  ;;(global $memChunks i32 (i32.const 1024))
  ;;(memory (global.get $memChunks))
  (memory 1024)
  (export "memory" (memory 0))
  ;;(global $memSize i32 (i32.const 1048576))  ;; 1024*1024 (currently $memSize not used)
  (global $memReclaimed (mut i32) (i32.const 0))
  (global $memReclamations (mut i32) (i32.const 0))
  
  (func $roundUpTo4 (param $size i32)(result i32)
	(i32.and (i32.add (local.get $size) (i32.const 3))(i32.const 0xfffffffc))
  )
  (func $mem.get (param $size i32)(result i32)
	;; Simple memory allocation done in 32-bit boundaries
	;; Should this get cleared first?
	(global.set $curMemUsed (call $roundUpTo4 (global.get $curMemUsed)))
	(global.get $curMemUsed) ;; on stack to return
	(global.set $curMemUsed (i32.add (global.get $curMemUsed)(local.get $size)))
	(if (i32.gt_u (global.get $curMemUsed)(global.get $maxMemUsed))
	  (global.set $maxMemUsed (global.get $curMemUsed)))
  )
  (func $reclaimMem (param $newCurMemUsed i32)
  ;; A simple way to reclaim memory
  ;; Resets where new mem is allocated and clears the reclaimed words
  ;; WARNING: It's possible that a string in the remaining memory could
  ;; point to string data in the reclaimed section
    (local $reclaimedBytes i32)
	(local $reclaimedWords i32)
	(local $wordToClear i32)
	(local $oldCurMemUsed i32)
    ;;(return)
	(if (i32.gt_u (local.get $newCurMemUsed)(global.get $curMemUsed))
	  (then
		 (call $str.printwlf(call $str.mkdata (global.get $reclaimMem)))
		(call $error2)
	  ))
	;;_testString('progress', `past first test in $reclaimMem')
	;; check for i32 word alignment
	(local.set $newCurMemUsed (call $roundUpTo4 (local.get $newCurMemUsed)))
	(if (i32.and (local.get $newCurMemUsed) (i32.const 3))
	  (call $error3 (i32.const 32)))
	(local.set $oldCurMemUsed (call $roundUpTo4 (global.get $curMemUsed)))
	(if (i32.and (local.get $oldCurMemUsed) (i32.const 3))
	  (call $error3 (i32.const 33)))
	(local.set $reclaimedBytes
	  (i32.sub (global.get $curMemUsed)(local.get $newCurMemUsed)))
	(global.set $memReclaimed
	  (i32.add (global.get $memReclaimed)(local.get $reclaimedBytes)))
	(local.set $wordToClear (local.get $newCurMemUsed))
	(loop $clearLoop
	  (if (i32.lt_u
		(local.get $wordToClear)
		(local.get $oldCurMemUsed))
		(then
		  (i32.store (local.get $wordToClear) (i32.const 0))
		  (local.set $wordToClear (i32.add (local.get $wordToClear) (i32.const 4)))
		  (br $clearLoop))))
	(global.set $curMemUsed (local.get $newCurMemUsed))
	(global.set $memReclamations (i32.add (global.get $memReclamations) (i32.const 1)))
  )
  (func $showMemUsedHelper (param $numBytes i32)(param $msg i32)
    (call $strdata.print (local.get $msg))
	(call $i32.print (local.get $numBytes))(call $printsp)
	(call $byte.print (i32.const 40(;LPAREN;)))
	(call $i32.print
	  (i32.shr_u (local.get $numBytes)(i32.const 10)))
	(call $byte.print (i32.const 75(;K;)))
	(call $byte.print (i32.const 41(;RPAREN;)))
	(call $printlf)
  )
   
   
   
   
  (func $showMemUsed 
	(local $memUsedMsg i32)
	(local $maxUsedMsg i32)
	(local $memReclaimedMsg i32)
	(local $memReclamationsMsg i32)
	(local $bytesUsed i32)
	;;(local $maxUsed i32)
	(call $showMemUsedHelper (global.get $curMemUsed)(global.get $gMemUsedMsg:))
	(local.set $bytesUsed
	  (i32.sub
		(global.get $maxMemUsed)
		(global.get $curMemUsed)))
	(call $showMemUsedHelper (local.get $bytesUsed)(global.get $gMaxUsedMsg:))
	(call $showMemUsedHelper (global.get $memReclaimed)(global.get $gMemReclaimed:))
	(call $showMemUsedHelper (global.get $memReclamations)(global.get $gMemReclamations:))
  )
  (func $mem.dumpline (param $memPtr i32)
	(local $ctr i32)
	;;_testString(`indumpline',`starting dumpline')
    (call $i32.hexprint(local.get $memPtr))  ;; show where we are in memory
	(local.set $ctr (i32.const 0))
	(loop $byteLoop1
	  (call $byte.hexprint (i32.load8_u (i32.add (local.get $ctr)(local.get $memPtr))))
	  (call $printsp)
	  (local.set $ctr (i32.add(local.get $ctr)(i32.const 1)))
	  (if (i32.lt_u (local.get $ctr) (i32.const 16))
		(br $byteLoop1)))
	(call $printsp)(call $printsp)
	(local.set $ctr (i32.const 0))
	(loop $byteLoop2
	  (call $byte.dump (i32.load8_u (i32.add (local.get $ctr)(local.get $memPtr))))
	  (local.set $ctr (i32.add(local.get $ctr)(i32.const 1)))
	  (if (i32.lt_u (local.get $ctr) (i32.const 16))
		(br $byteLoop2)))
	(call $printlf)
  )
   
  (func $mem.dump
    (local $memPtr i32)(local $nCols i32)(local $col i32)(local $row i32)(local $byte i32)
	(local.set $nCols (i32.const 100))
	;;_testString(`mem.dump',`Starting $mem.dump')
	(call $strdata.print (global.get $curMemUsed:))
	  (call $i32.print (global.get $curMemUsed))
	  (call $printlf)
	(local.set $memPtr (i32.const 0))
	(local.set $row (i32.const 0))
	(loop $rowLoop
	  (call $mem.dumpline (local.get $memPtr))
	  (local.set $memPtr (i32.add (local.get $memPtr) (i32.const 16)))
	  (if (i32.lt_u (local.get $memPtr)(global.get $curMemUsed))
	    (br $rowLoop)))
	)
  (func $showMemory
	(call $strdata.print (global.get $curMemUsed:))
	  (call $i32.print (global.get $curMemUsed))
	  (call $printlf)
  )

;; types.m4
  (func $getTypeNum(param $ptr i32)(result i32)
	(i32.load (local.get $ptr))
  )
  (func $setTypeNum(param $ptr i32)(param $typeNum i32)
	(i32.store (local.get $ptr)(local.get $typeNum))
  )
   
   
  (func $typeError (param $typeFound i32)(param $typeExpected i32)
    (call $printwsp (global.get $gExpectedType))
	(call $printwlf (call $typeNum.toStr (local.get $typeExpected)))
	(call $printwsp (global.get $gFound:))
	(call $printwlf (call $typeNum.toStr (local.get $typeFound)))
	(call $error2)
  )
  (func $typeNum.toStr (param $typeNum i32)(result i32)
    (local $strptr i32)
	(local.set $strptr (call $str.mk))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum) (i32.const 0)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum) (i32.const 8)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum) (i32.const 16)))
    (call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 24)))
	(local.get $strptr)  ;;return the new string
  )
     (func $typeNum.toStr.test (param $testNum i32)(result i32)
    ;;(call $str.printwlf (call $i32.toStr (global.get $i32L)))
	;;(call $printwlf (global.get $gi32L))
	(i32.eqz
	  (call $str.compare
		(call $typeNum.toStr (global.get $i32L)) ;; i32 value
		(call $str.mkdata (global.get $gi32L))))	;; null terminated string
  )
   
  (func $boundsError (param $pos i32)(param $max i32)
    (call $printwsp (global.get $gBoundsError))
	(call $printwsp (local.get $pos))
	(call $printwlf (local.get $max))
	(call $error2)
  )

;; string.m4
  (global $BStr		i32	(i32.const 0x72745342))	;; 'BStr' type# for byte strings
  (type $keyCompSig (func (param i32)(param i32)(result i32)))
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
	(local.set $strPtr (call $mem.get (i32.const 20)))
	(call $setTypeNum (local.get $strPtr) (global.get $BStr))
	(call $str.setByteLen (local.get $strPtr) (i32.const 0))
	(call $str.setMaxLen (local.get $strPtr) (i32.const 4))
	(call $str.setDataOff (local.get $strPtr)(i32.add(local.get $strPtr)(i32.const 16)))
	(local.get $strPtr)
  )
  (func $str.catByte (param $strPtr i32)(param $byte i32)
	(local $maxLen i32) (local $byteLen i32)
	(local.set $byteLen (call $str.getByteLen (local.get $strPtr)))
	(local.set $maxLen (call $str.getMaxLen (local.get $strPtr)))
	(if (i32.ge_u (local.get $byteLen) (local.get $maxLen))
	  (then (call $str.extend (local.get $strPtr))))
	(i32.store8
	  (i32.add (local.get $byteLen)(call $str.getDataOff (local.get $strPtr)))
	  (local.get $byte))  ;; only the low order 8 bits are used
	(call $str.setByteLen(local.get $strPtr)
	  (i32.add (local.get $byteLen) (i32.const 1)))
  )
   
     (func $str.catByte.test (param $testNum i32)(result i32)
	(local $sp i32)
	(local $memsp i32)
	(local.set $sp
	  (call $str.mk))
	(local.set $memsp 
	  (call $str.mkdata
		(global.get $gABCDEF)))
	(call $str.catByte (local.get $sp) (i32.const 65(;A;)))
	(call $str.catByte (local.get $sp) (i32.const 66(;B;)))
	(call $str.catByte (local.get $sp) (i32.const 67(;C;)))
	(call $str.catByte (local.get $sp) (i32.const 68(;D;)))
	(call $str.catByte (local.get $sp) (i32.const 69(;E;)))
	(call $str.catByte (local.get $sp) (i32.const 70(;F;)))
	(if
	  (i32.eqz
		(call $str.compare
		  (local.get $sp)
		  (local.get $memsp)))
	  (then
		(return (i32.const 1))))  ;; Failure
	;; Test UTF-8 compliance a bit
	(i32.const 0) ;; success
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
			(local.set $s2pos (i32.add(local.get $s2pos)(i32.const 1)))
			(br $bloop))))		
  )
   
     (func $str.catStr.test (param $testNum i32)(result i32)
    (local $AAA i32)(local $ZZZ i32)(local $aaa i32)
	(local.set $AAA (call $str.mkdata (global.get $gAAA)));; (call $str.print(local.get $AAA))(call $printlf)
	(local.set $ZZZ (call $str.mkdata (global.get $gZZZ)));; (call $str.print(local.get $ZZZ))(call $printlf)
	(local.set $aaa (call $str.mk))
	(call $str.catStr (local.get $aaa)(local.get $AAA));;(call $str.print(local.get $aaa))(call $printlf)
	(call $str.catStr (local.get $aaa)(local.get $ZZZ));;(call $str.print(local.get $aaa))(call $printlf)
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
		  (local.set $bpos (i32.add(local.get $bpos)(i32.const 1)))
		  (br $bloop1))))
	(local.set $bpos (i32.const 0))
	(loop $bloop2
	  (if (i32.lt_u (local.get $bpos)(local.get $byteLen2))
		(then
		  (call $str.catByte (local.get $s1+2Ptr)
			(call $str.getByte (local.get $s2Ptr)(local.get $bpos)))
		  (local.set $bpos (i32.add(local.get $bpos)(i32.const 1)))
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
			(local.set $cpos (i32.add(local.get $cpos)(i32.const 1)))
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
		(i32.sub (call $str.getByteLen (local.get $ts)) (i32.const 1)))
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
		(local.set $C (i32.shl (local.get $C) (i32.const 8)))  ;; move to next byte
	  (if (local.get $C)  ;; More?
	   (br $byteLoop)))
  )
  (global $UTF8-1 i32 (i32.const 0x24))		;; U+0024	Dollar sign
  (global $UTF8-2 i32 (i32.const 0xC2A2))		;; U+00A2	Cent sign
  (global $UTF8-3 i32 (i32.const 0xE0A4B9))	;; U+0939	Devanagari Letter Ha
  (global $UTF8-4 i32 (i32.const 0xF0908D88))	;; U+10348	Gothic Letter Hwair
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
			  (return (i32.const 0)))  ;; Failure
			(local.set $cpos (i32.add(local.get $cpos)(i32.const 1)))
			(br $cloop)
		)))
	(i32.const 1)  ;; Success
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
	(local.set $newMaxLen (i32.mul (local.get $maxLen) (i32.const 2)))
	(local.set $newDataOff (call $mem.get (local.get $newMaxLen)))
	(call $str.setMaxLen(local.get $strPtr)(local.get $newMaxLen))
	(call $str.setDataOff(local.get $strPtr)(local.get $newDataOff))
	(memory.copy (local.get $newDataOff)(local.get $dataOff)(local.get $curLen))
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
  (func $str.getByteLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr) (i32.const 4)))
  )
  (func $str.setByteLen(param $strPtr i32)(param $newLen i32)
	(i32.store (i32.add (local.get $strPtr) (i32.const 4)) (local.get $newLen))
  )
  (func $str.getMaxLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr) (i32.const 8)))
  )
  (func $str.setMaxLen(param $strPtr i32)(param $newMaxLen i32)
	(i32.store (i32.add(local.get $strPtr) (i32.const 8))(local.get $newMaxLen))
  )
  (func $str.getDataOff (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr)(i32.const 12)))
  )
  (func $str.setDataOff (param $strPtr i32)(param $newDataOff i32)
    (i32.store (i32.add(local.get $strPtr)(i32.const 12))(local.get $newDataOff))
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
			(i32.load8_u (i32.sub (i32.add (local.get $dataOff)(local.get $cpos)) (i32.const 1))))
		(local.set $cpos (i32.sub (local.get $cpos) (i32.const 1)))
		(br_if $cloop (i32.gt_s (local.get $cpos) (i32.const 0)))
	)
	(i32.store8 (local.get $dataOff)(local.get $Lchar))
  )
  (func $str.mkdata (param $dataOffset i32) (result i32)
	(local $curByte i32)(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(loop $bLoop
	  (local.set $curByte (i32.load8_u (local.get $dataOffset)))
	  (if (local.get $curByte)
		(then
		  (call $str.catByte (local.get $strPtr)(local.get $curByte))
		  (local.set $dataOffset (i32.add (local.get $dataOffset) (i32.const 1)))
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
		  (local.set $bpos (i32.add(local.get $bpos)(i32.const 1)))
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
	(local.set $dataOffset (call $str.getDataOff (local.get $strPtr)))
	(loop $cLoop
	  (if (i32.lt_u (local.get $cpos)(local.get $curLength))
		(then
		 (i32.load8_u (i32.add (local.get $dataOffset)(local.get $cpos)))
		 (call $byte.print)   
	     (local.set $cpos (i32.add (local.get $cpos) (i32.const 1)))
	     (br $cLoop))))
  )
  (func $str.printwlf (param $strPtr i32)
	(call $str.print (local.get $strPtr))
	(call $printlf)
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
			  (local.set $patPos (i32.add(local.get $patPos)(i32.const 1)))
			  (local.set $cPos (i32.add(local.get $cPos)(i32.const 1)))
			  (br $cloop))))))
	(i32.eq (local.get $patPos)(local.get $patLen))  ;; matched whole pat?
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
			(local.set $spos (i32.add(local.get $spos)(i32.const 1)))
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
  (func $str.toStr (param $strPtr i32)(result i32)
	;; This is used by map routines to dump a key that is a string
	(local.get $strPtr)
  )
  (func $strdata.print (param $dataOffset i32)
    ;; Print a null-terminated string
	;; avoiding data allocations
	(local $curByte i32)
	(loop $bLoop
	  (local.set $curByte (i32.load8_u (local.get $dataOffset)))
	  (if (local.get $curByte)
		(then
		  (call $byte.print (local.get $curByte))
		  (local.set $dataOffset (i32.add(local.get $dataOffset)(i32.const 1)))
		  (br $bLoop)))
	)
  )
  (func $strdata.printwlf (param $global i32)
    (call $printwlf (call $str.mkdata (local.get $global)))
  )
  (func $toStr (param $ptr i32)(result i32)
    (local $strPtr i32)
	(if (i32.eq (local.get $ptr) (i32.const 0x80000000))
	  (return (call $i32.toStr (local.get $ptr))))
	(if (i32.gt_u (local.get $ptr)(global.get $gZZZ))  ;; should be 'typed' data
	  (return (call $ptr.toStr (local.get $ptr))))
	(if
	  (i32.and
		(i32.ge_u (local.get $ptr)(global.get $gAAA))
		(i32.le_u (local.get $ptr)(global.get $gZZZ)))
	  (return (call $str.mkdata(local.get $ptr))))    ;; should be a null-terminated string
	(call $i32.toStr (local.get $ptr)) ;; just a number?
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
	(return (i32.const 0))
  )
  (func $str.catsp (param $strPtr i32)
	(call $str.catByte (local.get $strPtr)(i32.const 32(;SP;))))
  (func $str.catlf (param $strPtr i32)
    (call $str.catByte (local.get $strPtr)(i32.const 10(;LF;))))
  (func $str.drop(param $strPtr i32)  ;; drops last byte in string
	(if (i32.eqz (call $str.getByteLen (local.get $strPtr)))
	  (return))
	(call $str.setByteLen
	  (local.get $strPtr)
	  (i32.sub
		(call $str.getByteLen (local.get $strPtr)) (i32.const 1)))
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
		  (local.set $byte (call $str.getByte (local.get $strPtr)(local.get $bpos)))
		  (if (i32.eq (local.get $byte) (i32.const 32(;SP;)))
		    (then   ;; skip over blanks!
			  (local.set $bpos (i32.add (local.get $bpos) (i32.const 1)))
			  (br $sloop)))  
		  (local.set $temp (i32.sub (local.get $byte) (i32.const 48(;0;))))
		  (local.set $retv (i32.add (local.get $temp) (i32.mul(local.get $retv)(i32.const 10))))
		  (local.set $bpos (i32.add (local.get $bpos) (i32.const 1)))
		  (br $sloop))))
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
   
  (func $ptr.toStr (param $ptr i32)(result i32)
    (local $type i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(local.set $type (call $getTypeNum (local.get $ptr)))
	;;_testString(`t1',`in $ptr.toStr')(call $printsp)
	;;(call $str.print(call $typeNum.toStr (local.get $type)))(call $printlf)
	(if (i32.eq (local.get $type)(global.get $BStr))
	  (then
		(call $str.catByte (local.get $strPtr)(i32.const 34(;";)))
		(call $str.catStr (local.get $strPtr)(local.get $ptr))
		(call $str.catByte (local.get $strPtr)(i32.const 34(;";)))
		(return (local.get $strPtr))))
	(if (i32.eq (local.get $type)(global.get $i32L))
	 (then
	  (call $str.catStr 
		  (local.get $strPtr)
		  (call $i32list.toStr (local.get $ptr)))
	  (return (local.get $strPtr))))
	(if (i32.eq (local.get $type)(global.get $i64L))
    (then
	  (call $str.catStr 
		  (local.get $strPtr)
		  (call $i64list.toStr (local.get $ptr)))
	  (return (local.get $strPtr))))
	;;(call $i32.hexprint(local.get $type))
	(call $str.printwlf (call $typeNum.toStr(local.get $type)))
	(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gUnableToPrint:)))
	(call $i32.toStr (local.get $ptr))
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
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr)) (i32.const 3))
	  (return (i32.const 1)))
	  ;;(call $print (local.get $listPtr)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 69)))  ;; 'E'
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr)) (i32.const 1))
	  (return (i32.const 2)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 122)))  ;; 'z'
	(local.set $strptr0 (call $i32list.get@ (local.get $listPtr) (i32.const 0)))
	(if (i32.eqz 
		  (call $str.compare
			(call $i32list.get@ (local.get $listPtr) (i32.const 0))
			(local.get $AbCDbE)))
	  (return (i32.const 3)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbbE)(i32.const 98))) ;; split on'b'
	;; test to make sure multiple split characters are treated as a single split
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr)) (i32.const 3))
	  (return (i32.const 4))
	  ;;(call $printwlf (local.get $listPtr))
	  )
	(i32.const 0) ;; success
  )
  (func $str.index (param $strPtr i32)(param $ichar i32)(result i32)
	;; looks for $ichar in the string passed.  Returns position, or _maxNeg if not found
	(local $cpos i32)(local $strLen i32)
	(local.set $cpos (i32.const 0))
	(local.set $strLen (call $str.getByteLen (local.get $strPtr)))
	(loop $cLoop
	  (if (i32.lt_u (local.get $cpos)(local.get $strLen))
	    (then
		  (if (i32.eq (call $str.getByte (local.get $strPtr)(local.get $cpos))(local.get $ichar))
			(return (local.get $cpos)))
		  (local.set $cpos (i32.add(local.get $cpos)(i32.const 1)))
		  (br $cLoop)
		)
	  )
	)
	(i32.const 0x80000000)
  )
   
  (func $str.index.test (param $testNum i32)(result i32)
    (local $testString i32)
	(local.set $testString (call $str.mkdata(global.get $gABCdef)))
    ;; test for first char
	(if (i32.ne (call $str.index (local.get $testString) (i32.const 65(;A;))) (i32.const 0))
	  (return (i32.const 1)))
	;; test for last char
	(if (i32.ne (call $str.index (local.get $testString) (i32.const 102(;f;))) (i32.const 5))
	  (return (i32.const 1)))
	;; test for missing char
	(if (i32.ne (call $str.index (local.get $testString) (i32.const 90(;Z;))) (i32.const 0x80000000))
	  (return (i32.const 1)))
	(i32.const 0) ;; success
  )
     ;; split a string into i32's 
  (func $strToInt32s (param $line i32)(result i32)
    (local $cList i32)(local $numInts i32)(local $pos i32)(local $intList i32)
	(local $int i32)
	(local.set $cList (call $str.Csplit (local.get $line) (i32.const 32(;SP;))))
	;;(call $printwlf (local.get $cList))
	(local.set $numInts (call $i32list.getCurLen (local.get $cList)))
	(local.set $pos (i32.const 0))
	(local.set $intList (call $i32list.mk))
	(loop $intLoop  ;; oops, assumes string isn't empty!
	  (local.set $int (call $str.toI32 (call $i32list.get@ (local.get $cList)(local.get $pos))))
	  (call $i32list.push (local.get $intList)(local.get $int))
	  (local.set $pos (i32.add (local.get $pos)(i32.const 1)))
	  (if (i32.lt_u (local.get $pos)(local.get $numInts))
	    (br $intLoop)))
	(local.get $intList)
  )


;; map.m4

  (global $Map		i32 (i32.const 0x4D617020))	;; 'Map ' type# for i32 maps
   

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
  (global $mapTypeOff i32  (i32.const 0) )
  (global $mapListOff i32  (i32.const 1) )
  (global $valListOff i32  (i32.const 2) )
  (global $keyCompareOff i32  (i32.const 3) )
  (global $keyPrintOff i32  (i32.const 4) )
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
	(local.set $mapPos  (i32.const 0) )
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
		  (local.set $mapPos (i32.add (local.get $mapPos) (i32.const 1) ))
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
	(local.set $mapPos  (i32.const 0) )
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
		  (local.set $mapPos (i32.add (local.get $mapPos) (i32.const 1) ))
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
	(local.set $mapPos  (i32.const 0) )
	(call $str.catByte (local.get $strPtr)(i32.const 123(;{;)))
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
		  (local.set $mapPos (i32.add (local.get $mapPos) (i32.const 1) ))
		  (if (i32.lt_u (local.get $mapPos)(local.get $mapLen))
		    (then
			  (call $str.catByte (local.get $strPtr) (i32.const 44(;COMMA;)))
			  (call $str.catsp (local.get $strPtr))))
		  (br $mLoop))))
	(call $str.catByte (local.get $strPtr) (i32.const 125(;};)))
	(local.get $strPtr)
  )
     (func $map.test (param $testNum i32)(result i32)
	(local $imap i32)
	(local $smap i32)
	(local.set $imap (call $i32Map.mk))
	;; set map 3 -> 42 and test it
	(call $map.set (local.get $imap) (i32.const 3) (i32.const 42))
	(if
	  (i32.ne
		(call $map.get (local.get $imap) (i32.const 3) )
		(i32.const 42))
	  (return  (i32.const 1) )) ;; error #1
	;; use a key that hasn't been set
	(if
	  (i32.ne
		(call $map.get (local.get $imap) (i32.const 4) )
		(global.get $maxNeg))  	;; expect it not to be there
	  (return  (i32.const 2) ))	;; error #2
	;; set a second key/val pair and test it 4 ->43
	(call $map.set (local.get $imap) (i32.const 4) (i32.const 43))
	(if
	  (i32.ne
		(call $map.get (local.get $imap) (i32.const 4) )
		(i32.const 43))
	  (return  (i32.const 3) ))	;; error #3
	;; reset the value of key 3
	(call $map.set (local.get $imap) (i32.const 3) (i32.const 45))
	(if
	  (i32.ne
		(call $map.get (local.get $imap) (i32.const 3) )
		(i32.const 45))
	  (return  (i32.const 4) ))	;; error #4
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
     (i32.const 0)  ;; Success
  )

;; io.m4
  (global $readIOVsOff0 i32 (i32.const 0))
  (global $readIOVsOff4 	i32  (i32.const 4) )
  (global $readBuffOff 		i32  (i32.const 8) )
  (global $readBuffLen 		i32  (i32.const 4) )
  (global $writeIOVsOff0 	i32  (i32.const 16) )
  (global $writeIOVsOff4 	i32 (i32.const 20))
  (global $writeBuffOff 	i32 (i32.const 24))
  (global $writeBufLen 		i32  (i32.const 4) )
  (global $bytesRead		i32  (i32.const 4) )
  (global $bytesWritten		(mut i32)  (i32.const 0) )
  (func $io.initialize
  )
  (func $byte.print (param $B i32)
	(i32.store (global.get $writeIOVsOff0)(global.get $writeBuffOff))
	(i32.store (global.get $writeIOVsOff4) (i32.const 1) )
	(i32.store
		(global.get $writeBuffOff)
		(local.get $B))
	(call $fd_write
		 (i32.const 1)  ;; stdout
		(global.get $writeIOVsOff0)
		 (i32.const 1)  ;; # iovs
		 (i32.const 0)  ;; length?
	)
	drop
	(global.set $bytesWritten (i32.add (global.get $bytesWritten) (i32.const 1) ))
  )
  (func $byte.read (result i32)
	(local $nread i32)(local $rbyte i32)
	(i32.store (global.get $readIOVsOff0) (global.get $readBuffOff))
	(i32.store (global.get $readIOVsOff4)  (i32.const 1) )
	(call $fd_read
	   (i32.const 0)  ;; 0 for stdin
	  (global.get $readIOVsOff0) ;; *iovs
	   (i32.const 1)  ;; iovs_len
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
  (func $printsp (call $byte.print (i32.const 32(;SP;))))
  (func $printlf (call $byte.print (i32.const 10(;LF;))))
  (func $printwlf (param $ptr i32)
	(call $print (local.get $ptr))
	(call $printlf)
  )
  ;; print out ASCII of byte or a period if not printable
  (func $isASCII (param $byte i32)(result i32)
	(if (i32.ge_u (local.get $byte) (i32.const 32(;SP;)))
	  (then (if (i32.le_u (local.get $byte)(i32.const 126(;~;)))
	    (then (return (i32.const 1))))))
	(return (i32.const 0))
  )
  (func $byte.dump (param $byte i32)  ;; display memory as text
    (local.set $byte (i32.and (local.get $byte)(i32.const 0xFF)))
	(if (call $isASCII (local.get $byte))
	  (then	(call $byte.print (local.get $byte)))
	  (else	(call $byte.print (i32.const 46(;.;)))))
  )
  (func $i32.hexprint (param $N i32)
	(call $byte.print (i32.const 48(;0;)))
	(call $byte.print (i32.const 120(;x;))) ;; 'x'
	(call $i32.hexprintsup (local.get $N))
	(call $byte.print (i32.const 32(;SP;)))  ;; space
  )
  (func $i32.hexprintsup (param $n i32)
    (call $byte.hexprint (i32.shr_u (local.get $n)(i32.const 24)))
    (call $byte.hexprint (i32.shr_u (local.get $n) (i32.const 16) ))
    (call $byte.hexprint (i32.shr_u (local.get $n) (i32.const 8) ))
    (call $byte.hexprint (local.get $n))
  )
  (func $i64.hexprint (param $N i64)
	(call $byte.print (i32.const 48(;0;)))
	(call $byte.print (i32.const 120(;x;))) ;; 'x'
	(call $i64.hexprintsup (local.get $N))
	(call $byte.print (i32.const 32(;SP;)))  ;; space
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
	(call $nibble.hexprint (i32.shr_u (local.get $byte) (i32.const 4) ))
	(call $nibble.hexprint (i32.and (i32.const 0xF)(local.get $byte)))
  )
  (func $nibble.hexprint (param $nibble i32)
	(local.set $nibble (i32.and (local.get $nibble)(i32.const 0xf)))
	(if (i32.lt_u (local.get $nibble)(i32.const 10))
	  (then
		(call $byte.print (i32.add (i32.const 48(;0;))(local.get $nibble))))
	  (else
		(call $byte.print(i32.add (i32.const 55)(local.get $nibble))))) ;; 55=='A'-10
  )
  (func $str.read (result i32)
	(local $strPtr i32)
	(local $byte i32)
	(local.set $strPtr (call $str.mk))
	(loop $bloop
	  (local.set $byte (call $byte.read))
	  (if (i32.ge_s (local.get $byte) (i32.const 0))
		(then
		  (if (i32.eq (local.get $byte) (i32.const 10(;LF;)))
			(return (local.get $strPtr)))
		  (call $str.catByte(local.get $strPtr)(local.get $byte))
		  (br $bloop)
		)
	  )
	  (if (i32.eq (local.get $byte)(global.get $maxNeg))
	    (then
		  (if (call $str.getByteLen (local.get $strPtr))
			(return (local.get $strPtr)))
		  (return (i32.const 0x80000000))
		)
	  )
	)
	(local.get $strPtr)
  )
  ;; Clear passed string before reading line into it
  (func $str.readIntoStr (param $strPtr i32)(result i32)
    (call $str.setByteLen (local.get $strPtr) (i32.const 0))
	(call $str.readOntoStr (local.get $strPtr))
  )
  ;; Add bytes up to LF to passed string
  ;; Returns eol terminator (LF or $maxNeg)
  (func $str.readOntoStr (param $strPtr i32)(result i32)
	(local $byte i32)
	(loop $bloop
	  (local.set $byte (call $byte.read))
	  (if (i32.ge_s (local.get $byte) (i32.const 0))
		(then
		  (if (i32.eq (local.get $byte) (i32.const 10(;LF;)))
			(return (i32.const 10(;LF;))))
		  (if (i32.ne (local.get $byte) (i32.const 13(;CR;)));; skip over carriage returns!
			(call $str.catByte(local.get $strPtr)(local.get $byte)))
		  (br $bloop)
		)
		(else
		  (return (i32.const 0x80000000))
		)
	  )
	)
	(return (i32.const 0x80000000))
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
	  


;; i32.m4
   
  (global $maxNeg i32 (i32.const 0x80000000))

  (func $i32.compare (param $i1 i32)(param $i2 i32)(result i32)
	(i32.eq (local.get $i1)(local.get $i2))
  )
  (func $i32.printOLD (param $N i32)	;; change this to more like the simple $i32.print below !!
										;; this avoids storage allocations while printing an i32
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
	(if (i32.lt_s (local.get $N) (i32.const 0) )
	  (then
		(call $str.catByte(local.get $strPtr)(i32.const 45))  ;; hyphen
		(call $i32.toStrHelper (local.get $strPtr)(i32.sub  (i32.const 0) (local.get $N)))
		return))
    (if (i32.ge_u (local.get $N)(i32.const 10))
	  (call $i32.toStrHelper
		(local.get $strPtr)
		(i32.div_u (local.get $N)(i32.const 10))))
	(call $str.catByte (local.get $strPtr)
	  (i32.add
		(i32.rem_u (local.get $N)(i32.const 10))
		(i32.const 48(;0;))))
  )
(func $i32.print (param $N i32)
  (if (i32.ge_u (local.get $N)(i32.const 10))
    (call $i32.print (i32.div_u (local.get $N)(i32.const 10))))
  (call $byte.print
	  (i32.add
		(i32.rem_u (local.get $N)(i32.const 10))
		(i32.const 48(;0;))))
)

;;i32list.m4
  ;; i32Lists (basically 1-dimensional arrays of i32's)
  ;; an i32list pointer points at
  ;; a typeNum, curLen, maxLen, data pointer, all i32
  ;; the list starts out with a maxLen of 1 (4 bytes)
  ;; which is allocated in the next i32 (20 bytes total)
  (global $i32L	  	i32	(i32.const 0x4C323369)) ;; 'i32L' type# for i32 lists
   
  (func $i32.printMem (param $memOff i32)
	(call $i32.print (i32.load (local.get $memOff)))
  )
  (func $i32list.mk (result i32)
	;; returns a memory offset for an i32list pointer:
	;; 		typeNum, curLength, maxLength, dataOffset
	(local $lstPtr i32)
	(local.set $lstPtr (call $mem.get (i32.const 20))) 
	;; 4 bytes for type, 12 for the pointer info, 4 for first int32
	(call $setTypeNum (local.get $lstPtr)(global.get $i32L))
	(call $i32list.setCurLen (local.get $lstPtr) (i32.const 0))
	(call $i32list.setMaxLen (local.get $lstPtr)(i32.const 1))
	(call $i32list.setDataOff(local.get $lstPtr)
		(i32.add(local.get $lstPtr) (i32.const 16))) ;; 16 bytes for header info
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
(;;
;;  _addToTable($i32list.sets.test)
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
;;)
  (func $i32list.extend (param $lstPtr i32)
    ;; double the space available
	(local $maxLen i32) (local $curLen i32) (local $dataOff i32)
	(local $newMaxLen i32)(local $newDataOff i32)
	(local $cpos i32)
	(local.set $curLen (call $i32list.getCurLen (local.get $lstPtr)))
	(local.set $maxLen (call $i32list.getMaxLen (local.get $lstPtr)))
	(local.set $dataOff   (call $i32list.getDataOff (local.get $lstPtr)))
	(local.set $newMaxLen (i32.mul (local.get $maxLen)(i32.const 2)))
	(local.set $newDataOff (call $mem.get (i32.mul (local.get $newMaxLen)(i32.const 4))))
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
	(if (i32.lt_s (call $i32list.getCurLen (local.get $lstPtr)) (i32.const 0))
	  (call $boundsError (local.get $pos)(call $i32list.getCurLen (local.get $lstPtr))))
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
	(call $i32list.set@ (local.get $listPtr) (i32.const 0) (i32.const 33)) ;; should fail
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
	(local $maxLen i32) (local $curLen i32)
	(local.set $curLen (call $i32list.getCurLen(local.get $lstPtr)))
	(local.set $maxLen (call $i32list.getMaxLen(local.get $lstPtr)))
	(if (i32.ge_u (local.get $curLen) (local.get $maxLen));;handle reallocation
		(then
		  (call $i32list.extend (local.get $lstPtr))
		  (local.set $maxLen (call $i32list.getMaxLen(local.get $lstPtr)))
		))
	(call $i32list.set@ (local.get $lstPtr)(local.get $curLen)(local.get $val))
	(call $i32list.setCurLen (local.get $lstPtr)
		(i32.add (local.get $curLen) (i32.const 1)))
  )
  ;; Catenate a list to another
  (func $i32list.cat (param $basePtr i32) (param $newPtr i32)
    (local $newPos i32)(local $newLen i32)
	(local.set $newLen (call $i32list.getCurLen (local.get $newPtr)))
	(local.set $newPos (i32.const 0))
	(loop $move
	  (if (i32.lt_s (local.get $newPos)(local.get $newLen))
		(then
	      (call $i32list.push (local.get $basePtr)(call $i32list.get@ (local.get $newPtr)(local.get $newPos)))
		  (local.set $newPos (i32.add(local.get $newPos)(i32.const 1)))
		  (br $move))
	  )
	)
  )
  ;; Take last element from list and return it
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
  ;; reverse the list in-place
  (func $i32list.reverse (param $lstPtr i32)
	(local $leftPos i32)(local $rightPos i32)(local $temp i32)
	(local.set $leftPos (i32.const 0))
	(local.set $rightPos (call $i32list.getCurLen(local.get $lstPtr)))
	(local.set $rightPos (i32.sub(local.get $rightPos)(i32.const 1)))
	(loop $revLoop
	  (if
		(i32.lt_s (local.get $leftPos)(local.get $rightPos))
		  (then
			;; remember right value
			(local.set $temp (call $i32list.get@ (local.get $lstPtr)(local.get $rightPos)))
			;; put left value into right pos
			(call $i32list.set@ (local.get $lstPtr)(local.get $rightPos)
				(call $i32list.get@ (local.get $lstPtr)(local.get $leftPos)))
			;; put old right value into left pos
			(call $i32list.set@ (local.get $lstPtr)(local.get $leftPos)(local.get $temp))
			(local.set $leftPos (i32.add(local.get $leftPos)(i32.const 1)))
			(local.set $rightPos (i32.sub(local.get $rightPos)(i32.const 1)))
			(br $revLoop)
			)
	  )
	)
  )
     (func $i32list.reverse.test(param $testNum i32)(result i32)
    (local $list i32)
	(local.set $list (call $i32list.mk))
	(call $i32list.reverse (local.get $list))
	(if (call $i32list.getCurLen(local.get $list))
	  (return (i32.const 1))) ;; should have been 0 (false)
	(call $i32list.push (local.get $list) (i32.const 1))
	(call $i32list.reverse (local.get $list))
	(if (i32.ne (call $i32list.get@ (local.get $list) (i32.const 0)) (i32.const 1))
	  (return (i32.const 2)))
	(call $i32list.push (local.get $list) (i32.const 2))  ;; list should now be [1, 2]
	(call $i32list.reverse (local.get $list))      ;; should be [2, 1]
	(if (i32.ne (call $i32list.get@(local.get $list) (i32.const 0)) (i32.const 2))
	  (return (i32.const 3)))
	(if (i32.ne (call $i32list.get@(local.get $list) (i32.const 1)) (i32.const 1))
	  (return (i32.const 4)))
	(call $i32list.push (local.get $list) (i32.const 3))  ;; list now should be [2, 1, 3]
	(call $i32list.reverse (local.get $list))  ;; list now should be [3, 1, 2]
	(if (i32.ne (call $i32list.get@(local.get $list) (i32.const 0)) (i32.const 3))
	  (return (i32.const 3)))
	(if (i32.ne (call $i32list.get@(local.get $list) (i32.const 1)) (i32.const 1))
	  (return (i32.const 4)))
	(if (i32.ne (call $i32list.get@(local.get $list) (i32.const 2)) (i32.const 2))
	  (return (i32.const 4)))
	(return (i32.const 0))  ;; success
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
;;		(if (call $map.is (call $i32list.get@ (local.get $lstPtr)_0))
;;		  (return (call $map.toStr (local.get $lstPtr))))))
	  ))
	(call $str.catByte (local.get $strPtr)(i32.const 91(;[;)))
	(local.set $ipos (i32.const 0))
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (local.set $strTmp (call $toStr (call $i32list.get@ (local.get $lstPtr)(local.get $ipos))))
		  (call $str.catStr (local.get $strPtr)(local.get $strTmp))
		  (call $str.catByte (local.get $strPtr) (i32.const 44(;COMMA;)))
		  (call $str.catsp (local.get $strPtr))
	      (local.set $ipos (i32.add (local.get $ipos)(i32.const 1)))
	      (br $iLoop))))
	(if (local.get $curLength)
	  (then
		(call $str.drop (local.get $strPtr))  ;; extra comma
		(call $str.drop (local.get $strPtr))))  ;; extra final space
;;	(call $str.catByte (local.get $strPtr)(global.get $RSQBRACK)) ;; right bracket
	(call $str.catByte (local.get $strPtr)(i32.const 93(;];))) ;; right bracket
	(local.get $strPtr)
  )
  ;; from www.geeksforgeeks.org/quick-sort
  ;; fixed by using StackOverflow examp by BartoszKP
  (func $i32list.qsort (param $listPtr i32)(param $low i32)(param $high i32)
    (local $pi i32)  ;; partitioning index
	(if (i32.lt_s (local.get $low)(local.get $high))
	  (then
		(local.set $pi (call $i32list.partition (local.get $listPtr)(local.get $low)(local.get $high)))
		(call $i32list.qsort(local.get $listPtr)(local.get $low)(i32.sub (local.get $pi)(i32.const 1)))
		(call $i32list.qsort(local.get $listPtr)(i32.add (local.get $pi)(i32.const 1))(local.get $high))
	  )
	)
  )
  (func $i32list.partition (param $listPtr i32)(param $low i32)(param $high i32)(result i32)
	(local $pivot i32)(local $i i32)(local $j i32);;(local $highMinus1 i32)
	(local.set $pivot (call $i32list.get@ (local.get $listPtr)(local.get $high)))
	(local.set $i (i32.sub (local.get $low)(i32.const 1)))
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
  ;; copies a slice from a list
  (func $i32list.mkslice (param $lstptr i32)(param $offset i32)(param $length i32)(result i32)
	(local $slice i32) 	  ;; to be returned
	(local $ipos i32)	  ;;  pointer to copy data
	(local $lastipos i32) ;; don't go past this offset
	(local.set $slice (call $i32list.mk))  ;; new list to return
	(local.set $ipos (local.get $offset))
	(local.set $lastipos (i32.add (local.get $offset)(local.get $length)))
	(if (i32.gt_u (local.get $lastipos)(call $i32list.getCurLen (local.get $lstptr)))
	  (local.set $lastipos (call $i32list.getCurLen (local.get $lstptr))))
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $lastipos))
		(then
		  (call $i32list.push
		    (local.get $slice)
			  (call $i32list.get@
				(local.get $lstptr)
				(local.get $ipos)
			))
		  (local.set $ipos (i32.add(local.get $ipos)(i32.const 1)))
		  (br $iLoop)
		)))
	(local.get $slice)
  )
  ;; Sum the members of the list
  (func $i32list.sum (param $lstptr i32)(result i32)
    (local $sum i32)(local $ipos i32)(local $len i32)
	(local.set $sum (i32.const 0))
	(local.set $ipos (i32.const 0))
	(local.set $len (call $i32list.getCurLen (local.get $lstptr)))
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $len))
	    (then
		  (local.set $sum
		    (i32.add
			  (local.get $sum)
			  (call $i32list.get@ (local.get $lstptr)(local.get $ipos))))
		  (local.set $ipos (i32.add(local.get $ipos)(i32.const 1)))
		  (br $iLoop)
		)
	  )
	)
	(local.get $sum)
  )

;; i64.m4

  (global $i64L	  	i32	(i32.const 0x4C323369)) ;; 'i64L' type# for i64 lists
   

   
  (global $maxNeg64 i64 (i64.const 0x8000000000000000))
  
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
		;;(global.get $zero)))
		(i32.const 48(;0;))))
  )
  
(func $i64.toStr.test (param $testNum i32)(result i32)
    (local $t i64)
	(local.set $t (i64.const 123456789123456789))
	(i32.eqz
	  (call $str.compare
		(call $i64.toStr (local.get $t)) ;; i64 value
		(call $str.mkdata (global.get $gi64strTest))))
  )
;; i64list.m4
  (func $i64list.toStr (param $lstPtr i32)(result i32)
	(local $strPtr i32)
	(local $strTmp i32)
	(local $curLength i32)
	(local $ipos i32)
	(local.set $strPtr (call $str.mk))
	(local.set $curLength (call $i32list.getCurLen (local.get $lstPtr)))
	;;(call $str.catByte (local.get $strPtr)(global.get $LSQBRACK))
	(call $str.catByte (local.get $strPtr)(i32.const 91(;[;)))
	(local.set $ipos  (i32.const 0) )
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (local.set $strTmp (call $i64.toStr (call $i64list.get@ (local.get $lstPtr)(local.get $ipos))))
		  (call $str.catStr (local.get $strPtr)(local.get $strTmp))
		  (call $str.catByte (local.get $strPtr) (i32.const 44(;COMMA;)))
		  (call $str.catsp (local.get $strPtr))
	      (local.set $ipos (i32.add (local.get $ipos) (i32.const 1) ))
	      (br $iLoop))))
	(if (local.get $curLength)
	  (then
		(call $str.drop (local.get $strPtr))  ;; extra comma
		(call $str.drop (local.get $strPtr))))  ;; extra final space
	;;(call $str.catByte (local.get $strPtr)(global.get $RSQBRACK)) ;; right bracket
	(call $str.catByte (local.get $strPtr)(i32.const 93(;];)))
	(local.get $strPtr)
  )
  (func $i64list.mk (result i32)
	;; returns a memory offset for an i64list pointer:
	;; 		typeNum, curLength, maxLength, dataOffset
	;;		4 bytes	  4 bytes    4 bytes	4 bytes  (same as i32list)
	;; Reserves room for up to 10 64-bit values (80 bytes of potential data)
	(local $lstPtr i32)
	;;(local.set $lstPtr (call $getMem (i32.const 96))) ;; 80 +16
	(local.set $lstPtr (call $mem.get (i32.const 96))) ;; 80 + 16
	(call $setTypeNum (local.get $lstPtr)(global.get $i64L))
	(call $i64list.setCurLen (local.get $lstPtr)  (i32.const 0) )
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
	  (return  (i32.const 1) ))
	(if (i32.ne (call $i64list.getCurLen (local.get $lstPtr)) (i32.const 0) ) ;; should be False
		  (return  (i32.const 2) ))
	 (i32.const 0)  ;; OK
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
		(i32.add (local.get $curLen) (i32.const 1) ))
  )
  (func $i64list.push.test (param $testNum i32)(result i32)
    (local $lstPtr i32)
	(local $temp i64)
	(local.set $lstPtr (call $i64list.mk))
	(call $i64list.push (local.get $lstPtr) (i64.const 3))
	(if (i32.ne
	   (i32.const 1) 
	  (call $i64list.getCurLen (local.get $lstPtr)))
	  (return  (i32.const 1) ))
	(local.set $temp (call $i64list.pop (local.get $lstPtr)))
	(if (i64.ne (i64.const 3) (local.get $temp))
	  (return  (i32.const 2) ))
	(if (i32.ne
	   (i32.const 0) 
	  (call $i32list.getCurLen (local.get $lstPtr)))
	  (return  (i32.const 3) ))
	 (i32.const 0)  ;; passed
  )
     (func $i64list.pop (param $lstPtr i32)(result i64)
    (local $curLen i32)
	(local $lastPos i32)
	(local $popped i64)
    (local.set $curLen (call $i64list.getCurLen(local.get $lstPtr)))
	(if (i32.eqz (local.get $curLen))
	  (call $error2))
	(local.set $lastPos (i32.sub (local.get $curLen) (i32.const 1) ))
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

;;i32matrix.m4
  (global $i32M	  	i32	(i32.const 0x4D323369)) ;; 'i32M' type# for i32 Matices
  (func $i32Mtrx.mk (result i32)
	;; returns a memory offset for an i32matix pointer:
	;; 		typeNum, curLength, maxLength, dataOffset
	(local $lstPtr i32)
	(local.set $lstPtr (call $mem.get (i32.const 20))) 
	;; 4 bytes for type, 12 for the pointer info, 4 for first int32
	(call $setTypeNum (local.get $lstPtr)(global.get $i32M))
	(call $i32list.setCurLen (local.get $lstPtr) (i32.const 0))
	(call $i32list.setMaxLen (local.get $lstPtr) (i32.const 1))
	(call $i32list.setDataOff(local.get $lstPtr)
	(i32.add(local.get $lstPtr) (i32.const 16))) ;; 16 bytes for header info
	(local.get $lstPtr)  ;; return ptr to the new list
  )
  (func $i32Mtrx.addRow (param $matPtr i32)(param $rowPtr i32)
    (call $i32list.push(local.get $matPtr)(local.get $rowPtr))
  )
  (func $i32Mtrx.get@ (param $mtrxPtr i32)(param $row i32)(param $col i32)(result i32)
    (call $i32list.get@ (call $i32list.get@ (local.get $mtrxPtr) (local.get $row))(local.get $col))
  )
  (func $i32Mtrx.toStr (param $matPtr i32)(result i32)
	(local $dstr i32)(local $rowNum i32)(local $numRows i32)
     (call $str.printwlf(call $str.mkdata (global.get $gIni32MtoStr)))
	(local.set $dstr (call $str.mk))  ;; display string
	(local.set $rowNum (i32.const 0))(local.set $numRows (call $i32list.getCurLen (local.get $matPtr)))
	(loop $rowLoop
	  (if (i32.lt_s (local.get $rowNum)(local.get $numRows))
		(then
		  (call $str.catStr(local.get $dstr)(call $i32list.get@(local.get $matPtr)(local.get $rowNum)))
		  (local.set $rowNum (i32.add(local.get $rowNum)(i32.const 1)))
		  (br $rowLoop)
		)
	  )
	)
	(local.get $dstr)
  )


 
 
 
 
 
 
 
 
 
 

(global $strChildren (mut i32) (i32.const 0))
(global $strCd (mut i32) (i32.const 0))	;; 'cd'
(global $strDir (mut i32) (i32.const 0))	;; 'dir'
(global $strFile (mut i32) (i32.const 0))	;; 'file'
(global $strLs (mut i32) (i32.const 0))	;; 'ls'
(global $strName (mut i32) (i32.const 0))	;; 'name'
(global $strParent (mut i32) (i32.const 0));; 'parent'
(global $strSlash (mut i32) (i32.const 0))	;; '/'
(global $strType (mut i32) (i32.const 0))	;; 'type'
(global $strDol (mut i32) (i32.const 0))	;; '$'
(global $pushed (mut i32) (i32.const 0))

(global $curDir (mut i32) (i32.const 0))

(func $mkDir (param $name i32)(param $parent i32)(result i32)
  (local $dir i32)
   (call $str.printwlf(call $str.mkdata (global.get $g$mkDir)))
  (call $printwlf (local.get $name))
  (local.set $dir (call $strMap.mk))
;;  (if (i32.eqz (local.get  $parent))
;;	(local.set $parent (local.get $dir)))  ;; parent of itself
  ;;(call $printwlf (call $map.toStr(local.get $parent)))
  (call $map.set (local.get $dir)(global.get $strParent)(local.get $parent))
  (call $str.printwlf(call $str.mkdata (global.get $gnullparent)))(call $i32.print(local.get $parent))
 (call $printlf)
  (call $map.set
    (local.get $dir)
	(global.get $strType)
	(global.get $strDir))
  (call $map.set
    (local.get $dir)
	(global.get $strName)
	(local.get $name))
  (call $map.set
	  (local.get $dir)
	  (global.get $strChildren)
	  (call $i32list.mk))
  (call $map.set
	  (local.get $dir)
	  (global.get $strParent)
	  (local.get $parent))
  (local.get $dir)
)

(func $initFileSystem (result i32) ;; returns the initialized root directory
  (local $root i32)
  ;;(call $printwlf (local.get $root))
  (global.set $strCd (call $str.mkdata (global.get $gcd)))
  (global.set $strChildren (call $str.mkdata (global.get $gChildren)))
  (global.set $strParent (call $str.mkdata (global.get $gParent)))
  (global.set $strDir (call $str.mkdata (global.get $gDir)))
  (global.set $strFile (call $str.mkdata (global.get $gFile)))
  (global.set $strLs (call $str.mkdata (global.get $gls)))
  (global.set $strName (call $str.mkdata (global.get $gName)))
  (global.set $strSlash (call $str.mkdata (global.get $gSlash)))
  (global.set $strType (call $str.mkdata (global.get $gType)))
  (global.set $strDol (call $str.mkdata (global.get $gDol)))
  (global.set $pushed (call $str.mk))
  (local.set $root (call $mkDir (global.get $strSlash) (i32.const 0)))  ;;null parent
  ;;(call $map.set(local.get $root)(global.get $strParent)(local.get $root)) ;; it's own parent
  (local.get $root)
)

(func $fileSystemToStr (param $root i32)(result i32)
   ;; strMap's toStr won't work because of circular references
  (local $strPtr i32)(local $parent i32)
  (local.set $strPtr (call $str.mk))
   (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr1)))
  (call $str.catStr (local.get $strPtr)(global.get $strType))
    (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr2)))
 (call $str.catByte (local.get $strPtr) (i32.const 58(;:;)))
    (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr3)))
 (call $str.catStr (local.get $strPtr) (call $map.get(local.get $root)(global.get $strType)))
   (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr4)))
  (call $str.catByte (local.get $strPtr) (i32.const 10(;LF;)))
   (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr5)))
  (call $str.catStr (local.get $strPtr)(global.get $strName))
   (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr6)))
  (call $str.catStr (local.get $strPtr) (call $map.get(local.get $root)(global.get $strName)))
   (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr7)))
  (call $str.catByte (local.get $strPtr) (i32.const 10(;LF;)))
   (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr8)))
  (call $str.catStr (local.get $strPtr)(global.get $strParent))
  (call $str.catByte (local.get $strPtr) (i32.const 58(;:;)))
 (call $str.printwlf(call $str.mkdata (global.get $ggettingparent)))
  (local.set $parent (call $map.get (local.get $root)(global.get $strParent)))
 (call $str.printwlf(call $str.mkdata (global.get $ggotparent))) (call $i32.print(local.get $parent))
  (if (i32.eqz (local.get $parent))
	(call $str.catStr (local.get $strPtr)(global.get $strSlash))
  (else
	(call $str.catStr (local.get $strPtr)(call $map.get (local.get $parent)(global.get $strName)))
  ))
  ;;(call $str.catStr (local.get $strPtr)(call $i32.toStr(call $map.get (local.get $strParent) (global.get $strName))))
    (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostr9)))
  (call $str.catByte (local.get $strPtr) (i32.const 10(;LF;)))
  ;;(call $printwlf(local.get $strPtr))
  (call $str.catStr (local.get $strPtr)(global.get $strChildren))
    (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostra)))
  (call $str.catByte (local.get $strPtr) (i32.const 58(;:;)))
  ;;(call $printwlf (call $map.get(local.get $root)(global.get $strChildren)))
    (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostrb)))
  (call $str.catStr (local.get $strPtr) (call $i32list.toStr(call $map.get(local.get $root)(global.get $strChildren))))
    (call $str.printwlf(call $str.mkdata (global.get $gfilesystemtostrc)))
 (call $str.catByte (local.get $strPtr) (i32.const 10(;LF;)))
  (local.get $strPtr)
)
(func $cdCommand (param $root i32)(param $line i32)
  (local $cdName i32)
   (call $str.printwlf(call $str.mkdata (global.get $gcdCommand)))
  (local.set $cdName
	(call $str.mkslice
	  (local.get $line) (i32.const 5) (i32.sub (call $str.getByteLen(local.get $line)) (i32.const 5))))
  (if (call $str.compare
		(local.get $cdName)
		(call $map.get (local.get $root)(global.get $strName)))
	(then  (call $str.printwlf(call $str.mkdata (global.get $galready)))
		return))
)
(;;
(func $childrenToStr (param $childList i32)(result i32)
  (local $child i32)(local $numChildren i32)(local $childNum i32)(local $strPtr i32)
  (local.set $strPtr (call $str.mk))
  (local.set $numChildren (call $i32list.getCurLen))
  (local.set $childNum (i32.const 0))
  (loop $childLoop
	(if (i32.lt_s (local.get $childNum)(local.get $numChildren))
	  (then
		(call $str.catStr (local.get $strPtr)
	      (call $i32.toStr (call $i32list.get@(local.get $childList)(local.get $childNum))))
		(br $childLoop)
	  )
	)
  )
  (local.get $strPtr)
)
;;)
(func $dirCommand (param $root i32)(param $line i32)
  (local $dirName i32)(local $newDir i32)(local $rchildren i32)
   (call $str.printwlf(call $str.mkdata (global.get $gdirCommand)))
  (local.set $dirName
	(call $str.mkslice (local.get $line) (i32.const 4) 
		(i32.sub (call $str.getByteLen(local.get $line)) (i32.const 4))))
  ;;(call $i32.print (call $str.getByteLen(local.get $line)))(call $printlf)
  ;;(call $i32.print (i32.sub (call $str.getByteLen(local.get $line)) _4))(call $printlf)
  ;;_testString(`gdirCommand:', `dir name:')
  ;;(call $i32.print(call $str.getByteLen (local.get $dirName)))(call $printlf)
  ;;(call $str.printwlf (local.get $dirName))
  ;;(call $printwlf (call $fileSystemToStr(local.get $root)))
  (local.set $newDir (call $mkDir (local.get $dirName)(local.get $root)))
   (call $str.printwlf(call $str.mkdata (global.get $gAddingDir)))
  (call $printwlf (call $fileSystemToStr(local.get $newDir)))
  (local.set $rchildren (call $map.get (local.get $root)(global.get $strChildren)))
   (call $str.printwlf(call $str.mkdata (global.get $gshowchildren)))
  ;;(call $printwlf (local.get $rchildren))
  ;;(call $printwlf (call $i32list.toStr (local.get $rchildren)))
  (call  $i32list.push (local.get $rchildren)(local.get $newDir))
   (call $str.printwlf(call $str.mkdata (global.get $gPushedChildren)))
  ;;(call $printwlf (call $i32list.toStr (local.get $rchildren)))
   (call $str.printwlf(call $str.mkdata (global.get $gAddedDir)))
  ;;(call $printwlf (call $fileSystemToStr(local.get $root)))
)
(func $lsCommand (param $root i32)(param $line i32)
  (local $dirName i32)(local $lineTerm i32)
   (call $str.printwlf(call $str.mkdata (global.get $glsCommand)))
  (loop $lineLoop
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $printwlf (local.get $line))
	(if (i32.eq (i32.const 36(;DOLLAR;)) (call $str.getByte(local.get $line) (i32.const 0)))
	  (then 
	     (global.set $pushed (local.get $line))
		 return))
	;;(call $i32.print (call $str.find (local.get $line)(global.get $strDir)))
	(if (i32.eqz (call $str.find (local.get $line)(global.get $strDir)))
	  (then
	     (call $str.printwlf(call $str.mkdata (global.get $gfoundir)))
		(call $dirCommand(local.get $root)(local.get $line))
		 (call $str.printwlf(call $str.mkdata (global.get $gpastDirCommand)))
	   (return)
	  )
	(else
		 (call $str.printwlf(call $str.mkdata (global.get $ghandling)))))
	(br $lineLoop)
  )
)	
(func $parseLine (param $root i32)(param $line i32)
   (call $str.printwlf(call $str.mkdata (global.get $ginparseline)))
  (call $printwlf(local.get $line))
  (if (call $str.startsAt (local.get $line)(global.get $strCd) (i32.const 0))
	(then (call $cdCommand(local.get $root)(local.get $line))))
  (if (call $str.startsAt (local.get $line)(global.get $strLs) (i32.const 0))
	(then (call $lsCommand (local.get $root)(local.get $line))))
  (if (call $str.startsAt (local.get $line)(global.get $strDir) (i32.const 0))
	(then (call $dirCommand (local.get $root)(local.get $line))))
)

(func $Day07a (export "_Day07a")
  (local $line i32)(local $lineTerm i32)
  (local $root i32) ;; root of directory structue
  (local.set $root (call $initFileSystem))
   (call $str.printwlf(call $str.mkdata (global.get $grootvalue)))(call $printwlf (call $i32.toStr (local.get $root)))
  (call $printwlf (call $fileSystemToStr(local.get $root)))
  (local.set $line (call $str.mk))  ;; reused in $lineLoop
  (loop $lineLoop
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $printwlf (local.get $line))
	(call $parseLine (local.get $root)(local.get $line))
	(call $i32.print (local.get $lineTerm))(call $printlf)
	(if (i32.ne (local.get $lineTerm) (i32.const 0x80000000))
	  (br $lineLoop))
  )
)
;; moduleTail.m4
   
;; ready to undivert
  (data (i32.const 100) "AAA\00") (global $gAAA i32 (i32.const 100))
  (data (i32.const 104) "-2,147,483,648\00") (global $gMaxNegAsChars i32 (i32.const 104))
  (global $gFirstTestOffset i32 (i32.const 4))
  (data (i32.const 107) "something wrong in $reclaimMem\00") (global $reclaimMem i32 (i32.const 107))
  (data (i32.const 138) "Mem Reclaimed: \00") (global $gMemReclaimed: i32 (i32.const 138))
  (data (i32.const 154) "Mem Reclamations: \00") (global $gMemReclamations: i32 (i32.const 154))
  (data (i32.const 173) "Mem used:\00") (global $gMemUsedMsg: i32 (i32.const 173))
  (data (i32.const 183) "Max mem used: \00") (global $gMaxUsedMsg: i32 (i32.const 183))
  (data (i32.const 198) "curMemused:\00") (global $curMemUsed: i32 (i32.const 198))
  (data (i32.const 210) "Type error. Expected:\00") (global $gExpectedType i32 (i32.const 210))
  (data (i32.const 232) "Found:\00") (global $gFound: i32 (i32.const 232))
  (data (i32.const 239) "Bounds Error!\00") (global $gBoundsError i32 (i32.const 239))
  (data (i32.const 253) "ABCDEF\00") (global $gABCDEF i32 (i32.const 253))
  (data (i32.const 260) "AAAZZZ\00") (global $gAAAZZZ i32 (i32.const 260))
  (data (i32.const 267) "FEDCBA\00") (global $gFEDCBA i32 (i32.const 267))
  (data (i32.const 274) "aaa\00") (global $gaaa i32 (i32.const 274))
  (data (i32.const 278) "[]\00") (global $gDblBrack i32 (i32.const 278))
  (data (i32.const 281) "[[]]\00") (global $gDblDblBrack i32 (i32.const 281))
  (data (i32.const 286) "123\00") (global $g123text i32 (i32.const 286))
  (data (i32.const 290) "\00") (global $gEmptyString i32 (i32.const 290))
  (data (i32.const 291) "Unable to print:\00") (global $gUnableToPrint: i32 (i32.const 291))
  (data (i32.const 308) "AbCDbE\00") (global $gAbCDbE i32 (i32.const 308))
  (data (i32.const 315) "AbCDbbE\00") (global $gAbCDbbE i32 (i32.const 315))
  (data (i32.const 323) "ABCdef\00") (global $gABCdef i32 (i32.const 323))
  (data (i32.const 330) "map\00") (global $gmap i32 (i32.const 330))
  (data (i32.const 334) "-2147483648\00") (global $gMaxNegAsString i32 (i32.const 334))
  (data (i32.const 346) "i32L\00") (global $gi32L i32 (i32.const 346))
  (data (i32.const 351) "i64L\00") (global $gi64L i32 (i32.const 351))
  (data (i32.const 356) "-9,223,372,036,854,775,808\00") (global $gMaxNeg64AsString i32 (i32.const 356))
  (data (i32.const 359) "123456789123456789\00") (global $gi64strTest i32 (i32.const 359))
  (data (i32.const 378) "in $i32Mtrx.toStr\00") (global $gIni32MtoStr i32 (i32.const 378))
  (data (i32.const 396) "Children\00") (global $gChildren i32 (i32.const 396))
  (data (i32.const 405) "Parent\00") (global $gParent i32 (i32.const 405))
  (data (i32.const 412) "$ cd \00") (global $gcd i32 (i32.const 412))
  (data (i32.const 418) "dir\00") (global $gDir i32 (i32.const 418))
  (data (i32.const 422) "File\00") (global $gFile i32 (i32.const 422))
  (data (i32.const 427) "$ ls\00") (global $gls i32 (i32.const 427))
  (data (i32.const 432) "Name\00") (global $gName i32 (i32.const 432))
  (data (i32.const 437) "/\00") (global $gSlash i32 (i32.const 437))
  (data (i32.const 439) "Type\00") (global $gType i32 (i32.const 439))
  (data (i32.const 444) "$\00") (global $gDol i32 (i32.const 444))
  (data (i32.const 446) "in $mkDir\00") (global $g$mkDir i32 (i32.const 446))
  (data (i32.const 456) "here is the parent just set in $mkDir:\00") (global $gnullparent i32 (i32.const 456))
  (data (i32.const 495) "in $fileSystemToStr\00") (global $gfilesystemtostr1 i32 (i32.const 495))
  (data (i32.const 515) "in $fileSystemToStr\00") (global $gfilesystemtostr2 i32 (i32.const 515))
  (data (i32.const 535) "in $fileSystemToStr\00") (global $gfilesystemtostr3 i32 (i32.const 535))
  (data (i32.const 555) "in $fileSystemToStr\00") (global $gfilesystemtostr4 i32 (i32.const 555))
  (data (i32.const 575) "in $fileSystemToStr\00") (global $gfilesystemtostr5 i32 (i32.const 575))
  (data (i32.const 595) "in $fileSystemToStr6\00") (global $gfilesystemtostr6 i32 (i32.const 595))
  (data (i32.const 616) "in $fileSystemToStr7\00") (global $gfilesystemtostr7 i32 (i32.const 616))
  (data (i32.const 637) "in $fileSystemToStr8\00") (global $gfilesystemtostr8 i32 (i32.const 637))
  (data (i32.const 658) "about to get parent name\00") (global $ggettingparent i32 (i32.const 658))
  (data (i32.const 683) "got parent\00") (global $ggotparent i32 (i32.const 683))
  (data (i32.const 694) "in $fileSystemToStr9\00") (global $gfilesystemtostr9 i32 (i32.const 694))
  (data (i32.const 715) "in $fileSystemToStra\00") (global $gfilesystemtostra i32 (i32.const 715))
  (data (i32.const 736) "in $fileSystemToStrb\00") (global $gfilesystemtostrb i32 (i32.const 736))
  (data (i32.const 757) "in $fileSystemToStrc\00") (global $gfilesystemtostrc i32 (i32.const 757))
  (data (i32.const 778) "in $cdCommand\00") (global $gcdCommand i32 (i32.const 778))
  (data (i32.const 792) "cd already there!\00") (global $galready i32 (i32.const 792))
  (data (i32.const 810) "in $dirCommand\00") (global $gdirCommand i32 (i32.const 810))
  (data (i32.const 825) "$dirCommand adding new dir\00") (global $gAddingDir i32 (i32.const 825))
  (data (i32.const 852) "here are roots rchildren\00") (global $gshowchildren i32 (i32.const 852))
  (data (i32.const 877) "just pushed $newDir onto $rchildren\00") (global $gPushedChildren i32 (i32.const 877))
  (data (i32.const 913) "new children\00") (global $gAddedDir i32 (i32.const 913))
  (data (i32.const 926) "in $lsCommand\00") (global $glsCommand i32 (i32.const 926))
  (data (i32.const 940) "ls found dir\00") (global $gfoundir i32 (i32.const 940))
  (data (i32.const 953) "Past Dir command!\00") (global $gpastDirCommand i32 (i32.const 953))
  (data (i32.const 971) "ls handling line\00") (global $ghandling i32 (i32.const 971))
  (data (i32.const 988) "in parseLine\00") (global $ginparseline i32 (i32.const 988))
  (data (i32.const 1001) "Root value:\00") (global $grootvalue i32 (i32.const 1001))
  (data (i32.const 1013) "ZZZ\00") (global $gZZZ i32 (i32.const 1013))

;; undiverted
 (global $curMemUsed (mut i32)(i32.const 1017))
 (global $maxMemUsed (mut i32)(i32.const 1017))
 (global $tableLength i32 (i32.const 31))
  (table 31 funcref)
  (elem (i32.const 0)
    (;0;) $str.compare
    (;1;) $str.toStr
    (;2;) $i32.compare
    (;3;) $i32.toStr
    (;4;) $typeNum.toStr.test
    (;5;) $str.catByte.test
    (;6;) $str.catChar.test
    (;7;) $str.cat2Strings.test
    (;8;) $str.Rev.test
    (;9;) $str.getByte.test
    (;10;) $str.getLastByte.test
    (;11;) $str.catChar.test
    (;12;) $str.compare.test
    (;13;) $str.find.test
    (;14;) $str.mkdata.test
    (;15;) $str.mkslice.test
    (;16;) $str.stripLeading.test
    (;17;) $toStr.test
    (;18;) $str.drop.test
    (;19;) $str.toI32.test
    (;20;) $str.Csplit.test
    (;21;) $str.index.test
    (;22;) $map.test
    (;23;) $i32list.mk.test
    (;24;) $i32list.set@.test
    (;25;) $i32list.pop.test
    (;26;) $i32list.push.test
    (;27;) $i32list.reverse.test
    (;28;) $i64.toStr.test
    (;29;) $i64list.mk.test
    (;30;) $i64list.push.test
  )
) ;; end of module


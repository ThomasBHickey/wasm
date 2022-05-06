;;adventDay00.m4
;;defines.m4
;; Character defines
;; Global defines
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

              
        (table 6 funcref)
  (elem (i32.const 0)
    (;0;) $str.compare
    (;1;) $str.toStr
    (;2;) $i32.compare
    (;3;) $i32.toStr
    (;4;) $str.catByte.test
    (;5;) $str.catStr.test
  )

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
			(local.get $testOff)
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
  (func $Test.printTest
    (call $byte.print (i32.const 84(;T;)))
	(call $byte.print (i32.const 101(;e;)))
	(call $byte.print (i32.const 115(;s;)))
	(call $byte.print (i32.const 116(;t;)))
	(call $printsp)
  )
  (func $Test.showOK (param $testnum i32)
    (call $Test.printTest)
	(call $i32.print (local.get $testnum))
	(call $printsp)
	(call $byte.print (i32.const 79(;O;)))
	(call $byte.print (i32.const 75(;K;)))
	(call $printlf)
  )
  (func $Test.showFailed (param $testnum i32)(param $testResult i32)
    (call $Test.printTest)
	(call $i32.print (local.get $testnum))
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
	(i32.div_u (i32.const 1)(i32.const 0))
  )
  (func $error2
    (local $t i32)
    (local.set $t (i32.div_u (i32.const 1)(i32.const 0)))
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
  (memory 4096)
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
;;	(loop $tloop          ;; a little tight loop!
;;	  (br $tloop))
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
	  (local.get $byte))
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
	;;(call $str.print(local.get $memsp))(call $printlf)
	(call $str.catByte (local.get $sp) (i32.const 65(;A;)))
	(call $str.catByte (local.get $sp) (i32.const 66(;B;)))
	(call $str.catByte (local.get $sp) (i32.const 67(;C;)))
	(call $str.catByte (local.get $sp) (i32.const 68(;D;)))
	(call $str.catByte (local.get $sp) (i32.const 69(;E;)))
	(call $str.catByte (local.get $sp) (i32.const 70(;F;)))
	;;(call $str.print(local.get $sp))(call $printlf)
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
			;;(local.set $s2pos (i32.add (local.get $s2pos)(i32.const 1)))
			(br $bloop))))		
  )
  ;; already defined in defines.m4: _gdatadef(`gAAA',`AAA')
   
  (func $str.catStr.test (param $testNum i32)(result i32)
    (local $AAA i32)(local $ZZZ i32)(local $aaa i32)
	;;(call $mem.dump)
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
  (func $str.compare (type $keyCompSig)
	(local $s1ptr i32)(local $s2ptr i32)
	(local $s2len i32)(local $cpos i32)
	(local.set $s1ptr (local.get 0))
	(local.set $s2ptr (local.get 1))
	(local.set $s2len (call $str.getByteLen (local.get $s2ptr)))
	;;(call $str.print (local.get $s1ptr))(call $printlf)
	;;(call $str.print (local.get $s2ptr))(call $printlf)
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
;;	(local.set $map (call $i32Map.mk))
;;	(if
;;	  (i32.eqz (call $str.compare
;;		(call $toStr (local.get $map))
;;		(call $str.mkdata (global.get $gDblBrace))))
;;	  (return (i32.const 3)))
;;	(local.set $list (call $i32list.mk))
;;	(call $i32list.push (local.get $list)(call $strMap.mk))
;;	(if
;;	  (i32.eqz (call $str.compare
;;		(call $toStr (local.get $list))
;;		(call $str.mkdata (global.get $gBrackedBrace))))
;;	  (return (i32.const 4)))
	(return (i32.const 0))
  )
  (func $str.catsp (param $strPtr i32)
	(call $str.catByte (local.get $strPtr)(i32.const 32(;SP;))))
  (func $str.catlf (param $strPtr i32)
    (call $str.catByte (local.get $strPtr)(i32.const 10(;LF;))))
  (func $str.drop(param $strPtr i32)
	(if (i32.eqz (call $str.getByteLen (local.get $strPtr)))
	  (return))
	(call $str.setByteLen
	  (local.get $strPtr)
	  (i32.sub
		(call $str.getByteLen (local.get $strPtr)) (i32.const 1)))
  )

;; io.m4
  (global $readIOVsOff0 i32 (i32.const 0))
  (global $readIOVsOff4 	i32 (i32.const 4))
  (global $readBuffOff 		i32 (i32.const 8))
  (global $readBuffLen 		i32 (i32.const 4))
  (global $writeIOVsOff0 	i32 (i32.const 16))
  (global $writeIOVsOff4 	i32 (i32.const 20))
  (global $writeBuffOff 	i32 (i32.const 24))
  (global $writeBufLen 		i32 (i32.const 4))
  (global $bytesRead		i32 (i32.const 4))
  (global $bytesWritten		(mut i32) (i32.const 0))
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
    (call $byte.hexprint (i32.shr_u (local.get $n)(i32.const 16)))
    (call $byte.hexprint (i32.shr_u (local.get $n)(i32.const 8)))
    (call $byte.hexprint (local.get $n))
  )
  (func $byte.hexprint (param $byte i32)
    (local.set $byte (i32.and (local.get $byte)(i32.const 0xff)))
	(call $nibble.hexprint (i32.shr_u (local.get $byte)(i32.const 4)))
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
		  (return (global.get $maxNeg))
		)
	  )
	)
	(local.get $strPtr)
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
   
    (func $ptr.toStr (param $ptr i32)(result i32)
    (local $type i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(local.set $type (call $getTypeNum (local.get $ptr)))
	(if (i32.eq (local.get $type)(global.get $BStr))
	  (then
		;;(call $str.catByte (local.get $strPtr)(global.get $DBLQUOTE))
		(call $str.catByte (local.get $strPtr)(i32.const 34(;";)))
		(call $str.catStr (local.get $strPtr)(local.get $ptr))
		(call $str.catByte (local.get $strPtr)(i32.const 34(;";)))
		(return (local.get $strPtr))))
	(if (i32.eq (local.get $type)(global.get $i32L))
	  (call $str.catStr 
		  (local.get $strPtr)
		  (call $i32list.toStr (local.get $ptr)))
	  (return (local.get $strPtr)))
;;	(if (i32.eq (local.get $type)(global.get $i64L))
;;	  (call $str.catStr 
;;		  (local.get $strPtr)
;;		  (call $i64list.toStr (local.get $ptr)))
;;	  (return (local.get $strPtr)))
;;	(if (i32.eq (local.get $type)(global.get $Map))
;;	  (call $str.catStr (local.get $strPtr)(call $map.toStr (local.get $ptr)))
;;	  (return (local.get $strPtr)))
	(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gUnableToPrint:)))
	(local.get $strPtr)
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
  ;; i32Lists
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
;;	(if
;;	  (local.get $curLength)  ;; at least one item
;;	  (then
;;		(if (call $map.is (call $i32list.get@ (local.get $lstPtr)(i32.const 0)))
;;		  (return (call $map.toStr (local.get $lstPtr))))))
	;;(call $str.catByte (local.get $strPtr)(global.get $LSQBRACK))
	(call $str.catByte (local.get $strPtr)(i32.const 91(;[;)))
	(local.set $ipos (i32.const 0))
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (local.set $strTmp (call $toStr (call $i32list.get@ (local.get $lstPtr)(local.get $ipos))))
		  (call $str.catStr (local.get $strPtr)(local.get $strTmp))
		  (call $str.catByte (local.get $strPtr)(i32.const 44(;COMMA;)))
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

;; adventDay01main.m4
  (func $main (export "_start")
	(local $byte i32)(local $strPtr1 i32)(local $strPtr2 i32)(local $ctr i32)
	(call $io.initialize)
	(call $byte.print (i32.const 62(;>;)))
	(local.set $strPtr1 (call $str.read))
	(call $i32.print(local.get $strPtr1))
	(call $str.printwlf (local.get $strPtr1))
	(call $byte.print (i32.const 62(;>;)))
	(local.set $strPtr2 (call $str.read))
	(call $i32.print(local.get $strPtr2))(call $printlf)
	(local.set $ctr (i32.const 2))
	(call $mem.dump)
	(call $str.catStr(local.get $strPtr1) (local.get $strPtr2))
	(call $mem.dump)
	(call $str.printwlf (local.get $strPtr1))
	(call $str.catStr(local.get $strPtr1) (local.get $strPtr2))	
	(call $mem.dump)
	(call $str.printwlf (local.get $strPtr1))
  )

;; moduleTail.m4
   
  (data (i32.const 100) "AAA\00") (global $gAAA i32 (i32.const 100))
  (global $gFirstTestOffset i32 (i32.const 4))
  (global $tableLength  i32 (i32.const 6))
  (data (i32.const 104) "something wrong in $reclaimMem\00") (global $reclaimMem i32 (i32.const 104))
  (data (i32.const 135) "Mem Reclaimed: \00") (global $gMemReclaimed: i32 (i32.const 135))
  (data (i32.const 151) "Mem Reclamations: \00") (global $gMemReclamations: i32 (i32.const 151))
  (data (i32.const 170) "Mem used:\00") (global $gMemUsedMsg: i32 (i32.const 170))
  (data (i32.const 180) "Max mem used: \00") (global $gMaxUsedMsg: i32 (i32.const 180))
  (data (i32.const 195) "curMemused:\00") (global $curMemUsed: i32 (i32.const 195))
  (data (i32.const 207) "Type error. Expected:\00") (global $gExpectedType i32 (i32.const 207))
  (data (i32.const 229) "Found:\00") (global $gFound: i32 (i32.const 229))
  (data (i32.const 236) "Bounds Error!\00") (global $gBoundsError i32 (i32.const 236))
  (data (i32.const 250) "ABCDEF\00") (global $gABCDEF i32 (i32.const 250))
  (data (i32.const 257) "AAAZZZ\00") (global $gAAAZZZ i32 (i32.const 257))
  (data (i32.const 264) "[]\00") (global $gDblBrack i32 (i32.const 264))
  (data (i32.const 267) "[[]]\00") (global $gDblDblBrack i32 (i32.const 267))
  (data (i32.const 272) "Unable to print:\00") (global $gUnableToPrint: i32 (i32.const 272))
  (data (i32.const 289) "-2147483648\00") (global $gMaxNegAsString i32 (i32.const 289))
  (data (i32.const 301) "gi32L\00") (global $gi32L i32 (i32.const 301))
  (data (i32.const 307) "ZZZ\00") (global $gZZZ i32 (i32.const 307))

 (global $curMemUsed (mut i32)(i32.const 311))
 (global $maxMemUsed (mut i32)(i32.const 311))
) ;; end of module

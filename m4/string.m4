;; string.m4
  (global $BStr		i32	(i32.const 0x72745342))	;; 'BStr' type# for byte strings
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
	;;(call $byte.print _CHAR(`<'))
	(local.set $strPtr (call $mem.get (i32.const 20)))
	(call $setTypeNum (local.get $strPtr) (global.get $BStr))
	(call $str.setByteLen (local.get $strPtr) (i32.const 0))
	(call $str.setMaxLen (local.get $strPtr)(i32.const 4))
	(call $str.setDataOff (local.get $strPtr)(i32.add(local.get $strPtr)(i32.const 16)))
	(local.get $strPtr)
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
  _gdef(`gABCDEF', `ABCDEF')
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
  _gdef(`gAAA',`AAA')
  _gdef(`gAAAZZZ',`AAAZZZ')
  (func $str.catStr.test (param $testNum i32)(result i32)
    (local $AAA i32)(local $ZZZ i32)(local $aaa i32)
	(local.set $AAA (call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ (call $str.mkdata (global.get $gZZZ)))
	(local.set $aaa (call $str.mk))
	(call $str.catStr (local.get $aaa)(local.get $AAA))
	(call $str.catStr (local.get $aaa)(local.get $ZZZ))
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
	(if (i32.ne (call $str.getByteLen (local.get $s1ptr))(local.get $s2len))
	  (return (i32.const 0)))
	(local.set $cpos (i32.const 0))
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $s2len))
		(then
			(if (i32.ne (call $str.getByte (local.get $s1ptr)(local.get $cpos))
						(call $str.getByte (local.get $s2ptr)(local.get $cpos)))
			  ;;(return (i32.const 0)))
			  (return _0))  ;; Failure
			;;(local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
			_incrLocal($cpos)
			(br $cloop)
		)))
	_1  ;; Success
	;;(i32.const 1) ;; success
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
  (func $str.mkdata (param $dataOffset i32) (result i32)
	(local $curByte i32)(local $strPtr i32)
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
	     (local.set $cpos (i32.add (local.get $cpos)(i32.const 1)))
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
		  _incrLocal($dataOffset)
		  (br $bLoop)))
	)
  )
  (func $strdata.printwlf (param $global i32)
    (call $printwlf (call $str.mkdata (local.get $global)))
  )

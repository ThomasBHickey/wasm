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
	(call $str.setByteLen (local.get $strPtr) _0)
	(call $str.setMaxLen (local.get $strPtr) _4)
	(call $str.setDataOff (local.get $strPtr)(i32.add(local.get $strPtr)_16))
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
	  (i32.add (local.get $byteLen) _1))
  )
  _gnts(`gABCDEF', `ABCDEF')
  (func $str.catByte.test (param $testNum i32)(result i32)
	(local $sp i32)
	(local $memsp i32)
	(local.set $sp
	  (call $str.mk))
	(local.set $memsp 
	  (call $str.mkdata
		(global.get $gABCDEF)))
	;;(call $str.print(local.get $memsp))(call $printlf)
	(call $str.catByte (local.get $sp) _CHAR(`A'))
	(call $str.catByte (local.get $sp) _CHAR(`B'))
	(call $str.catByte (local.get $sp) _CHAR(`C'))
	(call $str.catByte (local.get $sp) _CHAR(`D'))
	(call $str.catByte (local.get $sp) _CHAR(`E'))
	(call $str.catByte (local.get $sp) _CHAR(`F'))
	;;(call $str.print(local.get $sp))(call $printlf)
	(if
	  (i32.eqz
		(call $str.compare
		  (local.get $sp)
		  (local.get $memsp)))
	  (then
		(return _1)))  ;; Failure
	;; Test UTF-8 compliance a bit
	_0 ;; success
  )
  (func $str.catStr (param $s1Ptr i32)(param $s2Ptr i32)
	;; Modify s1 by concatenating another string to it
	(local $s2pos i32)
	(local $s2ByteLen i32)
	(local.set $s2pos _0)
	(local.set $s2ByteLen (call $str.getByteLen (local.get $s2Ptr)))
	(loop $bloop
		(if (i32.lt_u (local.get $s2pos)(local.get $s2ByteLen))
		  (then
			(call $str.catByte(local.get $s1Ptr)
			  (call $str.getByte (local.get $s2Ptr)(local.get $s2pos)))
			_incrLocal($s2pos)
			;;(local.set $s2pos (i32.add (local.get $s2pos)(i32.const 1)))
			(br $bloop))))		
  )
  ;; already defined in defines.m4: _gnts(`gAAA',`AAA')
  _gnts(`gAAAZZZ',`AAAZZZ')
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
	  (return _0))
	(local.set $cpos _0)
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $s2len))
		(then
			(if (i32.ne (call $str.getByte (local.get $s1ptr)(local.get $cpos))
						(call $str.getByte (local.get $s2ptr)(local.get $cpos)))
			  (return _0))  ;; Failure
			_incrLocal($cpos)
			(br $cloop)
		)))
	_1  ;; Success
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
	(local.set $newMaxLen (i32.mul (local.get $maxLen) _2))
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
	  (else _0)
	)
  )
  (func $str.getByteLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr) _4))
  )
  (func $str.setByteLen(param $strPtr i32)(param $newLen i32)
	(i32.store (i32.add (local.get $strPtr) _4) (local.get $newLen))
  )
  (func $str.getMaxLen (param $strPtr i32)(result i32)
	(i32.load (i32.add (local.get $strPtr) _8))
  )
  (func $str.setMaxLen(param $strPtr i32)(param $newMaxLen i32)
	(i32.store (i32.add(local.get $strPtr) _8)(local.get $newMaxLen))
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
		  (local.set $dataOffset (i32.add (local.get $dataOffset) _1))
		  (br $bLoop)))
	)
	(local.get $strPtr)
  )
  (func $str.print (param $strPtr i32)
	(local $curLength i32)
	(local $dataOffset i32)  ;; offset to string data
	(local $cpos i32)  ;; steps through character positions
	(local.set $curLength (call $str.getByteLen(local.get $strPtr)))
	(local.set $cpos _0)
	(local.set $dataOffset (call $str.getDataOff (local.get $strPtr)))
	(loop $cLoop
	  (if (i32.lt_u (local.get $cpos)(local.get $curLength))
		(then
		 (i32.load8_u (i32.add (local.get $dataOffset)(local.get $cpos)))
		 (call $byte.print)   
	     (local.set $cpos (i32.add (local.get $cpos) _1))
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
  _gnts(`gDblBrack',`[]')
  _gnts(`gDblDblBrack', `[[]]')
  (func $toStr.test (param $testNum i32)(result i32)
	(local $list i32)
	(local $map i32)
	(local.set $list (call $i32list.mk))
	;;_testString(`emptylist:', `empty list:')
	;;(call $str.print (call $toStr (local.get $list)))
	;;(return _0)
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
	(call $str.catByte (local.get $strPtr)_SP))
  (func $str.catlf (param $strPtr i32)
    (call $str.catByte (local.get $strPtr)_LF))
  (func $str.drop(param $strPtr i32)
	(if (i32.eqz (call $str.getByteLen (local.get $strPtr)))
	  (return))
	(call $str.setByteLen
	  (local.get $strPtr)
	  (i32.sub
		(call $str.getByteLen (local.get $strPtr)) _1))
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
		  (if (i32.eq (local.get $byte) _SP)
		    (then   ;; skip over blanks!
			  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
			  (br $sloop)))  
		  (local.set $temp (i32.sub (local.get $byte)_CHAR(`0')))
		  (local.set $retv (i32.add (local.get $temp) (i32.mul(local.get $retv)(i32.const 10))))
		  (local.set $bpos (i32.add (local.get $bpos)(i32.const 1)))
		  (br $sloop))))
	(local.get $retv)
  )
  _gnts(`g123text',`123')
  _gnts(`gEmptyString', `')
  (func $str.toI32.test (param $testNum i32)(result i32)
    (if
	  (i32.ne (i32.const 123) (call $str.toI32 (call $toStr(global.get $g123text))))
	  (return (i32.const 1)))
	(if
	  (i32.ne (i32.const 0) (call $str.toI32 (call $toStr(global.get $gEmptyString))))
	  (return (i32.const 2)))
    (i32.const 0)
  )
  _gnts(`gUnableToPrint:', `Unable to print:')
  (func $ptr.toStr (param $ptr i32)(result i32)
    (local $type i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(local.set $type (call $getTypeNum (local.get $ptr)))
	;;_testString(`t1',`in $ptr.toStr')(call $printsp)
	;;(call $str.print(call $typeNum.toStr (local.get $type)))(call $printlf)
	(if (i32.eq (local.get $type)(global.get $BStr))
	  (then
		(call $str.catByte (local.get $strPtr)_CHAR(`"'))
		(call $str.catStr (local.get $strPtr)(local.get $ptr))
		(call $str.catByte (local.get $strPtr)_CHAR(`"'))
		(return (local.get $strPtr))))
	(if (i32.eq (local.get $type)(global.get $i32L))
	 (then
	  (call $str.catStr 
		  (local.get $strPtr)
		  (call $i32list.toStr (local.get $ptr)))
	  (return (local.get $strPtr))))
;; i64L and Map
;;	(if (i32.eq (local.get $type)(global.get $i64L))
;;    (then
;;	  (call $str.catStr 
;;		  (local.get $strPtr)
;;		  (call $i64list.toStr (local.get $ptr)))
;;	  (return (local.get $strPtr))))
;;	(if (i32.eq (local.get $type)(global.get $Map))
;;	  (call $str.catStr (local.get $strPtr)(call $map.toStr (local.get $ptr)))
;;	  (return (local.get $strPtr)))
	(call $i32.hexprint(local.get $type))
	(call $str.printwlf (call $typeNum.toStr(local.get $type)))
	(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gUnableToPrint:)))
	(call $i32.toStr (local.get $ptr))
  )

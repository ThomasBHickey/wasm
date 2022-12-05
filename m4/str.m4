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
  _addToTable($str.catByte.test)
  (func $str.catByte.test (param $testNum i32)(result i32)
	(local $sp i32)
	(local $memsp i32)
	(local.set $sp
	  (call $str.mk))
	(local.set $memsp 
	  (call $str.mkdata
		(global.get $gABCDEF)))
	(call $str.catByte (local.get $sp) _CHAR(`A'))
	(call $str.catByte (local.get $sp) _CHAR(`B'))
	(call $str.catByte (local.get $sp) _CHAR(`C'))
	(call $str.catByte (local.get $sp) _CHAR(`D'))
	(call $str.catByte (local.get $sp) _CHAR(`E'))
	(call $str.catByte (local.get $sp) _CHAR(`F'))
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
			(br $bloop))))		
  )
  _gnts(`gAAAZZZ',`AAAZZZ')
  _addToTable($str.catChar.test)
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
	(local.set $bpos _0)
	(loop $bloop1
	  (if (i32.lt_u (local.get $bpos)(local.get $byteLen1))
		(then
		  (call $str.catByte (local.get $s1+2Ptr)
			(call $str.getByte (local.get $s1Ptr)(local.get $bpos)))
		  _incrLocal($bpos)
		  (br $bloop1))))
	(local.set $bpos _0)
	(loop $bloop2
	  (if (i32.lt_u (local.get $bpos)(local.get $byteLen2))
		(then
		  (call $str.catByte (local.get $s1+2Ptr)
			(call $str.getByte (local.get $s2Ptr)(local.get $bpos)))
		  _incrLocal($bpos)
		  (br $bloop2))))
	(local.get $s1+2Ptr)
  )
  _addToTable($str.cat2Strings.test)
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
	(local.set $cpos _0)
	(local.set $curLen (call $str.getByteLen(local.get $strPtr)))
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $curLen))
		(then
			(local.set $curChar
			  (call $str.getByte (local.get $strPtr)(local.get $cpos)))
			(call $str.LcatChar (local.get $revStrPtr)(local.get $curChar))
			_incrLocal($cpos)
		)
	  )
	  (br_if $cloop (i32.lt_u (local.get $cpos)(local.get $curLen)))
	)
	(local.get $revStrPtr)
  )
  _gnts(`gFEDCBA',`FEDCBA')
  _addToTable($str.Rev.test)
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
	  (else _0)
	)
  )
  _addToTable($str.getByte.test)
  (func $str.getByte.test (param $testNum i32)(result i32)
    (local $ts i32)(local $lastCharPos i32)
	(local.set $ts (call $str.mkdata (global.get $gABCDEF)))
	(local.set $lastCharPos
		(i32.sub (call $str.getByteLen (local.get $ts)) _1))
	(if (i32.ne (call $str.getByte (local.get $ts)_0)
				(i32.const 65)) ;; 'A'
		(return _1))
	(if (i32.ne (call $str.getByte (local.get $ts)(local.get $lastCharPos))
				(i32.const 70)) ;; 'F'
		(return _1))
	_0  ;; success
  )
  (func $str.getLastByte (param $strPtr i32)(result i32)
	(if (i32.eqz (call $str.getByteLen (local.get $strPtr)))
	  (return _0))
	(call $str.getByte
	  (local.get $strPtr)
	  (i32.sub (call $str.getByteLen (local.get $strPtr))_1))
  )
  _addToTable($str.getLastByte.test)
  (func $str.getLastByte.test (param $testNum i32)(result i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(if (call $str.getLastByte (local.get $strPtr))
	  (return _1))  ;; should have been zero
	(local.set $strPtr (call $str.mkdata (global.get $gABCDEF)))
	(if
	  (i32.ne
		(call $str.getLastByte (local.get $strPtr))
		(i32.const 70)) ;; F
	  (return (i32.const 2))  ;; failure
	)
	_0 ;; Success
  )
  (func $str.catChar (param $strPtr i32)(param $C i32)
    (local $byte i32)
	(if (i32.eqz (local.get $C))  ;; handle null
	  (return (call $str.catByte (local.get $strPtr) _0)))
	(loop $byteLoop
	  (local.set $byte ;;assigned to high order byte in $C
		(i32.shr_u
		  (i32.and
			(i32.const 0xFF000000)  ;; mask and shift right
			  (local.get $C))
		  (i32.const 24)))
	  (if (local.get $byte)  ;; ignore leading null's
		(call $str.catByte (local.get $strPtr)(local.get $byte)))
		(local.set $C (i32.shl (local.get $C) _8))  ;; move to next byte
	  (if (local.get $C)  ;; More?
	   (br $byteLoop)))
  )
  _i32GlobalConst(`UTF8-1', 0x24)		;; U+0024	Dollar sign
  _i32GlobalConst(`UTF8-2', 0xC2A2)		;; U+00A2	Cent sign
  _i32GlobalConst(`UTF8-3', 0xE0A4B9)	;; U+0939	Devanagari Letter Ha
  _i32GlobalConst(`UTF8-4', 0xF0908D88)	;; U+10348	Gothic Letter Hwair
  _addToTable($str.catChar.test)
  (func $str.catChar.test (param $testNum i32)(result i32)
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-1))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-2))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-3))
	(call $str.catChar (local.get $strPtr) (global.get $UTF8-4))
	(if (i32.ne (call $str.getByteLen (local.get $strPtr))(i32.const 10))
	  (return _1))
	_0
  )
  (func $str.compare (type $keyCompSig)
	(local $s1ptr i32)(local $s2ptr i32)
	(local $s2len i32)(local $cpos i32)
	(local.set $s1ptr (local.get 0))
	(local.set $s2ptr (local.get 1))
	(local.set $s2len (call $str.getByteLen (local.get $s2ptr)))
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
  _addToTable($str.compare.test)
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
		(return _1))  ;; same string, should have matched
	(if (i32.eqz (call $str.compare (local.get $spAAA)(local.get $spAAA2)))
		(return (i32.const 2)))  ;; same contents, should have matched
	(if (call $str.compare (local.get $spAAA)(local.get $spZZZ))
		(return _3))  ;; should not have matched!
	_0 ;; success
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
  (func $str.find (param $string i32)(param $pat i32)(result i32)
    ;; returns position where found, otherwise -1
	(local $cpos i32)(local $lastPos i32)
	(local.set $lastPos (i32.sub (call $str.getByteLen (local.get $string))
								(call $str.getByteLen(local.get $pat))))
	(local.set $cpos _0)
	(loop $cloop
	  (if (i32.le_s (local.get $cpos) (local.get $lastPos))
		(then
		  (if (call $str.startsAt (local.get $string)(local.get $pat)(local.get $cpos))
			(then (local.get $cpos) return))
		  (local.set $cpos (i32.add (local.get $cpos) _1))
		  (br $cloop))))
	(i32.const -1)
  )
  _gnts(`gaaa',`aaa')
  _addToTable($str.find.test)
  (func $str.find.test (param $testNum i32) (result i32)
	(local $AAAZZZ i32)(local $AAA i32)(local $ZZZ i32)(local $aaa i32)
	(local.set $AAAZZZ 	(call $str.mkdata (global.get $gAAAZZZ)))
	(local.set $AAA 	(call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ		(call $str.mkdata (global.get $gZZZ)))
	(local.set $aaa		(call $str.mkdata (global.get $gaaa)))
	(if (i32.ne _0 (call $str.find (local.get $AAAZZZ)(local.get $AAA)))
		(return _1))
	(if (i32.ne _3 (call $str.find (local.get $AAAZZZ)(local.get $ZZZ)))
		(return _2))
	(if (i32.ne (i32.const -1) (call $str.find (local.get $AAAZZZ)(local.get $aaa)))
		(return _3))
	(if (i32.ne (i32.const -1) (call $str.find (local.get $AAA)(local.get $AAAZZZ)))
		(return _4))
	_0
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
			(i32.load8_u (i32.sub (i32.add (local.get $dataOff)(local.get $cpos)) _1)))
		(local.set $cpos (i32.sub (local.get $cpos) _1))
		(br_if $cloop (i32.gt_s (local.get $cpos) _0))
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
		  (local.set $dataOffset (i32.add (local.get $dataOffset) _1))
		  (br $bLoop)))
	)
	(local.get $strPtr)
  )
  _addToTable($str.mkdata.test)
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
		  _incrLocal($bpos)
		  (br $bLoop)
		)))
	(local.get $slice)
  )
  _addToTable($str.mkslice.test)
  (func $str.mkslice.test (param $testNum i32)(result i32)
	(local $AAAZZZ i32)(local $AAA i32)(local $ZZZ i32)
	(local $slice i32)
	(local.set $AAAZZZ (call $str.mkdata (global.get $gAAAZZZ)))
	(local.set $AAA (call $str.mkdata (global.get $gAAA)))
	(local.set $ZZZ (call $str.mkdata (global.get $gZZZ)))
	(local.set $slice
	  (call $str.mkslice
		(local.get $AAAZZZ)
		_0
		_3))
	(if (i32.eqz
		  (call $str.compare (local.get $AAA)(local.get $slice)))
	  (then
		(return _1)))
	(local.set $slice
	  (call $str.mkslice
		(local.get $AAAZZZ)
		_3
		_3))
	(if (i32.eqz
		  (call $str.compare (local.get $ZZZ)(local.get $slice)))
	  (return (i32.const 2)))
	(return _0)
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
  (func $str.startsAt (param $str i32)(param $pat i32)(param $startPos i32)(result i32)
	(local $patLen i32)(local $patPos i32)(local $cPos i32)
	(local.set $patLen (call $str.getByteLen(local.get $pat)))
	(if (i32.gt_u (i32.add (local.get $patLen)(local.get $startPos))
					(call $str.getByteLen (local.get $str)))
		(then (return _0)))
	(local.set $patPos _0)
	(local.set $cPos (local.get $startPos))
	(loop $cloop
	  (if (i32.lt_u (local.get $patPos)(local.get $patLen))
		(then
		  (if (i32.eq (call $str.getByte (local.get $pat)(local.get $patPos))
						(call $str.getByte (local.get $str)(local.get $cPos)))
			(then
			  _incrLocal($patPos)
			  _incrLocal($cPos)
			  (br $cloop))))))
	(i32.eq (local.get $patPos)(local.get $patLen))  ;; matched whole pat?
  )
  (func $str.stripLeading (param $strPtr i32)(param $charToStrip i32)(result i32)
	;; Return a new string without any leading $charToStrip's
	(local $spos i32)(local $curLen i32)(local $stripped i32)
	(local.set $spos _0)
	(loop $strip ;; $str.getByte returns Null if $spos goes out of bounds
		(if (i32.eq (local.get $charToStrip)
			(call $str.getByte (local.get $strPtr)(local.get $spos)))
		  (then
			(local.set $spos (i32.add (local.get $spos)_1))
			(br $strip)
		  )))
	(local.set $curLen (call $str.getByteLen(local.get $strPtr)))
	(local.set $stripped (call $str.mk))
	(loop $copy
		(if (i32.lt_u (local.get $spos)(local.get $curLen))
		  (then
		    (call $str.catByte (local.get $stripped)
				(call $str.getByte(local.get $strPtr)(local.get $spos)))
			_incrLocal($spos)
			(br $copy))))
	(local.get $stripped)
  )
  _addToTable($str.stripLeading.test)
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
		  _incrLocal($dataOffset)
		  (br $bLoop)))
	)
  )
  (func $strdata.printwlf (param $global i32)
    (call $printwlf (call $str.mkdata (local.get $global)))
  )
  (func $toStr (param $ptr i32)(result i32)
    (local $strPtr i32)
	(if (i32.eq (local.get $ptr) _maxNeg)
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
  _gnts(`gDblBrack',`[]')
  _gnts(`gDblDblBrack', `[[]]')
  _addToTable($toStr.test)
  (func $toStr.test (param $testNum i32)(result i32)
	(local $list i32)
	(local $map i32)
	(local.set $list (call $i32list.mk))
	(if
	  (i32.eqz (call $str.compare
		(call $toStr (local.get $list))
		(call $str.mkdata (global.get $gDblBrack))))
	  (return _1))
	(call $i32list.push (local.get $list)(call $i32list.mk))
	(if
	  (i32.eqz (call $str.compare
		(call $toStr (local.get $list))
		(call $str.mkdata (global.get $gDblDblBrack))))
	  (return (i32.const 2)))
	(return _0)
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
  _addToTable($str.drop.test)
  (func $str.drop.test (param $testNum i32)(result i32)
    (local $strptr i32)
	(local.set $strptr (call $str.mk))
	(call $str.catByte (local.get $strptr)(i32.const 65))
	(call $str.catByte (local.get $strptr)(i32.const 66))
	(if (i32.ne (call $str.getLastByte(local.get $strptr))(i32.const 66))
	  (return _1))
	(call $str.drop(local.get $strptr))
	(if (i32.ne (call $str.getLastByte(local.get $strptr))(i32.const 65))
	  (return (i32.const 2)))
	(call $str.drop (local.get $strptr))
	(if (i32.eqz (call $str.getByteLen (local.get $strptr)))
	  (return _0))  ;; OK
	(return _3)	
  )
  ;; Needs error checking!
  (func $str.toI32 (param $strPtr i32)(result i32)
	(local $bpos i32)
	(local $sByteLen i32)
	(local $retv i32)
	(local $temp i32)
	(local $byte i32)
	(local.set $bpos _0)
	(local.set $retv _0)
	(local.set $sByteLen (call $str.getByteLen (local.get $strPtr)))
	(loop $sloop
	  (if (i32.lt_u (local.get $bpos) (local.get $sByteLen))
		(then
		  (local.set $byte (call $str.getByte (local.get $strPtr)(local.get $bpos)))
		  (if (i32.eq (local.get $byte) _SP)
		    (then   ;; skip over blanks!
			  (local.set $bpos (i32.add (local.get $bpos) _1))
			  (br $sloop)))  
		  (local.set $temp (i32.sub (local.get $byte) _CHAR(`0')))
		  (local.set $retv (i32.add (local.get $temp) (i32.mul(local.get $retv)(i32.const 10))))
		  (local.set $bpos (i32.add (local.get $bpos) _1))
		  (br $sloop))))
	(local.get $retv)
  )
  _gnts(`g123text',`123')
  _gnts(`gEmptyString', `')
  _addToTable($str.toI32.test)
  (func $str.toI32.test (param $testNum i32)(result i32)
    (if
	  (i32.ne (i32.const 123) (call $str.toI32 (call $toStr(global.get $g123text))))
	  (return _1))
	(if
	  (i32.ne _0 (call $str.toI32 (call $toStr(global.get $gEmptyString))))
	  (return (i32.const 2)))
    _0
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
	(local.set $bpos _0)
	(local.set $strLen (call $str.getByteLen (local.get $toSplit)))
	(local.set $inSplit _0)  ;; last character was not the split char
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
		  (local.set $bpos (i32.add (local.get $bpos)_1))
		  (br $bloop)
		)
	  )
	)
	(if (call $str.getByteLen (local.get $strCum))
	  (call $i32list.push (local.get $splitList)(local.get $strCum)))
	(local.get $splitList)
  )
  _gnts(`gAbCDbE',`AbCDbE')
  _gnts(`gAbCDbbE',`AbCDbbE')
  _addToTable($str.Csplit.test)
  (func $str.Csplit.test (param $testNum i32)(result i32)
	;; The split character is not part of the split pieces
	(local $AbCDbE i32)(local $AbCDbbE i32)(local $listPtr i32)(local $strptr0 i32)
	(local.set $AbCDbE (call $str.mkdata (global.get $gAbCDbE)))
	(local.set $AbCDbbE (call $str.mkdata (global.get $gAbCDbbE)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 98)))  ;; 'b'
	;;(call $printwlf (local.get $listPtr))
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr)) _3)
	  (return _1))
	  ;;(call $print (local.get $listPtr)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 69)))  ;; 'E'
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr)) _1)
	  (return (i32.const 2)))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbE)(i32.const 122)))  ;; 'z'
	(local.set $strptr0 (call $i32list.get@ (local.get $listPtr) _0))
	(if (i32.eqz 
		  (call $str.compare
			(call $i32list.get@ (local.get $listPtr) _0)
			(local.get $AbCDbE)))
	  (return _3))
	(local.set $listPtr (call $str.Csplit (local.get $AbCDbbE)(i32.const 98))) ;; split on'b'
	;; test to make sure multiple split characters are treated as a single split
	(if (i32.ne (call $i32list.getCurLen (local.get $listPtr)) _3)
	  (return _4)
	  ;;(call $printwlf (local.get $listPtr))
	  )
	_0 ;; success
  )
  (func $str.index (param $strPtr i32)(param $ichar i32)(result i32)
	;; looks for $ichar in the string passed.  Returns position, or _maxNeg if not found
	(local $cpos i32)(local $strLen i32)
	(local.set $cpos _0)
	(local.set $strLen (call $str.getByteLen (local.get $strPtr)))
	(loop $cLoop
	  (if (i32.lt_u (local.get $cpos)(local.get $strLen))
	    (then
		  (if (i32.eq (call $str.getByte (local.get $strPtr)(local.get $cpos))(local.get $ichar))
			(return (local.get $cpos)))
		  _incrLocal($cpos)
		  (br $cLoop)
		)
	  )
	)
	_maxNeg
  )
  _gnts(`gABCdef',`ABCdef')
  (func $str.index.test (param $testNum i32)(result i32)
    (local $testString i32)
	(local.set $testString (call $str.mkdata(global.get $gABCdef)))
    ;; test for first char
	(if (i32.ne (call $str.index (local.get $testString) _CHAR(`A')) _0)
	  (return _1))
	;; test for last char
	(if (i32.ne (call $str.index (local.get $testString) _CHAR(`f')) _5)
	  (return _1))
	;; test for missing char
	(if (i32.ne (call $str.index (local.get $testString) _CHAR(`Z')) _maxNeg)
	  (return _1))
	_0 ;; success
  )
  _addToTable($str.index.test)


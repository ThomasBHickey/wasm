;; i64list.m4
  (func $i64list.toStr (param $lstPtr i32)(result i32)
	(local $strPtr i32)
	(local $strTmp i32)
	(local $curLength i32)
	(local $ipos i32)
	(local.set $strPtr (call $str.mk))
	(local.set $curLength (call $i32list.getCurLen (local.get $lstPtr)))
	;;(call $str.catByte (local.get $strPtr)(global.get $LSQBRACK))
	(call $str.catByte (local.get $strPtr)_CHAR(`['))
	(local.set $ipos  _0 )
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (local.set $strTmp (call $i64.toStr (call $i64list.get@ (local.get $lstPtr)(local.get $ipos))))
		  (call $str.catStr (local.get $strPtr)(local.get $strTmp))
		  (call $str.catByte (local.get $strPtr) _COMMA)
		  (call $str.catsp (local.get $strPtr))
	      (local.set $ipos (i32.add (local.get $ipos) _1 ))
	      (br $iLoop))))
	(if (local.get $curLength)
	  (then
		(call $str.drop (local.get $strPtr))  ;; extra comma
		(call $str.drop (local.get $strPtr))))  ;; extra final space
	;;(call $str.catByte (local.get $strPtr)(global.get $RSQBRACK)) ;; right bracket
	(call $str.catByte (local.get $strPtr)_CHAR(`]'))
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
	(call $i64list.setCurLen (local.get $lstPtr)  _0 )
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
	  (return  _1 ))
	(if (i32.ne (call $i64list.getCurLen (local.get $lstPtr)) _0 ) ;; should be False
		  (return  _2 ))
	 _0  ;; OK
  )
  _addToTable($i64list.mk.test)
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
		(i32.add (local.get $curLen) _1 ))
  )
  (func $i64list.push.test (param $testNum i32)(result i32)
    (local $lstPtr i32)
	(local $temp i64)
	(local.set $lstPtr (call $i64list.mk))
	(call $i64list.push (local.get $lstPtr) (i64.const 3))
	(if (i32.ne
	   _1 
	  (call $i64list.getCurLen (local.get $lstPtr)))
	  (return  _1 ))
	(local.set $temp (call $i64list.pop (local.get $lstPtr)))
	(if (i64.ne (i64.const 3) (local.get $temp))
	  (return  _2 ))
	(if (i32.ne
	   _0 
	  (call $i32list.getCurLen (local.get $lstPtr)))
	  (return  _3 ))
	 _0  ;; passed
  )
  _addToTable($i64list.push.test)
  (func $i64list.pop (param $lstPtr i32)(result i64)
    (local $curLen i32)
	(local $lastPos i32)
	(local $popped i64)
    (local.set $curLen (call $i64list.getCurLen(local.get $lstPtr)))
	(if (i32.eqz (local.get $curLen))
	  (call $error2))
	(local.set $lastPos (i32.sub (local.get $curLen) _1 ))
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

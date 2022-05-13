;; map.m4

  (global $Map		i32 (i32.const 0x4D617020))	;; 'Map ' type# for i32 maps
  _gnts(`gmap', `map')

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
	;;(call $str.catByte (local.get $strPtr)(global.get $LBRACE))
	(call $str.catByte (local.get $strPtr)_CHAR(`{'))
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
			  (call $str.catByte (local.get $strPtr) _COMMA)
			  (call $str.catsp (local.get $strPtr))))
		  (br $mLoop))))
	;;(call $str.catByte (local.get $strPtr)(global.get $RBRACE))
	(call $str.catByte (local.get $strPtr)_CHAR(`}'))
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

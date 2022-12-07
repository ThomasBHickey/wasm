;;i32list.m4
  ;; i32Lists
  ;; an i32list pointer points at
  ;; a typeNum, curLen, maxLen, data pointer, all i32
  ;; the list starts out with a maxLen of 1 (4 bytes)
  ;; which is allocated in the next i32 (20 bytes total)
  (global $i32L	  	i32	(i32.const 0x4C323369)) ;; 'i32L' type# for i32 lists
  _gnts(`gi32L', `i32L')
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
	(call $i32list.setCurLen (local.get $lstPtr) _0)
	(call $i32list.setMaxLen (local.get $lstPtr)_1)
	(call $i32list.setDataOff(local.get $lstPtr)
		(i32.add(local.get $lstPtr) _16)) ;; 16 bytes for header info
	(local.get $lstPtr)  ;; return ptr to the new list
  )
  _addToTable($i32list.mk.test)
  (func $i32list.mk.test (param $testNum i32)(result i32)
	(local $lstPtr i32)
	(local.set $lstPtr (call $i32list.mk))
	(if (i32.ne 
		  (call $getTypeNum (local.get $lstPtr))
		  (global.get $i32L))
	  (return _1))
	(if (call $i32list.getCurLen (local.get $lstPtr)) ;; should be False
		  (return _2))
	_0 ;; OK
  )
  (func $i32list.getCurLen(param $lstPtr i32)(result i32)
	(i32.load (i32.add (local.get $lstPtr)_4))
  )
  (func $i32list.setCurLen (param $lstPtr i32)(param $newLen i32)
	(i32.store (i32.add (local.get $lstPtr)_4)(local.get $newLen))
  )
  (func $i32list.getMaxLen (param $lstPtr i32)(result i32)
    (i32.load (i32.add (local.get $lstPtr)_8))
  )
  (func $i32list.setMaxLen (param $lstPtr i32)(param $newMaxLen i32)
    (i32.store (i32.add (local.get $lstPtr)_8)(local.get $newMaxLen))
  )
  (func $i32list.getDataOff (param $lstPtr i32)(result i32)
    (i32.load (i32.add (local.get $lstPtr)(i32.const 12)))
  )
  (func $i32list.setDataOff (param $lstPtr i32)(param $newDataOff i32)
    (i32.store (i32.add (local.get $lstPtr)(i32.const 12))(local.get $newDataOff))
  )
  _addToTable($i32list.sets.test)
  (func $i32list.sets.test (param $testNum i32) (result i32)
	(local $lstPtr i32)
	(local.set $lstPtr (call $i32list.mk))
	(call $i32list.setCurLen (local.get $lstPtr)(i32.const 37))
	(call $i32list.setMaxLen (local.get $lstPtr)(i32.const 38))
	(call $i32list.setDataOff (local.get $lstPtr)(i32.const 39))
	(if (i32.ne (call $getTypeNum (local.get $lstPtr))(global.get $i32L))
		(return _1))
	(if (i32.ne (call $i32list.getCurLen (local.get $lstPtr))(i32.const 37))
		(return _2))
	(if (i32.ne (call $i32list.getMaxLen (local.get $lstPtr))(i32.const 38))
		(return _3))
	(if (i32.ne (call $i32list.getDataOff (local.get $lstPtr))(i32.const 39))
		(return _4))
	_0
  )
  (func $i32list.extend (param $lstPtr i32)
    ;; double the space available
	(local $maxLen i32) (local $curLen i32) (local $dataOff i32)
	(local $newMaxLen i32)(local $newDataOff i32)
	(local $cpos i32)
	(local.set $curLen (call $i32list.getCurLen (local.get $lstPtr)))
	(local.set $maxLen (call $i32list.getMaxLen (local.get $lstPtr)))
	(local.set $dataOff   (call $i32list.getDataOff (local.get $lstPtr)))
	(local.set $newMaxLen (i32.mul (local.get $maxLen)_2))
	(local.set $newDataOff (call $mem.get (i32.mul (local.get $newMaxLen)_4)))
	(call $i32list.setMaxLen (local.get $lstPtr)(local.get $newMaxLen))
	(call $i32list.setDataOff(local.get $lstPtr)(local.get $newDataOff))
	(memory.copy (local.get $newDataOff)(local.get $dataOff)
				 (i32.mul (local.get $curLen)_4))
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
		  (i32.mul (local.get $pos)_4)))
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
				 (i32.mul _4 (local.get $pos))))
  )
  _addToTable($i32list.set@.test)
  (func $i32list.set@.test (param $testNum i32)(result i32)
    (local $listPtr i32)
	(local.set $listPtr (call $i32list.mk))
	(call $i32list.set@ (local.get $listPtr) _0 (i32.const 33)) ;; should fail
	_0
  )
  (func $i32list.tail (param $lstPtr i32)(result i32)
	(local $curLen i32)
	(local.set $curLen (call $i32list.getCurLen(local.get $lstPtr)))
	(if (i32.eqz (local.get $curLen))  (call $error2))
	(call $i32list.get@
	  (local.get $lstPtr)
	  (i32.sub (local.get $curLen)_1))
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
		(i32.add (local.get $curLen) _1))
  )
  ;; Take last element from list and return it
  (func $i32list.pop (param $lstPtr i32)(result i32)
    (local $curLen i32)
	(local $lastPos i32)
	(local $popped i32)
	(local.set $curLen (call $i32list.getCurLen(local.get $lstPtr)))
	(if (i32.eqz (local.get $curLen))
	  (return (call $error)))
	(local.set $lastPos (i32.sub (local.get $curLen)_1))
	(local.set $popped (call $i32list.get@
	    (local.get $lstPtr)(local.get $lastPos)))
	(call $i32list.setCurLen
	  (local.get $lstPtr)
	  (local.get $lastPos))
	(local.get $popped)
  )
  _addToTable($i32list.pop.test)
  (func $i32list.pop.test (param $testNum i32)(result i32)
	(local $lstPtr i32)
	(local $temp i32)
	(local.set $lstPtr (call $i32list.mk))
	(call $i32list.push (local.get $lstPtr)(i32.const 42))
	(call $i32list.push (local.get $lstPtr)(i32.const 43))
	(local.set $temp (call $i32list.pop (local.get $lstPtr)))
	(if (i32.ne (local.get $temp)(i32.const 43))
	  (return _1))
	(local.set $temp (call $i32list.pop (local.get $lstPtr)))
	(if (i32.ne (local.get $temp)(i32.const 42))
	  (return _2))
	(return (call $i32list.getCurLen (local.get $lstPtr)))
  )
  _addToTable($i32list.push.test)
  (func $i32list.push.test (param $testNum i32)(result i32)
    (local $lstPtr i32)
	(local $temp i32)
	(local.set $lstPtr (call $i32list.mk))
	(call $i32list.push (local.get $lstPtr) _3)
	(if (i32.ne
	  _1
	  (call $i32list.getCurLen (local.get $lstPtr)))
	  (return _1))
	(local.set $temp (call $i32list.pop (local.get $lstPtr)))
	(if (i32.ne _3 (local.get $temp))
	  (return _2))
	(if (i32.ne
	  _0
	  (call $i32list.getCurLen (local.get $lstPtr)))
	  (return _3))
	_0 ;; passed
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
	(call $str.catByte (local.get $strPtr)_CHAR(`['))
	(local.set $ipos _0)
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $curLength))
		(then
		  (local.set $strTmp (call $toStr (call $i32list.get@ (local.get $lstPtr)(local.get $ipos))))
		  (call $str.catStr (local.get $strPtr)(local.get $strTmp))
		  (call $str.catByte (local.get $strPtr) _COMMA)
		  (call $str.catsp (local.get $strPtr))
	      (local.set $ipos (i32.add (local.get $ipos)_1))
	      (br $iLoop))))
	(if (local.get $curLength)
	  (then
		(call $str.drop (local.get $strPtr))  ;; extra comma
		(call $str.drop (local.get $strPtr))))  ;; extra final space
;;	(call $str.catByte (local.get $strPtr)(global.get $RSQBRACK)) ;; right bracket
	(call $str.catByte (local.get $strPtr)_CHAR(`]')) ;; right bracket
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
		  _incrLocal($ipos)
		  (br $iLoop)
		)))
	(local.get $slice)
  )
  ;; Sum the members of the list
  (func $i32list.sum (param $lstptr i32)(result i32)
    (local $sum i32)(local $ipos i32)(local $len i32)
	(local.set $sum _0)
	(local.set $ipos _0)
	(local.set $len (call $i32list.getCurLen (local.get $lstptr)))
	(loop $iLoop
	  (if (i32.lt_u (local.get $ipos)(local.get $len))
	    (then
		  (local.set $sum
		    (i32.add
			  (local.get $sum)
			  (call $i32list.get@ (local.get $lstptr)(local.get $ipos))))
		  _incrLocal($ipos)
		  (br $iLoop)
		)
	  )
	)
	(local.get $sum)
  )

;;Advent2022/Day05.m4
include(`stdHeaders.m4')
(global $fullWinSize i32 _4) 
;; at position passed, checks to see if the first byte repeats within window
;; returns True if finds a dup of first char ($target)
(func $lookForDup (param $stream i32)(param $start i32)(param $len i32)(result i32)
  (local $count i32)(local $pos i32)
  (local $target i32)(local $lastPos i32)
  (local $testByte i32)
  (local.set $target (call $str.getByte (local.get $stream)(local.get $start)))
  _testString(`g$lookForDup', `in $lookForDup')
  (call $byte.print(local.get $target)) _testString(`gtarget',`: target')
  (local.set $pos (local.get $start)) _incrLocal($pos)  ;; first pos to check against $target
  (local.set $lastPos (i32.add (local.get $start)(local.get $len))) _decrLocal($lastPos)
  (loop $checkLoop
    _testString(`g$checkLoop', ` in $checkLoop')
	(call $i32.print(local.get $pos)) _testString(`gposition', `: $pos')
	(call $i32.print(local.get $lastPos)) _testString(`glastPos', `: $lastPos')
	(if (i32.le_s (local.get $pos)(local.get $lastPos))
	  (then
		(local.set $testByte (call $str.getByte(local.get $stream)(local.get $pos)))
		(call $byte.print _SP)(call $byte.print (local.get $testByte))_testString(`gtestByte',`: testByte')
		(if (i32.eq (local.get $target)(local.get $testByte))
		  (return _1))
		_incrLocal($pos)
		(br $checkLoop)
	  )
	)
  )
  (call $i32.print (local.get $pos))(call $printsp)
  _testString(`gtest1',` :pos, $lookForDup returns 0')
  ;;(call $i32.print (local.get $start))
  (return _0)  ;; no dup found
)
;; Check a sliding window against duplicate chars within it
;; Returns Pos of first window without duplicates, or _maxNeg if none found

(func $checkStream (param $stream i32)(param $pos i32)(param $winSize i32)(result i32)
  _testString(`gcheckStream', `in $checkStream')
  (call $i32.print(local.get $pos)) _testString(`gpos',`  $pos')
  (call $i32.print(local.get $winSize)) _testString(`gwinSize', `  :winSize')
  (if (i32.eqz (local.get $winSize))
	(return (local.get $pos)))
  (if (call $lookForDup (local.get $stream)(local.get $pos)(local.get $winSize)) ;; found a dup
    (then
	  _incrLocal($pos)
	  (return (call $checkStream (local.get $stream)(local.get $pos)(global.get $fullWinSize)))
	)
  )
  _incrLocal($pos) _decrLocal($winSize)
  (call $checkStream (local.get $stream)(local.get $pos)(local.get $winSize))
)
	
(func $day06a (export "_Day06a")
  (local $dataStream i32)
  (local.set $dataStream (call $str.read))
  (call $str.printwlf (local.get $dataStream))
  (call $i32.print (call $checkStream (local.get $dataStream) _0 (global.get $fullWinSize)))(call $printlf)
  ;;(call $i32.print (i32.add (global.get $fullWinSize)(call $checkStream (local.get $dataStream) (global.get $fullWinSize))))
  (call $printlf)
)

include(`../moduleTail.m4')

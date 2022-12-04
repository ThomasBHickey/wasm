;;Advent2022/Day02.m4
include(`stdHeaders.m4')
_gnts(`gAX', `A X')
_gnts(`gAY', `A Y')
_gnts(`gAZ', `A Z')
_gnts(`gBX', `B X')
_gnts(`gBY', `B Y')
_gnts(`gBZ', `B Z')
_gnts(`gCX', `C X')
_gnts(`gCY', `C Y')
_gnts(`gCZ', `C Z')

  (func $day02a (export "_Day02a")
	(local $line i32) (local $score i32)
	(local $scoreMap i32)(local $lineTerm i32)
	;; A X 1 3 = 4
	;; A Y 2 6 = 8
	;; A Z 3 0 = 3
	;; B X 1 0 = 1
	;; B Y 2 3 = 5
	;; B Z 3 6 = 9
	;; C X 1 6 = 7
	;; C Y 2 0 = 2
	;; C Z 3 3 = 6
	(local.set $score _0)
	(local.set $line (call $str.mk))
	(local.set $scoreMap (call $strMap.mk))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gAX))(i32.const 4))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gAY))(i32.const 8))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gAZ))(i32.const 3))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gBX))(i32.const 1))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gBY))(i32.const 5))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gBZ))(i32.const 9))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gCX))(i32.const 7))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gCY))(i32.const 2))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gCZ))(i32.const 6))
	(call $printwlf (call $map.toStr (local.get $scoreMap)))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $score (i32.add (local.get $score) (call $map.get (local.get $scoreMap)(local.get $line))))
	  (call $printwlf (call $map.get (local.get $scoreMap)(local.get $line)))
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $printwlf (local.get $score))
  )
  (func $day02b (export "_Day02b")
	(local $line i32) (local $score i32)(local $cols i32)
	(local $scoreMap i32)(local $lineTerm i32)
	;; A X 3 0 = 3
	;; A Y 1 3 = 4
	;; A Z 2 6 = 8
	;; B X 1 0 = 1
	;; B Y 2 3 = 5
	;; B Z 2 6 = 9
	;; C X 2 0 = 2
	;; C Y 3 3 = 6
	;; C Z 1 6 = 7
	(local.set $score _0)
	(local.set $line (call $str.mk))
	(local.set $scoreMap (call $strMap.mk))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gAX))(i32.const 3))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gAY))(i32.const 4))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gAZ))(i32.const 8))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gBX))(i32.const 1))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gBY))(i32.const 5))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gBZ))(i32.const 9))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gCX))(i32.const 2))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gCY))(i32.const 6))
	(call $map.set (local.get $scoreMap)(call $str.mkdata (global.get $gCZ))(i32.const 7))
	(call $printwlf (call $map.toStr (local.get $scoreMap)))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $cols (call $str.Csplit (local.get $line) _SP ))
	  ;;(call $print (local.get $cols))
	  (local.set $score (i32.add (local.get $score) (call $map.get (local.get $scoreMap)(local.get $line))))
	  ;;(call $printwlf (call $map.get (local.get $scoreMap)(local.get $line)))
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $printwlf (local.get $score))
  )
include(`../moduleTail.m4')


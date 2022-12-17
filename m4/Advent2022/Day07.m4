;;Advent2022/Day07.m4
include(`stdHeaders.m4')


_gnts(`gcd', `$ cd ')
_gnts(`ls',  `$ ls')

(func $parseLine (param $line i32)
  (if (call $str.startsAt (local.get $line)(call $str.mkdata (global.get $gcd)) _0)
    _testString(`gfoundcd',`Found cd')
	)
)
(func $day07a (export "_Day07a")
  (local $line i32)(local $lineTerm i32)
  (local.set $line (call $str.mk))
  (loop $lineLoop
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $printwlf (local.get $line))
	(call $parseLine (local.get $line))
	(if (i32.ne (local.get $lineTerm) _maxNeg)
	  (br $lineLoop))
  )
)
include(`../moduleTail.m4')

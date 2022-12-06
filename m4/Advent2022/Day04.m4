;;Advent2022/Day04.m4
include(`stdHeaders.m4')

  (func $makeSet (param $half i32)(result i64)
    (local $set i64) (local $pieces i32)
	(local.set $set (i64.const 0))
	(call $print (local.get $half))(call $printlf)
	(local.set $pieces (call $str.Csplit (local.get $half) _CHAR(`-')))
	(call $print (local.get $pieces))(call $printlf)
	(local.get $set)
  )
  (func $decodePair (param $line i32)
    (local $halves i32)(local $leftSet i64)(local $rightSet i64)
	
	(call $printwlf (local.get $line))
	(local.set $halves (call $str.Csplit (local.get $line) _CHAR(`,')))
	(call $printwlf (local.get $halves))
	(local.set $leftSet (call $makeSet (call $i32list.get@ (local.get $halves) _0)))
	
	(call $i64.print (local.get $leftSet)(call $printlf))
  )
  (func $day04a (export "_Day04a")
    (local $line i32)
	(local.set $line (call $str.read))
	(call $decodePair (local.get $line))
  )
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
include(`../moduleTail.m4')

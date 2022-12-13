;;Advent2022/Day05.m4
include(`stdHeaders.m4')


(func $doSlices (param $line i32)(param $chunkSize i32)
  (local $pos i32)
 

)

(func $day06a (export "_Day06a")
  (local $dataStream i32)
  (local.set $dataStream (call $str.read))
  (call $str.printwlf (local.get $dataStream))
)

include(`../moduleTail.m4')

;;Advent2022/Day07.m4
include(`stdHeaders.m4')


_gnts(`gcd',`$ cd ')
_gnts(`gls', `$ ls')
_gnts(`gSlash',`/')
_gnts(`gDir',`Dir')
_gnts(`gFile',`File')
_gnts(`gType',`Type')
_gnts(`gChildren',`Children')

;; The files/dirs are held as strMaps
;; Each has attributes:
;; 'Name' (name str)
;; 'Type': 'file' or 'dir'
;;  files will have a 'size' attribute (i32)
;;  directories have a 'children' attribute (i32list)
;;     and a 'parent' attribute
;; 
;; To get the size of directory, call getDirSize passing a ptr to the directory
(func $parseLine (param $line i32)
  (if (call $str.startsAt (local.get $line)(call $str.mkdata (global.get $gcd)) _0)
    _testString(`gfoundcd',`Found cd')
	)
)
;; return new directory with 'Name', 'Type' and 'Children' initialized
(func $mkDir )(param $name i32)(result i32)
  (local $dir i32)
  (local.set $dir (call $strMap.mk))
  (call $map.set
	(local.get $dir)
	(call $str.mkdata (global.get $gdir)))
  (call $map.set
	(local.get $dir)
	(local.get $name))
  (call $map.set
	(local.get 
)
  
(global $strChildren i32)
(global $strDir i32)
(global $strSlash i32)
(global $strFile i32)
(global $strType i32)
(global $strCd i32)
(global $strLs i32)
(func $initFileSytem (result i32) ;; returns the initialized root directory
  (local $root i32)
  (local.set $root (call $strMap.mk))
  (global.set $strChildren (call $str.mkdata (global.get $gChildren)))
  (global.set $strName (call $str.mkdata (global.get $gName)))
  (global.set $strDir (call $str.mkdata (global.get $gDir)))
  (global.set $strFile (call $str.mkdata (global.get $gFile)))
  (global.set $strCd (call $str.mkdata (global.get $gcd)))
  (global.set $strLs (call $str.mkdata (global.get $gls)))
  (global.set $strSlash (call $str.mkdata (global.get $gSlash)))
  (global.set $strType (call $str.mkdata (global.get $gType)))
  (call $map.set (local.get $root)(global.get $g/)(call $i32list.mk)) ;; empty list of 
  (local.get $root)
)
(func $day07a (export "_Day07a")
  (local $line i32)(local $lineTerm i32)
  (local $root i32) ;; root of directory structue
  (local.set $root (call $initFileSystem))

  (local.set $line (call $str.mk))  ;; reused in $linkLoop
  (loop $lineLoop
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $printwlf (local.get $line))
	(call $parseLine (local.get $line))
	(if (i32.ne (local.get $lineTerm) _maxNeg)
	  (br $lineLoop))
  )
)
include(`../moduleTail.m4')

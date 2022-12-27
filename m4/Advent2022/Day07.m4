;;Advent2022/Day07.m4
include(`stdHeaders.m4')

_gnts(`gChildren',`Children')
_gnts(`gParent',`Parent')
_gnts(`gcd',`$ cd ')
_gnts(`gDir',`dir')
_gnts(`gFile',`File')
_gnts(`gls', `$ ls')
_gnts(`gName', `Name')
_gnts(`gSlash',`/')
_gnts(`gType',`Type')
_gnts(`gDol', `$')

(global $strChildren (mut i32) _0)
(global $strCd (mut i32) _0)	;; 'cd'
(global $strDir (mut i32) _0)	;; 'dir'
(global $strFile (mut i32) _0)	;; 'file'
(global $strLs (mut i32) _0)	;; 'ls'
(global $strName (mut i32) _0)	;; 'name'
(global $strParent (mut i32) _0);; 'parent'
(global $strSlash (mut i32) _0)	;; '/'
(global $strType (mut i32) _0)	;; 'type'
(global $strDol (mut i32) _0)	;; '$'
(global $pushed (mut i32) _0)

(global $curDir (mut i32) _0)

(func $mkDir (param $name i32)(param $parent i32)(result i32)
  (local $dir i32)
  _testString(`g$mkDir',`in $mkDir')
  (local.set $dir (call $strMap.mk))
  (call $map.set(local.get $dir)(global.get $strParent)  (local.get $parent))
  (call $map.set(local.get $dir)(global.get $strType)	 (global.get $strDir))
  (call $map.set(local.get $dir)(global.get $strName)	 (local.get $name))
  (call $map.set(local.get $dir)(global.get $strChildren)(call $i32list.mk))
  (call $map.set(local.get $dir)(global.get $strParent)  (local.get $parent))
  (local.get $dir)
)

(func $initFileSystem (result i32) ;; returns the initialized root directory
  (local $root i32)
  (global.set $strCd (call $str.mkdata (global.get $gcd)))
  (global.set $strChildren (call $str.mkdata (global.get $gChildren)))
  (global.set $strParent (call $str.mkdata (global.get $gParent)))
  (global.set $strDir (call $str.mkdata (global.get $gDir)))
  (global.set $strFile (call $str.mkdata (global.get $gFile)))
  (global.set $strLs (call $str.mkdata (global.get $gls)))
  (global.set $strName (call $str.mkdata (global.get $gName)))
  (global.set $strSlash (call $str.mkdata (global.get $gSlash)))
  (global.set $strType (call $str.mkdata (global.get $gType)))
  (global.set $strDol (call $str.mkdata (global.get $gDol)))
  (global.set $pushed (call $str.mk))
  (local.set $root (call $mkDir (global.get $strSlash) _0))  ;;null parent
  (local.get $root)
)

(func $fileSystemToStr (param $root i32)(result i32)
   ;; strMap's toStr won't work because of circular references
  (local $strPtr i32)(local $parent i32)
  (local.set $strPtr (call $str.mk))
  (call $str.catStr (local.get $strPtr)(global.get $strType))
 (call $str.catByte (local.get $strPtr) _CHAR(`:'))
 (call $str.catStr (local.get $strPtr) (call $map.get(local.get $root)(global.get $strType)))
  (call $str.catByte (local.get $strPtr) _LF)
  (call $str.catStr (local.get $strPtr)(global.get $strName))
  (call $str.catStr (local.get $strPtr) (call $map.get(local.get $root)(global.get $strName)))
  (call $str.catByte (local.get $strPtr) _LF)
  (call $str.catStr (local.get $strPtr)(global.get $strParent))
  (call $str.catByte (local.get $strPtr) _CHAR(`:'))
  (local.set $parent (call $map.get (local.get $root)(global.get $strParent)))
  (if (i32.eqz (local.get $parent))
	(call $str.catStr (local.get $strPtr)(global.get $strSlash))
  (else
	(call $str.catStr (local.get $strPtr)(call $map.get (local.get $parent)(global.get $strName)))
  ))
  (call $str.catByte (local.get $strPtr) _LF)
  (call $str.catStr (local.get $strPtr)(global.get $strChildren))
  (call $str.catByte (local.get $strPtr) _CHAR(`:'))
  (call $str.catStr (local.get $strPtr)(call $childrenToStr(call $map.get(local.get $root)(global.get $strChildren))))
 (call $str.catByte (local.get $strPtr) _LF)
  (local.get $strPtr)
)
(func $cdCommand (param $root i32)(param $line i32)
  (local $cdName i32)
  _testString(`gcdCommand',`in $cdCommand')
  (local.set $cdName
	(call $str.mkslice
	  (local.get $line) _5 (i32.sub (call $str.getByteLen(local.get $line)) _5)))
  (if (call $str.compare
		(local.get $cdName)
		(call $map.get (local.get $root)(global.get $strName)))
	(then _testString(`galready',`cd already there!')
		return))
)

(func $childrenToStr (param $childList i32)(result i32)
  (local $child i32)(local $numChildren i32)(local $childNum i32)
  (local $strPtr i32)
  (local.set $strPtr (call $str.mk))
  (local.set $numChildren (call $i32list.getCurLen (local.get $childList)))
  (local.set $childNum _0)
  (loop $childLoop
	(if (i32.lt_s (local.get $childNum)(local.get $numChildren))
	  (then
	    (local.set $child (call $i32list.get@(local.get $childList)(local.get $childNum)))
		(call $str.catStr (local.get $strPtr)
	      (call $map.get (local.get $child)(global.get $strName)))
		(call $str.catByte (local.get $strPtr) _SP)
		_incrLocal($childNum)
		(br $childLoop))))
  (local.get $strPtr)
)
(func $dirCommand (param $root i32)(param $line i32)
  (local $dirName i32)(local $newDir i32)(local $rchildren i32)
  _testString(`gdirCommand',`in $dirCommand')
  (local.set $dirName
	(call $str.mkslice (local.get $line) _4 
		(i32.sub (call $str.getByteLen(local.get $line)) _4)))
  (local.set $newDir (call $mkDir (local.get $dirName)(local.get $root)))
  (call $printwlf (call $fileSystemToStr(local.get $newDir)))
  (local.set $rchildren (call $map.get (local.get $root)(global.get $strChildren)))
  (call $printwlf (call $childrenToStr(local.get $rchildren)))
  (call  $i32list.push (local.get $rchildren)(local.get $newDir))
)
(func $lsCommand (param $root i32)(param $line i32)
  (local $dirName i32)(local $lineTerm i32)
  (loop $lineLoop
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $printwlf (local.get $line))
	(if (i32.eq _DOLLAR (call $str.getByte(local.get $line) _0))
	  (then 
	     (global.set $pushed (local.get $line))
		 return))
	(if (i32.eqz (call $str.find (local.get $line)(global.get $strDir)))
	  (then
	    _testString(`gfoundir',`ls found dir')
		(call $dirCommand(local.get $root)(local.get $line))
		_testString(`gpastDirCommand', `Past Dir command!')
	   (return)
	  )
	(else
		_testString(`ghandling',`ls handling line')))
	(if (i32.ne (local.get $lineTerm) _maxNeg)
	  (br $lineLoop))
  )
)	
(func $parseLine (param $root i32)(param $line i32)
  _testString(`ginparseline',`in parseLine')
  (if (call $str.startsAt (local.get $line)(global.get $strCd) _0)
	(then (call $cdCommand(local.get $root)(local.get $line))))
  (if (call $str.startsAt (local.get $line)(global.get $strLs) _0)
	(then (call $lsCommand (local.get $root)(local.get $line))))
  (if (call $str.startsAt (local.get $line)(global.get $strDir) _0)
	(then (call $dirCommand (local.get $root)(local.get $line))))
)
(func $Day07a (export "_Day07a")
  (local $line i32)(local $lineTerm i32)
  (local $root i32) ;; root of directory structue
  (local.set $root (call $initFileSystem))
  (call $printwlf (call $fileSystemToStr(local.get $root)))
  (local.set $line (call $str.mk))  ;; reused in $lineLoop
  (loop $lineLoop
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $printwlf (local.get $line))
	(call $parseLine (local.get $root)(local.get $line))
  (call $printwlf (call $fileSystemToStr(local.get $root)))
	(if (i32.ne (local.get $lineTerm) _maxNeg)
	  (br $lineLoop))
  )
)
include(`../moduleTail.m4')

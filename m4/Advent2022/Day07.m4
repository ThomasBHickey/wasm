;;Advent2022/Day07.m4
include(`stdHeaders.m4')

_gnts(`gChildren',`children')
_gnts(`gParent',`parent')
_gnts(`gcd',`$ cd ')
_gnts(`gDir',`dir')
_gnts(`gFile',`file')
_gnts(`gls', `$ ls')
_gnts(`gName', `name')
_gnts(`gLength', `length')
_gnts(`gSlash',`/')
_gnts(`gType',`type')
_gnts(`gDol', `$')
_gnts(`gSizeEq', `file\2C size=')  ;; 2C=',' work around comma problem
_gnts(`gDotDot', `..')
_gnts(`gLook4',`dir swrgwp')
;;_gnts(`gLook4',`dir XXXXX')

(global $strChildren (mut i32) _0);;'children'
(global $strCd (mut i32) _0)	;; 'cd'
(global $strDir (mut i32) _0)	;; 'dir'
(global $strFile (mut i32) _0)	;; 'file'
(global $strLs (mut i32) _0)	;; 'ls'
(global $strName (mut i32) _0)	;; 'name'
(global $strParent (mut i32) _0);; 'parent'
(global $strLength (mut i32) _0)  ;; 'length'
(global $strSlash (mut i32) _0)	;; '/'
(global $strType (mut i32) _0)	;; 'type'
(global $strDol (mut i32) _0)	;; '$'
(global $strDotDot (mut i32) _0) ;; ..
(global $strSizeEq (mut i32) _0) ;; 'file, size='
(global $strLook4 (mut i32) _0)

(global $curDir (mut i32) _0)

(func $mkDir (param $name i32)(param $parent i32)(result i32)
  (local $dir i32)
  (local.set $dir (call $strMap.mk))
  ;;(call $map.set  (local.get $dir)(global.get $strType)	 (global.get $strDir))
  (call $setType    (local.get $dir)(global.get $strDir))
  (call $setName    (local.get $dir)(local.get $name))
  (call $setChildren(local.get $dir)(call $i32list.mk))
  (call $setParent  (local.get $dir)(local.get $parent))
  (local.get $dir)
)
(func $getType(param $dir i32)(result i32) (call $map.get(local.get $dir)(global.get $strType)))
(func $setType(param $dir i32)(param $type i32)(call $map.set(local.get $dir)(global.get $strType)(local.get $type)))
(func $getName(param $dir i32)(result i32) (call $map.get(local.get $dir)(global.get $strName)))
(func $setName(param $dir i32)(param $name i32)(call $map.set(local.get $dir)(global.get $strName)(local.get $name)))
(func $getChildren(param $dir i32)(result i32) (call $map.get(local.get $dir)(global.get $strChildren)))
(func $setChildren(param $dir i32)(param $children i32)(call $map.set(local.get $dir)(global.get $strChildren)(local.get $children)))
(func $getParent(param $dir i32)(result i32) (call $map.get(local.get $dir)(global.get $strParent)))
(func $setParent(param $dir i32)(param $parent i32)(call $map.set(local.get $dir)(global.get $strParent)(local.get $parent)))
(func $getLength(param $dir i32)(result i32) (call $map.get(local.get $dir)(global.get $strLength)))
(func $setLength(param $dir i32)(param $length i32)(call $map.set(local.get $dir)(global.get $strLength)(local.get $length)))
(func $initFileSystem (result i32) ;; returns the initialized root directory
  (local $root i32)
  (global.set $strCd (call $str.mkdata (global.get $gcd)))
  (global.set $strChildren (call $str.mkdata (global.get $gChildren)))
  (global.set $strParent (call $str.mkdata (global.get $gParent)))
  (global.set $strDir (call $str.mkdata (global.get $gDir)))
  (global.set $strFile (call $str.mkdata (global.get $gFile)))
  (global.set $strLs (call $str.mkdata (global.get $gls)))
  (global.set $strName (call $str.mkdata (global.get $gName)))
  (global.set $strLength (call $str.mkdata (global.get $gLength)))
  (global.set $strSlash (call $str.mkdata (global.get $gSlash)))
  (global.set $strType (call $str.mkdata (global.get $gType)))
  (global.set $strDol (call $str.mkdata (global.get $gDol)))
  (global.set $strSizeEq (call $str.mkdata (global.get $gSizeEq)))
  (global.set $strDotDot (call $str.mkdata (global.get $gDotDot)))
  (global.set $strLook4 (call $str.mkdata (global.get $gLook4)))
  (local.set $root (call $mkDir (global.get $strSlash) _0))  ;;null parent
  (call $setParent(local.get $root)(local.get $root))
  (local.get $root)
)
(func $printIndent(param $lev i32)
  (local $levCount i32)
  (local.set $levCount _0)
  (loop $levLoop
	(if (i32.lt_s (local.get $levCount)(local.get $lev))
	  (then
		(call $printsp)(call $printsp)
		_incrLocal($levCount)
		(br $levLoop))))
  (call $byte.print _CHAR(`-'))
  (call $printsp)
)
(func $parenthesizedSize (param $size i32)
	(call $printsp)
	(call $byte.print _LPAREN)
	(call $str.print(global.get $strSizeEq))
	(call $i32.print(local.get $size))
	(call $byte.print _RPAREN)
	(call $printlf)
)
(func $printElem (param $elem i32)(param $level i32)
  (local $elemType i32)(local $children i32)(local $numChildren i32)(local $childNum i32)
  (call $printIndent (local.get $level))
  (call $str.print (call $getName (local.get $elem)))
  (local.set $elemType (call $getType (local.get $elem)))
  (if (call $str.compare (local.get $elemType)(global.get $strFile))
	(then
	  (call $parenthesizedSize (call $getLength(local.get $elem)))
	  (return)))
  ;; if not a 'file' then it is a directory
  (call $printsp)(call $byte.print _LPAREN)(call $str.print(global.get $strDir))(call $byte.print _RPAREN)
  (call $printlf)
  (local.set $children (call $getChildren(local.get $elem)))
  (local.set $numChildren (call $i32list.getCurLen (local.get $children)))
  _incrLocal($level)
  (local.set $childNum _0)
  (loop $childLoop
	(if (i32.lt_s (local.get $childNum)(local.get $numChildren))
	  (then
		(call $printElem
			(call $i32list.get@(local.get $children)(local.get $childNum))
			(local.get $level))
		_incrLocal($childNum)
		(br $childLoop))))
)
(func $cdCommand (param $curDir i32)(param $line i32)(result i32)
  (local $cdName i32)(local $children i32)(local $child i32)
  (local $numChildren i32)(local $childNum i32)(local $newDir i32)
  (local.set $cdName
	(call $str.mkslice
	  (local.get $line) _5 (i32.sub (call $str.getByteLen(local.get $line)) _5)))
  (if (call $str.compare
		(local.get $cdName)
		(call $getName (local.get $curDir)))
	(then (return (local.get $curDir))))
  (if (call $str.compare
		(local.get $cdName)
		(global.get $strDotDot))
	(then
	  (local.set $newDir (call $getParent (local.get $curDir)))
	  (return (local.get $newDir))))
  (local.set $childNum _0)
  (local.set $children (call $getChildren(local.get $curDir)))
  (local.set $numChildren (call $i32list.getCurLen(local.get $children)))
  (loop $childLoop
    (if (i32.lt_s (local.get $childNum)(local.get $numChildren))
	  (then
	    (local.set $child (call $i32list.get@ (local.get $children)(local.get $childNum)))
		;;(call $byte.print _CHAR(`@'))
		;;(call $str.printwlf (call $getName (local.get $child)(global.get $strName)))
	    (if (call $str.compare (local.get $cdName) (call $getName (local.get $child)))
		(then
			(if (call $str.compare (call $getType(local.get $child))(global.get $strDir))
		    (return (local.get $child)))
		  ))
		_incrLocal($childNum)
		(br $childLoop)
	  )))
  (local.get $curDir)
)
(func $dirCommand (param $curDir i32)(param $line i32)
  (local $dirName i32)(local $newDir i32)(local $rchildren i32)
  (local.set $dirName
	(call $str.mkslice (local.get $line) _4 
		(i32.sub (call $str.getByteLen(local.get $line)) _4)))
  (local.set $newDir (call $mkDir (local.get $dirName)(local.get $curDir)))
  (local.set $rchildren (call $getChildren(local.get $curDir)))
  (call  $i32list.push (local.get $rchildren)(local.get $newDir))
)
(func $lsCommand (param $curDir i32)(param $line i32)  ;; no-op
)
(func $addFile (param $curDir i32)(param $line i32)
  (local $splits i32)(local $fileLength i32)(local $fileName i32)(local $file i32)
  (local.set $splits (call $str.Csplit(local.get $line) _SP))
  (local.set $fileLength (call $str.toI32 (call $i32list.get@(local.get $splits) _0)))
  (local.set $fileName (call $i32list.get@ (local.get $splits) _1))
  (local.set $file (call $strMap.mk))
  (call $setType(local.get $file)(global.get $strFile))
  (call $setName(local.get $file)(local.get $fileName))
  (call $setLength(local.get $file)(local.get $fileLength))
  (call $i32list.push
	(call $getChildren (local.get $curDir))  ;; i32list of children
	(local.get $file))
)
(func $getTotalSize (param $dir i32)(result i32)
  (local $tsize i32)
  (local $children i32)(local $numChildren i32)(local $childNum i32)(local $child i32)
  (if (call $str.compare(call $getType(local.get $dir))(global.get $strFile))
	(return (call $getLength(local.get $dir))))
  (local.set $tsize _0)  ;; Not a file, must be a directory
  (local.set $childNum _0)
  (local.set $children (call $getChildren(local.get $dir)))
  (local.set $numChildren (call $i32list.getCurLen(local.get $children)))
  (loop $childLoop
    (if (i32.lt_s (local.get $childNum)(local.get $numChildren))
	  (then
	    (local.set $child (call $i32list.get@ (local.get $children)(local.get $childNum)))
	    (local.set $tsize (i32.add (local.get $tsize)(call $getTotalSize (local.get $child))))
		_incrLocal($childNum)
		(br $childLoop)
	  )
	)
  )
  (local.get $tsize)
)
(func $Day07a (export "_Day07a")
  (local $line i32)(local $lineTerm i32)
  (local $root i32) ;; root of directory structue
  (local $curDir i32)
  (local.set $root (call $initFileSystem))
  (local.set $curDir (local.get $root))
  (local.set $line (call $str.mk))  ;; string object reused in $lineLoop
  (loop $lineLoop
    ;;(call $str.print (call $getName(local.get $curDir)))(call $printlf)
	;;(call $printElem(local.get $root) _0)
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $byte.print _CHAR(`>'))(call $printwlf (local.get $line))
	(if (call $str.startsAt (local.get $line)(global.get $strLook4) _0)
	  (then
		(call $byte.print _CHAR(`>'))(call $printwlf (local.get $line))
		(call $printElem (local.get $root) _0))
	   )
    (if (call $str.startsAt (local.get $line)(global.get $strCd) _0)
	  (then
		(local.set $curDir (call $cdCommand(local.get $curDir)(local.get $line)))
		(br $lineLoop)))
	(if (call $str.startsAt (local.get $line)(global.get $strLs) _0)
		(then
		  (call $lsCommand (local.get $curDir)(local.get $line))
		  (br $lineLoop)))
	(if (call $str.startsAt (local.get $line)(global.get $strDir) _0)
		(then
		  (call $dirCommand (local.get $curDir)(local.get $line))
		  (br $lineLoop)))
	(call $addFile(local.get $curDir)(local.get $line))
	(if (i32.ne (local.get $lineTerm) _maxNeg)
	  (br $lineLoop))
  )
  (call $printElem(local.get $root) _0)
  (call $i32.print (call $getTotalSize(local.get $root)))(call $printlf)
)
include(`../moduleTail.m4')
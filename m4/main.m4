;; main.m4
  _gdef(`gRead:', `Read:')dnl
  _gdef(`gWrote:', `Wrote:')dnl
  _gdef(`curMemUsed:', `curMemUsed: ')
  (func $main (export "_start")
	(local $byte i32)(local $strPtr1 i32)(local $strPtr2 i32)
	(call $io.initialize)
	(call $strdata.print (global.get $curMemUsed:))
	  (call $i32.print (global.get $curMemUsed))
	  (call $byte.print (_LF))
	(call $strdata.printwlf (global.get $curMemUsed:))
	(call $strdata.print (global.get $curMemUsed:))
	  (call $i32.print (global.get $curMemUsed))
	  (call $byte.print (_LF))
	
	;; (local.set $byte (call $byte.read))
	;; (call $strdata.print (global.get $gRead:))
	;; (call $i32.print (global.get $maxMemUsed))
	;; (call $strdata.print (global.get $gWrote:))
	(call $byte.print _CHAR(`>'))
	(local.set $strPtr1 (call $str.read))
	(call $str.print (local.get $strPtr1))
	(call $byte.print (_LF))
	(call $byte.print _CHAR(`>'))
	(local.set $strPtr2 (call $str.read))
	(call $str.print (local.get $strPtr2))
	(call $byte.print (_LF))
	(call $strdata.print (global.get $curMemUsed:)) (call $i32.print (global.get $curMemUsed))(call $byte.print (_LF))
	(call $str.catStr(local.get $strPtr1)(local.get $strPtr2))
	(call $str.print (local.get $strPtr1))(call $byte.print (_LF))
	(call $strdata.print (global.get $curMemUsed:)) (call $i32.print (global.get $curMemUsed))(call $byte.print (_LF))
	(call $str.print (local.get $strPtr2))
	(call $printwlf (local.get $strPtr1))
	(call $printwlf (call $str.mkdata (global.get $curMemUsed:)))
  )

;; main.m4
  _gdef(`gRead:', `Read:')dnl
  _gdef(`gWrote:', `Wrote:')dnl
  _gdef(`curMemUsed:', `curMemUsed: ')
  (func $showMemory
	(call $strdata.print (global.get $curMemUsed:))
	  (call $i32.print (global.get $curMemUsed))
	  (call $printlf)
  )
  (func $main (export "_start")
	(local $byte i32)(local $strPtr1 i32)(local $strPtr2 i32)(local $ctr i32)
	(call $io.initialize)
	;;(global.set $curMemUsed (call $roundUpTo4 (global.get $curMemUsed)))
	;;(global.set $maxMemUsed (global.get $curMemUsed))
	(call $byte.print _CHAR(`>'))
	(local.set $strPtr1 (call $str.read))
	(call $i32.print(local.get $strPtr1))
	(call $str.printwlf (local.get $strPtr1))
	(call $byte.print _CHAR(`>'))
	(local.set $strPtr2 (call $str.read))
	(call $i32.print(local.get $strPtr2))(call $printlf)
	(local.set $ctr (i32.const 2))
	(call $mem.dump)
	;;(call $strdata.print (global.get $curMemUsed:))
	;; (loop $catloop
	  ;; (if (local.get $ctr)
		;; (then
		  ;; (call $mem.dump)
		  ;; (call $i32.print(local.get $strPtr1))(call $printlf)
		  ;; (call $i32.print(local.get $strPtr2))(call $printlf)
		  ;; (local.set $strPtr2 (call $str.mk))
		  ;; (call $str.catStr(local.get $strPtr2)(local.get $strPtr1))
		  ;; (call $str.catStr(local.get $strPtr2)(local.get $strPtr1)) ;; now 2x string1 in string2
		  ;; (local.set $strPtr1 (call $str.mk))
		  ;; (call $str.catStr(local.get $strPtr1)(local.get $strPtr2)) ;; now 2x last string1 in string1
		  ;; (local.set $ctr (i32.sub (local.get $ctr) (i32.const 1)))
		  ;; (call $i32.print (call $str.getByteLen (local.get $strPtr1)))
		  ;; (call $printlf)
		  ;; (call $str.printwlf (local.get $strPtr1))
		  ;; (br $catloop)
		;; )
	  ;; )
	;;)
	(call $str.catStr(local.get $strPtr1) (local.get $strPtr2))
	(call $str.printwlf (local.get $strPtr1))
	(call $i32.print(global.get $curMemUsed))(call $printlf)
  )

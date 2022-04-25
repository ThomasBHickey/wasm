;; memory.m4
  ;;(global $memChunks i32 (i32.const 1024))
  ;;(memory (global.get $memChunks))
  (memory 4096)
  (export "memory" (memory 0))
  ;;(global $curMemUsed (mut i32)(i32.const 200)) ;; First 100 bytes reserved
  ;;(global $maxMemUsed (mut i32)(i32.const 200)) ;; e..g. I/O buffers in io.m4
  (global $memSize i32 (i32.const 1048576))  ;; 1024*1024
  (global $memReclaimed (mut i32)(i32.const 0))
  (global $memReclamations (mut i32)(i32.const 0))
  
  (func $roundUpTo4 (param $size i32)(result i32)
	(i32.and (i32.add (local.get $size)(i32.const 3))(i32.const 0xfffffff4))
  )
  (func $mem.get (param $size i32)(result i32)
	;; Simple memory allocation done in 4-byte chunks
	;; Should this get cleared first?
	(local $size4 i32)
	(local.set $size4 (call $roundUpTo4 (local.get $size)))  ;; make sure size divisble by 4
	(global.get $curMemUsed) ;; on stack to return
	(global.set $curMemUsed (i32.add (global.get $curMemUsed)(local.get $size4)))
	(if (i32.gt_u (global.get $curMemUsed)(global.get $maxMemUsed))
	  (global.set $maxMemUsed (global.get $curMemUsed)))
  )
  (func $hex.dumpline (param $memPtr i32)
	(local $ctr i32)(local.set $ctr _0)
	_testString(`indumpline',`starting dumpline')
    (call $i32.hexprint(local.get $memPtr))  ;; show where we are in memory
	(loop $byteLoop
	  (call $byte.hexprint (i32.load8_u (i32.add (local.get $ctr)(local.get $memPtr))))
	  _incrLocal($ctr)
	  (if (i32.lt_u (local.get $ctr)(i32.const 16))
		(br $byteLoop)))
	(call $printlf)
 	_testString(`exitingdumpline',`exiting dumpline')
 )
  (func $mem.dump
    (local $memPtr i32)(local $nCols i32)(local $col i32)(local $row i32)(local $byte i32)
	(local.set $nCols (i32.const 100))
	_testString(`mem.dump',`Starting $mem.dump')
	(call $strdata.print (global.get $curMemUsed:))
	  (call $i32.print (global.get $curMemUsed))
	  (call $printlf)
	(local.set $memPtr _0)
	(local.set $row _0)
	(loop $rowLoop
	(call $strdata.print (global.get $curMemUsed:))
	  (call $hex.dumpline (local.get $memPtr))
	  (local.set $memPtr (i32.add (local.get $memPtr)(i32.const 16)))
	  (if (i32.lt_u (local.get $memPtr)(global.get $curMemUsed))
	    (br $rowLoop)))
;;	  (call $i32.print (local.get $memPtr))(call $printsp)
;;	  (local.set $col _0)
;;	  (loop $colLoop
;;	    (local.set $byte (i32.load8_u (local.get $memPtr)))
;;		(call $byte.print (local.get $byte))
;;	    (call $i32.hexprintsup (local.get $byte))
;;		(call $printsp)
;;		_incrLocal($col)
;;		_incrLocal($memPtr)
;;		(if (i32.lt_u (local.get $memPtr)(global.get $curMemUsed))
;;		  (if (i32.lt_u (local.get $col)(local.get $nCols))
;;			(br $colLoop))))
;;	  (call $printlf)  ;; end of row
;;	  (local.set $row (i32.add (local.get $row) _1))
;;	  (if (i32.lt_u (local.get $memPtr)(global.get $curMemUsed))
;;		(br $rowLoop)))
	_testString(`mem.dumpend',`Leaving $mem.dump')
	)

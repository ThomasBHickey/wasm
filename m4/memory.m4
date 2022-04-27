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
	(i32.and (i32.add (local.get $size)(i32.const 3))(i32.const 0xfffffffc))
  )
  (func $mem.get (param $size i32)(result i32)
	;; Simple memory allocation done in 32-bit boundaries
	;; Should this get cleared first?
	;;(call $i32.print (global.get $curMemUsed))(call $printlf)
	(global.set $curMemUsed (call $roundUpTo4 (global.get $curMemUsed)))
	;;(call $i32.print (global.get $curMemUsed))(call $printlf)
	(global.get $curMemUsed) ;; on stack to return
	(global.set $curMemUsed (i32.add (global.get $curMemUsed)(local.get $size)))
	(if (i32.gt_u (global.get $curMemUsed)(global.get $maxMemUsed))
	  (global.set $maxMemUsed (global.get $curMemUsed)))
  )
  (func $reclaimMem (param $newCurMemUsed i32)
  ;; A simple way to reclaim memory
  ;; Resets where new mem is allocated and clears the reclaimed words
  ;; WARNING: It's possible that a string in the remaining memory could
  ;; point to string data in the reclaimed section
    (local $reclaimedBytes i32)
	(local $reclaimedWords i32)
	(local $wordToClear i32)
	(local $oldCurMemUsed i32)
    ;;(return)
	(if (i32.gt_u (local.get $newCurMemUsed)(global.get $curMemUsed))
		(call $error2))
	;; check for i32 word alignment
	(if (i32.and (local.get $newCurMemUsed)(i32.const 3))
	  (call $error3 (i32.const 32)))
	(local.set $oldCurMemUsed (global.get $curMemUsed))
	(if (i32.and (local.get $oldCurMemUsed)(i32.const 3))
	  (call $error3 (i32.const 33)))
	(local.set $reclaimedBytes
	  (i32.sub (global.get $curMemUsed)(local.get $newCurMemUsed)))
	(global.set $memReclaimed
	  (i32.add (global.get $memReclaimed)(local.get $reclaimedBytes)))
	(local.set $wordToClear (local.get $newCurMemUsed))
	(loop $clearLoop
	  (if (i32.lt_u
		(local.get $wordToClear)
		(local.get $oldCurMemUsed))
		(then
		  (i32.store (local.get $wordToClear)(i32.const 0))
		  (local.set $wordToClear (i32.add (local.get $wordToClear)(i32.const 4)))
		  (br $clearLoop))))
	(global.set $curMemUsed (local.get $newCurMemUsed))
	(global.set $memReclamations (i32.add (global.get $memReclamations)(i32.const 1)))
  )
  (func $showMemUsedHelper (param $numBytes i32)(param $msg i32)
    (call $str.print (local.get $msg))
	(call $i32.print (local.get $numBytes))(call $printsp)
	(call $byte.print _LPAREN)
	(call $i32.print
	  (i32.shr_u (local.get $numBytes)(i32.const 10)))
	(call $byte.print _CHAR(`K'))
	(call $byte.print _RPAREN)
	(call $printlf)
  )
  _gdef(`gMemReclaimed:',`Mem Reclaimed: ')
  _gdef(`gMemReclamations:', `Mem Reclamations: ')
  _gdef(`gMaxUsedMsg:', `Max mem used: ')
  (func $showMemUsed 
	(local $memUsedMsg i32)
	(local $maxUsedMsg i32)
	(local $memReclaimedMsg i32)
	(local $memReclamationsMsg i32)
	;;(local $maxUsed i32)
	(local.set $memUsedMsg (call $str.mkdata (global.get $curMemUsed)))
	(local.set $maxUsedMsg (call $str.mkdata (global.get $maxMemUsed)))
	(local.set $memReclaimedMsg (call $str.mkdata (global.get $gMemReclaimed:)))
	(local.set $memReclamationsMsg (call $str.mkdata (global.get $gMemReclamations:)))
	(call $showMemUsedHelper (global.get $curMemUsed)(local.get $memUsedMsg))
	(local.set $bytesUsed
	  (i32.sub
		(global.get $maxMemUsed)
		(global.get $firstFreeMem)))
	(call $showMemUsedHelper (local.get $bytesUsed)(local.get $maxUsedMsg))
	(call $showMemUsedHelper (global.get $memReclaimed)(local.get $memReclaimedMsg))
	(call $showMemUsedHelper (global.get $memReclamations)(local.get $memReclamationsMsg))
  )
  (func $mem.dumpline (param $memPtr i32)
	(local $ctr i32)
	;;_testString(`indumpline',`starting dumpline')
    (call $i32.hexprint(local.get $memPtr))  ;; show where we are in memory
	(local.set $ctr _0)
	(loop $byteLoop1
	  (call $byte.hexprint (i32.load8_u (i32.add (local.get $ctr)(local.get $memPtr))))
	  (call $printsp)
	  _incrLocal($ctr)
	  (if (i32.lt_u (local.get $ctr)(i32.const 16))
		(br $byteLoop1)))
	(call $printsp)(call $printsp)
	(local.set $ctr _0)
	(loop $byteLoop2
	  (call $byte.dump (i32.load8_u (i32.add (local.get $ctr)(local.get $memPtr))))
	  _incrLocal($ctr)
	  (if (i32.lt_u (local.get $ctr)(i32.const 16))
		(br $byteLoop2)))
	(call $printlf)
  )
  (func $mem.dump
    (local $memPtr i32)(local $nCols i32)(local $col i32)(local $row i32)(local $byte i32)
	(local.set $nCols (i32.const 100))
	;;_testString(`mem.dump',`Starting $mem.dump')
	(call $strdata.print (global.get $curMemUsed:))
	  (call $i32.print (global.get $curMemUsed))
	  (call $printlf)
	(local.set $memPtr _0)
	(local.set $row _0)
	(loop $rowLoop
	  (call $mem.dumpline (local.get $memPtr))
	  (local.set $memPtr (i32.add (local.get $memPtr)(i32.const 16)))
	  (if (i32.lt_u (local.get $memPtr)(global.get $curMemUsed))
	    (br $rowLoop)))
	)

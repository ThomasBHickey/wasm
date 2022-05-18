;; table.m4
  ;; test function signatures
  (type $testSig (func (param i32)(result i32)))
define(`_tableLength',`0')dnl
define(`_incrTableLength',`define(`_tableLength',eval(_tableLength+1))dnl')dnl
define(`_addToTable', `divert(`2')    (;_tableLength;) $1
divert _incrTableLength')dnl
define(`_finishTable',`(global $tableLength i32 (i32.const _tableLength))
  (table _tableLength funcref)
  (elem _0
undivert(`2')  )')dnl

  (global $strCompareOffset i32 (i32.const _tableLength))
  _addToTable($str.compare)
  (global $strToStrOffset	i32 (i32.const _tableLength))
  _addToTable($str.toStr)
  (global $i32CompareOffset i32 (i32.const _tableLength))
  _addToTable($i32.compare)
  (global $i32ToStrOffset	i32 (i32.const _tableLength))
  _addToTable($i32.toStr)
  divert(`1')  (global $gFirstTestOffset i32 (i32.const _tableLength))
divert
  (func $test (export "_test")
	;; Run tests: wasmtime run XXX.wat --invoke _test
	(local $testOff i32)
	(local $oldCurMemUsed i32)
	(local.set $testOff (global.get $gFirstTestOffset))
	(local.set $oldCurMemUsed (global.get $curMemUsed))
	(loop $testLoop
	  (if (i32.lt_u (local.get $testOff)(global.get $tableLength))
	    (then
		  (local.get $testOff)
		  (call $Test.show
			;;(i32.sub (local.get $testOff) _4)
			(i32.const 42)
			(call_indirect
			  (type $testSig)
			  (local.get $testOff)))
		  _incrLocal($testOff)
		  (br $testLoop)
		)
	  )
	)
	(call $reclaimMem (local.get $oldCurMemUsed))
	(call $showMemUsed)
  )
  (func $Test.show (param $testNum i32)(param $testResult i32)
	(if (local.get $testResult)
	  (then
	    (call $Test.showFailed
		  (local.get $testNum)
		  (local.get $testResult)))
	  (else
		(call $Test.showOK (local.get $testNum))))
  )
  ;; try to avoid allocations during tests
  (func $Test.printTest
    (call $byte.print _CHAR(`T'))
	(call $byte.print _CHAR(`e'))
	(call $byte.print _CHAR(`s'))
	(call $byte.print _CHAR(`t'))
	(call $printsp)
  )
  (func $Test.showOK (param $testnum i32)
    (call $Test.printTest)
	(call $i32.print (i32.sub (local.get $testnum)(global.get $gFirstTestOffset)))
	(call $printsp)
	(call $byte.print _CHAR(`O'))
	(call $byte.print _CHAR(`K'))
	(call $printlf)
  )
  (func $Test.showFailed (param $testnum i32)(param $testResult i32)
    (call $Test.printTest)
	(call $i32.print (i32.sub(local.get $testnum)(global.get $gFirstTestOffset)))
	(call $printsp)
	(call $byte.print _CHAR(`N'))
	(call $byte.print _CHAR(`O'))
	(call $byte.print _CHAR(`K'))
	(call $byte.print _CHAR(`!'))
	(call $byte.print _CHAR(`!'))
	(call $printsp)
	(call $i32.print (local.get $testResult))
	(call $printlf)
	)


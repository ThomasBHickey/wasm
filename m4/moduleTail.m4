;; moduleTail.m4
  _gnts(`gZZZ',`ZZZ')
;; ready to undivert
undivert(`1')
;; undiverted
 (global $curMemUsed (mut i32)(i32.const _globalPos))
 (global $maxMemUsed (mut i32)(i32.const _globalPos))
 _finishTable
) ;; end of module

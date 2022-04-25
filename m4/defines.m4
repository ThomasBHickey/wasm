;;defines.m4
changecom(`;;')dnl
;; Character defines
define(`_CHAR',`(i32.const eval(32+index(` !"#$%& ()*+,-./0123456789:;<=>?@ABCDEFGHIJKOMNOPQRSTUVWXYZ[\]^_ abcdefghijklmnopqrstuvwxyz{|}~',$1))`(;$1;)')')dnl
define(`_LEFTQ',(i32.const 39(;LEFTQ;)))dnl
define(`_TAB',(i32.const 9(;TAB;)))dnl
define(`_CR',(i32.const 13(;CR;)))dnl
define(`_LF',(i32.const 10(;LF;)))dnl
;;define(`_SP',`_CHAR(` '(;SP;))')dnl
define(`_SP', (i32.const 32))
define(`_SINGQUOTE',(i32.const 39(;SINGQUOTE;)))dnl
define(`_0',`(i32.const 0)')
define(`_1',`(i32.const 1)')
;; Global defines
define(`_globalPos', `100')dnl
define(`_newGlobalPos', `define(`_globalPos',eval(_globalPos+1+len($1)))')dnl
define(`_gdef', `divert(`1')  (data (i32.const _globalPos) "$2\00") (global $$1 i32 (i32.const _globalPos))
divert _newGlobalPos($2)')dnl
define(`_i32ConstGlob', `(global $$1 i32 (i32.const $2))')dnl
define(`_incrLocal', (local.set $1 (i32.add(local.get $1)_1)))
define(`_testString', `_gdef($1,$2)(call $str.printwlf(call $str.mkdata (global.get $$1)))')dnl

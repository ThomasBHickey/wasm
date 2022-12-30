;;defines.m4
changecom(`;;')dnl
;; Character defines
define(`_CHAR',`(i32.const eval(32+index(` !"#$%& ()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_ abcdefghijklmnopqrstuvwxyz{|}~',$1))`(;$1;)')')dnl
define(`_LEFTQ',(i32.const 39(;LEFTQ;)))dnl
define(`_TAB',(i32.const 9(;TAB;)))dnl
define(`_CR',(i32.const 13(;CR;)))dnl
define(`_LF',(i32.const 10(;LF;)))dnl
define(`_SP', (i32.const 32(;SP;)))dnl
define(`_SINGQUOTE',(i32.const 39(;SINGQUOTE;)))dnl
define(`_LPAREN', `(i32.const 40(;LPAREN;))')dnl
define(`_RPAREN', `(i32.const 41(;RPAREN;))')dnl
define(`_COMMA', `(i32.const 44(;COMMA;))')dnl
define(`_DOLLAR', `(i32.const 36(;DOLLAR;))')dnl
define(`_0',`(i32.const 0)')dnl
define(`_1',`(i32.const 1)')dnl
define(`_2',`(i32.const 2)')dnl
define(`_3',`(i32.const 3)')dnl
define(`_4',`(i32.const 4)')dnl
define(`_5',`(i32.const 5)')dnl
define(`_6',`(i32.const 6)')dnl
define(`_7',`(i32.const 7)')dnl
define(`_8',`(i32.const 8)')dnl
define(`_16',`(i32.const 16)')dnl
define(`_32',`(i32.const 32)')dnl
define(`_maxNeg',`(i32.const 0x80000000)')dnl
;; Global defines
define(`_globalPos', `100')dnl
define(`_newGlobalPos', `define(`_globalPos',eval(_globalPos+1+len($1)))')dnl
;; global null terminated strings (gnts's):
;; NOTE: For some reason commas in a _gnts cause the offset not to increment correctly!!!
define(`_gnts', `divert(`1')  (data (i32.const _globalPos) "$2\00") (global $$1 i32 (i32.const _globalPos))
divert _newGlobalPos($2)')dnl
define(`_incrLocal', (local.set $1 (i32.add(local.get $1)_1)))dnl
define(`_decrLocal', (local.set $1 (i32.sub(local.get $1)_1)))dnl
define(`_testString', `_gnts($1,$2)(call $str.printwlf(call $str.mkdata (global.get $$1)))')dnl
define(`_i32GlobalConst', `(global $$1 i32 (i32.const $2))')dnl
define(`_i64GlobalConst', `(global $$1 i64 (i64.const $2))')dnl
;; gAAA needs to be the first global declared
;; str.toStr uses the address to recognize the global null terminated strings
_gnts(`gAAA',`AAA')
_gnts(`gMaxNegAsChars', `-2,147,483,648')

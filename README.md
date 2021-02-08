# wasm
WebAssembly explorations

An interest in minimal systems makes WebAssembly an attractive system
to explore.  That it appears to be rapidly becoming essential to the Web
makes it even more attractive since it will probably be supported for the
long term.

Decades ago I spent a couple of years programming in Xerox/Honeywell CPV's 
Macro Assembler, and once wrote a Forth compiler in assembler to give me easier
string manipulation.  I expected that experience with Forth would help me
cope with WebAssembly's stack orientation, but the approach is so different
that not much seems to transfer.

Since most of my programming has centered around string manipulation,
writing a simple string package for Wasm seems like a reasonable first task.
Longer term I am planning on implementing Schorre's Meta II compiler
manipulation system.

My approach is to to do as much in WebAssembly as possible.  Currently the code's
external calls are to fd_read and fd_write as supported by bytecodealliance/wasmtime.
In addition to wasmtime I find it helpfule to use WebAssembly/wabt/wat2wasm since
it often gives more informative diagnotics than wasmtime.

string1.wat has some minimal string funcs that can create and display strings.

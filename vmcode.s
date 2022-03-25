	.intel_syntax noprefix

	.globl main_code

	.data

##
# macros for compiling code
#

# embed a primitive named `label` to execute immediately.
	.macro PRIMITIVE label
	.dc.a primitive_\label
	.endm

# embed a value as a literal to push immediately.
	.macro LITERAL val
	PRIMITIVE LIT
	.dc.a \val
	.endm

# embed an invocation of data field address to execute immediately.
# this is used only the codeptr is staticaly determined.
	.macro DOCOL codeptr
	PRIMITIVE DOCOL
	.dc.a \codeptr
	.endm

# embed codes to compile a valueas into HERE.
	.macro COMPILE_LIT val
	LITERAL primitive_LIT
	PRIMITIVE COMMA
	LITERAL \val
	PRIMITIVE COMMA
	.endm

# embed codes to compile a word invocation into HERE
	.macro COMPILE_PRM label
	LITERAL primitive_\label
	PRIMITIVE COMMA
	.endm

# embed codes to compile codes to compile a primitive invocation.
	.macro COMPILE_COMPILE_PRM label
	COMPILE_LIT primitive_\label
	COMPILE_PRM COMMA
	.endm

##
# word-defining macros
#

# define a code defining word named by `name`.
# when DOCOL a label create by this macro `defword_\label,
# CREATE and COMPILE a word behaved as the code between DEFWORD and ENDDEF at run-time.
	.macro DEFWORD name label flags
	.align 8
word_\label:
	.ascii "\name"
	.set word_\label\()_namelen, . - word_\label
	.align 8
define_word_\label:
	LITERAL \flags
	LITERAL word_\label
	LITERAL word_\label\()_namelen
	PRIMITIVE CREATE
	.endm

# close a code definition.
	.macro ENDDEF
	PRIMITIVE EXIT
	.endm

# invoke a word definition.
# after this macro, a word named `label` is added in the dictionary.
	.macro DEFINE label
	DOCOL define_word_\label
	.endm

# invoke a word defined at run-time.
	.macro EXECUTE label
	LITERAL word_\label
	LITERAL word_\label\()_namelen
	PRIMITIVE FIND
	PRIMITIVE DROP
	PRIMITIVE TO_BODY
	PRIMITIVE EXEC
	.endm

# embed codes to compile a invocation of a word defined at run-time.
	.macro COMPILE_WORD label
	COMPILE_PRM LIT
	LITERAL word_\label
	LITERAL word_\label\()_namelen
	PRIMITIVE FIND
	PRIMITIVE DROP
	PRIMITIVE TO_BODY
	PRIMITIVE COMMA
	COMPILE_PRM EXEC
	.endm

## defining macro example:
#
#	DEFWORD "FOUR", "FOUR", 0
#	COMPILE_LIT '*
#	COMPILE_PRM EMIT
#	COMPILE_PRM EXIT
#	ENDDEF
#
#initialize:
#	DEFINE FOUR
#	PRIMITIVE EXIT
#
#main_code:
#	DOCOL initialize
#	DOCOL export_primitives
#	EXECUTE FOUR
#	LITERAL 'h
#	EXECUTE EMIT
#	PRIMITIVE QUIT
#

##
# macros for exporting primitives
#

# redefine primitives as words
	.macro REDEF name label flags
	DEFWORD "\name", "\label", \flags
	COMPILE_PRM \label
	COMPILE_PRM EXIT
	ENDDEF
	.endm

# export a pirimitive by setting up
# to hide dengerous primitives in the primitive dictionary
	.macro EXPORT label
	DOCOL define_word_\label
	.endm

	REDEF "EMIT", "EMIT", 0x00
	REDEF ">R", "RPUSH", 0x00
	REDEF "R>", "RPOP", 0x00
	REDEF "=", "EQ", 0x00
	REDEF "NOT", "NOT", 0x00
	REDEF "OR", "OR", 0x00

export_primitives:
	EXPORT EMIT
	EXPORT RPUSH
	EXPORT RPOP
	EXPORT EQ
	EXPORT NOT
	EXPORT OR
	PRIMITIVE EXIT

## REWRITEING...

##
# built-in words
#

# start to branch conditionally. this word is available in compiler mode.
#
#    ( bool -- bool )
#
# in compilation:
#     ( -- addr )
#
	DEFWORD "IF", "IF", 0x80
	COMPILE_COMPILE_PRM NOT
	COMPILE_COMPILE_PRM DUP
	COMPILE_COMPILE_PRM BZ
	COMPILE_PRM FW_MARK
	COMPILE_PRM EXIT
	ENDDEF

# introduce an else clause to IF. this word is available in compiler mode.
#
#    ( bool -- )
#
# in compilation:
#    ( addr1 -- addr2 )
#
	DEFWORD "ELSE", "ELSE", 0x80
	COMPILE_PRM FW_RESOLVE
	COMPILE_COMPILE_PRM NOT
	COMPILE_COMPILE_PRM BZ
	COMPILE_PRM FW_MARK
	COMPILE_PRM EXIT
	ENDDEF

# terminate IF with catch branching. this word is available in compiler mode.
#
#    ( -- )
#
# in compilation:
#    ( addr -- )
#
	DEFWORD "ENDIF", "ENDIF", 0x80
	COMPILE_PRM FW_RESOLVE
	COMPILE_PRM EXIT
	ENDDEF

# start to loop. this word is available in compiler mode.
# BEGIN is used with two type loop:
#    1. `BEGIN ... bool UNTIL`              ... do loop until bool is true
#    2. `BEGIN ... bool WHILE ... REPEAT`   ... do loop until bool is false
#
#    ( -- )
#
# in compilation:
#    ( -- begin )
#
	DEFWORD "BEGIN", "BEGIN", 0x80
	COMPILE_PRM BW_MARK
	COMPILE_PRM EXIT
	ENDDEF

# terminate BEGIN-UNTIL loop. this word is available in compiler mode.
#
#    ( bool -- )
#
# in compilation:
#    ( begin -- )
#
	DEFWORD "UNTIL", "UNTIL", 0x80
	COMPILE_COMPILE_PRM NOT
	COMPILE_COMPILE_PRM BZ
	COMPILE_PRM BW_RESOLVE
	COMPILE_PRM EXIT
	ENDDEF

# check the loop condition in BEGIN-WHILE loop. this word is available in compiler mode.
#
#    ( bool -- )
#
# in compilation:
#    ( begin -- begin repeat )
#
	DEFWORD "WHILE", "WHILE", 0x80
	COMPILE_COMPILE_PRM NOT
	COMPILE_COMPILE_PRM BZ
	COMPILE_PRM FW_MARK
	COMPILE_PRM EXIT
	ENDDEF

# terminate BEGIN-WHILE loop. this word is available in compiler mode.
#
#    ( -- )
#
# in compilation:
#    ( begin repeat -- )
#
	DEFWORD "REPEAT", "REPEAT", 0x80
	COMPILE_PRM SWAP
	COMPILE_COMPILE_PRM B
	COMPILE_PRM BW_RESOLVE
	COMPILE_PRM FW_RESOLVE
	COMPILE_PRM EXIT
	ENDDEF

# a word for testing IF ~ ELSE ~ ENDIF
# ( u -- )
	DEFWORD "EMITZNZ", "EMITZNZ", 0x00
	EXECUTE IF
	COMPILE_LIT 'z
	COMPILE_PRM EMIT
	EXECUTE ELSE
	COMPILE_LIT 'n
	COMPILE_PRM EMIT
	EXECUTE ENDIF
	COMPILE_PRM EXIT
	ENDDEF

# a word for testing BEGIN-UNTIL loop
# ( -- )
	DEFWORD "BU_LOOP", "BU_LOOP", 0x00
	COMPILE_LIT 0
	EXECUTE BEGIN
	COMPILE_PRM DUP
	COMPILE_LIT 'a
	COMPILE_PRM ADD
	COMPILE_PRM EMIT
	COMPILE_LIT 1
	COMPILE_PRM ADD
	COMPILE_PRM DUP
	COMPILE_LIT 10
	COMPILE_PRM EQ
	EXECUTE UNTIL
	COMPILE_PRM EXIT
	ENDDEF

# a word for testing BEGIN-WHILE loops
# ( -- )
	DEFWORD "BW_LOOP", "BW_LOOP", 0x00
	COMPILE_LIT 0
	EXECUTE BEGIN
	COMPILE_PRM DUP
	COMPILE_LIT 10
	COMPILE_PRM EQ
	COMPILE_PRM NOT
	EXECUTE WHILE
	COMPILE_PRM DUP
	COMPILE_LIT 'A
	COMPILE_PRM ADD
	COMPILE_PRM EMIT
	COMPILE_LIT 1
	COMPILE_PRM ADD
	EXECUTE REPEAT
	COMPILE_PRM EXIT
	ENDDEF

# read one token delimited with `char`
#
# ( char -- addr u )
#
#   char: a delimiter character
#   addr: a pointer to string read
#   u:    a number of characters read into addr
#
	DEFWORD "WORD", "WORD", 0x00
	# IFを実装してから書く。
	# ループもいるな。
	#
	# アルゴリズム:
	#   1. ストリームが空なら補充
	#   2. 補充がエラーなら再度補充
	#   3. ストリームから1文字先読み
	#   4. デリミタ or 改行なら1文字消費して文字列addrと長さuをスタックに置いて終了
	#   5. それ以外なら消費しline bufferに追記して3へ
	ENDDEF

##
# startup codes

setup_builtins:
	DEFINE IF
	DEFINE ELSE
	DEFINE ENDIF
	DEFINE BEGIN
	DEFINE UNTIL
	DEFINE WHILE
	DEFINE REPEAT
	DEFINE EMITZNZ
	DEFINE BU_LOOP
	DEFINE BW_LOOP
	PRIMITIVE EXIT

main_code:
	DOCOL export_primitives
	DOCOL setup_builtins
	EXECUTE BW_LOOP
	PRIMITIVE QUIT

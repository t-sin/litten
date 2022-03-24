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
#
#	.macro COMPILE_WORD label
#	LITERAL word_\label
#	LITERAL word_\label\()_namelen
#	PRIMITIVE FIND
#	PRIMITIVE DROP
#	PRIMITIVE TO_BODY
#	COMPILE_PRM EXEC
#	PRIMITIVE COMMA
#	.endm
#

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

export_primitives:
	EXPORT EMIT
	EXPORT RPUSH
	EXPORT RPOP
	EXPORT EQ
	EXPORT NOT
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

# read one token delimited with `char`
#
# ( char -- addr )
#
#   char: a delimiter character
#   addr: a pointer to string read formatted as bytes: [len ch0 ch1 ...]
#
	DEFWORD "WORD", "WORD", 0x00
	# IFを実装してから書く
	ENDDEF

##
# startup codes

setup_builtins:
	DEFINE IF
	DEFINE ELSE
	DEFINE ENDIF
	DEFINE EMITZNZ
	PRIMITIVE EXIT

main_code:
	DOCOL export_primitives
	DOCOL setup_builtins
	LITERAL 0
	EXECUTE EMITZNZ
	LITERAL -1
	EXECUTE EMITZNZ
	PRIMITIVE QUIT

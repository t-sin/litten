	.intel_syntax noprefix

	.globl main_code

	.data

##
# convinient macros to define code
#

	.macro PRIMITIVE label
	.dc.a primitive_\label
	.endm

	.macro LIT val
	PRIMITIVE LIT
	.dc.a \val
	.endm

	.macro DOCOL codeptr
	PRIMITIVE DOCOL
	.dc.a \codeptr
	.endm

	.macro CMP_L val
	LIT \val
	PRIMITIVE COMMA
	.endm

	.macro CMP_P label
	LIT primitive_\label
	PRIMITIVE COMMA
	.endm

	.macro PUTCH ch
	LIT \ch
	PRIMITIVE EMIT
	.endm

# define a code defining word named by `name`
# when DOCOL a label create by this macro `defword_\label,
# CREATE and COMPILE a word behaved as the code between DEFWORD and ENDDEF at run-time.
#
	.macro DEFWORD name label flags
	.align 8
word_\label:
	.ascii "\name"
	.set word_\label\()_namelen, . - word_\label
	.align 8
defword_\label:
	LIT \flags
	LIT word_\label
	LIT word_\label\()_namelen
	PRIMITIVE CREATE
	.endm

	.macro ENDDEF
	PRIMITIVE EXIT
	.endm

	.macro DEFINE label
	DOCOL defword_\label
	.endm

	.macro EXECUTE label
	LIT word_\label
	LIT word_\label\()_namelen
	PRIMITIVE FIND
	PRIMITIVE DROP
	PRIMITIVE TO_BODY
	PRIMITIVE EXEC
	.endm

	.macro CMP_E label
	CMP_L word_\label
	CMP_L word_\label\()_namelen
	CMP_P FIND
	CMP_P DROP
	CMP_P TO_BODY
	CMP_P EXEC
	.endm

##
# word-defining macro example
#
#	DEFWORD "FOUR", "FOUR", 0
#	CMP_P LIT
#	CMP_L 4
#	CMP_P EXIT
#	ENDDEF
#
# initialize:
#	DEFINE FOUR
#	PRIMITIVE EXIT
#
# main_code:
#	DOCOL initialize
#	EXECUTE FOUR
#	PRIMITIVE EMIT
#	PRIMITIVE QUIT
#

# redefine primitives as words
#
	.macro REDEF name label flags
	DEFWORD "\name", "\label", \flags
	CMP_P \label
	ENDDEF
	.endm

# export a pirimitive by setting up
# to hide dengerous primitives in the primitive dictionary
#
	.macro EXPORT label
	DOCOL defword_\label
	.endm

	REDEF "EMIT", "EMIT", 0x00
	REDEF "=", "EQ", 0x00

export_primitives:
	EXPORT EMIT
	EXPORT EQ
	PRIMITIVE EXIT

##
# built-in words
#

# start to branch conditionally. this word is available in compiler mode.
#
# C: ( bool -- )
#
	DEFWORD "IF", "IF", 0x80
	CMP_P BZ
	PRIMITIVE FW_MARK
	ENDDEF

# introduce an else clause to IF. this word is available in compiler mode.
#
# C: ( addr -- addr )
#
	DEFWORD "ELSE", "ELSE", 0x80
	PRIMITIVE FW_MARK
	PRIMITIVE FW_RESOLVE
	ENDDEF

# terminate IF with catch branching. this word is available in compiler mode.
#
# C: ( addr -- )
#
	DEFWORD "THEN", "THEN", 0x80
	PRIMITIVE FW_RESOLVE
	ENDDEF

# a word for testing IF ~ ELSE ~ THEN
# ( u -- )
	DEFWORD "EMIT_ZNZ", "EMIT_ZNZ", 0x00
	EXECUTE IF
	CMP_L 'z
	CMP_E EMIT
	EXECUTE ELSE
	CMP_L 'n
	CMP_E EMIT
	CMP_L 'z
	CMP_E EMIT
	EXECUTE THEN
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
#	DOCOL defword_WORD
	DEFINE IF
	DEFINE ELSE
	DEFINE THEN
	PRIMITIVE EXIT

main_code:
	DOCOL export_primitives
	DOCOL setup_builtins
	EXECUTE EMIT_ZNZ
	PRIMITIVE QUIT

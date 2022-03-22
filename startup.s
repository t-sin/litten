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

	.macro COMPILE val
	LIT \val
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

##
# word-defining macro example
#
#	DEFWORD "FOUR", "FOUR", 0
#	COMPILE word_LIT
#	COMPILE 4
#	COMPILE word_EXIT
#	ENDDEF
#
# initialize:
#	DOCOL defword_FOUR
#	WORD EXIT
#
# main_code:
#	DOCOL initialize
#	LIT word_FOUR
#	LIT word_FOUR_namelen
#	WORD FIND
#	WORD DROP
#	WORD TO_BODY
#	WORD EXEC
#	WORD DUP
#	WORD QUIT
#

##
# startup codes

initialize:
	DOCOL defword_WORD
	LIT 'b
	PRIMITIVE DUP
	PRIMITIVE EMIT
	LIT 1
	PRIMITIVE SUB
	PRIMITIVE EMIT
	PRIMITIVE EXIT

main_code:
	DOCOL initialize
	PRIMITIVE QUIT

	.intel_syntax noprefix

	.globl main_code

	.data

##
# convinient macros to define code
#

	.macro WORD name
	.dc.a word_\name
	.endm

	.macro LIT val
	.dc.a word_LIT
	.dc.a \val
	.endm

	.macro DOCOL codeptr
	.dc.a word_DOCOL
	.dc.a \codeptr
	.endm

	.macro COMPILE val
	LIT \val
	WORD COMMA
	.endm

	.macro PUTCH ch
	LIT \ch
	.dc.a word_EMIT
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
	WORD CREATE
	.endm

	.macro ENDDEF
	WORD EXIT
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
	WORD EXIT

main_code:
	DOCOL initialize
	WORD QUIT

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

##
# second stage words defined in startup code
#

word_name_FOUR:
	.align 8
	.ascii "FOUR"
define_word_FOUR:
	.align 8
	LIT 0
	LIT word_name_FOUR
	LIT 4
	WORD CREATE
	COMPILE word_LIT
	COMPILE 4
	COMPILE word_EXIT
	WORD EXIT

##
# startup codes

main_code:
	DOCOL define_word_FOUR
	LIT word_name_FOUR
	LIT 4
	WORD FIND
	WORD DROP
	WORD TO_BODY
	WORD EXEC
	WORD DUP
	WORD QUIT

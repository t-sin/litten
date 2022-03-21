	.intel_syntax noprefix

	.globl main_code

	.data

##
# startup codes

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

	.macro PUTCH ch
	LIT \ch
	.dc.a word_EMIT
	.endm

main_code:
	# create a word
	LIT 0
	DOCOL prompt_name_code
	LIT '\n
	WORD PARSE
	WORD CREATE

	# create a word pt.2
	LIT 0
	DOCOL prompt_name_code
	LIT '\n
	WORD PARSE
	WORD CREATE

	# find word created above
	DOCOL prompt_name_code
	LIT '\n
	WORD PARSE
	WORD FIND
	WORD DROP
	WORD DROP
	WORD QUIT

prompt_name_code:
	PUTCH 'n
	PUTCH 'a
	PUTCH 'm
	PUTCH 'e
	PUTCH '?
	PUTCH ' 
	WORD EXIT

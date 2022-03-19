	.intel_syntax noprefix

	.globl main_code

	.data

##
# startup codes

	.macro PUTCH ch
	.dc.a word_LIT
	.dc.a \ch
	.dc.a word_EMIT
	.endm

main_code:
	.dc.a word_DOCOL
	.dc.a prompt_code
	.dc.a word_LIT
	.dc.a ' 
	.dc.a word_PARSE
	.dc.a word_FIND
	.dc.a word_DROP
	.dc.a word_DROP
	.dc.a word_QUIT

prompt_code:
	PUTCH '>
	PUTCH ' 
	.dc.a word_EXIT

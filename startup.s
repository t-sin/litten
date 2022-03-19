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
	# create a word
	.dc.a word_LIT
	.dc.a 0
	.dc.a word_DOCOL
	.dc.a prompt_name_code
	.dc.a word_LIT
	.dc.a '\n
	.dc.a word_PARSE
	.dc.a word_CREATE
	# find word created above
	.dc.a word_DOCOL
	.dc.a prompt_name_code
	.dc.a word_LIT
	.dc.a '\n
	.dc.a word_PARSE
	.dc.a word_FIND
	.dc.a word_DROP
	.dc.a word_DROP
	.dc.a word_QUIT

prompt_name_code:
	PUTCH 'n
	PUTCH 'a
	PUTCH 'm
	PUTCH 'e
	PUTCH '?
	PUTCH ' 
	.dc.a word_EXIT

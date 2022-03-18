	.intel_syntax noprefix

	.globl _start
	.globl inner_interpreter

	.text

.include "macro.s"

_start = main_start
main_start:
	lea rax, main_code
	call setup_system
	jmp inner_interpreter

	.text


## setup Forth's states
#
# input:
#   rax: startup code address
#
# this Forth system uses these registers specially:
#
#   r15: Forth's instruction pointer (IP)
#   r14: Return stack pointer (RSP)
#   r13: Parameter stack pointer (SP)
#   r12: Next dictionary entry (NP)
#   r11: Latest dictionary entry (LATEST)
#

	# なんかこれうごかない…
	# .set IP,     r15
	# .set RSP,    r14
	# .set SP,     r13
	# .set NP,     r12
	# .set LATEST, r11

setup_system:
	mov r15, rax
	lea r14, rstack_bottom
	lea r13, pstack_bottom
	lea r12, dict_start
	lea r11, defword_link
	ret

# Forth's toplevel inner interpreter
#
inner_interpreter:
	mov rax, qword ptr [r15]
	add r15, 8
	jmp rax


##
# startup codes
	.data

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

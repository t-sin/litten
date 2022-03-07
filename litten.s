	.intel_syntax noprefix

	.globl _start
	.globl main_quit
	.globl inner_interpreter

	.text

_start = main_start
main_start:
	lea r15, main_code
	jmp inner_interpreter

main_quit:
	mov rax, 0
	ret

# Forth's inner interpreter
# it uses these registers:
#
#   r15: Forth's instruction pointer (IP)
#   r14: temporal IP
#
inner_interpreter:
	mov r14, qword ptr [r15]
	add r15, 8
	jmp r14

	.data

main_code:
	.dc.a word_readch
	.dc.a word_writech
	.dc.a word_newline
	.dc.a word_quit

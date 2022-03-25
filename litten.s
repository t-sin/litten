	.intel_syntax noprefix

	.globl _start

	.text

.include "macro.s"

_start = main_start
main_start:
	lea rax, main_code
	call setup_interpreter
	jmp inner_interpreter

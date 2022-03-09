	.intel_syntax noprefix

	.globl _start
	.globl NEXT
	.globl inner_interpreter

	.text

_start = main_start
main_start:
	lea rax, main_code
	call setup_system
	jmp inner_interpreter


	.data

##
# return stack
#
rstack_max:
	.skip 0x10000
rstack_bottom:
rstack_size = . - rstack_max

## return stack operation

# push a cell to the return stack
#
	.macro RPUSH reg
	sub r14, 8
	mov qword ptr [r14], \reg
	.endm

# pop a cell from the return stack
#
	.macro RPOP reg
	mov \reg, qword ptr [r14]
	add r14, 8
	.endm

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
#
setup_system:
	mov r15, rax
	lea r14, rstack_bottom
	ret

# Forth's toplevel inner interpreter
#
inner_interpreter:
	mov rax, qword ptr [r15]
	add r15, 8
	jmp rax

##
# built-in words
#

# an IP progression macro for built-in words
#
	.macro NEXT
	jmp inner_interpreter
	.endm

## Forth primitives

# this is a starter words for user-defined words.
# the code of user-defined words must start with DOCOL words.
# 
word_docol:
	mov rax, [r15]
	add r15, 8
	mov rbx, r15
	RPUSH rbx
	mov r15, rax
	NEXT

# an IP progression macro for user-defined words
#
word_exit:
	RPOP r15
	NEXT

word_lit:
	mov rax, [r15]
	add r15, 8
	push rax
	NEXT

## system words

word_quit:
	mov rax, 0
	call syscall_exit

## I/O words

	.data

line_buffer:
	.skip 256
line_size = . - line_buffer

	.text

word_readch:
	mov rax, 0                         # 0 is for stdin
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_read
	mov rax, 0
	mov al, [line_buffer + 0]
	push rax
	NEXT

word_writech:
	pop rax
	mov byte ptr [line_buffer + 0], al
	mov rax, 1                         # 1 is for stdout
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_write
	NEXT

word_newline:
	mov al, 0x0a
	mov byte ptr [line_buffer + 0], al
	mov rax, 1                         # 1 is for stdout
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_write
	NEXT


	.data

##
# startup codes
	.data

	.macro PUTCH ch
	.dc.a word_lit
	.dc.a \ch
	.dc.a word_writech
	.endm

main_code:
	.dc.a word_readch
	.dc.a word_writech
	.dc.a word_docol
	.dc.a hello_code
	.dc.a word_lit
	.dc.a '*
	.dc.a word_writech
	.dc.a word_quit

hello_code:
	PUTCH 'h
	PUTCH 'i
	.dc.a word_exit

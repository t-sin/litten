	.intel_syntax noprefix

	.globl word_docol
	.globl word_exit
	.globl word_lit

	.globl word_quit

	.globl word_readch
	.globl word_writech
	.globl word_newline

	.text

.include "macro.s"

##
# built-in words
#


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

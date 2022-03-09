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

# define words and create its dictionary entry
#
# input:
#   name:    name string with a length `namelen`
#   namelen: length of `name`. it must be less than 7
#   flags:   if non-zero this word is an immediate word.
#            so, in compilation mode, this word is executed, not compiled.
#
	.set _defword_link, 0

	.macro DEFWORD name namelen flags

	.ifge \namelen - 8
	.error "namelen is too large: \namelen"
	.endif

	.set _defword_head, .

	.globl word_\name
	.section .text
	# name field
	.align 8
	.byte \namelen + \flags
	.ascii "\name"

	# link field
	.align 8
	.dc.a _defword_link
	.set _defword_link, _defword_head

	# codeptr
	.align 8
	.dc.a . + 8

word_\name:
	.endm

##
# built-in words
#


## Forth primitives

# this is a starter word for colon-defined words.
# the code of colon-defined words must start with DOCOL words.
#
	DEFWORD "docol", 5, 0
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
	PPUSH rax
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
	PPUSH rax
	NEXT

word_writech:
	PPOP rax
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

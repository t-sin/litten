	.intel_syntax noprefix
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
	.set defword_link, 0
	.globl defword_link

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
	.dc.a defword_link
	.set defword_link, _defword_head

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


# progress IP at the end of colon-defined words
#
	DEFWORD "exit", 4, 0
	RPOP r15
	NEXT

# push an integer literal following this word to pstack
# this is an immediate word
	DEFWORD "lit", 3, 0x80
	mov rax, [r15]
	add r15, 8
	PPUSH rax
	NEXT

## system words

# exit litten system with status code 0
	DEFWORD "quit", 4, 0
	mov rax, 0
	call syscall_exit

## I/O words

# read one character from stdin
	DEFWORD "readch", 6, 0
	mov rax, 0                         # 0 is for stdin
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_read
	mov rax, 0
	mov al, [line_buffer + 0]
	PPUSH rax
	NEXT

# write one character to stdout
	DEFWORD "writech", 7, 0
	PPOP rax
	mov byte ptr [line_buffer + 0], al
	mov rax, 1                         # 1 is for stdout
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_write
	NEXT

# write newline to stdout
	DEFWORD "newline", 7, 0
	mov al, 0x0a
	mov byte ptr [line_buffer + 0], al
	mov rax, 1                         # 1 is for stdout
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_write
	NEXT

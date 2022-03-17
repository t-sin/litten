	.intel_syntax noprefix
	.text

.include "macro.s"

##
# dictionary entry
#
# name     +---------+------+------+-----+------+
# field:   | flg+len | ch1  | ch2  | ... | ch7  |  ... 64 bit
#          +---------+------+------+-----+------+
#          | ch8     | ch9  | ch10 | ... | ch15 |
# link     +---------+------+------+-----+------+
# field:   | pointer to previous entry          |
#          +------------------------------------+
# data     | code or data.                      |
# field:   | it has its length if needed.       |
#          +------------------------------------+
#
# flg+len
#
#   a `flg+len` byte stores how the entry behaves.
#   it is formed with 8 bits as follows:
#
#     ih00llll
#
#   i: immediate bit
#     this bit indicates this word is an immediate word; when this word appears in compilation mode,
#     this word will be executed immediately, not will be compiled.
#   h: hidden bit
#     this bit indicates this word is a hidden word; this word is ignored while word finding process.
#   l: length
#     length of a name of this word.
#

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

word_\name:
	.endm

# create one dictionary entry
# after creating entry, NP (r12) is set to its parameter field head.
#
# (flags name -- )
#
#   flags: a flag byte for this entry
#   name: a pointer to the name string ([64-bit len, ch0, ch1, ...])
#
	DEFWORD "create", 6, 0x8
word_create:
	PPOP rbx        # name
	PPOP rax        # flags

	# set a flag byte
	mov rcx, qword ptr [rbx]
	# TODO: check if `rcx < 16`
	or al, cl       # assumes that cl is less than 16
	mov rdx, 0
	mov byte ptr [r12 + rdx], al
	add rdx, 1

	# create name field
_name_copy_loop:
	add rdx, 1
	cmp rcx, rdx
	je _name_copy_end
	mov sil, byte ptr [rbx + rdx]
	mov byte ptr [r12 + rdx], sil
	add rdx, 1
	jmp _name_copy_loop
_name_copy_end:
	cmp rcx, 0x08
	jg _2qword_name
	# 1qword name
	add rdx, 0x08
	jmp _create_link_field
_2qword_name:
	add rdx, 0x0f

_create_link_field:
	# create link field
	mov qword ptr [r12 + rdx], r11
	add rdx, 8
	mov r11, r12
	add r12, rdx

	NEXT

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
	DEFWORD "key", 3, 0
	mov rax, 0                         # 0 is for stdin
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_read
	mov rax, 0
	mov al, [line_buffer + 0]
	PPUSH rax
	NEXT

# write one character to stdout
	DEFWORD "emit", 4, 0
	PPOP rax
	mov byte ptr [line_buffer + 0], al
	mov rax, 1                         # 1 is for stdout
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_write
	NEXT

# write newline to stdout
	DEFWORD "nl", 2, 0
	mov al, 0x0a
	mov byte ptr [line_buffer + 0], al
	mov rax, 1                         # 1 is for stdout
	lea rbx, line_buffer
	mov rcx, 1
	call syscall_write
	NEXT

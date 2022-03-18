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
	lea rbx, input_buffer
	mov rdx, 0
	mov dx, word ptr [input_start]
	add rbx, rdx
	mov rcx, 1
	call syscall_read
	mov rax, 0
	mov al, [rbx]
	PPUSH rax
	NEXT

# write one character to stdout
	DEFWORD "emit", 4, 0
	PPOP rax
	lea rbx, output_buffer
	mov rdx, [output_start]
	add rbx, rdx
	mov byte ptr [rbx], al
	mov rax, 1                         # 1 is for stdout
	mov rcx, 1
	call syscall_write
	NEXT

# write newline to stdout
	DEFWORD "nl", 2, 0
	mov al, 0x0a
	lea rbx, output_buffer
	mov rdx, [output_start]
	add rbx, rdx
	mov byte ptr [rbx], al
	mov rax, 1                         # 1 is for stdout
	mov rcx, 1
	call syscall_write
	NEXT

# read one name from stdin
#
# ( ch -- addr )
#
#   ch: a delimiter
#   addr: a pointer to string read
#
	DEFWORD "parse", 5, 0x8
	mov r8, qword ptr [input_start]   # start position of input
	mov r9, 0                         # all num read
	PPOP r10                          # delimiter

_parse_read:
	mov rax, 0                          # stdin
	mov rcx, offset input_buffer_size   # num input
	mov rbx, offset input_buffer
	add rbx, r8
	call syscall_read

	cmp rax, 0
	jle _parse_read
	jg _parse_read_ok

_parse_read_ok:
	mov rcx, 0     # num read in _parse_loop

_parse_loop:
	mov dil, byte ptr [rbx + rcx]
	add rcx, 1
	add r9, 1

	cmp r9, offset input_buffer_size
	jge _parse_reaches_buffer_max
	jmp _parse_loop_cond

_parse_reaches_buffer_max:
	# TODO: handle error

_parse_loop_cond:
	cmp dil, r10b  # is a character read the delimiter?
	je _parse_end

	cmp rcx, rax
	je _parse_reread
	jmp _parse_loop

_parse_reread:
	add r9, rcx
	mov r8, r9
	jmp _parse_read

_parse_end:
	add r9, -1
	mov qword ptr [input_len], r9
	mov rax, offset input_len
	PPUSH rax

	NEXT

# print string
#
# ( addr -- )
#
	DEFWORD "print", 5, 0x8
	PPOP rax
	mov rbx, qword ptr [rax]  # length of string
	add rax, 8                # body of string
	mov rcx, 0                # output count
	lea rdx, output_buffer

_copy_str_loop:
	mov rsi, 0
	mov sil, [rax + rcx]
	mov byte ptr [output_buffer + rcx], sil
	add rcx, 1

	cmp rcx, rbx
	jne _copy_str_loop

	mov rax, 1              # 1 is for stdout
	lea rbx, output_buffer
	mov rcx, rcx            # num of output
	call syscall_write

	NEXT

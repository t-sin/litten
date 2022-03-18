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

##
# built-in words
#

## Forth primitives

# enter the execution of the colon definition following after this word.
# IP is set to the address of head of code field of the colon definition
# and push the address following after the colon definition as a return address.
# so the following address after this word must point the code field.
# this is a starter word for colon-defined words.
#
# R: ( -- addr )
#
	DEFWORD "DOCOL", 5, 0
	mov rax, [r15]
	add r15, 8
	mov rbx, r15
	RPUSH rbx
	mov r15, rax
	NEXT


# progress IP at the end of colon-defined words
#
# ( -- )
#
	DEFWORD "EXIT", 4, 0
	RPOP r15
	NEXT

# push an integer literal following this word to pstack
# this word is mainly used the compiler
# this is an immediate word
#
# ( -- u )
#
	DEFWORD "LIT", 3, 0x80
	mov rax, [r15]
	add r15, 8
	PPUSH rax
	NEXT

## system words

# exit litten system with status code 0
#
# ( -- )
#
	DEFWORD "QUIT", 4, 0
	mov rax, 0
	call syscall_exit

##
# dictionary-related words
#

# create one dictionary entry
# after creating entry, NP (r12) is set to its parameter field head.
#
# ( flags addr u -- )
#
#   flags: a flag byte for this entry
#   addr: a pointer to the body of name string
#   u: length of name string
#
	DEFWORD "CREATE", 6, 0x80
word_create:
	PPOP rax    # length of name string
	PPOP rbx    # body of name string
	PPOP rcx    # flag byte

	# TODO: check if `rax < 16` and rise an error if the check failed

	# set a flag byte
	or cl, al       # assumes that al is less than 16
	mov rdx, 0
	mov byte ptr [r12 + rdx], al
	add rdx, 1

	# create name field
_name_copy_loop:
	add rdx, 1
	cmp rax, rdx
	je _name_copy_end
	mov sil, byte ptr [rbx + rdx]
	mov byte ptr [r12 + rdx], sil
	add rdx, 1
	jmp _name_copy_loop
_name_copy_end:
	cmp rax, 0x08
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


# find a word named addr1 with length u in the dictionary.
# if such word is found, addr2 is the address of the code filed of the word
# and u is 1 if the word is immediate otherwise -1 (true).
# if such word is not found, addr2 is addr1 and u is zero.
#
# ( addr1 u -- addr2 u )
	DEFWORD "FIND", 4, 0x80
	PPOP rax                 # body of name for searching
	PPOP rbx                 # length of name for searching
	mov rcx, r11             # current entry

_find_loop:
	cmp rcx, 0
	je _find_word_not_found

	mov dl, byte ptr [rcx]
	and rdx, 0x0f            # length of name of the current entry

	cmp rdx, rbx
	jne _find_go_next_word

	mov rdx, rcx
	mov rsi, 0
	add rdx, 1

_find_name_equality:
	mov dil, byte ptr [rdx + rsi]
	mov bpl, byte ptr [rax + rsi]

	cmp dil, bpl
	jne _find_word_not_found

	cmp rsi, rbx
	jz _find_word_found

	add rsi, 1

	jmp _find_name_equality

_find_go_next_word:
	# check the name field length to calculate its link field
	# 4 bit or higher denotes a number of qwords
	mov rsi, rdx
	and rsi, 0xf8
	add rcx, rsi             # progress some qword

	# lowest 3 bits denotes a modulo devided by 8
	mov rsi, rdx
	and rsi, 0x7
	cmp rsi, 0
	jz _find_loop

	add rcx, 8
	jmp _find_loop

_find_word_found:
	PPUSH rcx

	mov al, byte ptr [rcx]
	and rax, 0x80
	cmp rax, 0
	jnz _find_word_is_immediate

	PPUSH -1                 # the word found is an immediate word
	jmp _find_exit
_find_word_is_immediate:
	PPUSH 1                  # the word found is not an immediate word

_find_exit:
	NEXT

_find_word_not_found:
	PPUSH rax
	PPUSH 0
	NEXT

##
# stack manupilation
#

# pop and discard one value from pstack
#
# ( v -- )
#
	DEFWORD "DROP", 4, 0
	PPOP rax
	NEXT

# duplicate a value on the top of pstack
#
# ( v -- v v )
#
	DEFWORD "DUP", 3, 0
	PPOP rax
	PPUSH rax
	PPUSH rax
	NEXT

##
# I/O words
#

# read one character from stdin
#
# ( -- u )
#
#   u: a character read
#
	DEFWORD "KEY", 3, 0
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
#
# ( u -- )
#
#   u: a character to output
#
	DEFWORD "EMIT", 4, 0
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
#
# ( -- )
#
	DEFWORD "NL", 2, 0
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
# ( u -- addr u)
#
#   u: a delimiter character
#   addr: a pointer to string read
#
	DEFWORD "PARSE", 5, 0x80
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
	mov rax, offset input_buffer
	PPUSH rax
	PPUSH r9

	NEXT

# print string
#
# ( addr u -- )
#
	DEFWORD "PRINT", 5, 0x80
	PPOP rax        # length of string
	PPOP rbx        # body of string
	mov rcx, 0      # output count
	lea rdx, output_buffer

_copy_str_loop:
	mov rsi, 0
	mov sil, [rbx + rcx]
	mov byte ptr [output_buffer + rcx], sil
	add rcx, 1

	cmp rcx, rax
	jne _copy_str_loop

	mov rax, 1              # 1 is for stdout
	lea rbx, output_buffer
	mov rcx, rcx            # num of output
	call syscall_write

	NEXT

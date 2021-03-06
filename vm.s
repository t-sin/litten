	.intel_syntax noprefix

	.globl setup_interpreter
	.globl inner_interpreter

	.text

.include "macro.s"

# The inner interpreter
#
inner_interpreter:
	mov rax, qword ptr [r15]
	add r15, 8
	jmp rax

## setup the inner interpreter
#
# input:
#   rax: startup code address
#
# this Forth system uses these registers specially:
#
#   r15: Forth's instruction pointer (IP)
#   r14: Return stack pointer (RSP)
#   r13: Parameter stack pointer (SP)
#   r12: Next dictionary entry (HERE)
#   r11: Latest dictionary entry (LATEST)
#

	# なんかこれうごかない…
	# .set IP,     r15
	# .set RSP,    r14
	# .set SP,     r13
	# .set HERE,   r12
	# .set LATEST, r11

setup_interpreter:
	mov r15, rax
	lea r14, rstack_bottom
	lea r13, pstack_bottom
	lea r12, dict_start
#	lea r11, defword_link
	mov r11, 0
	ret


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

	.macro DEFWORD name namelen label flags

	.ifge \namelen - 7
	.error "namelen is too large: \namelen"
	.endif

	.globl primitive_\label
	.section .text

	.align 8
	.set _defword_head, .

	# name field
	.byte \namelen + \flags
	.ascii "\name"

	# link field
	.align 8
	.dc.a defword_link
	.set defword_link, _defword_head

primitive_\label:
	.endm

##
# accessing FORTH states
#

# push an address of the next available dictionary entry
#
# ( -- addr )
#
	DEFWORD "HERE", 4, "HERE", 0
	PPUSH r12
	NEXT

# push an address of the latest created dictionary entry
#
# ( -- addr )
#
	DEFWORD "LATEST", 5, "LATEST", 0
	PPUSH r11
	NEXT

##
# Forth primitives
#

# enter the execution of the colon definition following after this word.
# IP is set to the address of head of code field of the colon definition
# and push the address following after the colon definition as a return address.
# so the following address after this word must point the code field.
# this is a starter word for colon-defined words.
#
# R: ( -- addr )
#
	DEFWORD "DOCOL", 5, "DOCOL", 0
	mov rax, [r15]
	add r15, 8
	mov rbx, r15
	RPUSH rbx
	mov r15, rax
	NEXT

# execute the word placed `addr`
#
#    ( addr1 -- )
# R: ( -- addr2 )
#
#   addr1: a data field address of execution target word
#   addr2: an address return back after execution
#
	DEFWORD "EXEC", 4, "EXEC", 0
	RPUSH r15
	PPOP rax
	mov r15, rax
	NEXT

# progress IP at the end of colon-defined words
#
# ( -- )
#
	DEFWORD "EXIT", 4, "EXIT", 0
	RPOP r15
	NEXT

# push an integer literal following this word to pstack
# this word is mainly used the compiler
# this is an immediate word
#
# ( -- u )
#
	DEFWORD "LIT", 3, "LIT", 0x80
	mov rax, [r15]
	add r15, 8
	PPUSH rax
	NEXT

##
# branching-related words
#

# mark here is the source address of forward branching,
# by pushing an address at here to pstack.
#
# tipically use like this: B >MARK ... >RESOLVE
#
# ( -- addr )
#
	DEFWORD ">MARK", 5, "FW_MARK", 0x80
	PPUSH r12
	add r12, 8
	NEXT

# resolve marked empty address for forward branching.
#
# ( addr -- )
#
	DEFWORD ">RES", 4, "FW_RESOLVE", 0x80
	PPOP rax
	mov qword ptr [rax], r12
	NEXT

# mark here is the destination address of backward branching,
# by pushing an address at here to pstack.
#
# tipically use like this: <MARK ... B <RESOLVE
#
# ( -- addr )
#
	DEFWORD "<MARK", 5, "BW_MARK", 0x80
	PPUSH r12
	NEXT

# resolve marked empty address for backward branching.
#
# ( addr -- )
#
	DEFWORD "<RES", 4, "BW_RESOLVE", 0x80
	PPOP rax
	mov qword ptr [r12], rax
	add r12, 8
	NEXT

# branch to the word specified `u` a qword following this word.
# if u is positive, it branch forward.
# if u is negative, it branch backward.
# if u is zero, this word has no effect.
#
# ( -- )
#
	DEFWORD "B", 1, "B", 0x00
	mov rax, qword ptr [r15]
	mov r15, rax
	NEXT

# conditional branching.
# branch to the word specified u a qword following this word only if bool is non-zero
#
# ( bool -- )
#
	DEFWORD "BZ", 2, "BZ", 0x00
	mov rax, qword ptr [r15]
	add r15, 8
	PPOP rbx
	cmp rbx, 0
	jne _bz_no_branch
	mov r15, rax
_bz_no_branch:
	NEXT

## system words

# exit litten system with status code 0
#
# ( -- )
#
	DEFWORD "QUIT", 4, "QUIT", 0
	mov rax, 0
	call syscall_exit

##
# dictionary-related words
#

# create one dictionary entry
# after creating entry, HERE (r12) is set to its parameter field head.
#
# ( flags addr u -- )
#
#   flags: a flag byte for this entry
#   addr: a pointer to the body of name string
#   u: length of name string
#
	DEFWORD "CREATE", 6, "CREATE", 0x80
	PPOP rax    # length of name string
	PPOP rbx    # body of name string
	PPOP rcx    # flag byte

	# TODO: check if `rax < 16` and rise an error if the check failed

	# 8-byte align
	mov rdx, r12
	mov rsi, 0x07
	and rdx, rsi
	cmp rdx, 0
	je _create_8byte_aligned
	mov rsi, 8
	sub rsi, rdx
	add r12, rsi
_create_8byte_aligned:

	# set a flag byte
	or cl, al       # assumes that al is less than 16
	mov byte ptr [r12], al
	mov rdx, 0
	mov rsi, 1

	# create name field
_name_copy_loop:
	cmp rax, rdx
	je _name_copy_end
	mov dil, byte ptr [rbx + rdx]
	mov byte ptr [r12 + rsi], dil
	add rdx, 1
	add rsi, 1
	jmp _name_copy_loop
_name_copy_end:
	mov rdx, rsi
	and rsi, 0x07
	cmp rsi, 0
	je _create_name_8byte_aligned
	mov rbp, 8
	sub rbp, rsi
	add rdx, rbp
_create_name_8byte_aligned:
	jmp _create_link_field
_create_link_field:
	# create link field
	mov qword ptr [r12 + rdx], r11
	add rdx, 8
	mov r11, r12
	# set HERE to the data field of this word
	add r12, rdx

	NEXT

# find a word named addr1 with length u in the dictionary.
# if such word is found, addr2 is the address of the code filed of the word
# and u is 1 if the word is immediate otherwise -1 (true).
# if such word is not found, addr2 is addr1 and u is zero.
#
# ( addr1 u -- addr2 u )
	DEFWORD "FIND", 4, "FIND", 0x80
	PPOP rbx                 # length of name for searching
	PPOP rax                 # body of name for searching
	mov rcx, r11             # current entry

_find_loop:
	cmp rcx, 0
	je _find_word_not_found

	mov dl, byte ptr [rcx]
	and rdx, 0x0f            # length of name of the current entry

	cmp rdx, rbx
	jne _find_go_next_word

	mov rsi, rcx
	mov rdi, 0
	add rsi, 1

_find_name_equality:
	mov bpl, byte ptr [rsi + rdi]
	mov spl, byte ptr [rax + rdi]
	add rdi, 1

	cmp bpl, spl
	jne _find_go_next_word

	cmp rdi, rbx
	jz _find_word_found
	jmp _find_name_equality

_find_go_next_word:
	# check the name field length to calculate its link field
	# 4 bit or higher denotes a number of qwords
	mov rsi, rdx
	and rsi, 0x08
	add rcx, rsi

	# lowest 3 bits denotes a modulo devided by 8
	mov rsi, rdx
	and rsi, 0x07
	cmp rsi, 0
	je _find_update_latest_pointer
	add rcx, 8
	jmp _find_update_latest_pointer

_find_update_latest_pointer:
	mov rcx, qword ptr [rcx]
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

# calculate an address of the code field
#
# ( addr1 -- addr2 )
#
#   addr1: the head address of the dictionary entry
#   addr2: an address of its code field
#
	DEFWORD ">BODY", 5, "TO_BODY", 0
	PPOP rax
	# skip name filed
	mov rbx, 0
	mov rcx, 0
	mov bl, byte ptr [rax]
	mov cl, bl
	and bl, 0x08
	add rax, rbx
	and cl, 0x07
	cmp cl, 0
	je _to_body_end
	add rax, 8
_to_body_end:
	# skip link field
	add rax, 8
	PPUSH rax
	NEXT

# allocate u bytes in the lastest created dictionary entry.
# r12 (HERE) is updated accordingly.
#
# ( u -- )
#
	DEFWORD "ALLOT", 5, "ALLOT", 0
	PPOP rax
	add r12, rax
	NEXT

# ALLOT space for qword then store qword at `HERE 8 -`
#
# ( qword -- )
#
	DEFWORD ",", 1, "COMMA", 0
	PPOP rax
	mov qword ptr [r12], rax
	add r12, 8
	NEXT

##
# memory manupilation
#

# store a qword into memory
#
# ( qword addr -- )
#
	DEFWORD "!", 1, "STORE", 0
	PPOP rax
	PPOP rbx
	mov qword ptr [rax], rbx
	NEXT

# store a byte into memory
#
# ( byte addr -- )
#
	DEFWORD "C!", 2, "CSTORE", 0
	PPOP rax
	PPOP rbx
	mov byte  ptr [rax], bl
	NEXT

# fetch a qword from memory
#
# ( addr - qword )
#
	DEFWORD "@", 1, "FETCH", 0
	PPOP rax
	mov rax, qword ptr [rax]
	PPUSH rax
	NEXT

# fetch a byte from memory
#
# ( addr - byte )
#
	DEFWORD "C@", 1, "CFETCH", 0
	PPOP rax
	mov rbx, 0
	mov bl, byte ptr [rax]
	PPUSH rbx
	NEXT

##
# stack manupilation
#

# pop and discard one value from pstack
#
# ( v -- )
#
	DEFWORD "DROP", 4, "DROP", 0
	PPOP rax
	NEXT

# duplicate a value on the top of pstack
#
# ( v -- v v )
#
	DEFWORD "DUP", 3, "DUP", 0
	PPOP rax
	PPUSH rax
	PPUSH rax
	NEXT

# swap two values on the top of pstack
#
# ( a b -- b a )
#
	DEFWORD "SWAP", 4, "SWAP", 0
	PPOP rax
	PPOP rbx
	PPUSH rax
	PPUSH rbx
	NEXT

# copy a value from the top of pstack
#
# ( v_n-1 v_n-2 ... v_0 n_1 -- v_n-1 ... v_0 v_n-1 )
#
	DEFWORD "PICK", 4, "PICK", 0
	PPOP rax
	mov rbx, 0
_pick_loop:
	cmp rbx, rax
	je _pick_end
	add rbx, 1
	jmp _pick_loop
_pick_end:
	mov rcx, rbx
	shl rcx, 3
	add rcx, r13
	mov rax, qword ptr [rcx]
	PPUSH rax
	NEXT

# transfer a value from pstack to rstack
#
#    ( v -- )
# R: ( -- v )
#
	DEFWORD ">R", 2, "RPUSH", 0
	PPOP rax
	RPUSH rax
	NEXT

# transfer a value from rstack to pstack
#
#    ( -- v)
# R: ( v -- )
#
	DEFWORD "R>", 2, "RPOP", 0
	RPOP rax
	PPUSH rax
	NEXT

##
# text input primitives
#

# peek a character from the input stream
# push zero if the input stream is empty
#
# ( -- u )
#
	DEFWORD "PEEK", 4, "PEEK", 0
	mov rax, 0
	mov rbx, 0
	mov eax, dword ptr [input_stream_count]
	cmp eax, 0
	je _peek_char
_peek_empty_input:
	mov rax, 0
	PPUSH rax
	NEXT
_peek_char:
	lea rax, input_stream
	mov rbx, 0
	mov ebx, dword ptr [input_stream_offset]
	add rax, rbx
	mov al, byte ptr [rax]
	and rax, 0xff
	PPUSH rax
	NEXT

# get a number of available characters in the input stream
#
# ( -- u )
#
	DEFWORD "#IS", 3, "NUM_IS", 0
	mov rax, 0
	mov eax, dword ptr [input_stream_count]
	PPUSH rax
	NEXT

	DEFWORD "IS", 2, "IS", 0
	lea rax, input_stream
	PPUSH rax
	NEXT

# go to next character in the input stream
# this word don't check wheather the character count is zero
#
# ( -- )
#
	DEFWORD "NEXT", 4, "NEXT", 0
	# next head address of available characters
	lea rax, input_stream
	mov rbx, 0
	mov ebx, dword ptr [input_stream_offset]
	add rbx, 1
	add rax, rbx
	# maximum address for characters in the input stream
	mov rcx, offset input_stream_size
	add rcx, -1
	# update offset: note that the input stream is a ring buffer
	cmp rax, rcx
	jg _next_wrap_offset
	jmp _next_update_offset
_next_wrap_offset:
	mov rbx, 0
_next_update_offset:
	mov dword ptr [input_stream_offset], ebx
	NEXT

# recieve characters from stdin
#
# ( -- u )
#
#   u: result status. 0 when succeeded, -1 when failed
#
	DEFWORD "RECV", 4, "RECV", 0
	# calculate a number of bytes to the edge of the ring buffer
	mov rdx, 0
	mov edx, dword ptr [input_stream_offset]
	mov rsi, offset input_stream_size
	sub rsi, 1
	sub rsi, rdx
	# read chars to the edge of the ring buffer
	mov rax, 0               # 0 is for stdin
	lea rbx, input_stream
	add rbx, rdx             # start address to copy
	mov rcx, rsi             # number of character to read
	call syscall_read

	cmp rax, 0
	jge _recv_first_read_succeeded
	jmp _recv_failed

_recv_first_read_succeeded:
	# temporary store a number of read at fisrt time
	mov rdi, rax

	# end of receiving if num read is less than num byte to the edge
	cmp rax, rsi
	jl _recv_end

	# calculate a number of bytes to the head of the ring buffer
	sub rdx, 1

	cmp rdx, 0
	je _recv_end

	# read chars from the head of stream to the previous byte of offset
	mov rax, 0               # 0 is for stdin
	lea rbx, input_stream    # start address to copy
	mov rcx, rdx             # number of character to read
	call syscall_read

	cmp rax, 0
	jl _recv_failed

	add rdi, rax
	jmp _recv_end

_recv_failed:
	PPUSH -1
	NEXT

_recv_end:
	mov rax, 0
	mov eax, dword ptr [input_stream_count]
	add rax, rdi
	mov dword ptr [input_stream_count], eax
	mov rax, 0
	PPUSH rax
	NEXT

# get an address of the line buffer
#
# ( -- addr )
#
	DEFWORD ">IB", 3, "IB", 0
	lea rax, line_buffer
	PPUSH rax
	NEXT

# get an address of a variable to count the contents of line buffer
#
# ( -- addr )
#
	DEFWORD "#IB", 3, "NUM_IB", 0
	lea rax, line_buffer_count
	PPUSH rax
	NEXT

##
# text output primitives
#

# display a character
#
# ( u -- )
#
#   u: a character to output
#
	DEFWORD "EMIT", 4, "EMIT", 0
	PPOP rax
	lea rbx, output_buffer
	mov rdx, [output_start]
	add rbx, rdx
	mov byte ptr [rbx], al
	mov rax, 1                         # 1 is for stdout
	mov rcx, 1
	call syscall_write
	NEXT

# display a newline
#
# ( -- )
#
	DEFWORD "NL", 2, "NL", 0
	mov al, 0x0a
	lea rbx, output_buffer
	mov rdx, [output_start]
	add rbx, rdx
	mov byte ptr [rbx], al
	mov rax, 1                         # 1 is for stdout
	mov rcx, 1
	call syscall_write
	NEXT

# display a string with length u
#
# ( addr u -- )
#
	DEFWORD "PRINT", 5, "PRINT", 0x80
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

##
# numeric operations
#

# test a numeric equality
#
# ( u1 u2 -- u3 )
#
	DEFWORD "=", 1, "EQ", 0x00
	PPOP rax
	PPOP rbx
	cmp rax, rbx
	jne _eq_not_equal
	mov rax, -1
	jmp _eq_end
_eq_not_equal:
	mov rax, 0
_eq_end:
	PPUSH rax
	NEXT

# invert all bits
#
# ( u1 -- u2 )
#
	DEFWORD "NOT", 3, "NOT", 0x00
	PPOP rax
	not rax
	PPUSH rax
	NEXT

# bit operation: or
#
# ( u1 u2  -- u3 )
#
	DEFWORD "OR", 2, "OR", 0x00
	PPOP rax
	PPOP rbx
	or rax, rbx
	PPUSH rax
	NEXT

# addition
#
# ( n1 n2 -- n3 )
#
	DEFWORD "+", 1, "ADD", 0x00
	PPOP rbx
	PPOP rax
	add rax, rbx
	PPUSH rax
	NEXT

# substruction
#
# ( n1 n2 -- n3 )
#
	DEFWORD "-", 1, "SUB", 0x00
	PPOP rbx
	PPOP rax
	sub rax, rbx
	PPUSH rax
	NEXT

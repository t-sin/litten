	.intel_syntax noprefix

	.globl word_quit
	.globl word_newline
	.globl word_readch
	.globl word_writech

	.macro NEXT
	jmp inner_interpreter
	.endm

	.data

line_buffer:
	.skip 256
line_size = . - line_buffer

	.text

word_quit:
	mov rax, 0
	call syscall_exit

# I/O words

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

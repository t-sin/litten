	.intel_syntax noprefix

	.globl syscall_exit
	.globl syscall_read
	.globl syscall_write
	.globl syscall_mmap

	.text

	.include "macro.s"

# Call exit() system call.
#
# input:
#   rax: exit status code
#
# ref:
#   https://linuxjm.osdn.jp/html/LDP_man-pages/man3/exit.3.html
#
syscall_exit:
	mov rdi, rax
	mov rax, 60     # `grep NR_exit -R /usr/include` 
	syscall

# Call read() system call.
#
# input:
#   rax: file discripter to input
#   rbx: buffer address
#   rcx: number of characters to input
#
# output:
#   rax: number of characters read, or -1 when error occurs
#
# ref:
#   https://linuxjm.osdn.jp/html/LDP_man-pages/man2/read.2.html
#
syscall_read:
	RPUSH rdi
	RPUSH rsi
	RPUSH rdx

	mov rdi, rax  # set fd
	mov rsi, rbx  # set buffer address
	mov rdx, rcx  # set num of input
	mov rax, 0    # system call number for read() in x86-64

	# syscall breaks r11 so save it
	# cf. https://stackoverflow.com/questions/50571275/why-does-a-syscall-clobber-rcx-and-r11
	RPUSH r11
	syscall
	RPOP r11

	RPOP rdi
	RPOP rsi
	RPOP rdx
	ret

# Call write() system call.
#
# input:
#   rax: file discripter to output
#   rbx: buffer address
#   rcx: number of characters to output
#
# output:
#   rax: number of characters written, or -1 when error occurs
#
# ref:
#   https://linuxjm.osdn.jp/html/LDP_man-pages/man2/write.2.html
#
syscall_write:
	RPUSH rdi
	RPUSH rsi
	RPUSH rdx

	mov rdi, rax  # set fd
	mov rsi, rbx  # set buffer address
	mov rdx, rcx  # set num of output
	mov rax, 1    # system call number for write() in x86-64
	RPUSH r11
	syscall
	RPOP r11

	RPOP rdi
	RPOP rsi
	RPOP rdx
	ret

# Call mmap() system call to allocate memory.
# This subrutine does not mmap with fd, with MAP_FIXED and with `offset`.
#
# input:
#   rax: memory region length to allocate
#   rbx: protection attributes for allocated memory region like PROT_EXEC etc.
#
# output:
#   rax: address of memory region allocated
#
# ref:
#   man of mmap(): https://linuxjm.osdn.jp/html/LDP_man-pages/man2/mmap.2.html
#
syscall_mmap:
	RPUSH rdi
	RPUSH rsi
	RPUSH rdx
	RPUSH rcx
	RPUSH r8
	RPUSH r9

	mov rdi, 0    # set addr to calucate mapped region. here it's NULL
	mov rsi, rax  # set length to allocate
	mov rdx, rbx  # set protection attributes
	mov rcx, 20   # set flags (MAP_ANONYMOUS)
	              # cf. /usr/include/x86_64-linux-gnu/bits/mman-linux.h
	mov r8, 0     # set fd to map with file. here it's ignored
	mov r9, 0     # set offset. here it's ignored.
	mov rax, 9    # system call number for mmap() in x86-64
	RPUSH r11
	syscall
	RPOP r11

	RPOP rdi
	RPOP rsi
	RPOP rdx
	RPOP rcx
	RPOP r8
	RPOP r9
	ret

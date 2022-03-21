	.intel_syntax noprefix

	.globl pstack_max
	.globl pstack_bottom
	.globl pstack_size

	.globl rstack_max
	.globl rstack_bottom
	.globl rstack_size

	.globl dict_start
	.globl dict_size

	.globl input_stream_offset
	.globl input_stream_count
	.globl input_stream
	.globl input_stream_size

	.globl output_len
	.globl output_start
	.globl output_buffer
	.globl output_buffer_size

	.data

##
# input stream (a ring buffer)
#
input_stream_offset:
	.dc.l 0
input_stream_count:
	.dc.l 0
input_stream:
	.skip 2048
input_stream_size = . - input_stream

##
# output buffer
output_start:
	.dc.a 0
output_len:
	.skip 8
output_buffer:
	.skip 2048
output_buffer_size = . - output_buffer

	.bss

##
# parameter stack
#
# data operands are stored with PUSH/POP macros.
# r13 register stores its stack top address.
#
pstack_max:
	.skip 0x10000
pstack_bottom:
pstack_size = . - pstack_max

##
# return stack
#
# control data are stored with RPUSH/RPOP macros.
# r14 register stores its stack top address.
#
rstack_max:
	.skip 0x10000
rstack_bottom:
rstack_size = . - rstack_max

##
# dictionary
#
# Forth's word dictionary.
# heap memory is not garbage collected and glows to bottom.
# r12 register stores its bottom address.
dict_start:
	.skip 0x800000
dict_size = . - dict_start

	.intel_syntax noprefix

	.data

	.globl pstack_max
	.globl pstack_bottom
	.globl pstack_size

	.globl rstack_max
	.globl rstack_bottom
	.globl rstack_size

	.globl dict_start
	.globl dict_size

	.globl input_len
	.globl input_start
	.globl input_buffer
	.globl input_buffer_size

	.globl output_len
	.globl output_start
	.globl output_buffer
	.globl output_buffer_size

##
# input line buffer
#
input_start:
	.dc.a 0
input_len:
	.skip 8
input_buffer:
	.skip 2048
input_buffer_size = . - input_buffer

##
# output buffer
output_start:
	.dc.a 0
output_len:
	.skip 8
output_buffer:
	.skip 2048
output_buffer_size = . - output_buffer


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

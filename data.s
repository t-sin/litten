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

	.globl line_buffer
	.globl line_size

##
# input line buffer
#
line_buffer:
	.skip 0xff
line_size = . - line_buffer

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

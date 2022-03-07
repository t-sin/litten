	.intel_syntax noprefix

	.globl pstack_max
	.globl pstack_bottom
	.globl pstack_size

	.macro PPUSH
	.endm

	.macro PPOP
	.endm

	.data

pstack_max:
	.skip 0x10000
pstack_bottom:
pstack_size = . - pstack_max

	.text

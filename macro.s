	.intel_syntax noprefix

##
# Forth primitives

# progress IP with built-in words
	.macro NEXT
	jmp inner_interpreter
	.endm

##
# parameter stack operation

# push a cell to the pstack
	.macro PPUSH reg
	sub r13, 8
	mov qword ptr [r13], \reg
	.endm

# pop a cell from the pstack
	.macro PPOP reg
	mov \reg, qword ptr [r13]
	add r13, 8
	.endm

##
# return stack operation

# push a cell to the return stack
	.macro RPUSH reg
	sub r14, 8
	mov qword ptr [r14], \reg
	.endm

# pop a cell from the return stack
	.macro RPOP reg
	mov \reg, qword ptr [r14]
	add r14, 8
	.endm

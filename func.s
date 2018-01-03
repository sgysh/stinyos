.file "func.s"
.code32
.globl io_hlt, io_cli, io_sti, io_stihlt
.globl io_load_eflags, io_store_eflags
.globl io_in8, io_in16, io_in32
.globl io_out8, io_out16, io_out32

.text

# HLT
io_hlt:
	hlt
	ret

# CLI
io_cli:
	cli
	ret

# STI
io_sti:
	sti
	ret

# STI -> HLT
io_stihlt:
	sti
	hlt
	ret

# LOAD EFLAGS
io_load_eflags:
	pushf
	popl %eax
	ret

# STORE EFLAGS
io_store_eflags:
	movl 4(%esp), %eax
	pushl %eax
	popf
	ret

# IN (8bit)
io_in8:
	movl 4(%esp), %edx
	xorl %eax, %eax
	inb %dx, %al
	ret

# IN (16bit)
io_in16:
	movl 4(%esp), %edx
	xorl %eax, %eax
	inw %dx, %ax
	ret

# IN (32bit)
io_in32:
	movl 4(%esp), %edx
	inl %dx, %eax
	ret

# OUT (8bit)
io_out8:
	movl 4(%esp), %edx
	movb 8(%esp), %al
	outb %al, %dx
	ret

# OUT (16bit)
io_out16:
	movl 4(%esp), %edx
	movl 8(%esp), %eax
	outw %ax, %dx
	ret

# OUT (32bit)
io_out32:
	movl 4(%esp), %edx
	movl 8(%esp), %eax
	outl %eax, %dx
	ret


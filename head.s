.equ BOTPAK,  0x00280000
.equ DSKCAC,  0x00100000
.equ DSKCAC0, 0x00008000

.equ CYLS_ADDR,  0x0ff0
.equ LEDS_ADDR,  0x0ff1
.equ VMODE_ADDR, 0x0ff2
.equ SCRNX_ADDR, 0x0ff4
.equ SCRNY_ADDR, 0x0ff6
.equ VRAM_ADDR,  0x0ff8

.text

.code16  # run in 16-bit mode

head:
	movb $0x00, %ah  # Set Video Mode
	movb $0x13, %al  # 320x200 256 color graphics (MCGA,VGA)
	int $0x10        # INT 10 Video BIOS Services

	movb $0x08, (VMODE_ADDR)
	movw $320, (SCRNX_ADDR)
	movw $200, (SCRNY_ADDR)
	movl $0x000a0000, (VRAM_ADDR)

	movb $0x02, %ah        # Read Keyboard Flags
	int $0x16              # INT 16 Keyboard BIOS Services
	                       #  on return:
	                       #  AL = BIOS keyboard flags (located in BIOS Data Area 0x417)
	                       #    |7|6|5|4|3|2|1|0|  AL or BIOS Data Area 0x417
	                       #     | | | | | | | `---- right shift key depressed
	                       #     | | | | | | `----- left shift key depressed
	                       #     | | | | | `------ CTRL key depressed
	                       #     | | | | `------- ALT key depressed
	                       #     | | | `-------- scroll-lock is active
	                       #     | | `--------- num-lock is active
	                       #     | `---------- caps-lock is active
	                       #     `----------- insert is active
	movb %al, (LEDS_ADDR)

	# PIC(Programmable Interrupt Controller) settings
	#   set IMR(Interrupt Mask Register) to ignore all IRQs
	#   All IRQs are ignored and nothing is sent to the CPU.
	movb $0xff, %al  # prepare for masking all IRQs
	outb %al, $0x21  # 0x21: master PIC data port
	nop
	outb %al, $0xa1  # 0xa1: slave PIC data port

	# CPU setting
	cli              # Clear interrupt flag; interrupts disabled when interrupt flag cleared.

	# enable A20 to access to addresses above 1MiB
	call wait_kbdinbuf_empty
	movb $0xd1, %al           # Command 0xd1: Write output port
	                          #               The value written to the port 0x60 is output to the output port.
	outb %al, $0x64           # The CPU can command the keyboard controller by writing port 0x64.
	call wait_kbdinbuf_empty
	movb $0xdf, %al
	outb %al, $0x60           # enable A20
	call wait_kbdinbuf_empty  # wait for enabling A20

.arch i486  # The .arch cpu_type directive enables a warning when gas detects an instruction that is not supported on the CPU specified.
	lgdtl (GDTR0)           # Load GDTR
	movl %cr0, %eax         # CR0: Control Register. |PG|----RESERVED----|NE|ET|TS|EM|MP|PE|
	andl $0x7fffffff, %eax  # PG: Bit 31. The Paging flag. When this flag is set, memory paging is enabled.
	orl $0x00000001, %eax   # PE: Bit 0. The Protected Environment flag. This flag puts the system into protected mode when set.
	movl %eax, %cr0
	jmp pipelineflash
pipelineflash:
	movw $1*8, %ax  # use selector 1 from the GDT
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs
	movw %ax, %ss

# copy to 0x280000 -
	movl $bootpack, %esi    # from
	movl $BOTPAK, %edi      # to
	movl $512*1024/4, %ecx  # size
	call memcpy

# copy to 0x100000 - 0x100200
	movl $0x7c00, %esi  # from
	movl $DSKCAC, %edi  # to
	movl $512/4, %ecx   # size
	call memcpy

# copy to 0x100200 -
	movl $DSKCAC0+512, %esi  # from
	movl $DSKCAC+512, %edi   # to
	movl $0x00, %ecx
	movb (CYLS_ADDR), %cl
	imull $512*18*2/4, %ecx
	subl $512/4, %ecx        # size
	call memcpy

# start bootpack
	movl $0x00310000, %esp
	ljmpl $2*8, $0x00000000

# function

wait_kbdinbuf_empty:
	inb $0x64, %al           # 0x64: I/O port address for the keyboard controller status register
	andb $0x02, %al          # Bit 1: Input buffer status
	                         #   0: Input buffer empty, can be written. 1: Input buffer full, don't write yet.
	jnz wait_kbdinbuf_empty  # jump if not zero
	ret

memcpy:
	movl (%esi), %eax
	addl $4, %esi
	movl %eax, (%edi)
	addl $4, %edi
	subl $1, %ecx
	jnz memcpy
	ret

# GDT
.align 8
GDT0:  # Global Descriptor Table
.skip 8, 0x00                                 # NULL descriptor
	.word 0xffff, 0x0000, 0x9200, 0x00cf
	.word 0xffff, 0x0000, 0x9a28, 0x0047

	.word 0x0000
GDTR0:  # Global Descriptor Table Register (GDT Register): 48 bits
	.word 8*3-1  # LIMIT (16 bits)
	.int GDT0    # BASE  (32 bits)

.align 8
bootpack:


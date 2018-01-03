.equ CYLS,      10
.equ CYLS_ADDR, 0x0ff0

.code16  # run in 16-bit mode

# Boot Sector
# The boot sector is the first sector of the volume.
# BPB(BIOS Parameter Block) is located in the boot sector.
# NOTE:
#         BPB_ : part of the BPB
#         BS_  : part of the boot sector (not really part of the BPB)
	jmp boot              # BS_jmpBoot    : jump instruction to boot code
	nop                   #                 (0xeb 0x?? 0x90: jmp(short jump)->0xeb, nop->0x90)
	.ascii "IPL     "     # BS_OEMName    : only a name string, 8 bytes
	.word 512             # BPB_BytsPerSec: count of bytes per sector
	.byte 1               # BPB_SecPerClus: number of sectors per allocation unit(cluster)
	.word 1               # BPB_RsvdSecCnt: number of reserved sectors
	.byte 2               # BPB_NumFATs   : the count of FAT data structures on the volume
	.word 224             # BPB_RootEntCnt: the count of 32-byte directory entries in the root directory (for FAT12 and FAT16 volumes)
	.word 2880            # BPB_TotSec16  : the old 16-bit total count of sectors on the volume
	                      #                 This field can be 0; if it is 0, then BPB_TotSec32 must be non-zero. For FAT32 volumes, this field must be 0.
	                      #                 For FAT12 and FAT16 volumes, this field contains the sector count,
	                      #                 and BPB_TotSec32 is 0 if the total sector count "fits" (is less than 0x10000).
	.byte 0xf0            # BPB_Media     : 0xF8 is the standard value for fixed (non-removable) media. For removable media, 0xF0 is frequently used.
	.word 9               # BPB_FATSz16   : the FAT12/FAT16 16-bit count of sectors occupied by ONE FAT
	.word 18              # BPB_SecPerTrk : sectors per track for interrupt 0x13
	.word 2               # BPB_NumHeads  : number of heads for interrupt 0x13
	.int 0                # BPB_HiddSec   : count of hidden sectors preceding the partition that contains this FAT volume
	                      #                 This field should always be zero on media that are not partitioned.
	.int 0                # BPB_TotSec32  : the new 32-bit total count of sectors on the volume
	                      #                 This field can be 0; if it is 0, then BPB_TotSec16 must be non-zero. For FAT32 volumes, this field must be non-zero.
	                      #                 For FAT12/FAT16 volumes, this field contains the sector count if BPB_TotSec16 is 0 (count is greater than or equal to 0x10000).
# At this point, the BPB/boot sector for FAT12 and FAT16 differs from the BPB/boot sector for FAT32.
# The structure for FAT12 and FAT16 starting at offset 36 of the boot sector is described below
	.byte 0               # BS_DrvNum     : Int 0x13 drive number
	                      #                 This field supports MS-DOS bootstrap and is set to the INT 0x13 drive number of the media
	                      #                 (0x00 for floppy disks, 0x80 for hard disks).
	.byte 0               # BS_Reserved1  : reserved (used by Windows NT)
	                      #                 Code that formats FAT volumes should always set this byte to 0.
	.byte 0x29            # BS_BootSig    : extended boot signature (0x29)
	                      #                 This is a signature byte that indicates that the following three fields in the boot sector are present.
	.int 0xffffffff       # BS_VolID      : volume serial number
	.ascii "STINYOS    "  # BS_VolLab     : volume label
	                      #                 This field matches the 11-byte volume label recorded in the root directory.
	.ascii "FAT12   "     # BS_FilSysType : one of the strings "FAT12   ", "FAT16   ", or "FAT     "

# Boot Code
boot:
	# Initialize the registers: DS, ES, SS and SP
	movw $0, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	movw $0x7c00, %sp
	
	# prepare to read disk sectors
	movw $0x0820, %ax
	movw %ax, %es      # ES:BX = pointer to buffer
	movb $0x00, %ch    # track/cylinder number: 0
	movb $0x02, %cl    # sector number: 2
	movb $0x00, %dh    # head number: 0

readloop:
	movw $0x00, %si  # error counter
retry:
	# read disk sectors
	movb $0x02, %ah  # Read Disk Sectors
	movb $0x01, %al  # number of sectors to read: 1
	movb $0x00, %dl  # drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
	movw $0, %bx     # ES:BX = pointer to buffer: 0x8200
	int $0x13        # INT 13, Diskette BIOS Services
	jnc next         # jump if not carry
	                 # CF(Carry Flag) = 0 if successful
	                 #                = 1 if error

	addw $0x01, %si  # increment error counter
	cmpw $0x05, %si  # check error counter
	jae error        # jump if above or equal

	# reset disk system
	movb $0x00, %ah  # Reset Disk System
	movb $0x00, %dl  # drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
	int $0x13        # INT 13, Diskette BIOS Services
	jmp retry

next:
	movw %es, %ax
	addw $0x0020, %ax
	movw %ax, %es      # increase pointer address by 0x0200
	addb $0x01, %cl    # increase sector number by 1
	cmpb $18, %cl      # check if 18 sectors have been read
	jbe readloop       # jump if below or equal

	movb $0x01, %cl  # set sector number to 1
	addb $0x01, %dh  # increase head number by 1
	cmpb $0x02, %dh
	jb readloop      # jump if below
	movb $0x00, %dh  # set head number to 0
	addb $0x01, %ch  # increase cylinder number by 1
	cmpb $CYLS, %ch  # check if $CYLS cylinders have been read
	jb readloop      # jump if below

	movb $CYLS, (CYLS_ADDR)  # save the number of read cylinders

	jmp 0xc200  # Data area begins at 0xc200 (0x8000 + 0x4200)

# Error Handling
error:
	movw $err_msg, %si  # point to error message
print:
	movb (%si), %al     # ASCII character to write
	addw $1, %si        # increase pointer address by 1
	cmpb $0, %al        # check if the character is null(0)
	je error_fin
	movb $0x0e, %ah     # Write Text in Teletype Mode
	movw $0x00, %bx     # BH = page number (text modes), BL = foreground pixel color (graphics modes)
	int $0x10           # INT 10, Video BIOS Services
	jmp print
error_fin:
	hlt
	jmp error_fin

err_msg:
	.string "load error"

	.org 0x1fe, 0x00  # The 0xAA55 signature in sector offsets 510 and 511.
	.byte 0x55, 0xaa  # signature


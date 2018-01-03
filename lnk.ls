/*
 * A detailed memory map is as follows:
 *
 *   0x0000 0000: boot sector
 *                BPB_RsvdSecCnt(1) * BPB_BytsPerSec(512) = 0x200
 *   -----------
 *   0x0000 0200: FAT #1
 *                BPB_FATSz16(9) * BPB_BytsPerSec(512) = 0x1200
 *   -----------
 *   0x0000 1400: FAT #2
 *                NOTE: BPB_NumFATs is 2.
 *                BPB_FATSz16(9) * BPB_BytsPerSec(512) = 0x1200
 *   -----------
 *   0x0000 2600: root directory
 *                32 * BPB_RootEntCnt(224) = 0x1c00
 *   -----------
 *   0x0000 4200: data area
 */

OUTPUT_FORMAT("binary")

IPL_BASE = 0x7C00;

SECTIONS {
  . = IPL_BASE;
}


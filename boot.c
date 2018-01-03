#include "func.h"

#define COLORN      16
#define COL_000000   0
#define COL_FF0000   1
#define COL_00FF00   2
#define COL_FFFF00   3
#define COL_0000FF   4
#define COL_FF00FF   5
#define COL_00FFFF   6
#define COL_FFFFFF   7
#define COL_C6C6C6   8
#define COL_840000   9
#define COL_008400  10
#define COL_848400  11
#define COL_000084  12
#define COL_840084  13
#define COL_008484  14
#define COL_848484  15

void Main(void);
void init_palete(void);
void set_palete(int, int, unsigned char *);
void boxfill(unsigned char *, int, unsigned char, int, int, int, int);

void Main(void) {
	char *vram = (char *)0xa0000;
	const int x = 320, y = 200;

	init_palete();

	boxfill(vram, x, COL_008484, 0,      0, x - 1, y - 29);
	boxfill(vram, x, COL_C6C6C6, 0, y - 28, x - 1, y - 28);
	boxfill(vram, x, COL_FFFFFF, 0, y - 27, x - 1, y - 27);
	boxfill(vram, x, COL_C6C6C6, 0, y - 26, x - 1, y -  1);

	boxfill(vram, x, COL_FFFFFF,  3, y - 24, 59, y - 24);
	boxfill(vram, x, COL_FFFFFF,  2, y - 24,  2, y -  4);
	boxfill(vram, x, COL_848484,  3, y -  4, 59, y -  4);
	boxfill(vram, x, COL_848484, 59, y - 23, 59, y -  5);
	boxfill(vram, x, COL_000000,  2, y -  3, 59, y -  3);
	boxfill(vram, x, COL_000000, 60, y - 24, 60, y -  3);

	boxfill(vram, x, COL_848484, x - 47, y - 24, x -  4, y - 24);
	boxfill(vram, x, COL_848484, x - 47, y - 23, x - 47, y -  4);
	boxfill(vram, x, COL_FFFFFF, x - 47, y -  3, x -  4, y -  3);
	boxfill(vram, x, COL_FFFFFF, x -  3, y - 24, x -  3, y -  3);

	while(1)
		io_hlt();
}

void init_palete(void) {
	unsigned char table_rgb[COLORN * 3] = {
		0x00, 0x00, 0x00,  /*  0: black       */
		0xff, 0x00, 0x00,  /*  1: red         */
		0x00, 0xff, 0x00,  /*  2: lime        */
		0xff, 0xff, 0x00,  /*  3: yellow      */
		0x00, 0x00, 0xff,  /*  4: blue        */
		0xff, 0x00, 0xff,  /*  5: purple      */
		0x00, 0xff, 0xff,  /*  6: cyan        */
		0xff, 0xff, 0xff,  /*  7: white       */
		0xc6, 0xc6, 0xc6,  /*  8: gray        */
		0x84, 0x00, 0x00,  /*  9: dark red    */
		0x00, 0x84, 0x00,  /* 10: green       */
		0x84, 0x84, 0x00,  /* 11: dark yellow */
		0x00, 0x00, 0x84,  /* 12: dark blue   */
		0x84, 0x00, 0x84,  /* 13: dark purple */
		0x00, 0x84, 0x84,  /* 14: dark cyan   */
		0x84, 0x84, 0x84   /* 15: dark gray   */
	};

	set_palete(0, 15, table_rgb);
}

void set_palete(int start, int end, unsigned char *rgb) {
	int i, eflags;

	eflags = io_load_eflags();

	io_cli();
	io_out8(0x3c8, start);  /* 0x3c8: DAC Address Write Mode Register */
	for( i = start; i <= end; i++ ) {
		io_out8(0x3c9, rgb[0] / 4);  /* 0x3c9: DAC Data Register */
		io_out8(0x3c9, rgb[1] / 4);
		io_out8(0x3c9, rgb[2] / 4);
		rgb += 3;
	}

	io_store_eflags(eflags);
}

void boxfill(unsigned char *vram, int width, unsigned char c,
	           int x0, int y0, int x1, int y1) {
	int x, y;

	for( y = y0; y <= y1; y++ ) {
		for( x = x0; x <= x1; x++ ) vram[y * width + x] = c;
	}
}


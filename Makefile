NAME := os
SERIAL_NUM := 0xffffffff
VOLUME_LABEL := STINYOS
LOADER_IMG := loader.img
IMG  := $(NAME).img
CFLAGS := -m32 -nostdlib -nostdinc -ffreestanding

.PHONY : all clean run debug gdb

all : $(IMG)

$(IMG) : Makefile lnk.ls loader.s sys.bin
	gcc $(CFLAGS) -o $(LOADER_IMG) loader.s -T lnk.ls
	mformat -f 1440 -v $(VOLUME_LABEL) -N $(SERIAL_NUM) -C -B $(LOADER_IMG) -i $(IMG)
	mcopy sys.bin -i $(IMG) ::

sys.bin : Makefile head.bin boot.bin
	cat head.bin boot.bin > sys.bin

head.bin : Makefile head.ls head.s
	gcc head.s $(CFLAGS) -T head.ls -o head.bin

boot.bin : Makefile boot.c func.o
	gcc boot.c $(CFLAGS) -Wl,--oformat=binary -c -o boot.o
	ld -m elf_i386 --oformat binary -o boot.bin --script=boot.ls boot.o func.o

func.o : Makefile func.s
	as --32 -march=i386 func.s -o func.o

run : $(IMG)
	qemu-system-i386 -m 32 -fda $(IMG)

debug : $(IMG)
	qemu-system-i386 -m 32 -s -S -fda $(IMG)

gdb :
	gdb -ex "target remote localhost:1234"

clean :
	rm $(IMG) $(LOADER_IMG) boot.bin boot.o func.o head.bin sys.bin


all:

	nasm -f elf32 ./src/bios.s -o ./sup/bios.elf
	
	ld -z max-page-size=0x01000 -T linker.lds --oformat=binary -m elf_i386 -e start16  ./sup/bios.elf -o ./bin/bios.bin -Map ./sup/mibios.map


.PHONY: clean

clean:
	rm ./bin/*.bin




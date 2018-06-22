all:
	$ mkdir -p sup
	nasm -f elf32 ./src/resetvec.s -o ./sup/resetvec.elf
	nasm -f elf32 ./src/init.s -o ./sup/init.elf
	nasm -f elf32 ./src/main.s -o ./sup/main.elf
	nasm -f elf32 ./src/sys_tables.s -o ./sup/sys_tables.elf
	nasm -f elf32 ./src/uninitdata.s -o ./sup/uninitdata.elf
	nasm -f elf32 ./src/tabla_digitos.s -o ./sup/tabla_digitos.elf
	nasm -f elf ./src/utils16.s -o ./sup/utils16.elf
	nasm -f elf ./src/handlers.s -o ./sup/handlers.elf
	nasm -f elf ./src/tarea1.s -o ./sup/tarea1.elf
	gcc -c -m32 -fno-stack-protector -fno-asynchronous-unwind-tables -fno-PIC -Wall ./src/utils32.c -o ./sup/utils32.elf


	ld -z max-page-size=0x01000 -T linker.lds --oformat=binary -m elf_i386 -e start16  ./sup/resetvec.elf ./sup/init.elf ./sup/main.elf ./sup/sys_tables.elf ./sup/uninitdata.elf ./sup/tabla_digitos.elf ./sup/utils16.elf ./sup/handlers.elf ./sup/tarea1.elf ./sup/utils32.elf -o ./bin/bios.bin -Map ./sup/mibios.map

.PHONY: clean

clean:
	rm ./bin/*.bin
	rm ./bin/*.ini
	rm ./bin/*.log
	rm ./sup/*.elf
	rm ./sup/*.map
	



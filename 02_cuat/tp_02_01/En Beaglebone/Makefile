obj-m+=i2c.o
KERNEL_DIR = /home/juan/Escritorio/kernel-bbb/kernel_beagle


"all:
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C $(KERNEL_DIR) M=$(PWD) modules
		#arm-linux-gnueabihf-gcc prueba_dev.c -o test -Wall
		#arm-linux-gnueabihf-gcc server.c -o server -Wall
		gcc clientes.c -o clientes -Wall
		
copy:
	sshpass -p "temppwd" scp i2c.ko	debian@192.168.6.2:/home/debian/i2c.ko
	#sshpass -p "temppwd" scp prueba_dev.c	debian@192.168.6.2:/home/debian/prueba_dev.c
	sshpass -p "temppwd" scp server.c	debian@192.168.6.2:/home/debian/server.c
	
connect:
	sshpass -p "temppwd" ssh debian@192.168.6.2
	
clean:
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C $(KERNEL_DIR) M=$(PWD) clean
		rm -f test_prg
		rm -f server

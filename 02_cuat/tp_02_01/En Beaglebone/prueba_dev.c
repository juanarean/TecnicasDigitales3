#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

int  main (void) {
    
    int fd, aux, i;
    char dato_rx[2];
    char pointer=0;
    float temp;
    
    dato_rx[2]=0;
    
    

        
        printf("Abriendo dispositivo...\n");
        fd = open("/dev/td3_i2c", O_RDWR);
        if(fd < 0){
            printf("Error al abrir dispositivo\n");
            return -1;
        }
        printf("fd= %d\n", fd);
        printf("Se abrio el dispositivo correctamete\n");
       //  Escribo el pointer register en el sensor 

        aux = write(fd, &pointer, sizeof(pointer));
        if(aux<=0){
            printf("Error al escribir en el dispositivo");
            return -1;
        }
        printf("Exito al escribir el pointer register\n"); 
        
        
    for (i=0;i<20;i++){
        sleep(1);        
        /* Intento leer 2 bytes de temperatura */

        printf("Leo temperatura del sensor...\n");
   
        aux = read(fd, dato_rx, 2);
    
        if(aux<=0){
            printf("Error al leer del dispositivo\n");
            return -1;
        }
    
        printf("Cantidad de bytes leidos %d\n", aux);
        printf("Bytes leidos: %x - %x\n", dato_rx[0], dato_rx[1]);
        
        
        temp=((dato_rx[0]<<3)+(dato_rx[1]>>5));
        
	printf("%x\n", (unsigned int)temp);

	temp =temp*0.125;

	printf("temperatura: %f\n", temp);
	 }
        close(fd);
        printf("Se cerro el dispositivo correctamete\n");
    
    return 0;
}

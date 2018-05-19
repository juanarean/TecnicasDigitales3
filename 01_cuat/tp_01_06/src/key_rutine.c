#include <conio.h>
#include "../inc/sys_types.h"

__attribute__(( section(".key"))) byte __leer_teclado(void)
{

   byte tecla = ERROR_DEFECTO;
   byte control = ERROR_DEFECTO;
   
   control = inportb(0x64);

   while(!(control && 1))
    control = inportb(0x64);
   
   tecla = inportb(0x60);
   
   while(!(tecla && 0x80))
       tecla = inportb(0x60);

//__asm__("xchg %bx,%bx");
   return(tecla);
}

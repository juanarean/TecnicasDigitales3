
#include "../inc/sys_types.h"
extern word * _cantidad;
extern dword * vectores;

__attribute__(( section(".init32"))) byte __fast_memcpy(const dword *src, dword *dst, dword length)
{

   byte status = ERROR_DEFECTO;

   if(length > 0)
   {
      
      while(length)
      {
         length--;
         *dst = *src;
         dst++;
         src++;
      }
      status = EXITO;   
   }
   return(status);
}

__attribute__(( section(".init32"))) byte __paginacion(dword lineal, dword fisica, dword base, dword atributos, dword cant)
{
    byte status = ERROR_DEFECTO;
  
    dword indice_td = (lineal & 0xffc00000) >> 20;
    dword indice_tp = (lineal & 0x003ff000) >> 10;
    
    dword *punt_td = 0;

    punt_td = (dword *) (base + indice_td);
    if((*punt_td) == 0)
    {
        cant ++;
        *punt_td = base + (cant*0x1000) + 7;
        cant = __paginacion((dword)(base + (cant*0x1000)), (dword)(base + (cant*0x1000)), base, 7, cant);
    }
    
    dword *punt_tp = 0;
    punt_tp = (dword *) (((*punt_td) & 0xfffff000) + indice_tp);
    *punt_tp = (fisica & 0xfffff000) + atributos;
    
    status = cant;
    return(status);
}

/*__attribute__(( section(".ISR_HANDLERS"))) dword __printf(dword atributos, dword caracteres)
{
    dword i;
    dword j;
    dword k;
    k = 0;
    dword * dst;
    dst = buffer;
    dword * src;
    src = vectores;
    
    if(num_bytes>0 && *_cantidad>0)
    {
        for(i=0;i<*_cantidad;i++)
        {
                for(j=0;j<2;j++)
                {
                    *dst = *src;
                    dst++;
                    src++;

                    k=+8;
                }
                if(k>=num_bytes)    break;
        }
    }

    return(k);
}
*/

__attribute__(( section(".kernel32"))) byte __print_inicio(void)
{
	unsigned char * pv = (unsigned char *)0xb8000;
	unsigned char i;
	unsigned char string_ptr[] = "Ingrese Datos." ;
	i = 0;
	while(i < 13)
	{
		*(unsigned char*)(pv+(2*i)) = (unsigned char)string_ptr[i];
		i++;
	}
__asm__("xchg %bx,%bx");
	return(0);
}
